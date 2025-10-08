# EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge({
    Environment = var.environment
    Project     = var.project_name
    Name        = "${var.project_name}-${var.environment}-eks-cluster-role"
  }, var.tags)
}

# EKS Node Group Role
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.project_name}-${var.environment}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge({
    Environment = var.environment
    Project     = var.project_name
    Name        = "${var.project_name}-${var.environment}-eks-node-group-role"
  }, var.tags)
}

# EKS Cluster Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# Optional: ECR Policy for pulling images
resource "aws_iam_policy" "ecr_pull_policy" {
  count = var.create_ecr_policy ? 1 : 0

  name        = "${var.project_name}-${var.environment}-ecr-pull-policy"
  description = "Policy for ECR image pull access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge({
    Environment = var.environment
    Project     = var.project_name
  }, var.tags)
}

resource "aws_iam_role_policy_attachment" "ecr_pull" {
  count = var.create_ecr_policy ? 1 : 0

  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = aws_iam_policy.ecr_pull_policy[0].arn
}

# Optional: S3 Access Policy
resource "aws_iam_policy" "s3_access_policy" {
  count = var.create_s3_policy && length(var.s3_bucket_arns) > 0 ? 1 : 0

  name        = "${var.project_name}-${var.environment}-s3-access-policy"
  description = "Policy for S3 bucket access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = concat(
          var.s3_bucket_arns,
          [for arn in var.s3_bucket_arns : "${arn}/*"]
        )
      }
    ]
  })

  tags = merge({
    Environment = var.environment
    Project     = var.project_name
  }, var.tags)
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  count = var.create_s3_policy && length(var.s3_bucket_arns) > 0 ? 1 : 0

  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = aws_iam_policy.s3_access_policy[0].arn
}

# Additional custom policies
resource "aws_iam_role_policy_attachment" "additional_policies" {
  count = length(var.additional_policies)

  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = var.additional_policies[count.index]
}