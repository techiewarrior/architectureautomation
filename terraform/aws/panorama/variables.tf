variable "aws_region" {
  type = string
  default = "us-west-2"
}
variable "availability-zones" {
   type = list
   default = [
    "us-west-2a",
    "us-west-2b",
    "us-west-2c",
    "us-west-2d"
  ]
}

/*variable "vpcs" {
  type  = map
  default = {
    "Security-In" = "10.255.0.0/16"
    "Security-Out" = "10.254.0.0/16"
    "Security-East-West" = "10.253.0.0/16"
    "Spoke1" = "10.1.0.0/16"
    "Spoke2" = "10.2.0.0/16"
  }
}
variable inbound-vpc-subnets {
  type = map
  default = { 
    "security-In-Mgmt-a" = {
      network = "10.255.110.0/24"
      availability_zone = "0"
      attachment = false
    }
    "security-In-TGW-a" = {
      network = "10.255.1.0/24"
      availability_zone = "0"
      attachment = true
    }
    "security-In-Pub-a" = {
      network = "10.255.100.0/24"
      availability_zone = "0"
      attachment = false
    }
    "security-In-Priv-a" = {
      network = "10.255.11.0/24"
      availability_zone = "0"
      attachment = false
    }
    "security-In-Mgmt-b" = {
      network = "10.255.120.0/24"
      availability_zone = "1"
      attachment = false
    }
    "security-In-TGW-b" = {
      network = "10.255.2.0/24"
      availability_zone = "1"
      attachment = true
    }
    "security-In-Pub-b" = {
      network = "10.255.200.0/24"
      availability_zone = "1"
      attachment = false
    }
    "security-In-Priv-b" = {
      network = "10.255.12.0/24"
      availability_zone = "1"
      attachment = false
    }
  }
}

variable outbound-vpc-subnets {
  type = map
  default = { 
    "security-Out-Mgmt-a" = {
      network = "10.254.110.0/24"
      availability_zone = "0"
    }
    "security-Out-TGW-a" = {
      network = "10.254.1.0/24"
      availability_zone = "0"
    }
    "security-Out-Pub-a" = {
      network = "10.254.100.0/24"
      availability_zone = "0"
    }
    "security-Out-Mgmt-b" = {
      network = "10.254.120.0/24"
      availability_zone = "1"
    }
    "security-Out-TGW-b" = {
      network = "10.254.2.0/24"
      availability_zone = "1"
    }
    "security-Out-Pub-b" = {
      network = "10.254.200.0/24"
      availability_zone = "1"
    }
  }
}

variable east-west-vpc-subnets {
  type = map
  default = { 
    "security-East-West-Mgmt-a" = {
      network = "10.253.110.0/24"
      availability_zone = "0"
    }
    "security-East-West-TGW-a" = {
      network = "10.253.1.0/24"
      availability_zone = "0"
    }
    "security-East-West-Pub-a" = {
      network = "10.253.100.0/24"
      availability_zone = "0"
    }
    "security-East-West-Mgmt-b" = {
      network = "10.253.120.0/24"
      availability_zone = "1"
    }
    "security-East-West-TGW-b" = {
      network = "10.253.2.0/24"
      availability_zone = "1"
    }
    "security-East-West-Pub-b" = {
      network = "10.253.200.0/24"
      availability_zone = "1"
    }
  }
}

variable spoke1-vpc-subnets {
  type = map
  default = { 
    "spoke1-web-a" = {
      network = "10.1.1.0/24"
      availability_zone = "0"
    }
    "spoke1-web-b" = {
      network = "10.1.2.0/24"
      availability_zone = "1"
    }
  }
}

variable spoke2-vpc-subnets {
  type = map
  default = { 
    "spoke2-db-a" = {
      network = "10.2.1.0/24"
      availability_zone = "0"
    }
    "spoke2-db-b" = {
      network = "10.2.2.0/24"
      availability_zone = "1"
    }
  }
}

variable management-sg-rules {
  type = "map"
  default = {
    Fw-to-Panorama = {
      type = "ingress"
      cidr_blocks = "0.0.0.0/0"
      protocol = "tcp"
      from_port = 3978
      to_port = 3978
    }
    software-retrieval = {
      type = "ingress"
      cidr_blocks = "0.0.0.0/0"
      protocol = "tcp"
      from_port = "28443"
      to_port = "28443"
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
      cidr_blocks = "192.168.100.0/24"
      protocol = "tcp"
      from_port = "22"
      to_port = "22"
    }
    ssh-from-on-prem = {
      type = "ingress"
      cidr_blocks = "172.16.0.0/16"
      protocol = "tcp"
      from_port = "22"
      to_port = "22"
    }
    https-from-aws = {
      type = "ingress"
      cidr_blocks = "10.0.0.0/8"
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
    }
    https-from-mgmt-vpc = {
      type = "ingress"
      cidr_blocks = "192.168.100.0/24"
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
    }
    https-from-on-prem = {
      type = "ingress"
      cidr_blocks = "172.16.0.0/16"
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
    }
    https-from-on-prem2 = {
      type = "ingress"
      cidr_blocks = "67.177.200.66/32"
      protocol = "tcp"
      from_port = "443"
      to_port = "443"
    }
    ping-reply-aws = {
      type = "ingress"
      cidr_blocks = "10.0.0.0/8"
      protocol = "icmp"
      from_port = "0"
      to_port = "0"
    }
    ping-reply-mgmt-vpc = {
      type = "ingress"
      cidr_blocks = "192.168.100.0/24"
      protocol = "icmp"
      from_port = "0"
      to_port = "0"
    }
    ping-request-aws = {
      type = "ingress"
      cidr_blocks = "10.0.0.0/8"
      protocol = "icmp"
      from_port = "8"
      to_port = "8"
    }
    ping-request-mgmt-vpc = {
      type = "ingress"
      cidr_blocks = "192.168.100.0/24"
      protocol = "icmp"
      from_port = "8"
      to_port = "8"
    }
  }
}*/

