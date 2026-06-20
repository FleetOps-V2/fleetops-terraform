output "oidc_provider_arn" { value = aws_iam_openid_connect_provider.eks.arn }
output "oidc_provider_url" {
  # Strip https:// prefix — this is what IAM IRSA trust policies expect
  value = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}




