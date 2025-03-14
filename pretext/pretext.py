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

# Python Version History
# vermin is a great linter/checker to check versions required
#     https://github.com/netromdk/vermin.git
# 2023-10-13: this module expects Python 3.8 or newer
#     shutil.copytree now has dirs_exist_ok argument
# 2021-05-21: this module expects Python 3.6 or newer
#
#     subprocess.run() requires Python 3.5
#     shutil.which() member requires 3.3
#     otherwise Python 3.0 might be sufficient
# 2020-05-20: this module expects Python 3.4 or newer

# Set up logging package:
import logging
log = logging.getLogger('ptxlogger')

# Can show full traceback, and then continue processing
# https://stackoverflow.com/questions/3702675/
# how-to-catch-and-print-the-full-exception-traceback-without-halting-exiting-the
import traceback  # format_exc()

########################
# Module/Package Imports
########################

#   IMPORTANT NOTES:
#
# * Never use the forms:
#   from foo import *
#   from foo import bar, baz
#
#   Always use the forms:
#   import foo
#   import foo as BAR
#
#   Only use the latter sparingly, only for module-level imports,
#   and with recognizable and rational aliases
#
#   This makes debugging easier (we always know where a function is coming from)
#   and it makes maintenance easier (search, and replace, are both more reliable)
#
# * For standard libraries used routinely, place import statements
#   here at the module level, with some documentation of the necessity
#
# * For standard libraries used infrequently (in three or fewer functions?),
#   include imports in the functions

# primarily directory manipulations (creating, switching, deleting)
import os

# primarily joining paths, but sometimes splitting
import os.path

# primarily copying entire directory trees of files, also which()
# we limit ourselves to shutil.copy2 and shutil.copytree
# Study: https://www.techbeamers.com/python-copy-file/
import shutil

# "shelling out" to run executables
# TODO: run() is preferable to call()
import subprocess

# version and platform inspection
import sys

# creation of zip'ed output or bundles
import zipfile

# regular expression tools
import re

# contextmanager tools
import contextlib

# * For non-standard packages (such as those installed via PIP) try to keep
#   dependencies to a minimum by *not* importing at the module-level
#   (with justified exceptions)
#
# * For non-standard packages always import within a try/except block
#   and use the provided warning message for failures
#
# * The "requests" module would be a candidate for a module-level
#   import but we prefer to leave it as an optional dependency

# This is a convenience for a uniform (detailed) warning when
# an "extraneous" module fails to load, which is indicative of
# some problem with an author's working environment
__module_warning = "\n".join(
    [
        'PTX ERROR: the "{}" module has failed to load, and',
        "  this is necessary for the task you have requested.  Perhaps",
        "  you have not installed it?  Or perhaps you have forgotten to",
        "  use a Python virtual environment you set up for this purpose?",
    ]
)

# Not much can be done without the "lxml" module which mimics
# the "xsltproc" executable (they share the same libraries)
try:
    import lxml.etree as ET
except ImportError:
    raise ImportError(__module_warning.format("lxml"))


#############################
#
#  Math as LaTeX on web pages
#
#############################


def mathjax_latex(xml_source, pub_file, out_file, dest_dir, math_format):
    """Convert PreTeXt source to a structured file of representations of mathematics"""
    # formats:  'svg', 'mml', 'nemeth', 'speech', 'kindle'
    # Internal calls will specify out_file with complete path
    # External calls might only specify a destination directory
    import fileinput  # for &nbsp; fix

    log.info("converting LaTeX from {} into {} format".format(xml_source, math_format))
    log.debug("converting LaTeX from {} into {} format".format(xml_source, math_format))

    # construct filenames for pre- and post- XSL stylesheets in xsl/support
    extraction_xslt = os.path.join(get_ptx_xsl_path(), "support/extract-math.xsl")
    cleaner_xslt = os.path.join(get_ptx_xsl_path(), "support/package-math.xsl")

    # Extraction stylesheet makes a simple, mock web page for MathJax
    # And MathJax executables preserve the page while changing the math
    tmp_dir = get_temporary_directory()
    mjinput = os.path.join(tmp_dir, "mj-input-latex.html")
    mjintermediate = os.path.join(tmp_dir, "mj-intermediate.html")
    mjoutput = os.path.join(tmp_dir, "mj-output-{}.html".format(math_format))

    log.debug("temporary directory for MathJax work: {}".format(tmp_dir))
    log.debug("extracting LaTeX from {} and collected in {}".format(xml_source, mjinput))

    # SVG, MathML, and PNG are visual and we help authors move punctuation into
    # displays, but not into inline versions.  Nemeth braille and speech are not,
    # so we leave punctuation outside.
    # 2022-11-01: extraction stylesheet now supports a subtree root,
    # which we could pass from the interface, into this function, then
    # into the string parameters.  However, we don't see a real need yet
    # for this, so we just leave this comment instead.
    if math_format in ["svg", "mml", "kindle"]:
        punctuation = "display"
    elif math_format in ["nemeth", "speech"]:
        punctuation = "none"
    params = {}
    params["math.punctuation"] = punctuation
    if pub_file:
        params["publisher"] = pub_file
    xsltproc(extraction_xslt, xml_source, mjinput, None, params)
    # Trying to correct baseline for inline math in Kindle, so we
    # insert a \mathstrut into all the inline math before feeding to MathJax
    if math_format == "kindle":
        with fileinput.FileInput(mjinput, inplace=True) as file:
            for line in file:
                print(line.replace(r"\(", r"\(\mathstrut "), end="")

    # shell out to process with MathJax/SRE node program
    msg = (
        "calling MathJax to convert LaTeX from {} into raw representations as {} in {}"
    )
    log.debug(msg.format(mjinput, math_format, mjoutput))

    # process with  pretext.js  executable from  MathJax (Davide Cervone, Volker Sorge)
    node_exec_cmd = get_executable_cmd("node")
    mjsre_page = os.path.join(get_ptx_path(), "script", "mjsre", "mj-sre-page.js")
    output = {
        "svg": "svg",
        "kindle": "mathml",
        "nemeth": "braille",
        "speech": "speech",
        "mml": "mathml",
    }
    try:
        mj_var = output[math_format]
    except KeyError:
        raise ValueError(
            'PTX:ERROR: incorrect format ("{}") for MathJax conversion'.format(
                math_format
            )
        )
    mj_option = "--" + mj_var
    mj_tag = "mj-" + mj_var
    mjpage_cmd = node_exec_cmd + [mjsre_page, mj_option, mjinput]
    with open(mjoutput, "w") as outfile:
        subprocess.run(mjpage_cmd, stdout=outfile)

    # the 'mjpage' executable converts spaces inside of a LaTeX
    # \text{} into &nbsp; entities, which is a good idea, and
    # fine for HTML, but subsequent conversions expecting XHTML
    # do not like &nbsp; nor &#xa0.  Be careful just below, as
    # repl contains a *non-breaking space* not a generic space.
    orig = "&nbsp;"
    repl = " "
    xhtml_elt = re.compile(orig)
    # the inplace facility of the fileinput module gets
    # confused about temporary backup files if the working
    # directory is not where the file lives
    # Also, print() here actual writes on the file, as
    # another facility of the fileinput module, but we need
    # to kill the "extra" newline that print() creates
    with working_directory(tmp_dir):
        html_file = mjoutput
        with fileinput.FileInput(html_file, inplace=True) as file:
            for line in file:
                print(xhtml_elt.sub(repl, line), end="")

    # clean up and package MJ representations, font data, etc
    derivedname = get_output_filename(
        xml_source, out_file, dest_dir, "-" + math_format + ".xml"
    )
    log.debug(
        "packaging math as {} from {} into XML file {}".format(
            math_format, mjoutput, out_file
        )
    )
    xsltproc(cleaner_xslt, mjoutput, derivedname)
    log.info("XML file of math representations deposited as {}".format(derivedname))


##############################################
#
#  Graphics Language Extraction and Processing
#
##############################################

def prefigure_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat):
    """Extract PreFigure code for diagrams and convert to graphics formats"""
    # stringparams is a dictionary, best for lxml parsing
    import glob

    try:
        import prefig
    except ImportError:
        raise ImportError(__module_warning.format("prefig"))

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    msg = 'converting PreFigure diagrams from {} to {} graphics for placement in {}'
    log.info(msg.format(xml_source, outformat.upper(), dest_dir))

    tmp_dir = get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-prefigure.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # no output (argument 3), stylesheet writes out per-image file
    # outputs a list of ids, but we just loop over created files
    log.info("extracting PreFigure diagrams from {}".format(xml_source))
    log.info("string parameters passed to extraction stylesheet: {}".format(stringparams))
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)

    # Resulting *.asy files are in tmp_dir, switch there to work
    with working_directory(tmp_dir):
        if outformat == "source" or outformat == "all":
            log.info("copying PreFigure source files into {}".format(dest_dir))
            shutil.copytree(
                tmp_dir,
                dest_dir,
                dirs_exist_ok=True
            )

        # get a list of all the source files and remove the publication file
        pf_source_files = os.listdir(tmp_dir)
        try:
            pf_source_files.remove('pf_publication.xml')
        except ValueError:
            pass

        if outformat == "svg":
            for pfdiagram in pf_source_files:
                log.info("compiling PreFigure source file {} to SVG".format(pfdiagram))
                prefig.engine.build('svg', pfdiagram)

        elif outformat == "pdf":
            for pfdiagram in pf_source_files:
                log.info("compiling PreFigure source file {} to PDF".format(pfdiagram))
                prefig.engine.pdf('svg', pfdiagram, dpi=100)

        elif outformat == "png":
            for pfdiagram in pf_source_files:
                log.info("compiling PreFigure source file {} to PNG".format(pfdiagram))
                prefig.engine.png('svg', pfdiagram)

        elif outformat == "tactile":
            for pfdiagram in pf_source_files:
                log.info("compiling PreFigure source file {} to tactile PDF".format(pfdiagram))
                prefig.engine.pdf('tactile', pfdiagram)

        elif outformat == "all":
            # make directories for the resulting diagrams
            # PreFigure makes 'output' but we also want to create 'output/tactile'
            os.mkdir('output')
            os.mkdir('output/tactile')

            # iterate through the diagrams making each format
            for pfdiagram in pf_source_files:
                log.info("compiling PreFigure source file {} to tactile PDF".format(pfdiagram))
                prefig.engine.pdf('tactile', pfdiagram)
                pdf_name = pfdiagram[:-4] + '.pdf'
                shutil.move('output/'+pdf_name, 'output/tactile/'+pdf_name)

                log.info("compiling PreFigure source file {} to PNG".format(pfdiagram))
                prefig.engine.png('svg', pfdiagram)

                log.info("compiling PreFigure source file {} to PDF".format(pfdiagram))
                prefig.engine.pdf('svg', pfdiagram, dpi=100)

                log.info("compiling PreFigure source file {} to SVG".format(pfdiagram))
                prefig.engine.build('svg', pfdiagram)

        # Check to see if we made some diagrams before copying the tree
        if os.path.exists('output'):
            log.info("copying PreFigure output to {}".format(dest_dir))
            shutil.copytree(
                'output',
                dest_dir,
                dirs_exist_ok=True
            )

def asymptote_conversion(
    xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat, method, ext_converter
):
    """Extract asymptote code for diagrams and convert to graphics formats"""
    # stringparams is a dictionary, best for lxml parsing
    # method == 'local': use a system executable from pretext.cfg
    # method == 'server': hit a server at U of Alberta, Asymptote HQ
    # ext_converter: an optinal hook for external libraries to patch
    #                the conversion of individual images.  The intent is that ext_converter
    #                attempts to use a cached version of the image, or else calls
    #                individual_asymptote_conversion() to generate the image (and cache it).
    #
    # If buggy, and server/communication is suspected, try an Asy
    # source file generated by this script (located in temporary
    # directory preserved by -vv), using, e.g.,
    #   curl --data-binary @source.asy 'asymptote.ualberta.ca:10007?f=svg' > output.svg
    import glob

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    try:
        import requests  # post()
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("requests"))

    msg = 'converting Asymptote diagrams from {} to {} graphics for placement in {} with method "{}"'
    log.info(msg.format(xml_source, outformat.upper(), dest_dir, method))

    # front-ends and calling routines should guarantee the following
    if not (method in ["local", "server"]):
        raise ValueError(
            "{} is not a method for Asymptote diagram generation".format(method)
        )

    tmp_dir = get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-asymptote.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # no output (argument 3), stylesheet writes out per-image file
    # outputs a list of ids, but we just loop over created files
    log.info("extracting Asymptote diagrams from {}".format(xml_source))
    log.info(
        "string parameters passed to extraction stylesheet: {}".format(stringparams)
    )
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    # Resulting *.asy files are in tmp_dir, switch there to work
    with working_directory(tmp_dir):
        # simply copy for source file output
        # no need to check executable or server, PreTeXt XSL does it all
        if outformat == "source" or outformat == "all":
            for asydiagram in os.listdir(tmp_dir):
                log.info("copying source file {}".format(asydiagram))
                shutil.copy2(asydiagram, dest_dir)
        # consolidated process for five possible output formats
        # parameterized for places where  method  differs
        if outformat == "all":
            outformats = ["html", "svg", "png", "pdf", "eps"]
        elif outformat in ["html", "svg", "png", "pdf", "eps"]:
            outformats = [outformat]
        else:
            outformats = []
        for outform in outformats:
            # initialize variables for each method
            asy_cli = []
            alberta = ""
            asyversion = ""
            # setup, depending on the method
            if method == "local":
                asy_executable_cmd = get_executable_cmd("asy")
                # perhaps replace following stock advisory
                # with a real version check.  Perhaps see:
                # https://stackoverflow.com/questions/11887762/how-do-i-compare-version-numbers-in-python
                proc = subprocess.Popen(
                    [asy_executable_cmd[0], "--version"], stderr=subprocess.PIPE
                )
                # bytes -> ASCII, strip final newline
                asyversion = proc.stderr.read().decode("ascii")[:-1]
                # build command line to suit
                # 2021-12-10, Michael Doob: "-noprc" is default for the server,
                # and newer CLI versions.  Retain for explicit use locally when
                # perhaps an older version is being employed
                asy_cli = asy_executable_cmd + ["-f", outform, "-noV"]
                if outform in ["pdf", "eps"]:
                    asy_cli += ["-noprc", "-iconify", "-tex", "xelatex", "-batchMask"]
                elif outform in ["svg", "png"]:
                    asy_cli += ["-render=4", "-tex", "xelatex", "-iconify"]
            if method == "server":
                alberta = "http://asymptote.ualberta.ca:10007?f={}".format(outform)
            # loop over .asy files, doing conversions
            for asydiagram in glob.glob(os.path.join(tmp_dir, "*.asy")):
                if ext_converter:
                    ext_converter(asydiagram, outform, method, asy_cli, asyversion, alberta, dest_dir)
                else:
                    individual_asymptote_conversion(asydiagram, outform, method, asy_cli, asyversion, alberta, dest_dir)

def individual_asymptote_conversion(asydiagram, outform, method, asy_cli, asyversion, alberta, dest_dir):
    try:
        import requests  # post()
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("requests"))

    filebase, _ = os.path.splitext(asydiagram)
    asyout = "{}.{}".format(filebase, outform)
    log.info("converting {} to {}".format(asydiagram, asyout))
    # do the work, depending on method
    if method == "local":
        asy_cmd = asy_cli + [asydiagram]
        log.debug("asymptote conversion {}".format(asy_cmd))
        subprocess.call(asy_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    if method == "server":
        log.debug("asymptote server query {}".format(alberta))
        with open(asydiagram) as f:
            # protect against Unicode (in comments?)
            data = f.read().encode("utf-8")
            response = requests.post(url=alberta, data=data)
            open(asyout, "wb").write(response.content)
    # copy resulting image file, or warn/advise about failure
    if os.path.exists(asyout):
        shutil.copy2(asyout, dest_dir)
    else:
        msg = [
            "the Asymptote output {} was not built".format(asyout),
            "             Perhaps your code has errors (try testing in the Asymptote web app).",
        ]
        if method == "local":
            msg += [
                "             Or your local copy of Asymtote may precede version 2.66 that we expect.",
                "             In this case, not every image can be built in every possible format.",
                "",
                "             Your Asymptote reports its version within the following:",
                "             {}".format(asyversion),
            ]
        log.warning("\n".join(msg))

def sage_conversion(
    xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat, ext_converter
):

    # ext_converter: an optinal hook for external libraries to patch
    #                the conversion of individual images.  The intent is that ext_converter
    #                attempts to use a cached version of the image, or else calls
    #                individual_sage_conversion() to generate the image (and cache it).
    #
    # To make all four formats, just call this routine
    # four times and halt gracefully with an explicit "return"
    if outformat == "all":
        log.info('Pass 1 for "all" formats, now generating PDF')
        sage_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, "pdf", ext_converter)
        log.info('Pass 2 for "all" formats, now generating SVG')
        sage_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, "svg", ext_converter)
        log.info('Pass 3 for "all" formats, now generating PNG')
        sage_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, "png", ext_converter)
        log.info('Pass 4 for "all" formats, now generating HTML')
        sage_conversion(
            xml_source, pub_file, stringparams, xmlid_root, dest_dir, "html", ext_converter
        )
        return None
    # The real routine, which is thinly parameterized by "outformat",
    # thus necessitating the four separate calls above due to the
    # extraction stylesheet producing slightly different Sage code
    # for each possible output format
    log.info(
        "converting Sage diagrams from {} to {} graphics for placement in {}".format(
            xml_source, outformat.upper(), dest_dir
        )
    )
    tmp_dir = get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    sage_executable_cmd = get_executable_cmd("sage")
    # TODO why this debug line? get_executable_cmd() outputs the same debug info
    log.debug("sage executable: {}".format(sage_executable_cmd[0]))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-sageplot.xsl")
    log.info("extracting Sage diagrams from {}".format(xml_source))
    # extraction stylesheet is parameterized by fileformat
    # this is an internal parameter only, do not use otherwise
    stringparams["sageplot.fileformat"] = outformat
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    with working_directory(tmp_dir):
        failed_images = []
        for sageplot in os.listdir(tmp_dir):
            try:
                if ext_converter:
                    ext_converter(sageplot, outformat, dest_dir, sage_executable_cmd)
                else:
                    individual_sage_conversion(sageplot, outformat, dest_dir, sage_executable_cmd)
            except Exception as e:
                failed_images.append(sageplot)
                log.warning(e)
    # raise an error if there were *any* failed images
    if failed_images:
        msg = "\n".join(
            [
                'Sage conversion failed for {} sageplot(s).',
                "Build with '-v debug' option and review the log for error messages.",
                "Images are:",
            ]
        ).format(len(failed_images))
        # 2-space indentation
        image_list = "\n  " + "\n  ".join(failed_images)
        raise ValueError(msg + image_list)

def individual_sage_conversion(sageplot, outformat, dest_dir, sage_executable_cmd):
    filebase, _ = os.path.splitext(sageplot)
    sageout = "{0}.{1}".format(filebase, outformat)
    sage_cmd = sage_executable_cmd + [sageplot]
    log.info("converting {} to {}".format(sageplot, sageout))
    log.debug("sage conversion {}".format(sage_cmd))

    result = subprocess.run(sage_cmd, capture_output=True, encoding="utf-8")
    if result.returncode:
        log.debug(result.stderr)
        raise Exception("sage conversion of {} failed".format(sageplot))
    else:
        shutil.copy2(sageout, dest_dir)

def latex_image_conversion(
    xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat, method, ext_converter
):
    # stringparams is a dictionary, best for lxml parsing
    # ext_converter: an optinal hook for external libraries to patch
    #                the conversion of individual images.  The intent is that ext_converter
    #                attempts to use a cached version of the image, or else calls
    #                individual_latex_image_conversion() to generate the image (and cache it).

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    log.info(
        "converting latex-image pictures from {} to {} graphics for placement in {}".format(
            xml_source, outformat, dest_dir
        )
    )
    tmp_dir = get_temporary_directory()
    log.debug("temporary directory for latex-image conversion: {}".format(tmp_dir))
    ptx_xsl_dir = get_ptx_xsl_path()
    log.info("extracting latex-image pictures from {}".format(xml_source))
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    log.info(
        "string parameters passed to extraction stylesheet: {}".format(stringparams)
    )
    # Need to copy entire external directory in the managed case.
    # Making data files available for latex image compilation is
    # not supported outside of the managed directory scheme (2021-07-28)
    _, external_dir = get_managed_directories(xml_source, pub_file)
    copy_managed_directories(tmp_dir, external_abs=external_dir)
    # now create all the standalone LaTeX source files
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-latex-image.xsl")
    # no output (argument 3), stylesheet writes out per-image file
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    # now work in temporary directory
    with working_directory(tmp_dir):
        # and maintain a list of failures for later
        failed_images = []
        # files *only*, from top-level
        files = list(filter(os.path.isfile, os.listdir(tmp_dir)))
        for latex_image in files:
            try:
                if ext_converter:
                    ext_converter(latex_image, outformat, dest_dir, method)
                else:
                    individual_latex_image_conversion(latex_image, outformat, dest_dir, method)
            except ImportError:
                # re-raise the ImportError pdfCropMargins or pyMuPDF is not imported.
                raise
            except Exception as e:
                failed_images.append(latex_image)
                # We continue to try to process other images, but log a warning.
                log.warning(e)

    # raise an error if there were *any* failed images
    if failed_images:
        msg = "\n".join(
            [
                'LaTeX compilation failed for {} "latex-image"(s).',
                "Review the log for error messages, and LaTeX transcripts.",
                "Images are:",
            ]
        ).format(len(failed_images))
        # 2-space indentation
        image_list = "\n  " + "\n  ".join(failed_images)
        raise ValueError(msg + image_list)

