provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_03" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_03"
  }
}

resource "aws_subnet" "subnet_juanmi1" {
  vpc_id                  = aws_vpc.vpc_03.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet1"
  }
}

resource "aws_subnet" "subnet_juanmi2" {
  vpc_id                  = aws_vpc.vpc_03.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet2"
  }
}


resource "aws_internet_gateway" "mi_gw" {
  vpc_id = aws_vpc.vpc_03.id

  tags = {
    Name = "mi_gw"
  }
}

resource "aws_route_table" "tabla_route" {
  vpc_id = aws_vpc.vpc_03.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mi_gw.id 
  }

  tags = {
    Name = "tabla_route"
  }
}

resource "aws_route_table_association" "asociacion_1" {
  subnet_id      = aws_subnet.subnet_juanmi1.id 
  route_table_id = aws_route_table.tabla_route.id
}

resource "aws_route_table_association" "asociacion_2" {
  subnet_id      = aws_subnet.subnet_juanmi2.id
  route_table_id = aws_route_table.tabla_route.id
}

resource "aws_security_group" "servidor_ssh_icmp" {
  name        = "permetre-ssh-icmp"
  vpc_id      = aws_vpc.vpc_03.id

  tags = {
    Name = "grupo_seguridad"
  }
}

resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.servidor_ssh_icmp.id
}

resource "aws_security_group_rule" "icmp_ingress" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = [aws_vpc.vpc_03.cidr_block]
  security_group_id = aws_security_group.servidor_ssh_icmp.id
}

resource "aws_security_group_rule" "all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.servidor_ssh_icmp.id
}

resource "aws_instance" "instancia_1" {
    ami = "ami-0341d95f75f311023"
    instance_type = "t3.micro"
    key_name = "vockey"
    subnet_id = aws_subnet.subnet_juanmi1.id
    vpc_security_group_ids = [aws_security_group.servidor_ssh_icmp.id]
        tags = {
            Name = "ec2_a"
        }
}

resource "aws_instance" "instancia_2" {
    ami = "ami-0341d95f75f311023"
    instance_type = "t3.micro"
    key_name = "vockey"
    subnet_id = aws_subnet.subnet_juanmi2.id
    vpc_security_group_ids = [aws_security_group.servidor_ssh_icmp.id]
        tags = {
            Name = "ec2_b"
        }
}
