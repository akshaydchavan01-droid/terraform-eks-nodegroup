# -------------------------------
# EKS CLUSTER IAM ROLE
# -------------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# -------------------------------
# EKS CLUSTER
# -------------------------------
resource "aws_eks_cluster" "ankit_cluster-v02" {
  name     = "ankit-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = [
      "subnet-0a478f54566f47171",
      "subnet-0c89c6986d0ee79f3"
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

# -------------------------------
# NODE GROUP IAM ROLE
# -------------------------------
resource "aws_iam_role" "worker_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach required policies
resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# -------------------------------
# NODE GROUP
# -------------------------------
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.ankit_cluster-v02.name
  node_group_name = "pc-node-group-v06"
  node_role_arn   = aws_iam_role.worker_role.arn

  subnet_ids = [
    "subnet-0a478f54566f47171",
    "subnet-0c89c6986d0ee79f3"
  ]

  instance_types = ["t3.medium"]
  disk_size      = 20
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy
  ]
}

# -------------------------------
# OUTPUTS
# -------------------------------
output "cluster_endpoint" {
  value = aws_eks_cluster.ankit_cluster-v02.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.ankit_cluster-v02.name
}