def individual_latex_image_conversion(latex_image, outformat, dest_dir, method):
    # external module, often forgotten
    try:
        import pdfCropMargins
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("pdfCropMargins"))
    try:
        import fitz # for svg and png conversion
    except ImportError:
        raise ImportError(__module_warning.format("pyMuPDF"))

    if outformat == "source":
        shutil.copy2(latex_image, dest_dir)
        log.info("copying {} to {}".format(latex_image, dest_dir))
    else:
        filebase, _ = os.path.splitext(latex_image)
        latex_image_pdf = "{}.pdf".format(filebase)
        latex_image_svg = "{}.svg".format(filebase)
        latex_image_png = "{}.png".format(filebase)
        latex_image_eps = "{}.eps".format(filebase)
        latex_image_log = "{}.log".format(filebase)
        # process with a  latex  engine
        latex_key = get_deprecated_tex_fallback(method)
        tex_executable_cmd = get_executable_cmd(latex_key)
        # TODO why this debug line? get_executable_cmd() outputs the same debug info
        log.debug("tex executable: {}".format(tex_executable_cmd[0]))
        latex_cmd = tex_executable_cmd + ["-interaction=nonstopmode", "-halt-on-error", latex_image]
        log.info("converting {} to {}".format(latex_image, latex_image_pdf))
        # Run LaTeX on the image file, usual console transcript is stdout.
        # "result" is a "CompletedProcess" object.  Specifying an encoding
        # causes captured output to be a string, which is convenient.
        result = subprocess.run(latex_cmd, stdout=subprocess.PIPE, encoding="utf-8")

        # It may be that the image needs to be compiled twice. If the .log file contains
        # the string `Rerun to get`, then the document should be compiled again.

        # We keep track of how many times we've tried to compile the document and
        # bail if it looks like we're stuck in a loop.
        loop_count = 0
        MAX_LOOPS = 10
        while result.returncode == 0 and "Rerun to get" in open(latex_image_log).read() and loop_count < MAX_LOOPS:
            msg = "File {} needs to be processed with LaTeX again. Rerunning LaTeX for pass number {}."
            log.info(msg.format(latex_image, loop_count + 2))
            result = subprocess.run(latex_cmd, stdout=subprocess.PIPE, encoding="utf-8")
            loop_count += 1

        if loop_count == MAX_LOOPS:
            log.error("Detected infinite loop while compiling {}. Aborting.".format(latex_image))
            result.returncode = 1

        if result.returncode != 0:
            # failed to compile the LaTeX image
            # we help as much as we can
            msg = "\n".join(
                [
                    "LaTeX compilation of {} failed.",
                    'Re-run, requesting "source" as the format, to analyze the image.',
                    "Likely creating the entire document as PDF will fail similarly.",
                    "The transcript of the LaTeX run follows.",
                ]
            ).format(latex_image)
            log.error(msg)
            print(
                "##################################################################"
            )
            print(result.stdout)
            print(
                "##################################################################"
            )
            # and raise an exception so the calling function can add the image to the list of failed images
            raise Exception("LaTeX compilation of {} failed".format(latex_image))
        else:
            # Threshold implies only byte value 255 is white, which
            # assumes these images are *produced* on white backgrounds
            pcm_cmd = [
                latex_image_pdf,
                "-o",
                "cropped-" + latex_image_pdf,
                "-t",
                "254",
                "-p",
                "0",
                "-a",
                "-1",
            ]
            log.info(
                "cropping {} to {}".format(
                    latex_image_pdf, "cropped-" + latex_image_pdf
                )
            )
            pdfCropMargins.crop(pcm_cmd)
            if not os.path.exists("cropped-" + latex_image_pdf):
                log.error(
                    "There was a problem cropping {} and {} was not created".format(
                        latex_image_pdf, "cropped-" + latex_image_pdf
                    )
                )
            shutil.move("cropped-" + latex_image_pdf, latex_image_pdf)
            log.info(
                "renaming {} to {}".format(
                    "cropped-" + latex_image_pdf, latex_image_pdf
                )
            )
            if outformat == "all":
                shutil.copy2(latex_image, dest_dir)
            if outformat == "pdf" or outformat == "all":
                shutil.copy2(latex_image_pdf, dest_dir)
            if outformat == "svg" or outformat == "all":
                # create svg using pymupdf:
                log.info("converting {} to {}".format(latex_image_pdf, latex_image_svg))
                with fitz.Document(latex_image_pdf) as doc:
                    svg = doc.load_page(0).get_svg_image()
                with open(latex_image_svg, "w") as f:
                    f.write(svg)

                if not os.path.exists(latex_image_svg):
                    log.error(
                        "There was a problem converting {} to svg and {} was not created".format(
                            latex_image_pdf, latex_image_svg
                        )
                    )
                shutil.copy2(latex_image_svg, dest_dir)
            if outformat == "png" or outformat == "all":
                # create high-quality png using pymupdf:
                log.info("converting {} to {}".format(latex_image_pdf, latex_image_png))
                with fitz.Document(latex_image_pdf) as doc:
                    png = doc.load_page(0).get_pixmap(dpi=300, alpha=True)
                png.save(latex_image_png)
                shutil.copy2(latex_image_png, dest_dir)

                if not os.path.exists(latex_image_png):
                    log.error(
                        "There was a problem converting {} to png and {} was not created".format(
                            latex_image_pdf, latex_image_png
                        )
                    )
                shutil.copy2(latex_image_png, dest_dir)
            if outformat == "eps" or outformat == "all":
                pdfeps_executable_cmd = get_executable_cmd("pdfeps")
                # TODO why this debug line? get_executable_cmd() outputs the same debug info
                log.debug("pdfeps executable: {}".format(pdfeps_executable_cmd[0]))
                eps_cmd = pdfeps_executable_cmd + [
                    "-eps",
                    latex_image_pdf,
                    latex_image_eps,
                ]
                log.info(
                    "converting {} to {}".format(latex_image_pdf, latex_image_eps)
                )
                subprocess.call(eps_cmd)
                if not os.path.exists(latex_image_eps):
                    log.error(
                        "There was a problem converting {} to eps and {} was not created".format(
                            latex_image_pdf, latex_image_eps
                        )
                    )
                shutil.copy2(latex_image_eps, dest_dir)

#############################################
#
# Binary Source Files to Base 64 in XML Files
#
#############################################

def datafiles_to_xml(xml_source, pub_file, stringparams, xmlid_root, dest_dir):
    """Convert certain  files in source to text representations in XML files"""
    # stringparams is a dictionary, best for lxml parsing

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    import base64

    msg = 'converting data files from {} to text representations in XML files for placement in {}'
    log.info(msg.format(xml_source, dest_dir))

    tmp_dir = get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-datafile.xsl")
    the_files = os.path.join(tmp_dir, 'datafile-list.txt')
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # no output (argument 3), stylesheet writes out per-image file
    # outputs a list of ids, but we just loop over created files
    log.info("extracting source files from {}".format(xml_source))
    log.info("string parameters passed to extraction stylesheet: {}".format(stringparams) )
    xsltproc(extraction_xslt, xml_source, the_files, None, stringparams)

    # Copy in external resources (e.g., js code)
    generated_abs, external_abs = get_managed_directories(xml_source, pub_file)

    # Each file receives a single element as its root
    # element. These are templates for that entry
    image_info = '<pi:image-b64 xmlns:pi="http://pretextbook.org/2020/pretext/internal" pi:mime-type="{}" pi:base64="{}"/>'
    text_info  = '<pi:text-file xmlns:pi="http://pretextbook.org/2020/pretext/internal">{}</pi:text-file>'

    # read lines, one-per-binary
    with open(the_files, "r") as datafile_list:
        dfs = datafile_list.readlines()
    for df in dfs:
        visible_id, file_type, relative_path = df.split()
        data_file = os.path.join(external_abs, relative_path)
        log.debug("converting data file {} to a text/XML file".format(data_file))

        # Now condition of the "kind" of file given in source
        # according to the use of certain PTX elements
        # Each stanza should produce the contents of a UTF-8 XML file
        if file_type == "image":
            # best guess of image type, as a MIME type
            # https://en.wikipedia.org/wiki/Media_type
            # https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
            # https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
            _, extension = os.path.splitext(data_file)
            # normalize, drop leading period
            # in rough popularity order
            lcext = extension[1:].lower()
            if lcext in ["jpeg", "jpg"]:
                mime_type = "image/jpeg"
            elif lcext == "png":
                mime_type = "image/png"
            elif lcext =="gif":
                mime_type = "image/gif"
            elif lcext =="webp":
                mime_type = "image/webp"
            elif lcext =="avif":
                mime_type = "image/avif"
            elif lcext =="apng":
                mime_type = "image/apng"
            # Do we want to base64 an XML file???
            elif lcext =="svg":
                mime_type = "image/svg+xml"
            else:
                log.info("PTX:WARNING : MIME type of image {} not determined".format(data_file))
                mime_type = "unknown"

            # Open binary file and encode in base64 with standard module
            with open(data_file, "rb") as f:
                base64version = base64.b64encode(f.read()).decode("utf8")
            xml_representation = image_info.format(mime_type, base64version)
        elif file_type == "pre":
            with open(data_file, "rb") as f:
                rawtext = f.read().decode("utf8")
            xml_representation = text_info.format(rawtext)
        else:
            xml_representation = "<oops/>"

        # Open as a text file (i.e. not binary), since we have
        # built text/XML representations, we know this really is
        # "straight" ASCII.  The XML header says "UTF-8", which
        # is not a problem?
        out_filename = os.path.join(dest_dir, visible_id + '.xml')
        with open(out_filename, "w") as f:
            f.write(__xml_header)
            f.write(xml_representation)


#######################
#
#  LaTeX Tactile Images
#
#######################


def latex_tactile_image_conversion(xml_source, pub_file, stringparams, dest_dir, outformat):
    '''Support for tactile versions of "latex-image" removed 2024-07-29'''

    msg = "\n".join(['Support for production of "latex-image" as tactile',
                     "graphics with braille labels was discontinued on 2024-07-29.",
                     "Instead, investigate the PreFigure project at prefigure.org."])
    raise ValueError(msg)


#####################
# Traces for CodeLens
#####################

# Convert program source code into traces for the interactive
# CodeLens tool in Runestone

def tracer(xml_source, pub_file, stringparams, xmlid_root, dest_dir):

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    try:
        import requests  # post()
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("requests"))

    # Trace Server: language abbreviation goes in argument
    url_string = "http://tracer.runestone.academy:5000/trace{}"
    server_error_msg = '\n'.join([
           "the server at {} could not process program source file {}.",
           "No trace file was produced.  The generated traceback follows, other files will still be processed."
           ])

    log.info(
        "creating trace data from {} for placement in {}".format(xml_source, dest_dir)
    )
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-trace.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's, languages, sources into a scratch directory/file
    tmp_dir = get_temporary_directory()
    code_filename = os.path.join(tmp_dir, "codelens.txt")
    log.debug("Program sources for traces temporarily in {}".format(code_filename))
    xsltproc(extraction_xslt, xml_source, code_filename, None, stringparams)
    # read lines, one-per-program
    with open(code_filename, "r") as code_file:
        programs = code_file.readlines()
    for program in programs:
        # three parts, always
        program_quad = program.split(",", 3)
        runestone_id = program_quad[0]
        visible_id = program_quad[1]
        language = program_quad[2]
        if language == 'python':
            url = url_string.format('py')
        else:
            # c, cpp, java
            url = url_string.format(language)
        # instead use  .decode('string_escape')  somehow
        # as part of reading the file?
        source = program_quad[3].replace("\\n", "\n")
        log.info("converting {} source {} to a trace...".format(language, visible_id))

        # success will replace this empty string
        trace = ""
        if (language == "c") or (language == "cpp"):
            try:
                r = requests.post(url, data=dict(src=source), timeout=30)
                if r.status_code == 200:
                    trace = r.text[r.text.find('{"code":') :]
            except Exception as e:
                log.critical(traceback.format_exc())
                log.critical(server_error_msg.format(url, visible_id))
        elif language == "java":
            try:
                r = requests.post(url, data=dict(src=source), timeout=30)
                if r.status_code == 200:
                    trace = r.text
            except Exception as e:
                log.critical(traceback.format_exc())
                log.critical(server_error_msg.format(url, visible_id))
        elif language == "python":
            try:
                r = requests.post(url, data=dict(src=source), timeout=30)
                if r.status_code == 200:
                    trace = r.text
            except Exception as e:
                log.critical(traceback.format_exc())
                log.critical(server_error_msg.format(url, visible_id))
        # should now have a trace, except for timing out
        # no trace, then do not even try to produce a file
        if trace:
            script_leadin_string = 'if (allTraceData === undefined) {{\n var allTraceData = {{}};\n }}\n allTraceData["{}"] = '
            script_leadin = script_leadin_string.format(runestone_id)
            trace = script_leadin + trace
            trace_file = os.path.join(dest_dir, "{}.js".format(visible_id))
            with open(trace_file, "w") as f:
                f.write(trace)


