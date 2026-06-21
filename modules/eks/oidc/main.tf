# =============================================================
# Module: eks/oidc  |  Phase: 2B
# Creates the OIDC Identity Provider for IRSA
# Must run AFTER eks/cluster — depends on the OIDC issuer URL
# =============================================================

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list = ["sts.amazonaws.com"]
  # AWS validates EKS OIDC against its own root CAs — the thumbprint is not
  # actually checked. A static value prevents tls_certificate data-source drift
  # (the live fingerprint changes whenever AWS rotates the cert in the chain).
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = var.oidc_issuer_url

  lifecycle {
    ignore_changes = [thumbprint_list]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "eks/oidc"
    Owner       = "FleetOps-Team"
  }
}




