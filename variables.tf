variable "instance_type" {
  description = "Type of EC2 instance to provision"
  type        = string
  default     = "t2.micro"
}

variable "ami_filter" {
  description = "The name and owner of the AMI"
  type        = object({
    name      = string
    owner     = string
  })
  default     = {
    name  = "bitnami-tomcat-*-x86_64-hvm-ebs-nami"
    owner = "979382823631"
  }
}

variable "environment" {
  description       = "Development environment"
  type              = object({
    name            = string
    network_prefix  = string
  })
  default           = {
    name            = "dev"
    network_prefix  = "10.0"
  }
}

variable "min_size" {
  description = "The minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum number of instances in the ASG"
  type        = number
  default     = 2
}
