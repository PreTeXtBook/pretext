# ********************************************************************
# Copyright 2010-2020 Robert A. Beezer
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

# 2020-05-20: this module expects Python 3.4 or newer

#############################
#
#  Math as LaTeX on web pages
#
#############################

def mathjax_latex(xml_source, result, math_format):
    """Convert PreTeXt source to a structured file of representations of mathematics"""
    # formats:  'svg', 'mml', 'nemeth', 'speech'
    import os.path, subprocess
    import re, os, fileinput # for &nbsp; fix

    _verbose('converting LaTeX from {} into {} format'.format(xml_source, math_format))
    _debug('converting LaTeX from {} into {} format placed into {}'.format(xml_source, math_format, result))

    # construct filenames for pre- and post- XSL stylesheets in xsl/support
    extraction_xslt = os.path.join(get_ptx_xsl_path(), 'support/extract-math.xsl')
    cleaner_xslt    = os.path.join(get_ptx_xsl_path(), 'support/package-math.xsl')

    # Extraction stylesheet makes a simple, mock web page for MathJax
    # And MathJax executables preserve the page while changing the math
    tmp_dir = get_temporary_directory()
    mjinput  = os.path.join(tmp_dir, 'mj-input-latex.html')
    mjintermediate = os.path.join(tmp_dir, 'mj-intermediate.html')
    mjoutput = os.path.join(tmp_dir, 'mj-output-{}.html'.format(math_format))

    _debug('temporary directory for MathJax work: {}'.format(tmp_dir))
    _debug('extracting LaTeX from {} and collected in {}'.format(xml_source, mjinput))

    # SVG, MathML, and PNG are visual and we help authors move punctuation into
    # displays, but not into inline versions.  Nemeth braille and speech are not,
    # so we leave punctuation outside.
    if math_format in ['svg', 'mml']:
        punctuation = 'display'
    elif math_format in ['nemeth', 'speech']:
        punctuation = 'none'
    params = {}
    params['math.punctuation'] = punctuation
    xsltproc(extraction_xslt, xml_source, mjinput, None, params)

    # shell out to process with MathJax
    # mjpage can return "innerHTML" w/ --fragment, which we
    # could wrap into our own particular version of mjoutput
    _debug('calling MathJax to convert LaTeX from {} into raw representations in {}'.format(mjinput, mjoutput))

    # process with  mjpage  executable from  mathjax-node-page  package
    mjpage_exec = get_executable('mjpage')
    if math_format == 'svg':
        # kill caching to keep glyphs within SVG
        # versus having a font cache at the end
        mjpage_cmd = [mjpage_exec, '--output', 'SVG', '--noGlobalSVG', 'true']
    elif math_format == 'mml':
        mjpage_cmd = [mjpage_exec, '--output', 'MML']
    elif math_format in ['nemeth', 'speech']:
        # MathML is precursor for SRE outputs
        mjpage_cmd = [mjpage_exec, '--output', 'MML']
    else:
        raise ValueError('PTX:ERROR: incorrect format ("{}") for MathJax conversion'.format(math_format))

    infile = open(mjinput)
    if math_format in ['nemeth', 'speech']:
        # braille is a two-pass pipeline
        outfile = open(mjintermediate, 'w')
    else:
        outfile = open(mjoutput, 'w')
    subprocess.run(mjpage_cmd, stdin=infile, stdout=outfile)

    # the 'mjpage' executable converts spaces inside of a LaTeX
    # \text{} into &nbsp; entities, which is a good idea, and
    # fine for HTML, but subsequent conversions expecting XHTML
    # do not like &nbsp; nor &#xa0.  Be careful just below, as
    # repl contains a *non-breaking space* not a generic space.
    orig = '&nbsp;'
    repl = ' '
    xhtml_elt = re.compile(orig)
    # the inplace facility of the fileinput module gets
    # confused about temporary backup files if the working
    # directory is not where the file lives
    # Also, print() here actual writes on the file, as
    # another facility of the fileinput module, but we need
    # to kill the "extra" newline that print() creates
    owd = os.getcwd()
    os.chdir(tmp_dir)
    if  math_format in ['nemeth', 'speech']:
        html_file = mjintermediate
    else:
        html_file = mjoutput
    for line in fileinput.input(html_file, inplace=1):
        print(xhtml_elt.sub(repl, line), end='')
    os.chdir(owd)

    if math_format in ['nemeth', 'speech']:
        mjsre_exec = os.path.join(get_ptx_path(), 'script', 'braille', 'mjpage-sre.js')
        mjsre_cmd=[mjsre_exec, math_format, mjintermediate, mjoutput]
        subprocess.run(mjsre_cmd)

    # clean up and package MJ representations, font data, etc
    _debug('packaging math as {} from {} into XML file {}'.format(math_format, mjoutput, result))
    xsltproc(cleaner_xslt, mjoutput, result)


##############################################
#
#  Graphics Language Extraction and Processing
#
##############################################

