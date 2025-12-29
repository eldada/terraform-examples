# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policy to EKS Cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Create EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = var.tags
}

# IAM Role for EKS Node Group (EC2)
resource "aws_iam_role" "eks_node_group" {
  count = var.enable_ec2 ? 1 : 0
  name  = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policies to Node Group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count      = var.enable_ec2 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.enable_ec2 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  count      = var.enable_ec2 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group[0].name
}

# Create EKS Node Group (EC2)
resource "aws_eks_node_group" "main" {
  count           = var.enable_ec2 ? 1 : 0
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group[0].arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.node_instance_types
  disk_size       = var.node_disk_size
  capacity_type   = var.node_capacity_type
  ami_type        = var.node_ami_type

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  dynamic "remote_access" {
    for_each = var.node_key_pair != "" ? [1] : []
    content {
      ec2_ssh_key = var.node_key_pair
    }
  }

  update_config {
    max_unavailable = 1
  }

  # Labels for pod scheduling (nodeSelector/nodeAffinity)
  labels = var.ec2_node_labels

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only
  ]

  # Tags will propagate to EC2 instances, including Name tag
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-node"
    }
  )
}

# Data source for EKS cluster OIDC issuer URL
data "tls_certificate" "eks" {
  count    = var.enable_ec2 ? 1 : 0
  url      = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

# Create OIDC provider for the cluster (required for IRSA)
resource "aws_iam_openid_connect_provider" "eks" {
  count           = var.enable_ec2 ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  tags = var.tags
}

# IAM Role for EBS CSI Driver Addon (using IRSA)
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_ec2 ? 1 : 0
  name  = "${var.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policy for EBS CSI driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  count      = var.enable_ec2 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}

# Install EBS CSI Driver Addon
resource "aws_eks_addon" "ebs_csi_driver" {
  count                    = var.enable_ec2 ? 1 : 0
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = null # Use latest compatible version
  service_account_role_arn = aws_iam_role.ebs_csi_driver[0].arn

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy,
    aws_iam_openid_connect_provider.eks
  ]

  tags = var.tags
}

# Create gp3 StorageClass and set it as default
resource "kubernetes_storage_class" "gp3" {
  count = var.enable_ec2 ? 1 : 0

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [
    aws_eks_addon.ebs_csi_driver
  ]
}

# IAM Role for Fargate Pod Execution
resource "aws_iam_role" "fargate_pod_execution" {
  count = var.enable_fargate ? 1 : 0
  name  = "${var.cluster_name}-fargate-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policy to Fargate Pod Execution role
resource "aws_iam_role_policy_attachment" "fargate_pod_execution_role_policy" {
  count      = var.enable_fargate ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution[0].name
}

# Create Fargate Profiles for general namespaces
resource "aws_eks_fargate_profile" "main" {
  count                  = var.enable_fargate ? length(var.fargate_namespaces) : 0
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name    = "${var.cluster_name}-fargate-${replace(var.fargate_namespaces[count.index], "_", "-")}"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution[0].arn
  subnet_ids             = aws_subnet.private[*].id

  selector {
    namespace = var.fargate_namespaces[count.index]
    # Match all pods in the namespace by default (empty labels map = {} matches all)
    # Add labels only if you need fine-grained control within a namespace
    labels = var.fargate_pod_labels
  }

  depends_on = [
    aws_iam_role_policy_attachment.fargate_pod_execution_role_policy
  ]

  tags = var.tags
}

# Create dedicated Fargate profile for CoreDNS
# According to AWS documentation, CoreDNS needs a specific profile with label selectors
# See: https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns
# Only create this when Fargate is enabled AND EC2 is disabled (if EC2 is enabled, CoreDNS will run on EC2 nodes)
resource "aws_eks_fargate_profile" "coredns" {
  count                  = var.enable_fargate && !var.enable_ec2 && contains(var.fargate_namespaces, "kube-system") ? 1 : 0
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "coredns"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution[0].arn
  subnet_ids             = aws_subnet.private[*].id

  selector {
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kube-dns"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.fargate_pod_execution_role_policy
  ]

  tags = var.tags
}

# Trigger CoreDNS rollout restart after Fargate profile is created
# This ensures CoreDNS pods are rescheduled to run on Fargate
# Only needed when Fargate is enabled and EC2 is disabled (if EC2 is enabled, CoreDNS will run on EC2 nodes)
resource "null_resource" "restart_coredns" {
  count = var.enable_fargate && !var.enable_ec2 && contains(var.fargate_namespaces, "kube-system") ? 1 : 0

  triggers = {
    fargate_profile_id = aws_eks_fargate_profile.coredns[0].id
    cluster_name       = aws_eks_cluster.eks_cluster.name
    region             = var.region
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for Fargate profile to be active
      echo "Waiting for CoreDNS Fargate profile to be active..."
      aws eks wait fargate-profile-active \
        --cluster-name ${aws_eks_cluster.eks_cluster.name} \
        --fargate-profile-name coredns \
        --region ${var.region} || true
      
      # Configure kubectl
      aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.eks_cluster.name}
      
      # Restart CoreDNS deployment to trigger rescheduling on Fargate
      echo "Restarting CoreDNS deployment..."
      kubectl rollout restart -n kube-system deployment coredns || echo "CoreDNS deployment may not exist yet"
      
      # Wait for rollout to complete
      echo "Waiting for CoreDNS rollout to complete..."
      kubectl rollout status -n kube-system deployment coredns --timeout=300s || true
    EOT
  }

  depends_on = [
    aws_eks_fargate_profile.coredns,
    aws_eks_cluster.eks_cluster
  ]
}

# Add EKS Cluster to AWS Auth ConfigMap (for EC2 nodes)
# This is handled automatically by EKS, but we can add additional users/roles here if needed
data "aws_caller_identity" "current" {}

