# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group" {
  name = "${var.cluster_name}-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
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
          "elasticloadbalancing:DescribeLoadBalancers", # 权限修改，增加 ALB 查询权限
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:AddTags", # 添加 AddTags 权限
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
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess" # 确保具备完整的负载均衡权限
}
