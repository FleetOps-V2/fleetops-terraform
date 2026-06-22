locals {
  name_prefix  = "${var.project}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "eks/addons"
    Owner       = "FleetOps-Team"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "alb_controller" {
  name = "${local.name_prefix}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "alb_controller" {
  #checkov:skip=CKV_AWS_288:ALB Controller requires wildcard resource for ElasticLoadBalancing APIs
  #checkov:skip=CKV_AWS_289:ALB Controller requires resource management permissions for ALB provisioning
  #checkov:skip=CKV_AWS_290:ALB Controller requires write access to create/modify load balancers
  #checkov:skip=CKV_AWS_355:ALB Controller policy is AWS-recommended; wildcard resources are scoped by action type
  name        = "${local.name_prefix}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:SetWebAcl",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeAddresses",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:ModifyNetworkInterfaceAttribute",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:CreateServiceLinkedRole",
          "cognito-idp:DescribeUserPoolClient",
          "shield:GetSubscriptionState",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "wafv2:ListWebACLs",
          "waf-regional:GetWebACLForResource",
          "waf-regional:GetWebACL",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "tag:GetResources",
          "tag:TagResources"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "aws_iam_role" "cluster_autoscaler" {
  name = "${local.name_prefix}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  #checkov:skip=CKV_AWS_288:Cluster Autoscaler requires wildcard EC2 and autoscaling describe permissions
  #checkov:skip=CKV_AWS_290:Cluster Autoscaler requires write access to modify autoscaling groups
  #checkov:skip=CKV_AWS_355:Cluster Autoscaler policy follows AWS recommended pattern; autoscaling actions require wildcard
  name = "${local.name_prefix}-cluster-autoscaler-policy"
  role = aws_iam_role.cluster_autoscaler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DescribeInstanceTypes",
        "eks:DescribeNodegroup"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "external_secrets" {
  name = "${local.name_prefix}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "${local.name_prefix}-external-secrets-policy"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = var.kms_secrets_key_arn != "" ? var.kms_secrets_key_arn : "*"
      }
    ]
  })
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }
  set {
    name  = "region"
    value = var.aws_region
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  set {
    name  = "image.repository"
    value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/ecr-public/eks/aws-load-balancer-controller"
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets"
  version    = "0.9.19"

  create_namespace = true

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_secrets.arn
  }
  set {
    name  = "image.repository"
    value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/external-secrets"
  }
  set {
    name  = "webhook.image.repository"
    value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/external-secrets"
  }
  set {
    name  = "certController.image.repository"
    value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/external-secrets"
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"

  set {
    name  = "image.repository"
    value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/registry.k8s.io/metrics-server/metrics-server"
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }
  set {
    name  = "awsRegion"
    value = var.aws_region
  }
  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler.arn
  }
  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }
  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }
  set {
    name  = "image.repository"
    value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/registry.k8s.io/autoscaling/cluster-autoscaler"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "6.7.11"
  timeout          = 600
  force_update     = true
  wait             = false
  atomic           = false

  # ALB controller installs a ValidatingWebhookConfiguration that intercepts
  # Ingress objects. If ArgoCD installs before ALB controller pods are Ready,
  # the webhook call fails with "no endpoints available". Wait for it first.
  depends_on = [helm_release.aws_load_balancer_controller]

  values = [
    yamlencode({
      global = {
        image = {
          # Route all ArgoCD component images through ECR pull-through cache
          # (quay.io pull-through cache, no credentials required for public images)
          repository = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/quay.io/argoproj/argocd"
        }
      }
      dex = {
        # Dex is for OIDC/SSO only — not needed. Disable to avoid ghcr.io pull.
        enabled = false
      }
      redis = {
        image = {
          repository = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/ecr-public/docker/library/redis"
        }
      }
      server = {
        extraArgs = ["--insecure"] # TLS terminates at ALB; server runs plain HTTP internally
      }
    })
  ]
}

