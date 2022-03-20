# How to Manage a PHP Application with AWS&Terraform?

## Information

The aim of this project;

•The first step is to manage the PHP application with Terraform and  AWS.<br/>


# Prerequisite:
•	AWS Account <br/>
•	Access Key & Secret Key created the AWS <br/>
• SSH Key <br/>
•	Terraform <br/>
•	Docker <br/>

## What is Terraform?
Terraform is an open-source infrastructure as a code (IAC) tool that allows to create, manage & deploy the production-ready environment.


I started working by creating terraform modules.I chose the **main** word for easy filtering(Main VPC,Main Subnet etc.)

This terraform module includes ;<br/>
•	VPC<br/>
•	Auto Scaling Group<br/>
•	Launch Configuration<br/>
•	Auto Scaling Policy<br/>
•	Elastic Load Balancer<br/>
•	Internet Gateway<br/>
•	Route Table<br/>
•	Security Groups<br/>
•	Subnets<br/>
•	CloudWatch Alarm<br/>


**Step 1- Create Provider block**

* Create `provider.tf` file and add the below content to it

  ```
  provider "aws" {
    region = "eu-central-1"
    access_key = "{}"
    secret_key = "{}"
  }
  ```

**Step 2 - Create AWS VPC**

* Create `vpc.tf` file and add the below code to it

  ```
  resource "aws_vpc" "mainvpc" {
     cidr_block       = "${var.vpc_cidr}"
     instance_tenancy = "default"
  tags = {
     Name = "Main VPC"
   }
  }
  ``` 
  
**Step 3:- Create AWS Internet Gateway**

* Create `igw.tf` file and add the below code to it

  ```
  resource "aws_internet_gateway" "maingateway" {
    vpc_id = "${aws_vpc.mainvpc.id}"
  }
  ``` 

* Here I have created the Internet Gateway for newly created VPC.

**Step 4:- Create AWS Subnets**

* Create `subnet.tf` file and add the below code to it

  ```
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
  ```

**Step 5:- Create AWS Route Table**

* Create `route_table.tf` file and add the below code to it

  ```
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
  ```

**Step 6:- Create AWS Security Group for Load Balancer**

* Create `sg_elb.tf` file and add the below code to it
  
  ```
  # Creating Security Group for ELB
  resource "aws_security_group" "mainsg1" {
    name        = "Main Security Group"
    description = "Main Module"
    vpc_id      = "${aws_vpc.mainvpc.id}"
  
  # Inbound Rules
  # HTTP access from anywhere
    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  # SSH access from anywhere
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    HTTP access from anywhere
    engress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    HTTPS access from anywhere
    engress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  }
  ```
* Here I am creating inbound rules for ports 22,80 opening outbound connection.


**Step 7:- Create AWS Load Balancer**

* Create `elb.tf` file and add the below code to it
  
  ```
  resource "aws_elb" "web_elb" {
  name = "web-elb"
  security_groups = [
    "${aws_security_group.mainsg1.id}"
  ]
  subnets = [
    "${aws_subnet.mainsubnet.id}",
    "${aws_subnet.mainsubnet1.id}"
  ]
  cross_zone_load_balancing   = true
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
  }
  ```
* This will create an ELB that will be deployed across all of the AZs where our multiple servers that can run in separate AZs. AWS will automatically scale the number of load balancer servers up and down based on traffic and handle failover if one of those servers goes down so that we can get scalability and high availability.

* Note also that the aws_elb code above shows we're telling the ELB how to route requests by adding listeners which specify what port the ELB should listen on and what port it should route the request to.


**Step 8:- Create AWS Launch configuration**

* Create `launch_config.tf` file and add the below code to it
* ASG helps us to automatically launch EC2 Instances, monitor their health, restart failed nodes, and adjust the size of the cluster in response to varying demands.

  ```
  resource "aws_launch_configuration" "web" {
    name_prefix = "web-"
    image_id = "ami-04c921614424b07cd
    " 
    instance_type = "t2.micro"
    key_name = "tests"
    security_groups = [ "${aws_security_group.mainsg.id}" ]
    associate_public_ip_address = true
    user_data = "${file("data.sh")}"
  lifecycle {
    create_before_destroy = true
  }
  }
  ```
* I created AWS Linux 2 as the AMI instance and using user data for configuring the newly created instances.I will explain the user data in the next steps.
* Key pair has already existed in the region
* We use `create_before_destroy` to create the replacement first, and then deleting the old one. Note that the default order is to delete the old resource and then create the new one.


**Step 9:- Create AWS Security group for EC2 instances**

* Create `sg_ec2.tf` file and add the below code to it

  ```
  # Creating Security Group for ELB
  resource "aws_security_group" "mainsg1" {
    name        = "Main Security Group"
    description = "Main Module"
    vpc_id      = "${aws_vpc.mainvpc.id}"
  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  }
  ```
* Here I created inbound rules for ports **22,80 & 443** and opening outbound connection for all the ports for all the IPs.


**Step 10:- Create AWS Auto Scaling Group**

