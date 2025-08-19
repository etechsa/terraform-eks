# main.tf
# EKS 클러스터 인프라 구성을 위한 메인 진입점
# 각 모듈을 호출하여 전체 EKS 환경을 구성

# Terraform 및 Provider 버전 요구사항 정의
terraform {
  required_version = ">= 1.4.0"  # Terraform 최소 버전
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # AWS Provider 5.x 버전 사용
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"  # HTTP Provider (사용자 IP 조회용)
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"  # TLS Provider (키페어 생성용)
    }

  }
}

# AWS Provider 설정
provider "aws" {
  region = var.aws_region  # 변수로 정의된 AWS 리전 사용
}

# IAM 사용자 및 역할 생성 모듈
# EKS 클러스터 관리에 필요한 IAM 리소스들을 자동 생성
module "iam" {
  source = "./modules/iam"  # IAM 모듈 경로
  prefix = var.prefix       # 리소스 이름 접두사
}

# VPC 및 네트워크 인프라 생성 모듈
# 전체 네트워크 환경을 구성 (VPC, 서브넷, NAT Gateway, 보안그룹 등)
module "vpc" {
  source     = "./modules/vpc"  # VPC 모듈 경로
  prefix     = var.prefix       # 리소스 이름 접두사
  aws_region = var.aws_region   # AWS 리전
}

# EKS 클러스터 생성 모듈
# 마스터 노드와 컨트롤 플레인을 구성
module "eks" {
  source             = "./modules/eks"                # EKS 모듈 경로
  prefix             = var.prefix                     # 리소스 이름 접두사
  vpc_id             = module.vpc.vpc_id              # VPC 모듈에서 생성된 VPC ID
  private_subnet_ids = module.vpc.private_subnet_ids  # VPC 모듈에서 생성된 프라이빗 서브넷들
  kubernetes_version = var.kubernetes_version         # Kubernetes 버전
  service_account_role_arn = module.iam.service_account_role_arn  # IAM 모듈에서 생성된 서비스 계정 Role ARN
  bastion_role_arn   = module.iam.bastion_role_arn         # IAM 모듈에서 생성된 Bastion 역할 ARN
  developer_user_arn = module.iam.developer_user_arn       # IAM 모듈에서 생성된 개발자 사용자 ARN
  depends_on         = [module.vpc, module.iam]       # VPC와 IAM 생성 후 실행
}

# EKS 워커 노드그룹 생성 모듈
# 실제 워크로드가 실행될 EC2 인스턴스들을 관리
module "nodegroup" {
  source                    = "./modules/nodegroup"                    # 노드그룹 모듈 경로
  prefix                    = var.prefix                               # 리소스 이름 접두사
  cluster_name              = module.eks.cluster_name                  # EKS 클러스터 이름 (의존성)
  node_instance_type        = var.node_instance_type                  # 워커 노드 인스턴스 타입
  subnet_ids                = module.vpc.private_subnet_ids            # VPC 모듈에서 생성된 모든 프라이빗 서브넷 사용 (3개 AZ)
  key_name                  = module.iam.key_pair_name                 # IAM 모듈에서 생성된 키페어
  bastion_security_group_id = module.vpc.bastion_security_group_id     # Bastion 보안그룹 ID
  nodegroup_security_group_id = module.vpc.nodegroup_security_group_id # 노드그룹 보안그룹 ID
  depends_on                = [module.vpc, module.eks]                             # EKS 클러스터 생성 후 실행
}

# Bastion 호스트 생성 모듈
# EKS 클러스터 관리를 위한 점프 서버 (kubectl, helm 등 도구 포함)
module "bastion" {
  source                    = "./modules/bastion"                    # Bastion 모듈 경로
  prefix                    = var.prefix                             # 리소스 이름 접두사
  public_subnet_id          = module.vpc.public_subnet_a_id          # VPC 모듈에서 생성된 퍼블릭 서브넷 A
  bastion_security_group_id = module.vpc.bastion_security_group_id   # VPC 모듈에서 생성된 보안 그룹
  key_name                      = module.iam.key_pair_name                 # IAM 모듈에서 생성된 키페어
  eks_cluster_name              = module.eks.cluster_name                  # EKS 클러스터 이름 (kubeconfig 설정용)
  aws_region                    = var.aws_region                           # AWS 리전 (AWS CLI 설정용)
  kubernetes_version            = var.kubernetes_version                   # Kubernetes 버전 (kubectl 다운로드용)
  bastion_instance_profile_name = module.iam.bastion_instance_profile_name # IAM 모듈에서 생성된 인스턴스 프로파일
  depends_on                = [module.vpc, module.eks]               # VPC와 EKS 생성 후 실행
}

# EKS 필수 애드온 설치 모듈
# vpc-cni, kube-proxy, coredns 등 클러스터 운영에 필요한 기본 구성요소
module "addons" {
  source             = "./modules/addons"       # 애드온 모듈 경로
  cluster_name       = module.eks.cluster_name  # EKS 클러스터 이름
  kubernetes_version = var.kubernetes_version   # Kubernetes 버전
  depends_on         = [module.eks]             # EKS 클러스터 생성 후 실행
}

# aws-auth ConfigMap은 수동으로 설정
# Bastion 서버에서 다음 명령어 실행:
# kubectl apply -f aws-auth-configmap.yaml