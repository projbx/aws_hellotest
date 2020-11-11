#terraform {
#  required_version = "> 0.9.0"
#}
variable "image_id" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."

  validation {
    condition     = length(var.image_id) > 4 && substr(var.image_id, 0, 4) == "ami-"
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
  }
}

variable "aws_access_key" {
  type        = string
  description = "aws_access_key"
}

variable "aws_secret_key" {
  type        = string
  description = "aws_secret_key"
}

variable "aws_region" {
  type        = string
  description = "aws_region"
}

variable "ec2_access_public_key" {
  type        = string
  description = "access public_key"
}

provider "aws" {
    region  = var.aws_region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "test_vpc" {
    cidr_block                          = "10.0.0.0/16"
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.test_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port           = 0
    to_port             = 0
    protocol            = "-1"
    ipv6_cidr_blocks    = ["::/0"]
  }    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port           = 0
      to_port             = 0
      protocol            = "-1"
      ipv6_cidr_blocks    = ["::/0"]
    }
}

resource "aws_internet_gateway" "test_ig" {
    vpc_id = aws_vpc.test_vpc.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.test_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.test_ig.id
}

resource "aws_subnet" "test_pub_snet" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.test_vpc.id
  cidr_block = "10.0.${20+count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}
resource "aws_subnet" "test_priv_snet" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.test_vpc.id
  cidr_block = "10.0.${0+count.index}.0/24"
  availability_zone= data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
}

resource "aws_key_pair" "test_key" {
  key_name   = "key4test"
  public_key = var.ec2_access_public_key
 }

resource "aws_lb_target_group" "test_lbgroup" {
  name     = "lb4test"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test_vpc.id
}

resource "aws_launch_configuration" "test_lc" {
  name_prefix   = "lc4test_"
  #REDHAT image_id      = "ami-0a54aef4ef3b5f881" 
  #UBUNTU BASE image_id      = "ami-0dd9f0e7df0f0a138"
  image_id      = var.image_id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.test_key.id
}

resource "aws_autoscaling_group" "test_asg" {
  name                 = "asg4test"
  launch_configuration = aws_launch_configuration.test_lc.name
  vpc_zone_identifier  = [
      for num in range(length(aws_subnet.test_pub_snet)):
          element(aws_subnet.test_pub_snet,num).id
  ]
  target_group_arns    = [aws_lb_target_group.test_lbgroup.id]
  min_size             = 1
  max_size             = 1

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "test_lb" {
  name               = "loadbal4test"
  internal           = false
  load_balancer_type = "application"
  subnets            = [
      for num in range(length(aws_subnet.test_pub_snet)):
          element(aws_subnet.test_pub_snet,num).id
  ]
}

resource "aws_lb_listener" "test_listener" {
  load_balancer_arn = aws_lb.test_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test_lbgroup.arn
  }
}

data "aws_lb" "gettestlb" {
  arn  = aws_lb.test_lb.arn
}

output "lb_dns" {
  value = data.aws_lb.gettestlb.dns_name
}

