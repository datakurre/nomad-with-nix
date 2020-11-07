job "production" {
  datacenters = ["dc1"]
  type = "service"

  group "database" {

    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }

    task "database" {
      driver = "exec"
      resources {
        network {
          port "psql" {}
        }
      }
      service {
        name = "database"
        port = "psql"
        check {
          type = "tcp"
          port = "psql"
          interval = "5s"
          timeout = "2s"
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
fi
exec postgres
EOH
        ]
      }
      artifact {
        source = "http://127.0.0.1:8080/postgresql-[[ .postgres.version ]].tar.gz"
        destination = "/"
      }
    }
  }

  group "app" {
    count = 2
    update {
      max_parallel = 1
      min_healthy_time = "2m"
      healthy_deadline = "15m"
      progress_deadline = "20m"
    }
    task "database-init" {
      driver = "exec"
      lifecycle {
        hook = "prestart"
        sidecar = "false"
      }
      template {
        data = <<EOH
PGARGS=-h {{ range service "database" }}{{ .Address }} -p {{ .Port }}{{ end }} -U postgres
EOH
        destination = "local/file.env"
        env = true
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
while ! pg_isready ${PGARGS}; do \
echo "Waiting for database ${PGARGS}"; sleep 2; done

if createdb ${PGARGS} app; then
  createuser ${PGARGS} app
  psql ${PGARGS} -c "alter user app with encrypted password 'app';"
  psql ${PGARGS} -c "grant all privileges on database app to app;"
fi
EOH
        ]
      }
      artifact {
        source = "http://127.0.0.1:8080/postgresql-[[ .postgres.version ]].tar.gz"
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
      service {
        name = "app"
        port = "http"
        check {
          type = "http"
          path = "/"
          interval = "5s"
          timeout = "2s"
        }
      }
      template {
        data = <<EOH
DATABASE_URL=postgresql://app:app@{{ range service "database" }}{{ .Address }}:{{ .Port }}{{ end }}/app
EOH
        destination = "local/file.env"
        env = true
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
uvicorn main:app --port ${NOMAD_PORT_http}
EOH
        ]
      }
      artifact {
        source = "http://127.0.0.1:8080/app-[[ .app.version ]].tar.gz"
        destination = "/"
      }
    }
  }
}