def asymptote_conversion(xml_source, stringparams, xmlid_root, dest_dir, outformat):
    """Extract asymptote code for diagrams and convert to graphics formats"""
    # stringparams is a dictionary, best for lxml parsing
    import os.path # join()
    import os, subprocess, shutil, glob

    _verbose('converting Asymptote diagrams from {} to {} graphics for placement in {}'.format(xml_source, outformat.upper(), dest_dir))
    tmp_dir = get_temporary_directory()
    _debug("temporary directory: {}".format(tmp_dir))
    asy_executable = get_executable('asy')
    _debug("asy executable: {}".format(asy_executable))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-asymptote.xsl')
    # support subtree argument
    if xmlid_root:
        stringparams['subtree'] = xmlid_root
    # no output (argument 3), stylesheet writes out per-image file
    # outputs a list of ids, but we just loop over created files
    _verbose("extracting Asymptote diagrams from {}".format(xml_source))
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    # Resulting *.asy files are in tmp_dir, switch there to work
    os.chdir(tmp_dir)
    devnull = open(os.devnull, 'w')
    # perhaps replace following stock advisory with a real version
    # check using the (undocumented) distutils.version module, see:
    # https://stackoverflow.com/questions/11887762/how-do-i-compare-version-numbers-in-python
    if outformat == 'html':
        # https://stackoverflow.com/questions/4514751/pipe-subprocess-standard-output-to-a-variable
        proc = subprocess.Popen([asy_executable, '--version'], stderr=subprocess.PIPE)
        asyversion = proc.stderr.read()
        _verbose("#####################################################")
        _verbose("Asymptote 3D HTML output is experimental (2020-05-18)")
        _verbose("it is only supported by Asymptote 2.62 and newer,")
        _verbose("and will produce best results with Asymptote 2.66 and")
        _verbose("newer.  Your Asymptote executable in use reports:")
        _verbose(asyversion)
        _verbose("#####################################################")
    for asydiagram in os.listdir(tmp_dir):
        if outformat == 'source':
            shutil.copy2(asydiagram, dest_dir)
        elif outformat == 'html':
            filebase, _ = os.path.splitext(asydiagram)
            asyout = "{}.{}".format(filebase, outformat)
            asysvg = "{}.svg".format(filebase)
            asypng = "{}_*.png".format(filebase)
            asy_cmd = [asy_executable,
                       '-f', 'html',
                       asydiagram
                       ]
            _verbose("converting {} to {}".format(asydiagram, asyout))
            _debug("asymptote conversion {}".format(asy_cmd))
            subprocess.call(asy_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            if os.path.exists(asyout) == True:
                shutil.copy2(asyout, dest_dir)
            else:
                shutil.copy2(asysvg, dest_dir)
                # Sometimes Asymptotes SVGs include multiple PNGs for colored regions
                for f in glob.glob(asypng):
                    shutil.copy2(f, dest_dir)
        elif outformat == 'svg':
            filebase, _ = os.path.splitext(asydiagram)
            asyout = "{}.{}".format(filebase, outformat)
            # asysvg = "{}.svg".format(filebase)
            asypng = "{}_*.png".format(filebase)
            asy_cmd = [asy_executable,
                       '-f', 'svg',
                       '-render=4', '-iconify',
                       asydiagram
                       ]
            _verbose("converting {} to {}".format(asydiagram, asyout))
            _debug("asymptote conversion {}".format(asy_cmd))
            subprocess.call(asy_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            shutil.copy2(asyout, dest_dir)
            # Sometimes Asymptotes SVGs include multiple PNGs for colored regions
            for f in glob.glob(asypng):
                shutil.copy2(f, dest_dir)
        # 2020-05-18, EPS, PDF not really examined
        else:
            filebase, _ = os.path.splitext(asydiagram)
            asyout = "{}.{}".format(filebase, outformat)
            asypng = "{}_*.png".format(filebase)
            asy_cmd = [asy_executable, '-noprc', '-iconify', '-batchMask', '-f', outformat, asydiagram]
            _verbose("converting {} to {}".format(asydiagram, asyout))
            _debug("asymptote conversion {}".format(asy_cmd))
            subprocess.call(asy_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            shutil.copy2(asyout, dest_dir)
            # Sometimes Asymptotes SVGs include multiple PNGs for colored regions
            for f in glob.glob(asypng):
                shutil.copy2(f, dest_dir)


def sage_conversion(xml_source, xmlid_root, dest_dir, outformat):
    import tempfile, os, os.path, subprocess, shutil, glob
    _verbose('converting Sage diagrams from {} to {} graphics for placement in {}'.format(xml_source, outformat.upper(), dest_dir))
    tmp_dir = get_temporary_directory()
    _debug("temporary directory: {}".format(tmp_dir))
    xslt_executable = get_executable('xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    sage_executable = get_executable('sage')
    _debug("sage executable: {}".format(sage_executable))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-sageplot.xsl')
    extract_cmd = [xslt_executable,
        '--stringparam', 'subtree', xmlid_root,
        '--xinclude',
        extraction_xslt,
        xml_source
        ]
    _verbose("extracting Sage diagrams from {}".format(xml_source))
    # Run conversion with temporary directory as current working directory
    # do not pass (cross-platform, Windows) pathnames into stylesheets
    # Be certain pathnames are not relative to original (user) working directory
    os.chdir(tmp_dir)
    subprocess.call(extract_cmd)
    devnull = open(os.devnull, 'w')
    for sageplot in os.listdir(tmp_dir):
        if outformat == 'source':
            shutil.copy2(sageplot, dest_dir)
        else:
            filebase, _ = os.path.splitext(sageplot)
            sageout = "{0}.{1}".format(filebase, outformat)
            sagepng = "{0}.png".format(filebase, outformat)
            sage_cmd = [sage_executable,  sageplot, outformat]
            _verbose("converting {} to {} (or {} for 3D)".format(sageplot, sageout, sagepng))
            _debug("sage conversion {}".format(sage_cmd))
            subprocess.call(sage_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            # Sage makes PNGs for 3D
            for f in glob.glob(sageout):
                shutil.copy2(f, dest_dir)
            for f in glob.glob(sagepng):
                shutil.copy2(f, dest_dir)

def latex_image_conversion(xml_source, stringparams, xmlid_root, data_dir, dest_dir, outformat):
    # stringparams is a dictionary, best for lxml parsing
    import platform # system, machine()
    import os.path # join()
    import subprocess # call() is Python 3.5
    import os, shutil

    _verbose('converting latex-image pictures from {} to {} graphics for placement in {}'.format(xml_source, outformat, dest_dir))
    _verbose('string parameters passed to extraction stylesheet: {}'.format(stringparams))
    # for killing output
    devnull = open(os.devnull, 'w')
    tmp_dir = get_temporary_directory()
    _debug("temporary directory for latex-image conversion: {}".format(tmp_dir))
    # NB: next command uses relative paths, so no chdir(), etc beforehand
    if data_dir:
        copy_data_directory(xml_source, data_dir, tmp_dir)
    ptx_xsl_dir = get_ptx_xsl_path()
    _verbose("extracting latex-image pictures from {}".format(xml_source))
    # support subtree argument
    if xmlid_root:
        stringparams['subtree'] = xmlid_root
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-latex-image.xsl')
    # no output (argument 3), stylesheet writes out per-image file
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    # now work in temporary directory
    os.chdir(tmp_dir)
    # files *only*, from top-level
    files = list(filter(os.path.isfile, os.listdir(tmp_dir)))
    for latex_image in files:
        if outformat == 'source':
            shutil.copy2(latex_image, dest_dir)
            _verbose("copying {} to {}".format(latex_image, dest_dir))
        else:
            filebase, _ = os.path.splitext(latex_image)
            latex_image_pdf = "{}.pdf".format(filebase)
            latex_image_svg = "{}.svg".format(filebase)
            latex_image_png = "{}.png".format(filebase)
            latex_image_eps = "{}.eps".format(filebase)
            tex_executable = get_executable('tex')
            _debug("tex executable: {}".format(tex_executable))
            latex_cmd = [tex_executable, "-interaction=batchmode", latex_image]
            _verbose("converting {} to {}".format(latex_image, latex_image_pdf))
            subprocess.call(latex_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            pdfcrop_executable = get_executable('pdfcrop')
            _debug("pdfcrop executable: {}".format(pdfcrop_executable))
            if platform.system() == "Windows":
                _debug("using pdfcrop is not reliable on Windows unless you are using a linux-like shell, e.g. Git Bash or SageMathCloud terminal")
                # Test for 32-bit v. 64-bit OS
                # http://stackoverflow.com/questions/2208828/
                # detect-64-bit-os-windows-in-python
                if platform.machine().endswith('64'):
                    pdfcrop_cmd = [pdfcrop_executable, "--gscmd", "gswin64c.exe", latex_image_pdf, latex_image_pdf]
                else:
                    pdfcrop_cmd = [pdfcrop_executable, "--gscmd", "gswin32c.exe", latex_image_pdf, latex_image_pdf]
            else:
                pdfcrop_cmd = [pdfcrop_executable, latex_image_pdf, latex_image_pdf]
            _verbose("cropping {} to {}".format(latex_image_pdf, latex_image_pdf))
            subprocess.call(pdfcrop_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            if outformat == 'all':
                shutil.copy2(latex_image, dest_dir)
            if (outformat == 'pdf' or outformat == 'all'):
                shutil.copy2(latex_image_pdf, dest_dir)
            if (outformat == 'svg' or outformat == 'all'):
                pdfsvg_executable = get_executable('pdfsvg')
                _debug("pdfsvg executable: {}".format(pdfsvg_executable))
                svg_cmd = [pdfsvg_executable, latex_image_pdf, latex_image_svg]
                _verbose("converting {} to {}".format(latex_image_pdf, latex_image_svg))
                subprocess.call(svg_cmd)
                shutil.copy2(latex_image_svg, dest_dir)
            if (outformat == 'png' or outformat == 'all'):
                # create high-quality png, presumes "convert" executable
                pdfpng_executable = get_executable('pdfpng')
                _debug("pdfpng executable: {}".format(pdfpng_executable))
                png_cmd = [pdfpng_executable, "-density", "300",  latex_image_pdf, "-quality", "100", latex_image_png]
                _verbose("converting {} to {}".format(latex_image_pdf, latex_image_png))
                subprocess.call(png_cmd)
                shutil.copy2(latex_image_png, dest_dir)
            if (outformat == 'eps' or outformat == 'all'):
                pdfeps_executable = get_executable('pdfeps')
                _debug("pdfeps executable: {}".format(pdfeps_executable))
                eps_cmd = [pdfeps_executable, '-eps', latex_image_pdf, latex_image_eps]
                _verbose("converting {} to {}".format(latex_image_pdf, latex_image_eps))
                subprocess.call(eps_cmd)
                shutil.copy2(latex_image_eps, dest_dir)

################################
#
#  WeBWorK Extraction Processing
#
################################

def webwork_to_xml(xml_source, abort_early, server_params, dest_dir):
    import subprocess, os.path, xml.dom.minidom
    import sys # version_info
    import urllib.parse # urlparse()
    import re     # regular expressions for parsing
    import base64  # b64encode()
    # at least on Mac installations, requests module is not standard
    try:
        import requests
    except ImportError:
        msg = 'PTX:ERROR: failed to import requests module, is it installed?'
        raise ValueError(msg)

    # execute XSL extraction to get back four dictionaries
    # where the keys are the internal-ids for the problems
    # origin, seed, source, pg
    xslt_executable = get_executable('xslt')
    _debug("xslt executable command: {}".format(xslt_executable))
    ptx_xsl_dir = get_ptx_xsl_path()
    xsl_transform = 'extract-pg.xsl'
    extraction_xslt = os.path.join(ptx_xsl_dir, xsl_transform)
    cmd = [xslt_executable, '--xinclude', extraction_xslt, xml_source]
    try:
        problem_dictionaries = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)

    # execute XSL extraction to get back the dictionary
    # where the keys are the internal-ids for the problems
    # pgptx
    xsl_transform_pgptx = 'extract-pg-ptx.xsl'
    extraction_xslt_pgptx = os.path.join(ptx_xsl_dir, xsl_transform_pgptx)
    cmd = [xslt_executable, '--xinclude', extraction_xslt_pgptx, xml_source]
    try:
        problem_dictionary_pgptx = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)

    # "run" the dictionaries
    # protect backslashes in LaTeX code
    # globals() necessary for success in both Python 2 and 3
    exec(problem_dictionaries.decode('utf-8').replace('\\','\\\\'), globals())
    exec(problem_dictionary_pgptx.decode('utf-8').replace('\\','\\\\'), globals())

    # initialize more dictionaries
    pgbase64 = {}
    pgbase64['hint_yes_solution_yes'] = {}
    pgbase64['hint_yes_solution_no'] = {}
    pgbase64['hint_no_solution_yes'] = {}
    pgbase64['hint_no_solution_no'] = {}
    static = {}

    # verify, construct problem format requestor
    # remove any surrounding white space
    server_params = server_params.strip()
    if (server_params.startswith("(") and server_params.endswith(")")):
        server_params=server_params.strip('()')
        split_server_params = server_params.split(',')
        server_url = sanitize_url(split_server_params[0])
        courseID = sanitize_alpha_num_underscore(split_server_params[1])
        userID = sanitize_alpha_num_underscore(split_server_params[2])
        password = sanitize_alpha_num_underscore(split_server_params[3])
        course_password = sanitize_alpha_num_underscore(split_server_params[4])
    else:
        server_url = sanitize_url(server_params)
        courseID = 'anonymous'
        userID = 'anonymous'
        password = 'anonymous'
        course_password = 'anonymous'

    wwurl = server_url + "webwork2/html2xml"

    # Begin preparation for getting static versions

    # using a "Session()" will pool connection information
    # since we always hit the same server, this should increase performance
    session = requests.Session()

    # XML content comes back
    # these delimit what we want
    start_marker = re.compile('<!--BEGIN PROBLEM-->')
    end_marker = re.compile('<!--END PROBLEM-->')

    # End preparation for getting static versions

    # begin writing single .xml file with all webwork representations
    include_file_name = os.path.join(dest_dir, "webwork-extraction.xml")
    try:
         with open(include_file_name, 'w') as include_file:
            include_file.write('<?xml version="1.0" encoding="UTF-8" ?>\n<webwork-extraction>\n')
    except Exception as e:
        root_cause = str(e)
        msg = "PTX:ERROR: there was a problem writing a problem to the file: {}\n"
        raise ValueError(msg.format(include_file_name) + root_cause)

    # Choose one of the dictionaries to take its keys as what to loop through
    for problem in sorted(origin):

        # It is more convenient to identify server problems by file path,
        # and PTX problems by internal ID
        problem_identifier = problem if (origin[problem] == 'ptx') else source[problem]

        #remove outer webwork tag (and attributes) from authored source
        if origin[problem] == 'ptx':
            source[problem] = re.sub(r"<webwork.*?>",'',source[problem]).replace('</webwork>','')

        #use "webwork-reps" as parent tag for the various representations of a problem
        try:
            with open(include_file_name, 'a') as include_file:
                webwork_reps = '  <webwork-reps xml:id="extracted-{}" ww-id="{}">\n'
                include_file.write(webwork_reps.format(problem,problem))
        except Exception as e:
            root_cause = str(e)
            msg = "PTX:ERROR: there was a problem writing a problem to the file: {}\n"
            raise ValueError(msg.format(include_file_name) + root_cause)

        if origin[problem] == 'server':
            msg = 'writing representations of server-based WeBWorK problem'
        elif origin[problem] == 'ptx':
            msg = 'writing representations of PTX-authored WeBWorK problem'
        else:
            raise ValueError("PTX:ERROR: problem origin should be 'server' or 'ptx', not '{}'".format(origin[problem]))
        _verbose(msg)

        # make base64 for PTX problems
        if origin[problem] == 'ptx':
            for hint_sol in ['hint_yes_solution_yes','hint_yes_solution_no','hint_no_solution_yes','hint_no_solution_no']:
                pgbase64[hint_sol][problem] = base64.b64encode(bytes(pgptx[hint_sol][problem], 'utf-8'))

        # First write authored
        if origin[problem] == 'ptx':
            try:
                with open(include_file_name, 'a') as include_file:
                    authored_tag = '    <authored>\n{}\n    </authored>\n\n'
                    include_file.write(authored_tag.format(re.sub(re.compile('^(?=.)', re.MULTILINE),'      ',source[problem])))
            except Exception as e:
                root_cause = str(e)
                msg = "PTX:ERROR: there was a problem writing the authored source of {} to the file: {}\n"
                raise ValueError(msg.format(problem_identifier, include_file_name) + root_cause)

        # Now begin getting static version from server

        # WW server can react to a
        #   URL of a problem stored there already
        #   or a base64 encoding of a problem
        # server_params is tuple rather than dictionary to enforce consistent order in url parameters
        server_params = (('answersSubmitted','0'),
                         ('displayMode','PTX'),
                         ('courseID',courseID),
                         ('userID',userID),
                         ('password',password),
                         ('course_password',course_password),
                         ('outputformat','ptx'),
                         ('sourceFilePath',source[problem]) if origin[problem] == 'server' else ('problemSource',pgbase64['hint_yes_solution_yes'][problem]),
                         ('problemSeed',seed[problem]))

        msg = "sending {} to server to save in {}: origin is '{}'"
        _verbose(msg.format(problem, dest_dir, origin[problem]))
        if origin[problem] == 'server':
            _debug('server-to-ptx: {} {} {} {}'.format(source[problem], wwurl, dest_dir, problem))
        elif origin[problem] == 'ptx':
            _debug('server-to-ptx: {} {} {} {}'.format(pgptx['hint_yes_solution_yes'][problem], wwurl, dest_dir, problem))

        # Ready, go out on the wire
        try:
            response = session.get(wwurl, params=server_params)
        except requests.exceptions.RequestException as e:
            root_cause = str(e)
            msg = "PTX:ERROR: there was a problem collecting a problem,\n Server: {}\nRequest Parameters: {}\n"
            raise ValueError(msg.format(wwurl, server_params) + root_cause)

        # When a PG Math Object is a text string that has to be rendered in a math environment,
        # depending on the string's content and the version of WeBworK, it can come back as:

        # \text{string}            only when the string is built solely from -A-Za-z0-9 ,.;:+=?()[]
        # \verb\x85string\x85      version 2.14 and earlier
        # \verb\x1Fstring\x1F      certain develop branches between 2.14 and 2.15, and WW HTML output for 2.15+
        # {\verb\rstring\r}        WW PTX (and TeX) output starting with 2.15, hopefully stable

        # We would like to replace all instances with \text{string},
        # but in addition to character escaping issues, \text does not behave equally in TeX and MathJax.
        # Certain characters _need_ to be escaped in TeX, but must _not_ be escaped in MathJax.
        # So we make the change after checking that none of the dangerous characters are present,
        # and otherwise leave \verb in place. But we replace the delimiter with the first available
        # "normal" character.
        # \r would be valid XML, but too unpredictable in translations
        # something like \x85 would be vald XML, but may not be OK in some translations

        verbatim_split = re.split(r'(\\verb\x85.*?\x85|\\verb\x1F.*?\x1F|\\verb\r.*?\r)', response.text)
        response_text = ''
        for item in verbatim_split:
            if re.match(r'^\\verb(\x85|\x1F|\r).*?\1$', item):
                (original_delimiter, verbatim_content) = re.search(r'\\verb(\x85|\x1F|\r)(.*?)\1', item).group(1,2)
                if set(['#', '%', '&', '<', '>', '\\', '^', '_', '`', '|', '~']).intersection(set(list(verbatim_content))):
                    index = 33
                    while index < 127:
                        if index in [42, 34, 38, 39, 59, 60, 62] or chr(index) in verbatim_content:
                            # the one character you cannot use with \verb as a delimiter is chr(42), *
                            # the others excluded here are the XML control characters,
                            # and semicolon for good measure (as the closer for escaped characters)
                            index += 1
                        else:
                            break
                    if index == 127:
                        print('PTX:WARNING: Could not find delimiter for verbatim expression')
                        return '!Could not find delimiter for verbatim expression.!'
                    else:
                        response_text += item.replace(original_delimiter, chr(index))
                else:
                    # These three characters are escaped in both TeX and MathJax
                    text_content = verbatim_content.replace('$', '\\$')
                    text_content = text_content.replace('{', '\\{')
                    text_content = text_content.replace('}', '\\}')
                    response_text += '\\text{' + text_content + '}'
            else:
                response_text += item

        # Check for errors with PG processing
        # Get booleans signaling badness: file_empty, no_compile, bad_xml, no_statement
        file_empty = 'ERROR:  This problem file was empty!' in response_text
        no_compile = 'ERROR caught by Translator while processing problem file:' in response_text
        bad_xml = False
        no_statement = False
        try:
            from xml.etree import ElementTree
        except ImportError:
            msg = 'PTX:ERROR: failed to import ElementTree from xml.etree'
            raise ValueError(msg)
        try:
            problem_root = ElementTree.fromstring(response_text)
        except:
            bad_xml = True
        if not bad_xml:
            if problem_root.find('.//statement') is None:
                no_statement = True
        badness = file_empty or no_compile or bad_xml or no_statement

        # Custom responses for each type of badness
        # message for terminal log
        # tip reminding about -a (abort) option
        # value for @failure attribute in static element
        # base64 for a shell PG problem that simply indicates there was an issue and says what the issue was
        if file_empty:
            badness_msg = "PTX:ERROR: WeBWorK problem {} was empty\n"
            badness_tip = ''
            badness_type = 'empty'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBGaWxlIFdhcyBFbXB0eQoKRU5EX1BHTUwKCkVORERPQ1VNRU5UKCk7'
        elif no_compile:
            badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} did not compile  \n{}\n"
            badness_tip = '  Use -a to halt with full PG and returned content' if (origin[problem] == 'ptx') else '  Use -a to halt with returned content'
            badness_type = 'compile'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IENvbXBpbGUKCkVORF9QR01MCgpFTkRET0NVTUVOVCgpOw%3D%3D'
        elif bad_xml:
            badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} does not return valid XML  \n  It may not be PTX compatible  \n{}\n"
            badness_tip = '  Use -a to halt with returned content'
            badness_type = 'xml'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IEdlbmVyYXRlIFZhbGlkIFhNTAoKRU5EX1BHTUwKCkVORERPQ1VNRU5UKCk7'
        elif no_statement:
            badness_msg = "PTX:ERROR: WeBWorK problem {} with seed {} does not have a statement tag \n  Maybe it uses something other than BEGIN_TEXT or BEGIN_PGML to print the statement in its PG code \n{}\n"
            badness_tip = '  Use -a to halt with returned content'
            badness_type = 'statement'
            badness_base64 = 'RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IEhhdmUgYSBbfHN0YXRlbWVudHxdKiBUYWcKCkVORF9QR01MCgpFTkRET0NVTUVOVCgpOw%3D%3D'

        # If we are aborting upon recoverable errors...
        if abort_early:
            if badness:
                debugging_help = response_text
                if origin[problem] == 'ptx' and no_compile:
                    debugging_help += "\n" + pg[problem]
                raise ValueError(badness_msg.format(problem_identifier, seed[problem], debugging_help))

        # If there is "badness"...
        # Build 'shell' problems to indicate failures
        if badness:
            print(badness_msg.format(problem_identifier, seed[problem], badness_tip))
            static_skeleton = "<static failure='{}'>\n<statement>\n  <p>\n    {}  </p>\n</statement>\n</static>\n"
            static[problem] = static_skeleton.format(badness_type, badness_msg.format(problem_identifier, seed[problem], badness_tip))

        else:
            # add to dictionary
            static[problem] = response_text
            # strip out actual PTX code between markers
            start = start_marker.split(static[problem], maxsplit=1)
            static[problem] = start[1]
            end = end_marker.split(static[problem], maxsplit=1)
            static[problem] = end[0]
            # change element from webwork to static and indent
            static[problem] = static[problem].replace('<webwork>', '<static>')
            static[problem] = static[problem].replace('</webwork>', '</static>')

        # Convert answerhashes XML to a sequence of answer elements
        # This is crude text operation on the XML
        # If correct_ans_latex_string is nonempty, use it, encased in <p><m>
        # Else if correct_ans is nonempty, use it, encased in just <p>
        # Else we have no answer to print out
        answerhashes = re.findall(r'<AnSwEr\d+ (.*?) />', static[problem], re.DOTALL)
        if answerhashes:
            answer = ''
            for answerhash in answerhashes:
                try:
                    correct_ans = re.search('correct_ans="(.*?)"', answerhash, re.DOTALL).group(1)
                except:
                    correct_ans = ''
                try:
                    correct_ans_latex_string = re.search('correct_ans_latex_string="(.*?)"', answerhash, re.DOTALL).group(1)
                except:
                    correct_ans_latex_string = ''

                if correct_ans_latex_string or correct_ans:
                    answer += "<answer>\n  <p>"
                    if not correct_ans_latex_string:
                        answer += correct_ans
                    else:
                        answer += '<m>' + correct_ans_latex_string + '</m>'
                    answer += "</p>\n</answer>\n"

            # Now we need to cut out the answerhashes that came from the server.
            beforehashes = re.compile('<answerhashes>').split(static[problem])[0]
            afterhashes = re.compile('</answerhashes>').split(static[problem])[1]
            static[problem] = beforehashes + afterhashes

            # We don't just replace it with the answer we just built. To be
            # schema-compliant, the answer should come right after the latter of
            # (last closing statement, last closing hint)
            # By reversing the string, we can just target first match
            reverse = static[problem][::-1]
            parts = re.split(r"(\n>tnemetats/<|\n>tnih/<)",reverse, 1)
            static[problem] = parts[2][::-1] + parts[1][::-1] + answer + parts[0][::-1]

        # nice to know what seed was used
        static[problem] = static[problem].replace('<static', '<static seed="' + seed[problem] + '"')

        # nice to know sourceFilePath for server problems
        if origin[problem] == 'server':
            static[problem] = static[problem].replace('<static', '<static source="' + source[problem] + '"')

        # adjust indentation
        static[problem] = re.sub(re.compile('^(?=.)', re.MULTILINE),'      ',static[problem]).replace('  <static','<static').replace('  </static','</static')
        # remove excess blank lines that come at the end from the server
        static[problem] = re.sub(re.compile('\n+( *</static>)', re.MULTILINE),r"\n\1",static[problem])

        # need to loop through content looking for images with pattern:
        #
        #   <image source="relative-path-to-temporary-image-on-server"
        #
        graphics_pattern = re.compile(r'<image.*?source="([^"]*)"')

        # replace filenames, download images with new filenames
        count = 0
        # ww_image_url will be the URL to an image file used by the problem on the ww server
        for match in re.finditer(graphics_pattern, static[problem]):
            ww_image_url = match.group(1)
            # strip away the scheme and location, if present (e.g 'https://webwork-ptx.aimath.org/')
            ww_image_url_parsed = urllib.parse.urlparse(ww_image_url)
            ww_image_scheme = ww_image_url_parsed.scheme
            ww_image_full_path = ww_image_url_parsed.path
            count += 1
            # split the full path into (path, file). path could theoretically be empty.
            ww_image_path, ww_image_filename = os.path.split(ww_image_full_path)
            # split the filename into (name, extension). extension can be empty or like '.png'.
            ww_image_name, image_extension = os.path.splitext(ww_image_filename)
            # rename, eg, webwork-extraction/webwork-5-image-3.png
            ptx_image_name =  problem + '-image-' + str(count)
            ptx_image_filename = ptx_image_name + image_extension
            if ww_image_scheme:
                image_url = ww_image_url
            else:
                image_url = server_url + ww_image_full_path
            # modify PTX problem source to include local versions
            static[problem] = static[problem].replace(ww_image_full_path, 'images/' + ptx_image_filename)
            # download actual image files
            # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests
            try:
                response = session.get(image_url)
            except requests.exceptions.RequestException as e:
                root_cause = str(e)
                msg = "PTX:ERROR: there was a problem downloading an image file,\n URL: {}\n"
                raise ValueError(msg.format(image_url) + root_cause)
            # and save the image itself
            try:
                with open(os.path.join(dest_dir, ptx_image_filename), 'wb') as image_file:
                    image_file.write(response.content)
            except Exception as e:
                root_cause = str(e)
                msg = "PTX:ERROR: there was a problem saving an image file,\n Filename: {}\n"
                raise ValueError(os.path.join(dest_dir, ptx_filename) + root_cause)

        # place static content
        # we open the file in binary mode to preserve the \r characters that may be present
        try:
            with open(include_file_name, 'ab') as include_file:
                include_file.write(bytes(static[problem] + '\n', encoding='utf-8'))
        except Exception as e:
            root_cause = str(e)
            msg = "PTX:ERROR: there was a problem writing a problem to the file: {}\n"
            raise ValueError(msg.format(include_file_name) + root_cause)

        # Write urls for interactive version
        for hint in ['yes','no']:
            for solution in ['yes','no']:
                hintsol = 'hint_' + hint + '_solution_' + solution
                url_tag = '    <server-url hint="{}" solution="{}">{}?courseID={}&amp;userID={}&amp;password={}&amp;course_password={}&amp;answersSubmitted=0&amp;displayMode=MathJax&amp;outputformat=simple&amp;problemSeed={}&amp;{}</server-url>\n\n'
                source_selector = 'problemSource=' if (badness or origin[problem] == 'ptx') else 'sourceFilePath='
                if badness:
                    source_value = badness_base64
                else:
                    if origin[problem] == 'server':
                        source_value = source[problem]
                    else:
                        source_value = urllib.parse.quote_plus(pgbase64[hintsol][problem])
                source_query = source_selector + source_value
                try:
                    with open(include_file_name, 'a') as include_file:
                        include_file.write(url_tag.format(hint,solution,wwurl,courseID,userID,password,course_password,seed[problem],source_query))
                except Exception as e:
                    root_cause = str(e)
                    msg = "PTX:ERROR: there was a problem writing URLs for {} to the file: {}\n"
                    raise ValueError(msg.format(problem_identifier, include_file_name) + root_cause)

        # Write PG. For server problems, just include source as attribute and close pg tag
        if origin[problem] == 'ptx':
            pg_tag = '    <pg>\n{}\n    </pg>\n\n'
            if badness:
                pg_shell = "DOCUMENT();\nloadMacros('PGstandard.pl','PGML.pl','PGcourse.pl');\nTEXT(beginproblem());\nBEGIN_PGML\n{}END_PGML\nENDDOCUMENT();"
                formatted_pg = pg_shell.format(badness_msg.format(problem_identifier, seed[problem], badness_tip))
            else:
                formatted_pg = pg[problem]
            # opportunity to cut out extra blank lines
            formatted_pg = re.sub(re.compile(r"(\n *\n)( *\n)*", re.MULTILINE),r"\n\n",formatted_pg)

            try:
                with open(include_file_name, 'a') as include_file:
                    include_file.write(pg_tag.format(formatted_pg))
            except Exception as e:
                root_cause = str(e)
                msg = "PTX:ERROR: there was a problem writing the PG for {} to the file: {}\n"
                raise ValueError(msg.format(problem_identifier, include_file_name) + root_cause)
        elif origin[problem] == 'server':
            try:
                with open(include_file_name, 'a') as include_file:
                    pg_tag = '    <pg source="{}" />\n\n'
                    include_file.write(pg_tag.format(source[problem]))
            except Exception as e:
                root_cause = str(e)
                msg = "PTX:ERROR: there was a problem writing the PG for {} to the file: {}\n"
                raise ValueError(msg.format(problem_identifier, include_file_name) + root_cause)

        # close webwork-reps tag
        try:
            with open(include_file_name, 'a') as include_file:
                include_file.write('  </webwork-reps>\n\n')
        except Exception as e:
            root_cause = str(e)
            msg = "PTX:ERROR: there was a problem writing a problem to the file: {}\n"
            raise ValueError(msg.format(include_file_name) + root_cause)

    # close webwork-extraction tag and finish
    try:
        with open(include_file_name, 'a') as include_file:
            include_file.write('</webwork-extraction>')
    except Exception as e:
        root_cause = str(e)
        msg = "PTX:ERROR: there was a problem writing a problem to the file: {}\n"
        raise ValueError(msg.format(include_file_name) + root_cause)


##############################
#
#  You Tube thumbnail scraping
#
##############################

def youtube_thumbnail(xml_source, xmlid_root, dest_dir):
    import os.path  # join()
    import subprocess, shutil
    import requests

    _verbose('downloading YouTube thumbnails from {} for placement in {}'.format(xml_source, dest_dir))
    xslt_executable = get_executable('xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-youtube.xsl')
    # No temporary directory involved,
    # results land directly in dest_dir
    cmd = [xslt_executable,
            '--xinclude',
            '--stringparam', 'subtree', xmlid_root,
            extraction_xslt,
            xml_source]
    try:
        thumb_list = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)
    # "run" an assignment for the list of triples of strings
    thumbs = eval(thumb_list.decode('ascii'))

    session = requests.Session()
    for thumb in thumbs:
        url = 'http://i.ytimg.com/vi/{}/default.jpg'.format(thumb[0])
        path = os.path.join(dest_dir, thumb[1] + '.jpg')
        _verbose('downloading {} as {}...'.format(url, path))
        # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests/13137873
        # removed some settings wrapper from around the URL, otherwise verbatim
        r = requests.get(url, stream=True)
        if r.status_code == 200:
            with open(path, 'wb') as f:
                r.raw.decode_content = True
                shutil.copyfileobj(r.raw, f)
        else:
            msg = 'PTX:ERROR: download returned a bad status code ({}), perhaps try {} manually?'
            raise OSError(msg.format(r.status_code, url))
    _verbose('YouTube thumbnail download complete')


#####################################
#
#  Interactive preview screenshotting
#
#####################################

def preview_images(xml_source, xmlid_root, dest_dir):
    import subprocess, shutil
    import os.path # join()

    suffix = 'png'

    _verbose('creating interactive previews from {} for placement in {}'.format(xml_source, dest_dir))

    # see below, pageres-cli writes into current working directory
    needs_moving = not( os.getcwd() == os.path.normpath(dest_dir) )

    xslt_executable = get_executable('xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-interactive.xsl')
    # No temporary directory involved,
    # results land directly in dest_dir
    cmd = [xslt_executable,
            '--xinclude',
            '--stringparam','subtree',xmlid_root,
            extraction_xslt,
            xml_source]
    try:
        interactive_list = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)
    # "run" an assignment for the list of problem numbers
    interactives = eval(interactive_list.decode('ascii'))

    # Cheating a bit, base URL is *always* first item
    # Presumed to not have a trailing slash
    # Once this is a publisher option, then the xsltproc
    # call will need to accept the override as a stringparam
    baseurl = interactives[0]

    pageres_executable = get_executable('pageres')
    _debug("pageres executable: {}".format(pageres_executable))
    _debug("interactives identifiers: {}".format(interactives))

    # Start after the leading base URL sneakiness
    for preview in interactives[1:]:
        input_page = os.path.join(baseurl, preview + '.html')
        selector_option = '--selector=#' + preview
        # file suffix is provided by pageres
        format_option = '--format=' + suffix
        filename_option = '--filename=' + preview + '-preview'
        filename = preview + '-preview.' + suffix

        # pageres invocation
        # Overwriting files prevents numbered versions (with spaces!)
        # 3-second delay allows Javascript, etc to settle down
        # --transparent, --crop do not seem very effective
        cmd = [pageres_executable,
        "-v",
        "--overwrite",
        '-d5',
        '--transparent',
        selector_option,
        filename_option,
        input_page
        ]

        _debug("pageres command: {}".format(cmd))

        subprocess.call(cmd)
        # 2018-04-27  CLI pageres only writes into current directory
        # and it is an error to move a file onto itself, so we are careful
        if needs_moving:
            shutil.move(filename, dest_dir)


#####################################
#
#  MyOpenMath static problem scraping
#
#####################################

def mom_static_problems(xml_source, xmlid_root, dest_dir):
    import os.path # join()
    import subprocess, shutil
    import requests

    _verbose('downloading MyOpenMath static problems from {} for placement in {}'.format(xml_source, dest_dir))
    xslt_executable = get_executable('xslt')
    _debug("xslt executable: {}".format(xslt_executable))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, 'extract-mom.xsl')
    # No temporary directory involved,
    # results land directly in dest_dir
    cmd = [xslt_executable,
            '--xinclude',
            '--stringparam', 'subtree', xmlid_root,
            extraction_xslt,
            xml_source]
    try:
        problem_list = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        root_cause = str(e)
        msg = 'xsltproc command failed, tried: "{}"\n'.format(' '.join(cmd))
        raise ValueError(msg + root_cause)
    # "run" an assignment for the list of problem numbers
    problems = eval(problem_list.decode('ascii'))
    xml_header = '<?xml version="1.0" encoding="UTF-8" ?>\n'
    session = requests.Session()
    for problem in problems:
        url = 'https://www.myopenmath.com/util/mbx.php?id={}'.format(problem)
        path = os.path.join(dest_dir, 'mom-{}.xml'.format(problem))
        _verbose('downloading MOM #{} to {}...'.format(problem, path))
        # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests/13137873
        # removed some settings wrapper from around the URL, otherwise verbatim
        r = requests.get(url, stream=True)
        with open(path, 'wb') as f:
            f.write(xml_header.encode('utf-8'))
            if r.status_code == 200:
                r.raw.decode_content = True
                shutil.copyfileobj(r.raw, f)
            else:
                msg = 'PTX:ERROR: download returned a bad status code ({}), perhaps try {} manually?'
                raise OSError(msg.format(r.status_code, url))
    _verbose('MyOpenMath static problem download complete')

