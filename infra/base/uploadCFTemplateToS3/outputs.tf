output "template_url" {
  value = local.cloudtrail_template_object_url == "none" ? "no such bucket" : local.cloudtrail_template_object_url
}

output "config_template_url" {
  value = local.config_template_object_url
}
