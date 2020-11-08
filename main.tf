#====================================================
# OPS09. Make by Daniil Nareiko
#====================================================

terraform {
  required_providers {
    hcloud = {
      source = "terraform-providers/hcloud"
    }
    aws = {
      source = "hashicorp/aws"
    }
    null = {
      source = "registry.terraform.io/hashicorp/null"
    }
  }
}

# Providers =========================================

provider "hcloud" {
  token = var.hcloud_token
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "eu-west-1"
}

#====================================================

# Data ==============================================

data "hcloud_ssh_key" "rebrain_key" {
  name = var.rebrain_key_name
}

data "aws_route53_zone" "srwx_net" {
  name = var.dns.zone
}

#====================================================

# Resources =========================================

resource "random_string" "new_password" {
  count   = length(var.devs)
  length  = 12
  special = false
}

resource "hcloud_server" "OPS09" {
  count = length(var.devs)

  # <login>-<vm_role><number VM if number is greaten than 0>
  name  = "${element(var.devs[*].login, count.index)}-${element(var.devs[*].vm_role, count.index)}${element(var.devs[*].number_of_instance, count.index) == "0" ? "" : element(var.devs[*].number_of_instance, count.index)}"
  image = element(var.devs[*].type, count.index) == "dev" ? element(var.devs[*].vm_role, count.index) == "app" ? var.dev_servers.app.image : var.dev_servers.db.image : element(var.devs[*].vm_role, count.index) == "app" ? var.prod_servers.app.image : var.prod_servers.db.image
  #  Condition illustration:
  #
  # element(var.devs[*].type, count.index) == "dev" ?
  # + element(var.devs[*].vm_role, count.index) == "app" ?
  # ++ var.dev_servers.app.image :
  # -- var.dev_servers.db.image :
  # - element(var.devs[*].vm_role, count.index) == "app" ?
  # ++ var.prod_servers.app.image :
  # -- var.prod_servers.db.image :
  server_type = element(var.devs[*].type, count.index) == "dev" ? element(var.devs[*].vm_role, count.index) == "app" ? var.dev_servers.app.plan : element(var.devs[*].vm_role, count.index) == "db" ? var.dev_servers.db.plan : var.dev_servers.lb.plan : element(var.devs[*].vm_role, count.index) == "app" ? var.prod_servers.app.plan : element(var.devs[*].vm_role, count.index) == "db" ? var.prod_servers.db.plan : var.prod_servers.lb.plan
  #  Condition illustration:
  #
  # element(var.devs[*].type, count.index) == "dev" ?
  # + element(var.devs[*].vm_role, count.index) == "app" ?
  # ++ var.dev_servers.app.plan :
  # -- var.dev_servers.db.plan :
  # - element(var.devs[*].vm_role, count.index) == "app" ?
  # ++ var.prod_servers.app.plan :
  # -- var.prod_servers.db.plan :
  labels = {
    module = var.tags.module
    email  = var.tags.email
  }
  ssh_keys = [data.hcloud_ssh_key.rebrain_key.id, hcloud_ssh_key.my_key.id]

  provisioner "remote-exec" {
    connection {
      # host        = element(hcloud_server.OPS07[*].ipv4_address, count.index)
      host        = self.ipv4_address
      user        = var.connection.user
      type        = var.connection.type
      private_key = file(var.connection.private_key)
    }
    inline = ["/bin/echo -e \"root:${element(random_string.new_password[*].result, count.index)}\" | /usr/sbin/chpasswd"]
  }
  depends_on = [random_string.new_password]
}

resource "hcloud_ssh_key" "my_key" {
  name       = "my_key"
  public_key = file(var.my_key)
}

resource "aws_route53_record" "dns_record" {
  count = length(var.devs)

  zone_id = data.aws_route53_zone.srwx_net.zone_id
  # <var.dns.name>-<var.devs.vm_role><umber VM if number is greaten than 0><var.dns.zone>
  # Examples:
  # daniil_at_nareyko_by-db.devops.rebrain.srwx.net
  # daniil_at_nareyko_by-app1.devops.rebrain.srwx.net
  name       = "${var.dns.name}-${element(var.devs[*].vm_role, count.index)}${element(var.devs[*].number_of_instance, count.index) == "0" ? "" : element(var.devs[*].number_of_instance, count.index)}.${var.dns.zone}"
  type       = var.dns.type
  ttl        = var.dns.ttl
  records    = [element(hcloud_server.OPS09[*].ipv4_address, count.index)]
  depends_on = [hcloud_server.OPS09]
}

resource "null_resource" "logging" {
  count = length(var.devs)

  provisioner "local-exec" {
    command = "echo '${count.index}: ${element(aws_route53_record.dns_record[*].name, count.index)} ${element(hcloud_server.OPS09[*].ipv4_address, count.index)} ${element(random_string.new_password[*].result, count.index)}' >> ops09.log"
  }
  depends_on = [aws_route53_record.dns_record]
}

resource "null_resource" "sort" {
  provisioner "local-exec" {
    command = "a=`tail -n ${length(var.devs)} ops09.log | sort`; echo \"$a\" > ops09.log"
  }
  depends_on = [null_resource.logging]
}