#######################
# Conversion to Braille
#######################

def braille(xml_source, pub_file, dest_dir):
    """Produce a complete document in BRF format ( = Braille ASCII, plus formatting control)"""
    import os.path # join()
    import subprocess # run()

    # general message for this entire procedure
    _verbose('converting {} into BRF in {} combining UEB2 and Nemeth'.format(xml_source, dest_dir))

    # Build into a scratch directory
    tmp_dir = get_temporary_directory()
    _debug('Braille manufacture in temporary directory: {}'.format(tmp_dir))

    # use of  math_format is for consistency
    # with MathJax used to make EPUB
    math_format = 'nemeth'
    math_representations = os.path.join(tmp_dir, 'math-representations-{}.xml'.format(math_format))
    braille_xslt = os.path.join(get_ptx_xsl_path(), 'pretext-braille.xsl')
    #  liblouis-precursor.xml  is hard-coded in  pretext-braille.xsl  stylesheet
    liblouis_xml = os.path.join(tmp_dir, 'liblouis-precursor.xml')

    # ripping out LaTeX as math representations
    msg = 'converting raw LaTeX from {} into clean {} format placed into {}'
    _debug(msg.format(xml_source, math_format, math_representations))
    mathjax_latex(xml_source, math_representations, math_format)

    msg = 'converting source ({}) and clean representations ({}) into liblouis precursor XML file ({})'
    _debug(msg.format(xml_source, math_representations, liblouis_xml))
    params = {}
    params['mathfile'] = math_representations
    if pub_file:
        params['publisher'] = pub_file
    xsltproc(braille_xslt, xml_source, None, tmp_dir, params)

    liblouis_cfg = os.path.join(get_ptx_path(), 'script', 'braille', 'pretext-liblouis.cfg')
    final_brf = os.path.join(dest_dir, 'book.brf')
    liblouis_exec = get_executable('liblouis')
    msg = 'applying liblouis to {} with configuration {}, creating BRF {}'
    _debug(msg.format(liblouis_xml, liblouis_cfg, final_brf))
    liblouis_cmd = [liblouis_exec, '-f', liblouis_cfg, liblouis_xml, final_brf]

    subprocess.run(liblouis_cmd)


