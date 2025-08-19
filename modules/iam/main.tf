# modules/iam/main.tf
# IAM 사용자 및 역할 생성 모듈
# EKS 클러스터 관리에 필요한 IAM 리소스들을 자동 생성

# ==================================================
# 개발자 IAM 사용자 생성
# ==================================================

resource "aws_iam_user" "developer" {
  name = "${var.prefix}-developer"
  path = "/"

  tags = {
    Name = "${var.prefix}-developer"
    Role = "Developer"
  }
}

# 개발자 사용자용 액세스 키 생성
resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

# 개발자 사용자에게 EKS 관리 권한 부여
resource "aws_iam_user_policy_attachment" "developer_eks" {
  user       = aws_iam_user.developer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ==================================================
# 서비스 계정 IAM 역할 생성
# ==================================================

resource "aws_iam_role" "service_account" {
  name = "${var.prefix}-service-account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Name = "${var.prefix}-service-account"
    Role = "ServiceAccount"
  }
}

# 서비스 계정 역할에 EKS 관리 권한 부여
resource "aws_iam_role_policy_attachment" "service_account_eks" {
  role       = aws_iam_role.service_account.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ==================================================
# EC2 키페어 생성
# ==================================================

# TLS 프라이빗 키 생성
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# AWS EC2 키페어 생성
resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.prefix}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh

  tags = {
    Name = "${var.prefix}-key"
  }
}

# ==================================================
# Bastion 서버 IAM 역할 생성
# ==================================================

resource "aws_iam_role" "bastion_role" {
  name = "${var.prefix}-bastion-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.prefix}-bastion-server-role"
    Role = "Bastion"
  }
}

# Bastion 서버가 EKS 클러스터에 접근할 수 있도록 필요한 권한들
resource "aws_iam_role_policy_attachment" "bastion_eks_cluster_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "bastion_eks_worker_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "bastion_eks_service_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# EKS 클러스터 조회 및 kubeconfig 설정을 위한 커스텀 정책
resource "aws_iam_role_policy" "bastion_eks_access" {
  name = "${var.prefix}-bastion-server-eks-access"
  role = aws_iam_role.bastion_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:ListClusters",
          "eks:DescribeCluster",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:ListUpdates",
          "eks:DescribeUpdate"
        ]
        Resource = "*"
      }
    ]
  })
}

# Bastion 인스턴스 프로파일
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.prefix}-bastion-server-instance-profile"
  role = aws_iam_role.bastion_role.name
}

# 현재 AWS 계정 정보 조회
data "aws_caller_identity" "current" {}