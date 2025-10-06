provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "hello_world" {
    instance_type = "t2.micro"
    ami = "ami-052064a798f08f0d3"

    tags = {
        Name = "terraform-primer-vistazo"
    }
}