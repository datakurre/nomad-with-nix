job "production" {
  datacenters = ["dc1"]
  type = "service"

  group "app" {

    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }

    task "database" {
      driver = "exec"
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
        LC_ALL = "C"
        PGDATA = "${NOMAD_TASK_DIR}/db"
        PGPORT = "${NOMAD_PORT_psql}"
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
if [ ! -d ${PGDATA} ]; then
  initdb -U postgres
  echo "unix_socket_directories='${PGDATA}'" >> ${PGDATA}/postgresql.conf
  cat ${PGDATA}/postgresql.conf
fi
exec postgres
EOH
        ]
      }
      artifact {
        source = "http://127.0.0.1:8080/postgresql-11.9-0.tar.gz"
        destination = "/"
      }
    }

    task "database-init" {
      driver = "exec"
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
while ! pg_isready ${PGARGS}; do \
echo "Waiting for database ${NOMAD_ADDR_database_psql}"; sleep 2; done

if createdb ${PGARGS} app; then
  createuser ${PGARGS} app
  psql ${PGARGS} -c "alter user app with encrypted password 'app';"
  psql ${PGARGS} -c "grant all privileges on database app to app;"
fi
EOH
        ]
      }
      artifact {
        source = "http://127.0.0.1:8080/postgresql-11.9-0.tar.gz"
        destination = "/"
      }
    }

    task "server" {
      driver = "exec"
      resources {
        network {
          port "http" {}
        }
      }
      env {
        DATABASE_URL = "postgresql://app:app@${NOMAD_ADDR_database_psql}/app"
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
uvicorn main:app --port ${NOMAD_PORT_http}
EOH
        ]
      }
      artifact {
        source = "http://127.0.0.1:8080/app-1.0.tar.gz"
        destination = "/"
      }
    }
  }
}
