output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster."
  value       = module.eks.cluster_version
}

output "vpc_id" {
  description = "ID of the dedicated VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (EKS nodes run here)."
  value       = module.vpc.private_subnets
}

output "aws_region" {
  description = "AWS region where the cluster is deployed."
  value       = var.aws_region
}

output "karpenter_node_role_name" {
  description = "IAM role name assigned to Karpenter-launched nodes."
  value       = module.karpenter.node_iam_role_name
}

output "karpenter_interruption_queue_name" {
  description = "SQS queue name used by Karpenter for Spot interruption events."
  value       = module.karpenter.queue_name
}

output "configure_kubectl" {
  description = "Run this to configure kubectl after apply."
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}
