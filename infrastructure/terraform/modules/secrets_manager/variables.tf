variable "mongo_username" {}
variable "mongo_password" {}
variable "mongo_host" {}
variable "mongo_port" {
  default = "27017"
}
variable "mongo_dbname" {
  default = "mydatabase"
}

variable "secret_name" {
  default = "mongo-connection"
  
}