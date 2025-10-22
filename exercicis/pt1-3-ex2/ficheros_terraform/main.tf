provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "vpc_juanmi" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "vpc_juanmi"
    }
}

resource "aws_subnet" "subnet_juanmi1" {
    vpc_id = aws_vpc.vpc_juanmi.id
    cidr_block = "10.0.32.0/25"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "Subnet1"
    }
}
resource "aws_subnet" "subnet_juanmi2" {
    vpc_id = aws_vpc.vpc_juanmi.id
    cidr_block = "10.0.30.0/23"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "Subnet2"
    }
}
resource "aws_subnet" "subnet_juanmi3" {
    vpc_id = aws_vpc.vpc_juanmi.id
    cidr_block = "10.0.33.0/28"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "Subnet3"
    }
}

resource "aws_instance" "instancia_A" {
    count = 2
    ami = "ami-0341d95f75f311023"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.subnet_juanmi1.id
        tags = {
            Name = "instancia_A-${count.index + 1}"
        }
}

resource "aws_instance" "instancia_B" {
    count = 2
    ami = "ami-0341d95f75f311023"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.subnet_juanmi2.id
        tags = {
            Name = "instancia_B-${count.index + 1}"
        }
}

resource "aws_instance" "instancia_C" {
    count = 2
    ami = "ami-0341d95f75f311023"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.subnet_juanmi3.id
        tags = {
            Name = "instancia_C-${count.index + 1}"
        }
}