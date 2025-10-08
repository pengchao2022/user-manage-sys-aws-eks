resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = "1.28"

  vpc_config {
    subnet_ids = var.private_subnets
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${replace(var.cluster_name, "-", "")}NodeGroup"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.private_subnets

  instance_types = var.instance_types

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}