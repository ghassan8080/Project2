# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "terraform_dev" # please provide your profile name
}

# 1- Define the VPC 
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name        = var.vpc_name
    Environment = "project2_environment"
    Terraform   = "true"
  }
}

# 2A- Getting the list of the available AZs in our region
data "aws_availability_zones" "available_zones" {
  state = "available"
}

# 2B - Create the Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = data.aws_availability_zones.available_zones.names[0]
  tags = {
    Name      = "project_public_subnet"
    Terraform = "true"
  }
}

#3 - Create the Internet Gateway and attach it to the VPC using a Route Table
# 3A - Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "project_igw"
  }
}
# 3B - Create route table for the public subnet and associate it with the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name      = "project_public_rtb"
    Terraform = "true"
  }
}
#3C- Create route table associations to the public subnet
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnet]
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet.id
}

#4- Create a Security Group for the EC2 Instance
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins_sg"
  vpc_id = aws_vpc.vpc.id
  # Since Jenkins runs on port 8080, we are allowing all traffic from the internet
  # to be able ot access the EC2 instance on port 8080
  ingress {
    description = "Allow all traffic through port 8080"
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Since we only want to be able to SSH into the Jenkins EC2 instance, we are only
  # allowing traffic from our IP on port 22
  ingress {
    description = "Allow SSH from my computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }
  # We want the Jenkins EC2 instance to being able to talk to the internet
  egress {
    description = "Allow all outbound traffic"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # We are setting the Name tag to tutorial_jenkins_sg
  tags = {
    Name = "tutorial_jenkins_sg"
  }
}
# 5- Create the Jenkins EC2 instance, add the Jenkins installation to its user data and attach to it Elastic IP.
#5A- Create the Key Local and attach to the instance.
resource "aws_key_pair" "jenkins-key" {
  key_name   = "jenkins-key"
  public_key = "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"
}
# 5B- This data store is holding the most recent ubuntu 20.04 image
data "aws_ami" "ubuntu" {
  most_recent = "true"

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

#5C- Create the EC2 Instance 
resource "aws_instance" "jenkins_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = "jenkins-key"
  availability_zone      = data.aws_availability_zones.available_zones.names[0]
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.public_subnet.id
  root_block_device {
    encrypted = true
  }
  user_data = file("${path.module}/jenkins_installation.sh")
  tags = {
    Name = "Jenkins_Instance"
  }
}

#5D- Creating an Elastic IP called jenkins_eip
resource "aws_eip" "jenkins_eip" {
  # Attaching it to the jenkins_server EC2 instance
  instance = aws_instance.jenkins_instance.id

  # Making sure it is inside the VPC
  domain = "vpc"

  # Setting the tag Name to jenkins_eip
  tags = {
    Name = "jenkins_eip"
  }
}
