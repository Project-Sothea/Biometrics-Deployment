variable "BACKEND_PORT" {
  default = "3333"
}

variable "API_URL" {
  default = ""
}

target "backend" {
  context    = "https://github.com/Project-Sothea/Sothea-Backend.git#main"
  dockerfile = "Dockerfile"

  tags = ["sothea-biometrics-backend:latest"]

  output = ["type=docker"]
}

target "frontend" {
  context    = "https://github.com/Project-Sothea/Sothea-Frontend.git#main"
  dockerfile = "Dockerfile"

  args = {
    VITE_API_URL = API_URL != "" ? API_URL : "http://localhost:${BACKEND_PORT}/api"
  }

  tags = ["sothea-biometrics-frontend:latest"]

  output = ["type=docker"]
}

group "default" {
  targets = ["backend", "frontend"]
}