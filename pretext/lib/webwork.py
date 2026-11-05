# ********************************************************************
# Copyright (C) 2010-2026  Robert A. Beezer
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
    xml_source, pub_file, stringparams, xmlid_root, abort_early, server_params, dest_dir, ext_converter
):
    # ext_converter: an optional hook for external libraries to patch
    #                the conversion of individual problems.  The intent is that
    #                ext_converter attempts to use a cached version of a problem's
    #                representations, or else calls individual_webwork_conversion()
    #                to build them (and cache them).

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

    # Build the tree into a scratch file.  The stylesheet also writes one
    # file per problem (the tree restricted to that problem, named by its
    # id) into a scratch directory; each is the input to the conversion
    # of that problem, below.
    tmp_dir = common.get_temporary_directory()
    extracted_pg_filename = os.path.join(tmp_dir, "extracted-pg.xml")
    problems_dir = os.path.join(tmp_dir, "problems")
    os.mkdir(problems_dir)
    log.debug("Extracted PG temporarily in {}".format(extracted_pg_filename))
    log.debug("Extracted PG for individual problems temporarily in {}".format(problems_dir))
    common.xsltproc(extraction_xslt, xml_source, extracted_pg_filename, problems_dir, stringparams)

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

    # The extracted problems always carry the server and its credentials,
    # from the "webwork" element of a publication file or from the defaults
    # for that element.  The "server_params" argument is not read; it stays
    # in the signature because the PreTeXt command-line interface passes it.
    webwork2_domain = common.sanitize_url(webwork2_server)
    courseID        = extracted_pg_xml.find("server-params-pub").get("course-id")
    user            = extracted_pg_xml.find("server-params-pub").get("user-id")
    passwd          = extracted_pg_xml.find("server-params-pub").get("password")
    static_processing = extracted_pg_xml.find("processing").attrib["static"]
    pg_location = extracted_pg_xml.find("processing").attrib["pg-location"]

    # The password goes into the representations file and from there into
    # the HTML of every exercise, so readers can see it once published
    if passwd != "anonymous":
        log.warning("WeBWorK password is not \"anonymous\".\n" +
              "              It is written into the generated representations file and into the HTML\n" +
              "              of every WeBWorK exercise, where any reader can see it.\n" +
              "              Use only credentials you are willing to make public.")

    webwork2_domain_webwork2 = webwork2_domain + "/webwork2/"
    webwork2_render_rpc = webwork2_domain_webwork2 + "render_rpc"

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
        render_rpc_response = requests.get(url=webwork2_render_rpc, params=params_for_version_determination)
    except Exception as e:
        root_cause = str(e)
        msg = ("PTX:ERROR:   There was a problem contacting the WeBWorK server.\n")
        raise ValueError(msg.format(webwork2_domain_webwork2) + root_cause)

    if render_rpc_response.status_code == 200:
        # A server that refuses the credentials still answers 200, with a
        # line of text in place of the JSON of a rendered problem.  Every
        # JSON decoding error that "requests" raises is a ValueError.
        try:
            version_determination_json = render_rpc_response.json()
        except ValueError:
            server_reply = " ".join(render_rpc_response.text.split())[:200]
            msg = ("The WeBWorK server at {} answered, but did not accept the course \"{}\",\n" +
                  "              the user \"{}\", and the password given in the \"webwork\" element\n" +
                  "              of the publication file.  The server replied: {}")
            log.fatal(msg.format(webwork2_domain, courseID, user, server_reply))
        if "ww_version" in version_determination_json:
            webwork2_version = version_determination_json["ww_version"]
            webwork2_version_match = re.search(
                r"((\d+)\.(\d+)(\+develop)?)", webwork2_version, re.I
            )

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

    if webwork2_major_version != 2 or webwork2_minor_version < 19:
        msg = (
            "PTX:ERROR:   PreTeXt supports WeBWorK 2.19 and later, and it appears you are attempting to use version: {}\n"
            + "                         Server: {}\n"
            + "                         You may want to use the AIM WeBWorK server at webwork-ptx.aimath.org.\n"
        )
        raise ValueError(msg.format(webwork2_version, webwork2_domain))

    # using a "Session()" will pool connection information
    # since we always hit the same server, this should increase performance
    webwork2_session = None
    if need_for_webwork2:
        webwork2_session = requests.Session()

    # Folders of macro files that problems may load: the document's own,
    # built from "docinfo" by pg_macros() above, and an author's, in the
    # external directory.  A local renderer reads these; a server reads
    # the copies uploaded to its course.
    macro_dirs = [ww_macros_dir]
    if external_dir:
        macro_dirs.append(os.path.join(external_dir, 'macros'))
    macro_dirs = [d for d in macro_dirs if os.path.isdir(d)]

    clientsocket = None

    if need_for_socket:
        import socket

        perl_executable_cmd = common.get_executable_cmd('perl')[0]
        pgscript = os.path.join(common.get_ptx_path(), 'script', 'webwork', 'pg-ptx.pl')

        extra_macro_dirs = []
        for macro_dir in macro_dirs:
            extra_macro_dirs.append('--extraMacroDir')
            extra_macro_dirs.append(macro_dir)

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

    # Everything the conversion of a problem needs to know about how
    # problems are rendered, which is the same for every problem.
    # individual_webwork_conversion() documents the keys.
    renderer = {
        "static_processing": static_processing,
        "generated_dir": generated_dir,
        "external_dir": external_dir,
        "tmp_dir": tmp_dir,
        "macro_dirs": macro_dirs,
        "localization": localization,
        "webwork2_domain": webwork2_domain,
        "webwork2_render_rpc": webwork2_render_rpc,
        "webwork2_major_version": webwork2_major_version,
        "webwork2_minor_version": webwork2_minor_version,
        "courseID": courseID,
        "user": user,
        "passwd": passwd,
        "webwork2_session": webwork2_session,
        "clientsocket": clientsocket,
    }

    # convert each problem, in document order, from the file the
    # stylesheet wrote for it
    for problem in extracted_pg_xml.iter("problem"):
        problem_file = os.path.join(problems_dir, problem.get("id") + ".xml")
        if ext_converter:
            ext_converter(problem_file, dest_dir, abort_early, renderer)
        else:
            individual_webwork_conversion(problem_file, dest_dir, abort_early, renderer)

    # close session to avoid resource warnings
    if webwork2_session:
        webwork2_session.close()

    # close the socket
    if clientsocket:
        clientsocket.send(b'quit')