* Create `asg.tf` file and add the below code to it
* Auto Scaling Group will get information about instance availability from the ELB
* Minimum 1 instance , max 2 instances.
* Auto Scaling Group will be launched with 1 instance

  ```
  resource "aws_autoscaling_group" "web" {
    name = "${aws_launch_configuration.web.name}-asg"
    min_size             = 1
    desired_capacity     = 1
    max_size             = 2
  
    health_check_type    = "ELB"
    load_balancers = [
      "${aws_elb.web_elb.id}"
    ]
  launch_configuration = "${aws_launch_configuration.web.name}"
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"
  vpc_zone_identifier  = [
    "${aws_subnet.mainsubnet.id}",
    "${aws_subnet.mainsubnet1.id}"
  ]
  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
  }
  ```

**Step 11:- Create AWS Auto Scaling Policy**

* Create `asg_policy.tf` file and add the below code to it.

  ```
  resource "aws_autoscaling_policy" "web_policy_up" {
    name = "web_policy_up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 200
    autoscaling_group_name = "${aws_autoscaling_group.web.name}"
  }
  resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
    alarm_name = "web_cpu_alarm_up"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "50"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ "${aws_autoscaling_policy.web_policy_up.arn}" ]
  }
  resource "aws_autoscaling_policy" "web_policy_down" {
    name = "web_policy_down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 200
    autoscaling_group_name = "${aws_autoscaling_group.web.name}"
  }
  resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
    alarm_name = "web_cpu_alarm_down"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "20"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ "${aws_autoscaling_policy.web_policy_down.arn}" ]
  }
  ```
  
* `aws_cloudwatch_metric_alarm, threshold = "50"` is an alarm, if the total CPU utilization of all instances in our Auto Scaling Group will be the greater or equal threshold value which is 50% during 120 seconds.
* `aws_cloudwatch_metric_alarm, threshold = "20"` is an alarm, if the total CPU utilization of all instances in our Auto Scaling Group will be the lesser or equal threshold value which is 20% during 120 seconds.
* I reviewed this [aws_cloudwatch_metric_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) from the link.
 

**Step 12:- Create terraform variable file**

* Create `vars.tf` file and add the below code to it

  ```
  # Defining Public Key
  variable "public_key" {
    default = "tests.pub"
  }
  # Defining Private Key
  variable "private_key" {
    default = "tests.pem"
  }
  # Definign Key Name for connection
  variable "key_name" {
   default = "tests"
  }
  # Defining CIDR Block for VPC
  variable "vpc_cidr" {
    default = "10.0.0.0/16"
  }
  # Defining CIDR Block for Subnet
  variable "subnet_cidr" {
    default = "10.0.1.0/24"
  }
  # Defining CIDR Block for 2d Subnet
  variable "subnet1_cidr" {
    default = "10.0.2.0/24"
  }
  ```

**Step 13:- Create a user data file**

* Create `data.sh` file and add the below code to it

  ```
  sudo yum update -y
  sudo amazon-linux-extras install docker -y
  sudo service docker start
  sudo usermod -a -G docker ec2-user
  sudo chkconfig docker on
  sudo chmod 666 /var/run/docker.sock
  docker pull ndockern/docker-php:v1
  docker run -d -p 80:80 ndockern/docker-php:latest 

  
  ```
* Here I am installing docker and running php application’s docker image.

* Please check this link for [docker image](https://github.com/nisaclk/IAC-CICD/tree/master/docker) details. 

**Finally, We need to run the below steps to test and create the infrastructure**

* `terraform init` is to initialize the working directory and downloading plugins of the AWS provider<br/>
* `terraform plan` is to create the execution plan for our code<br/>
* `terraform apply` is to create the actual infrastructure. It will ask you to provide the Access Key and Secret Key in order to create the infrastructure. So, instead of hardcoding the Access Key and Secret Key, it is better to apply at the run time.


**After terraform apply, we can control the services on the AWS.**


**1.VPC**
![VPC](https://github.com/nisaclk/tf-web/blob/master/documentation/vpc60a-png.png)

**2.EC2 İnstance**
* We see that the serveris running.

![instance](https://github.com/nisaclk/tf-web/blob/master/documentation/instance.png)

**3.Auto Scaling Group**
* There will be a minimum of 1 instance to serve the traffic.

 * There will be at max 2 instancess to serve the traffic.

* Auto Scaling Group will be launched with 1 instance

![ASG](https://github.com/nisaclk/tf-web/blob/master/documentation/autoscalinggroup.png)

**4.Elastic Load Balancer**
![ELB](https://github.com/nisaclk/tf-web/blob/master/documentation/elb.png)

**5.CloudWatch Metrics**

* Scale Up :If the total CPU utilization of all instances in our Auto Scaling Group will be the greater or equal threshold value which is 50% during 120 seconds.

![>50](https://github.com/nisaclk/tf-web/blob/master/documentation/cpu-scale-up-detals.png)

* Scale Down :If the total CPU utilization of all instances in our Auto Scaling Group will be the lesser or equal threshold value which is 20% during 120 seconds.

![>20](https://github.com/nisaclk/tf-web/blob/master/documentation/scale-down-graph.png)


