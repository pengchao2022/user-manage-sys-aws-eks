# EKS Cluster IAM Role（OIDC 配置）
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${var.cluster_oidc_issuer}"
      }
      Condition = {
        StringEquals = {
          "oidc.eks.${var.region}.amazonaws.com/id/${var.cluster_oidc_issuer}:sub" = "system:serviceaccount:kube-system:eks-admin"
        }
      }
    }]
    Version = "2012-10-17"
  })
}

# EKS Node Group IAM Role（OIDC 配置）
resource "aws_iam_role" "eks_node_group" {
  name = "${var.cluster_name}-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${var.cluster_oidc_issuer}"
      }
      Condition = {
        StringEquals = {
          "oidc.eks.${var.region}.amazonaws.com/id/${var.cluster_oidc_issuer}:sub" = "system:serviceaccount:kube-system:alb-ingress-controller"
        }
      }
    }]
    Version = "2012-10-17"
  })
}

# EKS Cluster Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Node Group Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# 使用 ElasticLoadBalancingFullAccess 策略作为回退方案
resource "aws_iam_role_policy_attachment" "alb_controller_fallback" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

# 创建自定义 ALB Controller 策略（如果需要）
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "alb-controller-policy"
  description = "Custom policy for ALB Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:RemoveTags"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# 如果使用自定义策略，附加它
resource "aws_iam_role_policy_attachment" "alb_controller_custom" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.eks_node_group.name
}

# 为 EKS Node Group 角色添加额外的 ElasticLoadBalancing 权限，确保它可以进行 ALB 操作
resource "aws_iam_role_policy_attachment" "eks_node_group_elb_permissions" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

# 为 EKS Node Group 角色添加 EC2 创建安全组的权限
resource "aws_iam_policy" "ec2_create_security_group_policy" {
  name        = "ec2-create-security-group-policy"
  description = "Allow EKS Node Group to create EC2 Security Groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_create_security_group" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = aws_iam_policy.ec2_create_security_group_policy.arn
}

# 为 EKS Node Group 角色添加 VPC 相关权限
resource "aws_iam_role_policy_attachment" "eks_node_group_vpc_permissions" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}
