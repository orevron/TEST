import os
import configparser
from argparse import ArgumentParser
import json

from utilsPython.es.es_utilities import ElasticsearchUtilities

# Parsing the command-line parameters
parser = ArgumentParser()
parser.add_argument('--domain_name', required=True)
parser.add_argument('--aws_profile', required=True)
parser.add_argument('--region', required=True)

# Extract the command line variables.tf
args = vars(parser.parse_args())
domain_name = args["domain_name"]
profile = args["aws_profile"]
region = args["region"]

# Initiate elasticsearch instance
es_instance = ElasticsearchUtilities(domain_name=domain_name, region=region, profile=profile)
dir_path = os.path.dirname(os.path.realpath(__file__))

# Creating the index template
for directory, subdirectories, files in os.walk("{}/dashboards".format(dir_path)):

    for file in files:
        filepath = os.path.join(directory, file)
        with open(filepath, 'r') as f:
            dashboard_items = json.load(f)
            version = dashboard_items.pop("version", None)
            for kibana_object in dashboard_items["objects"]:
                kibana_object.pop("version", None)
                if version == "6.8":
                    object_id = kibana_object.pop("_id", None)
                    attributes = kibana_object.pop("_source", None)
                    object_type = kibana_object.pop("_type", None)
                    kibana_object["migrationVersion"] = kibana_object.pop("_migrationVersion", None)
                    kibana_object["type"] = object_type
                else:
                    object_id = kibana_object.pop("id", None)
                    attributes = kibana_object.pop("attributes", None)
                    object_type = kibana_object["type"]
                kibana_object[object_type] = attributes
                es_instance.es_instance.index(index=".kibana", doc_type="doc",
                                              id="{}:{}".format(object_type, object_id), body=kibana_object)
    es_instance.es_instance.index(index=".kibana", doc_type="doc", id="config:6.4.2", body={"type": "config",
                                                                                            "updated_at": "2019-10-21T20:01:48.692Z",
                                                                                            "config": {
                                                                                                "buildNum": 18010,
                                                                                                "defaultIndex": "5cb87170-6f27-11e9-beee-e3bd9c9d6b0a"
                                                                                            }})
print("done importing kibana dashboards")
