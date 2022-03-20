resource "aws_vpc" "mainvpc" {
   cidr_block       = "${var.vpc_cidr}"
   instance_tenancy = "default"
tags = {
   Name = "Main VPC"
 }
}

#create ıgw
resource "aws_internet_gateway" "maingateway" {
  vpc_id = "${aws_vpc.mainvpc.id}"
}

# Creating 1st subnet 
resource "aws_subnet" "mainsubnet" {
  vpc_id                  = "${aws_vpc.mainvpc.id}"
  cidr_block             = "${var.subnet_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1a"
  tags = {
    Name = "Main Subnet"
  }
}
# Creating 2nd subnet 
resource "aws_subnet" "mainsubnet1" {
  vpc_id                  = "${aws_vpc.mainvpc.id}"
  cidr_block             = "${var.subnet1_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1b"
  tags = {
    Name = "Main Subnet 1"
  }
}
#Creating Route Table
resource "aws_route_table" "route" {
  vpc_id = "${aws_vpc.mainvpc.id}"
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.maingateway.id}"
    }
  tags = {
      Name = "Route to internet"
    } 
}
resource "aws_route_table_association" "rt1" {
  subnet_id = "${aws_subnet.mainsubnet.id}"
  route_table_id = "${aws_route_table.route.id}"
}
resource "aws_route_table_association" "rt2" {
  subnet_id = "${aws_subnet.mainsubnet1.id}"
  route_table_id = "${aws_route_table.route.id}"
}