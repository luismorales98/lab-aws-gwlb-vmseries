# Create IAM role
resource "aws_iam_role" "panorama_read_only_role" {
  count = var.panorama_create_iam_role ? 1 : 0

  name               = "${var.prefix_name_tag}PanoramaReadOnly"
  description        = "Allow read-only access to AWS resources."
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  tags = merge(var.global_tags, {
    yor_trace = "a80feab5-222c-43be-b1bf-dd409b756ec0"
  })
}

data "aws_iam_policy" "iam_policy_arn" {
  count = var.panorama_iam_policy_name != "" ? 1 : 0

  name = var.panorama_iam_policy_name
}

# Attach IAM Policy to IAM Role

resource "aws_iam_policy_attachment" "panorama_iam_attach" {
  count = var.panorama_create_iam_role ? 1 : 0

  name       = "${var.prefix_name_tag}panorama_ro_iam_policy_attachment"
  roles      = [aws_iam_role.panorama_read_only_role[0].name]
  policy_arn = data.aws_iam_policy.iam_policy_arn[0].arn
}

resource "aws_iam_instance_profile" "panorama_instance_profile" {
  count = var.panorama_create_iam_instance_profile ? 1 : 0

  name = "${var.prefix_name_tag}panorama_iam_att_profile"
  role = var.panorama_existing_iam_role_name != "" ? var.panorama_existing_iam_role_name : aws_iam_role.panorama_read_only_role[0].name
  tags = {
    yor_trace = "809d77f2-479a-4f4f-98c5-4371978d541a"
  }
}
