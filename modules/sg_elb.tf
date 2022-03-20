# Creating Security Group for ELB
resource "aws_security_group" "mainsg1" {
  name        = "Main Security Group"
  description = "Main Module"
  vpc_id      = "${aws_vpc.mainvpc.id}"

# Inbound Rules
# HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# SSH access 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# Outbound Rules
# Internet access 
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}