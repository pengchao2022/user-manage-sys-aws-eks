output "alb_controller_role_arn" {
  description = "ARN of the ALB Controller IAM role"
  value       = aws_iam_role.alb_controller.arn
}

output "alb_controller_policy_arn" {
  description = "ARN of the ALB Controller IAM policy"
  value       = aws_iam_policy.alb_controller.arn
}