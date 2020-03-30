resource null_resource "update_cloudtrail_integrations_when_created" {
  provisioner "local-exec" {
    command     = "pipenv run python ./update_cloudtrail_integrations.py ${var.customer_name} ${var.base_stack_unique_tag}"
    working_dir = path.module
  }

  depends_on = [aws_elasticsearch_domain.host, null_resource.kibana_dashboard_resource]
}

resource null_resource "update_cloudtrail_integrations_when_deleted" {
  provisioner "local-exec" {
    command     = "pipenv install && pipenv run python ./update_cloudtrail_integrations.py ${var.customer_name} ${var.base_stack_unique_tag}"
    when        = "destroy"
    working_dir = path.module
  }
}
