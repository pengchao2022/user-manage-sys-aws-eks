variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "k8s_namespace" {
  description = "Kubernetes namespace for ALB Controller"
  type        = string
  default     = "kube-system"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name for ALB Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "helm_chart_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.4.7"
}

variable "replica_count" {
  description = "Number of ALB Controller replicas"
  type        = number
  default     = 1
}