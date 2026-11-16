# ---------- VPC ----------
resource "aws_vpc" "terraform_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ---------- Subnets ----------
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = var.subnet_cidrs["public-1"]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = var.subnet_cidrs["public-2"]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
  }
}

resource "aws_subnet" "public_3" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = var.subnet_cidrs["public-3"]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-3"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.terraform_vpc.id
  cidr_block = var.subnet_cidrs["private-1"]

  tags = {
    Name = "${var.project_name}-private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.terraform_vpc.id
  cidr_block = var.subnet_cidrs["private-2"]

  tags = {
    Name = "${var.project_name}-private-subnet-2"
  }
}

resource "aws_subnet" "private_3" {
  vpc_id     = aws_vpc.terraform_vpc.id
  cidr_block = var.subnet_cidrs["private-3"]

  tags = {
    Name = "${var.project_name}-private-subnet-3"
  }
}

# ---------- Internet Gateway ----------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ---------- Elastic IP + NAT Gateway ----------
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# ---------- Route tables ----------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# ---------- Route table associations ----------
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_3" {
  subnet_id      = aws_subnet.public_3.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_3" {
  subnet_id      = aws_subnet.private_3.id
  route_table_id = aws_route_table.private_rt.id
}

# ---------- Default routes ----------
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# ---------- Security group + rules ----------

resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# ----------- SSH Ingress rule -----------

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "${var.my_ip}/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# ---------- Outbound Traffic ----------

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------- Key pair ----------
resource "aws_key_pair" "bastion_key" {
  key_name   = var.key_name
  public_key = file(pathexpand(var.public_key_path))
}

# ---------- Bastion EC2 ----------
resource "aws_instance" "bastion_host" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion_key.key_name

  tags = {
    Name = "${var.project_name}-bastion-host"
  }
}
