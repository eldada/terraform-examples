# AWS EKS Cluster Example

This Terraform example creates a complete AWS EKS cluster with VPC, subnets, networking, and compute resources. It supports **EC2 node groups**, **Fargate profiles**, or **both** simultaneously.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                    VPC                                   │
│  ┌────────────────────────────────┐  ┌────────────────────────────────┐  │
│  │         Public Subnet          │  │         Public Subnet          │  │
│  │            (AZ-1)              │  │            (AZ-2)              │  │
│  │  ┌──────────────────────────┐  │  │  ┌──────────────────────────┐  │  │
│  │  │      NAT Gateway         │  │  │  │   NAT Gateway (HA mode)  │  │  │
│  │  └──────────────────────────┘  │  │  └──────────────────────────┘  │  │
│  │              │                 │  │              │                 │  │
│  └──────────────│─────────────────┘  └──────────────│─────────────────┘  │
│                 │         Internet Gateway          │                    │
│  ┌──────────────│─────────────────┐  ┌──────────────│─────────────────┐  │
│  │         Private Subnet         │  │         Private Subnet         │  │
│  │            (AZ-1)              │  │            (AZ-2)              │  │
│  │  ┌──────────────────────────┐  │  │  ┌──────────────────────────┐  │  │
│  │  │       EKS Nodes          │  │  │  │       EKS Nodes          │  │  │
│  │  │    (EC2 / Fargate)       │  │  │  │    (EC2 / Fargate)       │  │  │
│  │  └──────────────────────────┘  │  │  └──────────────────────────┘  │  │
│  └────────────────────────────────┘  └────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl

## Quick Start

```shell
# Initialize
terraform init

# EC2 only (default) with HA NAT Gateway
terraform apply

# Fargate only
terraform apply -var 'enable_ec2=false' -var 'enable_fargate=true'

# Mixed: EC2 + Fargate
terraform apply -var 'enable_ec2=true' -var 'enable_fargate=true'

# Cost-optimized for dev/test (single NAT Gateway)
terraform apply -var 'nat_gateway_mode=single'
```

## Configure kubectl

```shell
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

## NAT Gateway Configuration

The `nat_gateway_mode` variable controls how NAT Gateways are deployed for private subnet egress.

### Options

| Mode | Description | NAT Gateways | Best For |
|------|-------------|--------------|----------|
| `single` (default) | Cost-optimized - one NAT Gateway in first AZ | 1 | Dev/Test environments |
| `ha` | High Availability - one NAT Gateway per AZ | N (one per AZ) | Production workloads |

### Cost Comparison

| Mode | Monthly Cost (approx.) | Notes |
|------|------------------------|-------|
| `single` | ~$32 + data charges | One NAT Gateway |
| `ha` (2 AZs) | ~$64 + data charges | Two NAT Gateways |
| `ha` (3 AZs) | ~$96 + data charges | Three NAT Gateways |

*NAT Gateway pricing: ~$0.045/hour (~$32/month) per gateway + $0.045/GB data processed*

### Availability Implications

#### Single NAT Gateway Mode (`single`)
- One NAT Gateway in the first AZ serves all private subnets
- If the AZ with the NAT Gateway fails, **all private subnets lose internet egress**
- Cross-AZ data transfer charges apply for traffic from other AZs
- **Suitable for dev/test or cost-sensitive non-critical workloads**

#### High Availability Mode (`ha`)
- Each AZ has its own NAT Gateway in the public subnet
- If an AZ fails, only resources in that AZ are affected
- Private subnets in other AZs continue to have internet egress
- **Recommended for production workloads**

### Usage Examples

```shell
# Dev/Test: Single NAT Gateway (default)
terraform apply -var 'nat_gateway_mode=single'

# Production: HA mode
terraform apply -var 'nat_gateway_mode=ha'
```

### Traffic Flow

**HA Mode:**
```
Private Subnet AZ-1 → NAT Gateway AZ-1 → Internet
Private Subnet AZ-2 → NAT Gateway AZ-2 → Internet
```

**Single Mode:**
```
Private Subnet AZ-1 → NAT Gateway AZ-1 → Internet
Private Subnet AZ-2 → NAT Gateway AZ-1 → Internet (cross-AZ traffic)
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
