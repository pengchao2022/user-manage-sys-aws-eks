data "aws_caller_identity" "current" {}

# 获取集群信息
data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.eks_cluster_name
}

# 创建 IAM Role for ALB Controller
resource "aws_iam_role" "alb_controller" {
  name = "${var.eks_cluster_name}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      }
    ]
  })
}

# 绑定 AWS 官方 ALB Controller Policy
resource "aws_iam_policy_attachment" "alb_controller_attach" {
  name       = "${var.eks_cluster_name}-alb-policy-attachment"
  roles      = [aws_iam_role.alb_controller.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
}

# 创建 Service Account for ALB Controller
resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }

  automount_service_account_token = true
}

# Helm 安装 AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.chart_version

  depends_on = [kubernetes_service_account.alb_controller]

  values = [
    yamlencode({
      clusterName = var.eks_cluster_name
      region      = var.aws_region
      vpcId       = var.vpc_id
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.alb_controller.metadata[0].name
      }
    })
  ]
}
