provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Web Server (Public)
resource "aws_instance" "web" {

  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  key_name      = var.key_name

  tags = {
    Name = "web-server"
  }
}

# App Server (Private)
resource "aws_instance" "app" {

  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  key_name      = var.key_name

  tags = {
    Name = "app-server"
  }
}

# RDS
resource "aws_db_instance" "db" {

  allocated_storage = 20
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"

  db_name  = "userdata"
  username = "admin"
  password = "Password123!"

  skip_final_snapshot = true
}

########################
# OUTPUTS
########################

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}

output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}