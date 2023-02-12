
# Nhà cung cấp
provider "aws" {
  region     = "ap-southeast-1"
  access_key = "AKIA4AC2ULJMTG4Q4JIO"
  secret_key = "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"
}

# 1.Create VPC
resource "aws_vpc" "prod_VPC" {
  cidr_block = "120.0.0.0/16"
  tags = {
    "Name" = "production"
  }
}
# 2.Create Internet gateways
resource "aws_internet_gateway" "gateways1" {
  vpc_id = aws_vpc.prod_VPC.id
}


# 3. Create custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateways1.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gateways1.id
  }

  tags = {
    Name = "Production"
  }
}
# 4 Create Subnet
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod_VPC.id
  cidr_block        = "120.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    "Name" = "prod-subnet"
  }
}
# 5 Acsociate subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create secuiry Group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.prod_VPC.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_Web"
  }
}
# 7 Terraform network subnet
resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["120.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}
# 8 Elastic IP
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "120.0.1.50"
  depends_on                = [aws_internet_gateway.gateways1]


}

# 9 Create server
resource "aws_instance" "web-server-instance" {
  ami           = "ami-082b1f4237bd816a1"
  instance_type = "t2.micro"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web_server_nic.id
  }
  key_name  = "bachdangtuan"
  user_data = <<-EOF
                #! /bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                EOF

  tags = {
    Name = "ubuntu1-webserver"
  }
}
