variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "eks_node_role_arn" {
  description = "ARN of the EKS node group role for ECR access"
  type        = string
}