# Bootstrap the ArgoCD root Application via local-exec rather than
# kubernetes_manifest, which contacts the K8s API during plan to resolve CRD
# schemas — breaking plan when the EKS cluster does not yet exist.
# local-exec runs only on apply, and kubectl apply is idempotent.
resource "terraform_data" "argocd_root_app" {
  triggers_replace = [
    var.argocd_repo_url,
    var.cluster_name,
    var.environment,
  ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<EOT
aws eks update-kubeconfig --name "${var.cluster_name}" --region "${var.aws_region}"
kubectl apply -f - <<'MANIFEST'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fleetops-root-${var.environment}
  namespace: argocd
  labels:
    app.kubernetes.io/name: fleetops-root-${var.environment}
    app.kubernetes.io/environment: ${var.environment}
    app.kubernetes.io/component: root
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  project: default
  source:
    repoURL: ${var.argocd_repo_url}
    targetRevision: HEAD
    path: argocd/apps/${var.environment}
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
MANIFEST
EOT
  }

  depends_on = [helm_release.argocd, kubernetes_secret.argocd_repo]
}

# Without this addon, "Pods --> Metrics --> CloudWatch" does NOT work.
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = var.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  addon_version            = "v6.2.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.cloudwatch_agent.arn
  tags                     = local.common_tags

  # CloudWatch addon creates Service resources that trigger the ALB webhook.
  # Wait for ALB controller pods to be Running before starting the addon.
  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "aws_iam_role" "cloudwatch_agent" {
  name = "${local.name_prefix}-cloudwatch-agent-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Recreated automatically on every terraform apply — no manual kubectl needed.
# Token is stored in Secrets Manager, never in Git or tfvars.
data "aws_secretsmanager_secret_version" "github_pat" {
  secret_id = "${var.project}/${var.environment}/github-pat"
}

resource "kubernetes_secret" "argocd_repo" {
  metadata {
    name      = "argocd-repo-fleetops-deployments"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = {
    type     = "git"
    url      = "https://github.com/FleetOps-V2/fleetops-deployments.git"
    username = jsondecode(data.aws_secretsmanager_secret_version.github_pat.secret_string)["username"]
    password = jsondecode(data.aws_secretsmanager_secret_version.github_pat.secret_string)["token"]
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_namespace" "fleetops_prod" {
  count = var.bedrock_access_key != "" ? 1 : 0

  metadata {
    name = "fleetops-prod"
  }

  lifecycle {
    # ArgoCD adds its own labels/annotations to the namespace — ignore them to avoid perpetual drift
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_secret" "bedrock" {
  count = var.bedrock_access_key != "" ? 1 : 0

  metadata {
    name      = "fleetops-bedrock-secret"
    namespace = kubernetes_namespace.fleetops_prod[0].metadata[0].name
  }
  data = {
    BEDROCK_ACCESS_KEY = var.bedrock_access_key
    BEDROCK_SECRET_KEY = var.bedrock_secret_key
  }
}

resource "kubernetes_ingress_v1" "argocd" {
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/certificate-arn"  = var.acm_certificate_arn
      "alb.ingress.kubernetes.io/group.name"       = "fleetops"
      "alb.ingress.kubernetes.io/security-groups"  = var.alb_sg_id
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      host = "argocd.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.argocd, helm_release.aws_load_balancer_controller]
}

resource "aws_iam_role" "efs_csi_driver" {
  name = "${local.name_prefix}-efs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:efs-csi-controller-sa"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  role       = aws_iam_role.efs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-efs-csi-driver"
  addon_version            = "v2.0.7-eksbuild.1"
  service_account_role_arn = aws_iam_role.efs_csi_driver.arn
  tags                     = local.common_tags

  depends_on = [helm_release.aws_load_balancer_controller]
}

# aws-for-fluent-bit EKS managed addon is not supported on Kubernetes 1.31.
# Log shipping is handled by the amazon-cloudwatch-observability addon above,
# which bundles the CloudWatch agent and Fluent Bit in a single package.
# The IAM role below is retained for when Fluent Bit is deployed via Helm.

resource "aws_iam_role" "fluent_bit" {
  name = "${local.name_prefix}-fluent-bit-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:amazon-cloudwatch:fluent-bit"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy" "fluent_bit_logs" {
  name = "${local.name_prefix}-fluent-bit-policy"
  role = aws_iam_role.fluent_bit.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}




