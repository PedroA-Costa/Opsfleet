# EKS + Karpenter POC

Creates EKS + VPC + Karpenter with 2 node pools:
- x86 (amd64)
- arm64 (Graviton)

Fixed names in code:
- Cluster: eksTest
- VPC: eksTestVpc

## Requirements
- Terraform 1.9+
- AWS CLI configured
- kubectl

## Deploy
```bash
cd terraform
terraform init
terraform apply
aws eks --region < region > update-kubeconfig --name eksTest
kubectl get nodes
kubectl get nodepools
```

## Example x86 Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-x86
spec:
  nodeSelector:
    kubernetes.io/arch: amd64
  containers:
  - name: nginx
    image: nginx:latest
```

```bash
kubectl apply -f nginx-x86.yaml
kubectl get pod nginx-x86 -o wide
```

## Example arm64 Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-arm
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-arm
  template:
    metadata:
      labels:
        app: nginx-arm
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64
      containers:
      - name: nginx
        image: nginx:latest
```

```bash
kubectl apply -f nginx-arm.yaml
kubectl get pods -l app=nginx-arm -o wide
```

## Destroy
```bash
kubectl delete nodepools --all
kubectl delete ec2nodeclasses --all
terraform destroy
```
