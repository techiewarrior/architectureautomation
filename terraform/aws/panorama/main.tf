terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  region = var.aws_region
  version = "~> 2.53"
}

data "aws_availability_zones" "available" {
  state = "available"
}


locals {
  name = "${var.deployment_name != "" ? "${var.deployment_name} ${var.vpc_name}" : var.vpc_name}"
  deployment_name = "${var.deployment_name != "" ? "${var.deployment_name} " : ""}"
  availability_zones = data.aws_availability_zones.available.names
  management_sg_rules = {
    Fw-to-Panorama = {
      type = "ingress"
      cidr_blocks = "0.0.0.0/0"
      protocol = "tcp"
      from_port = "3978"
      to_port = "3978"
    }
    software-retrieval = {
      type = "ingress"
      cidr_blocks = "0.0.0.0/0"
      protocol = "tcp"
      from_port = "28443"
      to_port = "28443"
    }
    Panorama-to-CortexDL = {
      type = "ingress"
      cidr_blocks = "0.0.0.0/0"
      protocol = "tcp"
      from_port = "444"
      to_port = "444"
    }
    ntp = {
      type = "ingress"
      cidr_blocks = "0.0.0.0/0"
      protocol = "udp"
      from_port = "123"
      to_port = "123"
    }
    ssh-from-mgmt-vpc = {
      type = "ingress"
      cidr_blocks = var.vpc_cidr_block
      protocol = "tcp"
      from_port = "22"
      to_port = "22"
    }
    ssh-from-on-prem = {
      type = "ingress"
      cidr_blocks = var.onprem_IPaddress
      protocol = "tcp"
      from_port = "22"
      to_port = "22"
    }
    https-from-mgmt-vpc = {
      type = "ingress"
      cidr_blocks = var.vpc_cidr_block
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
    }
    https-from-on-prem = {
      type = "ingress"
      cidr_blocks = var.onprem_IPaddress
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
    }
    ping-reply-mgmt-vpc = {
      type = "ingress"
      cidr_blocks = var.vpc_cidr_block
      protocol = "icmp"
      from_port = "0"
      to_port = "-1"
    }
    ping-request-mgmt-vpc = {
      type = "ingress"
      cidr_blocks = var.vpc_cidr_block
      protocol = "icmp"
      from_port = "8"
      to_port = "-1"
    }
    HA1 = {
      type = "ingress"
      cidr_blocks = var.vpc_cidr_block
      protocol = "tcp"
      from_port = "28260"
      to_port = "28260"
    }
    HA2 = {
      type = "ingress"
      cidr_blocks = var.vpc_cidr_block
      protocol = "tcp"
      from_port = "28"
      to_port = "28"
    }
    HA3 = {
      type = "ingress"
      cidr_blocks = var.vpc_cidr_block
      protocol = "tcp"
      from_port = "28769"
      to_port = "28769"
    }
    egress = {
      type = "egress"
      cidr_blocks = "0.0.0.0/0"
      protocol = "-1"
      from_port = 0
      to_port = 0
    }
  }
}

resource "aws_security_group" "management" {
  name = "${local.deployment_name}Panorama"
  description = "Inbound filtering for Panorama"
  vpc_id = module.panorama.management_vpc_id
}

resource "aws_security_group_rule" "sg-out-mgmt-rules" {
  for_each = local.management_sg_rules
  security_group_id = aws_security_group.management.id
  type = each.value.type
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = [each.value.cidr_blocks]
}

resource "aws_key_pair" "deployer" {
  key_name   = "${local.deployment_name}paloaltonetworks-deployment"
  public_key = var.ra_key 
  }

# I really wish I could have a module for each Panorama. However, there isn't a clean way to optionally deploy a module like you can a resource.
# So, for now I am passing the enable_ha variable into the module to determine if I deploy the secondary resources or not.
# When count or for_each becomes available for a module the VPC, Subnets, Route Table and IGW should move out of the module.
module "panorama" {
  source = "../modules/panorama/"
  name = local.name
  deployment_name = local.deployment_name
  enable_ha = var.enable_ha
  aws_region = var.aws_region
  vpc_cidr_block = var.vpc_cidr_block
  security_group = aws_security_group.management.id
  aws_key = aws_key_pair.deployer.key_name
  availability_zones = local.availability_zones
}

output "primary_eip" {
  value = module.panorama.primary_ip
}

output "secondary_eip" {
  value = module.panorama.secondary_ip
}

output "primary_private_ip" {
  value = module.panorama.primary_private_ip
}

output "secondary_private_ip" {
  value = module.panorama.secondary_private_ip
}