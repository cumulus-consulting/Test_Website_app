variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default = "10.0.0.0/16"
  
}

variable "public_subnet_cidr_block" {
  description = "The CIDR block for the subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    ]
}

variable "private_subnet_cidr_block" {
  description = "The CIDR block for the subnets"
  type        = list(string)
  default = [
    "10.0.3.0/24",
    "10.0.4.0/24",
    ]
}