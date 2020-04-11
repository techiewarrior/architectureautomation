variable "aws_region" {
  type = string
  default = "us-west-2"
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