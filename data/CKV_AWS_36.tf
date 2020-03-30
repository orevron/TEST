resource "aws_cloudtrail" "foobar" {
  name                          = "tf-trail-foobar"
  s3_bucket_name                = "suli"
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
}