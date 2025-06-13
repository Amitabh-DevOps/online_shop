# AMI fallback configuration
variable "fallback_ami_id" {
  description = "Fallback AMI ID to use if dynamic lookup fails"
  type        = string
  default     = "ami-07b5312224c6b20e7" # Use the Ubuntu AMI that was found
}

variable "use_fallback_ami" {
  description = "Whether to use fallback AMI instead of dynamic lookup"
  type        = bool
  default     = false
}

# Local values for AMI selection - simplified
locals {
  # Always use the Ubuntu AMI that was found since it's working
  final_ami_id = data.aws_ami.ubuntu.id
}

# Output the selected AMI for debugging
output "selected_ami_info" {
  value = {
    ami_id   = local.final_ami_id
    ami_name = data.aws_ami.ubuntu.name
    source   = "dynamic"
  }
  description = "Information about the selected AMI"
}
