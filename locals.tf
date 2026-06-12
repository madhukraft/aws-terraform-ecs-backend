data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  az_names   = data.aws_availability_zones.available.names
  ecs_ami_id = try(data.aws_ssm_parameter.ecs_ami.value, null)
}
