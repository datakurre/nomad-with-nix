job "production" {
  datacenters = ["dc1"]
  type = "batch"

  group "app" {

    task "server" {
      driver = "exec"
      resources {
        network {
          port "http" {}
        }
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
exec uvicorn main:app --port ${NOMAD_PORT_http}
EOH
        ]
      }
      artifact {
        source = "http://127.0.0.1:8080/app-1.0.tar.xz"
        destination = "/"
      }
    }
  }
}
