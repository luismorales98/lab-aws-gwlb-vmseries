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
    yor_trace = "fb69da21-8e8a-4506-861b-6e67e8bf3bcc"
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
    yor_trace = "323aa97a-83b9-4f94-be6a-6852b40ee156"
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
    yor_trace = "e08e2cc9-685c-48eb-91e3-aaf80d164ed9"
  }
}

resource "aws_s3_bucket_object" "bootstrap_files" {
  for_each = fileset("${path.root}/files", "**")

  bucket = aws_s3_bucket.this.id
  key    = each.value
  source = "${path.root}/files/${each.value}"
  tags = {
    yor_trace = "980b8337-6c9d-42e8-9d8e-d0e7e2079ba1"
  }
}

resource "aws_iam_role" "this" {
  name = "${var.prefix}-${random_id.bucket_id.hex}"

  tags = merge(var.global_tags, {
    yor_trace = "8eac4add-0051-4a30-9f40-0724ff8f8efe"
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
    yor_trace = "2449a0b1-a47c-4d8d-baab-631de31db4f8"
  }
}
