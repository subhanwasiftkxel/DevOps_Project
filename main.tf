terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
}


resource "aws_vpc" "my_vpc_terraform" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "My-VPC-terraform"
  }

}

resource "aws_subnet" "PublicSubnetTerraform" {
  vpc_id     = aws_vpc.my_vpc_terraform.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "publicSubnet"
  }
}
resource "aws_subnet" "PrivateSubnetTerraform" {
  vpc_id     = aws_vpc.my_vpc_terraform.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "privateSubnet"
  }
}

resource "aws_internet_gateway" "internet_gateway_terrafom" {
  vpc_id = aws_vpc.my_vpc_terraform.id
  tags = {
    Name = "gw"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_terrafom.id
  }

  tags = {
    Name = "routeTable"
  }
}

resource "aws_route_table_association" "Subnet_Association" {
  subnet_id      = aws_subnet.PublicSubnetTerraform.id
  route_table_id = aws_route_table.my_route_table.id
}


resource "aws_security_group" "terraform_security_group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my_vpc_terraform.id

  ingress {
    description = "TLS from VPC"
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
    Name = "allow_tls"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "my_ec2_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.PublicSubnetTerraform.id # Place the instance in the public subnet
  # Associate the security group created earlier
  vpc_security_group_ids = [aws_security_group.terraform_security_group.id]
  # Ensure you have this key pair created in AWS or add this field accordingly

  tags = {
    Name = "MyEC2Instance"
  }
  provisioner "local-exec" {
    command = <<EOT
      echo "[my_ec2_instance]" > inventory
      echo "${aws_instance.my_ec2_instance.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=my-second-key" >> inventory
      echo "It is working, the key is ${aws_instance.my_ec2_instance.public_ip}"
    EOT
  }
}


