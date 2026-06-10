# ********************************************************************
# Copyright 2010-2026 Robert A. Beezer
#
# This file is part of PreTeXt.
#
# PreTeXt is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 or version 3 of the
# License (at your option).
#
# PreTeXt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
# *********************************************************************

# History
# 2026-06-03: created by splitting the WeBWorK processing out of "pretext.py"

import logging
log = logging.getLogger('ptxlogger')

import os
import os.path
import re
import shutil
import subprocess

from . import common
# reuse the canonical warning string defined in common.py
__module_warning = common.__module_warning
import lxml.etree as ET


def webwork_to_xml(
    xml_source, pub_file, stringparams, xmlid_root, abort_early, server_params, dest_dir
):
    # import what we will need
    import urllib.parse  # urlparse()
    import base64  # b64encode()
    import copy
    import tarfile

    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    log.info(
        "string parameters passed to extraction stylesheet: {}".format(stringparams)
    )

    # dest_dir is already resolved by get_destination_directory() in the CLI:
    #   explicit -d > managed directories (generated/webwork/) > cwd fallback.
    # Warn when managed directories are not in use, since WeBWorK output
    # landing in the current directory is likely unintentional.
    generated_dir, external_dir = common.get_managed_directories(xml_source, pub_file)
    if not generated_dir:
        msg = "".join(
            [
                "a publisher file specifying /publication/source/directories/@generated ",
                "is not in use. WeBWorK representations will be in {}",
            ]
        )
        log.warning(msg.format(dest_dir))
    ww_reps_dir = dest_dir
    ww_images_dir = os.path.join(dest_dir, "images")

    # per-exercise representation files live in this directory, named {assembly-id}.xml

    # where generated pg problem files will live (each .pg file will usually be deeper in a folder
    # tree based on document structure and chunking level)
    ww_pg_dir = os.path.join(ww_reps_dir, "pg")

    # create these directories if they don't already exist
    if not (os.path.isdir(ww_reps_dir)):
        os.mkdir(ww_reps_dir)
    if not (os.path.isdir(ww_images_dir)):
        os.mkdir(ww_images_dir)
    if not (os.path.isdir(ww_pg_dir)):
        os.mkdir(ww_pg_dir)

    # execute XSL extraction to get back a tree with fundamental
    # information about webwork exercises in the project
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-pg.xsl")

    # Build the tree into a scratch file
    tmp_dir = common.get_temporary_directory()
    extracted_pg_filename = os.path.join(tmp_dir, "extracted-pg.xml")
    log.debug("Exctracted PG temporarily in {}".format(extracted_pg_filename))
    common.xsltproc(extraction_xslt, xml_source, extracted_pg_filename, None, stringparams)

    # build necessary variables by reading xml with lxml
    extracted_pg_xml = ET.parse(extracted_pg_filename).getroot()
    localization = extracted_pg_xml.get("localization")
    webwork2_server = extracted_pg_xml.find("server-params-pub").get("webwork2-server")
    numbered_title_filesafe = extracted_pg_xml.get("numbered-title-filesafe")
    ww_project_dir = os.path.join(ww_reps_dir, "pg", numbered_title_filesafe)
    if not (os.path.isdir(ww_project_dir)):
        os.mkdir(ww_project_dir)
    ww_macros_dir = os.path.join(ww_project_dir, "macros")
    if not (os.path.isdir(ww_macros_dir)):
        os.mkdir(ww_macros_dir)

    # construct the generated pg files, etc, which may need to be read later for rendering problems
    webwork_sets(xml_source, pub_file, stringparams, ww_pg_dir, False, False)
    pg_macros(xml_source, pub_file, stringparams, ww_macros_dir)

    no_publication_file = False
    if webwork2_server is not None:
        server_params_pub = {
            "webwork2_domain": webwork2_server,
            "courseID": extracted_pg_xml.find("server-params-pub").get("course-id"),
            "user": extracted_pg_xml.find("server-params-pub").get("user-id"),
            "passwd": extracted_pg_xml.find("server-params-pub").get("password"),
            "disableCookies": '1',
        }
        static_processing = extracted_pg_xml.find("processing").attrib["static"]
        pg_location = extracted_pg_xml.find("processing").attrib["pg-location"]
    else:
        no_publication_file = True
        server_params_pub = {
            "webwork2_domain": "https://webwork-ptx.aimath.org",
            "courseID": "anonymous",
            "user": "anonymous",
            "passwd": "anonymous",
            "disableCookies": '1',
        }
        static_processing = 'webwork2'
        pg_location = '/opt/webwork/pg'

    # ideally, pub_file is in use, in which case server_params_pub is nonempty.
    # if no pub_file in use, rely on server_params argument.
    # if both present, use server_params_pub and give warning
    # if neither in use give warning and fail
    if no_publication_file and server_params is None:
        raise ValueError("Either use a publication file or pass a --server argument")
    elif no_publication_file:
        # We rely on the argument server_params
        # This is deprecated in favor of using a publication file
        log.warning("WeBWorK server declared using -s argument.\n" +
              "              Please consider using a publication file with publication/webwork instead.")
        server_params = server_params.strip()
        if (server_params.startswith("(") and server_params.endswith(")")):
            server_params = server_params.strip("()")
            split_server_params = server_params.split(",")
            webwork2_domain = common.sanitize_url(split_server_params[0])
            courseID = common.sanitize_alpha_num_underscore(split_server_params[1])
            user = common.sanitize_alpha_num_underscore(split_server_params[2])
            passwd = common.sanitize_alpha_num_underscore(split_server_params[3])
        else:
            webwork2_domain = common.sanitize_url(server_params)
            courseID        = "anonymous"
            user            = "anonymous"
            passwd          = "anonymous"
    else:
        # Now we know we had a publication file
        # Use it, and warn if server_params argument is also present
        if server_params is not None:
            log.warning("Publication file in use and -s argument passed for WeBWorK server.\n"
                  + "              -s argument will be ignored.\n"
                  + "              Using publication/webwork values (or defaults) instead.")
        webwork2_domain = common.sanitize_url(server_params_pub["webwork2_domain"])
        courseID        = server_params_pub["courseID"]
        user            = server_params_pub["user"]
        passwd          = server_params_pub["passwd"]

    webwork2_domain_webwork2 = webwork2_domain + "/webwork2/"
    webwork2_render_rpc = webwork2_domain_webwork2 + "render_rpc"
    webwork2_html2xml = webwork2_domain_webwork2 + "html2xml"

    webwork2_version = None
    webwork2_major_version = None
    webwork2_minor_version = None

    # Establish if there is any need to use webwork2
    need_for_webwork2 = (
        (static_processing == 'webwork2')
        or (extracted_pg_xml.xpath("//problem[@origin='webwork2']"))
    )

    # Establish if there is any need to use a socket
    need_for_socket = (
        (static_processing == 'local')
        and (extracted_pg_xml.xpath("//problem[@origin!='webwork2']"))
    )

    # at least on Mac installations, requests module is not standard
    try:
        import requests  # webwork server
    except ImportError:
        raise ImportError(__module_warning.format("requests"))

    # Establish WW server version, for live rendering if nothing else
    # First try to identify the WW version according to what a response hash says it is.
    # This should work for 2.17 and beyond.
    try:
        params_for_version_determination = dict(
            problemSeed=1,
            displayMode='PTX',
            courseID=courseID,
            user=user,
            userID=user,
            passwd=passwd,
            disableCookies='1',
            outputformat='raw'
        )
        # Always use html2xml for this; we don't know the server version yet
        version_determination_json = requests.get(url=webwork2_html2xml, params=params_for_version_determination).json()
        if "ww_version" in version_determination_json:
            webwork2_version = version_determination_json["ww_version"]
            webwork2_version_match = re.search(
                r"((\d+)\.(\d+)(\+develop)?)", webwork2_version, re.I
            )
    except Exception as e:
        root_cause = str(e)
        msg = ("PTX:ERROR:   There was a problem contacting the WeBWorK server.\n")
        raise ValueError(msg.format(webwork2_domain_webwork2) + root_cause)

    # Now if that failed, try to infer the version from what is printed on the landing page.
    if webwork2_version == None:
        try:
            landing_page = requests.get(webwork2_domain_webwork2)
        except Exception as e:
            root_cause = str(e)
            msg = (
                "PTX:ERROR:   There was a problem contacting the WeBWorK server.\n"
                + "             Is there a WeBWorK landing page at {}?\n"
            )
            raise ValueError(msg.format(webwork2_domain_webwork2) + root_cause)
        landing_page_text = landing_page.text

        webwork2_version_match = re.search(
            r"WW.VERSION:\s*((\d+)\.(\d+)(\+develop)?)", landing_page_text, re.I
        )

    try:
        webwork2_version = webwork2_version_match.group(1)
        webwork2_major_version = int(webwork2_version_match.group(2))
        webwork2_minor_version = int(webwork2_version_match.group(3))
    except AttributeError as e:
        root_cause = str(e)
        msg = (
            "PTX:ERROR:   PreTeXt was unable to discern the version of the WeBWorK server.\n"
            + "                         Is there a WeBWorK landing page at {}?\n"
            + "                         And does it display the WeBWorK version?\n"
        )
        raise ValueError(msg.format(webwork2_version, webwork2_domain))

    webwork2_path = webwork2_render_rpc if (webwork2_major_version == 2 and webwork2_minor_version >= 19) else webwork2_html2xml

    # initialize dictionaries for all the problem features
    origin = {}
    copied_from = {}
    seed = {}
    path = {}
    pghuman = {}
    pgdense = {}
    for problem in extracted_pg_xml.iter("problem"):
        origin[problem.get("id")] = problem.get("origin")
        seed[problem.get("id")]   = problem.get("seed")
        path[problem.get("id")]   = problem.get("path")
        if problem.get("copied-from") is not None:
            copied_from[problem.get("id")] = problem.get("copied-from")
        else:
            copied_from[problem.get("id")] = None
        if problem.get("origin") == "generated":
            pghuman[problem.get("id")] = problem.find("pghuman").text
            pgdense[problem.get("id")] = problem.find("pgdense").text

    if webwork2_major_version != 2 or webwork2_minor_version < 16:
        msg = (
            "PTX:ERROR:   PreTeXt supports WeBWorK 2.16 and later, and it appears you are attempting to use version: {}\n"
            + "                         Server: {}\n"
            + "                         You may want to use the AIM WeBWorK server at webwork-ptx.aimath.org.\n"
        )
        raise ValueError(msg.format(webwork2_version, webwork2_domain))

    # using a "Session()" will pool connection information
    # since we always hit the same server, this should increase performance
    if need_for_webwork2:
        webwork2_session = requests.Session()

    clientsocket = None

    if need_for_socket:
        import socket
        import json

        perl_executable_cmd = common.get_executable_cmd('perl')[0]
        pgscript = os.path.join(common.get_ptx_path(), 'script', 'webwork', 'pg-ptx.pl')

        extra_macro_dirs = []

        if os.path.exists(ww_macros_dir):
            extra_macro_dirs.append('--extraMacroDir')
            extra_macro_dirs.append(ww_macros_dir)

        if os.path.exists(os.path.join(external_dir, 'macros')):
            extra_macro_dirs.append('--extraMacroDir')
            extra_macro_dirs.append(os.path.join(external_dir, 'macros'))

        proc = subprocess.Popen([
            perl_executable_cmd, pgscript,
            '--externalFileDir', external_dir,
            '--tempDirectory', tmp_dir,
            *extra_macro_dirs,
        ], stdin=None, stdout=None, stderr=None, env={"PG_ROOT": pg_location, "MOJO_MODE": 'production'})
        clientsocket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

        count = 1
        while count > 0 and count < 10:
            try:
                clientsocket.connect(tmp_dir + '/pg-ptx.sock')
                count = 0
            except:
                ++count
        if count > 0:
            raise ValueError("PTX:ERROR: unable to establish connection to local socket")

    NSMAP = {"xml": "http://www.w3.org/XML/1998/namespace"}
    XML = "http://www.w3.org/XML/1998/namespace"
    # Choose one of the dictionaries to take its keys as what to loop through
    for problem in origin:
        if origin[problem] == "webwork2":
            msg = "building representations of webwork2-hosted WeBWorK problem"
        elif origin[problem] == "generated":
            msg = "building representations of generated WeBWorK problem"
        else:
            raise ValueError(
                "PTX:ERROR: problem origin should be 'webwork2' or 'generated', not '{}'".format(
                    origin[problem]
                )
            )
        log.info(msg)

        # If and only if the server is version 2.16, we adjust PG code to use PGtikz.pl
        # instead of PGlateximage.pl
        if webwork2_major_version == 2 and webwork2_minor_version == 16 and origin[problem] == "generated":
            pgdense[problem] = pgdense[problem].replace('PGlateximage.pl','PGtikz.pl')
            pgdense[problem] = pgdense[problem].replace('createLaTeXImage','createTikZImage')
            pgdense[problem] = pgdense[problem].replace('BEGIN_LATEX_IMAGE','BEGIN_TIKZ')
            pgdense[problem] = pgdense[problem].replace('END_LATEX_IMAGE','END_TIKZ')
            pghuman[problem] = pghuman[problem].replace('PGlateximage.pl','PGtikz.pl')
            pghuman[problem] = pghuman[problem].replace('createLaTeXImage','createTikZImage')
            pghuman[problem] = pghuman[problem].replace('BEGIN_LATEX_IMAGE','BEGIN_TIKZ')
            pghuman[problem] = pghuman[problem].replace('END_LATEX_IMAGE','END_TIKZ')
            # We crudely remove tikzpicture environment delimiters
            pgdense[problem] = pgdense[problem].replace('\\begin{tikzpicture}','')
            pgdense[problem] = pgdense[problem].replace('\\end{tikzpicture}','')
            pghuman[problem] = pghuman[problem].replace('\\begin{tikzpicture}','')
            pghuman[problem] = pghuman[problem].replace('\\end{tikzpicture}','')

        # The code in pgdense[problem] may have `$refreshCachedImages=1;`
        # We want to keep this for the code that is sent to the server for static harvesting,
        # but kill this for the code that is used repeatedly by embedded problems in HTML
        # So here we branch a copy for embedding where we kill `$refreshCachedImages=1;`
        # But we can't literally just remove that, since an author may have used something
        # like `$refreshCachedImages  =  'true' ;` so instead, we change `$refreshCachedImages`
        # to something inert
        if origin[problem] == "generated":
            embed_problem = re.sub(r'(refreshCachedImages)(?![\w\d])', r'\1Inert', pgdense[problem])

        # make base64 for PTX problems for webwork prior to 2.19
        if origin[problem] == "generated":
            if webwork2_minor_version < 19:
                pgbase64 = base64.b64encode(bytes(pgdense[problem], "utf-8")).decode("utf-8")
                embed_problem_base64 = base64.b64encode(bytes(embed_problem, "utf-8")).decode("utf-8")

        if static_processing == 'local' and origin[problem] != 'webwork2':
            socket_params = { "problemSeed": seed[problem], "problemUUID": problem }

            if origin[problem] == 'generated':
                socket_params["source"] = pgdense[problem]
            else:
                socket_params["sourceFilePath"] = os.path.join(external_dir, path[problem])

            msg = "sending {} to socket to save in {}: origin is '{}'"
            log.info(msg.format(problem, ww_reps_dir, origin[problem]))
            clientsocket.send(json.dumps(socket_params).encode('utf-8'))

            buffer = bytearray()
            while True:
                received = clientsocket.recv(4096)
                if not received: break
                buffer.extend(received)
                if buffer.endswith(b'ENDOFSOCKETDATA'): break

            response = buffer.decode().replace('ENDOFSOCKETDATA', '')

        else:
            # Construct URL to get static version from server
            # First establish how the acctual problem code
            # should be delivered to whatever will render it
            if webwork2_minor_version >= 19:
                if origin[problem] == "webwork2":
                    server_params_source = {"sourceFilePath":path[problem]}
                else:
                    server_params_source = {"rawProblemSource":pgdense[problem]}
            else:
                # server_params_source is tuple rather than dictionary to enforce consistent order in url parameters
                if origin[problem] == "webwork2":
                    server_params_source = (("sourceFilePath", path[problem]))
                else:
                    server_params_source = (("problemSource", pgbase64))

            if webwork2_minor_version >= 19:
                server_params = {
                    "showSolutions": "1",
                    "showHints": "1",
                    "displayMode": "PTX",
                    "courseID": courseID,
                    "user": user,
                    "passwd": passwd,
                    "outputformat": "ptx",
                    "disableCookies": '1',
                    "problemSeed": seed[problem],
                    "problemUUID": problem,
                }
                server_params.update(server_params_source)
            else:
                # server_params is tuple rather than dictionary to enforce consistent order in url parameters
                server_params = (
                    ("answersSubmitted", "0"),
                    ("showSolutions", "1"),
                    ("showHints", "1"),
                    ("displayMode", "PTX"),
                    ("courseID", courseID),
                    ("userID", user),
                    ("course_password", passwd),
                    ("outputformat", "ptx"),
                    server_params_source,
                    ("problemSeed", seed[problem]),
                    ("problemUUID", problem),
                )

            msg = "sending {} to server to save in {}: origin is '{}'"
            log.info(msg.format(problem, ww_reps_dir, origin[problem]))
            if origin[problem] == "webwork2":
                log.debug(
                    "server-to-ptx: {}\n{}\n{}\n{}".format(
                        problem, webwork2_path, path[problem], ww_reps_dir
                    )
                )
            elif origin[problem] == "generated":
                log.debug(
                    "server-to-ptx: {}\n{}\n{}\n{}".format(
                        problem, webwork2_path, pgdense[problem], ww_reps_dir
                    )
                )

            # Ready, go out on the wire
            try:
                if webwork2_minor_version >= 19:
                    response = webwork2_session.post(webwork2_path, data=server_params)
                else:
                    response = webwork2_session.get(webwork2_path, params=server_params)
                log.debug("Getting problem response from: " + response.url)

            except requests.exceptions.RequestException as e:
                root_cause = str(e)
                msg = "PTX:ERROR: there was a problem collecting a problem,\n Server: {}\nRequest Parameters: {}\n"
                raise ValueError(msg.format(webwork2_path, server_params) + root_cause)

            # TODO: Instead of this use a different variable shared by the local script approach.
            response = response.text

        # Check for errors with PG processing
        # Get booleans signaling badness: file_empty, no_compile, bad_xml, no_statement
        file_empty = "ERROR:  This problem file was empty!" in response

        no_compile = (
            "ERROR caught by Translator while processing" in response
        )

        bad_xml = False
        try:
            response_root = ET.fromstring(bytes(response, encoding='utf-8'))
        except:
            response_root = ET.Element("webwork")
            bad_xml = True

        no_statement = False
        if not bad_xml:
            if response_root.find(".//statement") is None:
                no_statement = True
        badness = file_empty or no_compile or bad_xml or no_statement

        # Custom responses for each type of badness
        # message for terminal log
        # tip reminding about -a (abort) option
        # value for @failure attribute in static element
        # base64 for a shell PG problem that simply indicates there was an issue and says what the issue was
        badness_msg = ""
        badness_tip = ""
        badness_type = ""
        badness_base64 = ""
        # NB: in WeBWorK 2.17+, the response from a nonexistent problem is not distinguishable from
        # the response from a problem that has broken code. So even when a file is empty, file_empty
        # will be false and instead no_compile will be true.
        if file_empty:
            badness_msg = "PTX:ERROR: WeBWorK problem {} was empty\n"
            badness_tip = ""
            badness_type = "empty"
            badness_base64 = "RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBGaWxlIFdhcyBFbXB0eQoKRU5EX1BHTUwKCkVORERPQ1VNRU5UKCk7"
        elif no_compile:
            badness_msg = (
                "PTX:ERROR: WeBWorK problem {} with seed {} is either empty or failed to compile  \n{}\n"
            )
            badness_tip = (
                "  Use -a to halt with full PG and returned content"
                if (origin[problem] == "generated")
                else "  Use -a to halt with returned content"
            )
            badness_type = "compile"
            badness_base64 = "RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEb2VzIE5vdCBFeGlzdCBPciBEaWQgTm90IENvbXBpbGUKCkVORF9QR01MCgpFTkRET0NVTUVOVCgpOw=="
        elif bad_xml:
            badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} does not return valid XML  \n  It may not be PTX compatible  \n{}\n"
            badness_tip = "  Use -a to halt with returned content"
            badness_type = "xml"
            badness_base64 = "RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IEdlbmVyYXRlIFZhbGlkIFhNTAoKRU5EX1BHTUwKCkVORERPQ1VNRU5UKCk7"
        elif no_statement:
            badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} does not have a statement tag \n  Maybe it uses something other than BEGIN_TEXT or BEGIN_PGML to print the statement in its PG code \n{}\n"
            badness_tip = "  Use -a to halt with returned content"
            badness_type = "statement"
            badness_base64 = "RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IEhhdmUgYSBbfHN0YXRlbWVudHxdKiBUYWcKCkVORF9QR01MCgpFTkRET0NVTUVOVCgpOw=="

        # If we are aborting upon recoverable errors...
        if abort_early:
            if badness:
                debugging_help = response
                if origin[problem] == "generated" and no_compile:
                    debugging_help += "\n" + pghuman[problem]
                raise ValueError(
                    badness_msg.format(
                        path[problem], seed[problem], debugging_help
                    )
                )

        # Now a block where we edit the text from the response before using it to build XML
        # First some special handling for verbatim in answers.
        # Then change targets of img (while downloading the original target as an image file)

        # When a PG Math Object is a text string that has to be rendered in a math environment,
        # depending on the string's content and the version of WeBWorK, it can come back as:

        # \text{string}            only when the string is built solely from -A-Za-z0-9 ,.;:+=?()[]
        # \verb\x1Fstring\x1F      WW HTML output for 2.15+
        # {\verb\rstring\r}        WW PTX (and TeX) output starting with 2.15, hopefully stable

        # We would like to replace all instances with \text{string},
        # but in addition to character escaping issues, \text does not behave equally in TeX and MathJax.
        # Certain characters _need_ to be escaped in TeX, but must _not_ be escaped in MathJax.
        # So we make the change after checking that none of the dangerous characters are present,
        # and otherwise leave \verb in place. But we replace the delimiter with the first available
        # "normal" character.
        # \r would be valid XML, but too unpredictable in translations

        verbatim_split = re.split(
            r"(\\verb\x1F.*?\x1F|\\verb\r.*?\r)", response
        )
        response_text = ""
        for item in verbatim_split:
            if re.match(r"^\\verb(\x1F|\r).*?\1$", item):
                (original_delimiter, verbatim_content) = re.search(
                    r"\\verb(\x1F|\r)(.*?)\1", item
                ).group(1, 2)
                if set(
                    ["#", "%", "&", "<", ">", "\\", "^", "_", "`", "|", "~"]
                ).intersection(set(list(verbatim_content))):
                    index = 33
                    while index < 127:
                        if (
                            index in [42, 34, 38, 39, 59, 60, 62]
                            or chr(index) in verbatim_content
                        ):
                            # the one character you cannot use with \verb as a delimiter is chr(42), *
                            # the others excluded here are the XML control characters,
                            # and semicolon for good measure (as the closer for escaped characters)
                            index += 1
                        else:
                            break
                    if index == 127:
                        log.warning(
                            "Could not find delimiter for verbatim expression"
                        )
                        return "!Could not find delimiter for verbatim expression.!"
                    else:
                        response_text += item.replace(original_delimiter, chr(index))
                else:
                    # These three characters are escaped in both TeX and MathJax
                    text_content = verbatim_content.replace("$", "\\$")
                    text_content = text_content.replace("{", "\\{")
                    text_content = text_content.replace("}", "\\}")
                    response_text += "\\text{" + text_content + "}"
            else:
                response_text += item

        # need to loop through content looking for images with pattern:
        #
        #   <image source="relative-path-to-temporary-image-on-server"
        #
        graphics_pattern = re.compile(r'<image.*?source="([^"]+)"')

        # replace filenames, download images with new filenames
        count = 0
        # ww_image_url will be the URL to an image file used by the problem on the ww server
        for match in re.finditer(graphics_pattern, response_text):
            ww_image_full_path = match.group(1)
            if static_processing == 'local' and origin[problem] != 'webwork2':
                ww_image_scheme = ''
            else:
                ww_image_url = urllib.parse.urljoin(webwork2_domain, ww_image_full_path)
                # strip away the scheme and location, if present (e.g 'https://webwork-ptx.aimath.org/')
                ww_image_url_parsed = urllib.parse.urlparse(ww_image_url)
                ww_image_scheme = ww_image_url_parsed.scheme
                ww_image_full_path = ww_image_url_parsed.path
            count += 1
            # split the full path into (path, file). path could theoretically be empty.
            ww_image_path, ww_image_filename = os.path.split(ww_image_full_path)
            # split the filename into (name, extension). extension can be empty or like '.png'.
            ww_image_name, image_extension = os.path.splitext(ww_image_filename)
            # rename, eg, webwork-representations/webwork-5-image-3.png
            ptx_image_name = problem + "-image-" + str(count)
            ptx_image_filename = ptx_image_name + image_extension
            if image_extension == ".tgz":
                ptx_image = ptx_image_name
            else:
                ptx_image = ptx_image_name + image_extension
            if ww_image_scheme:
                image_url = ww_image_url
            else:
                image_url = urllib.parse.urljoin(webwork2_domain, ww_image_full_path)
            # modify PTX problem source to include local versions
            if generated_dir:
                if "xmlns:pi=" not in response_text:
                    response_text = response_text.replace(
                        "<webwork>",
                        '<webwork xmlns:pi="http://pretextbook.org/2020/pretext/internal">',
                    )
                response_text = re.sub(
                    r"(<image[^>]*? )source=",
                    r"\1pi:generated=",
                    response_text,
                    count=0,
                    flags=0,
                )
                # the filepath constructed below will be used for web addresses of image files
                # and filepaths in LaTeX for image inclusion. Even for a Windows user, forward
                # slashes are in play, not backward slashes. So we inteentionally do not use
                # os.path.join(). Perhaps in the future we decide to use a posix path constructor.
                response_text = response_text.replace(
                    ww_image_full_path, "webwork/images/" + ptx_image
                )
            else:
                # see note above about posix path construction
                response_text = response_text.replace(
                    ww_image_full_path, "images/" + ptx_image
                )
            if static_processing == 'local' and origin[problem] != 'webwork2':
                image_local_path = ww_image_full_path.replace('/pg_files/tmp', tmp_dir)
                destination_image_file = os.path.join(ww_images_dir, ptx_image_filename)

                try:
                    log.info(
                        "saving image file {} {} in {}".format(
                            ptx_image_filename,
                            "(contents)" if image_extension == ".tgz" else "",
                            ww_images_dir
                        )
                    )
                    shutil.copy2(image_local_path, destination_image_file)
                except Exception as e:
                    raise ValueError("PTX:ERROR:   There was an error copying the image file {} to {}.\n".format(
                        image_local_path, destination_image_file
                    ) + str(e))
            else:
                # download actual image files
                # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests
                try:
                    image_response = webwork2_session.get(image_url)
                except requests.exceptions.RequestException as e:
                    root_cause = str(e)
                    msg = "PTX:ERROR: there was a problem downloading an image file,\n URL: {}\n"
                    raise ValueError(msg.format(image_url) + root_cause)
                # and save the image itself
                destination_image_file = os.path.join(ww_images_dir, ptx_image_filename)
                try:
                    with open(destination_image_file, "wb") as image_file:
                        msg = "saving image file {} {} in {}"
                        qualifier = ""
                        if image_extension == ".tgz":
                            qualifier = "(contents)"
                        log.info(msg.format(ptx_image_filename, qualifier, ww_images_dir))
                        image_file.write(image_response.content)
                except Exception as e:
                    root_cause = str(e)
                    msg = "PTX:ERROR: there was a problem saving an image file,\n Filename: {}\n"
                    raise ValueError(
                        msg.format(destination_image_file)
                        + root_cause
                    )
            # unpack if it's a tgz
            if image_extension == ".tgz":
                tgzfile = tarfile.open(destination_image_file)
                tgzfile.extractall(os.path.join(ww_images_dir))
                tgzfile.close()
                # template for error message(s)
                msg = "{} did not contain a .{} file"
                # attempt to recover four file formats, with warnings
                for ext in ["tex", "pdf", "svg", "png"]:
                    try:
                        os.rename(
                            os.path.join(ww_images_dir, "image.{}".format(ext)),
                            os.path.join(ww_images_dir, ptx_image_name + ".{}".format(ext)),
                        )
                    except:
                        log.warning(msg.format(destination_image_file, ext))
                os.remove(os.path.join(ww_images_dir, ptx_image_filename))

        # Use "webwork-reps" as the root tag for this problem's representation file
        webwork_reps = ET.Element("webwork-reps", nsmap=NSMAP)
        # There once was a "version 1" structure to the representations file before "version 2".
        # For a while, both were supported. Neither was officially defined anywhere, and now
        # "version 1" is a thing of the past. We still mark the current representations file as
        # "version 2" here, but it has no effect as all the code elsewhere now assumes "version 2".
        webwork_reps.set("version", "2")
        webwork_reps.set("webwork2_major_version", str(webwork2_major_version))
        webwork_reps.set("webwork2_minor_version", str(webwork2_minor_version))
        webwork_reps.set("{%s}id" % (XML), "extracted-" + problem)
        webwork_reps.set("assembly-id", problem)
        static = ET.SubElement(webwork_reps, "static")
        static.set("seed", seed[problem])
        if origin[problem] == "webwork2":
            static.set("source", path[problem])

        # If there is "badness"...
        # Build 'shell' problems to indicate failures.  Fall through (no
        # "continue") so that rendering-data, pg, and the per-exercise file
        # write below all execute — those sections have explicit "if badness"
        # branches that produce a minimal faux problem, and assembly relies
        # on the file existing for every WeBWorK exercise.
        if badness:
            log.error(badness_msg.format(path[problem], seed[problem], badness_tip))
            static.set("failure", badness_type)
            statement = ET.SubElement(static, "statement")
            p = ET.SubElement(statement, "p")
            p.text = badness_msg.format(path[problem], seed[problem], badness_tip)
        else:
            # Start appending XML children
            response_root = ET.fromstring(bytes(response_text, encoding='utf-8'))

            # This recursive function is needed in the case of nested tasks.
            # It is written in such a way to handle task with no nesting, and even an exercise without any task.

            def static_webwork_level(write, read):
                # (tree we are building, tree we take from)
                # since write is a tree and read is a tree, we use deepcopy to make sure
                # that when we append nodes we are appending new ones, not intertwining the trees

                tasks = read.findall("./task")
                if tasks:
                    titles = read.xpath("./title")
                    if titles:
                        for ttl in list(titles):
                            title = copy.deepcopy(ttl)
                            write.append(title)
                    introductions = read.xpath(
                        "./statement[following-sibling::task]|./statement[following-sibling::stage]"
                    )
                    if introductions:
                        introduction = ET.SubElement(write, "introduction")
                        for intro in list(introductions):
                            for child in intro:
                                chcopy = copy.deepcopy(child)
                                introduction.append(chcopy)
                    for tsk in list(tasks):
                        task = ET.SubElement(write, "task")
                        static_webwork_level(task, tsk)
                    conclusions = read.xpath("./statement[preceding-sibling::task]")
                    if conclusions:
                        conclusion = ET.SubElement(write, "conclusion")
                        for conc in list(conclusions):
                            for child in conc:
                                chcopy = copy.deepcopy(child)
                                conclusion.append(chcopy)
                else:
                    titles = read.xpath("./title")
                    if titles:
                        for ttl in list(titles):
                            title = copy.deepcopy(ttl)
                            write.append(title)
                    statements = read.xpath(
                        "./statement[not(preceding-sibling::task or following-sibling::task)]"
                    )
                    if statements:
                        statement = ET.SubElement(write, "statement")
                        for stat in list(statements):
                            for child in stat:
                                chcopy = copy.deepcopy(child)
                                statement.append(chcopy)
                    hints = read.xpath("./hint")
                    if hints:
                        hint = ET.SubElement(write, "hint")
                        for hnt in list(hints):
                            for child in hnt:
                                chcopy = copy.deepcopy(child)
                                hint.append(chcopy)
                    answer_names = read.xpath(".//fillin/@name|.//var/@name|.//ul/@name|.//ol/@name|.//dl/@name")
                    answer_hashes = response_root.find("./answerhashes")
                    if answer_hashes is not None:
                        for ans in list(answer_hashes):
                            if ans.get("ans_name") in list(answer_names):
                                correct_ans = ans.get("correct_ans", "")
                                correct_ans_latex_string = ans.get(
                                    "correct_ans_latex_string", ""
                                )
                                if correct_ans != "" or correct_ans_latex_string != "":
                                    answer = ET.SubElement(write, "answer")
                                    p = ET.SubElement(answer, "p")
                                    if correct_ans_latex_string:
                                        m = ET.SubElement(p, "m")
                                        m.text = correct_ans_latex_string
                                    elif correct_ans:
                                        p.text = correct_ans
                    solutions = read.xpath("./solution")
                    if solutions:
                        solution = ET.SubElement(write, "solution")
                        for sol in list(solutions):
                            for child in sol:
                                chcopy = copy.deepcopy(child)
                                solution.append(chcopy)

            static_webwork_level(static, response_root)

        # Add rendering-data element with attribute data for rendering a problem
        if (badness or origin[problem] == "generated" or (webwork2_minor_version < 19 and origin[problem] != "webwork2")):
            source_key = "problemSource"
        else:
            source_key = "sourceFilePath"

        if badness:
            source_value = badness_base64
        else:
            if origin[problem] == "webwork2":
                source_value = path[problem]
            else:
                if webwork2_minor_version < 19:
                    source_value = embed_problem_base64
                else:
                    if copied_from[problem] is not None:
                        source_value = path[copied_from[problem]]
                    else:
                        source_value = path[problem]

        rendering_data = ET.SubElement(webwork_reps, "rendering-data")
        rendering_data.set(source_key, source_value)
        rendering_data.set("origin", origin[problem])
        rendering_data.set("domain", webwork2_domain)
        rendering_data.set("course-id", courseID)
        rendering_data.set("user-id", user)
        rendering_data.set("passwd", passwd)
        rendering_data.set("language", localization)

        # Add PG for PTX-authored problems
        # Empty tag with @source for server problems
        pg = ET.SubElement(webwork_reps, "pg")
        try:
            pg.set("copied-from", copied_from[problem])
        except Exception:
            pass

        if origin[problem] == "generated":
            if badness:
                pg_shell = "DOCUMENT();\nloadMacros('PGstandard.pl','PGML.pl','PGcourse.pl');\nTEXT(beginproblem());\nBEGIN_PGML\n{}END_PGML\nENDDOCUMENT();"
                formatted_pg = pg_shell.format(
                    badness_msg.format(path[problem], seed[problem], badness_tip)
                )
            else:
                formatted_pg = pghuman[problem]
            pg.text = ET.CDATA("\n" + formatted_pg)
        elif origin[problem] == "webwork2":
            pg.set("source", path[problem])

        # write one file per exercise, named by @assembly-id
        include_file_name = os.path.join(ww_reps_dir, problem + ".xml")
        try:
            with open(include_file_name, "wb") as include_file:
                include_file.write(
                    ET.tostring(
                        webwork_reps,
                        encoding="utf-8",
                        xml_declaration=True,
                        pretty_print=True,
                    )
                )
        except Exception as e:
            root_cause = str(e)
            msg = "PTX:ERROR: there was a problem writing a problem to the file: {}\n"
            raise ValueError(msg.format(include_file_name) + root_cause)

    # close session to avoid resource wanrnings
    try:
        webwork2_session.close()
    except:
        pass

    # close the socket
    if clientsocket:
        clientsocket.send(b'quit')


