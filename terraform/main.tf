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

module "alb_controller" {
  source = "./alb-controller"

  cluster_name              = "${var.project_name}-${var.environment}"
  cluster_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}"
  vpc_id                    = module.vpc.vpc_id
  aws_region                = var.aws_region
}

data "aws_caller_identity" "current" {}