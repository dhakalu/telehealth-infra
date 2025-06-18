locals {
  domain         = "common"
  s3_bucket_name = "${local.domain}-tfstate-${var.aws_region}"
}

resource "aws_s3_bucket" "tfstate" {
  bucket        = local.s3_bucket_name
  force_destroy = true

  tags = {
    Environment = var.environment
    Domain      = local.domain
  }
}

resource "aws_s3_bucket_versioning" "tfstate_version" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "bucket_name" {
  value = aws_s3_bucket.tfstate.bucket
}