####################
# Conversion to EPUB
####################

def epub(xml_source, pub_file, dest_dir, math_format):
    """Produce complete document in an EPUB container"""
    # math_format is a string that parameterizes this process
    #   'svg': mathematics as SVG
    #   'mml': mathematics as MathML
    import os, os.path, subprocess, shutil
    import re, fileinput
    import zipfile as ZIP
    import lxml.etree as ET

    # general message for this entire procedure
    _verbose('converting {} into EPUB in {} with math as {}'.format(xml_source, dest_dir, math_format))

    # Build into a scratch directory
    tmp_dir = get_temporary_directory()
    _debug('EPUB manufacture in temporary directory: {}'.format(tmp_dir))

    # Before making a zip file, the temporary directory should look
    # like the unzipped version of an EPUB file.  For us, that goes:

    # mimetype
    # EPUB
    #   package.opf
    #   css
    #   xhtml
    #     images (customizable)
    # META-INF

    source_dir = get_source_path(xml_source)
    epub_xslt = os.path.join(get_ptx_xsl_path(), 'pretext-epub.xsl')
    math_representations = os.path.join(tmp_dir, 'math-representations-{}.xml'.format(math_format))
    packaging_file = os.path.join(tmp_dir, 'packaging.xml')
    xhtml_dir = os.path.join(tmp_dir, 'EPUB', 'xhtml')

    # ripping out LaTeX as math representations
    msg = 'converting raw LaTeX from {} into clean {} format placed into {}'
    _debug(msg.format(xml_source, math_format, math_representations))
    mathjax_latex(xml_source, math_representations, math_format)

    # Build necessary content and infrastructure EPUB files, 
    # using SVG images of math.  Most output goes into the
    # EPUB/xhtml directory via exsl:document templates in
    # the EPUB XSL conversion.  The stylesheet does record,
    # and produce some information needed for the packaging here.
    _verbose('converting source ({}) and clean representations ({}) into EPUB files'.format(xml_source, math_representations))
    params = {}
    params['mathfile'] = math_representations
    params['math.format'] = math_format
    if pub_file:
        params['publisher'] = pub_file
    xsltproc(epub_xslt, xml_source, packaging_file, tmp_dir, params)

    # XHTML files lack an overall namespace,
    # while EPUB validation expects it
    # regex inplace to end up with:
    # <html xmlns="http://www.w3.org/1999/xhtml">
    orig = '<html'
    repl = '<html xmlns="http://www.w3.org/1999/xhtml"'
    # the inoplace facility of the fileinput module gets
    # confused about temporary backup files if the working
    # directory is not where the file lives
    # Also, print() here actual writes on the file, as
    # another facility of the fileinput module, but we need
    # to kill the "extra" newline that print() creates
    owd = os.getcwd()
    os.chdir(xhtml_dir)
    html_elt = re.compile(orig)
    for root, dirs, files in os.walk(xhtml_dir):
        for fn in files:
            for line in fileinput.input(fn, inplace=1):
                print(html_elt.sub(repl, line), end='')
    os.chdir(owd)

    # EPUB stylesheet writes an XHTML file with
    # bits of info necessary for packaging
    packaging_tree = ET.parse(packaging_file)

    # Stage CSS files in EPUB/css, coordinate 
    # with names in manifest and *.xhtml via XSL.
    # CSS files live in distribution in "css" directory, 
    # which is a peer of the "xsl" directory
    # EPUB exists from above xsltproc call
    css_dir = os.path.join(tmp_dir, 'EPUB', 'css')
    os.mkdir(css_dir)
    stylefile = packaging_tree.xpath('/packaging/css/@stylefile')[0]
    colorfile = packaging_tree.xpath('/packaging/css/@colorfile')[0]
    for cssfilename in [str(stylefile), str(colorfile), 'pretext_add_on.css', 'setcolors.css']:
        css = os.path.join(get_ptx_xsl_path(), '..', 'css', cssfilename)
        shutil.copy2(css, css_dir)

    # directory of images, relative to master source file, given by publisher
    # build the same directory relative to the XHTML files
    #imdir = packaging_tree.xpath('/packaging/images/@image-directory')[0]
    #source_image_dir = os.path.join(source_dir, str(imdir))
    #os.mkdir(os.path.join(tmp_dir, 'EPUB', 'xhtml', str(imdir)))
    source_image_dir = os.path.join(source_dir, 'images')
    os.mkdir(os.path.join(tmp_dir, 'EPUB', 'xhtml', 'images'))
    # position cover file
    cov = packaging_tree.xpath('/packaging/cover/@filename')[0]
    cover_source = os.path.join(source_dir, str(cov))
    cover_dest = os.path.join(tmp_dir, 'EPUB', 'xhtml', str(cov))
    shutil.copy2(cover_source, cover_dest)
    # position image files
    images = packaging_tree.xpath('/packaging/images/image/@filename')
    for im in images:
        source = os.path.join(source_dir, str(im))
        dest = os.path.join(tmp_dir, 'EPUB', 'xhtml', str(im))
        shutil.copy2(source, dest)

    # clean-up the trash
    # TODO: squelch knowls or find alternative
    # shutil.rmtree(os.path.join(tmp_dir, 'knowl'))
    # os.remove(packaging_file)
    # os.remove(math_representations)


    # mimetype parameters: -0Xq
    # -0 no compression
    # -X no extra fields, eg uid/gid on Unix
    # -q quiet (not relevant)

    # remainder parameters: -Xr9Dq
    # -X no extra fields, eg uid/gid on Unix
    # -r recursive travel
    # -9 maximum compression
    # -D no directory entries
    # -q quiet (not relevant)

    # https://www.w3.org/publishing/epub3/epub-ocf.html#sec-container-zip
    # Spec says only "deflated compression"

    # recursize walking
    # https://www.tutorialspoint.com/How-to-zip-a-folder-recursively-using-Python

    # Python 3.7 - compress level 0 to 9

    epub_file = 'book-{}.epub'.format(math_format)
    _verbose('packaging an EPUB as {}'.format(epub_file))
    owd = os.getcwd()
    os.chdir(tmp_dir)
    with ZIP.ZipFile(epub_file, mode='w', compression=ZIP.ZIP_DEFLATED) as epub:
        epub.write('mimetype', compress_type=ZIP.ZIP_STORED)
        for root, dirs, files in os.walk('EPUB'):
            for name in files:
                epub.write(os.path.join(root, name))
        for root, dirs, files in os.walk('META-INF'):
            for name in files:
                epub.write(os.path.join(root, name))
        for root, dirs, files in os.walk('css'):
            for name in files:
                epub.write(os.path.join(root, name))
    shutil.copy2(epub_file, dest_dir)
    os.chdir(owd)


