variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura."
  type        = string
  default     = "eu-west-1" # Irlanda
}

variable "vpc_cidr" {
  description = "Bloque CIDR principal para la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Bloque CIDR para la subred pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_instance_count" {
  description = "Número de instancias privadas a crear"
  type        = number
  default     = 2 
}

variable "allowed_ip" {
  description = "La IP pública desde la que se permitirá la conexión SSH al Bastión"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2 a utilizar."
  type        = string
  default     = "t2.micro" 
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  # Esta AMI es un ejemplo de Amazon Linux 2023 en eu-west-1
  default     = "ami-0eb22c76a3013b860" 
}