# modules/addons/main.tf
# EKS 주요 애드온 설치

# 공통 설정
locals {
  common_addon_config = {
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"
  }
}

# 애드온 버전 동적 조회
data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

data "aws_eks_addon_version" "ebs_csi_driver" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

data "aws_eks_addon_version" "pod_identity_agent" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

# 애드온 리소스
resource "aws_eks_addon" "vpc_cni" {
  cluster_name       = var.cluster_name
  addon_name         = "vpc-cni"
  addon_version      = data.aws_eks_addon_version.vpc_cni.version
  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"   # Prefix Delegation 활성화
    }
  })
  resolve_conflicts_on_create = local.common_addon_config.resolve_conflicts_on_create
  resolve_conflicts_on_update = local.common_addon_config.resolve_conflicts_on_update
  
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name    = var.cluster_name
  addon_name      = "kube-proxy"
  addon_version   = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts_on_create = local.common_addon_config.resolve_conflicts_on_create
  resolve_conflicts_on_update = local.common_addon_config.resolve_conflicts_on_update
}

resource "aws_eks_addon" "coredns" {
  cluster_name    = var.cluster_name
  addon_name      = "coredns"
  addon_version   = data.aws_eks_addon_version.coredns.version
  resolve_conflicts_on_create = local.common_addon_config.resolve_conflicts_on_create
  resolve_conflicts_on_update = local.common_addon_config.resolve_conflicts_on_update
  
  depends_on = [aws_eks_addon.vpc_cni]
  
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name    = var.cluster_name
  addon_name      = "aws-ebs-csi-driver"
  addon_version   = data.aws_eks_addon_version.ebs_csi_driver.version
  resolve_conflicts_on_create = local.common_addon_config.resolve_conflicts_on_create
  resolve_conflicts_on_update = local.common_addon_config.resolve_conflicts_on_update
  
  depends_on = [aws_eks_addon.vpc_cni]
  
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name    = var.cluster_name
  addon_name      = "eks-pod-identity-agent"
  addon_version   = data.aws_eks_addon_version.pod_identity_agent.version
  resolve_conflicts_on_create = local.common_addon_config.resolve_conflicts_on_create
  resolve_conflicts_on_update = local.common_addon_config.resolve_conflicts_on_update
}
