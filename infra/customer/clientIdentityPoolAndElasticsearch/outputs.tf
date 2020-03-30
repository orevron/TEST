output "es_arn" {
  value = "${aws_elasticsearch_domain.host.arn}"
}

output "es_endpoint" {
  value = "${aws_elasticsearch_domain.host.endpoint}"
}

output "kibana_url" {
  value = "${aws_elasticsearch_domain.host.kibana_endpoint}"
}

output "authenticated_role_arn" {
  value = "${aws_iam_role.authenticated_role.arn}"
}
