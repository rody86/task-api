variable "aws_region" {
  description = "AWS region"
  default     = "eu-south-2" # Cambia a la que prefieras
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "c7i-flex.large"
}

variable "key_name" {
  description = "Name of the AWS SSH key pair"
  type        = string
  # Sin default: deberás pasarlo o definirlo en un .tfvars
}

variable "my_ip" {
  description = "Your public IP for SSH access (e.g. 203.0.113.5/32)"
  type        = string
  # Ejecuta 'curl ifconfig.me' y añade /32
}
