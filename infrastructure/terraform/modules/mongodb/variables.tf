variable "image_id" {
    type = string
}

variable "instance_type" {
    type = string
    default = "t2.micro"    
  
}

variable "vpc_id" {
    type = string
  
}

variable "secrets_manager_arn" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "subnet_id" {
    type = string   
  
}



variable "secret_id" {
  type = string
}