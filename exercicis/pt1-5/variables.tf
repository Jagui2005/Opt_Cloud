variable "region" {
    type = string
    description = "Región" 
    default = "us-east-1"
}

variable "project_name" {
    type = string
    description = "Nombre del projecto" 
}

variable "instance_count" {
    type = number
    description = "Número de instancias por subred"
    default = 1
}

variable "subnet_count" {
    type = number
    description = "Número de subnets per cada tipus"
    default = 2 
}

variable "instance_type" {
    type = string
    description = "Tipo de instancia" 
    default = "t3.micro"
}

variable "instance_ami" {
    type = string
    description = "Cadena de texto de la ami" 
    default = "ami-0157af9aea2eef346"
}

variable "vpc_CIDR" {
    type = string
    description = "CIDR para las subredes"
    default = "10.0.0.0/16"
}

variable "my_ip" {
    type = string
    description = "Mi ip"
    default = "0.0.0.0/0"
}

variable "create_s3_bucket" {
    type = bool
    description = "Crear contenedores s3"
    default = true
}
