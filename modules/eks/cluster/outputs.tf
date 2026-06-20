output "cluster_name"              { value = aws_eks_cluster.main.name }
output "cluster_arn"               { value = aws_eks_cluster.main.arn }
output "cluster_endpoint"          { value = aws_eks_cluster.main.endpoint }
output "cluster_ca_data"           { value = aws_eks_cluster.main.certificate_authority[0].data }
output "cluster_version"           { value = aws_eks_cluster.main.version }
output "cluster_role_arn"          { value = aws_iam_role.eks_cluster.arn }
output "oidc_issuer_url" {
  description = "OIDC issuer URL — used by the oidc module to create the OIDC provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_sg_id" {
  description = "Auto-created EKS cluster security group — attached to all managed nodes and pods"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}




