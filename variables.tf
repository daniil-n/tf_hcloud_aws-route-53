
variable "hcloud_token" {
  description = "Enter the Hetzner Cloud secret token"
  type        = string
  default     = ""
}

variable "aws_access_key" {
  description = "Entrer the aws access key"
  type        = string
  default     = ""
}

variable "aws_secret_key" {
  description = "Enter the aws secret token"
  type        = string
  default     = ""
}

variable "connection" {
  default = {
    user        = "root"
    type        = "ssh"
    private_key = "~/.ssh/id_rsa"
  }
}
#==========================================================

variable "devs" {
  type = list
  default = [
    {
      login              = "kostya" # Enter your login
      vm_role            = "app"    # "app" | "db"
      number_of_instance = "1"      # Enter number so that set name (ex. app1, app2...)
      type               = "dev"    # "prod" | "dev"
    },
    {
      login              = "kostya" # Enter your login
      vm_role            = "app"    # "app" | "db"
      number_of_instance = "2"      # Enter number so that set name (ex. app1, app2...)
      type               = "prod"   # "prod" | "dev"
    },
    {
      login              = "andrey" # Enter your login
      vm_role            = "db"     # "app" | "db"
      number_of_instance = "0"      # Enter number so that set name (ex. app1, app2...)
      type               = "dev"    # "prod" | "dev"
    },
  ]
}

#===========================================================

variable "dev_servers" {
  default = {
    app = {
      image = "ubuntu-20.04"
      plan  = "cx11"
    }
    db = {
      image = "ubuntu-20.04"
      plan  = "cx21"
    }
  }
}

variable "prod_servers" {
  default = {
    app = {
      image = "ubuntu-20.04"
      plan  = "cx21"
    }
    db = {
      image = "ubuntu-20.04"
      plan  = "cx31"
    }
  }
}

variable "rebrain_key_name" {
  description = "Enter rebrain's public ssh key"
  type        = string
  default     = "REBRAIN.SSH.PUB.KEY"
}

variable "my_key" {
  description = "Enter your public ssh key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "dns" {
  description = "Enter a map variable for set dns recort parameters (zone, type, ttl and record)"
  type        = map
  default = {
    zone = "devops.rebrain.srwx.net"
    type = "A"
    ttl  = "60"
    name = "my_email"
  }
}

variable "tags" {
  description = "Enter a map variable for set tags for server"
  type        = map
  default = {
    module = "devops"
    email  = "my_email"
  }
}
