# AWS EKS Cluster Example

This example demonstrates how to create a complete AWS EKS (Elastic Kubernetes Service) cluster setup with support for both EC2 and Fargate compute types.

## Prerequisites

- AWS account with appropriate permissions
- AWS CLI installed and configured
- Terraform installed (>= 1.0)
- kubectl installed (for interacting with the cluster)

## Architecture

This example creates:

- **VPC** with public and private subnets across multiple availability zones
- **Internet Gateway** and **NAT Gateways** for network connectivity
- **EKS Cluster** with proper IAM roles and policies
- **Compute Resources** (choose one):
  - **EC2 Node Group**: Managed EC2 instances running Kubernetes worker nodes
  - **Fargate Profile**: Serverless compute for running pods

## Files

- `variables.tf` - Contains all configurable variables for this example
- `providers.tf` - Contains the Terraform providers configuration (AWS and Kubernetes)
- `vpc.tf` - Contains VPC, subnets, internet gateway, NAT gateways, and routing configuration
- `eks.tf` - Contains EKS cluster, node groups, and IAM roles
- `outputs.tf` - Contains all output values for the infrastructure
- `README.md` - This file

## Configuration

### Key Variables

- `compute_type` - Choose between `"ec2"` or `"fargate"` (default: `"ec2"`)
- `cluster_name` - Name of the EKS cluster (default: `"example-eks-cluster"`)
- `region` - AWS region (default: `"eu-central-1"`)
- `kubernetes_version` - Kubernetes version (default: `"1.34"`)

### API Endpoint Access Variables

- `cluster_endpoint_public_access` - Enable/disable public API endpoint (default: `true`)
- `cluster_endpoint_private_access` - Enable/disable private API endpoint (default: `true`)
- `cluster_endpoint_public_access_cidrs` - List of CIDR blocks allowed to access the public API endpoint (default: `["0.0.0.0/0"]` - allows all)
  - To restrict access, provide specific CIDR ranges: `["203.0.113.0/24", "198.51.100.0/24"]`
  - To block all public access, set to empty list: `[]` (requires `cluster_endpoint_private_access = true`)

### EC2-Specific Variables

When using `compute_type = "ec2"`:
- `node_instance_types` - Instance types for nodes (default: `["t4g.small"]` - Graviton/ARM)
- `node_ami_type` - AMI type for the node group (default: `"AL2023_ARM_64_STANDARD"` for Graviton)
  - For Graviton/ARM instances: `"AL2023_ARM_64_STANDARD"`
  - For x86_64 instances: `"AL2023_x86_64_STANDARD"`
- `node_capacity_type` - Capacity type: `"ON_DEMAND"` or `"SPOT"` (default: `"SPOT"`)
- `node_desired_size` - Desired number of nodes (default: `2`)
- `node_min_size` - Minimum number of nodes (default: `1`)
- `node_max_size` - Maximum number of nodes (default: `3`)
- `node_disk_size` - Disk size in GB (default: `20`)
- `node_key_pair` - EC2 Key Pair for SSH access (optional)

**Note**: EC2 instances are automatically named with the pattern `${cluster_name}-node` via tags. When using Graviton instances (t4g, m6g, etc.), ensure `node_ami_type` is set to `AL2023_ARM_64_STANDARD`.

### Fargate-Specific Variables

When using `compute_type = "fargate"`:
- `fargate_namespaces` - Kubernetes namespaces to run on Fargate (default: `["default", "kube-system"]`)
- `fargate_architecture` - CPU architecture preference for Fargate pods: `"arm64"` (Graviton) or `"amd64"` (x86_64) (default: `"arm64"`)
  - **Important**: This is informational/documentation only. Fargate architecture is automatically determined by your container image architecture, NOT by node selectors. 
  - **For multi-arch images**: Simply use the standard image tag (e.g., `myapp:latest` or `myapp:v1.0.0`). The container runtime automatically selects the correct architecture variant. No special tag needed!
  - **For architecture-specific images**: Use architecture-specific tags (e.g., `myapp:arm64` or `myapp:amd64`) if you only have single-arch images
  - **Do NOT use node selectors** like `kubernetes.io/arch` with Fargate - they will cause scheduling failures

## Usage

### 1. Initialize Terraform

```shell
terraform init
```

### 2. Plan the Deployment

```shell
# Plan with default EC2 compute type
terraform plan

# Plan with Fargate compute type
terraform plan -var 'compute_type=fargate'

# Plan with custom variables
terraform plan \
  -var 'cluster_name=my-eks-cluster' \
  -var 'compute_type=ec2' \
  -var 'node_desired_size=3' \
  -var 'node_max_size=5'

# Plan with restricted API access (only allow specific CIDR ranges)
terraform plan \
  -var 'cluster_endpoint_public_access_cidrs=["203.0.113.0/24","198.51.100.0/24"]'
```

### 3. Apply the Configuration

```shell
# Apply with default settings (EC2)
terraform apply

# Apply with Fargate
terraform apply -var 'compute_type=fargate'

# Apply with custom values
terraform apply \
  -var 'cluster_name=my-eks-cluster' \
  -var 'compute_type=ec2' \
  -var 'node_instance_types=["t4g.medium"]' \
  -var 'node_desired_size=3'

# Apply with ON_DEMAND instances instead of SPOT
terraform apply \
  -var 'node_capacity_type=ON_DEMAND'

# Apply with restricted API access
terraform apply \
  -var 'cluster_endpoint_public_access_cidrs=["203.0.113.0/24","198.51.100.0/24"]'

# Apply with only private endpoint (no public access)
terraform apply \
  -var 'cluster_endpoint_public_access=false' \
  -var 'cluster_endpoint_private_access=true'
```

### 4. Configure kubectl

