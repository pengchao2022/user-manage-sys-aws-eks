output "service_account_name" {
  description = "The Kubernetes ServiceAccount used by ALB Controller"
  value       = kubernetes_service_account.alb_controller.metadata[0].name
}

output "iam_role_arn" {
  description = "The IAM Role ARN used by the ALB Controller"
  value       = aws_iam_role.alb_controller.arn
}