/*variable public-sg-rules {
  type = map
  default = {
    all-traffic = {
      type = "ingress"
      cidr_blocks = "0.0.0.0/0"
      protocol = "-1"
      from_port = "0"
      to_port = "0"
    }
  }
}

variable ra_key {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvhGY3JSg5aC0JKEwIJtMUHLCYzEYxfFD5UuUFfd2MbBiplew0nWzWONpMk5plM0KEY7n5zTnyHCzJuXtb3VrblPW2S+L5Cod+ZTHmTR5JLcGaoPhMKryMsN9nz/iPuojmB+kIEK+PSaMhAjWis8oHHvGqCbim6sO1Q6LzGj+hqg+jINZ8djFHqsVEyvvpvCi7QVJHDPKVK05WVoU2+p881u8fvGyPSPFYY0H75PZt0im11RcHLQSh5X8Z5UyjiCFc2owuk14ZuweeV2jYss2fFaQJ3643FSJHLJl2oE+3BK98NVUNUKbwOvVNxzF9jIGmGNndrXV/jDE+ovgmc+vb admin"
}

variable "rg_name" {
  description = "The name for the new resource group"
  type      = string
  default   = "AzureRefArch"
}

variable "prefix" {
  description = "The name for the new resource group"
  type  = string
  default   = "tj"
}

variable "rg_location" {
  description = "Region"
  type  = string
  default   = "West US"
}

variable "vnet_name" {
  description = "Name for the VNet"
  type = string
  default   = "AzureRefArch-VNET"
}

variable "Victim_CIDR" {
  description = "Block"
  type  = string
  default   = "192.168.1.0/24"
}

variable "Subnet_CIDR" {
  description = "Subnet"
  type = string
  default   = "192.168.1.0/24"
}

variable "Admin_Username" {
  description = "Username"
  type = string
  default = "tschuler"
}

variable "Admin_Password" {
  description = "Password"
  type = string
  default = "Password123456789"
}*/

