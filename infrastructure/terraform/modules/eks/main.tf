

resource "aws_ecr_repository" "frontend" {
  name         = "frontend-ecr-repo"
  force_delete = true
}

resource "aws_ecr_repository" "backend" {
  name         = "backend-ecr-repo"
  force_delete = true
}


# EKS Cluster IAM Role

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}


# Worker Node Group IAM Role

data "aws_iam_policy_document" "eks_nodes_assume_role" {
  statement {
    actions    = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node_group_role" {
  name               = "eks-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.eks_nodes_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}


# EKS Cluster

resource "aws_eks_cluster" "this" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = concat(var.public_subnets, var.private_subnets)
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_service_policy_attach,
    aws_iam_role_policy_attachment.eks_cluster_policy_attach
  ]
}


# EKS Data Sources for cluster & auth

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}


# Kubernetes Provider

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}


# EC2 Managed Node Group

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "my-eks-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnets


  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role.eks_node_group_role
  ]
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
  
}

resource "helm_release" "myapp" {
  name      = "myapp"
  namespace = "default"
  chart     = "../charts/myapp"
  set {
    name  = "mongoUri"
    value = "mongodb://admin:${var.mongo_password}@${var.private_ip}:27017/mydatabase?authSource=${var.mongo_username}&authMechanism=SCRAM-SHA-256"
  }



  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}
