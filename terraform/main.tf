# Generate random password for database
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# VPC Module
module "vpc" {
  source = "./vpc"

  vpc_cidr        = var.vpc_cidr
  environment     = var.environment
  project_name    = var.project_name
  aws_region      = var.aws_region
}

# IAM Module
module "iam" {
  source = "./iam"

  environment  = var.environment
  project_name = var.project_name
  cluster_name = "${var.project_name}-${var.environment}"
  
  # 可选：配置额外的策略
  create_ecr_policy = true
  create_s3_policy  = false
  
  tags = {
    Terraform   = "true"
    Repository  = "user-registration-app"
    Owner       = "devops-team"
  }
}

# EKS Module
module "eks" {
  source = "./eks"

  environment        = var.environment
  project_name       = var.project_name
  cluster_name       = "${var.project_name}-${var.environment}"
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.vpc.private_subnets
  public_subnets     = module.vpc.public_subnets
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_group_role_arn = module.iam.eks_node_group_role_arn
  instance_types     = var.eks_instance_types
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