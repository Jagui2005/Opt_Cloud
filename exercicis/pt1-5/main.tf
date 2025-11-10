# C01-F25 - Fitxer principal de definició de recursos (Versió Simplificada)

# -- PAS 2: Xarxa i subxarxes --

# 1. Crear una VPC amb el CIDR de la variable vpc_cidr.
# La VPC és la nostra xarxa virtual aïllada a AWS.
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_CIDR

  tags = {
    Name    = "${var.project_name}-var"
  }
}

# 2. Crear 2 subxarxes públiques.
# Fem servir 'count' per crear el nombre de subxarxes definit a la variable 'subnet_count'.
resource "aws_subnet" "public_subnets" {
  count      = var.subnet_count
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.${count.index + 1}.0/24" 
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-PublicSubnet-${count.index + 1}"
  }
}

# 2. Crear 2 subxarxes privades.
# Fem el mateix per a les privades, però amb un rang d'IPs diferent per no solapar-se.
resource "aws_subnet" "private_subnets" {
  count      = var.subnet_count
  vpc_id     = aws_vpc.main_vpc.id
  # Ex: 10.0.101.0/24, 10.0.102.0/24...
  cidr_block = "10.0.${count.index + 101}.0/24"

  tags = {
    Name    = "${var.project_name}-PrivateSubnet-${count.index + 1}"
    Project = var.project_name
  }
}

# 3. Crear un Internet Gateway (IGW) per donar accés a Internet a la VPC.
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name    = "${var.project_name}-IGW"
    Project = var.project_name
  }
}

# 3. Crear una taula de rutes per a les subxarxes públiques.
# Aquesta taula diu que tot el trànsit cap a Internet (0.0.0.0/0) ha de sortir per l'IGW.
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name    = "${var.project_name}-PublicRouteTable"
    Project = var.project_name
  }
}

# 3. Associar la taula de rutes a les subxarxes públiques.
# Apliquem la regla anterior a totes les nostres subxarxes públiques.
resource "aws_route_table_association" "public_assoc" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}


# -- PAS 3: Instàncies EC2 --

# 1. Crear un Security Group (actua com un firewall).
resource "aws_security_group" "instance_sg" {
  name        = "${var.project_name}-SG"
  description = "Regles de firewall per a les instàncies EC2."
  vpc_id      = aws_vpc.main_vpc.id

  # Permet HTTP (port 80) des de qualsevol IP.
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permet SSH (port 22) només des de la IP definida a la variable 'my_ip'.
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.my_ip]
  }

  # No permet tràfic ICMP (ping) des de fora de la VPC.
  # Aquesta regla permet ICMP només des de dins de la pròpia VPC.
  ingress {
    protocol    = "icmp"
    from_port   = -1 # Qualsevol tipus de ICMP
    to_port     = -1 # Qualsevol codi de ICMP
    cidr_blocks = [var.vpc_cidr]
  }

  # Permet tot el tràfic sortint a qualsevol IP.
  egress {
    protocol    = "-1" # Tots els protocols
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-SG"
    Project = var.project_name
  }
}

# 2. Crear les instàncies en les subxarxes públiques.
resource "aws_instance" "public_instances" {
  count                  = var.instance_count
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  # Associem la instància a una de les subxarxes públiques.
  subnet_id              = aws_subnet.public_subnets[count.index].id
  # Apliquem les regles del firewall que hem creat.
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  # Afegim una dependència explícita per assegurar que l'IGW estigui llest.
  depends_on = [aws_internet_gateway.main_igw]

  tags = {
    Name    = "${var.project_name}-PublicInstance-${count.index + 1}"
    Project = var.project_name
  }
}

# 2. Crear les instàncies en les subxarxes privades.
resource "aws_instance" "private_instances" {
  count                  = var.instance_count
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = {
    Name    = "${var.project_name}-PrivateInstance-${count.index + 1}"
    Project = var.project_name
  }
}


# -- PAS 4: Bucket S3 condicional --

# Crear un bucket S3 només si la variable 'create_s3_bucket' és 'true'.
# Fem servir 'count': si la variable és 'true', count serà 1 (es crea).
# Si és 'false', count serà 0 (no es crea).
resource "aws_s3_bucket" "conditional_bucket" {
  count = var.create_s3_bucket ? 1 : 0

  # El nom del bucket ha de ser únic a tot AWS. Usem el nom del projecte.
  # ATENCIÓ: Si aquest nom ja existeix, donarà error. L'hauràs de canviar.
  bucket = "${lower(var.project_name)}-bucket-asix2-2025"

  tags = {
    Name    = "${var.project_name}-S3Bucket"
    Project = var.project_name
  }
}