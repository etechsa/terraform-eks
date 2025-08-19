# modules/bastion/main.tf
# Bastion EC2 인스턴스 생성

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Bastion 서버용 EIP 생성
resource "aws_eip" "bastion" {
  domain = "vpc"
  
  tags = {
    Name = "${var.prefix}-bastion-eip"
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = false  # EIP 사용으로 비활성화
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.bastion_security_group_id]
  iam_instance_profile        = var.bastion_instance_profile_name
  
  tags = {
    Name = "${var.prefix}-bastion"
  }

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    aws_region         = var.aws_region
    eks_cluster_name   = var.eks_cluster_name
    kubernetes_version = var.kubernetes_version
  })
}

# EIP를 Bastion 인스턴스에 연결
resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}