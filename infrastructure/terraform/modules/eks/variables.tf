variable "eks_version" {
  type = string
  description = "The version of EKS to use"
}   

variable "public_subnets" {
  type = list(string)
  description = "The public subnets"
}

variable "private_subnets" {
  type = list(string)
  description = "The private subnets"
}

variable "mongo_password" {
  type = string
  description = "MongoDB password"
  sensitive = true
}

variable "private_ip" {
  type = string
  description = "Private IP address of the MongoDB instance"
}

variable "mongo_username" {
  type = string
  description = "MongoDB username"
  sensitive = true
  
}