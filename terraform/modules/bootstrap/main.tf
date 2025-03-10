############################################################################################
# Copyright 2020 Palo Alto Networks.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
############################################################################################


resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.prefix}-${random_id.bucket_id.hex}"
  #acl    = "private"
  tags = merge(var.global_tags, {
    yor_trace = "54f67319-0dee-4998-9af8-add97a476b4e"
  })
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_object" "bootstrap_dirs" {
  for_each = toset(var.bootstrap_directories)

  bucket  = aws_s3_bucket.this.id
  key     = each.value
  content = "/dev/null"
  tags = {
    yor_trace = "01f50f8b-04d5-4e19-baec-7bfab2fa0f22"
  }
}

resource "aws_s3_bucket_object" "init_cfg" {
  bucket = aws_s3_bucket.this.id
  key    = "config/init-cfg.txt"
  content = templatefile("${path.module}/init-cfg.txt.tmpl",
    {
      "hostname"         = var.hostname,
      "panorama-server"  = var.panorama-server,
      "panorama-server2" = var.panorama-server2,
      "tplname"          = var.tplname,
      "dgname"           = var.dgname,
      "dns-primary"      = var.dns-primary,
      "dns-secondary"    = var.dns-secondary,
      "vm-auth-key"      = var.vm-auth-key,
      "op-command-modes" = var.op-command-modes
    }
  )
  tags = {
    yor_trace = "1b507f69-849a-44d5-a93b-9bf4c609a0c9"
  }
}

resource "aws_s3_bucket_object" "bootstrap_files" {
  for_each = fileset("${path.root}/files", "**")

  bucket = aws_s3_bucket.this.id
  key    = each.value
  source = "${path.root}/files/${each.value}"
  tags = {
    yor_trace = "4f5b6832-b770-4840-b625-f139ea713542"
  }
}

resource "aws_iam_role" "this" {
  name = "${var.prefix}-${random_id.bucket_id.hex}"

  tags = merge(var.global_tags, {
    yor_trace = "1424a868-9e78-41ba-ac35-0c643ba17025"
  })
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
      "Service": "ec2.amazonaws.com"
    },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "bootstrap" {
  name   = "${var.prefix}-${random_id.bucket_id.hex}"
  role   = aws_iam_role.this.id
  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.this.bucket}"
    },
    {
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::${aws_s3_bucket.this.bucket}/*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.prefix}-${random_id.bucket_id.hex}"
  role = aws_iam_role.this.name
  path = "/"
  tags = {
    yor_trace = "27f589af-5d28-4339-bf1d-3e077e35e3e6"
  }
}
