# Innovate Inc. - Cloud Architecture Design (AWS)

## 1. Objective

This document describes the cloud architecture for Innovate Inc.'s web application. The app is a React SPA frontend with a Flask REST API backend and a PostgreSQL database. The goal is to have something secure, that can scale over time, and supports CI/CD deployments. Users access the system from web browsers and mobile devices.

---

## 2. Cloud Environment Structure

The recommendation is to use 4 AWS accounts managed through AWS Organizations. Having separate accounts for each environment is a good practice because it avoids one environment affecting another, makes billing clearer, and gives better control over permissions. For a small startup this is enough without making things too complicated.

1. **Management/Security** — central account for organization policies and security tools
2. **Development** — used for active development and testing
3. **Staging** — close to production, used to validate before releasing
4. **Production** — the live environment, more restricted access

---

## 3. Network Design (VPC)

Each environment gets its own VPC with 3 Availability Zones. The subnets are split into three layers: public (ALB and NAT Gateway), private for the application (EKS nodes), and private for the database (RDS).

- The React SPA is stored in **S3** and delivered through **CloudFront**
- **AWS WAF** is placed in front of CloudFront/ALB to filter bad traffic
- Security Groups are set with least privilege rules, and the database has no public access
- All traffic uses TLS

---

## 4. Compute Platform (Amazon EKS)

The application runs on Amazon EKS, one cluster per environment. There are two node groups: **system-ng** for cluster components and **api-ng** for the Flask API. The Horizontal Pod Autoscaler handles scaling at the pod level, and Cluster Autoscaler (or Karpenter) handles the nodes. All workloads have resource requests and limits configured.

---

## 5. Containerization and Deployment

The backend is packaged as a Docker image and stored in **Amazon ECR**. Image scanning is enabled to catch vulnerabilities before deploying.

The CI/CD pipeline works like this: run tests → build image → push to ECR → deploy to Dev → promote to Staging → promote to Production (requires manual approval). Helm or Kustomize is used to manage the Kubernetes manifests. Deployments use rolling updates and can be rolled back quickly if something goes wrong.

---

## 6. Data Layer

- **RDS PostgreSQL (Multi-AZ)** — chosen because it is a fully managed service, which reduces operational work for a small team. It has built-in high availability, automatic backups with point-in-time recovery, and supports read replicas. For disaster recovery, snapshots are copied to another region. The target is RPO under 15 minutes and RTO under 1 hour.
- **ElastiCache (Redis)** — used as a cache between the API and the database to reduce load on RDS.
- **S3** — stores the React SPA static files, served through CloudFront.

---

## 7. Security and Monitoring

- IAM roles follow least privilege. Pods use IRSA to get AWS permissions without sharing credentials
- Secrets are stored in AWS Secrets Manager, never in the code or environment variables in plain text
- All data at rest is encrypted with KMS
- CloudTrail and GuardDuty are enabled for auditing and threat detection
- Logs and metrics are collected in CloudWatch
