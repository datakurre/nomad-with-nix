job "development" {
  datacenters = ["dc1"]
  type = "batch"

  group "app" {

    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }

    task "database" {
      driver = "raw_exec"
      lifecycle {
        hook = "prestart"
        sidecar = "true"
      }
      resources {
        network {
          port "psql" {}
        }
      }
      env {
        PGDATA = "${NOMAD_TASK_DIR}/db"
        PGPORT = "${NOMAD_PORT_psql}"
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
exec ${NIX_SHELL} ${NOMAD_NIX} --run "

if [ ! -d ${PGDATA} ]; then
  initdb -U postgres
  echo \"unix_socket_directories='/tmp'\" >> \"${PGDATA}/postgresql.conf\"
fi

exec postgres
"
EOH
        ]
      }
    }

    task "database-init" {
      driver = "raw_exec"
      lifecycle {
        hook = "prestart"
        sidecar = "false"
      }
      env {
        PGARGS = "-h ${NOMAD_IP_database_psql} -p ${NOMAD_PORT_database_psql} -U postgres"
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
exec ${NIX_SHELL} ${NOMAD_NIX} --run "

while ! pg_isready \${PGARGS}; do \
echo \"Waiting for database ${NOMAD_ADDR_database_psql}\"; sleep 2; done

if createdb ${PGARGS} app; then
  createuser ${PGARGS} app
  psql ${PGARGS} -c \"alter user app with encrypted password 'app';\"
  psql ${PGARGS} -c \"grant all privileges on database app to app;\"
fi
"
EOH
        ]
      }
    }

    task "server" {
      driver = "raw_exec"
      resources {
        network {
          port "http" {}
        }
      }
      env {
        PGARGS = "-h ${NOMAD_IP_database_psql} -p ${NOMAD_PORT_database_psql} -U postgres"
        DATABASE_URL = "postgresql://app:app@${NOMAD_ADDR_database_psql}/app"
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
exec ${NIX_SHELL} ${NOMAD_NIX} --run "

cd \"$(dirname ${NOMAD_NIX})/app\"

python -m uvicorn main:app --port ${NOMAD_PORT_http} --reload
"
EOH
        ]
      }
    }
  }
}