################################
#
#  Dynamic Exercise Static Representations
#
################################
def dynamic_substitutions(xml_source, pub_file, stringparams, xmlid_root, dest_dir, ext_rs_methods):
    import asyncio  # get_event_loop()

    # external module, often forgotten
    # imported here, used only in interior
    # routine to launch browser
    try:
        import playwright.async_api  # launch()
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("playwright"))

    # Interior asynchronous routine to manage the Chromium headless browser.
    # Use the same page instance for the generation of all interactive previews
    async def extract_substitutions(dynamic_elements, baseurl, subst_file):

        # dynamic_elements:  list containing the interactive hash/fragment ids [1:]
        # baseurl:           local server's base url (includes local port)
        # subst_file:        file containing the substitutions

        # Open playwright's asynchronous api to load a browser and page
        async with playwright.async_api.async_playwright() as pw:
            browser = await pw.chromium.launch()
            page = await browser.new_page()

            msg = 'Storing dynamic substitutions in file {}'
            log.info(msg.format(subst_file))
            subst_xml = open(subst_file, "w")
            subst_xml.write("<xml>")
            # First index contains original baseurl of hosted site (not used)
            for dynamic_entry in dynamic_elements:
                entries = dynamic_entry.split("\t")
                dynamic_container = entries[0]
                dynamic_task = entries[1]
                # loaded page url containing interactive
                input_page = os.path.join(baseurl, dynamic_container + ".html")

                # progress report
                msg = 'extracting substitutions for exercise-interactive with identifier "{}" on page {}'
                log.info(msg.format(dynamic_task, input_page))

                # goto page and wait for content to load
                await page.goto(input_page, wait_until='domcontentloaded')
                await page.wait_for_timeout(1000)
                # see what Runestone substituted into the expressions
                xpath = "//div[@id='{}-substitutions']".format(dynamic_task)
                elt = page.locator(xpath)
                exercise_substitutions = await elt.inner_html()

                # add this to the XML of all substitutions
                # redundancies will be present but don't matter
                element = '<dynamic-substitution id="{}">'
                subst_xml.write(element.format(dynamic_task))
                subst_xml.write(exercise_substitutions)
                subst_xml.write("</dynamic-substitution>")

            subst_xml.write("</xml>")
            subst_xml.close()
            await browser.close()

    log.info(
        "using playwright package to determine substitutions in dynamic exercises from {}".format(
            xml_source
        )
    )

    # Identify dynamic exercises that will be processed
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-dynamic.xsl")
    # Where to store the results
    dyn_subs_file = os.path.join(dest_dir, "dynamic_substitutions.xml")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root

    tmp_dir = get_temporary_directory()

    # interrogate Runestone server (or debugging switches) and populate
    # NB: stringparams is augmented with Runestone Services information
    _place_runestone_services(tmp_dir, stringparams, ext_rs_methods)

    generated_abs, external_abs = get_managed_directories(xml_source, pub_file)
    if external_abs:
        external_dir = os.path.join(tmp_dir, "external")
        shutil.copytree(external_abs, external_dir)
    copy_html_js(tmp_dir)

    # Build list of id's into a scratch directory/file
    id_filename = os.path.join(tmp_dir, "dynamic-ids.txt")
    log.debug("Dynamic exercise id list temporarily in {}".format(id_filename))
    log.debug("Dynamic exercise html files temporarily in {}".format(tmp_dir))
    # This next call outputs the list of ids
    # *and* produce a pile of files (the "standalone") pages
    xsltproc(extraction_xslt, xml_source, id_filename, tmp_dir, stringparams)
    # read the list of exercise identifiers just generated
    id_file = open(id_filename, "r")
    dynamic_exercises = [f.strip() for f in id_file.readlines() if not f.isspace()]

    # Spawn a new process running a local html.server
    import subprocess
    import random
    # Try a standard port and if it fails, try a random port
    port = 8888
    looking_for_port = True
    numAttempt = 0
    maxAttempts = 10  # In case failure is not due to blocked ports.
    while looking_for_port and numAttempt < maxAttempts:
        try:
            numAttempt = numAttempt + 1
            log.info(f"Opening subprocess http.server with port={port}")
            # -u so that stdout and stderr are not cached
            server = subprocess.Popen(["python", "-u", "-m", "http.server", f"{port}", "-d", tmp_dir], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            # Check if terminated. Allow 1 second to start-up.
            try:
                result = server.wait(1)
                log.debug(f"Server startup failed")
                port = random.randint(49152, 65535)
                log.debug(f"Trying port {port} instead")
            # The exception is success because process did not terminate.
            except subprocess.TimeoutExpired:
                looking_for_port = False
        except OSError:
            # Not sure if this will ever trigger b/c Python itself should start
            log.debug(f"Subprocess to open http.server failed")
            port = random.randint(49152, 65535)
            log.debug(f"Trying port {port} instead.\n")
    if numAttempt >= maxAttempts:
        log.error("Unable to open http.server for interactive previews")

    # filenames lead to placement in current working directory
    # so change to temporary directory, and copy out
    # TODO: just write to "dest_dir"?
    owd = os.getcwd()
    os.chdir(tmp_dir)

    # event loop and copy, terminating server process even if interrupted
    try:
        log.debug("Using http.server subprocess {}".format(server.pid))
        baseurl = "http://localhost:{}".format(port)
        asyncio.get_event_loop().run_until_complete(extract_substitutions(dynamic_exercises, baseurl, dyn_subs_file))
    finally:
        # close the server and report (debug) results
        log.info("Closing http.server subprocess")
        server.kill()
        log.debug("Log data from http.server:")
        server_output = server.stderr.read()
        for line in server_output.split("\n"):
            log.debug(line)

    # restore working directory
    os.chdir(owd)


################################
#
#  WeBWorK Extraction Processing
#
################################


def webwork_to_xml(
    xml_source, pub_file, stringparams, xmlid_root, abort_early, server_params, dest_dir
):
    import urllib.parse  # urlparse()
    import base64  # b64encode()
    import copy
    import tarfile

    # external module, often forgotten
    # at least on Mac installations, requests module is not standard
    try:
        import requests  # webwork server
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("requests"))

    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    log.info(
        "string parameters passed to extraction stylesheet: {}".format(stringparams)
    )

    # Either we have a "generated" directory, or we must assume placing everything in dest_dir
    generated_dir, _ = get_managed_directories(xml_source, pub_file)
    if generated_dir:
        ww_reps_dir = os.path.join(generated_dir, "webwork")
        ww_images_dir = os.path.join(ww_reps_dir, "images")
    else:
        msg = "".join(
            [
                "a publisher file specifying /publication/source/directories/@generated ",
                "is not in use. WeBWorK representations will be in {}",
            ]
        )
        log.warning(msg.format(dest_dir))
        ww_reps_dir = dest_dir
        # Below is not a good choice, but here for backwards compatibility
        ww_images_dir = dest_dir

    if not (os.path.isdir(ww_reps_dir)):
        os.mkdir(ww_reps_dir)
    if not (os.path.isdir(ww_images_dir)):
        os.mkdir(ww_images_dir)
    ww_reps_file = os.path.join(ww_reps_dir, "webwork-representations.xml")

    # execute XSL extraction to get back six dictionaries
    # where the keys are the unique-id for the problems
    # origin, copy, seed, source, pghuman, pgdense
    # also get the localization as a string
    # The XSL gets the problems in document order, and the
    # Python dictionaries (v3.5+?) will maintain the order
    # in which the problems are added, which aids in debugging
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-pg.xsl")

    # Build dictionaries and localization string into a scratch directory/file
    tmp_dir = get_temporary_directory()
    ww_filename = os.path.join(tmp_dir, "webwork-dicts.xml")
    log.debug("WeBWorK dictionaries temporarily in {}".format(ww_filename))
    xsltproc(extraction_xslt, xml_source, ww_filename, None, stringparams)
    # build necessary variables by reading xml with lxml
    ww_xml = ET.parse(ww_filename).getroot()
    localization = ww_xml.find("localization").text
    if ww_xml.find("server-params-pub").find("ww-domain") is not None:
        server_params_pub = {
            "ww_domain": ww_xml.find("server-params-pub").find("ww-domain").text,
            "courseID": ww_xml.find("server-params-pub").find("course-id").text,
            "userID": ww_xml.find("server-params-pub").find("user-id").text,
            "password": ww_xml.find("server-params-pub").find("password").text,
            "course_password": ww_xml.find("server-params-pub").find("course-password").text,
        }
    else:
        server_params_pub = {}
    origin = {}
    copiedfrom = {}
    seed = {}
    source = {}
    pghuman = {}
    pgdense = {
        "hint_no_solution_no": {},
        "hint_no_solution_yes": {},
        "hint_yes_solution_no": {},
        "hint_yes_solution_yes": {},
    }
    for ele in ww_xml.iter("problem"):
        origin[ele.get("id")] = ele.get("origin")
        seed[ele.get("id")] = ele.get("seed")
        if ele.get("source") is not None:
            source[ele.get("id")] = ele.get("source")
        else:
            if ele.get("copied-from") is not None:
                copiedfrom[ele.get("id")] = ele.get("copied-from")
            pghuman[ele.get("id")] = ele.find("pghuman").text
            for dense in ele.iter("pgdense"):
                if dense.get("hint")=="yes" and dense.get("solution")=="yes":
                    pgdense[ele.get("id")] = dense.text
                    pgdense["hint_yes_solution_yes"][ele.get("id")] = dense.text
                elif dense.get("hint")=="yes" and dense.get("solution")=="no":
                    pgdense["hint_yes_solution_no"][ele.get("id")] = dense.text
                elif dense.get("hint")=="no" and dense.get("solution")=="yes":
                    pgdense["hint_no_solution_yes"][ele.get("id")] = dense.text
                elif dense.get("hint")=="no" and dense.get("solution")=="no":
                    pgdense["hint_no_solution_no"][ele.get("id")] = dense.text

    # ideally, pub_file is in use, in which case server_params_pub is nonempty.
    # if no pub_file in use, rely on server_params.
    # if both present, use server_params_pub and give warning
    # if neither in use give warning and fail
    if not(server_params_pub) and server_params is None:
        raise ValueError("No WeBWorK server declared. Declare WeBWorK server in publication/webwork/@server.")
    elif not(server_params_pub):
        # We rely on the argument server_params
        # This is deprecated in favor of using a publication file
        log.warning("WeBWorK server declared using -s argument.\n" +
              "              Please consider using a publication file with publication/webwork/@server instead.")
        server_params = server_params.strip()
        if (server_params.startswith("(") and server_params.endswith(")")):
            server_params = server_params.strip("()")
            split_server_params = server_params.split(",")
            ww_domain = sanitize_url(split_server_params[0])
            courseID = sanitize_alpha_num_underscore(split_server_params[1])
            userID = sanitize_alpha_num_underscore(split_server_params[2])
            password = sanitize_alpha_num_underscore(split_server_params[3])
            course_password = sanitize_alpha_num_underscore(split_server_params[4])
        else:
            ww_domain       = sanitize_url(server_params)
            courseID        = "anonymous"
            userID          = "anonymous"
            password        = "anonymous"
            course_password = "anonymous"
    else:
        # Now we know server_params_pub is nonepty
        # Use it, and warn if server_params argument is also present
        if server_params is not None:
            log.warning("Publication file in use and -s argument passed for WeBWorK server.\n"
                  + "              -s argument will be ignored.\n"
                  + "              Using publication/webwork values (or defaults) instead.")
        ww_domain       = sanitize_url(server_params_pub["ww_domain"])
        courseID        = server_params_pub["courseID"]
        userID          = server_params_pub["userID"]
        password        = server_params_pub["password"]
        course_password = server_params_pub["course_password"]

    ww_domain_ww2 = ww_domain + "/webwork2/"
    ww_domain_path = ww_domain_ww2 + "html2xml"

    # Establish WeBWorK version

    # First try to identify the WW version according to what a response hash says it is.
    # This should work for 2.17 and beyond.
    try:
        params_for_version_determination = dict(
            problemSeed=1,
            displayMode='PTX',
            courseID=courseID,
            userID=userID,
            course_password=course_password,
            outputformat='raw'
        )
        version_determination_json = requests.get(url=ww_domain_path, params=params_for_version_determination, timeout=10).json()
        ww_version = ""
        if "ww_version" in version_determination_json:
            ww_version = version_determination_json["ww_version"]
            ww_version_match = re.search(
                r"((\d+)\.(\d+))", ww_version, re.I
            )
    except Exception as e:
        root_cause = str(e)
        msg = ("PTX:ERROR:   There was a problem contacting the WeBWorK server.\n")
        raise ValueError(msg.format(ww_domain_ww2) + root_cause)

    # Now if that failed, try to infer the version from what is printed on the landing page.
    if ww_version == "":
        try:
            landing_page = requests.get(ww_domain_ww2, timeout=10)
        except Exception as e:
            root_cause = str(e)
            msg = (
                "PTX:ERROR:   There was a problem contacting the WeBWorK server.\n"
                + "             Is there a WeBWorK landing page at {}?\n"
            )
            raise ValueError(msg.format(ww_domain_ww2) + root_cause)
        landing_page_text = landing_page.text

        ww_version_match = re.search(
            r"WW.VERSION:\s*((\d+)\.(\d+))", landing_page_text, re.I
        )

    try:
        ww_version = ww_version_match.group(1)
        ww_major_version = int(ww_version_match.group(2))
        ww_minor_version = int(ww_version_match.group(3))
    except AttributeError as e:
        root_cause = str(e)
        msg = (
            "PTX:ERROR:   PreTeXt was unable to discern the version of the WeBWorK server.\n"
            + "                         Is there a WeBWorK landing page at {}?\n"
            + "                         And does it display the WeBWorK version?\n"
        )
        raise ValueError(msg.format(ww_domain_ww2))

    if ww_major_version != 2 or ww_minor_version < 14:
        msg = (
            "PTX:ERROR:   PreTeXt supports WeBWorK 2.14 and later, and it appears you are attempting to use version: {}\n"
            + "                         Server: {}\n"
        )
        raise ValueError(msg.format(ww_version, ww_domain))

    ww_reps_version = ""
    if ww_major_version == 2 and (ww_minor_version == 14 or ww_minor_version == 15):
        # version 1: live problems are embedded in an iframe
        ww_reps_version = "1"
    elif ww_major_version == 2 and ww_minor_version >= 16:
        # version 1: live problems are injected into a div using javascript
        ww_reps_version = "2"

    # using a "Session()" will pool connection information
    # since we always hit the same server, this should increase performance
    session = requests.Session()

    # begin XML tree
    # then we loop through all problems, appending children
    NSMAP = {"xml": "http://www.w3.org/XML/1998/namespace"}
    XML = "http://www.w3.org/XML/1998/namespace"
    webwork_representations = ET.Element("webwork-representations", nsmap=NSMAP)
    # Choose one of the dictionaries to take its keys as what to loop through
    for problem in origin:

        # It is more convenient to identify server problems by file path,
        # and PTX problems by internal ID
        problem_identifier = problem if (origin[problem] == "ptx") else source[problem]

        if origin[problem] == "server":
            msg = "building representations of server-based WeBWorK problem"
        elif origin[problem] == "ptx":
            msg = "building representations of PTX-authored WeBWorK problem"
        else:
            raise ValueError(
                "PTX:ERROR: problem origin should be 'server' or 'ptx', not '{}'".format(
                    origin[problem]
                )
            )
        log.info(msg)

        # If and only if the server is version 2.16, we adjust PG code to use PGtikz.pl
        # instead of PGlateximage.pl
        if ww_major_version == 2 and ww_minor_version == 16 and origin[problem] == "ptx":
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
        if origin[problem] == "ptx":
            embed_problem = re.sub(r'(\$refreshCachedImages)(?![\w\d])', r'\1Inert', pgdense[problem])

        # make base64 for PTX problems
        if origin[problem] == "ptx":
            if ww_reps_version == "2":
                pgbase64 = base64.b64encode(bytes(pgdense[problem], "utf-8")).decode(
                    "utf-8"
                )
                embed_problem_base64 = base64.b64encode(bytes(embed_problem, "utf-8")).decode(
                    "utf-8"
                )
            elif ww_reps_version == "1":
                pgbase64 = {}
                for hint_sol in [
                    "hint_yes_solution_yes",
                    "hint_yes_solution_no",
                    "hint_no_solution_yes",
                    "hint_no_solution_no",
                ]:
                    pgbase64[hint_sol] = base64.b64encode(
                        bytes(pgdense[hint_sol][problem], "utf-8")
                    )

        # Construct URL to get static version from server
        # WW server can react to a
        #   URL of a problem stored there already
        #   or a base64 encoding of a problem
        # server_params is tuple rather than dictionary to enforce consistent order in url parameters
        if ww_reps_version == "2":
            server_params_source = (
                ("sourceFilePath", source[problem])
                if origin[problem] == "server"
                else ("problemSource", pgbase64)
            )
        elif ww_reps_version == "1":
            server_params_source = (
                ("sourceFilePath", source[problem])
                if origin[problem] == "server"
                else ("problemSource", pgbase64["hint_yes_solution_yes"])
            )

        server_params = (
            ("answersSubmitted", "0"),
            ("showSolutions", "1"),
            ("showHints", "1"),
            ("displayMode", "PTX"),
            ("courseID", courseID),
            ("userID", userID),
            ("password", password),
            ("course_password", course_password),
            ("outputformat", "ptx"),
            server_params_source,
            ("problemSeed", seed[problem]),
            ("problemUUID", problem),
        )

        msg = "sending {} to server to save in {}: origin is '{}'"
        log.info(msg.format(problem, ww_reps_file, origin[problem]))
        if origin[problem] == "server":
            log.debug(
                "server-to-ptx: {}\n{}\n{}\n{}".format(
                    problem, ww_domain_path, source[problem], ww_reps_file
                )
            )
        elif origin[problem] == "ptx":
            if ww_reps_version == "2":
                log.debug(
                    "server-to-ptx: {}\n{}\n{}\n{}".format(
                        problem, ww_domain_path, pgdense[problem], ww_reps_file
                    )
                )
            elif ww_reps_version == "1":
                log.debug(
                    "server-to-ptx: {}\n{}\n{}\n{}".format(
                        problem,
                        ww_domain_path,
                        pgdense["hint_yes_solution_yes"][problem],
                        ww_reps_file,
                    )
                )

        # Ready, go out on the wire
        try:
            response = session.get(ww_domain_path, params=server_params)
            log.debug("Getting problem response from: " + response.url)

        except requests.exceptions.RequestException as e:
            root_cause = str(e)
            msg = "PTX:ERROR: there was a problem collecting a problem,\n Server: {}\nRequest Parameters: {}\n"
            raise ValueError(msg.format(ww_domain_path, server_params) + root_cause)

        # Check for errors with PG processing
        # Get booleans signaling badness: file_empty, no_compile, bad_xml, no_statement
        file_empty = "ERROR:  This problem file was empty!" in response.text

        no_compile = (
            "ERROR caught by Translator while processing" in response.text
        )

        bad_xml = False
        try:
            response_root = ET.fromstring(bytes(response.text, encoding='utf-8'))
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
                if (origin[problem] == "ptx")
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
                debugging_help = response.text
                if origin[problem] == "ptx" and no_compile:
                    debugging_help += "\n" + pghuman[problem]
                raise ValueError(
                    badness_msg.format(
                        problem_identifier, seed[problem], debugging_help
                    )
                )

        # Now a block where we edit the text from the response before using it to build XML
        # First some special handling for verbatim in answers.
        # Then change targets of img (while downloading the original target as an image file)

        # When a PG Math Object is a text string that has to be rendered in a math environment,
        # depending on the string's content and the version of WeBWorK, it can come back as:

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

        verbatim_split = re.split(
            r"(\\verb\x85.*?\x85|\\verb\x1F.*?\x1F|\\verb\r.*?\r)", response.text
        )
        response_text = ""
        for item in verbatim_split:
            if re.match(r"^\\verb(\x85|\x1F|\r).*?\1$", item):
                (original_delimiter, verbatim_content) = re.search(
                    r"\\verb(\x85|\x1F|\r)(.*?)\1", item
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
        graphics_pattern = re.compile(r'<image.*?source="([^"]*)"')

        # replace filenames, download images with new filenames
        count = 0
        # ww_image_url will be the URL to an image file used by the problem on the ww server
        for match in re.finditer(graphics_pattern, response_text):
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
                image_url = urllib.parse.urljoin(ww_domain, ww_image_full_path)
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
            # download actual image files
            # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests
            try:
                image_response = session.get(image_url)
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

        # Use "webwork-reps" as parent tag for the various representations of a problem
        webwork_reps = ET.SubElement(webwork_representations, "webwork-reps")
        webwork_reps.set("version", ww_reps_version)
        webwork_reps.set("ww_major_version", str(ww_major_version))
        webwork_reps.set("ww_minor_version", str(ww_minor_version))
        webwork_reps.set("{%s}id" % (XML), "extracted-" + problem)
        webwork_reps.set("ww-id", problem)
        static = ET.SubElement(webwork_reps, "static")
        static.set("seed", seed[problem])
        if origin[problem] == "server":
            static.set("source", source[problem])

        # If there is "badness"...
        # Build 'shell' problems to indicate failures
        if badness:
            print(badness_msg.format(problem_identifier, seed[problem], badness_tip))
            static.set("failure", badness_type)
            statement = ET.SubElement(static, "statement")
            p = ET.SubElement(statement, "p")
            p.text = badness_msg.format(problem_identifier, seed[problem], badness_tip)
            continue

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

        # Add elements for interactivity
        if ww_reps_version == "2":
            # Add server-data element with attribute data for rendering a problem
            source_key = (
                "problemSource"
                if (badness or origin[problem] == "ptx")
                else "sourceFilePath"
            )
            if badness:
                source_value = badness_base64
            else:
                if origin[problem] == "server":
                    source_value = source[problem]
                else:
                    source_value = embed_problem_base64

            server_data = ET.SubElement(webwork_reps, "server-data")
            server_data.set(source_key, source_value)
            server_data.set("domain", ww_domain)
            server_data.set("course-id", courseID)
            server_data.set("user-id", userID)
            server_data.set("course-password", course_password)
            server_data.set("language", localization)

        elif ww_reps_version == "1":
            # Add server-url elements for putting into the @src of an iframe
            for hint in ["yes", "no"]:
                for solution in ["yes", "no"]:
                    hintsol = "hint_" + hint + "_solution_" + solution
                    source_selector = (
                        "problemSource="
                        if (badness or origin[problem] == "ptx")
                        else "sourceFilePath="
                    )
                    if badness:
                        source_value = urllib.parse.quote(badness_base64)
                    else:
                        if origin[problem] == "server":
                            source_value = source[problem]
                        else:
                            source_value = urllib.parse.quote_plus(pgbase64[hintsol])
                    source_query = source_selector + source_value

                    server_url = ET.SubElement(webwork_reps, "server-url")
                    server_url.set("hint", hint)
                    server_url.set("solution", solution)
                    server_url.set("domain", ww_domain)
                    url_shell = "{}?courseID={}&userID={}&password={}&course_password={}&answersSubmitted=0&displayMode=MathJax&outputformat=simple&language={}&problemSeed={}&{}"
                    server_url.text = url_shell.format(
                        ww_domain_path,
                        courseID,
                        userID,
                        password,
                        course_password,
                        localization,
                        seed[problem],
                        source_query,
                    )

        # Add PG for PTX-authored problems
        # Empty tag with @source for server problems
        pg = ET.SubElement(webwork_reps, "pg")
        try:
            pg.set("copied-from", copiedfrom[problem])
        except Exception:
            pass

        if origin[problem] == "ptx":
            if badness:
                pg_shell = "DOCUMENT();\nloadMacros('PGstandard.pl','PGML.pl','PGcourse.pl');\nTEXT(beginproblem());\nBEGIN_PGML\n{}END_PGML\nENDDOCUMENT();"
                formatted_pg = pg_shell.format(
                    badness_msg.format(problem_identifier, seed[problem], badness_tip)
                )
            else:
                formatted_pg = pghuman[problem]
            # opportunity to cut out extra blank lines
            formatted_pg = re.sub(
                re.compile(r"(\n *\n)( *\n)*", re.MULTILINE), r"\n\n", formatted_pg
            )
            pg.text = ET.CDATA("\n" + formatted_pg)
        elif origin[problem] == "server":
            pg.set("source", source[problem])

    # write to file
    include_file_name = os.path.join(ww_reps_file)
    try:
        with open(include_file_name, "wb") as include_file:
            include_file.write(
                ET.tostring(
                    webwork_representations,
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
    session.close()


################################
#
#  WeBWorK Problem Sets
#
################################


def webwork_sets(xml_source, pub_file, stringparams, dest_dir, tgz):

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    if pub_file:
        stringparams["publisher"] = pub_file
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "pretext-ww-problem-sets.xsl")
    tmp_dir = get_temporary_directory()
    xsltproc(extraction_xslt, xml_source, None, output_dir=tmp_dir, stringparams=stringparams)
    # We don't explicitly know the name of the folder that has all of the sets
    # But it is the only thing in the tmp_dir
    folder_name = os.listdir(tmp_dir)[0]
    folder = os.path.join(tmp_dir, folder_name)
    macros_folder = os.path.join(folder, 'macros')
    os.mkdir(macros_folder)
    pg_macros(xml_source, pub_file, stringparams, macros_folder)
    if tgz:
        archive_file = os.path.join(tmp_dir, folder_name + ".tgz")
        targz(archive_file, folder)
        shutil.copy2(archive_file, dest_dir)
    else:
        # with multiple files, we need to copy a tree
        # see comments at  copy_build_directory()
        # before replacing with  shutil.copytree()
        copy_build_directory(folder, os.path.join(dest_dir,folder_name))


################################
#
#  WeBWorK PG Macro Library
#
################################


def pg_macros(xml_source, pub_file, stringparams, dest_dir):

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    if pub_file:
        stringparams["publisher"] = pub_file
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "support", "pretext-pg-macros.xsl")
    xsltproc(extraction_xslt, xml_source, None, output_dir=dest_dir, stringparams=stringparams)


##############################
#
#  You Tube thumbnail scraping
#
##############################


def youtube_thumbnail(xml_source, pub_file, stringparams, xmlid_root, dest_dir):

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    try:
        import requests  # YouTube server
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("requests"))

    log.info(
        "downloading YouTube thumbnails from {} for placement in {}".format(
            xml_source, dest_dir
        )
    )
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-youtube.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = get_temporary_directory()
    id_filename = os.path.join(tmp_dir, "youtube-ids.txt")
    log.debug("YouTube id list temporarily in {}".format(id_filename))
    xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)
    # "run" an assignment for the list of triples of strings
    with open(id_filename, "r") as id_file:
        # read lines, but only lines that are comma delimited
        thumbs = [t.strip() for t in id_file.readlines() if "," in t]

    for thumb in thumbs:
        thumb_pair = thumb.split(",")
        url = "http://i.ytimg.com/vi/{}/default.jpg".format(thumb_pair[0])
        path = os.path.join(dest_dir, thumb_pair[1] + ".jpg")
        log.info("downloading {} as {}...".format(url, path))
        # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests/13137873
        # removed some settings wrapper from around the URL, otherwise verbatim
        r = requests.get(url, stream=True, timeout=10)
        if r.status_code == 200:
            with open(path, "wb") as f:
                r.raw.decode_content = True
                shutil.copyfileobj(r.raw, f)
        else:
            msg = "PTX:ERROR: download returned a bad status code ({}), perhaps try {} manually?"
            raise OSError(msg.format(r.status_code, url))
    log.info("YouTube thumbnail download complete")


