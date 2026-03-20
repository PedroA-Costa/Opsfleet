# EC2NodeClass: AWS config shared by all NodePools (AMI, IAM role, subnets, security groups)
resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      # AL2023 works on both x86 and arm64
      amiSelectorTerms:
        - alias: al2023@latest
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.karpenter_discovery_tag}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.karpenter_discovery_tag}
      tags:
        karpenter.sh/discovery: ${local.karpenter_discovery_tag}
  YAML

  depends_on = [time_sleep.wait_for_karpenter_crds]
}

# NodePool for x86 (amd64) — Intel/AMD instances, prefers Spot
resource "kubectl_manifest" "karpenter_node_pool_x86" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: x86
    spec:
      template:
        metadata:
          labels:
            eks-karpenter/arch: amd64
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]
            - key: karpenter.k8s.aws/instance-family
              operator: In
              values: ["m5", "m6i", "m7i", "c5", "c6i", "c7i", "r5", "r6i", "r7i"]
            - key: karpenter.k8s.aws/instance-size
              operator: NotIn
              values: ["nano", "micro", "small"]
      limits:
        cpu: "100"
        memory: 400Gi
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
  YAML

  depends_on = [kubectl_manifest.karpenter_node_class]
}

# NodePool for arm64 (Graviton) — better price/performance than x86, also prefers Spot
resource "kubectl_manifest" "karpenter_node_pool_arm64" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: arm64
    spec:
      template:
        metadata:
          labels:
            eks-karpenter/arch: arm64
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["arm64"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]
            - key: karpenter.k8s.aws/instance-family
              operator: In
              values: ["m6g", "m7g", "c6g", "c7g", "r6g", "r7g"]
            - key: karpenter.k8s.aws/instance-size
              operator: NotIn
              values: ["nano", "micro", "small"]
      limits:
        cpu: "100"
        memory: 400Gi
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
  YAML

  depends_on = [kubectl_manifest.karpenter_node_class]
}
