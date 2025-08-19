# modules/vpc/main.tf
# VPC 및 네트워크 인프라 생성 모듈
# EKS 클러스터를 위한 완전한 네트워크 환경 구성

# ==================================================
# 현재 사용자 IP 조회 (보안그룹 설정용)
# ==================================================

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  my_ip = "${chomp(data.http.myip.response_body)}/32"
}

# ==================================================
# VPC 생성
# ==================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# ==================================================
# 인터넷 게이트웨이
# ==================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

# ==================================================
# 퍼블릭 서브넷 (a, c, d zone)
# ==================================================

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet-a"
    Type = "Public"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet-c"
    Type = "Public"
  }
}

resource "aws_subnet" "public_d" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.aws_region}d"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet-d"
    Type = "Public"
  }
}

# ==================================================
# 프라이빗 서브넷 (a, c, d zone)
# ==================================================

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.prefix}-private-subnet-a"
    Type = "Private"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.prefix}-private-subnet-c"
    Type = "Private"
  }
}

resource "aws_subnet" "private_data_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.prefix}-private-data-subnet-a"
    Type = "Private-Data"
  }
}

resource "aws_subnet" "private_data_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.prefix}-private-data-subnet-c"
    Type = "Private-Data"
  }
}

resource "aws_subnet" "private_d" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.50.0/24"
  availability_zone = "${var.aws_region}d"

  tags = {
    Name = "${var.prefix}-private-subnet-d"
    Type = "Private"
  }
}

resource "aws_subnet" "private_data_d" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.60.0/24"
  availability_zone = "${var.aws_region}d"

  tags = {
    Name = "${var.prefix}-private-data-subnet-d"
    Type = "Private-Data"
  }
}

# ==================================================
# NAT 게이트웨이 (a zone에 1개)
# ==================================================

resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "${var.prefix}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${var.prefix}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# ==================================================
# 라우팅 테이블 - 퍼블릭
# ==================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_d" {
  subnet_id      = aws_subnet.public_d.id
  route_table_id = aws_route_table.public.id
}

# ==================================================
# 라우팅 테이블 - 프라이빗
# ==================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data_a" {
  subnet_id      = aws_subnet.private_data_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data_c" {
  subnet_id      = aws_subnet.private_data_c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_d" {
  subnet_id      = aws_subnet.private_d.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data_d" {
  subnet_id      = aws_subnet.private_data_d.id
  route_table_id = aws_route_table.private.id
}

# ==================================================
# 보안그룹 - Bastion 서버용
# ==================================================

resource "aws_security_group" "bastion" {
  name        = "${var.prefix}-bastion-sg"
  description = "Security group for Bastion server"
  vpc_id      = aws_vpc.main.id

  # SSH 접속 (내 IP만 허용)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
    description = "SSH from my IP"
  }

  # 모든 아웃바운드 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.prefix}-bastion-sg"
  }
}

# ==================================================
# 보안그룹 - EKS 노드그룹용
# ==================================================

resource "aws_security_group" "nodegroup" {
  name        = "${var.prefix}-nodegroup-sg"
  description = "Security group for EKS node group"
  vpc_id      = aws_vpc.main.id

  # SSH 접속 (Bastion에서만 허용)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from Bastion"
  }

  # 노드 간 통신 (모든 포트)
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
    description = "Node to node communication"
  }

  # 컨트롤 플레인에서 노드로 (HTTPS)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "HTTPS from control plane"
  }

  # kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Kubelet API"
  }

  # NodePort 서비스
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "NodePort services"
  }

  # 모든 아웃바운드 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.prefix}-nodegroup-sg"
  }
}