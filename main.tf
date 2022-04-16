
provider "aws" {}

variable "vpc_cidr_blocks" {}
variable "subnet_cidr_blocks" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "avail_zone" {}
variable "public_key_location" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_blocks
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}
resource "aws_subnet" "myapp_subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_blocks
  availability_zone = "us-east-1a"
  tags = {
    Name = "${var.env_prefix}-sub"
  }
}
resource "aws_internet_gateway" "myapp-IGW" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-IGW"
  }
}
resource "aws_default_route_table" "myapp-default-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-IGW.id
  }
  tags = {
    Name = "${var.env_prefix}-main-routetb"
  }
}
resource "aws_default_security_group" "default-sg"{
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    description = "22 from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip
  }
  ingress {
    description = "80 from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env_prefix}-default-SG"
  }
}
resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
}
resource "aws_instance" "myapp-server" {
  ami = "ami-03ededff12e34e59e"
  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp_subnet-1.id
  security_groups = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name
  user_data = file("entry-script.sh")
  tags = {
    Name = "${var.env_prefix}-myapp-Instance"
  }
}
output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}