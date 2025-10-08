output "iam_role_arn" {
  description = "ARN of the IAM role for ALB Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy for ALB Controller"
  value       = aws_iam_policy.alb_controller.arn
}

output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = kubernetes_service_account.alb_controller.metadata[0].name
}

output "namespace" {
  description = "Kubernetes namespace where ALB Controller is installed"
  value       = var.k8s_namespace
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.aws_load_balancer_controller.name
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.aws_load_balancer_controller.status
}