data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = "blog-alb"

  load_balancer_type = "application"

  vpc_id             = module.blog_vpc.vpc_id
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_sg.security_group_id]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "ex-target"
      }
    }

    target_groups = {
    ex-target = {
      name_prefix      = "blog-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  }

  tags = {
    Environment = "dev"
  }
}

module "blog_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.13.0"
  name                = "blog"

  vpc_id              = module.blog_vpc.vpc_id
  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules        = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "blog_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name                = "blog"
  instance_name   = "my-instance-name"

  min_size                  = 1
  max_size                  = 2
  health_check_type         = "EC2"
  vpc_zone_identifier       = module.blog_vpc.private_subnets

  # Launch template
  launch_template_name        = "app_instance"
  launch_template_description = "Complete launch template example"
  update_default_version      = true

  image_id                = data.aws_ami.app_ami.id
  instance_type           = var.instance_type

  # # Security group is set on the ENIs below
  # security_groups          = [module.blog_sg.security_group_id]
}

resource "aws_autoscaling_attachment" "blog_alb_attachment" {
  autoscaling_group_name = module.blog_autoscaling.autoscaling_group_id
  lb_target_group_arn    = module.blog_alb.target_group_arn
}
