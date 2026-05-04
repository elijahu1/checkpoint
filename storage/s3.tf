resource "aws_s3_bucket" "name" {
  # config (can be minimal or empty when importing)
}

import {
  to = aws_s3_bucket.name
  id = "remote-state-h1"
}

