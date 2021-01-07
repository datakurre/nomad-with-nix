variable "postgres_artifact" {
  type = string
  default = "http://127.0.0.1:8080/postgresql-11.9-0.tar.gz"
}

variable "app_artifact" {
  type = string
  default = "http://127.0.0.1:8080/app-1.0.tar.gz"
}

job "production" {

  datacenters = ["dc1"]
  type = "service"

  group "database" {

    network {
      mode = "bridge"
    }

    service {
      name = "database"
      port = "5432"

      connect {
        sidecar_service {}
      }
    }

    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }

    task "database" {
      driver = "exec"

      env {
        LC_ALL = "C"
        PGDATA = "${NOMAD_TASK_DIR}/db"
      }

      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
set -e
if [ ! -d ${PGDATA} ]; then
  initdb -U postgres
  echo "unix_socket_directories='${PGDATA}'" >> ${PGDATA}/postgresql.conf
fi
exec postgres
EOH
        ]
      }

      artifact {
        source = var.postgres_artifact
        destination = "/"
      }
    }
  }

  group "app" {
    count = 2

    update {
      max_parallel = 1
      min_healthy_time = "5s"
      healthy_deadline = "5m"
      progress_deadline = "10m"
    }

    network {
      mode = "bridge"

      port "http" {
        to = -1
      }
    }

    service {
      name = "app"
      port = "http"

      check {
        type = "http"
        port = "http"
        path = "/"
        interval = "5s"
        timeout = "2s"
      }

      connect {
        sidecar_service {
          proxy {
            config {
              protocol = "http"
            }
            upstreams {
              destination_name = "database"
              local_bind_port  = 5432
            }
          }
        }
      }
    }

    task "database-init" {
      driver = "exec"

      lifecycle {
        hook = "prestart"
        sidecar = "false"
      }

      env {
        PGARGS = "-h ${NOMAD_UPSTREAM_IP_database} -p ${NOMAD_UPSTREAM_PORT_database} -U postgres"
      }

      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
set -e
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
        source = var.postgres_artifact
        destination = "/"
      }
    }

    task "server" {
      driver = "exec"

      env {
        DATABASE_URL = "postgresql://app:app@${NOMAD_UPSTREAM_ADDR_database}/app"
      }

      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
set -e
uvicorn main:app --host 0.0.0.0 --port ${NOMAD_PORT_http}
EOH
        ]
      }

      artifact {
        source = var.app_artifact
        destination = "/"
      }
    }
  }

  group "proxy" {
    network {
      mode = "bridge"
      port "public" {
        static = 8090
      }
    }

    service {
      name = "proxy"
      port = "8090"

      connect {
        gateway {
          proxy {}
          ingress {
            listener {
              port = 8090
              protocol = "http"
              service {
                name = "app"
                hosts = [ "localhost:8090" ]
              }
            }
          }
        }
      }
    }
  }
}
