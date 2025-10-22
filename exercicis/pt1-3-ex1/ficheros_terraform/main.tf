provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "instancia_1" {
    ami = "ami-0341d95f75f311023"
    instance_type = "t3.micro"
}

resource "aws_instance" "instancia_2" {
    ami = "ami-0341d95f75f311023"
    instance_type = "t3.micro"
}