#################
# XSLT Processing
#################

# Pythonic replacement for xsltproc executable
def xsltproc(xsl, xml, result, output_dir=None, stringparams={}):
    """
    Apply an XSL stylesheet to an XML source, with control over location of results.

    xsl          - filename (string) for XSL stylesheet
    xml          - filename (string) for XML source
    result       - filename (string) for result tree of the stylesheet
                   None if stylesheet 100% writes its own files,
                   i.e. expecting an empty result tree
    output_dir   - a directory for exsl:document() templates to write to
    stringparams - a dictionary of option/value string:string pairs to
                   pass to  xsl:param  elements of the stylesheet
    """
    import os
    import lxml.etree as ET

    _verbose('XSL conversion of {} by {}'.format(xml, xsl))
    debug_string = 'XSL conversion via {} of {} to {} and/or into directory {} with parameters {}'
    _debug(debug_string.format(xsl, xml, result, output_dir, stringparams))

    # string parameters arrive in a "plain" string:string dictionary
    # but the values need to be prepped for lxml use, always
    stringparams = {key:ET.XSLT.strparam(value) for (key, value) in stringparams.items()}

    # parse source, no harm to assume
    # xinclude modularization is necessary
    src_tree = ET.parse(xml)
    src_tree.xinclude()

    # parse xsl, and build a transformation object
    # allow writing if an output directory is given
    # this is the default, but we are explicit here
    control = None
    if output_dir:
        control = ET.XSLTAccessControl(write_file=True)
    xsl_tree = ET.parse(xsl)
    xslt = ET.XSLT(xsl_tree, access_control=control)

    # do the transformation, with parameterization
    # possibly change/restore directories to capture
    # (multi-)file output from  exsl:document() calls
    owd = os.getcwd()
    if output_dir:
        os.chdir(output_dir)
    result_tree = xslt(src_tree, **stringparams)
    os.chdir(owd)

    # write a serialized version to a file if
    # there is a non-empty result tree on stdout
    # NB: this seems to presume an ASCII (not UTF-8)
    # encoding for output, no matter what stylesheet says
    # There seems to be a way to set this, but that would
    # possibly be a significant change in behavior, so
    # should be extensively tested
    if result:
        with open(result, 'w') as result_file:
            result_file.write(str(result_tree))


