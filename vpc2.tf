provider "aws" {
  region = "ap-south-1"
  profile= "surbhisahdev508"
}

resource "tls_private_key" "generated_key" {
  algorithm   = "RSA"
  
}

resource "aws_key_pair" "generated_key" {
  depends_on = [ tls_private_key.generated_key, ]
  key_name   = "sshkey3"
  public_key = tls_private_key.generated_key.public_key_openssh
}


resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
tags = {
    Name = "vpc"
  }
}

//Provides an VPC subnet resource


resource "aws_subnet" "wpsubnet1" {
  vpc_id     = "vpc-0c050bc55779129be"
  cidr_block = "192.168.1.0/24"
//availability_zone = aws_instance.my_instance.availability_zone
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"


  tags = {
    Name = "wpsubnet1"
  }
}

//Provides an VPC subnet resource


resource "aws_subnet" "mysqlsubnet2" {
  vpc_id     = "vpc-0c050bc55779129be"
  cidr_block = "192.168.0.0/24"
//availability_zone = aws_instance.my_instance.availability_zone
  availability_zone = "ap-south-1a"


  tags = {
    
     Name = "mysqlsubnet2"
  }
}


resource "aws_internet_gateway" "gateway" {
  vpc_id = "vpc-0c050bc55779129be"

  tags = {
    Name = "gateway"
  }
}


resource "aws_route_table" "gateway_route" {
  vpc_id = "vpc-0c050bc55779129be"


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "igw-076994abd178d8b60"
  }


  tags = {
    Name = "my_gw_route"
  }
}

// Provides a resource to create an association


resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.wpsubnet1.id
  route_table_id = aws_route_table.gateway_route.id
}

resource "aws_eip" "eip" {
  vpc = true
}



resource "aws_nat_gateway" "gw2" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.wpsubnet1.id


  tags = {
    Name = "NATGW"
  }
}


resource "aws_route_table" "route_nat" {
  vpc_id = "${aws_vpc.vpc.id}"


  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id  = "${aws_nat_gateway.gw2.id}"
  }


  tags = {
    Name = "NAT-gateway"
     }
 }


  
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.mysqlsubnet2.id
  route_table_id = aws_route_table.route_nat.id
}


// Provides a security group resource for wordpress_sg

resource "aws_security_group" "wpsg" {
  name        = "wordpress-sg"
  description = "Allow inbound traffic"
  vpc_id      = "vpc-0c050bc55779129be"


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


// provides a security group for mysql_sg


resource "aws_security_group" "mysql-sg" {
  name        = "mysql-sg"
  description = "Allow only ssh inbound traffic"
  vpc_id      = "${aws_vpc.vpc.id}"
ingress {
    description = "SSH"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "mysql-sg"
  }
}


resource "aws_instance" "wordpress" {
   ami = "ami-004a955bfb611bf13"
   instance_type = "t2.micro"
   associate_public_ip_address = true
   subnet_id = aws_subnet.wpsubnet1.id
   vpc_security_group_ids = [ aws_security_group.wpsg.id]
   key_name = "sshkey3"
tags = { 
         Name = "Wordpress"
     }
}

resource "aws_instance" "mysql" {
   ami = "ami-08706cb5f68222d09"
   instance_type = "t2.micro"
   subnet_id = aws_subnet.mysqlsubnet2.id
   vpc_security_group_ids = [ aws_security_group.mysql-sg.id ]
   key_name = "sshkey3"
tags = { 
         Name = "mysql"
     }
}


