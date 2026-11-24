# EKS Auto Mode Cluster

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  bootstrap_self_managed_addons = false #Disable normal self-managed nodes

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Enable EKS Auto Mode (AWS-managed Karpenter compute, networking, and storage)
  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.node.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.compute_policy,
    aws_iam_role_policy_attachment.block_storage_policy,
    aws_iam_role_policy_attachment.load_balancing_policy,
    aws_iam_role_policy_attachment.networking_policy,
    aws_iam_role_policy_attachment.node_minimal,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}

# Access provider for extra IAM principals cluster-admin access
# Example: admin_principal_arns = ["arn:aws:iam::123456789012:role/github-actions", "arn:aws:iam::123456789012:user/teammate"]
resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}