###################
#
# Utility Functions
#
###################

def set_verbosity(v):
    """Set how chatty routines are at console: 0, 1, or 2"""
    # 0 - nothing
    # 1 - _verbose() only
    # 2 - _verbose() and _debug()
    global _verbosity

    if ((v != 0) and (v !=1 ) and (v!= 2)):
        raise ValueError('PTX:ERROR: verbosity level is 0, 1, or 2, not {}'.format(v))
    _verbosity = v

def _verbose(msg):
    """Write a message to the console on program progress"""
    if _verbosity >= 1:
        print('PTX: {}'.format(msg))

def _debug(msg):
    """Write a message to the console with some raw information"""
    if _verbosity >= 2:
        print('PTX:DEBUG: {}'.format(msg))

def python_version():
    """Return 'major.minor' version number as string/info"""
    import sys

    return '{}.{}'.format(sys.version_info[0], sys.version_info[1])

def check_python_version():
    """Raise error with Python 2 (or less)"""
    import sys # version_info

    # This test could be more precise,
    # but only handling 2to3 switch when introduced
    msg = ''.join(["PreTeXt script/module expects Python 3.4, not Python 2 or older\n",
                   "You have Python {}\n",
                   "** Try prefixing your command-line with 'python3 ' **"])
    if sys.version_info[0] <= 2:
        raise(OSError(msg.format(python_version())))

