# AWS EKS Cluster Example

This Terraform example creates a complete AWS EKS cluster with VPC, subnets, networking, and compute resources. It supports **EC2 node groups**, **Fargate profiles**, or **both** simultaneously.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl

## Quick Start

```shell
# Initialize
terraform init

# EC2 only (default)
terraform apply

# Fargate only
terraform apply -var 'enable_ec2=false' -var 'enable_fargate=true'

# Mixed: EC2 + Fargate
terraform apply -var 'enable_ec2=true' -var 'enable_fargate=true'
```

## Configure kubectl

```shell
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

## Assigning Workloads to Fargate

Pods run on Fargate when deployed to namespaces listed in `fargate_namespaces` (default: `["fargate"]`).

**Example:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: fargate  # Runs on Fargate
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: myapp:latest
```

To add more Fargate namespaces:
```shell
terraform apply -var 'fargate_namespaces=["fargate", "my-namespace"]'
```

## Assigning Workloads to EC2

Deploy pods to namespaces **not** in `fargate_namespaces`, or use node labels:

```yaml
spec:
  nodeSelector:
    node-type: ec2  # Default EC2 node label
```

## Clean Up

```shell
terraform destroy
```
