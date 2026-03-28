data "aws_subnets" "available-subnets"{
    filter {
        name = "vpc-id"
        values = ["vpc-09a556c54b16179a1"]
    }
}

resource "aws_eks_cluster" "ankit-cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.example.arn

  # हा ब्लॉक (Access Config) जोडा ✅
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = data.aws_subnets.available-subnets.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.ankit-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.ankit-cluster.certificate_authority[0].data
}

resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.ankit-cluster.name
  node_group_name = "pc-node-group-v05"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = data.aws_subnets.available-subnets.ids
  capacity_type   = "ON_DEMAND"
  disk_size       = "20"
  instance_types  = ["t3.medium"]
  labels = tomap({ env = "dev" })

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
    ]  
}
