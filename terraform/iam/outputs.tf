output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.name
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "eks_node_group_role_name" {
  description = "Name of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group_role.name
}

output "ecr_pull_policy_arn" {
  description = "ARN of the ECR pull policy (if created)"
  value       = var.create_ecr_policy ? aws_iam_policy.ecr_pull_policy[0].arn : null
}

output "cluster_role_unique_id" {
  description = "Stable and unique string identifying the cluster role"
  value       = aws_iam_role.eks_cluster_role.unique_id
}

output "node_group_role_unique_id" {
  description = "Stable and unique string identifying the node group role"
  value       = aws_iam_role.eks_node_group_role.unique_id
}