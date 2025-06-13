# AMI fallback configuration
variable "fallback_ami_id" {
  description = "Fallback AMI ID to use if dynamic lookup fails"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (HVM) - eu-west-1
}

variable "use_fallback_ami" {
  description = "Whether to use fallback AMI instead of dynamic lookup"
  type        = bool
  default     = false
}

# Local values for AMI selection
locals {
  # Use fallback AMI if specified, otherwise use dynamic lookup
  final_ami_id = var.use_fallback_ami ? var.fallback_ami_id : data.aws_ami.ubuntu.id
}

# Output the selected AMI for debugging
output "selected_ami_info" {
  value = {
    ami_id   = local.final_ami_id
    ami_name = var.use_fallback_ami ? "Fallback AMI" : data.aws_ami.ubuntu.name
    source   = var.use_fallback_ami ? "fallback" : "dynamic"
  }
  description = "Information about the selected AMI"
}
