module "vpc" {
  source = "./modules/vpc" 
}

module "mongo_bucket" {
  source = "./modules/s3"
}

module "secret_manager" {
  source = "./modules/secrets_manager"
  mongo_username = var.mongo_username
  mongo_host = module.mongo_instance.private_dns
  mongo_password = var.mongo_password
  secret_name    = "mongo-${random_pet.secret_name.id}"
}


resource "random_pet" "secret_name" {
  length    = 2
  separator = "-"
}



module "eks_cluster" {
  source          = "./modules/eks"
  public_subnets  = module.vpc.public_subnet_ids
  private_subnets = module.vpc.private_subnet_ids
  eks_version     = "1.31"
  mongo_password  = var.mongo_password
  private_ip      = module.mongo_instance.private_ip
  mongo_username  = var.mongo_username
}



module "mongo_instance" {
  source = "./modules/mongodb"
  subnet_id = module.vpc.private_subnet_ids[0]
  vpc_id = module.vpc.vpc_id
  s3_bucket_arn = module.mongo_bucket.bucket_arn
  secrets_manager_arn = module.secret_manager.secret_arn
  instance_type = "t2.micro"
  image_id = var.image_id
  secret_id = "mongo-${random_pet.secret_name.id}"


}