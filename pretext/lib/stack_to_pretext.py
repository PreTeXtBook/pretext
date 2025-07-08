import requests
import json
import re


def replace_latex(text):
    text = re.sub(r"\\\((.*?[^\\])\\\)", r"<m>\1</m>", text)
    text = re.sub(r"\\\[(.*?[^\\])\\]", r"<me>\1</me>", text)
    # We may want to detect align/similar environments inside \[\] and replace them with
    # <md></md> using <mrow></mrow> for each row and \amp for alignment (also \lt, \gt)
    return text


def process_response(qdict):
    # This is a new feature not yet available at https://stack-api.maths.ed.ac.uk/render
    # if qdict["isinteractive"]:
    #     # We could generate a QR code to an online version in the future
    #     return "<statement><p>This question contains interactive elements.</p></statement>"
    qtext = qdict["questionrender"]
    soltext = qdict["questionsamplesolutiontext"]

    # Strip validation and specific feedback
    qtext = re.sub("\[\[validation:(\w+)\]\]", "", qtext)
    qtext = re.sub("\[\[feedback:(\w+)\]\]", "", qtext)

    # Iterate over inputs. For each input with ID ansid:
    ansids = re.findall("\[\[input:(\w+)\]\]", qtext)
    answers = []
    for ansid in ansids:
        ansdata = qdict["questioninputs"][ansid]

        ansconfig = ansdata["configuration"]
        width = ansconfig["boxWidth"]

        answers.append(f'<p><m>{ansdata["samplesolutionrender"]}</m></p>') # still need to wrap into <answer></answer>
        qtext = qtext.replace(f"[[input:{ansid}]]", f'<fillin characters="{width}" name="{ansid}">')

    qtext = replace_latex(qtext)
    soltext = replace_latex(soltext)

    return f'''
    <statement>{qtext}</statement>
    <solution>{soltext}</solution>
    ''' + "\n".join(f"<answer>{ans}</answer>" for ans in answers)


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
