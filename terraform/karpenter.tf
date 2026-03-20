# ---------------------------------------------------------------------------
# Karpenter
# ---------------------------------------------------------------------------

# Creates IAM roles, SQS queue and EventBridge rules for Spot interruption
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = module.eks.cluster_name

  enable_pod_identity             = true
  create_pod_identity_association = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  # Wait for pods to be ready before creating NodePools
  wait    = true
  timeout = 300

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      interruptionQueue: ${module.karpenter.queue_name}
    controller:
      resources:
        requests:
          cpu: "1"
          memory: 1Gi
        limits:
          cpu: "1"
          memory: 1Gi
    # Keep Karpenter on the system node group
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
        effect: NoSchedule
    nodeSelector:
      node.kubernetes.io/purpose: system
    EOT
  ]

  depends_on = [
    module.karpenter,
    module.eks,
  ]
}

# Short pause after the Helm release to give the Kubernetes API server time
# to fully index the newly installed CRDs (EC2NodeClass, NodePool) before
# nodepools.tf applies instances of them.
resource "time_sleep" "wait_for_karpenter_crds" {
  depends_on      = [helm_release.karpenter]
  create_duration = "30s"
}
