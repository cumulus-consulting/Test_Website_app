variable "mongo_username" {
  type = string
  description = "value for mongo username"

}

variable "mongo_password" {
  type = string
  description = "value for mongo password"

}

variable "region" {
  type = string
  description = "AWS region to deploy the resources"
    default = "us-east-1"
  
}

variable "image_id" {
  type = string
  description = "AMI ID for the EC2 instance"
  default = "ami-01a228f15911e06f6"
  
}