data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-ASIX2-RA1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW-ASIX2-RA1"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Public-Bastion-Subnet"
  }
}

resource "aws_eip" "nat" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  
  tags = {
    Name = "NAT-Gateway-ASIX2-RA1"
  }
  depends_on = [aws_eip.nat] 
}


resource "aws_subnet" "private" {
  count = var.private_instance_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 2) 
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = false

  tags = {
    Name = "Private-Subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private-Route-Table"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.private_instance_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id
  name   = "bastion-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion-SG"
  }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.main.id
  name   = "private-sg"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    self            = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Private-SG"
  }
}

resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_key_aws" {
  key_name   = "bastion-key-asix2-ra1"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

# 5.2. Claves de los Servidores Privados (N)
resource "tls_private_key" "private_keys" {
  count     = var.private_instance_count
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "private_keys_aws" {
  count      = var.private_instance_count
  key_name   = "private-key-${count.index + 1}-asix2-ra1"
  public_key = tls_private_key.private_keys[count.index].public_key_openssh
}

resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.bastion_key_aws.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  
  tags = {
    Name = "Bastion-Host-ASIX2"
  }
}

resource "aws_eip" "bastion_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}


resource "aws_instance" "private" {
  count                       = var.private_instance_count
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[count.index].id
  key_name                    = aws_key_pair.private_keys_aws[count.index].key_name
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  
  tags = {
    Name = "Private-Server-${count.index + 1}"
  }
}

resource "aws_s3_bucket" "key_backup" {
  bucket = "key-backup-asix2-ra1-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_ownership_controls" "s3_controls" {
  bucket = aws_s3_bucket.key_backup.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

locals {
  all_public_keys = merge(
    {
      "bastion" = tls_private_key.bastion_key.public_key_openssh
    },
    { for i in range(var.private_instance_count) : 
      "private-${i + 1}" => tls_private_key.private_keys[i].public_key_openssh 
    }
  )
}

resource "aws_s3_object" "public_key_backup" {
  for_each = local.all_public_keys

  bucket = aws_s3_bucket.key_backup.id
  key    = "keys/${each.key}.pub"
  content = each.value
  
  depends_on = [aws_s3_bucket_ownership_controls.s3_controls]
}

resource "local_file" "bastion_private_key_file" {
  content  = tls_private_key.bastion_key.private_key_pem
  filename = "bastion.pem"
}

resource "local_file" "private_private_key_files" {
  count    = var.private_instance_count
  content  = tls_private_key.private_keys[count.index].private_key_pem
  filename = "private-${count.index + 1}.pem"
}

resource "local_file" "ssh_config_file" {
  content = templatefile("${path.module}/ssh_config.tpl", {
    bastion_ip     = aws_eip.bastion_eip.public_ip,
    num_instances  = var.private_instance_count,
    # Lista de IPs privadas de las N instancias para el Hostname
    private_ips    = aws_instance.private[*].private_ip
  })
  filename = "ssh_config_per_connect.txt"
}