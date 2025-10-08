provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

data "aws_eks_cluster_auth" "main" {
  name = "user-registration-staging"
}
# Generate random password for database
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# VPC Module
module "vpc" {
  source = "./vpc"

  vpc_cidr     = var.vpc_cidr
  environment  = var.environment
  project_name = var.project_name
  aws_region   = var.aws_region
}

# IAM Module
module "iam" {
  source = "./iam"

  environment  = var.environment
  project_name = var.project_name
  cluster_name = "${var.project_name}-${var.environment}"
}

# EKS Module
module "eks" {
  source = "./eks"

  environment         = var.environment
  project_name        = var.project_name
  cluster_name        = "${var.project_name}-${var.environment}"
  vpc_id              = module.vpc.vpc_id
  private_subnets     = module.vpc.private_subnets
  public_subnets      = module.vpc.public_subnets
  cluster_role_arn    = module.iam.eks_cluster_role_arn
  node_group_role_arn = module.iam.eks_node_group_role_arn
  instance_types      = var.eks_instance_types
}

# RDS Module
module "rds" {
  source = "./rds"

  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  private_subnets   = module.vpc.private_subnets
  database_name     = var.database_name
  database_username = var.database_username
  database_password = random_password.db_password.result
  instance_class    = var.db_instance_class
}

# ECR Module
module "ecr" {
  source = "./ecr"

  environment       = var.environment
  project_name      = var.project_name
  repository_name   = "${var.project_name}-app"
  eks_node_role_arn = module.iam.eks_node_group_role_arn

}

# ALB Ingress Controller Module
module "alb_ingress_controller" {
  source = "./alb-controller"

  eks_cluster_name = module.eks.cluster_name
  aws_region       = var.aws_region
  vpc_id           = module.vpc.vpc_id

  # 可选：如想固定 Helm chart 版本
  chart_version = "1.9.2"
}