##########################
#
#  Video Play Button Image
#
##########################

def play_button(dest_dir):
    '''Copy generic static video image to a directory'''

    ptx_xsl_dir = get_ptx_xsl_path()
    play_button_provided_image = os.path.join(ptx_xsl_dir, "support", "play-button", "play-button.png")
    log.info('Generating generic video preview, aka "play button" into {}'.format(dest_dir))
    shutil.copy2(play_button_provided_image, dest_dir)


########################
#
#  QR Code manufacturing
#
########################


def qrcode(xml_source, pub_file, stringparams, xmlid_root, dest_dir):

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # Establish whether there is an image from pub file
    has_image = False
    try:
        pub_vars = get_publisher_variable_report(xml_source, pub_file, stringparams)
        image = get_publisher_variable(pub_vars, 'qrcode-image')
        _, external_dir = get_managed_directories(xml_source, pub_file)
        image_path = os.path.join(external_dir, image)
        if (image != '' and os.path.exists(image_path)):
            has_image = True
    except:
        pass

    # https://pypi.org/project/qrcode/
    try:
        import qrcode  # YouTube server
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("qrcode"))

    import qrcode.image.styledpil

    log.info(
        "manufacturing QR codes from {} for placement in {}".format(
            xml_source, dest_dir
        )
    )
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-qrcode.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = get_temporary_directory()
    id_filename = os.path.join(tmp_dir, "qrcode-ids.txt")
    log.debug("QR code id list temporarily in {}".format(id_filename))
    xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)
    # "run" an assignment for the list of triples of strings
    with open(id_filename, "r") as id_file:
        interactives = id_file.readlines()

    for inter in interactives:
        # separator is a space, since a comma can be in a YouTube playlist
        # no argument here means contiguous whitespace - should always
        # be a single space coming from the extraction routine.
        # NB: an audio or video file provided by an author with a URL to
        # some external location, with a space in it, will be a problem here.
        # The URL should be percent-encoded so the space is not problematic.
        inter_pair = inter.split()
        url = inter_pair[0]
        path = os.path.join(dest_dir, inter_pair[1] + ".png")
        log.info('creating URL with content "{}" as {}...'.format(url, path))
        # Using more elaborate (class) calls to simply get a zero border,
        # rather than cropping (ala https://stackoverflow.com/questions/9870876)
        # Simple version: qr_image = qrcode.make(url), has border
        if has_image:
            # error correction up to 25%
            error_correction = qrcode.constants.ERROR_CORRECT_Q
        else:
            # error correction up to 7%
            error_correction = qrcode.constants.ERROR_CORRECT_L
        qr = qrcode.QRCode(version=None,
                           error_correction=error_correction,
                           box_size=10,
                           border=0
                           )
        qr.add_data(url)
        if has_image:
            qr_image = qr.make_image(image_factory=qrcode.image.styledpil.StyledPilImage, embeded_image_path=image_path)
        else:
            qr_image = qr.make_image(fill_color="black", back_color="white")
        # Now save as a PNG
        qr_image.save(path)
    log.info("QR code creation complete")


#####################################
#
#  Mermaid images
#
#####################################

def mermaid_images(
    xml_source, pub_file, stringparams, xmlid_root, dest_dir
):
    msg = 'converting Mermaid diagrams from {} to png graphics for placement in {}'
    log.info(msg.format(xml_source, dest_dir))

    tmp_dir = get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-mermaid.xsl")

    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root

    log.info("extracting Mermaid diagrams from {}".format(xml_source))
    log.info(
        "string parameters passed to extraction stylesheet: {}".format(stringparams)
    )
    #generate mmd files with markdown to be converted to png
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)

    pub_vars = get_publisher_variable_report(xml_source, pub_file, stringparams)
    mermaid_theme = get_publisher_variable(pub_vars, 'mermaid-theme')

    import glob
    # Resulting *.mmd files are in tmp_dir, switch there to work
    with working_directory(tmp_dir):
        mmd_executable_cmd = get_executable_cmd("mermaid")
        log.debug("Mermaid executable command: {}".format(mmd_executable_cmd))
        for mmddiagram in glob.glob(os.path.join(tmp_dir, "*.mmd")):
            filebase, _ = os.path.splitext(mmddiagram)
            versions = [
                {"name":"-color", "opts":["-s", "4", "-t", mermaid_theme]},
                {"name":"-bw", "opts":["-s", "4", "-t", "neutral"]}
            ]
            for version in versions:
                mmdout = "{}.{}".format(filebase + version['name'], 'png')
                mmd_cmd = mmd_executable_cmd + ["-i", mmddiagram, "-o", mmdout] + version['opts']
                log.debug("mermaid conversion {}".format(" ".join(mmd_cmd)))
                subprocess.call(mmd_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
                if os.path.exists(mmdout):
                    shutil.copy2(mmdout, dest_dir)
                else:
                    msg = [
                        "the Mermaid output {} was not built".format(mmdout),
                    ]
                    log.warning("\n".join(msg))

#####################################
#
#  Interactive preview screenshotting
#
#####################################


def preview_images(xml_source, pub_file, stringparams, xmlid_root, dest_dir):
    import asyncio  # get_event_loop()

    # external module, often forgotten
    # imported here, used only in interior
    # routine to launch browser
    try:
        import playwright.async_api  # launch()
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("playwright"))

    # Interior asynchronous routine to manage the Chromium headless browser.
    # Use the same page instance for the generation of all interactive previews
    async def generate_previews(interactives, baseurl, dest_dir):

        # interactives:  list containing the interactive hash/fragment ids [1:]
        # baseurl:       local server's base url (includes local port)
        # dest_dir:      folder where images are saved

        # Open playwright's asynchronous api to load a browser and page
        async with playwright.async_api.async_playwright() as pw:
            browser = await pw.chromium.launch()
            page = await browser.new_page()
            # First index contains original baseurl of hosted site (not used)
            for preview_fragment in interactives:
                # loaded page url containing interactive
                input_page = baseurl + "/" + preview_fragment + ".html"
                # filename of saved preview image
                filename = preview_fragment + "-preview.png"

                # the "standalone" page has one "iframe" known by HTML id "preview_fragment"
                xpath = "//iframe[@id='{}'][1]".format(preview_fragment)

                # progress report
                msg = 'automatic screenshot of interactive with identifier "{}" on page {} to file {}'
                log.info(msg.format(preview_fragment, input_page, filename))

                # goto page and wait for content to load
                await page.goto(input_page, wait_until='domcontentloaded')
                # wait again, 5 seconds, for more than just splash screens, etc
                await page.wait_for_timeout(5000)
                # list of locations, need first (and only) one
                elt = page.locator(xpath)
                await elt.screenshot(path=filename, scale="css")

                # copy
                shutil.copy2(filename, dest_dir)
            await browser.close()

    # Start http server in a thread
    def start_server():
        '''
        Starts a simple http.server on port 8888 if available, or finds a random port.  Returns the port and the server object.
        '''
        try:
            import http.server
            import socketserver
            import threading
            import random
        except ImportError:
            raise ImportError("http.server, socketserver, threading, random")

        # Subclass SimpleHTTPRequestHandler to send messages to log.debug:
        class MyHandler(http.server.SimpleHTTPRequestHandler):
            def log_message(self, format, *args):
                log.debug("http.server: " + format % args)
                return
        # Find a port to use
        port = 8888
        attempts = 0
        max_attempts = 10
        while attempts < max_attempts:
            try:
                log.debug("Trying http.server on port {}".format(port))
                server = socketserver.TCPServer(("localhost", port), MyHandler)
                thread = threading.Thread(target=server.serve_forever)
                thread.start()
                log.debug(f"Started http.server on port {port}")
                return port, server
            except Exception as e:
                log.debug("http.server error: port {} in use; (error {})".format(port, e))
                port = random.randint(49152, 65535)
                attempts += 1
        else:
            raise OSError("Unable to open http.server for interactive previews")

    def stop_server(server):
        try:
            log.debug("Stopping http.server")
            server.shutdown()
            log.debug("http.server shutdown successful")
        except Exception as e:
            log.warning("http.server shutdown failed; perhaps it wasn't running? error: {}".format(e))

    # Main content of preview_images function:
    log.info(
        "using playwright package to create previews for interactives from {} for placement in {}".format(
            xml_source, dest_dir
        )
    )

    # Identify interactives that will be processed
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-interactive.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = get_temporary_directory()
    id_filename = os.path.join(tmp_dir, "interactives-ids.txt")
    log.debug("Interactives id list temporarily in {}".format(id_filename))
    log.debug("Interactives html files temporarily in {}".format(tmp_dir))
    # This next call may be unique in that the stylesheet outputs the
    # list of ids *and* produce a pile of files (the "standalone") pages
    xsltproc(extraction_xslt, xml_source, id_filename, tmp_dir, stringparams)
    # read the list of interactive identifiers just generated
    with open(id_filename, "r") as id_file:
        interactives = [f.strip() for f in id_file.readlines() if not f.isspace()]

    # Copy in external resources (e.g., js code)
    _, external_abs = get_managed_directories(xml_source, pub_file)
    copy_managed_directories(tmp_dir, external_abs=external_abs)
    # place JS in scratch directory
    copy_html_js(tmp_dir)

    # filenames lead to placement in current working directory
    # so change to temporary directory, and copy out
    # TODO: just write to "dest_dir"?
    with working_directory(tmp_dir):
        # event loop and copy, terminating server process even if interrupted
        try:
            log.debug("Starting event loop for playwright, after starting server")
            port, server = start_server()
            baseurl = "http://localhost:{}".format(port)
            asyncio.get_event_loop().run_until_complete(
                generate_previews(interactives, baseurl, dest_dir)
            )
        finally:
            # close the server
            log.info("Closing http.server thread")
            if server:
                stop_server(server)


############
# All Images
############


def all_images(xml, pub_file, stringparams, xmlid_root):
    """All images, in all necessary formats, in subdirectories, for production of any project"""

    # parse source, no harm to assume
    # xinclude modularization is necessary
    # NB: see general  "xsltproc()"  for construction of a HUGE parser
    src_tree = ET.parse(xml)
    src_tree.xinclude()

    # explore source for various PreTeXt elements needing assistance
    # no element => empty list => boolean is False
    has_latex_image = bool(src_tree.xpath("/pretext/*[not(docinfo)]//latex-image"))
    has_asymptote = bool(src_tree.xpath("/pretext/*[not(docinfo)]//asymptote"))
    has_sageplot = bool(src_tree.xpath("/pretext/*[not(docinfo)]//sageplot"))
    has_youtube = bool(src_tree.xpath("/pretext/*[not(docinfo)]//video[@youtube]"))
    has_preview = bool(
        src_tree.xpath("/pretext/*[not(docinfo)]//interactive[not(@preview)]")
    )

    # debugging comment/uncomment or True/False
    # has_latex_image = False
    # has_asymptote = False
    # has_sageplot = False
    # has_youtube = False
    # has_preview = False

    # get the target output directory from the publisher file
    # this is *required* so fail if pieces are missing
    if not (pub_file):
        msg = " ".join(
            [
                "creating all images requires a directory specification",
                "in a publisher file, and no publisher file has been given",
            ]
        )
        raise ValueError(msg)
    generated_dir, _ = get_managed_directories(xml, pub_file)

    # correct attribute and not a directory gets caught earlier
    # but could have publisher file and bad elements/attributes
    if not (generated_dir):
        msg = " ".join(
            [
                "creating all images requires a directory specified in the",
                "publisher file in the attribute /publication/source/directories/@generated",
            ]
        )
        raise ValueError(msg)

    # first stanza has code comments, and subsequent follow this
    # model so only comments are for important distinctions

    # latex-image
    #
    if has_latex_image:
        # empty last part implies directory separator
        dest_dir = os.path.join(generated_dir, "latex-image", "")
        # make directory if not already present
        if not (os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        latex_image_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "pdf", True, None)
        latex_image_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "svg", True, None)

    # Asymptote
    #
    if has_asymptote:
        dest_dir = os.path.join(generated_dir, "asymptote", "")
        if not (os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        asymptote_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "pdf", None)
        asymptote_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "html", None)

    # Sage plots
    #
    if has_sageplot:
        dest_dir = os.path.join(generated_dir, "sageplot", "")
        if not (os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        # for 3D images might produce a single PNG instead of an SVG and a PDF
        # conversions look for this PNG as a fallback absent SVG or PDF
        sage_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "pdf", None)
        sage_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "svg", None)

    # YouTube previews
    #
    if has_youtube:
        dest_dir = os.path.join(generated_dir, "youtube", "")
        if not (os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        # no format, they are what they are (*.jpg)
        youtube_thumbnail(xml, pub_file, stringparams, xmlid_root, dest_dir)

    # Previews (headless screenshots)
    #
    if has_preview:
        dest_dir = os.path.join(generated_dir, "preview", "")
        if not (os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        # no format, they are what they are (*.png)
        preview_images(xml, pub_file, stringparams, xmlid_root, dest_dir)


#####################################
#
#  MyOpenMath static problem scraping
#
#####################################


def mom_static_problems(xml_source, pub_file, stringparams, xmlid_root, dest_dir):

    import urllib.parse
    import PIL.Image

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    try:
        import requests  # MyOpenMath server
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("requests"))

    log.info(
        "downloading MyOpenMath static problems from {} for placement in {}".format(
            xml_source, dest_dir
        )
    )
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-mom.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = get_temporary_directory()
    id_filename = os.path.join(tmp_dir, "mom-ids.txt")
    log.debug("MyOpenMath id list temporarily in {}".format(id_filename))
    xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)
    # prep regex for looking for images
    graphics_pattern = re.compile(r'<image(.*?)source="([^"]*)"')
    images_dir = os.path.join(dest_dir, 'images')
    if not (os.path.isdir(images_dir)):
        os.mkdir(images_dir)

    # "run" an assignment for the list of problem numbers
    with open(id_filename, "r") as id_file:
        # read lines, skipping blank lines
        problems = [p.strip() for p in id_file.readlines() if not p.isspace()]
    for problem in problems:
        url = "https://www.myopenmath.com/util/mbx.php?id={}".format(problem)
        path = os.path.join(dest_dir, "mom-{}.xml".format(problem))
        log.info("downloading MOM #{} to {}...".format(problem, path))

        # download question xml
        r = requests.get(url, timeout=10)
        with open(path, "w", encoding="utf-8") as f:
            # f.write(__xml_header.encode("utf-8"))
            f.write('<?xml version="1.0" encoding="utf-8"?>\n')
            if r.status_code == 200:
                problemcontent = r.text
                # add pi namespace
                problemcontent = problemcontent.replace('<myopenmath', '<myopenmath xmlns:pi="http://pretextbook.org/2020/pretext/internal"')
                # extract any images in content
                for match in re.finditer(graphics_pattern, problemcontent):
                    image_url = match.group(2)
                    image_url_parsed = urllib.parse.urlparse(image_url)
                    image_filename = os.path.basename(image_url_parsed.path)
                    imageloc = 'problems/images/' + image_filename
                    image_path = os.path.join(images_dir, image_filename)
                    # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests/13137873
                    # removed some settings wrapper from around the URL, otherwise verbatim
                    imageresp = requests.get(image_url, stream=True, timeout=10)
                    with open(image_path, "wb") as imagefile:
                        imageresp.raw.decode_content = True
                        shutil.copyfileobj(imageresp.raw, imagefile)
                    imgwidthtag = ''
                    try:
                        img = PIL.Image.open(image_path)
                        imgwidthtag = ' width="' + str(min(100,round(img.width/6))) + '%" '
                        img.close()
                    except Exception as e:
                        log.info("Unable to read image width of " + image_path)
                    # replace image source, using pi:
                    newtagstart = ('<image' + imgwidthtag + match.group(1) + 'pi:generated="' + imageloc + '"')
                    problemcontent = problemcontent.replace(match.group(0), newtagstart)

                f.write(problemcontent)
            else:
                msg = "PTX:ERROR: download returned a bad status code ({}), perhaps try {} manually?"
                raise OSError(msg.format(r.status_code, url))
    log.info("MyOpenMath static problem download complete")


#######################
# Conversion to Braille
#######################


