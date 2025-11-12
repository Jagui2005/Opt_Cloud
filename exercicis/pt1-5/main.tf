resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_CIDR 
  tags = {
    Name = "${var.project_name}-VPC"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  count             = var.subnet_count
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.vpc_CIDR, 8, count.index) # Adaptat a vpc_CIDR. 
  availability_zone = tolist(data.aws_availability_zones.available.names)[count.index]
  map_public_ip_on_launch = true 
  
  tags = {
    Name = "${var.project_name}-PublicSubnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = var.subnet_count
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.vpc_CIDR, 8, var.subnet_count + count.index) 
  availability_zone = tolist(data.aws_availability_zones.available.names)[count.index]

  tags = {
    Name = "${var.project_name}-PrivateSubnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.project_name}-PublicRouteTable"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_security_group" "main_sg" {
  name        = "${var.project_name}-SG"
  description = "Grup de seguretat principal del projecte"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_CIDR] # Adaptat a vpc_CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public_instances" {
  count                  = var.instance_count
  ami                    = var.instance_ami 
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnets[count.index % var.subnet_count].id
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  depends_on = [aws_internet_gateway.main_igw]

  tags = {
    Name = "${var.project_name}-PublicInstance-${count.index + 1}"
  }
}

resource "aws_instance" "private_instances" {
  count                  = var.instance_count
  ami                    = var.instance_ami 
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnets[count.index % var.subnet_count].id
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  tags = {
    Name = "${var.project_name}-PrivateInstance-${count.index + 1}"
  }
}

resource "aws_s3_bucket" "conditional_bucket" {
  count = var.create_s3_bucket ? 1 : 0
  
  bucket = "${lower(var.project_name)}-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-S3Bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}