locals {
  region  = var.vpc_endpoints_enabled && var.vpc_id != null ? split(":", data.aws_vpc.selected[0].arn)[3] : data.aws_region.current.name
  subnets = var.vpc_endpoints_enabled ? var.subnet_ids != [] ? var.subnet_ids : data.aws_subnet_ids.selected[0].ids : []
}

data "aws_subnet_ids" "selected" {
  count  = var.vpc_endpoints_enabled ? 1 : 0
  vpc_id = var.vpc_id
}

data "aws_route_table" "selected" {
  count     = var.vpc_endpoints_enabled ? length(local.subnets) : 0
  subnet_id = sort(local.subnets)[count.index]
}

# SSM, EC2Messages, and SSMMessages endpoints are required for Session Manager
resource "aws_vpc_endpoint" "ssm" {
  count             = var.vpc_endpoints_enabled ? 1 : 0
  vpc_id            = var.vpc_id
  subnet_ids        = local.subnets
  service_name      = "com.amazonaws.${local.region}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_sg[0].id
  ]

  private_dns_enabled = var.vpc_endpoint_private_dns_enabled
  tags = merge(var.tags, {
    yor_trace = "feabc8e1-b11b-4e92-a52a-4c438456346f"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  count             = var.vpc_endpoints_enabled ? 1 : 0
  vpc_id            = var.vpc_id
  subnet_ids        = local.subnets
  service_name      = "com.amazonaws.${local.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_sg[0].id,
  ]

  private_dns_enabled = var.vpc_endpoint_private_dns_enabled
  tags = merge(var.tags, {
    yor_trace = "f0243ec3-f797-4a6b-b161-646143ec7466"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count             = var.vpc_endpoints_enabled ? 1 : 0
  vpc_id            = var.vpc_id
  subnet_ids        = local.subnets
  service_name      = "com.amazonaws.${local.region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_sg[0].id,
  ]

  private_dns_enabled = var.vpc_endpoint_private_dns_enabled
  tags = merge(var.tags, {
    yor_trace = "070fde69-acf3-4c10-9637-8689598ef740"
  })
}

# To write session logs to S3, an S3 endpoint is needed:
resource "aws_vpc_endpoint" "s3" {
  count        = var.vpc_endpoints_enabled && var.enable_log_to_s3 ? 1 : 0
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${local.region}.s3"
  tags = merge(var.tags, {
    yor_trace = "9b52b078-4d5e-4148-8cdf-9aebd76e5a1d"
  })
}

# Associate S3 Gateway Endpoint to VPC and Subnets
resource "aws_vpc_endpoint_route_table_association" "private_s3_route" {
  count           = var.vpc_endpoints_enabled && var.enable_log_to_s3 ? 1 : 0
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = data.aws_vpc.selected[0].main_route_table_id
}

resource "aws_vpc_endpoint_route_table_association" "private_s3_subnet_route" {
  count           = var.vpc_endpoints_enabled && var.enable_log_to_s3 ? length(data.aws_route_table.selected) : 0
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = data.aws_route_table.selected[count.index].id
}

# To write session logs to CloudWatch, a CloudWatch endpoint is needed
resource "aws_vpc_endpoint" "logs" {
  count             = var.vpc_endpoints_enabled && var.enable_log_to_cloudwatch ? 1 : 0
  vpc_id            = var.vpc_id
  subnet_ids        = local.subnets
  service_name      = "com.amazonaws.${local.region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_sg[0].id
  ]

  private_dns_enabled = var.vpc_endpoint_private_dns_enabled
  tags = merge(var.tags, {
    yor_trace = "39117727-fcb2-41a4-a40b-d5b6756f2ce0"
  })
}

# To Encrypt/Decrypt, a KMS endpoint is needed
resource "aws_vpc_endpoint" "kms" {
  count             = var.vpc_endpoints_enabled ? 1 : 0
  vpc_id            = var.vpc_id
  subnet_ids        = local.subnets
  service_name      = "com.amazonaws.${local.region}.kms"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_sg[0].id
  ]

  private_dns_enabled = var.vpc_endpoint_private_dns_enabled
  tags = merge(var.tags, {
    yor_trace = "3ffb01da-f75f-4e21-a82c-f8ef6b80d940"
  })
}
