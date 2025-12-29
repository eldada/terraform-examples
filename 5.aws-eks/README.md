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

- `enable_ec2` - Enable EC2 node group (default: `true`)
- `enable_fargate` - Enable Fargate profiles (default: `false`)
- **Note**: You can enable both `enable_ec2` and `enable_fargate` simultaneously to have mixed compute types
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

When `enable_ec2 = true`:
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
- `ec2_node_labels` - Labels to apply to EC2 nodes for pod scheduling (default: `{"node-type": "ec2"}`)
- `ec2_node_taints` - Taints to apply to EC2 nodes to prevent unscheduled pods (default: `[]`)

**Note**: EC2 instances are automatically named with the pattern `${cluster_name}-node` via tags. When using Graviton instances (t4g, m6g, etc.), ensure `node_ami_type` is set to `AL2023_ARM_64_STANDARD`.

### Fargate-Specific Variables

When `enable_fargate = true`:
- `fargate_namespaces` - Kubernetes namespaces where pods will run on Fargate (default: `["default", "kube-system"]`). **This is the primary way to assign workloads to Fargate** - simply deploy pods to namespaces in this list.
- `fargate_pod_labels` - Optional pod labels for fine-grained Fargate scheduling within a namespace (default: `{}` - matches all pods). Only use if you need to selectively schedule some pods to Fargate within a namespace that also has EC2 workloads.
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
# Plan with default EC2 only
terraform plan

# Plan with Fargate only
terraform plan -var 'enable_ec2=false' -var 'enable_fargate=true'

# Plan with both EC2 and Fargate (mixed compute)
terraform plan -var 'enable_ec2=true' -var 'enable_fargate=true'

# Plan with custom variables
terraform plan \
  -var 'cluster_name=my-eks-cluster' \
  -var 'enable_ec2=true' \
  -var 'node_desired_size=3' \
  -var 'node_max_size=5'

# Plan with restricted API access (only allow specific CIDR ranges)
terraform plan \
  -var 'cluster_endpoint_public_access_cidrs=["203.0.113.0/24","198.51.100.0/24"]'
```

### 3. Apply the Configuration

```shell
# Apply with default settings (EC2 only)
terraform apply

# Apply with Fargate only
terraform apply -var 'enable_ec2=false' -var 'enable_fargate=true'

# Apply with both EC2 and Fargate (mixed compute)
terraform apply -var 'enable_ec2=true' -var 'enable_fargate=true'

# Apply with custom values
terraform apply \
  -var 'cluster_name=my-eks-cluster' \
  -var 'enable_ec2=true' \
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
- **EBS CSI Driver**: The EBS CSI driver addon is automatically installed when EC2 is enabled
  - Required for dynamic volume provisioning
  - Uses IAM role for service account (IRSA) for secure access
- **gp3 StorageClass**: A gp3 StorageClass is automatically created and set as default when EC2 is enabled
  - Uses EBS CSI driver (`ebs.csi.aws.com`)
  - Encrypted by default
  - Supports volume expansion
  - Volume binding mode: `WaitForFirstConsumer` (volumes are created when pods are scheduled)
  - **Note**: If your cluster has an existing default storage class (e.g., gp2), you may want to remove its default annotation to avoid conflicts:
    ```bash
    kubectl annotate storageclass gp2 storageclass.kubernetes.io/is-default-class- --overwrite
    ```

### Fargate Compute Type

- Pods run on Fargate only in specified namespaces (see `fargate_namespaces`)
- No node management required - AWS handles the infrastructure
- Pods in other namespaces will not run unless you create additional Fargate profiles
- Fargate profiles are created for each namespace specified in `fargate_namespaces`
- **CoreDNS Fargate Profile**: A dedicated Fargate profile is automatically created for CoreDNS when Fargate is enabled, EC2 is disabled, and `kube-system` is in `fargate_namespaces`. This profile uses label selectors (`k8s-app=kube-dns`) as recommended by AWS documentation. **Note**: If both EC2 and Fargate are enabled, this profile is NOT created because CoreDNS will run on EC2 nodes.
- **Automatic CoreDNS Rollout**: After the CoreDNS Fargate profile is created and active, Terraform automatically triggers a rollout restart of the CoreDNS deployment to reschedule pods on Fargate
   - **Note**: This restart only occurs when Fargate is enabled AND EC2 is disabled. If EC2 is enabled, CoreDNS will run on EC2 nodes and no restart is needed.
   - See [Fargate and coredns](https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns) for more details
- **Fargate Architecture**: The `fargate_architecture` variable documents your architecture preference. **Important**: Fargate architecture is determined by your container image architecture, NOT by node selectors.

