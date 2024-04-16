terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "PodinfoVPC"
  cidr = "10.0.0.0/16"
  azs             = ["eu-central-1a"]
  public_subnets  = ["10.0.1.0/24"]

}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"
  name = "PodinfoInstance"
  ami = "ami-0f7204385566b32d0"
  instance_type = "t2.micro"
  key_name = "PodinfoKey"
  vpc_security_group_ids = [aws_security_group.podinfo_sg.id]
  subnet_id      = module.vpc.public_subnets[0]
  associate_public_ip_address = true

 user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install docker -y
                service docker start
                usermod -a -G docker ec2-user
                chkonfig docker on                
                docker pull stefanprodan/podinfo
                docker run -d -p 80:9898 stefanprodan/podinfo
                EOF
}


resource "aws_security_group" "podinfo_sg" {
  name        = "podinfo_sg"
  description = "Allow traffic for podinfo"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}