def set_ptx_path():
    """Discover and set path to root of PreTeXt distribution"""
    # necessary to locate configuration files, XSL stylesheets
    # since authors can drop distribution *anywhere* in their system
    global _ptx_path
    import os.path # abspath(), split()

    # full path to module itself
    ptx_path = os.path.abspath(__file__)
    # split "python.py" off module's filename
    module_dir, _ = os.path.split(ptx_path)
    # split "pretext" path off executable
    _ptx_path, _ = os.path.split(module_dir)
    return None

def get_ptx_path():
    """Returns path to root of PreTeXt distribution"""
    global _ptx_path

    return _ptx_path

def get_ptx_xsl_path():
    """Returns path of PreTeXt XSL directory"""
    import os.path

    return os.path.join(get_ptx_path(), 'xsl')

def get_source_path(source_file):
    """Returns path of source XML file"""
    import sys, os.path

    # split path off filename
    source_dir, _ = os.path.split(source_file)
    _verbose("discovering source file's directory name: {}".format(source_dir))
    return os.path.normpath(source_dir)

def get_executable(exec_name):
    """Queries configuration file for executable name, verifies existence in Unix"""
    import os
    import platform
    import subprocess

    # parse user configuration(s), contains locations of executables
    # in the "executables" section of the INI-style file
    config = get_config_info()

    # http://stackoverflow.com/questions/11210104/check-if-a-program-exists-from-a-python-script
    # suggests  where.exe  as Windows equivalent (post Windows Server 2003)
    # which  = 'where.exe' if platform.system() == 'Windows' else 'which'

    # get the name, but then see if it really, really works
    _debug('locating "{}" in [executables] section of configuration file'.format(exec_name))
    config_name = config.get('executables', exec_name)

    devnull = open(os.devnull, 'w')
    try:
        result_code = subprocess.call(['which', config_name], stdout=devnull, stderr=subprocess.STDOUT)
    except OSError:
        print('PTX:WARNING: executable existence-checking was not performed (e.g. on Windows)')
        result_code = 0  # perhaps a lie on Windows
    if result_code != 0:
        error_message = '\n'.join([
                        'PTX:ERROR: cannot locate executable with configuration name "{}" as command "{}"',
                        '*** Edit the configuration file and/or install the necessary program ***'])
        raise OSError(error_message.format(exec_name, config_name))
    _debug("{} executable: {}".format(exec_name, config_name))
    return config_name