def individual_webwork_conversion(problem_file, dest_dir, abort_early, renderer):
    """Build the file of representations of one WeBWorK problem

    problem_file - a file written by "extract-pg.xsl" for one problem,
                   as webwork_to_xml() arranges
    dest_dir     - the directory for the representations file, which
                   holds any images of the problem in its "images"
                   subdirectory; both directories exist already
    abort_early  - raise an error for a problem that fails to render,
                   rather than writing representations that report
                   the failure
    renderer     - a dictionary, built by webwork_to_xml(), of how
                   problems are rendered:
                     static_processing - "webwork2" (a server) or "local"
                     generated_dir, external_dir - the managed directories
                     tmp_dir - scratch directory, where local rendering
                               leaves image files
                     macro_dirs - folders of macro files that problems
                               may load; their content is not in the
                               problem's file
                     localization - the document language
                     webwork2_domain, webwork2_render_rpc - the server
                               and its rendering endpoint
                     webwork2_major_version, webwork2_minor_version
                     courseID, user, passwd - credentials for the server
                     webwork2_session - a "requests" session with the
                               server, or None
                     clientsocket - a socket to a local renderer, or None

    Returns the list of files written: the representations file, then
    any image files.  The names of all of these begin with the problem's
    id, so a caller may cache them as the output of this one problem.
    """
    import urllib.parse  # urlparse()
    import copy  # deepcopy()
    import tarfile  # open()
    import json  # dumps()

    # at least on Mac installations, requests module is not standard
    try:
        import requests  # webwork server
    except ImportError:
        raise ImportError(__module_warning.format("requests"))

    static_processing = renderer["static_processing"]
    generated_dir = renderer["generated_dir"]
    external_dir = renderer["external_dir"]
    tmp_dir = renderer["tmp_dir"]
    localization = renderer["localization"]
    webwork2_domain = renderer["webwork2_domain"]
    webwork2_render_rpc = renderer["webwork2_render_rpc"]
    webwork2_major_version = renderer["webwork2_major_version"]
    webwork2_minor_version = renderer["webwork2_minor_version"]
    courseID = renderer["courseID"]
    user = renderer["user"]
    passwd = renderer["passwd"]
    webwork2_session = renderer["webwork2_session"]
    clientsocket = renderer["clientsocket"]

    ww_reps_dir = dest_dir
    ww_images_dir = os.path.join(dest_dir, "images")

    # the problem's features, from the one "problem" element of the file
    problem_element = ET.parse(problem_file).getroot().find("problem")
    problem = problem_element.get("id")
    origin = problem_element.get("origin")
    seed = problem_element.get("seed")
    path = problem_element.get("path")
    copied_from = problem_element.get("copied-from")
    copied_from_path = problem_element.get("copied-from-path")
    pghuman = None
    pgdense = None
    if origin == "generated":
        pghuman = problem_element.find("pghuman").text
        pgdense = problem_element.find("pgdense").text

    # the files this problem produces
    written_files = []

    if origin == "webwork2":
        msg = "building representations of webwork2-hosted WeBWorK problem"
    elif origin == "generated":
        msg = "building representations of generated WeBWorK problem"
    else:
        raise ValueError(
            "PTX:ERROR: problem origin should be 'webwork2' or 'generated', not '{}'".format(
                origin
            )
        )
    log.info(msg)

    if static_processing == 'local' and origin != 'webwork2':
        socket_params = { "problemSeed": seed, "problemUUID": problem }

        if origin == 'generated':
            socket_params["source"] = pgdense
        else:
            socket_params["sourceFilePath"] = os.path.join(external_dir, path)

        msg = "sending {} to socket to save in {}: origin is '{}'"
        log.info(msg.format(problem, ww_reps_dir, origin))
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
        # First establish how the actual problem code
        # should be delivered to whatever will render it
        if origin == "webwork2":
            server_params_source = {"sourceFilePath":path}
        else:
            server_params_source = {"rawProblemSource":pgdense}

        server_params = {
            "showSolutions": "1",
            "showHints": "1",
            "displayMode": "PTX",
            "courseID": courseID,
            "user": user,
            "passwd": passwd,
            "outputformat": "ptx",
            "disableCookies": '1',
            "problemSeed": seed,
            "problemUUID": problem,
        }
        server_params.update(server_params_source)

        msg = "sending {} to server to save in {}: origin is '{}'"
        log.info(msg.format(problem, ww_reps_dir, origin))
        if origin == "webwork2":
            log.debug(
                "server-to-ptx: {}\n{}\n{}\n{}".format(
                    problem, webwork2_render_rpc, path, ww_reps_dir
                )
            )
        elif origin == "generated":
            log.debug(
                "server-to-ptx: {}\n{}\n{}\n{}".format(
                    problem, webwork2_render_rpc, pgdense, ww_reps_dir
                )
            )

        # Ready, go out on the wire
        try:
            response = webwork2_session.post(webwork2_render_rpc, data=server_params)
            log.debug("Getting problem response from: " + response.url)

        except requests.exceptions.RequestException as e:
            root_cause = str(e)
            msg = "PTX:ERROR: there was a problem collecting a problem,\n Server: {}\nRequest Parameters: {}\n"
            raise ValueError(msg.format(webwork2_render_rpc, server_params) + root_cause)

        # TODO: Instead of this use a different variable shared by the local script approach.
        response = response.text

    # Check for errors with PG processing
    # Get booleans signaling badness: no_compile, bad_xml, no_statement

    # This will be true if there is an actual syntax issue with compiling the problem, but also
    # if the problem file is simply missing. TODO: We could get more specifics about what went
    # wrong if we repeat the request, but ask for HTML instead of PTX. That will carry details,
    # and would be helpful to report to a PTX author/publisher.
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
    badness = no_compile or bad_xml or no_statement

    # Custom responses for each type of badness
    # message for terminal log
    # tip reminding about -a (abort) option
    # value for @failure attribute in static element
    # base64 for a shell PG problem that simply indicates there was an issue and says what the issue was
    badness_msg = ""
    badness_tip = ""
    badness_type = ""
    badness_base64 = ""
    if no_compile:
        badness_msg = (
            "PTX:ERROR: WeBWorK problem {} with seed {} is either empty or failed to compile  \n{}\n"
        )
        badness_tip = (
            "  Use -a to halt with full PG and returned content"
            if (origin == "generated")
            else "  Use -a to halt with returned content"
        )
        badness_type = "compile"
        badness_base64 = "RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygnUEdzdGFuZGFyZC5wbCcpOwpURVhUKCdXZUJXb3JLIFByb2JsZW0gRG9lcyBOb3QgRXhpc3QgT3IgRGlkIE5vdCBDb21waWxlJyk7CkVORERPQ1VNRU5UKCk7"
    elif bad_xml:
        badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} does not return valid XML  \n  It may not be PTX compatible  \n{}\n"
        badness_tip = "  Use -a to halt with returned content"
        badness_type = "xml"
        badness_base64 = "RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygnUEdzdGFuZGFyZC5wbCcpOwpURVhUKCdXZUJXb3JLIFByb2JsZW0gRGlkIE5vdCBHZW5lcmF0ZSBWYWxpZCBYTUwnKTsKRU5ERE9DVU1FTlQoKTs="
    elif no_statement:
        badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} does not have a statement tag \n  Maybe it uses something other than BEGIN_TEXT or BEGIN_PGML to print the statement in its PG code \n{}\n"
        badness_tip = "  Use -a to halt with returned content"
        badness_type = "statement"
        badness_base64 = "RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygnUEdzdGFuZGFyZC5wbCcpOwpURVhUKCdXZUJXb3JLIFByb2JsZW0gRGlkIE5vdCBIYXZlIGEgInN0YXRlbWVudCIgVGFnJyk7CkVORERPQ1VNRU5UKCk7"

    # If we are aborting upon recoverable errors...
    if abort_early:
        if badness:
            debugging_help = response
            if origin == "generated" and no_compile:
                debugging_help += "\n" + pghuman
            raise ValueError(
                badness_msg.format(
                    path, seed, debugging_help
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
                    msg = "PTX:ERROR: could not find a delimiter for a verbatim expression in WeBWorK problem {}"
                    raise ValueError(msg.format(problem))
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
        if static_processing == 'local' and origin != 'webwork2':
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
        # rename the image file to, e.g., webworkParentExerciseLabel-image-3.png
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
            # slashes are in play, not backward slashes. So we intentionally do not use
            # os.path.join(). Perhaps in the future we decide to use a posix path constructor.
            response_text = response_text.replace(
                ww_image_full_path, "webwork/images/" + ptx_image
            )
        else:
            # see note above about posix path construction
            response_text = response_text.replace(
                ww_image_full_path, "images/" + ptx_image
            )
        if static_processing == 'local' and origin != 'webwork2':
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
            # attempt to recover four file formats, with warnings
            for ext in ["tex", "pdf", "svg", "png"]:
                unpacked_image_file = os.path.join(ww_images_dir, ptx_image_name + ".{}".format(ext))
                try:
                    os.replace(
                        os.path.join(ww_images_dir, "image.{}".format(ext)),
                        unpacked_image_file,
                    )
                    written_files.append(unpacked_image_file)
                except:
                    msg = "{} did not contain a .{} file"
                    log.warning(msg.format(destination_image_file, ext))
            os.remove(os.path.join(ww_images_dir, ptx_image_filename))
        else:
            written_files.append(destination_image_file)

    # Use "webwork-reps" as the root tag for this problem's representation file
    NSMAP = {"xml": "http://www.w3.org/XML/1998/namespace"}
    XML = "http://www.w3.org/XML/1998/namespace"
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
    static.set("seed", seed)
    if origin == "webwork2":
        static.set("source", path)

    # If there is "badness"...
    # Build 'shell' problems to indicate failures.  Fall through (no
    # early return) so that rendering-data, pg, and the per-exercise file
    # write below all execute — those sections have explicit "if badness"
    # branches that produce a minimal faux problem, and assembly relies
    # on the file existing for every WeBWorK exercise.
    if badness:
        log.error(badness_msg.format(path, seed, badness_tip))
        static.set("failure", badness_type)
        statement = ET.SubElement(static, "statement")
        p = ET.SubElement(statement, "p")
        p.text = badness_msg.format(path, seed, badness_tip)
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
    if (badness or origin == "generated"):
        source_key = "problemSource"
    else:
        source_key = "sourceFilePath"

    if badness:
        source_value = badness_base64
    else:
        if origin == "webwork2":
            source_value = path
        else:
            # a copy is rendered live from the original's file
            if copied_from is not None:
                source_value = copied_from_path
            else:
                source_value = path

    rendering_data = ET.SubElement(webwork_reps, "rendering-data")
    rendering_data.set(source_key, source_value)
    rendering_data.set("origin", origin)
    rendering_data.set("domain", webwork2_domain)
    rendering_data.set("course-id", courseID)
    rendering_data.set("user-id", user)
    rendering_data.set("passwd", passwd)
    rendering_data.set("language", localization)

    # Add PG for PTX-authored problems
    # Empty tag with @source for server problems
    pg = ET.SubElement(webwork_reps, "pg")
    if copied_from is not None:
        pg.set("copied-from", copied_from)

    if origin == "generated":
        if badness:
            pg_shell = "DOCUMENT();\nloadMacros('PGstandard.pl','PGML.pl','PGcourse.pl');\nBEGIN_PGML\n{}END_PGML\nENDDOCUMENT();"
            formatted_pg = pg_shell.format(
                badness_msg.format(path, seed, badness_tip)
            )
        else:
            formatted_pg = pghuman
        pg.text = ET.CDATA("\n" + formatted_pg)
    elif origin == "webwork2":
        pg.set("source", path)

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

    return [include_file_name] + written_files


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
    # But it is the only thing in the tmp_dir.  A document with no WeBWorK
    # problems produces no folder, so there are no sets to collect.
    set_folders = os.listdir(tmp_dir)
    if not set_folders:
        log.info("no WeBWorK problem sets to construct")
        return
    folder_name = set_folders[0]
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
