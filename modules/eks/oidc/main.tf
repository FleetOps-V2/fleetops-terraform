# =============================================================
# Module: eks/oidc  |  Phase: 2B
# Creates the OIDC Identity Provider for IRSA
# Must run AFTER eks/cluster — depends on the OIDC issuer URL
# =============================================================

data "tls_certificate" "eks" {
  url = var.oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = var.oidc_issuer_url

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "eks/oidc"
    Owner       = "FleetOps-Team"
  }
}




