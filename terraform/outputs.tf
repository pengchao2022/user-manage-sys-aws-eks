output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "database_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.database_endpoint
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = module.rds.database_name
}

output "database_username" {
  description = "Database username"
  value       = var.database_username
  sensitive   = true
}

output "database_password" {
  description = "RDS password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}