import json
import sys

import boto3

aws_lambda = boto3.client('lambda', region_name='us-west-2')
[_, customer_name, base_stack_unique_tag] = sys.argv
integrations_api = f'bc-integrations-api-{base_stack_unique_tag}'
get_integrations_payload = json.dumps({
    'body': {'customerName': customer_name, 'type': 'cloudtrail', 'format': 'stepFunction'},
    'path': '/invoke/service/getByType',
    'headers': {'Content-Type': 'text/plain'}
})
get_integrations_response = aws_lambda.invoke(FunctionName=integrations_api, Payload=get_integrations_payload)
cloudtrail_integrations = json.load(get_integrations_response['Payload'])['integrations']
for integration in cloudtrail_integrations:
    update_integration_payload = json.dumps({
        'body': {'customerName': customer_name, 'id': integration['id'], 'updatedBy': 'Bridgecrew'},
        'path': '/invoke/service/update',
        'headers': {'Content-Type': 'text/plain'}
    })
    update_integration = aws_lambda.invoke(FunctionName=integrations_api, Payload=update_integration_payload)
