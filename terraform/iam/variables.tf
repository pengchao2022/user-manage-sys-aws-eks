variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 20
    error_message = "Project name must be between 3 and 20 characters."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster, used for IAM role naming"
  type        = string
}

variable "additional_policies" {
  description = "Additional IAM policies to attach to the EKS node group role"
  type        = list(string)
  default     = []
}

variable "create_ecr_policy" {
  description = "Whether to create and attach ECR policy for the node group"
  type        = bool
  default     = true
}

variable "create_s3_policy" {
  description = "Whether to create and attach S3 access policy for the node group"
  type        = bool
  default     = false
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs to grant access to (if create_s3_policy is true)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all IAM resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cluster_oidc_issuer" {
  description = "The OIDC issuer URL for the EKS cluster"
  type        = string
}
