import requests
import json
import re


def process_stack_XML(filename, api_url, seed=None):
    qdata = open(filename).read()
    req_data = {
        "questionDefinition": qdata,
        "seed": seed,
    }

    x = requests.post(api_url, json=req_data)
    qdict = json.loads(x.text)
    # print(json.dumps(qdict, indent=4))
    return process_response(qdict)


if __name__ == "__main__":
    # This is for demonstration purposes and will be removed when integrating
    # this functionality into pretext.

    api_url = 'https://stack-api.maths.ed.ac.uk/render'
    # api_url = 'http://127.0.0.1:3080/render'  # for local docker setup
    filename = "../../examples/stack/minimal/questions/01_integration_with_feedback.xml"
    qpretext = process_stack_XML(filename, api_url)
    print(qpretext)
