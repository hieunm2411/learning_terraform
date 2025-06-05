data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  name    = "${var.environment.name}-sg"

  vpc_id              = module.blog_vpc.vpc_id
  ingress_rules       = ["https-443-tcp","http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment.name}-vpc"
  cidr = "${var.environment.network_prefix}.0/16"

  azs             = ["ap-southeast-1a","ap-southeast-1b","ap-southeast-1c"]
  public_subnets  = ["${var.environment.network_prefix}0.0/24", "${var.environment.network_prefix}1.0/24", "${var.environment.network_prefix}2.0/24"]

  tags = {
    Environment = var.environment.name
  }
}

module "blog_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name = "${var.environment.name}-autoscaling"

  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  health_check_type         = "EC2"
  vpc_zone_identifier       = module.blog_vpc.public_subnets

  security_groups    = [module.blog_sg.security_group_id]

  instance_refresh = {
    strategy = "Rolling"
  }
  
  launch_template_name        = "${var.environment.name}-instance"
  launch_template_description = "Template for blog project's instances"
  update_default_version      = true

  image_id          = data.aws_ami.app_ami.id
  instance_type     = var.instance_type

  traffic_source_attachments = {
    blog-alb = {
      traffic_source_identifier = module.blog_alb.target_groups["blog_instance"].arn
      traffic_source_type       = "elbv2"
    }
  }

  tags = {
    Environment = var.environment.name
  }
}

module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = "${var.environment.name}alb"

  load_balancer_type = "application"

  vpc_id             = module.blog_vpc.vpc_id
  subnets            = module.blog_vpc.public_subnets

  security_groups       = [module.blog_sg.security_group_id]
  create_security_group = false

  enable_deletion_protection = false

  listeners = {
    http = {
      port      = 80
      protocol  = "HTTP"
      forward   = {
        target_group_key = "blog_instance"
      }
    }
  }

  target_groups = {
    blog_instance = {
      name_prefix       = "target"
      backend_protocol  = "HTTP"
      backend_port      = 80
      target_type       = "instance"
      
      create_attachment = false
    }
  }

  tags = {
    Environment = var.environment.name
  }
}
