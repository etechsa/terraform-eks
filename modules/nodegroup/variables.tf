# modules/nodegroup/variables.tf
# EKS 노드그룹 모듈 입력 변수 정의

# ==================================================
# 기본 설정
# ==================================================

variable "prefix" {
  description = "노드그룹 리소스 이름에 사용될 접두사"
  type        = string
}

variable "cluster_name" {
  description = "노드그룹이 연결될 EKS 클러스터 이름"
  type        = string
}

# ==================================================
# 인스턴스 설정
# ==================================================

variable "node_instance_type" {
  description = "워커 노드 EC2 인스턴스 타입 (워크로드에 따라 선택)"
  type        = string
  default     = "t3.medium"  # 2 vCPU, 4GB RAM
}



variable "key_name" {
  description = "워커 노드 EC2 인스턴스에 연결할 키페어 이름 (SSH 접근용)"
  type        = string
}

# ==================================================
# 네트워크 설정
# ==================================================

variable "subnet_ids" {
  description = "워커 노드가 배치될 프라이빗 서브넷 ID 리스트 (3개 AZ 분산용)"
  type        = list(string)
}

variable "bastion_security_group_id" {
  description = "Bastion 호스트의 보안 그룹 ID (워커 노드 SSH 접근 허용용)"
  type        = string
}

variable "nodegroup_security_group_id" {
  description = "EKS 노드그룹용 보안그룹 ID (VPC 모듈에서 생성)"
  type        = string
}