## Assigning Workloads to Node Pools

When you have both EC2 and Fargate enabled, you can control which workloads run on each compute type using Kubernetes scheduling mechanisms.

### Assigning Pods to EC2 Nodes

**Simplest Method: Use Namespaces**

The easiest way to assign pods to EC2 is to deploy them to namespaces **NOT** in `fargate_namespaces`. Pods in non-Fargate namespaces will automatically run on EC2 nodes.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ec2-workloads
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: ec2-workloads  # This namespace is NOT in fargate_namespaces
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: myapp:latest
```

**Using nodeSelector (Optional)**

If you want explicit control or are deploying to a Fargate namespace, you can use `nodeSelector`. EC2 nodes have labels applied (default: `node-type: ec2`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: ec2-workloads  # Deploy to non-Fargate namespace
spec:
  template:
    spec:
      nodeSelector:
        node-type: ec2  # Matches the default EC2 node label
      containers:
      - name: my-app
        image: myapp:latest
```

#### Using nodeAffinity (Advanced)

For more complex scheduling rules, use `nodeAffinity`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-type
                operator: In
                values:
                - ec2
      containers:
      - name: my-app
        image: myapp:latest
```

#### Applying and Handling EC2 Node Taints

Taints are not directly configurable in the Terraform node group resource. To apply taints to EC2 nodes, use kubectl after the nodes are created:

```bash
# Apply a taint to all EC2 nodes
kubectl taint nodes -l node-type=ec2 dedicated=workload:NoSchedule

# Or apply to a specific node
kubectl taint node <node-name> dedicated=workload:NoSchedule
```

If you have taints on EC2 nodes, you must add matching tolerations to your pods:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      nodeSelector:
        node-type: ec2
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "workload"
        effect: "NoSchedule"
      containers:
      - name: my-app
        image: myapp:latest
```

### Assigning Pods to Fargate

**Simplest Method: Use Namespaces**

The easiest way to assign pods to Fargate is to deploy them to namespaces **in** `fargate_namespaces`. By default, all pods in these namespaces will run on Fargate.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fargate-apps
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: fargate-apps  # This namespace must be in fargate_namespaces
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: myapp:latest
```

**Note**: Make sure `fargate-apps` is added to the `fargate_namespaces` variable in Terraform, or use an existing namespace like `default` (if it's in `fargate_namespaces`).

**Using Pod Labels (Advanced - Optional)**

If `fargate_pod_labels` is configured (not empty), pods must have matching labels to run on Fargate. This is only needed if you want to selectively schedule some pods to Fargate within a namespace that also has EC2 workloads.

#### Method 2: Use Fargate Profile Label Selectors

If your Fargate profile has label selectors (like the CoreDNS profile), add matching labels to your pods:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: kube-system  # Must match Fargate profile namespace
spec:
  template:
    metadata:
      labels:
        k8s-app: kube-dns  # Matches Fargate profile label selector
    spec:
      containers:
      - name: my-app
        image: myapp:latest
```

**Important**: Do NOT use `nodeSelector` or `nodeAffinity` with Fargate - Fargate profiles cannot satisfy node selectors and pods will fail to schedule.

### Example: Mixed Workloads

Here's an example deploying different workloads to different compute types using namespaces:

```yaml
# Namespace for EC2 workloads
apiVersion: v1
kind: Namespace
metadata:
  name: ec2-workloads
---
# Namespace for Fargate workloads  
apiVersion: v1
kind: Namespace
metadata:
  name: fargate-workloads
---
# Workload 1: Runs on EC2 (deployed to EC2 namespace)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compute-intensive
  namespace: ec2-workloads  # NOT in fargate_namespaces
spec:
  template:
    spec:
      containers:
      - name: app
        image: compute-app:latest
        resources:
          requests:
            cpu: "2"
            memory: "4Gi"
---
# Workload 2: Runs on Fargate (deployed to Fargate namespace)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: fargate-workloads  # Must be in fargate_namespaces
spec:
  template:
    spec:
      containers:
      - name: app
        image: web-app:latest
        resources:
          requests:
            cpu: "250m"
            memory: "512Mi"
```

**Remember**: Add `fargate-workloads` to your `fargate_namespaces` variable in Terraform!

### Checking Node Labels

To see what labels are available on your nodes:

```bash
# List all nodes with their labels
kubectl get nodes --show-labels

# Get detailed information about a specific node
kubectl describe node <node-name>
```

### Terraform Outputs

The Terraform configuration provides outputs to help you reference node labels:

```bash
# Get EC2 node labels
terraform output ec2_node_labels

# Get EC2 node taints
terraform output ec2_node_taints
``` 
  
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

