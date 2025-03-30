# need mongo instance, role to grab from SM and put backups into s3,and a launch template and ASG to run the mongo instance and keep 1 at all times min capactity 

# resource "aws_launch_template" "this" {
#   name = "mongo-launch-template"
#   image_id = var.image_id
#   vpc_security_group_ids = [aws_security_group.this.id]
#   instance_type = var.instance_type
#   user_data = filebase64("${path.module}/user_data.sh")
#   iam_instance_profile {
#     name = aws_iam_instance_profile.mongo_profile.name
#   }
#   network_interfaces {
#     associate_public_ip_address = false
#     subnet_id = var.subnet_id
#   }
# }


resource "aws_instance" "this" {
  ami                    = var.image_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.mongo_profile.name
  private_ip             = "10.0.3.50"

  user_data = base64encode(
    templatefile("${path.module}/user_data.tpl", {
      secret_id = var.secret_id
    })
  )

  tags = {
    Name = "mongo-instance"
  }
}




resource "aws_iam_instance_profile" "mongo_profile" {
  name = "test_profile"
  role = aws_iam_role.role.name
  
}


resource "aws_security_group" "this" {
  vpc_id = var.vpc_id
  name = "monog-security-group"
  description = "Allow inbound traffic on port 27017"

}

resource "aws_vpc_security_group_ingress_rule" "allow_mongo" {
  security_group_id = aws_security_group.this.id
  from_port         = 27017
  ip_protocol       = "tcp"
  to_port           = 27017
  cidr_ipv4 = "0.0.0.0/0" 
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "permissions_for_mongo" {
    statement {
        effect = "Allow"
    
        actions = [
        "*"
        ]
        resources = [
        "*"
        ]
    }
}


resource "aws_iam_policy" "this" {
  name        = "mongo_policy"
  description = "Policy for mongo instance"
  policy      = data.aws_iam_policy_document.permissions_for_mongo.json
  
}

resource "aws_iam_role" "role" {
  name               = "mongo_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  
  
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.this.arn

}