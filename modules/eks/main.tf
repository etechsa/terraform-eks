# modules/eks/main.tf
# EKS 클러스터 생성 모듈
# 마스터 노드와 컨트롤 플레인을 관리하는 EKS 클러스터를 생성

# ==================================================
# EKS 클러스터 IAM 역할 설정
# ==================================================

# EKS 서비스가 사용할 IAM 역할 생성
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.prefix}-eks-cluster-role"

  # EKS 서비스가 이 역할을 사용할 수 있도록 허용
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

# EKS 서비스가 역할을 사용할 수 있도록 하는 신뢰 정책
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]  # 역할 사용 권한
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]  # EKS 서비스만 사용 가능
    }
  }
}

# EKS 클러스터 운영에 필요한 AWS 관리형 정책 연결
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"  # EKS 클러스터 관리 권한
}

# ==================================================
# EKS 접근 제어 설정 (AWS 콘솔 접근용)
# ==================================================

# 현재 사용자 정보 조회
data "aws_caller_identity" "current" {}

# 클러스터 생성자를 관리자로 등록
resource "aws_eks_access_entry" "cluster_creator" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_creator_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.cluster_creator.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_cluster.this]
}

# 서비스 계정을 EKS 클러스터에 등록
resource "aws_eks_access_entry" "service_account" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.service_account_role_arn  # 서비스 계정 IAM Role ARN
  type          = "STANDARD"                    # 표준 접근 엔트리
}

# 서비스 계정에 클러스터 관리자 권한 부여
resource "aws_eks_access_policy_association" "service_account_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.service_account.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"  # 클러스터 관리자 정책

  access_scope {
    type = "cluster"  # 전체 클러스터에 대한 권한
  }

  depends_on = [aws_eks_cluster.this]  # 클러스터 생성 후 실행
}

# ==================================================
# EKS 클러스터 생성
# ==================================================

# EKS 클러스터 리소스 생성
resource "aws_eks_cluster" "this" {
  name     = "${var.prefix}-eks"                # 클러스터 이름
  role_arn = aws_iam_role.eks_cluster_role.arn   # 클러스터가 사용할 IAM 역할
  version  = var.kubernetes_version              # Kubernetes 버전

  # 네트워크 설정
  vpc_config {
    subnet_ids              = var.private_subnet_ids  # 프라이빗 서브넷에 배치 (보안 강화)
  }
  
  # 인증 모드 설정
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"  # API와 ConfigMap 둘 다 사용
  }

  # IAM 역할 정책 연결 후 생성
  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}