def webwork_sets(xml_source, pub_file, stringparams, dest_dir, tgz, need_macros):

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    if pub_file:
        stringparams["publisher"] = pub_file
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "pretext-ww-problem-sets.xsl")
    tmp_dir = common.get_temporary_directory()
    common.xsltproc(extraction_xslt, xml_source, None, output_dir=tmp_dir, stringparams=stringparams)
    # We don't explicitly know the name of the folder that has all of the sets
    # But it is the only thing in the tmp_dir
    folder_name = os.listdir(tmp_dir)[0]
    folder = os.path.join(tmp_dir, folder_name)
    macros_folder = os.path.join(folder, 'macros')
    os.mkdir(macros_folder)
    if need_macros:
        pg_macros(xml_source, pub_file, stringparams, macros_folder)
    if tgz:
        archive_file = os.path.join(tmp_dir, folder_name + ".tgz")
        common.targz(archive_file, folder)
        shutil.copy2(archive_file, dest_dir)
    else:
        # with multiple files, we need to copy a tree
        # see comments at  copy_build_directory()
        # before replacing with  shutil.copytree()
        common.copy_build_directory(folder, os.path.join(dest_dir,folder_name))


def pg_macros(xml_source, pub_file, stringparams, dest_dir):

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    if pub_file:
        stringparams["publisher"] = pub_file
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "support", "pretext-pg-macros.xsl")
    common.xsltproc(extraction_xslt, xml_source, None, output_dir=dest_dir, stringparams=stringparams)
