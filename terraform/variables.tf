variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "cluster_version" {
  description = "Kubernetes version. Check the EKS docs for the latest available."
  type        = string
  default     = "1.32"
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version. Must be v1.x. Check GitHub releases for the latest."
  type        = string
  default     = "1.3.3"
}
