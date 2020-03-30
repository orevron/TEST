# Elasticsearch service and Kibana module
This module generates an Elasitcsearch service domain and a Kibana endpoint for a client.
It also creates a policy that allows actions on this domain, and attaches it to the authenticated role from the client's 
Cognito Identity Pool.

Please note that launching as Elasticsearch service takes ~4-10 minutes.

# Variables
| Name | Required? | Type | Default | Example Value | Description |
|---|---|---|---|---|---|
|aws_profile | NO | String | default | dev | The aws credentials profile as denoted in ~/.aws/credentials
|region | NO | String | us-east-2 | us-east-1 | The aws region 
|env | NO | String | dev | prod | The environment will be a part of the elasticsearch domain name 
|customer_name | YES | String | | globality | The name of the client the elasticsearch domain is for. Will be a part of the domain name
|elasticsearch_version | NO | String | "6.4" | "1.5" | The version of elasticsearch to be deployed.
|instance_type | NO | String | m4.xlarge.elasticsearch | | The instance the elasticsearch service will run on
|snapshot_time_hour | NO | Int | 0 | 23 | The hour, in 24 hour format, when a snapshot of the instance will be taken
|ebs_volume_size | NO | Int | 10 | 115 | The storage size of the EBS, in GB.
|user_pool_id | NO | String | us-east-2_wK9LkBMQ6 | | The ID of the Bridgecrew User Pool
|identity_pool_id | YES | String | | IP_acme_dev | The client's identity pool ID
|encrypt_at_rest_enabled| NO | Boolean | true | false | Indicates whether the es instance has encryption-at-rest
|instance_count |NO | Int | 1 | 5 | The number of instances in the cluster

# Outputs
| Name | Example Value | Description |
|---|---|---|
|es_arn | arn:aws:es:us-east-2:090772183824:domain/es-acme-dev | The ARN of the Elasticsearch service
|es_endpoint | search-es-acme-dev-6gpfziwmvlfvdyxt5wl26vsxvu.us-east-2.es.amazonaws.com | The endpoint of the Elasticsearch service
|kibana_url | search-es-acme-dev-6gpfziwmvlfvdyxt5wl26vsxvu.us-east-2.es.amazonaws.com/_plugin/kibana/ | The Kibana endpoint of the Elasticsearch service
|app_client_id| 5ohm6l4qgeod26kn9sciqkkc3h | The app client ID created by ES 