After the cluster is created, configure kubectl to connect to your cluster:

```shell
# Use the output command
aws eks update-kubeconfig --region <region> --name <cluster-name>

# Or use the terraform output
terraform output -raw configure_kubectl | bash
```

### 5. Verify the Cluster

```shell
# Check cluster status
kubectl cluster-info

# Get nodes
kubectl get nodes

# For EC2: You should see your EC2 instances
# For Fargate: Nodes will appear when you deploy pods to Fargate namespaces
```

### 6. Deploy a Test Application

```shell
# Deploy a simple nginx pod
kubectl create deployment nginx --image=nginx

# Expose it as a service
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Get the service
kubectl get svc nginx
```

### 7. Clean Up

When you're done, destroy all resources:

```shell
terraform destroy
```

## Important Notes

### EC2 Compute Type

- Nodes run in private subnets for security
- Default instance type is `t4g.small` (Graviton2/ARM64) for cost efficiency
- Default capacity type is `SPOT` for significant cost savings (can be changed to `ON_DEMAND`)
- EC2 instances are automatically named with the pattern `${cluster_name}-node`
- SSH access is optional (set `node_key_pair` variable)
- Auto-scaling is configured based on `node_min_size`, `node_desired_size`, and `node_max_size`
- Nodes are managed by AWS EKS and automatically join the cluster

### Fargate Compute Type

- Pods run on Fargate only in specified namespaces (see `fargate_namespaces`)
- No node management required - AWS handles the infrastructure
- Pods in other namespaces will not run unless you create additional Fargate profiles
- Fargate profiles are created for each namespace specified in `fargate_namespaces`
- **CoreDNS Fargate Profile**: A dedicated Fargate profile is automatically created for CoreDNS when `kube-system` is in `fargate_namespaces`. This profile uses label selectors (`k8s-app=kube-dns`) as recommended by AWS documentation
- **Automatic CoreDNS Rollout**: After the CoreDNS Fargate profile is created and active, Terraform automatically triggers a rollout restart of the CoreDNS deployment to reschedule pods on Fargate
   - See [Fargate and coredns](https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns) for more details
- **Fargate Architecture**: The `fargate_architecture` variable documents your architecture preference. **Important**: Fargate architecture is determined by your container image architecture, NOT by node selectors. 
  
  **How to use multi-arch images:**
  - Multi-arch images (Docker manifest lists) automatically work - just use your normal image tag:
    ```yaml
    image: myapp:latest        # Works! Runtime selects correct architecture
    image: myapp:v1.0.0       # Works! Runtime selects correct architecture
    ```
  - The container runtime (containerd) automatically pulls the architecture variant that matches Fargate's available architectures
  - No special tags or configuration needed - the registry and runtime handle it automatically
  
  **For single-arch images:**
  - Use architecture-specific tags: `myapp:arm64` or `myapp:amd64`
  
  **Do NOT add node selectors** - Fargate profiles cannot satisfy architecture-based node selectors and pods will fail to schedule

### Networking

- The VPC is configured with public and private subnets across multiple availability zones
- Public subnets have internet access via Internet Gateway
- Private subnets have outbound internet access via NAT Gateways
- EKS cluster endpoints are configured for both private and public access

### Security

- All required IAM roles and policies are created automatically
- Cluster logging is enabled for audit and troubleshooting
- Nodes run in private subnets (for EC2)
- Security groups are automatically configured by EKS
- **API Endpoint Access Control**: You can restrict public API access using `cluster_endpoint_public_access_cidrs`
  - By default, public endpoint allows all traffic (`0.0.0.0/0`)
  - Restrict to specific CIDR ranges for enhanced security
  - Set to empty list `[]` to disable public access entirely (requires private endpoint)
  - Private endpoint access is always from within the VPC

## Troubleshooting

### Cluster Creation Fails

- Ensure your AWS credentials have sufficient permissions
- Check that the specified region supports EKS
- Verify that the Kubernetes version is supported in your region

### Cannot Connect to Cluster

- Run `aws eks update-kubeconfig` to refresh credentials
- Verify your AWS credentials are valid: `aws sts get-caller-identity`
- Check that the cluster status is "ACTIVE" in the AWS console

### Fargate Pods Not Starting

- Ensure pods are deployed to namespaces specified in `fargate_namespaces`
- Check Fargate profile status: `aws eks describe-fargate-profile --cluster-name <name> --fargate-profile-name <profile-name>`
- Verify pod execution role has correct permissions

### CoreDNS Pods Not Scheduling on Fargate

If CoreDNS pods are not scheduling on Fargate:

1. **Verify the CoreDNS Fargate profile exists and is active:**
   ```bash
   aws eks describe-fargate-profile --cluster-name <cluster-name> --fargate-profile-name coredns --region <region>
   ```

2. **Manually restart the CoreDNS deployment** (if automatic rollout didn't work):
   ```bash
   kubectl rollout restart -n kube-system deployment coredns
   kubectl rollout status -n kube-system deployment coredns
   ```

3. **Check CoreDNS pod status:**
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   kubectl describe pod -n kube-system -l k8s-app=kube-dns
   ```

4. **Verify the Fargate profile selectors match CoreDNS:**
   The CoreDNS Fargate profile should have:
   - Namespace: `kube-system`
   - Labels: `k8s-app=kube-dns`
   
   This is automatically configured when `kube-system` is in `fargate_namespaces`.

**Note**: Terraform automatically triggers a CoreDNS rollout restart after the Fargate profile is created. If you need to manually trigger it, use the command in step 2.

### EC2 Nodes Not Joining Cluster

- Check node group status in AWS console
- Verify IAM roles and policies are attached correctly
- Review CloudWatch logs for node group issues

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider - EKS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

