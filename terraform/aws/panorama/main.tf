terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  region = var.aws_region
  version = "~> 2.53"
}

variable deployment_name {
  description = "Name of the deployment. This name will prefix the resources so it is easy to determine which resources are part of this deployment."
  type = string
  default = "Reference Architecture"
}

variable vpc_name {
  description = "Name of the Management VPC"
  type = string
  default = "Central Mgmt"
}

variable vpc_cidr_block {
  description = "CIDR block for the Management VPC. Code supports /16 Mask trough /29"
  type = string
  default = "10.255.0.0/16"
}

variable enable_ha {
  description = "If enabled, deploy the resources for a HA pair of Panoramas instead of a single Panorama"
  type = bool
  default = true
}

variable onprem_IPaddress {
  description = "IP and mask of the network that will be accessing Panorama"
  type = string
}

variable ra_key {
  description = "Public key for SSH"
  type = string
  default = ""
}

locals {
  name = "${var.deployment_name != "" ? "${var.deployment_name} ${var.vpc_name}" : var.vpc_name}"
  deployment_name = "${var.deployment_name != "" ? "${var.deployment_name} " : ""}"
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
    ssh-from-aws = {
      type = "ingress"
      cidr_blocks = "10.0.0.0/8"
      protocol = "tcp"
      from_port = "22"
      to_port = "22"
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
    /*ssh-from-on-prem2 = {
      type = "ingress"
      cidr_blocks = "67.177.200.66/32"
      protocol = "tcp"
      from_port = "22"
      to_port = "22"
    }*/
    https-from-aws = {
      type = "ingress"
      cidr_blocks = "10.0.0.0/8"
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
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
   /* https-from-on-prem2 = {
      type = "ingress"
      cidr_blocks = "67.177.200.66/32"
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
    }*/
    ping-reply-aws = {
      type = "ingress"
      cidr_blocks = "10.0.0.0/8"
      protocol = "icmp"
      from_port = "0"
      to_port = "-1"
    }
    ping-reply-mgmt-vpc = {
      type = "ingress"
      cidr_blocks = var.vpc_cidr_block
      protocol = "icmp"
      from_port = "0"
      to_port = "-1"
    }
    ping-request-aws = {
      type = "ingress"
      cidr_blocks = "10.0.0.0/8"
      protocol = "icmp"
      from_port = "8"
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
    Egress = {
      type = "egress"
      cidr_blocks = "0.0.0.0/0"
      protocol = "-1"
      from_port = 0
      to_port = 0
    }
  }
}

/*resource "aws_vpc" "management-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${local.name} VPC"
  }
  enable_dns_hostnames = true
}

module "newbits" {
  source = "../modules/subnetting/"
  cidr_block = aws_vpc.management-vpc.cidr_block
}

resource "aws_subnet" "management-subnet-primary" {
  vpc_id = aws_vpc.management-vpc.id
  availability_zone = var.availability-zones[0]
  cidr_block = cidrsubnet(aws_vpc.management-vpc.cidr_block, module.newbits.newbits, 0)
   tags = {
    Name = "${local.name} - ${var.availability-zones[0]}"
  }
}

resource "aws_subnet" "management-subnet-secondary" {
  count = var.enable_ha ? 1 : 0
  vpc_id = aws_vpc.management-vpc.id
  availability_zone = var.availability-zones[1]
  cidr_block = cidrsubnet(aws_vpc.management-vpc.cidr_block, module.newbits.newbits, 1)
   tags = {
    Name = "${local.name} - ${var.availability-zones[1]}"
  }
}

resource "aws_internet_gateway" "management-igw" {
  vpc_id = aws_vpc.management-vpc.id

  tags = {
    Name = "${local.name} IGW"
  }
}

resource "aws_route_table" "management-igw" {
  vpc_id = aws_vpc.management-vpc.id

  tags = {
    Name = "${local.name} IGW"
  }
}

resource "aws_route_table_association" "management-igw-primary" {
  subnet_id      = aws_subnet.management-subnet-primary.id
  route_table_id = aws_route_table.management-igw.id
}
resource "aws_route_table_association" "management-igw-secondary" {
  count = var.enable_ha ? 1 : 0
  subnet_id      = aws_subnet.management-subnet-secondary[0].id
  route_table_id = aws_route_table.management-igw.id
}
resource "aws_route" "in-default" {
  route_table_id = aws_route_table.management-igw.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.management-igw.id
}*/

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
  #subnet = aws_subnet.management-subnet-primary.id
  security_group = aws_security_group.management.id
  aws_key = aws_key_pair.deployer.key_name
  availability-zones = var.availability-zones
}

/*module "panorama-secondary" {
  source = "../modules/panorama/"
  name  = "${local.deployment_name}Panorama-secondary"
  aws_region = var.aws_region
  enable = var.enable_ha
  subnet = aws_subnet.management-subnet-secondary[0].id
  security_group = aws_security_group.management.id
  mgmtip = cidrhost(aws_subnet.management-subnet-secondary[0].cidr_block,4)
  aws_key = aws_key_pair.deployer.key_name
}*/

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



/*module "security-in" {
  source = "./security/"
  availability-zones = var.availability-zones
  vpc-name = "Security-In"
  vpc-cidr = "10.255.0.0/16"
  vpc-subnets = var.inbound-vpc-subnets
  management-sg-rules = var.management-sg-rules
  public-sg-rules = var.public-sg-rules
  tgw =  "${aws_ec2_transit_gateway.TGW1.id}"
}

/*module "security-out" {
  source = "./security/"
  availability-zones = var.availability-zones
  vpc-name = "Security-Out"
  vpc-cidr = "10.254.0.0/16"
  vpc-subnets = var.outbound-vpc-subnets
  management-sg-rules = var.management-sg-rules
  public-sg-rules = var.public-sg-rules
}

module "security-east-west" {
  source = "./security/"
  availability-zones = var.availability-zones
  vpc-name = "Security-East-West"
  vpc-cidr = "10.253.0.0/16
  management-sg-rules = var.management-sg-rules
  public-sg-rules = var.public-sg-rules
}*/


/*resource "aws_vpc" "tgw-vpcs" {
  for_each = var.vpcs
  cidr_block = each.value
  tags = {
    Name = each.key
  }
}

resource "aws_subnet" "inbound-subnets" {
  for_each = var.inbound-vpc-subnets
  vpc_id = "${aws_vpc.tgw-vpcs["Security-In"].id}"
  availability_zone = var.availability-zones[each.value.availability_zone]
  cidr_block = each.value.network
   tags = {
    Name = each.key
  }
}
resource "aws_subnet" "outbound-subnets" {
  for_each = var.outbound-vpc-subnets
  vpc_id = "${aws_vpc.tgw-vpcs["Security-Out"].id}"
  availability_zone = var.availability-zones[each.value.availability_zone]
  cidr_block = each.value.network
   tags = {
    Name = each.key
  }
}
resource "aws_subnet" "east-west-subnets" {
  for_each = var.east-west-vpc-subnets
  vpc_id = "${aws_vpc.tgw-vpcs["Security-East-West"].id}"
  availability_zone = var.availability-zones[each.value.availability_zone]
  cidr_block = each.value.network
   tags = {
    Name = each.key
  }
}
resource "aws_subnet" "spoke1-subnets" {
  for_each = var.spoke1-vpc-subnets
  vpc_id = "${aws_vpc.tgw-vpcs["Spoke1"].id}"
  availability_zone = var.availability-zones[each.value.availability_zone]
  cidr_block = each.value.network
   tags = {
    Name = each.key
  }
}
resource "aws_subnet" "spoke2-subnets" {
  for_each = var.spoke2-vpc-subnets
  vpc_id = "${aws_vpc.tgw-vpcs["Spoke2"].id}"
  availability_zone = var.availability-zones[each.value.availability_zone]
  cidr_block = each.value.network
   tags = {
    Name = each.key
  }
}

resource "aws_security_group" "security-in-management" {
  name = "security-in-management"
  description = "Management SG for Inbound Security VPC"
  vpc_id = "${aws_vpc.tgw-vpcs["Security-In"].id}"
  tags = {
    Name = "security-in-management"
  }
}

resource "aws_security_group_rule" "sg-in-mgmt-rules" {
  for_each = var.management-sg-rules
  security_group_id = "${aws_security_group.security-in-management.id}"
  type = each.value.type
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = [each.value.cidr_blocks]
}

resource "aws_security_group" "security-out-management" {
  name = "security-out-management"
  vpc_id = "${aws_vpc.tgw-vpcs["Security-Out"].id}"
}

resource "aws_security_group_rule" "sg-out-mgmt-rules" {
  for_each = var.management-sg-rules
  security_group_id = "${aws_security_group.security-out-management.id}"
  type = each.value.type
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = [each.value.cidr_blocks]
}

resource "aws_security_group" "security-east-west-management" {
  name = "security-east-west-management"
  vpc_id = "${aws_vpc.tgw-vpcs["Security-East-West"].id}"
}

resource "aws_security_group_rule" "sg-east-west-mgmt-rules" {
  for_each = var.management-sg-rules
  security_group_id = "${aws_security_group.security-east-west-management.id}"
  type = each.value.type
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = [each.value.cidr_blocks]
}
 
resource "aws_security_group" "security-in-public" {
  name = "security-in-public"
  vpc_id = "${aws_vpc.tgw-vpcs["Security-In"].id}"
}

resource "aws_security_group_rule" "sg-in-public-rules" {
  for_each = var.public-sg-rules
  security_group_id = "${aws_security_group.security-in-public.id}"
  type = each.value.type
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = [each.value.cidr_blocks]
}

resource "aws_security_group" "security-out-public" {
  name = "security-out-public"
  vpc_id = "${aws_vpc.tgw-vpcs["Security-Out"].id}"
}

resource "aws_security_group_rule" "sg-out-public-rules" {
  for_each = var.public-sg-rules
  security_group_id = "${aws_security_group.security-out-public.id}"
  type = each.value.type
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = [each.value.cidr_blocks]
}

resource "aws_security_group" "security-east-west-public" {
  name = "security-east-west-public"
  vpc_id = "${aws_vpc.tgw-vpcs["Security-East-West"].id}"
}

resource "aws_security_group_rule" "sg-east-west-public-rules" {
  for_each = var.public-sg-rules
  security_group_id = "${aws_security_group.security-east-west-public.id}"
  type = each.value.type
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = [each.value.cidr_blocks]
}*/

/*resource "aws_ec2_transit_gateway" "TGW1" {
  description = "Transit Gateway"
   tags = {
    Name = "TGW1"
  }
  amazon_side_asn = 64512
  dns_support = "enable"
  vpn_ecmp_support = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
}
 
/*
resource "aws_ec2_transit_gateway_vpc_attachment" "security-out" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-Out"].id}"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
  subnet_ids = ["${aws_subnet.outbound-subnets["security-Out-TGW-a"].id}", "${aws_subnet.outbound-subnets["security-Out-TGW-b"].id}"]
  dns_support = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  }
resource "aws_ec2_transit_gateway_vpc_attachment" "central-mgmt" {
  vpc_id = "${module.panorama.vpc.id}"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
  subnet_ids = ["${module.panorama.subnet-a.id}", "${module.panorama.subnet-b.id}"]
  dns_support = "enable"
    transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}
resource "aws_ec2_transit_gateway_vpc_attachment" "security-east-west" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-East-West"].id}"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
  subnet_ids = ["${aws_subnet.east-west-subnets["security-East-West-TGW-a"].id}", "${aws_subnet.east-west-subnets["security-East-West-TGW-b"].id}"]
  dns_support = "enable"
    transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke1" {
  vpc_id = "${aws_vpc.tgw-vpcs["Spoke1"].id}"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
  subnet_ids = ["${aws_subnet.spoke1-subnets["spoke1-web-a"].id}", "${aws_subnet.spoke1-subnets["spoke1-web-b"].id}"]
  dns_support = "enable"
    transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke2" {
  vpc_id = "${aws_vpc.tgw-vpcs["Spoke2"].id}"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
  subnet_ids = ["${aws_subnet.spoke2-subnets["spoke2-db-a"].id}", "${aws_subnet.spoke2-subnets["spoke2-db-b"].id}"]
  dns_support = "enable"
    transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_route_table" "security" {
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
  tags = {
    Name = "Security"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spokes" {
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
  tags = {
    Name = "Spokes"
  }
}



resource "aws_ec2_transit_gateway_route_table_association" "security-in"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.security-in.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}

resource "aws_ec2_transit_gateway_route_table_association" "security-out"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.security-out.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}

resource "aws_ec2_transit_gateway_route_table_association" "security-east-west"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.security-east-west.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}

resource "aws_ec2_transit_gateway_route_table_association" "central-mgmt"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.central-mgmt.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}

resource "aws_ec2_transit_gateway_route_table_propagation" "security-in-security"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.security-in.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}
resource "aws_ec2_transit_gateway_route_table_propagation" "security-out-security"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.security-out.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}
resource "aws_ec2_transit_gateway_route_table_propagation" "security-east-west-security"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.security-east-west.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke1-security"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.spoke1.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke2-security"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.spoke2.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}
resource "aws_ec2_transit_gateway_route_table_propagation" "central-mgmt-security"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.central-mgmt.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.security.id}"
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke1"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.spoke1.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.spokes.id}"
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke2"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.spoke2.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.spokes.id}"
}

resource "aws_ec2_transit_gateway_route_table_propagation" "security-in"{
  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.security-in.id}"
  transit_gateway_route_table_id = "${aws_ec2_transit_gateway_route_table.spokes.id}"
}

resource "aws_internet_gateway" "security-in-igw" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-In"].id}"

  tags = {
    Name = "security-in-igw"
  }
}

resource "aws_route_table" "security-in-igw" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-In"].id}"

  tags = {
    Name = "security-in-igw"
  }
}

resource "aws_route_table_association" "security-in-igw-a" {
  subnet_id      = "${aws_subnet.inbound-subnets["security-In-Pub-a"].id}"
  route_table_id = "${aws_route_table.security-in-igw.id}"
}
resource "aws_route_table_association" "security-in-igw-b" {
  subnet_id      = "${aws_subnet.inbound-subnets["security-In-Pub-b"].id}"
  route_table_id = "${aws_route_table.security-in-igw.id}"
}
resource "aws_route" "in-default" {
  route_table_id = "${aws_route_table.security-in-igw.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.security-in-igw.id}"
}
resource "aws_route_table" "security-in-tgw" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-In"].id}"

  tags = {
    Name = "security-in-tgw"
  }
}
resource "aws_route_table_association" "security-in-tgw-a" {
  subnet_id      = "${aws_subnet.inbound-subnets["security-In-TGW-a"].id}"
  route_table_id = "${aws_route_table.security-in-tgw.id}"
}
resource "aws_route_table_association" "security-in-tgw-b" {
  subnet_id      = "${aws_subnet.inbound-subnets["security-In-TGW-b"].id}"
  route_table_id = "${aws_route_table.security-in-tgw.id}"
}
resource "aws_route_table" "security-in-priv" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-In"].id}"

  tags = {
    Name = "security-in-priv"
  }
}
resource "aws_route_table_association" "security-in-priv-a" {
  subnet_id      = "${aws_subnet.inbound-subnets["security-In-Priv-a"].id}"
  route_table_id = "${aws_route_table.security-in-priv.id}"
}
resource "aws_route_table_association" "security-in-priv-b" {
  subnet_id      = "${aws_subnet.inbound-subnets["security-In-Priv-b"].id}"
  route_table_id = "${aws_route_table.security-in-priv.id}"
}
resource "aws_route" "security-in-internal" {
  route_table_id = "${aws_route_table.security-in-priv.id}"
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
}

resource "aws_route_table" "security-in-mgmt" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-In"].id}"

  tags = {
    Name = "security-in-mgmt"
  }
}
resource "aws_route_table_association" "security-in-mgmt-a" {
  subnet_id      = "${aws_subnet.inbound-subnets["security-In-Mgmt-a"].id}"
  route_table_id = "${aws_route_table.security-in-mgmt.id}"
}
resource "aws_route_table_association" "security-in-mgmt-b" {
  subnet_id      = "${aws_subnet.inbound-subnets["security-In-Mgmt-b"].id}"
  route_table_id = "${aws_route_table.security-in-mgmt.id}"
}
resource "aws_route" "security-in-mgmt" {
  route_table_id = "${aws_route_table.security-in-mgmt.id}"
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
}
resource "aws_route" "in-mgmt-default" {
  route_table_id = "${aws_route_table.security-in-mgmt.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.security-in-igw.id}"
}




resource "aws_internet_gateway" "security-out-igw" {
 vpc_id = "${aws_vpc.tgw-vpcs["Security-Out"].id}"

  tags = {
    Name = "security-out-igw"
  }
}
resource "aws_route_table" "security-out-igw" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-Out"].id}"

  tags = {
    Name = "security-out-igw"
  }
}
resource "aws_route_table_association" "security-out-igw-a" {
  subnet_id      = "${aws_subnet.outbound-subnets["security-Out-Pub-a"].id}"
  route_table_id = "${aws_route_table.security-out-igw.id}"
}
resource "aws_route_table_association" "security-out-igw-b" {
  subnet_id      = "${aws_subnet.outbound-subnets["security-Out-Pub-b"].id}"
  route_table_id = "${aws_route_table.security-out-igw.id}"
}
resource "aws_route" "out-default" {
  route_table_id = "${aws_route_table.security-out-igw.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.security-out-igw.id}"
}
resource "aws_route_table" "security-out-tgw" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-Out"].id}"

  tags = {
    Name = "security-out-tgw"
  }
}
resource "aws_route_table_association" "security-out-tgw-a" {
  subnet_id      = "${aws_subnet.outbound-subnets["security-Out-TGW-a"].id}"
  route_table_id = "${aws_route_table.security-out-tgw.id}"
}
resource "aws_route_table_association" "security-out-tgw-b" {
  subnet_id      = "${aws_subnet.outbound-subnets["security-Out-TGW-b"].id}"
  route_table_id = "${aws_route_table.security-out-tgw.id}"
}

resource "aws_route_table" "security-out-mgmt" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-Out"].id}"

  tags = {
    Name = "security-out-mgmt"
  }
}
resource "aws_route_table_association" "security-out-mgmt-a" {
  subnet_id      = "${aws_subnet.outbound-subnets["security-Out-Mgmt-a"].id}"
  route_table_id = "${aws_route_table.security-out-mgmt.id}"
}
resource "aws_route_table_association" "security-out-mgmt-b" {
  subnet_id      = "${aws_subnet.outbound-subnets["security-Out-Mgmt-b"].id}"
  route_table_id = "${aws_route_table.security-out-mgmt.id}"
}
resource "aws_route" "security-out-mgmt" {
  route_table_id = "${aws_route_table.security-out-mgmt.id}"
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
}

resource "aws_internet_gateway" "security-east-west-igw" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-East-West"].id}"

  tags = {
    Name = "security-east-west-igw"
  }
}

resource "aws_route_table" "security-east-west-igw" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-East-West"].id}"

  tags = {
    Name = "security-east-west-igw"
  }
}
resource "aws_route_table_association" "security-east-west-igw-a" {
  subnet_id      = "${aws_subnet.east-west-subnets["security-East-West-Pub-a"].id}"
  route_table_id = "${aws_route_table.security-east-west-igw.id}"
}
resource "aws_route_table_association" "security-east-west-igw-b" {
  subnet_id      = "${aws_subnet.east-west-subnets["security-East-West-Pub-b"].id}"
  route_table_id = "${aws_route_table.security-east-west-igw.id}"
}
resource "aws_route" "east-west-default" {
  route_table_id = "${aws_route_table.security-east-west-igw.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.security-east-west-igw.id}"
}

resource "aws_route_table" "security-east-west-tgw" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-East-West"].id}"

  tags = {
    Name = "security-east-west-tgw"
  }
}
resource "aws_route_table_association" "security-east-west-tgw-a" {
  subnet_id      = "${aws_subnet.east-west-subnets["security-East-West-TGW-a"].id}"
  route_table_id = "${aws_route_table.security-east-west-tgw.id}"
}
resource "aws_route_table_association" "security-east-west-tgw-b" {
  subnet_id      = "${aws_subnet.east-west-subnets["security-East-West-TGW-b"].id}"
  route_table_id = "${aws_route_table.security-east-west-tgw.id}"
}

resource "aws_route_table" "security-east-west-mgmt" {
  vpc_id = "${aws_vpc.tgw-vpcs["Security-East-West"].id}"

  tags = {
    Name = "security-east-west-mgmt"
  }
}
resource "aws_route_table_association" "security-east-west-mgmt-a" {
  subnet_id      = "${aws_subnet.east-west-subnets["security-East-West-Mgmt-a"].id}"
  route_table_id = "${aws_route_table.security-east-west-mgmt.id}"
}
resource "aws_route_table_association" "security-east-west-mgmt-b" {
  subnet_id      = "${aws_subnet.east-west-subnets["security-East-West-Mgmt-b"].id}"
  route_table_id = "${aws_route_table.security-east-west-mgmt.id}"
}
resource "aws_route" "security-east-west-mgmt" {
  route_table_id = "${aws_route_table.security-east-west-mgmt.id}"
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
}

resource "aws_route" "central-mgmt-internal" {
  route_table_id = "${module.panorama.route-table.id}"
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
}

resource "aws_route_table" "spoke1" {
  vpc_id = "${aws_vpc.tgw-vpcs["Spoke1"].id}"

  tags = {
    Name = "spoke1"
  }
}
resource "aws_route_table_association" "spoke1-a" {
  subnet_id      = "${aws_subnet.spoke1-subnets["spoke1-web-a"].id}"
  route_table_id = "${aws_route_table.spoke1.id}"
}
resource "aws_route_table_association" "spoke1-b" {
  subnet_id      = "${aws_subnet.spoke1-subnets["spoke1-web-b"].id}"
  route_table_id = "${aws_route_table.spoke1.id}"
}
resource "aws_route" "spoke1" {
  route_table_id = "${aws_route_table.spoke1.id}"
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
}

resource "aws_route_table" "spoke2" {
  vpc_id = "${aws_vpc.tgw-vpcs["Spoke2"].id}"

  tags = {
    Name = "spoke2"
  }
}
resource "aws_route_table_association" "spoke2-a" {
  subnet_id      = "${aws_subnet.spoke2-subnets["spoke2-db-a"].id}"
  route_table_id = "${aws_route_table.spoke2.id}"
}
resource "aws_route_table_association" "spoke2-b" {
  subnet_id      = "${aws_subnet.spoke2-subnets["spoke2-db-b"].id}"
  route_table_id = "${aws_route_table.spoke2.id}"
}
resource "aws_route" "spoke2" {
  route_table_id = "${aws_route_table.spoke2.id}"
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id = "${aws_ec2_transit_gateway.TGW1.id}"
}


module "ngfw1" {
  source = "./vm-series/"

  name = "vmfw-sec-in-aza-1"

  aws_key = "${aws_key_pair.deployer.key_name}"

  trust_subnet_id         = "${aws_subnet.inbound-subnets["security-In-Priv-a"].id}"
  trust_security_group_id = "${aws_security_group.security-in-public.id}"
  trustfwip               = "10.255.11.10"

  untrust_subnet_id         = "${aws_subnet.inbound-subnets["security-In-Pub-a"].id}"
  untrust_security_group_id = "${aws_security_group.security-in-public.id}"
  untrustfwip               = "10.255.100.10"

  management_subnet_id         = "${aws_subnet.inbound-subnets["security-In-Mgmt-a"].id}"
  management_security_group_id = "${aws_security_group.security-in-management.id}"
  mgmtfwip                = "10.255.110.10"

  //bootstrap_profile  = "${aws_iam_instance_profile.bootstrap_profile.id}"
 // bootstrap_s3bucket = "${var.bootstrap_s3bucket}"

 // tgw_id = "${aws_ec2_transit_gateway.tgw.id}"

  aws_region = "${var.aws_region}"
}

/*"azurerm" {
    subscription_id = "05a10a14-2316-4ef0-894e-6b02208bca31"
    client_id       = "b62e283a-25c9-4d28-9254-e7177903f7fb"
    #client_secret   = "b045ce0e-c0c9-4695-bedf-3af9092995f3"
    tenant_id       = "85a86f10-35a9-4c23-9455-866ca4584940"
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.rg_name}"
  location = "${var.rg_location}"

  tags = {
    environment = "ReferenceArchitecture"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name				= "${var.vnet_name}"
  address_space		= ["${var.Victim_CIDR}"]
  location		= "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name	= "${azurerm_resource_group.resourcegroup.name}"
}
resource "azurerm_subnet" "management" {
  name                 = "management"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.Subnet_CIDR}"
}
#### CREATE PUBLIC IP ADDRESSES ####

resource "azurerm_public_ip" panorama-1 {
	name                = "Azure-Panorama-1"
	location			      = "${azurerm_resource_group.resourcegroup.location}"
	resource_group_name	= "${azurerm_resource_group.resourcegroup.name}"
    sku = "Standard"
	allocation_method   = "Static"
    domain_name_label   = "${var.prefix}-ara-panorama-1"

}
resource "azurerm_network_security_group" "PAN_FW_NSG" {
  name                = "AllowManagement-Subnet"
  resource_group_name      = "${azurerm_resource_group.resourcegroup.name}"
  location                 = "${azurerm_resource_group.resourcegroup.location}"

  security_rule {
    name                       = "AllowHTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    #destination_address_prefix = "${var.FW_Mgmt_IP}"
  }
    security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    #destination_address_prefix = "${var.FW_Mgmt_IP}"
  }
}
resource "azurerm_subnet_network_security_group_association" "management" {
  subnet_id                 = "${azurerm_subnet.management.id}"
  network_security_group_id = "${azurerm_network_security_group.PAN_FW_NSG.id}"
}
resource "azurerm_availability_set" "as_panorama" {
  name                = "AzureRefArch-AS"
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
}
resource "azurerm_storage_account" "sa_panorama_diag" {
  name                     = "${var.prefix}azurerefarchv2diag"
  resource_group_name      = "${azurerm_resource_group.resourcegroup.name}"
  location                 = "${azurerm_resource_group.resourcegroup.location}"
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  }

#### CREATE Panorama ####

resource "azurerm_network_interface" "management" {
	name								= "Panorama-eth0"
	location							= "${azurerm_resource_group.resourcegroup.location}"
	resource_group_name 				= "${azurerm_resource_group.resourcegroup.name}"
	ip_configuration {
		name							= "eth0"
		subnet_id						= "${azurerm_subnet.management.id}"
		private_ip_address_allocation 	= "Dynamic"
        #private_ip_address = "${var.FW_Mgmt_IP}"
		public_ip_address_id = "${azurerm_public_ip.panorama-1.id}"
	}
	depends_on = ["azurerm_public_ip.panorama-1"]
}

resource "azurerm_virtual_machine" "panorama" {
	name						= "Azure-Panorama-1"
	location					= "${azurerm_resource_group.resourcegroup.location}"
	resource_group_name	        = "${azurerm_resource_group.resourcegroup.name}"
	network_interface_ids       = ["${azurerm_network_interface.management.id}"]

	primary_network_interface_id		= "${azurerm_network_interface.management.id}"
	vm_size								= "Standard_D3_v2"

  plan {
    name = "byol"
    publisher = "paloaltonetworks"
    product = "panorama"
  }

	storage_image_reference	{
		publisher 	= "paloaltonetworks"
		offer		= "panorama"
		sku			= "byol"
		version		= "8.1.2"
	}

	storage_os_disk {
		name			= "Panorama-1"
		caching 		= "ReadWrite"
		create_option	= "FromImage"
    managed_disk_type = "Standard_LRS"
	}

    boot_diagnostics {
        enabled         = true
        storage_uri     = "${azurerm_storage_account.sa_panorama_diag.primary_blob_endpoint}"
    }

	delete_os_disk_on_termination    = true
	delete_data_disks_on_termination = true

	os_profile 	{
		computer_name	= "Panorama-1"
		admin_username	= "${var.Admin_Username}"
		admin_password	= "${var.Admin_Password}"
		#custom_data = "storage-account=${var.Bootstrap_Storage_Account},access-key=${var.Storage_Account_Access_Key},file-share=${var.Storage_Account_Fileshare},share-directory=${var.Storage_Account_Fileshare_Directory}"
	}

	os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "public_ip_address" {
  value = "${azurerm_public_ip.panorama-1.ip_address}"
}*/