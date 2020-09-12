job "development" {
  datacenters = ["dc1"]
  type = "batch"

  group "app" {

    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }

    task "server" {
      driver = "raw_exec"
      resources {
        network {
          port "http" {}
        }
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<EOH
cd "$(dirname $NOMAD_NIX)/app"
exec $NIX_SHELL --run "
python -m uvicorn main:app --port ${NOMAD_PORT_http} --reload
"
EOH
        ]
      }
    }
  }
}