def braille(xml_source, pub_file, stringparams, out_file, dest_dir, page_format):
    """Produce a complete document in BRF format ( = Braille ASCII, plus formatting control)"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # general message for this entire procedure
    log.info(
        "converting {} into BRF in {} combining UEB2 and Nemeth".format(
            xml_source, dest_dir
        )
    )

    # get chunk level from publisher file, start with sentinel
    # eventually passed to routine that splits up a BRF
    chunk_level = ''
    if pub_file:
        # parse publisher file, xinclude is conceivable
        # for multiple similar publisher files with common parts
        pub_tree = ET.parse(pub_file)
        pub_tree.xinclude()
        # "chunking" element => single-item list
        # no "chunking" element => empty list
        chunk_elt = pub_tree.xpath("/publication/common/chunking")
        if chunk_elt:
            # attribute dictionary
            attrs = chunk_elt[0].attrib
            # check for attribute @level
            if "level" in attrs:
                chunk_level = chunk_elt[0].attrib['level']
                # respected values are '0' and '1', as *strings*
                if chunk_level in ['0', '1']:
                    msg = 'braille chunking level (from publisher file) set to "{}"'
                    log.info(msg.format(chunk_level))
                else:
                    msg = 'braille chunking level in publisher file should be "0" or "1", not "{}".'
                    log.warning(msg.format(chunk_level))
                    chunk_level = ''
    # never set, or set to an improper value
    # latter will have issued a warning above
    if chunk_level == '':
        msg = 'braille chunking level was never elected properly in a publisher file, using default value, "0".'
        log.debug(msg)
        chunk_level = '0'

    # Temporarily neuter all of above
    log.warning("Any elective chunking is temporarily disabled")
    chunk_level = '0'

    # Build into a scratch directory
    tmp_dir = get_temporary_directory()
    log.debug("Braille manufacture in temporary directory: {}".format(tmp_dir))

    # use of  math_format is for consistency
    # with MathJax used to make EPUB
    math_format = "nemeth"
    math_representations = os.path.join(
        tmp_dir, "math-representations-{}.xml".format(math_format)
    )

    # ripping out LaTeX as math representations
    msg = "converting raw LaTeX from {} into clean {} format placed into {}"
    log.debug(msg.format(xml_source, math_format, math_representations))
    mathjax_latex(xml_source, pub_file, math_representations, None, math_format)

    # use XSL to make a simplified BRF-like XML version, "preprint"
    msg = "converting source ({}) and clean representations ({}) into preprint XML file ({})"
    stringparams["mathfile"] = math_representations.replace(os.sep, "/")
    # pass in the page format (for messages about graphics, etc.)
    stringparams["page-format"] = page_format
    if pub_file:
        stringparams["publisher"] = pub_file
    preprint = os.path.join(tmp_dir, "preprint.xml")
    braille_xslt = os.path.join(get_ptx_xsl_path(), "pretext-braille-preprint.xsl")
    xsltproc(braille_xslt, xml_source, preprint, tmp_dir, stringparams)

    # use Python to format simplified BRF as a real BRF
    import braille_format as braille

    # Build a BRF in the *temporary* directory: final or chunkable
    temp_brf = os.path.join(tmp_dir, "temporary.brf")
    # Python formatting call
    braille.parse_segments(preprint, temp_brf, page_format)

    # move out of temporary directory as final product(s)
    # chunk level is either '0' or '1' (exclusive "if" follow)
    if chunk_level == '0':
        # monolithic file
        final_brf = get_output_filename(xml_source, out_file, dest_dir, ".brf")
        shutil.copyfile(temp_brf, final_brf)
        log.info("Single BRF file deposited as {}".format(final_brf))
    if chunk_level == '1':
        # chunked into chapters
        # directory switch could be moved to split routine,
        # or it could be done in temporary directory and copied out
        with working_directory(dest_dir):
            _split_brf(temp_brf)
            log.info("BRF file chunked and deposited in {}".format(dest_dir))

############################
# Splitting braille chapters
############################

def _split_brf(filename):
    """Decompose a BRF file for a book into multiple files of chapters"""

    # Original author: Alexei Kolesnikov, 2022-12-30
    # Incorporation into pretext/pretext script: Rob Beezer, 2023-01-01

    # Comments from original version:
    # This is a script to split a long brf document
    # that contains many chapters into shorter brf files with a
    # single chapter each. The script expects that:
    #
    # * All the pages are numbered, the number is on the last line of
    # a page. Chapter titles are at the top of a page,
    # * There is a table of contents, with specific formatting described
    # in the comments below.
    # * The TOC begins with a centered title "3t5ts" ("contents", in BRF).
    # * The TOC ends with a centered chapter title on a new page, followed
    # by a blank line.
    # * Chapter line in TOC is indented 2 spaces.
    #
    # There are limited checks to let the user know when something goes wrong.


    # Utilities to convert BRF digits into ASCII digits
    brf_numbers = 'abcdefghij'
    num_numbers = '1234567890'
    brf_to_num_dict = dict(zip(brf_numbers,num_numbers))
    num_to_brf_dict = dict(zip(num_numbers,brf_numbers))

    def brf_to_num(string):
        out = ''
        for char in string:
            out += brf_to_num_dict[char]
        return(int(out))

    def num_to_brf(num):
        out = ''
        for char in str(num):
            out += num_to_brf_dict[char]
        return(out)

    # Wrapper class for chapter number, chapter page range,
    # chapter body
    class Chapter():
        def __init__(self,start_page_num, numbered_chapter,chapter_number):
            self.start_page = start_page_num
            self.numbered = numbered_chapter
            self.number = chapter_number
            # Placeholder values
            self.end_page = -1
            self.body = []
            self.front_matter = True

        def get_body(self,pages):
            for page_num in range(self.start_page,self.end_page):
                self.body += pages[page_num]

        def write_body(self):
        # The last two cases will be used if we want to split frontmatter or backmatter
            if self.numbered:
                out_filename = f"chapter_{self.number:02d}.brf"
            elif self.front_matter:
                out_filename = f"frontmatter_{self.number}.brf"
            else:
                out_filename = f"backmatter_{self.number}.brf"

            with open(out_filename,'w') as g:
                g.writelines(self.body)

    def is_chapter_name(line):
        # If a TOC line starts with two spaces followed by "," (capital letter sign) or "#"
        # then it is a chapter line
        if len(re.findall("^[ ]{2}[,|#]", line)) > 0:
            chapter_name = True
            if len(re.findall("^[ ]{2}#([a-j]+?) ", line)) > 0:
                numbered_chapter = True
                chapter_number = brf_to_num(re.findall("^[ ]{2}#([a-j]+?) ", line)[0])
            elif len(re.findall("^[ ]{2},\\*apt} #([a-j]+?) ", line)) > 0:
                numbered_chapter = True
                chapter_number = brf_to_num(re.findall("^[ ]{2},\\*apt} #([a-j]+?) ", line)[0])
            else:
                numbered_chapter = False
                chapter_number = -1
        else:
            chapter_name = False
            numbered_chapter = False
            chapter_number = -1
        # Return whether the TOC line starts a chapter name, whether it is a numbered chapter
        # and if yes, the chapter number (-1 if not a numbered chapter).
        return(chapter_name, numbered_chapter, chapter_number)

    # Input line, output a pair (page_num_found, page_num)
    # The first is a Boolean; True if the page number is found on the line,
    # the second is an integer
    #
    # Logic:
    #
    # * Are there lead-to characters?
    #
    # If yes, we win:
    # ,foo ''''''' #abc
    # abc is the page of chapter 'foo'; the number at the end of the lead-to characters is the page number
    #
    # If not, either the chapter name is too long to have lead-to characters, but the page number is there,
    # or the number will be on one of the next lines. There are two cases:
    #
    # If the line is short <40 characters, then definitely the number is on a line below
    #
    # If the line is not short, there are three subcases:
        # * If the line ends with " #abc #de", then the first one is the chapter
            # page number and the second is the TOC page number
        # * If the line ends with only one number precedeed by more than 3 spaces, then the chapter page
            # number is on a line below.
        # * If the line ends with only one number precedeed by no more than 3 spaces, then this is the
            # chapter page number.
    #
    # This does take into account some crazy chapter names:
    # "Key algebro-topological properties of 42  123"
    # Asked Michael Cantino more about spacing, he is saying the Liblouis spacing
    # we have is incorrect.

    def find_chapter_page_num(line):
        # Are there lead-to characters " ' "?
        if len(re.findall(" [']{2,35} #",line)) > 0:
            m = re.search("[']{2,35} #(.+?)[ |\n]",line)

            return(True, brf_to_num(m.group(1)))
        elif len(line) < 40:
            return(False, -1)
        elif len(re.findall(" #([a-j]+?)  #[a-j]+?$",line)) > 0:
            page = brf_to_num(re.findall(" #([a-j]+?)  #[a-j]+?$",line)[0])
            return(True, page)
        elif len(re.findall("[ ]{4,35}#[a-j]+?$",line)) > 0:
            return(False, -1)
        elif len(re.findall("[ ]{1,3}#([a-j]+?)$",line)) > 0:
            page = brf_to_num(re.findall("[ ]{1,3}#([a-j]+?)$",line)[0])
            return(True, page)
        else:
            raise ValueError(f"A weird long TOC line found:\n{line}")

    # The idea is to scan the BRF file for the word 'contents', or '3t5ts' in ASCII Braille
    # that appears on a short centered line. This would mark the beginning of the TOC.
    #
    # Then keep scanning the TOC until we get the next chapter.
    # Adding running heads will mess with this! So need to revisit when that happens.
    #
    # Will return three things: TOC, the entire front matter (ending with TOC), and the "body"
    # All are returned as lists of lines.

    def get_TOC(filename):
        f = open(filename,'r', encoding="latin-1")
        front_matter = [] # We want to keep the entire front matter up to and including TOC, it'll be one of the chunks
        TOC = [] # This will keep the TOC only
        text_body = [] # We want to get the text body, to be split into pages and then chapters

        is_contents = False

        while not is_contents:
            line = f.readline()
            front_matter.append(line)
            if line == '':
                raise ValueError("Reached the end of file while looking for Table of Contents")

            if len(re.findall("3t5ts",line)) > 0: # if a line contains the word 'contents', in the middle
                if re.search("3t5ts",line).start() > 10 and re.search("3t5ts",line).end() < 30:
                    is_contents = True
                    log.debug("TOC found")

        while is_contents:
            line = f.readline()

            if line == '':
                raise ValueError("Reached end of file while reading the Table of Contents")

            # Check if the line is likely centered and at the top of the page:
            trailing_spaces = 40 - len(line) - 2 # -2 for good luck
            pattern = f"\f[ ]{ {trailing_spaces} }"
            if len(re.findall(pattern,line)) == 0:
                # if not centered at the top, then add to the TOC list and move on
                TOC.append(line)
                front_matter.append(line)
            else:
                temp_line = line
                line = f.readline()

                if line == '\n':
                    # if the line after the centered one is empty,
                    # then we are likely at the start of the next chapter, so done with TOC
                    is_contents = False
                    log.debug(f"Found the end of TOC:\n{temp_line}")
                    text_body.append(temp_line)
                    text_body.append(line)
                else:
                    # False alarm
                    TOC.append(temp_line)
                    TOC.append(line)
                    front_matter.append(temp_line)
                    front_matter.append(line)

        while line != '':
            line = f.readline()
            text_body.append(line)

        f.close()
        return(TOC, front_matter, text_body)

    # Scan TOC, if a Chapter line is detected (two spaces followed by [,|#] -- anything else?),
    # then look for a page number of the chapter and append to the list of chapter pages

    def get_chapter_list(TOC):
        chapter_list = []
        line_number = 0

        while line_number < len(TOC) - 1:
            line = TOC[line_number]
            (chapter_name, numbered_chapter, chapter_number) = is_chapter_name(line)
            if chapter_name:
                (page_num_found, start_page_num) = find_chapter_page_num(line)
                while not page_num_found:
                    line_number += 1
                    if line_number == len(TOC)-1:
                        raise ValueError("Reached end of TOC while looking for the page number")

                    line = TOC[line_number]
                    (page_num_found, start_page_num) = find_chapter_page_num(line)

                chapter_list.append(Chapter(start_page_num, numbered_chapter,chapter_number))

            line_number += 1
        return(chapter_list)

    def split_body_into_pages(text_body):
    # text_body is a list of lines, let's make it into a dictionary of pages
    # Each element of 'pages' is a list of lines on the same page, indexed by the
    # number of the page in BRF file
        pages = dict()

        if len(re.findall("\f", text_body[0])) == 0:
            raise ValueError("Unexpected first line of body text: does not start with new page character")
        current_page = [text_body[0]]

        for number, line in enumerate(text_body[1:]):
            if line != '': # if we are not at the end
                if len(re.findall("\f", line)) == 0:
                # if we are not starting a new page
                    current_page.append(line)
                else: # get the page number of the current page, put it in dict and start a new current page
                    prev_line = text_body[number] # not 'number - 1' because we are starting with text_body[1]

                    if len(re.findall("[ ]{2}#([a-j]+?)$",prev_line)) == 0:
                        raise ValueError(f"Page number not found, expected to be on the line\n{prev_line}")
                    else:
                        page_num = brf_to_num(re.findall("[ ]{2}#([a-j]+?)$",prev_line)[0])
                        pages[page_num] = current_page
                        current_page = [line]
            # if we are at the last line, nothing to be done
        log.debug(f"Successfully split text into {page_num} pages")
        return(pages)

    def write_chapters(chapter_list, front_matter, text_body, \
                       split_frontmatter = False, split_backmatter = False):

        pages = split_body_into_pages(text_body)
        is_front_matter = True
        unnumbered_counter = 1
        back_matter = []

        for index in range(len(chapter_list)):
            # Assume that un-numbered chapters at the start are part of front matter.
            # Followed by numbered chapters
            # Followed by un-numbered back-matter

            chapter = chapter_list[index]
            # End page of a chapter is either the first page of the next chapter
            # (keeping in mind Python range conventions) or the last page of the document
            if index < len(chapter_list) - 1:
                chapter.end_page = chapter_list[index + 1].start_page
            else:
                chapter.end_page = max([num for num in pages.keys()]) + 1
            # Now we get the pages for each chapter:
            chapter.get_body(pages)

            if chapter.numbered:
                is_front_matter = False # Somewhat inefficient because we do it
                unnumbered_counter = 1  # more than once, but no harm

                chapter.write_body()

            elif is_front_matter:
                chapter.front_matter = True
                if split_frontmatter:
                    chapter.number = unnumbered_counter
                    chapter.write_body()
                    unnumbered_counter += 1
                else:
                    front_matter += chapter.body

            else: # Must be back matter
                chapter.front_matter = False
                if split_backmatter:
                    chapter.number = unnumbered_counter
                    chapter.write_body()
                    unnumbered_counter += 1
                else:
                    back_matter += chapter.body


            # Now everything was written except the TOC front matter and backmatter
            # if we were not splitting

            with open("frontmatter.brf",'w') as g:
                g.writelines(front_matter)
            if back_matter != []:
                with open("backmatter.brf",'w') as g:
                    g.writelines(back_matter)

            # TODO: add debug message listing all the chapters?

    toc, frontmatter, bodytext = get_TOC(filename)
    chapters = get_chapter_list(toc)
    write_chapters(chapters, frontmatter, bodytext)


####################
# Conversion to EPUB
####################


def epub(xml_source, pub_file, out_file, dest_dir, math_format, stringparams):
    """Produce complete document in an EPUB container"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # math_format is a string that parameterizes this process
    #   'svg': mathematics as SVG
    #   'mml': mathematics as MathML
    import fileinput

    # for building a cover image
    # modules from the PIL package
    import PIL.Image  # new()
    import PIL.ImageDraw  # Draw()
    import PIL.ImageFont  # truetype(), load_default()

    # general message for this entire procedure
    log.info(
        "converting {} into EPUB in {} with math as {}".format(
            xml_source, dest_dir, math_format
        )
    )

    # Build into a scratch directory
    tmp_dir = get_temporary_directory()
    log.debug("EPUB manufacture in temporary directory: {}".format(tmp_dir))

    # Before making a zip file, the temporary directory should look
    # like the unzipped version of an EPUB file.  For us, that goes:

    # mimetype
    # EPUB
    #   package.opf
    #   css
    #   xhtml
    #     generated images (customizable)
    #     external images (customizable)
    # META-INF

    source_dir = get_source_path(xml_source)
    epub_xslt = os.path.join(get_ptx_xsl_path(), "pretext-epub.xsl")
    math_representations = os.path.join(
        tmp_dir, "math-representations-{}.xml".format(math_format)
    )
    # speech representations are just for SVG images, but we define the filename always anyway
    speech_representations = os.path.join(
        tmp_dir, "math-representations-{}.xml".format("speech")
    )
    packaging_file = os.path.join(tmp_dir, "packaging.xml")
    xhtml_dir = os.path.join(tmp_dir, "EPUB", "xhtml")

    # ripping out LaTeX as math representations
    msg = "converting raw LaTeX from {} into clean {} format placed into {}"
    log.debug(msg.format(xml_source, math_format, math_representations))
    mathjax_latex(xml_source, pub_file, math_representations, None, math_format)
    # optionally, build a file of speech versions of the math
    if math_format == "svg":
        log.debug(msg.format(xml_source, "speech", speech_representations))
        mathjax_latex(xml_source, pub_file, speech_representations, None, "speech")

    # Build necessary content and infrastructure EPUB files,
    # using SVG images of math.  Most output goes into the
    # EPUB/xhtml directory via exsl:document templates in
    # the EPUB XSL conversion.  The stylesheet does record,
    # and produce some information needed for the packaging here.
    log.info(
        "converting source ({}) and clean representations ({}) into EPUB files".format(
            xml_source, math_representations
        )
    )
    params = {}

    # the EPUB production is parmameterized by how math is produced
    params["mathfile"] = math_representations.replace(os.sep, "/")
    # It is convenient for the subsequent XSL to always get a 'speechfile'
    # string parameter.  An empty string seems to not provoke an error,
    # though perhaps the resulting variable is crazy.  We'll just be
    # sure not to access the variable unless making SVG images.
    if math_format == "svg":
        params["speechfile"] = speech_representations.replace(os.sep, "/")
    else:
        params["speechfile"] = ""
    params["math.format"] = math_format
    params["tmpdir"] = tmp_dir.replace(os.sep, "/")
    if pub_file:
        params["publisher"] = pub_file
    xsltproc(epub_xslt, xml_source, packaging_file, tmp_dir, {**params, **stringparams})

    # XHTML files lack an overall namespace,
    # while EPUB validation expects it
    # Kindle needs an encoding declaration to avoid assuming ASCII
    # regex inplace to end up with:
    #   <?xml version="1.0" encoding="UTF-8"?>
    #   <html xmlns="http://www.w3.org/1999/xhtml">
    orig = "<html"
    repl = __xml_header + '<html xmlns="http://www.w3.org/1999/xhtml"'
    # the inoplace facility of the fileinput module gets
    # confused about temporary backup files if the working
    # directory is not where the file lives
    # Also, print() here actual writes on the file, as
    # another facility of the fileinput module, but we need
    # to kill the "extra" newline that print() creates
    with working_directory(xhtml_dir):
        html_elt = re.compile(orig)
        for root, dirs, files in os.walk(xhtml_dir):
            for fn in files:
                with fileinput.FileInput(fn, inplace=True) as file:
                    for line in file:
                        print(html_elt.sub(repl, line), end="")

    # EPUB stylesheet writes an XHTML file with
    # bits of info necessary for packaging
    packaging_tree = ET.parse(packaging_file)

    # Stage CSS files in EPUB/css, coordinate
    # with names in manifest and *.xhtml via XSL.
    # CSS files live in distribution in "css" directory,
    # which is a peer of the "xsl" directory
    # EPUB exists from above xsltproc call
    css_dir = os.path.join(tmp_dir, "EPUB", "css")
    os.mkdir(css_dir)

    # All styles are baked into one of these two files
    if math_format == "kindle":
        css = os.path.join(get_ptx_xsl_path(), "..", "css", "dist", "kindle.css")
        shutil.copy2(css, css_dir)
    if math_format == "svg":
        css = os.path.join(get_ptx_xsl_path(), "..", "css", "dist", "epub.css")
        shutil.copy2(css, css_dir)

    # EPUB Cover File

    # The /packaging/cover/ entry has the (relative) paths for the author's
    # provided cover image file and where it should land in the XHTML directory
    # of files, consistent with the manifest, etc.
    #
    # @authored-cover is 'yes' or 'no'.  In the latter case most of the
    # action happens here in the Python

    is_cover_authored = (packaging_tree.xpath("/packaging/cover/@authored-cover")[0] == 'yes')
    if is_cover_authored:
        # Build absolute paths and mirror directory structure, except for the
        # transition from authors name for "external" to the actual use of
        # "external" in the XHTML.  These details were handled in the creation
        # of the relevant publisher variables, which then migrated to the
        # packaging file, and then here
        cover_source_file = packaging_tree.xpath("/packaging/cover/@source")[0]
        cover_dest_file = packaging_tree.xpath("/packaging/cover/@dest")[0]
        cover_source = os.path.join(source_dir, str(cover_source_file))
        cover_dest = os.path.join(xhtml_dir, str(cover_dest_file))
        # https://stackoverflow.com/questions/2793789, Python 3.2
        os.makedirs(os.path.dirname(cover_dest), exist_ok=True)
        shutil.copy2(cover_source, cover_dest)
    else:
        # When an author does not provide an image, we try to manufacture one.
        # The file will be named "cover.png" and will be a top-level file in
        # the XHTML directory.  A publisher variable maintains consistency as
        # to what land in the XHTML files themselves (and manifest, etc.)
        cover_source = os.path.join(tmp_dir, "cover.png")
        cover_dest = os.path.join(xhtml_dir, "cover.png")
        # Get some useful things from the packaging file
        title = packaging_tree.xpath("/packaging/title")[0].xpath("string()").__str__()
        subtitle = (
            packaging_tree.xpath("/packaging/subtitle")[0].xpath("string()").__str__()
        )
        author = (
            packaging_tree.xpath("/packaging/author")[0].xpath("string()").__str__()
        )
        title_ASCII = "".join([x if ord(x) < 128 else "?" for x in title])
        subtitle_ASCII = "".join([x if ord(x) < 128 else "?" for x in subtitle])
        author_ASCII = "".join([x if ord(x) < 128 else "?" for x in author])
        log.info("attempting to construct cover image using LaTeX and ImageMagick")
        try:
            # process with the  xelatex  engine (better Unicode support)
            latex_key = get_deprecated_tex_fallback("xelatex")
            tex_executable_cmd = get_executable_cmd(latex_key)
            cover_tex_template = "\\documentclass[20pt]{{scrartcl}}\\begin{{document}}\\title{{ {} }}\\subtitle{{ {} }}\\author{{ {} }}\\date{{}}\\maketitle\\thispagestyle{{empty}}\\end{{document}}"
            if "xelatex" in tex_executable_cmd:
                cover_tex = cover_tex_template.format(
                    title, subtitle, author.replace(", ", "\\\\")
                )
            else:
                cover_tex = cover_tex_template.format(
                    title_ASCII, subtitle_ASCII, author_ASCII
                )
            cover_tex_file = os.path.join(tmp_dir, "cover.tex")
            with open(cover_tex_file, "w") as tex:
                tex.write(cover_tex)
            latex_cmd = tex_executable_cmd + ["-interaction=batchmode", cover_tex_file]
            cover_pdf_file = os.path.join(tmp_dir, "cover.pdf")
            # Presume ImageMagick's "convert" executable is on the path
            pdfpng_executable_cmd = ["convert"]
            png_cmd = pdfpng_executable_cmd + [
                "-quiet",
                "-density",
                "300",
                cover_pdf_file + "[0]",
                "-gravity",
                "center",
                "-crop",
                "5:8",
                "-background",
                "white",
                "-alpha",
                "remove",
                "-quality",
                "100",
                cover_source,
            ]
            with working_directory(tmp_dir):
                subprocess.run(latex_cmd)
                subprocess.run(png_cmd)
        except:
            msg = '\n'.join(["failed to construct cover image using LaTeX and ImageMagick",
                             'perhaps because the "convert" executable is not on your path.'])
            log.warning(msg)
            log.info('attempting to construct cover image using "Arial.ttf" and "Arial Bold.ttf"')
            try:
                title_size = 100
                title_font = PIL.ImageFont.truetype("Arial Bold.ttf", title_size)
                subtitle_size = int(title_size * 0.6)
                subtitle_font = PIL.ImageFont.truetype(
                    "Arial Bold.ttf", subtitle_size
                )
                author_size = subtitle_size
                author_font = PIL.ImageFont.truetype("Arial.ttf", author_size)
                title_words = title.split()
                subtitle_words = subtitle.split()
                author_names = [x.strip() for x in author.split(",")]
                png_width = 1280
                png_height = int(png_width * 1.6)
                # build an array of lines for the title (and subtitle), each line fitting within 80% of png_width
                title_lines = [""]
                for word in title_words:
                    last_line = title_lines[-1]
                    (line_width, line_height) = title_font.getsize(
                        last_line + " " + word
                    )
                    if line_width <= 0.8 * png_width:
                        title_lines[-1] += " " + word
                    else:
                        title_lines.append(word)
                multiline_title = "\n".join(title_lines).strip()
                subtitle_lines = [""]
                for word in subtitle_words:
                    last_line = subtitle_lines[-1]
                    (line_width, line_height) = subtitle_font.getsize(
                        last_line + " " + word
                    )
                    if line_width <= 0.8 * png_width:
                        subtitle_lines[-1] += " " + word
                    else:
                        subtitle_lines.append(word)
                multiline_subtitle = "\n".join(subtitle_lines).strip()
                # each author on own line
                multiline_author = "\n".join(author_names).strip()
                # create new image
                cover_png = PIL.Image.new(
                    mode="RGB", size=(png_width, png_height), color="white"
                )
                draw = PIL.ImageDraw.Draw(cover_png)
                title_depth = int(png_height // 4)
                subtitle_depth = (
                    title_depth + len(title_lines) * title_size + 0.2 * title_size
                )
                author_depth = (
                    subtitle_depth
                    + len(subtitle_lines) * subtitle_size
                    + 0.8 * title_size
                )
                draw.multiline_text(
                    (int(png_width // 2), title_depth),
                    multiline_title,
                    font=title_font,
                    fill="black",
                    anchor="ma",
                    align="center",
                )
                draw.multiline_text(
                    (int(png_width // 2), subtitle_depth),
                    multiline_subtitle,
                    font=subtitle_font,
                    fill="gray",
                    anchor="ma",
                    align="center",
                )
                draw.multiline_text(
                    (int(png_width // 2), author_depth),
                    multiline_author,
                    font=author_font,
                    fill="black",
                    anchor="ma",
                    align="center",
                )
                cover_png.save(cover_source)
            except:
                log.warning(
                    'failed to construct cover image using "Arial.ttf" and "Arial Bold.ttf"'
                )
                log.info("attempting to construct crude bitmap font cover image")
                try:
                    title_words = title_ASCII.split()
                    title_font = PIL.ImageFont.load_default()
                    cover_png = PIL.Image.new(
                        mode="RGB", size=(120, 192), color="white"
                    )
                    draw = PIL.ImageDraw.Draw(cover_png)
                    y = 20
                    for word in title_words:
                        draw.text((20, y), word, font=title_font, fill="black")
                        y += 10
                    cover_png.save(cover_source)
                except:
                    # We failed to build a cover.png so we remove all references to cover.png
                    log.warning("failed to construct a cover image")
        try:
            shutil.copy2(cover_source, cover_dest)
        except:
            log.info("removing references to cover image from package.opf")
            package_opf = os.path.join(tmp_dir, "EPUB/package.opf")
            package_opf_tree = ET.parse(package_opf)
            for meta in package_opf_tree.xpath(
                "//opf:meta[@name='cover']",
                namespaces={"opf": "http://www.idpf.org/2007/opf"},
            ):
                meta.getparent().remove(meta)
            for item in package_opf_tree.xpath(
                "//opf:item[@id='cover-image']",
                namespaces={"opf": "http://www.idpf.org/2007/opf"},
            ):
                item.getparent().remove(item)
            package_opf_tree.write(package_opf)

    # position image files
    images = packaging_tree.xpath("/packaging/images/image[@filename]")
    for im in images:
        sourcename = str(im.get("sourcename"))
        filename = str(im.get("filename"))
        try:
            source = os.path.join(source_dir, sourcename)
            dest = os.path.join(xhtml_dir, filename)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            shutil.copy2(source, dest)
        except:
            msg = 'PTX:BUG: error copying image with sourcename "{}" and filename "{}".  Perhaps see issue #2326.'
            log.warning(msg.format(sourcename, filename))

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

    title_file_element = packaging_tree.xpath("/packaging/filename")[0]
    title_file = ET.tostring(title_file_element, method="text").decode("ascii")
    epub_file = "{}-{}.epub".format(title_file, math_format)
    log.info("packaging an EPUB temporarily as {}".format(epub_file))
    with working_directory(tmp_dir):
        with zipfile.ZipFile(epub_file, mode="w", compression=zipfile.ZIP_DEFLATED) as epub:
            epub.write("mimetype", compress_type=zipfile.ZIP_STORED)
            for root, dirs, files in os.walk("EPUB"):
                for name in files:
                    epub.write(os.path.join(root, name))
            for root, dirs, files in os.walk("META-INF"):
                for name in files:
                    epub.write(os.path.join(root, name))
        derivedname = get_output_filename(xml_source, out_file, dest_dir, ".epub")
        log.info("EPUB file deposited as {}".format(derivedname))
        shutil.copy2(epub_file, derivedname)


####################
# Conversion to HTML
####################

# Leads with various helper functions, see
# also the dynamic_subsitutions() function

def _parse_runestone_services(et):
    # Unpack contents into format for XSL string parameters
    # This mirrors the XML file format, including multiple "item"
    #
    # creates PreTeXt-specific format for passing to XSL to unpack

    # colon-delimited string of the JS files
    rs_js = ''
    for js in et.xpath("/all/js/item"):
        rs_js = rs_js + js.text + ':'
    rs_js = rs_js[:-1]
    # colon-delimited string of the CSS files
    rs_css = ''
    for css in et.xpath("/all/css/item"):
        rs_css = rs_css + css.text + ':'
    rs_css = rs_css[:-1]
    # single CDN URL
    rs_cdn_url = et.xpath("/all/cdn-url")[0].text
    # single Runestone Services version
    rs_version = et.xpath("/all/version")[0].text

    return (rs_js, rs_css, rs_cdn_url, rs_version)

# A helper function to query the latest Runestone
# Services file, while failing gracefully

def _runestone_services(stringparams, ext_rs_methods):
    """Query the very latest Runestone Services file from the RS CDN"""

    # stringparams - string parameter dictionary, this gains three
    #                new keys which are passed on to the XSL eventually
    # ext_rs_methods - an optional function that can replace the querying
    #                   of the Runestone Services file
    # Result - returns five pieces of discovered or set information,
    #          see *two* return statements, one is intermediate.
    #          Failure is an option, if a network request fails

    # Canonical location of file of redirections to absolute-latest
    # released version of Runestone Services when parameterized by
    # "latest", otherwise will get a specific previous version
    services_url_template = 'https://runestone.academy/cdn/runestone/{}/webpack_static_imports.xml'

    # First, set the URL to hit on Runestone servers to initiate discovery
    # 1. debugging with a specific (old) version, set a URL and warn
    # 2. The generic  debug.rs.dev  requires developer to populate _static
    # 3. The "usual" case is provided by Runestone's "latest" directory, set a URL
    # (2) always succeeds, (1) and (3) can fail due to network errors
    if "debug.rs.version" in stringparams:
        rs_debug_version = stringparams["debug.rs.version"]
        services_url = services_url_template.format(rs_debug_version)
        msg = '\n'.join(["Requested Runestone Services, version {} from Runestone servers via the  debug.rs.version  string parameter.",
            "This is strictly for DEBUGGING and not for PRODUCTION.  The requested version may not exist,",
            "or there could be a network error and you will get something you did not expect.",
            "Subsequent diagnostic messages may be inaccurate.  Verify your HTML output is as intended."
            ])
        log.info(msg.format(rs_debug_version))
        # could remove the  debug.rs.version  key here,
        # no longer necessary to distinguish this case
    elif "debug.rs.dev" in stringparams:
        # basically a "pass"
        log.info("Building for local developmental Runestone Services. Make sure to build Runestone Services to _static in the output directory.")
    else:
        services_url = services_url_template.format("latest")

    # Predictable and convenient debugging situation
    # Developer is responsible for placement of the right files in _static
    # ** Simply return early with stock values (or None) **
    if "debug.rs.dev" in stringparams:
        rs_js = "prefix-runtime.bundle.js:prefix-runtime-libs.bundle.js:prefix-runestone.bundle.js"
        rs_css = "prefix-runtime-libs.css:prefix-runestone.css"
        rs_cdn_url = None
        rs_version = "dev"
        services_xml = None
        # Return, plus side-effect
        stringparams["rs-js"] = rs_js
        stringparams["rs-css"] = rs_css
        stringparams["rs-version"] = rs_version
        return (rs_js, rs_css, rs_cdn_url, rs_version, services_xml)

    # Otherwise, we have a URL pointing to the Runestone server/CDN
    # which may be successful and may not.
    try:
        if ext_rs_methods and "debug.rs.version" not in stringparams:
            # ext_rs_methods can be passed by the calling function.
            # It should only accept keyword arguments, including `format` to
            # distinguish between different types of requests.  Here we use
            # format="xml" to indicate we are getting the small XML file containing
            # data about the services and returning it as a string.
            services_xml = ext_rs_methods(url=services_url, format="xml")
        else:
            # Network failure is fatal.  query_runestone_services() will raise an exception
            # if it cannot get the Runestone Services file
            services_xml = query_runestone_services(services_url)
    except Exception as e:
        raise Exception(e)

    # Now services_xml should be meaningful since we haven't raised an exception.

    services = ET.fromstring(services_xml)
    # Interrogate the services XML
    rs_js, rs_css, rs_cdn_url, rs_version = _parse_runestone_services(services)

    # Return, plus side-effect
    stringparams["rs-js"] = rs_js
    stringparams["rs-css"] = rs_css
    stringparams["rs-version"] = rs_version
    return (rs_js, rs_css, rs_cdn_url, rs_version, services_xml)


def _cdn_runestone_services(stringparams, ext_rs_methods):
    """Version of _runestone_services function to query the Runestone Services file from the PreTeXt html-static CDN"""

    # stringparams - string parameter dictionary, this gains three
    #                new keys which are passed on to the XSL eventually
    # ext_rs_methods - an optional function that can replace the querying
    #                   of the Runestone Services file
    # Result - returns None, but updates stringparams dictionary with relevant rs values.

    # CDN url for runestone services xml file
    services_url_template = 'https://cdn.jsdelivr.net/gh/pretextbook/html-static@{}/dist/_static/runestone_services.xml'

    # When builing portable html using the pretext CDN, it doesn't make sense to
    # use the rs.version or rs.dev stringparams.  We warn if either of these are set.
    if "debug.rs.version" in stringparams:
        log.warning("Building portable html so ignoring the debug.rs.version string param")
        stringparams.pop("debug.rs.version")
    if "debug.rs.dev" in stringparams:
        log.warning("Building portable html so ignoring the debug.rs.dev string param")
        stringparams.pop("debug.rs.dev")

    # set version to "latest" unless cli set cdn version
    rs_version = stringparams.get("cli.version") or "latest"
    log.info("Using rs services version {} from the PreTeXt CDN".format(rs_version))
    services_url = services_url_template.format(rs_version)

    # Otherwise, we have a URL pointing to the Runestone server/CDN
    # which may be successful and may not.
    try:
        if ext_rs_methods:
            # ext_rs_methods can be passed by the calling function.
            # It should only accept keyword arguments, including `format` to
            # distinguish between different types of requests.  Here we use
            # format="xml" to indicate we are getting the small XML file containing
            # data about the services and returning it as a string.
            services_xml = ext_rs_methods(url=services_url, format="xml")
        else:
            # Network failure is fatal.  query_runestone_services() will raise an exception
            # if it cannot get the Runestone Services file
            services_xml = query_runestone_services(services_url)
    except Exception as e:
        raise Exception(e)

    # Now services_xml should be meaningful since we haven't raised an exception.
    services = ET.fromstring(services_xml)
    # Interrogate the services XML
    rs_js, rs_css, rs_cdn_url, rs_version = _parse_runestone_services(services)

    # Set rs stringparams
    stringparams["rs-js"] = rs_js
    stringparams["rs-css"] = rs_css
    stringparams["rs-version"] = rs_version
    return None


def query_runestone_services(services_url):
    """Query the Runestone Services file from the Runestone CDN.  Returns the response object's text (xml) or raises an exception if the network request fails."""

    # We assume an online query is a success, until we learn otherwise
    online_success = True

    # Test if (optional) requests module is installed
    try:
        import requests
    except ImportError:
        msg = 'the "requests" module is not available and is necessary for querying the Runestone CDN'
        log.debug(msg)
        online_success = False

    # Make a request with requests, which could fail if offline
    if online_success:
        try:
            services_response = requests.get(services_url, timeout=(1,10)) # 1 second connect, 10 second read
        except requests.exceptions.RequestException as e:
            msg = '\n'.join(['there was a network problem while trying to retrieve "{}"',
                             'from the Runestone CDN and the reported problem is:',
                             '{}'
                             ])
            log.debug(msg.format(services_url, e))
            online_success = False

    # Check that an online request was "OK", HTTP response code 200
    if online_success:
        response_status_code = services_response.status_code
        if response_status_code != 200:
            msg = '\n'.join(["the file {} was not found at the Runestone CDN",
                             "the server returned response code {}"
                             ])
            log.debug(msg.format(services_url, response_status_code))
            online_success = False

    if not(online_success):
        msg = '\n'.join(["unable to get Runestone Services from the Runestone CDN.",
                         "This is due to an error reported immediately prior in the log.",
                         "Unable to proceed and build useful HTML output without this."
                         ])
        log.debug(msg)
        # fatal error here, a URL is not doing the job
        raise Exception(msg)
    # Return the XML from the services response
    return services_response.text


def _place_runestone_services(tmp_dir, stringparams, ext_rs_methods):
    '''Obtain Runestone Services and place in _static directory of build'''

    # stringparams - this will be changed, receives Runestone Services information
    #                also contains potential debugging switches to influence behavior
    # ext_rs_methods - an optional function that can replace the querying and
    #                  downloading of the Runestone Services file

    # See if we can get Runestone Services, or interpret debugging selections
    # This call will always change  stringparams (absent network failures)
    # These get communicated eventually to the XSL to formulate the HTML #head
    rs_js, rs_css, rs_cdn_url, rs_version, services_xml = _runestone_services(stringparams, ext_rs_methods)
    # A URL to the Runestone servers will have been successful
    # in the "usual" and  debug.rs.version  cases
    if "debug.rs.dev" not in stringparams:
        # Previous line will raise a fatal error if the Runestone servers
        # do not cooperate, so we assume we have good information for
        # locating the most recent version of Runestone Services
        msg = 'Runestone Services via online CDN query: version {}'
        log.info(msg.format(rs_version))

        # Get all the Runestone files and place in _static
        # We "build" in tmp_dir, place "output" in dest_dir
        build_dir = os.path.join(tmp_dir, "_static")
        services_file_name = "dist-{}.tgz".format(rs_version)
        services_build_path = os.path.join(build_dir, services_file_name)
        # services_record is copy of services xml file
        # predictable name, contains version information
        services_record_build_path = os.path.join(build_dir, "_runestone-services.xml")
        try:
            msg = 'Downloading Runestone Services, version {}'
            log.info(msg.format(rs_version))
            if ext_rs_methods:
                # ext_rs_methods can be passed by the calling function.
                # It should only accept keyword arguments, including `format` to
                # distinguish between different types of requests.  Here we use
                # the format "tgz" to indicate that we are finding the full
                # tgz archive of Runestone Services.
                ext_rs_methods(url=rs_cdn_url + services_file_name, out_path=services_build_path, format="tgz")
            else:
                download_file(rs_cdn_url + services_file_name, services_build_path)
            log.info("Extracting Runestone Services from archive file")
            import tarfile
            services_file = tarfile.open(services_build_path)
            services_file.extractall(build_dir)
            services_file.close()
            # once unpacked, archive no longer necessary
            os.remove(services_build_path)
            # write the services_record XML file for potential
            # version checking with a caching implementation
            services_record = open(services_record_build_path, 'w')
            services_record.write(services_xml)
            services_record.close()
        except Exception as e:
            log.warning(e)
            log.warning("Failed to download all Runestone Services files")

# Helper to move a prebuilt css theme into the build directory as theme.css
def _move_prebuilt_theme(theme_name, theme_opts, tmp_dir):
    css_src = os.path.join(get_ptx_path(), "css", "dist")
    css_dest = os.path.join(tmp_dir, "_static", "pretext", "css")

    src = os.path.join(get_ptx_path(), "css", "dist", "theme-{}.css".format(theme_name))
    dest = os.path.join(get_ptx_path(), os.path.join(css_dest, "theme.css"))

    # ugly to have this here - it exists for more general use in _palette-dual.scss,
    # but to support prebuilt default theme we need to look up its colors here
    color_schemes = {
      "blue-red": {
        "primary-color": "#195684",
        "secondary-color": "#932c1c",
      },
      "blue-green": {
        "primary-color": "#195684",
        "secondary-color": "#28803f",
      },
      "green-blue": {
        "primary-color": "#1a602d",
        "secondary-color": "#2a5ea4",
      },
      "greens": {
        "primary-color": "#193e1c",
        "secondary-color": "#347a3a",
      },
      "blues": {
        "primary-color": "hsl(217, 70%, 20%)",
        "secondary-color": "hsl(216, 42%, 47%)",
      }
    }

    scheme = "blue-red"
    if 'palette' in theme_opts['options'].keys():
        if theme_opts['options']['palette']:
            selected_palette = theme_opts['options']['palette']
            if selected_palette in color_schemes.keys():
                scheme = theme_opts['options']['palette']
            else:
                log.warning("Selected palette " + selected_palette + " not found in color schemes. Using default scheme.")

    if 'primary-color' not in theme_opts['options'].keys():
        theme_opts['options']['primary-color'] = color_schemes[scheme]['primary-color']

    if 'secondary-color' not in theme_opts['options'].keys():
        theme_opts['options']['secondary-color'] = color_schemes[scheme]['secondary-color']

    log.info("Using prebuilt CSS theme: " + theme_name + " with options: " + str(theme_opts))

    # copy src -> dest with modifications
    with open(src, 'r') as theme_file:
        filedata = theme_file.read()

        # modify file so that it points to the map file theme.css.map
        filedata = re.sub(r'sourceMappingURL=[^\s]*', r'sourceMappingURL=theme.css.map', filedata)

        # append some css variables to the file so that colors can be customized
        # without rebuilding the theme
        regular_vars = {k:v for k, v in theme_opts['options'].items() if "-dark" not in k}
        if regular_vars:
            filedata += "\n/* generated from pub variables */\n:root:not(.dark-mode) {"
            for key, value in regular_vars.items():
                filedata += "--{}: {};".format(key, value)
            filedata += "}"

        dark_vars = {k.replace("-dark",""):v for k, v in theme_opts['options'].items() if "-dark" in k}
        if dark_vars:
            filedata += "\n/* generated from pub variables */\n:root.dark-mode {"
            for key, value in dark_vars.items():
                filedata += "--{}: {};".format(key, value)
            filedata += "}"

        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, 'w+') as file:
            file.write(filedata)

    # map file copied as is if it exists
    if os.path.exists(src + ".map"):
        shutil.copy(src + ".map", dest + ".map")

# Helper to build a custom version of a theme
def _build_custom_theme(xml, theme_name, theme_opts, tmp_dir):
    ptx_path = get_ptx_path()
    script = os.path.join(ptx_path, "script", "cssbuilder", "cssbuilder.mjs")
    css_dest = os.path.join(tmp_dir, "_static", "pretext", "css")

    # if doing building a completely custom theme, update entry-point to include full path as string
    if theme_name == "custom":
        theme_opts['options']['entry-point'] = os.path.join(get_source_path(xml), theme_opts['options']['entry-point'])

    # attempt build
    error_message = "Node.js is required to build themes other than default-modern. Make sure it is installed and in your PATH. Then do 'npm install' in the pretext/script/cssbuilder directory. https://pretextbook.org/doc/guide/html/node-and-npm.html"
    try:
        import subprocess, json
        node_exec_cmd = get_executable_cmd("node")
        # theme name is prefixed with "theme-" in the cssbuilder script output
        full_name = "theme-{}".format(theme_name)
        log.info("Building custom css theme: " + full_name)
        log.debug("Theme options:" + json.dumps(theme_opts))
        result = subprocess.run(node_exec_cmd + [script, "-t", full_name, "-o", css_dest, "-c", json.dumps(theme_opts)], capture_output=True, timeout=60)
        if result.stdout:
            log.debug(result.stdout.decode())
        if result.stderr:
            error_message = result.stderr.decode()
            raise Exception("Failed to build custom theme")
    except Exception as e:
        log.error(error_message)
        raise e

# Temporary helper to move style file for custom ol markers into _static/pretext/css
def move_ol_marker_css(tmp_dir):
    css_dest = os.path.join(tmp_dir, "_static", "pretext", "css")
    src = os.path.join(tmp_dir, "ol-markers.css")
    dest = os.path.join(get_ptx_path(), os.path.join(css_dest, "ol-markers.css"))
    if os.path.exists(src):
        shutil.move(src, dest)

def check_color_contrast(color1, color2):
    try:
        from coloraide import Color
        contrast = Color(color1).contrast(color2, method='wcag21')
        if contrast < 4.5:
            log.warning("Color " + color1 + " does not have enough contrast with expected background color " + color2 + ". Contrast ratio is " + str(contrast) + " but should be at least 4.5. Adjust your publisher file html/css/variables to ensure sufficient contrast.")
    except ImportError:
        log.warning("The coloraide module is not available and is necessary for checking color contrast. Install it with 'pip install coloraide' or by using the requirements.txt file.")

def build_or_copy_theme(xml, pub_var_dict, tmp_dir):
    theme_name = get_publisher_variable(pub_var_dict, 'html-theme-name')
    theme_opts_json = get_publisher_variable(pub_var_dict, 'html-theme-options')
    import json
    theme_opts = json.loads(theme_opts_json)

    # attempt basic sanity check of colors
    for var, check_color in theme_opts['contrast-checks'].items():
        if var in theme_opts['options']:
            check_color_contrast(theme_opts['options'][var], check_color)

    # use prerolled theme if legacy or default-modern and no node available
    use_prerolled = False
    if "-legacy" in theme_name:
        use_prerolled = True
    elif theme_name == "default-modern":
        try:
            get_executable_cmd("node")
            if not os.path.exists(os.path.join(get_ptx_path(), "script", "cssbuilder", "node_modules")):
                log.info("CSSBuilder packages not installed. Relying on prebuilt default-modern. To fix this, run 'npm install' in the pretext/script/cssbuilder directory. https://pretextbook.org/doc/guide/html/node-and-npm.html")
                use_prerolled = True
        except Exception as e:
            log.info("Node.js not available. Relying on prebuilt default-modern.")
            use_prerolled = True

    if use_prerolled:
        _move_prebuilt_theme(theme_name, theme_opts, tmp_dir)
    else:
        _build_custom_theme(xml, theme_name, theme_opts, tmp_dir)

# entry point for pretext script to only build the theme
def update_theme(xml_source, publication_file, stringparams, dest_dir):
    tmp_dir = get_temporary_directory()
    pub_vars = get_publisher_variable_report(xml_source, publication_file, stringparams)
    build_or_copy_theme(xml_source, pub_vars, tmp_dir)
    copy_build_directory(tmp_dir, dest_dir)

# todo - rewrite other code that does similar things to use this function?
def get_web_asset(url):
    """Get the contents of an http request"""
    try:
        import requests
    except ImportError:
        msg = 'The "requests" module is not available and is necessary for downloading files.'
        log.debug(msg)
        raise Exception(msg)

    try:
        services_response = requests.get(url, timeout=(1,10))
    except requests.exceptions.RequestException as e:
        msg = '\n'.join(['There was a network problem while trying to download "{}"',
                            'and the reported problem is:',
                            '{}'
                            ])
        log.debug(msg.format(url, e))
        raise Exception(msg.format(url, e))

    # Check that an online request was "OK", HTTP response code 200
    response_status_code = services_response.status_code
    if response_status_code != 200:
        msg = '\n'.join(["The file {} was not found",
                            "the server returned response code {}"
                            ])
        log.debug(msg.format(url, response_status_code))
        raise Exception(msg.format(url, response_status_code))

    return services_response.content

def download_file(url, dest_filename):
    """Write a web asset to a local file"""
    contents = get_web_asset(url)
    try:
        dest_dir = os.path.dirname(dest_filename)
        os.makedirs(dest_dir, exist_ok=True)

        with open(dest_filename, 'wb') as f:
            f.write(contents)
    except Exception as e:
        raise Exception("Failed to save download", dest_filename)

def html(xml, pub_file, stringparams, xmlid_root, file_format, extra_xsl, out_file, dest_dir, ext_rs_methods):
    """Convert XML source to HTML files, in destination directory or as zip file"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # Consult publisher file for locations of images
    generated_abs, external_abs = get_managed_directories(xml, pub_file)

    # names for scratch directories
    tmp_dir = get_temporary_directory()

    pub_vars = get_publisher_variable_report(xml, pub_file, stringparams)
    include_static_files = get_publisher_variable(pub_vars, 'portable-html') != "yes"

    if include_static_files:
        # interrogate Runestone server (or debugging switches) and populate
        # NB: stringparams is augmented with Runestone Services information
        _place_runestone_services(tmp_dir, stringparams, ext_rs_methods)
    else:
        # even if we don't need static files, we need to set stringparams for
        # Runestone Services information.
        _cdn_runestone_services(stringparams, ext_rs_methods)

    # support publisher file, and subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Optional extra XSL could be None, or sanitized full filename
    if extra_xsl:
        extraction_xslt = extra_xsl
    else:
        extraction_xslt = os.path.join(get_ptx_xsl_path(), "pretext-html.xsl")

    # place managed directories - some of these (Asymptote HTML) are
    # consulted during the XSL run and so need to be placed beforehand
    copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs)

    if include_static_files:
        # Copy js and css, but only if not building portable html
        # place JS in scratch directory
        copy_html_js(tmp_dir)

        # build or copy theme
        build_or_copy_theme(xml, pub_vars, tmp_dir)

    # Write output into temporary directory
    log.info("converting {} to HTML in {}".format(xml, tmp_dir))
    xsltproc(extraction_xslt, xml, None, tmp_dir, stringparams)

    if include_static_files:
        # extra css for custom ol markers
        move_ol_marker_css(tmp_dir)
    if not(include_static_files):
        # remove latex-image generated directories for portable builds
        shutil.rmtree(os.path.join(tmp_dir, "generated", "latex-image"), ignore_errors=True)

    if file_format  == "html":
        # with multiple files, we need to copy a tree
        # see comments at  copy_build_directory()
        # before replacing with  shutil.copytree()
        copy_build_directory(tmp_dir, dest_dir)
    elif file_format == "zip":
        # working in temporary directory gets simple paths in zip file
        with working_directory(tmp_dir):
            zip_file = "html-output.zip"
            log.info(
                "packaging a zip file temporarily as {}".format(
                    os.path.join(tmp_dir, zip_file)
                )
            )
            with zipfile.ZipFile(zip_file, mode="w", compression=zipfile.ZIP_DEFLATED) as epub:
                for root, dirs, files in os.walk("."):
                    for name in files:
                        epub.write(os.path.join(root, name))
            derivedname = get_output_filename(xml, out_file, dest_dir, ".zip")
            shutil.copy2(zip_file, derivedname)
            log.info("zip file of HTML output deposited as {}".format(derivedname))
    else:
        raise ValueError("PTX:BUG: HTML file format not recognized")


def revealjs(
    xml, pub_file, stringparams, xmlid_root, file_format, extra_xsl, out_file, dest_dir
):
    """Convert XML source "slideshow" to reveal.js HTML file"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # Consult publisher file for locations of images
    generated_abs, external_abs = get_managed_directories(xml, pub_file)

    # names for scratch directories
    tmp_dir = get_temporary_directory()

    # support publisher file, and subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Optional extra XSL could be None, or sanitized full filename
    if extra_xsl:
        extraction_xslt = extra_xsl
    else:
        extraction_xslt = os.path.join(get_ptx_xsl_path(), "pretext-revealjs.xsl")

    # place managed directories - some of these (Asymptote HTML) are
    # consulted during the XSL run and so need to be placed beforehand
    copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs)

    # place JS in scratch directory
    copy_html_js(tmp_dir)

    # Write output into temporary directory
    log.info("converting {} to HTML in {}".format(xml, tmp_dir))
    derivedname = get_output_filename(xml, out_file, dest_dir, ".html")
    xsltproc(extraction_xslt, xml, derivedname, tmp_dir, stringparams)
    # with multiple files, we need to copy a tree
    # see comments at  copy_build_directory()
    # before replacing with  shutil.copytree()
    copy_build_directory(tmp_dir, dest_dir)


##################
# Assembled Source
##################

# AKA the aftermath of the pre-processor
# Parameterized by static v. dynamic exercises


def assembly(xml, pub_file, stringparams, out_file, dest_dir, method):
    """Convert XML source to pre-processed PreTeXt in destination directory"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # support publisher file, not subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    # method dictates which type of exercises are produced
    # parameter is exclusive to utility styleheet below
    if method in ["static", "dynamic", "pg-problems"]:
        stringparams["debug.assembly.exercise"] = method
    elif method == "version":
        stringparams["assembly.version-only"] = "yes"
    else:
        log.error("assembly method {} not recognized".format(method))
    # "extra_xsl" would be silly in this context (?)
    extraction_xslt = os.path.join(
        get_ptx_xsl_path(), "utilities/pretext-enhanced-source.xsl"
    )
    # form output filename based on source filename,
    # unless an  out_file  has been specified
    derivedname = get_output_filename(xml, out_file, dest_dir, ".xml")
    # Write output into working directory, no scratch space needed
    log.info(
        "converting {} to enhanced (pre-processed) PreTeXt source as {}".format(
            xml, derivedname
        )
    )
    xsltproc(extraction_xslt, xml, derivedname, None, stringparams)


#####################
# Conversion to LaTeX
#####################

def get_latex_style(xml, pub_file, stringparams):
    """
    Returns the name of a latex_style to be used for processing to latex.
      - Checks the value of the publisher variable 'journal-name'.
      - If it finds a journal name, tries to resolve that using the list of
        journals, returning the corresponding latex-style entry for that journal.
      - If there is no journal-name publisher variable, or the variable is not in the
        list of journals, checks for the publisher variable 'latex-style' and returns this.
    """
    pub_vars = get_publisher_variable_report(xml, pub_file, stringparams)
    journal_name = get_publisher_variable(pub_vars, "journal-name")
    pub_latex_style = get_publisher_variable(pub_vars, "latex-style")
    if len(journal_name) > 0:
        journal_info = get_journal_info(journal_name)
        latex_style = journal_info["latex-style"]
        if len(latex_style) == 0:
            msg = "The journal name {} in your publication file is invalid or does not correspond to a valid latex-style.  Using the default LaTeX style instead."
            log.warning(msg.format(journal_name))
            latex_style = pub_latex_style
        if len(pub_latex_style) > 0 and pub_latex_style != latex_style:
            msg = "Your publication file specifies a latex-style of {}, but a journal name of {}.  Building with the latex style {} which matches that journal instead."
            log.warning(msg.format(pub_latex_style, journal_name, latex_style))
    else:
        latex_style = pub_latex_style
    return latex_style

# This is not a build target, there is no such thing as a "latex build."
# Instead, this is a conveience for developers who want to compare
# different versions of this file during development and testing.

def latex(xml, pub_file, stringparams, extra_xsl, out_file, dest_dir):
    """Convert XML source to LaTeX in destination directory"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # support publisher file, not subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file

    # Get potential extra XSL for LaTeX style from publication file
    latex_style = get_latex_style(xml, pub_file, stringparams)

    # Optional extra XSL could be None, or sanitized full filename
    if extra_xsl:
        extraction_xslt = extra_xsl
        if latex_style:
            log.warning("Ignoring the publisher file's latex-style in favor of the extra XSL specified.")
    elif latex_style:
        log.debug("Using LaTeX style: {}".format(latex_style))
        extraction_xslt = os.path.join(get_ptx_xsl_path(), "latex", f"pretext-latex-{latex_style}.xsl")
    else:
        extraction_xslt = os.path.join(get_ptx_xsl_path(), "pretext-latex.xsl")
    # form output filename based on source filename,
    # unless an  out_file  has been specified
    derivedname = get_output_filename(xml, out_file, dest_dir, ".tex")
    # Write output into working directory, no scratch space needed
    log.info("converting {} to LaTeX as {}".format(xml, derivedname))
    xsltproc(extraction_xslt, xml, derivedname, None, stringparams)


###################
# Conversion to PDF
###################


def pdf(xml, pub_file, stringparams, extra_xsl, out_file, dest_dir, method):
    """Convert XML source to a PDF (incomplete)"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    generated_abs, external_abs = get_managed_directories(xml, pub_file)
    # perhaps necessary (so drop "if"), but maybe not; needs to be supported
    if pub_file:
        stringparams["publisher"] = pub_file
    # names for scratch directories
    tmp_dir = get_temporary_directory()

    # make the LaTeX source file in scratch directory
    # (1) pass None as out_file to derive from XML source filename
    # (2) pass tmp_dir (scratch) as destination directory
    latex(xml, pub_file, stringparams, extra_xsl, None, tmp_dir)

    # Create localized filenames for pdflatex conversion step
    # sourcename  needs to match behavior of latex() with above arguments
    basename = os.path.splitext(os.path.split(xml)[1])[0]
    sourcename = basename + ".tex"
    pdfname = basename + ".pdf"

    # Copy directories as indicated in publisher file
    # A "None" value will indicate there was no information
    # (an empty string is impossible due to a slash always being present?)

    copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs)

    # now work in temporary directory since LaTeX is a bit incapable
    # of working outside of the current working directory
    with working_directory(tmp_dir):
        # process with a  latex  engine
        latex_key = get_deprecated_tex_fallback(method)
        latex_exec_cmd = get_executable_cmd(latex_key)
        # In flux during development, now nonstop
        # -halt-on-error will give an exit code to examine
        # perhaps behavior depends on -v, -vv
        # Two passes to resolve cross-references,
        # we may need a third for tcolorbox adjustments
        latex_cmd = latex_exec_cmd + ["-halt-on-error", sourcename]
        subprocess.run(latex_cmd)
        subprocess.run(latex_cmd)

        # out_file: not(None) only if provided in CLI
        # dest_dir: always defined, if only current directory of CLI invocation
        if out_file:
            shutil.copy2(pdfname, out_file)
        else:
            shutil.copy2(pdfname, dest_dir)

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

    N.B. The value of a "publisher" string parameter passed in the
    "stringparams" argument must be a complete path, since a relative
    path can be rendered incorrect by the change to an "output_dir"
    different than that at the time of the command-line invocation.

    N.B. A stylesheet may output text to be captured in the "result"
    file, and it may *also simultaneously* produce many files to be
    collected in the "output_dir" directory.  An example is in the
    formation of preview images for interactives.
    """
    import threading  # Thread()

    log.info("XSL conversion of {} by {}".format(xml, xsl))
    debug_string = (
        "XSL conversion via {} of {} to {} and/or into directory {} with parameters {}"
    )
    log.debug(debug_string.format(xsl, xml, result, output_dir, stringparams))

    # string parameters arrive in a "plain" string:string dictionary
    # but the values need to be prepped for lxml use, always
    stringparams = {
        key: ET.XSLT.strparam(value) for (key, value) in stringparams.items()
    }

    # Parse source, no harm to assume
    # xinclude modularization is necessary.
    # We build a custom parser without limitations
    # Seems a depth of 256 was exceeded for an SVG image:
    # lxml.etree.XMLSyntaxError: Excessive depth in document: 256 use XML_PARSE_HUGE option
    huge_parser = ET.XMLParser(huge_tree=True)
    src_tree = ET.parse(xml, parser=huge_parser)
    try:
        src_tree.xinclude()
    except ET.XIncludeError as e:
        # xinclude() does not show what file a parsing error occured in
        # So if there was an error, build a custom loader and redo with ElementInclude
        # which will include the file name in the stack dump.
        # ElementInclude is a limited version of xinclude(), so can't rely
        # on it for the real include process.

        # Generate custom loader
        from lxml import ElementInclude
        def my_loader(href, parse, encoding=None, parser=None):
            ret = ElementInclude._lxml_default_loader(href, parse, encoding, parser)
            return ret

        # Reparse the tree (was modified in try clause) and run ElementInclude
        # This should also fail, but will give a better error message
        src_tree = ET.parse(xml, parser=huge_parser)
        ElementInclude.include(src_tree, loader=my_loader, max_depth=100)

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
    # clear global errors, apply the xsl transform
    ET.clear_error_log()
    result_tree = []
    texc = None

    def transform():
        nonlocal result_tree, texc
        try:
            result_tree = xslt(src_tree, **stringparams)
        except Exception as e:
            texc = e

    try:
        parse_t = threading.Thread(target=transform)
        parse_t.start()
        still_alive = True
        start = 0
        while still_alive:
            parse_t.join(0.5)  # Wait 0.5 seconds for thread to complete
            still_alive = parse_t.is_alive()

            end = len(xslt.error_log)

            # if there are any messages and we are just
            # starting out, produce an explanatory line
            # start will be reset to non-zero, so this is
            # one-time only, and never if there are no messages
            if (start == 0) and (end > 0):
                log.info("messages from the log for XSL processing:")
            # print out any unprinted messages from error_log
            for line in xslt.error_log[start:end]:
                if "PTX:FATAL" in line.message:
                    log.critical(f"* {line.message}")
                elif "PTX:ERROR" in line.message or "PTX:BUG" in line.message:
                    log.error(f"* {line.message}")
                elif "PTX:WARNING" in line.message or "PTX:DEPRECATE" in line.message:
                    log.warning(f"* {line.message}")
                elif "PTX:DEBUG" in line.message:
                    log.debug(f"* {line.message}")
                else:
                    log.info(f"* {line.message}")
            start = end
        if texc is None:
            log.info("successful application of {}".format(xsl))
        else:
            raise (texc)
    except Exception as e:
        log.error("processing with {} has failed\n".format(xsl))
        # report any errors on failure (indented)
        raise (e)
    finally:
        # wait until thread is done
        if parse_t.is_alive():
            parse_t.join()
        # restore directory in success or failure
        os.chdir(owd)

    # write a serialized version of `result_tree` to a file
    # write_output() is an lxml method which respects/interprets
    # the stylesheet's xsl:output/@encoding attribute value
    # An error traced back here could be a stylesheet with no explicit
    # encoding given, so determine which `xsl` is in use and check
    try:
        if result:
            result_tree.write_output(result)
    except LookupError as e:
        root_cause = str(e)
        msg = "".join(
            [
                "PTX:ERROR: the stylesheet: {}\n",
                "has a problem with xsl:output/@encoding.\n",
                "The lxml error message is:\n",
                '"{}"',
            ]
        ).format(xsl, root_cause)
        raise ValueError(msg)


########################
#
# JaaS
# Jing as a Service
# (Validation with Jing)
#
########################

def validate(xml_source, out_file, dest_dir):

    try:
        import requests  # post()
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("requests"))

    # JaaS server location
    server_url = 'https://mathgenealogy.org:9000/validate'
    # Alias for XInclude namespace
    NSMAP = {"xi": "http://www.w3.org/2001/XInclude"}
    # home for zip file construction
    tmp_dir = get_temporary_directory()

    # directory location of main source file, every filename collected
    # below (in *_files lists) is relative to this directory
    d = os.path.split(xml_source)[0]
    base = os.path.split(xml_source)[1]

    # Initialize with overall source file's
    # name (base), relative to its location (d)
    # all_files will be the eventual result
    all_files = [base]
    # new_files is refreshed for each pass of the while loop,
    # non-empty ensures the while loop happens at least once
    new_files = [base]
    while new_files:
        # accumulator to become the subsequent new_files
        next_files = []
        for f in new_files:
            # construct full filename for parse operation
            # do not xinclude, that would defeat the purpose
            file_tree = ET.parse(os.path.join(d, f))
            includes = file_tree.xpath("//xi:include", namespaces=NSMAP)
            # @href attributes are relative to the location
            #  of f, which we compute as f_dir
            f_dir = os.path.split(f)[0]
            for elt in includes:
                # the href, required/expected/necessary
                if "href" in elt.attrib:
                    href = elt.attrib["href"]
                else:
                    raise ValueError("an xi:include element lacks the expected @href attribute")
                # the normaized filename, relative to the main file location (d)
                # this is where the eventual results are first created
                rel_path = os.path.normpath(os.path.join(f_dir, href))
                # always of interest, always add to result, even
                # a text file might be needed to feed the schema
                all_files.append(rel_path)
                # if including a text file, then lxml inspection
                # will fail, AND we don't need to examine it further,
                # as it is a dead-end in the tree (can't xi:include anyway)
                parsing = None
                if 'parse' in elt.attrib:
                    parsing = elt.attrib['parse']
                # Usually we want to inspect a file for more includes,
                # so we add most to the list of files to examine next
                if not(parsing == 'text'):
                    next_files.append(rel_path)
        # recycle next_files into new_files, and next_file
        # will be re-initialized as while loop resumes
        new_files = next_files

    # Build a zip file of the source, files with relative paths
    # zipfile.ZIP_DEFLATED is the "usual  ZIP compression method"
    zip_filename = os.path.join(tmp_dir, "test.zip")
    log.info("packaging source temporarily as {}".format(zip_filename))
    with working_directory(d):
        with zipfile.ZipFile(zip_filename, mode="w", compression=zipfile.ZIP_DEFLATED) as zip_file:
            # set() will avoid duplicate files included twice (or more)
            for f in set(all_files):
                zip_file.write(f)


    # fresh schema from the PreTeXt distribution
    schema_filename = os.path.join(get_ptx_path(), "schema", "pretext.rng")
    files = {'source': open(zip_filename,'rb'), 'rng': open(schema_filename,'rb')}
    data = {'mainfile': base}
    log.info("communicating with server at {}".format(server_url))
    r = requests.post(server_url, data=data, files=files)

    derivedname = get_output_filename(xml_source, out_file, dest_dir, ".jing")
    with open(derivedname, "w") as f:
        f.writelines(r.text)
    log.info("messages from validation in {}".format(derivedname))


###################
#
# Utility Functions
#
###################


def python_version():
    """Return 'major.minor' version number as string/info"""

    return "{}.{}".format(sys.version_info[0], sys.version_info[1])


def check_python_version():
    """Raise error with Python 2 (or less)"""

    # This test could be more precise,
    # but only handling 2to3 switch when introduced
    msg = "".join(
        [
            "PreTeXt script/module expects Python 3.8, not Python 2 or older\n",
            "You have Python {}\n",
            "** Try prefixing your command-line with 'python3 ' **",
        ]
    )
    if sys.version_info[0] <= 2:
        raise (OSError(msg.format(python_version())))


def set_ptx_path(path=None):
    """Set (or discover) path to root of PreTeXt distribution"""
    # necessary to locate configuration files, XSL stylesheets
    # since authors can drop distribution *anywhere* in their system
    # Default (path=None) will assume the location is relative to
    # this module in the PreTeXt distribution.  Otherwise, a
    # simple assignment is made

    global __ptx_path

    if path:
        __ptx_path = path
    else:
        # full path to module itself
        ptx_path = os.path.abspath(__file__)
        # split "python.py" off module's filename
        module_dir, _ = os.path.split(ptx_path)
        # split "pretext" path off executable
        __ptx_path, _ = os.path.split(module_dir)
    return None


def get_ptx_path():
    """Returns path to root of PreTeXt distribution"""
    global __ptx_path

    return __ptx_path


def get_ptx_xsl_path():
    """Returns path of PreTeXt XSL directory"""

    return os.path.join(get_ptx_path(), "xsl")


def get_source_path(source_file):
    """Returns path of source XML file"""

    # split path off filename
    source_dir, _ = os.path.split(source_file)
    log.info("discovering source file's directory name: {}".format(source_dir))
    return os.path.normpath(source_dir)


def _git_symbolic_to_hash(symbolic):
    '''Convert a branch name to its commit hash at the tip'''

    repo = get_ptx_path();
    # e.g. .git/refs/heads/master
    commit_filename = os.path.join(repo, '.git', 'refs', 'heads', symbolic)
    try:
        with open(commit_filename, 'r') as f:
            # always a commit hash in hex
            # strip a trailing newline (OK assumption?)
            return f.readline()[:-1]
    except Exception as e:
        log.critical(traceback.format_exc())
        log.critical("the full PreTeXt repository may not be available, so determination of commits is not possible")
        return None


# presumes PreTeXt repo publishes "master" as mainline branchh
def get_git_master_commit():
    """Return the full commit hash of master branch"""
    # Note: no guarantee this is the branch in use
    return _git_symbolic_to_hash('master')


def get_git_head():
    '''Returns a pair for active branch: (symbolic name, hash)'''
    # Note: in "detached state" the symbolic name is None

    import string

    repo = get_ptx_path();
    # .git/refs/heads/master
    branch_filename = os.path.join(repo, '.git', 'HEAD')
    try:
        with open(branch_filename, 'r') as f:
            # strip a trailing newline (OK assumption?)
            head = f.readline()[:-1]
    except Exception as e:
        log.critical(traceback.format_exc())
        log.critical("the full PreTeXt repository may not be available, so determination of commits is not possible")
        return (None, None)

    # head is normally a full symbolic reference
    # but on a "checkout" is "detached" and is a hash
    # https://stackoverflow.com/questions/11592261/check-if-a-string-is-hexadecimal
    # https://stackoverflow.com/a/11592279
    if all(c in string.hexdigits for c in head):
        return (None, head)
    else:
        # strip leading 16 characters: "ref: refs/heads/"
        branch = head[16:]
        commit = _git_symbolic_to_hash(branch)
        return (branch, commit)


def build_info_message():
    '''Return a string with useful information about build environment'''
    # Presumes the git repository is present, may need an override
    branch, commit = get_git_head()
    master = get_git_master_commit()
    msg = 'built with {} using commit {} at tip of branch "{}" ("master": {})'
    return msg.format("pretext/pretext script", commit, branch, master)


def set_executables(adict):
    global __executables

    __executables = adict


def get_executable_cmd(exec_name):
    """Queries configuration file for executable name, verifies existence in Unix"""

    global __executables

    # get the name, but then see if it really, really works
    log.debug(
        'locating "{}" in [executables] section of configuration file'.format(exec_name)
    )
    # 'tex' deprecated, and replaced by 'latex', 'pdflatex', and 'xelatex'
    if exec_name == "tex":
        msg = "\n".join(
            [
                "'tex'  is deprecated as a key for a LaTeX executable (2022-01-31)'",
                "             and has been replaced by 'latex', 'pdflatex', or 'xelatex'.",
                "***  We will attempt to honor your existing LaTeX engine choice.                ***",
                '***  Edit the configuration file  ("pretext.cfg" or "project.ptx") accordingly  ***',
            ]
        )
        # upgrade to an ERROR/exception after some interval
        log.warning(msg)
    config_cmd_line = __executables[exec_name].split()

    # Returns the full-path version of the command, as if the PATH was employed
    # "None" indicates the executable does not exist on the system
    # https://stackoverflow.com/questions/377017/test-if-executable-exists-in-python
    normalized_exec = shutil.which(config_cmd_line[0])

    error_messages = []
    if normalized_exec == None:
        error_messages += [
            "PTX:ERROR: cannot locate executable with configuration name `{}` as command `{}`".format(
                exec_name, config_cmd_line[0]
            ),
            '***  Edit the configuration file  ("pretext.cfg" or "project.ptx") and/or install  ***',
            "***  the necessary program and/or make sure the executable is on your PATH         ***",
        ]
    if error_messages:
        raise OSError("\n".join(error_messages))
    log.debug(
        "{} executable: {}, options: {}".format(
            exec_name, config_cmd_line[0], " ".join(config_cmd_line[1:])
        )
    )
    return config_cmd_line


def get_deprecated_tex_fallback(key):
    """Return the best executable key in light of deprecation"""
    global __executables

    # Input: 'latex', 'pdflatex', or 'xelatex', as
    #         enforced in the user interface
    #
    # Output: simply echo input, unless such an executable key
    # does not exist AND there is a stale (deprecated) 'tex' key.
    # In this case, generate the 'tex' key.  Warning will come
    # from the  get_executable_cmd()  function.
    if not (key in __executables) and ("tex" in __executables):
        return "tex"
    else:
        return key


def sanitize_url(url):
    """Verify a server address"""
    log.info("validating, cleaning server URL: {}".format(url))
    try:
        import requests  # test a URL
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("requests"))
    try:
        requests.get(url, timeout=10)
    except requests.exceptions.RequestException as e:
        root_cause = str(e)
        msg = "PTX:ERROR: there was a problem with the server URL, {}\n".format(url)
        raise ValueError(msg + root_cause)
    return url


def sanitize_alpha_num_underscore(param):
    """Verify parameter is a string containing only alphanumeric and undescores"""
    import string

    allowed = set(string.ascii_letters + string.digits + "_")
    log.info("verifying parameter: {}".format(param))
    if not (set(param) <= allowed):
        raise ValueError(
            "PTX:ERROR: param {} contains characters other than a-zA-Z0-9_ ".format(
                param
            )
        )
    return param


def get_temporary_directory():
    """Create, record, and return a scratch directory"""
    import tempfile  #  mkdtemp()

    global __temps  #  cache of temporary directories

    temp_dir = tempfile.mkdtemp(prefix="ptx-")
    # Register the directory for cleanup at the end of successful
    # execution iff the verbosity is set to level 2 ("debug")
    # So errors, or requesting gross debugging info, will leave the
    # directories behind for inspection, otherwise they get removed
    __temps.append(temp_dir)
    return temp_dir


def get_output_filename(xml, out_file, dest_dir, suffix):
    """Formulate a filename for single-file output"""
    #  out_file  is None, or full path
    #  dest_dir is at least current working directory

    if out_file:
        return out_file
    # split off source filename, replace suffix
    derivedname = os.path.splitext(os.path.split(xml)[1])[0] + suffix
    return os.path.join(dest_dir, derivedname)


def release_temporary_directories():
    """Release scratch directories unless requesting debugging info"""

    global __temps

    # log.level is 10 for debug, greater for all other levels.
    if log.level > 10:
        for td in __temps:
            log.info("Removing temporary directory {}".format(td))
            # conservatively, raise exception on errors
            shutil.rmtree(td, ignore_errors=False)
            # reset list of temp direcotries to empty, to avoid duplicate requests
            __temps = []
    else:
        log.debug("Temporary directories left behind for inspection: {}".format(__temps))


def verify_input_directory(inputdir):
    """Verify directory exists, or raise error.  Return absolute path"""

    log.info("verifying and expanding input directory: {}".format(inputdir))
    if not (os.path.isdir(inputdir)):
        raise ValueError("directory {} does not exist".format(inputdir))
    absdir = os.path.abspath(inputdir)
    log.info("input directory expanded to absolute path: {}".format(absdir))
    return absdir


def get_managed_directories(xml_source, pub_file):
    """Returns pair: (generated, external) absolute paths, derived from publisher file"""

    # N.B. manage attributes carefully to distinguish
    # absent (None) versus empty string value ('')

    # Examine /publication/source/directories element carefully
    # for attributes which we code here for convenience
    gen_attr = "generated"
    ext_attr = "external"

    # prepare for relative paths later
    source_dir = get_source_path(xml_source)

    # Unknown until running the gauntlet
    generated = None
    external = None
    if pub_file:
        # parse publisher file, xinclude is conceivable
        # for multiple similar publisher files with common parts
        pub_tree = ET.parse(pub_file)
        pub_tree.xinclude()
        # "source" element => single-item list
        # no "source" element => empty list => triple of None returned
        element_list = pub_tree.xpath("/publication/source/directories")
        if element_list:
            attributes_dict = element_list[0].attrib
            # common error messages
            abs_path_error = " ".join(
                [
                    "the directory path to data for images, given in the",
                    'publisher file as "source/directories/@{}" must be relative to',
                    'the PreTeXt source file location, and not the absolute path "{}"',
                ]
            )
            missing_dir_error = " ".join(
                [
                    'the directory "{}" implied by the value "{}" in the',
                    '"source/directories/@{}" entry of the publisher file does not',
                    "exist. Check the spelling, create the necessary directory, or entirely",
                    'remove the whole "source/directories" element of the publisher file.'
                ]
            )
            # attribute absent => None
            if gen_attr in attributes_dict.keys():
                raw_path = attributes_dict[gen_attr]
                if os.path.isabs(raw_path):
                    raise ValueError(abs_path_error.format(gen_attr, raw_path))
                else:
                    abs_path = os.path.join(source_dir, raw_path)
                try:
                    generated = verify_input_directory(abs_path)
                except:
                    raise ValueError(missing_dir_error.format(abs_path, raw_path, gen_attr))
            # attribute absent => None
            if ext_attr in attributes_dict.keys():
                raw_path = attributes_dict[ext_attr]
                if os.path.isabs(raw_path):
                    raise ValueError(abs_path_error.format(ext_attr, raw_path))
                else:
                    abs_path = os.path.join(source_dir, raw_path)
                try:
                    external = verify_input_directory(abs_path)
                except:
                    raise ValueError(missing_dir_error.format(abs_path, raw_path, ext_attr))
    # pair of discovered absolute paths
    return (generated, external)


def get_platform_host(pub_file):
    '''Reports the html/platform/@host value from the publication file'''

    # "web": the default
    # "runestone": electing to host on a Runestone server

    # NB: this interrogates the publisher file as authored, and provides
    # a default value if not explicitly set otherwise. Thus, very different
    # from  get_publisher_variable()  and a bit dangerous if the publisher
    # file computations change.  In use by the PreTeXt-CLI to ascertain a
    # Runestone build. (2024-09-25)

    if not(pub_file):
        return "web"

    pub_tree = ET.parse(pub_file)
    pub_tree.xinclude()
    element_list = pub_tree.xpath("/publication/html/platform")
    if not(element_list):
        return "web"

    # assume at most one, schema may enforce
    platform = element_list[0]
    attrs = platform.attrib
    if not('host') in attrs:
        return "web"

    return attrs['host']


def copy_managed_directories(build_dir, external_abs=None, generated_abs=None):
    # Copies external and generated directories from absolute paths set in external_abs
    # and generated_abs (unless set to None) into a build directory.  Since the
    # build directory is fresh for each build, these directories should not exist
    # in advance and the  shutil.copytree()  function should raise an error.
    if external_abs is not None:
        external_dir = os.path.join(build_dir, "external")
        shutil.copytree(external_abs, external_dir)

    if generated_abs is not None:
        generated_dir = os.path.join(build_dir, "generated")
        shutil.copytree(generated_abs, generated_dir)


def copy_html_js(work_dir):
    '''Copy all necessary CSS and JS into working directory'''

    # Place support files where expected.
    # We are not careful about placing only modules that are needed, all are copied.
    js_src = os.path.join(get_ptx_path(), "js")
    js_dest = os.path.join(work_dir, "_static", "pretext", "js")
    shutil.copytree(js_src, js_dest)

    # 2024-01-18: may migrate these resources up to "js"
    js_lib_src = os.path.join(get_ptx_path(), "js_lib")
    js_lib_dest = os.path.join(work_dir, "_static", "pretext", "js", "lib")
    shutil.copytree(js_lib_src, js_lib_dest)


def copy_build_directory(build_dir, dest_dir):
    '''Copy final product from build directory into desired destination directory'''

    # Both directories exist when this is called.
    # build_dir is a temporary directory we have created
    # dest_dir will have been error-checked once specified

    # 2024-01-17:  It is tempting to replace this function by
    # shutil.copytree().  As of Python 3.8, this function allows
    # the destination directory to exist beforehand, but will
    # replace the permissions with those of the  build_dir.
    # When the build_dir is a temporary directory, the permissions
    # are 700 which was problematic.  We also choose not to
    # touch, in any way, the permissions on whatever directory is
    # given as the destination.
    #
    # So instead, we iterate over the top level of the build
    # directory and copy files and directories there individually.

    for filename in os.listdir(build_dir):
        src = os.path.join(build_dir, filename)
        if os.path.isfile(src):
            shutil.copy2(src, dest_dir)
        elif os.path.isdir(src):
            dest = os.path.join(dest_dir, filename)
            # repeated builds may land in the same place,
            # so allow directories to clobber existing ones
            shutil.copytree(src, dest, dirs_exist_ok=True)
        else:
            msg = "the build directory {} contained an unexpected object, {}"
            log.debug(msg.format(build_dir, src))


def targz(output, source_dir):
    """Creates a zipped tar file, output; the root of the archive has a single folder, source_dir"""
    import tarfile

    with tarfile.open(output, "w:gz") as tar:
        tar.add(source_dir, arcname=os.path.basename(source_dir))

@contextlib.contextmanager
def working_directory(path):
    """
    Temporarily change the current working directory.

    Usage:
    with working_directory(path):
        do_things()   # working in the given path
    do_other_things() # back to original path
    """
    current_directory = os.getcwd()
    os.chdir(path)
    log.debug(f"Now working in directory {path}")
    try:
        yield
    finally:
        os.chdir(current_directory)
        log.debug(f"Successfully changed directory back to {current_directory}")


def get_publisher_variable_report(xml_source, pub_file, params):
    """Parse the pubfile and return a dict containing the variables"""

    # IMPORTANT: to report the value of a (computed) publisher variable,
    # two related routines are involved.  For a variable not previously
    # supported, a developer must take action to implement a report. The
    # XSL in the "utilities/report-publisher-variable.xsl" stylesheet must
    # include the report of a value, which will be captured in a temporary
    # file to be read by the Python routine "get_publisher_variable_report()".

    # NB: this will always be consistent with what *is computed* from
    # the publisher file.  An eception is given by the  get_platform_host()
    # routine, which directly examines the authored file. (2024-09-25)

    # NB: there may not be a publication file (pub_file = None)
    # Variables are still computed and should have reasonable default values
    log.debug("parsing the publisher file variables")

    # to ensure provided stringparams aren't mutated unintentionally
    params = params.copy()

    if pub_file:
        params["publisher"] = pub_file

    # construct filename for the XSL to report variable/value pairs
    reporting_xslt = os.path.join(get_ptx_xsl_path(), "utilities","report-publisher-variables.xsl")
    # Short-circuit the assembly (pre-processor) stylesheet to only
    # make the "version" tree.  This is as much as is needed for the
    # determination of the publisher variables and will be significantly
    # faster (by a factor of 15 or so wuih the sample article.  So every
    # place we call "get_publisher_variable_report()" will see a reduction
    # in time.   "assembly.version-only" is defined in pretext-assembly.xsl,
    # which is im[ported by the stylesheet just defined.
    params["assembly.version-only"] = "yes"

    # file to receive result of stylesheet
    tmp_dir = get_temporary_directory()
    log.debug("temporary directory for publisher variables: {}".format(tmp_dir))
    temp_file = os.path.join(tmp_dir, "pub_var.txt")
    log.debug("file of publisher variables: {}".format(temp_file))

    # Apply the stylesheet, with source and publication file
    xsltproc(reporting_xslt, xml_source, temp_file, None, params)

    # parse file into a dictionary
    variables = {}
    with open(temp_file, 'r') as f:
        for line in f:
            parts = line.split()
            # careful: value could be empty string,
            # then split() returns 1 part only
            if len(parts) == 1:
                variables[parts[0]] = ''
            else:
                # value could have spaces, so rejoin other parts
                variables[parts[0]] = " ".join(parts[1:])

    return variables


def get_publisher_variable(variable_dict, variable_name):
    """Get a computed publisher-variable's value via variable name"""

    # Actually parsing the pub file is relatively expensive, so callers must do that
    # and pass the resulting dict to this function, hopefully retaining the dict
    # for any other calls within the scope of the computed dictionary.

    log.debug("determining value of publisher variable '{}'".format(variable_name))

    if variable_name in variable_dict:
        return variable_dict[variable_name]
    else:
        msg = '\n'.join(["the publisher variable '{}' could not be located.",
                        "Did you spell it correctly or does it need implementation?",
                        "If the latter, read instructions in code comments in the relevant routines."])
        raise ValueError(msg.format(variable_name))


def get_journal_info(journal_name):
    """
    Returns a dictionary of data for a journal based on
    a master list of journals in journals/journals.xml.
    """
    journal_xml = os.path.join(get_ptx_path(), "journals", "journals.xml")
    log.debug("Reading list of journals in {}".format(journal_xml))
    journals_tree = ET.parse(journal_xml)
    journals_tree.xinclude()
    # Find the node with <code> value journal_name:
    try:
        journal = journals_tree.xpath(f"//journal[code='{journal_name.lower()}']")[0]
    except Exception as e:
        log.warning("The journal name {} specified in the publication file is not supported.".format(journal_name))
        return {"latex-style": ""}
    keys = ["name", "code", "latex-style", "publisher"]
    journal_info = {}
    for key in keys:
        if journal.find(key) is not None:
            journal_info[key] = journal.find(key).text
    return journal_info


###########################
#
#  Module-level definitions
#
###########################

# One-time set-up for global use in the module
# Module provides, and depends on these variables,
# whose scope is the module, so must be declared
# by employing routines as non-local ("global")
#
#  __xml_header - standard first line of an XML file.
#                 a convenience here
#
#  __ptx_path - root directory of installed PreTeXt distribution
#              necessary to locate stylesheets and other support
#
#  __config - parsed values from an INI-style configuration file
#
#  __temps - created temporary directories, to report or release
#
#  __module_warning - stock import-failure warning message

# NB: some uses of this module last for longer than processing
# just one document, for example, on Runestone Academy when
# building many books at once with the CLI.  These variables
# then also have a long life, and so some care needs to be
# exercised that they do not contain document-specific information.

# Convenience
__xml_header = '<?xml version="1.0" encoding="UTF-8"?>\n'

# Discover and set distribution path once at start-up
__ptx_path = None
set_ptx_path()

# Configuration as a dictionary
__executables = None

#  cache of temporary directories
__temps = []
