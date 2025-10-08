variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the EKS cluster is running"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is running"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version of aws-load-balancer-controller"
  type        = string
  default     = "1.9.2" # 你可以固定或升级版本
}