def sanitize_url(url):
    """Verify a server address, append a slash"""
    _verbose('validating, cleaning server URL: {}'.format(url))
    import requests
    try:
        requests.get(url)
    except requests.exceptions.RequestException as e:
        root_cause = str(e)
        msg = "PTX:ERROR: there was a problem with the server URL, {}\n".format(url)
        raise ValueError(msg + root_cause)
    # We expect relative paths to locations on the server
    # So we add a slash if there is not one already
    if url[-1] != "/":
        url = url + "/"
    return url

def sanitize_alpha_num_underscore(param):
    """Verify parameter is a string containing only alphanumeric and undescores"""
    import string
    allowed = set(string.ascii_letters + string.digits + '_')
    _verbose('verifying parameter: {}'.format(param))
    if not(set(param) <= allowed):
        raise ValueError('PTX:ERROR: param {} contains characters other than a-zA-Z0-9_ '.format(param))
    return param

def set_config_info():
    """Create configuation in object for querying"""
    global _config
    import os.path # join()
    import configparser # ConfigParser()

    ptx_dir = get_ptx_path()
    config_filename = 'pretext.cfg'
    default_config_file = os.path.join(ptx_dir, 'pretext', config_filename)
    user_config_file = os.path.join(ptx_dir, 'user', config_filename)
    # 2020-05-21: obsolete'd mbx script and associated config filenames
    # Try to read old version, but prefer new version
    stale_user_config_file = os.path.join(ptx_dir, 'user', 'mbx.cfg')
    config_file_list = [default_config_file, stale_user_config_file, user_config_file]
    # ConfigParser module was renamed to configparser in Python 3
    # and object was renamed from SafeConfigParser() to ConfigParser()
    _config = configparser.ConfigParser()

    _verbose("parsing possible configuration files: {}".format(config_file_list))
    files_read = _config.read(config_file_list)
    _debug("configuration files actually used/read: {}".format(files_read))
    if not(user_config_file in files_read):
        msg = "using default configuration only, custom configuration file not used at {}"
        _verbose(msg.format(user_config_file))
    return _config

# def debug_config_info():

def get_config_info():
    """Return configuation in object for querying"""
    global _config

    return _config

def copy_data_directory(source_file, data_dir, tmp_dir):
    """Stage directory from CLI argument into the working directory"""
    import os.path, shutil

    # Assumes all input paths are absolute, and that
    # data_dir is one step longer than directory for source_file,
    # in other words, data directory is a peer of source file
    _verbose("formulating data directory location")
    source_full_path, _ = os.path.split(source_file)
    data_last_step = os.path.basename(data_dir)
    destination_root = os.path.join(tmp_dir, data_last_step)
    _debug("copying data directory {} to working location {}".format(data_dir, destination_root))
    shutil.copytree(data_dir, destination_root)

def get_temporary_directory():
    """Create scratch directory and return a fully-qualified filename"""
    import tempfile # gettempdir()
    import os       # times(), makedirs()
    import os.path  # join()

    # TODO: condition on debugging switch to
    # make self-cleaning temporary directories

    # https://stackoverflow.com/questions/847850/
    # cross-platform-way-of-getting-temp-directory-in-python
    # TODO: convert hash value to unsigned hex?
    # t = os.path.join(tempfile.gettempdir(), 'pretext{}'.format(hash(os.times())))
    # os.makedirs(t)
    # return t
    return tempfile.mkdtemp()

########
#
# Module
#
########

# One-time set-up for global use in the module
# Module provides, and depends on:
#
#  _verbosity - level of detail in console output
#
#  _ptx_path - root directory of installed PreTeXt distribution
#              necessary to locate stylesheets and other support
#
#  _config - parsed values from an INI-style configuration file

# verbosity parameter defaults to 0 at startup
# employing application can use set_verbosity()
# to override via application's methodology
_verbosity = None
set_verbosity(0)

# Discover and set distribution path once at start-up
_ptx_path = None
set_ptx_path()

# Parse configuration file once
_config = None
set_config_info()