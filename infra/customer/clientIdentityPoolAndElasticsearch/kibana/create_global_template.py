import os
import sys
import configparser
from argparse import ArgumentParser

from os import path

from utilsPython.es.es_utilities import ElasticsearchUtilities

# Parsing the command-line parameters
parser = ArgumentParser()
parser.add_argument('--domain_name', required=True)
parser.add_argument('--aws_profile', required=True)
parser.add_argument('--template_name', required=True)
parser.add_argument('--index_pattern', required=True)
parser.add_argument('--total_fields_limit', required=True)

# Extract the command line variables.tf
args = vars(parser.parse_args())
domain_name = args["domain_name"]
profile = args["aws_profile"]
template_name = args["template_name"]
index_pattern = args["index_pattern"]
total_fields_limit = args["total_fields_limit"]

# Retrieve the aws credentials from credentials file
config.read('{0}/.aws/config'.format(os.environ["HOME"]))
if profile == 'default':
    region = config["{0}".format(profile)]["region"]
else:
    region = config["profile {0}".format(profile)]["region"]

# Initiate elasticsearch instance
es_instance = ElasticsearchUtilities(domain_name=domain_name, profile=profile, region=region)

# Create the index template body object
template_body = {}
template_body["index_patterns"] = [index_pattern]
template_body["settings"] = {}
template_body["settings"]["index.mapping.total_fields.limit"] = total_fields_limit

# Creating the index template
es_instance.create_index_template(template_name, template_body)
