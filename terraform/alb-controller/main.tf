data "aws_iam_openid_connect_provider" "cluster" {
  count = var.cluster_oidc_provider_arn == null ? 1 : 0

  url = var.cluster_oidc_provider_url
}

locals {
  oidc_provider_arn = var.cluster_oidc_provider_arn != null ? var.cluster_oidc_provider_arn : data.aws_iam_openid_connect_provider.cluster[0].arn
}
resource "aws_iam_policy" "alb_controller" {
  name        = "${var.project_name}-${var.environment}-ALBControllerPolicy"
  description = "Policy for AWS Load Balancer Controller"
  policy      = data.aws_iam_policy_document.alb_controller.json

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for ALB Controller
resource "aws_iam_role" "alb_controller" {
  name = "${var.project_name}-${var.environment}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.cluster_oidc_issuer_url}:aud" : "sts.amazonaws.com",
            "${var.cluster_oidc_issuer_url}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}