module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  # Public endpoint so developers can reach the cluster from their machines
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    # Needed for Karpenter to use EKS Pod Identity
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Karpenter uses this tag to find the node security group
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.karpenter_discovery_tag
  }

  # Let the Terraform caller manage the cluster (admin access entry)
  enable_cluster_creator_admin_permissions = true

  # System node group for add-ons and Karpenter.
  eks_managed_node_groups = {
    system = {
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 4
      desired_size = 2

      labels = {
        "node.kubernetes.io/purpose" = "system"
      }

      taints = [
        {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.karpenter_discovery_tag
  })
}
