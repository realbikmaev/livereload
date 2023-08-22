terraform {
  required_providers {
    fly = {
      source  = "fly-apps/fly"
      version = "0.0.23"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "fly" {
  fly_api_token = var.fly_api_token
}
provider "docker" {
  registry_auth {
    address  = "registry.fly.io"
    username = "x"
    password = var.fly_api_token
  }
}

variable "vm_user" {}
variable "github_user" {}
variable "volume_path" {}
variable "volume_size" {}
variable "memory_size" {}
variable "num_cpus" {}

variable "fly_api_token" {}
variable "app_name" {}
variable "region" {}
variable "org" {}

locals {
  image = "registry.fly.io/${var.app_name}:${substr(sha256(file("Dockerfile")), 0, 10)}"
}

resource "docker_registry_image" "docker_image" {
  keep_remotely = false
  name          = local.image
  depends_on    = [docker_image.image, fly_app.app]
}

resource "docker_image" "image" {
  name = local.image
  build {
    context     = "."
    dockerfile  = "Dockerfile"
    pull_parent = true
    no_cache    = true
    platform    = "linux/amd64"
    build_args = {
      vm_user     = var.vm_user
      github_user = var.github_user
      volume_path = var.volume_path
    }
  }

  triggers = {
    build = sha256(file("Dockerfile"))
    main  = sha256(file("proxy/src/main.rs"))
  }
}


resource "fly_app" "app" {
  name = var.app_name
  org  = var.org
}

resource "fly_volume" "app_volume" {
  app        = var.app_name
  name       = "${var.app_name}_volume"
  region     = var.region
  depends_on = [fly_app.app]
  size       = var.volume_size
}

resource "fly_ip" "app_ip" {
  app        = var.app_name
  type       = "v4"
  depends_on = [fly_app.app]
}

resource "fly_machine" "app_machine" {
  app        = var.app_name
  name       = "${var.app_name}_machine"
  region     = var.region
  image      = local.image
  depends_on = [fly_app.app, docker_registry_image.docker_image]
  count      = 1

  services = [
    {
      ports = [
        {
          port = 22
        }
      ]
      protocol      = "tcp"
      internal_port = 2222
    },
    {
      ports = [
        {
          port     = 443
          handlers = ["tls", "http"]
        },
        {
          port     = 80
          handlers = ["http"]
        }
      ]
      "protocol" : "tcp",
      "internal_port" : 8000
    }
  ]

  mounts = [
    { path   = "${var.volume_path}"
      volume = fly_volume.app_volume.id
    }
  ]

  cpus     = var.num_cpus
  memorymb = var.memory_size
}


