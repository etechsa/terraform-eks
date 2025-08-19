# modules/nodegroup/main.tf
# EKS 워커 노드 그룹 생성 모듈
# 실제 컴테이너 워크로드가 실행될 EC2 인스턴스들을 관리

# ==================================================
# 워커 노드 IAM 역할 설정
# ==================================================

# 워커 노드 EC2 인스턴스가 사용할 IAM 역할
resource "aws_iam_role" "node_role" {
  name = "${var.prefix}-eks-node-role"

  # EC2 서비스가 이 역할을 사용할 수 있도록 허용
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
}

# EC2 서비스가 역할을 사용할 수 있도록 하는 신뢰 정책
data "aws_iam_policy_document" "node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]  # 역할 사용 권한
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]  # EC2 서비스만 사용 가능
    }
  }
}

# 워커 노드 운영에 필요한 AWS 관리형 정책들 연결
resource "aws_iam_role_policy_attachment" "node_policy_attachments" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",        # EKS 워커 노드 기본 권한
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # ECR 이미지 다운로드 권한
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"              # VPC CNI 플러그인 권한
  ])
  role       = aws_iam_role.node_role.name
  policy_arn = each.key
}

# ==================================================
# EKS 노드 그룹 생성
# ==================================================

# EKS 워커 노드 그룹 리소스 생성
resource "aws_eks_node_group" "node_group" {
  cluster_name    = var.cluster_name                    # 연결할 EKS 클러스터 이름
  node_group_name = "${var.prefix}-eks-node-group"      # 노드 그룹 이름
  node_role_arn   = aws_iam_role.node_role.arn          # 노드가 사용할 IAM 역할
  subnet_ids      = var.subnet_ids                      # 노드가 배치될 서브넷들 (3개 AZ)

  # 오토 스케일링 설정
  scaling_config {
    desired_size = 1  # 희망 노드 수
    max_size     = 1  # 최대 노드 수
    min_size     = 1  # 최소 노드 수
  }

  instance_types = [var.node_instance_type]  # EC2 인스턴스 타입
  disk_size      = 20                        # EBS 루트 볼륨 크기 (GB)

  # Bastion에서 워커 노드로 SSH 접근을 허용
  remote_access {
    ec2_ssh_key               = var.key_name
    source_security_group_ids = [var.nodegroup_security_group_id]  # VPC 모듈에서 생성된 보안그룹 사용
  }
  
  # IAM 역할 정책 연결 후 생성
  depends_on = [aws_iam_role_policy_attachment.node_policy_attachments]
}