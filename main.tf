provider "aws" {
region = "us-east-1"
}
##vpc
resource "aws_vpc" "vpc"{
cidr_block = "10.0.0.0/16"
tags = {Name = "pubvpc"}
}
##public subnate
resource "aws_subnet" "psub"{
cidr_block = "10.0.0.0/24"
availability_zone = "us-east-1a"
map_public_ip_on_launch = true
vpc_id = aws_vpc.vpc.id
tags = {Name = "publci_subnet"}
}
##private_subnet
resource "aws_subnet" "pvsub"{
cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1b"
map_public_ip_on_launch = false
vpc_id = aws_vpc.vpc.id
tags = {Name = "private_subnet"}
}
##internet Gateway
resource "aws_internet_gateway" "igw"{
vpc_id = aws_vpc.vpc.id
tags = {Name = "internet_gatway"}
}
##elastic_Ip
resource "aws_eip" "eip"{
vpc = true
tags = {Name = "elasticip"}
}
##NAT Gateway
resource "aws_nat_gateway" "ngw"{
allocation_id = aws_eip.eip.id
subnet_id = aws_subnet.psub.id
tags = {Name = "NATGW"}
}
##route table
resource "aws_route_table" "rtbl"{
vpc_id = aws_vpc.vpc.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw.id
}
tags = {Name = "route_tb"}
}
##route table for nat
resource "aws_route_table" "rtbnl"{
vpc_id = aws_vpc.vpc.id
route {
cidr_block = "0.0.0.0/0"
nat_gateway_id = aws_nat_gateway.ngw.id
}
tags = {Name = "route_nattb"}
}
##route table associations 
resource "aws_route_table_association" "rtpbs"{
subnet_id = aws_subnet.psub.id
route_table_id = aws_route_table.rtbl.id
}

resource "aws_route_table_association" "rtpvs"{
subnet_id = aws_subnet.pvsub.id
route_table_id = aws_route_table.rtbnl.id
}
##public_sg
resource "aws_security_group" "pbsgw"{
vpc_id = aws_vpc.vpc.id
ingress {
from_port = 0
to_port = 0
protocol = -1
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = -1
cidr_blocks = ["0.0.0.0/0"]
}
tags = {Name = "pbsg"}
}
##private_sg
resource "aws_security_group" "pvsgw"{
vpc_id = aws_vpc.vpc.id
ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = -1
cidr_blocks = ["0.0.0.0/0"]
}
tags = {Name = "pvsg"}
}

## key_pair
resource "aws_key_pair" "key"{
key_name = "khasim"
public_key = file("/root/.ssh/id_rsa.pub")
}
## instance public
resource "aws_instance" "pub"{
key_name = aws_key_pair.key.key_name
subnet_id = aws_subnet.psub.id
ami = "ami-0583d8c7a9c35822c"
instance_type = "t2.micro"
vpc_security_group_ids = [aws_security_group.pbsgw.id]
connection {
user = "ec2-user"
type = "ssh"
private_key = file("/root/.ssh/id_rsa")
host = self.public_ip
}
user_data =     <<-EOF
		#!/bin/bash 
		sudo -i
		sudo yum install nginx -y
		sudo systemctl enable nginx --now
		echo done
EOF
tags = {Name = "Bastion_server"}
}

##prviate server
resource "aws_instance" "pvt"{
key_name = aws_key_pair.key.key_name
subnet_id = aws_subnet.pvsub.id
ami = "ami-0583d8c7a9c35822c"
instance_type = "t2.micro"
vpc_security_group_ids = [aws_security_group.pvsgw.id]
tags = {Name = "Private"}
}
