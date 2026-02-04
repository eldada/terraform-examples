# Region
variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-central-1"
}

# Cluster configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "example-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.35"
}

# VPC configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "nat_gateway_mode" {
  description = <<-EOT
    NAT Gateway deployment mode:
    - "single": One NAT Gateway in the first AZ (cost-effective, suitable for dev/test)
    - "ha": One NAT Gateway per AZ for high availability (recommended for production)
    
    Cost implications:
    - Single: ~$32/month + data processing charges
    - HA (2 AZs): ~$64/month + data processing charges
    - HA (3 AZs): ~$96/month + data processing charges
    
    Availability implications:
    - Single: If the AZ with the NAT Gateway fails, private subnet egress in other AZs is unavailable
    - HA: Each AZ has independent egress; AZ failure only affects that AZ's resources
  EOT
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "ha"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be either 'single' or 'ha'."
  }
}

# Compute type - you can enable both EC2 and Fargate simultaneously
variable "enable_ec2" {
  description = "Enable EC2 node group for the cluster"
  type        = bool
  default     = true
}

variable "enable_fargate" {
  description = "Enable Fargate profiles for the cluster"
  type        = bool
  default     = false
}

# EC2 Node Group configuration (only used when enable_ec2 is true)
variable "node_instance_types" {
  description = "Instance types for the EKS node group"
  type        = list(string)
  default     = ["t4g.small"]
}

variable "node_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "SPOT"
  
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be either 'ON_DEMAND' or 'SPOT'."
  }
}

variable "node_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group. For Graviton/ARM instances use AL2023_ARM_64_STANDARD, for x86_64 use AL2023_x86_64_STANDARD"
  type        = string
  default     = "AL2023_ARM_64_STANDARD"
  
  validation {
    condition     = contains(["AL2023_ARM_64_STANDARD", "AL2023_x86_64_STANDARD", "AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA", "WINDOWS_CORE_2019_x86_64", "WINDOWS_FULL_2019_x86_64", "WINDOWS_CORE_2022_x86_64", "WINDOWS_FULL_2022_x86_64"], var.node_ami_type)
    error_message = "node_ami_type must be a valid EKS AMI type."
  }
}

variable "node_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 0
}

variable "node_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Disk size in GB for the node group instances"
  type        = number
  default     = 20
}

variable "node_key_pair" {
  description = "EC2 Key Pair name for SSH access to nodes (optional)"
  type        = string
  default     = ""
}

variable "ec2_node_labels" {
  description = "Labels to apply to EC2 nodes for pod scheduling (nodeSelector/nodeAffinity)"
  type        = map(string)
  default = {
    "node-type" = "ec2"
  }
}

variable "ec2_node_taints" {
  description = "Taints to apply to EC2 nodes (applied via Kubernetes after node creation). Format: list of objects with 'key', 'value' (optional), and 'effect' ('NoSchedule', 'PreferNoSchedule', or 'NoExecute')"
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []
}

# Fargate Profile configuration (only used when enable_fargate is true)
variable "fargate_namespaces" {
  description = "List of Kubernetes namespaces for Fargate profile"
  type        = list(string)

  # NOTE: If EC2 is enabled, you don't need to include "kube-system" in this list,
  # as CoreDNS and other kube-system pods will run on EC2 nodes.
  # If only Fargate is enabled, include "kube-system" so a dedicated CoreDNS Fargate profile is created (see README for details).
  default     = ["default", "kube-system"]
}

variable "fargate_pod_labels" {
  description = "Pod labels that must match for Fargate scheduling. Set to empty map {} (default) to match all pods in Fargate namespaces. Use labels only if you need fine-grained control within a namespace."
  type        = map(string)
  default     = {}
}

variable "fargate_architecture" {
  description = "CPU architecture preference for Fargate pods: 'arm64' (Graviton) or 'amd64' (x86_64). Note: Fargate architecture is determined by your container image architecture, not node selectors. Use this variable for documentation/reference purposes. To use a specific architecture, ensure your container images are built for that architecture (e.g., use multi-arch images or architecture-specific image tags)."
  type        = string
  default     = "arm64"
  
  validation {
    condition     = contains(["arm64", "amd64"], var.fargate_architecture)
    error_message = "fargate_architecture must be either 'arm64' or 'amd64'."
  }
}

# EKS API endpoint access configuration
variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint. If not specified, defaults to 0.0.0.0/0 (all traffic). Set to empty list [] to restrict all public access."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "deploy_metrics_server" {
  description = "Deploy the metrics server for the EKS cluster"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

