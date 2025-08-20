# outputs.tf
# 주요 출력값 정의

output "eks_cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "node_role_arn" {
  description = "EKS 노드 그룹 IAM 역할 ARN"
  value       = module.nodegroup.node_role_arn
}

output "bastion_instance_id" {
  description = "Bastion EC2 인스턴스 ID"
  value       = module.bastion.instance_id
}

output "bastion_public_ip" {
  description = "Bastion 퍼블릭 IP"
  value       = module.bastion.public_ip
}

output "private_key_pem" {
  description = "SSH 접속용 프라이빗 키 (PEM 형식)"
  value       = module.iam.private_key_pem
  sensitive   = true
}

output "ssh_connection_command" {
  description = "Bastion 서버 SSH 접속 명령어"
  value       = "ssh -i etech-hatiolab-key.pem ec2-user@${module.bastion.public_ip}"
}