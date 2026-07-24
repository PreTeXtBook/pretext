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
# 2026-07-06: this module expects Python 3.10 or newer
#     FileInput(..., encoding="utf-8") added, required Python 3.10
#     stack.py: str.removeprefix(), str.removesuffix() requires Python 3.9
# 2023-10-13: this module expects Python 3.8 or newer
#     shutil.copytree now has dirs_exist_ok argument
# 2021-05-21: this module expects Python 3.6 or newer
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

# gdscript needs
import pathlib

import time

# cleanup multiline strings used as source code
import textwrap

# * For non-standard packages (such as those installed via PIP) try to keep
#   dependencies to a minimum by *not* importing at the module-level
#   (with justified exceptions)
#
# * For non-standard packages always import within a try/except block
#   and use the provided warning message for failures
#
# * The "requests" module would be a candidate for a module-level
#   import but we prefer to leave it as an optional dependency

# ----------------------------------------------------------------------
# 2026 module split: the lengthy WeBWorK and STACK routines, and the
# shared low-level helpers, were moved out of this file into siblings.
# The import graph is strictly one-way, so there are no import cycles:
#
#     common.py        - imports nothing from its siblings
#       ^  ^  ^
#       |  |  +---- pretext.py  (this file)
#       |  +------- stack.py
#       +---------- webwork.py
#
#   "webwork" and "stack" import only "common".
#   "pretext" imports all three; it imports "webwork"/"stack" only to
#   re-export their public names (see end of file), so the public
#   ptx.NAME interface used by the driver script is unchanged.
#
# "common" holds the canonical __module_warning; we alias it here so the
# import guards below and existing bare references keep working.
# ----------------------------------------------------------------------
from . import common
__module_warning = common.__module_warning
from . import webwork
from . import stack
from . import godot_helper

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


def mathjax_latex(xml_source, pub_file, out_file, dest_dir, math_format, math_cross_references):
    """Convert PreTeXt source to a structured file of representations of mathematics"""
    # formats:  'svg', 'mml', 'nemeth', 'speech', 'kindle'
    # Internal calls will specify out_file with complete path
    # External calls might only specify a destination directory
    import fileinput  # for &nbsp; fix

    log.info("converting LaTeX from {} into {} format".format(xml_source, math_format))
    log.debug("converting LaTeX from {} into {} format".format(xml_source, math_format))

    # construct filenames for pre- and post- XSL stylesheets in xsl/support
    extraction_xslt = os.path.join(common.get_ptx_xsl_path(), "support/extract-math.xsl")
    cleaner_xslt = os.path.join(common.get_ptx_xsl_path(), "support/package-math.xsl")

    # Extraction stylesheet makes a simple, mock web page for MathJax
    # And MathJax executables preserve the page while changing the math
    tmp_dir = common.get_temporary_directory()
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
    # a single-file target (XSL-FO/PDF) can ask that cross-references
    # inside mathematics become active internal links (an SVG "a")
    if math_cross_references:
        params["math.cross-references"] = "yes"
    if pub_file:
        params["publisher"] = pub_file
    common.xsltproc(extraction_xslt, xml_source, mjinput, None, params)
    # Trying to correct baseline for inline math in Kindle, so we
    # insert a \mathstrut into all the inline math before feeding to MathJax
    if math_format == "kindle":
        # fileinput's in-place mode rewrites each file line by line: print() writes
        # back onto the file, and end="" suppresses the extra newline it would add
        # (the line already carries its own).  Two Windows pitfalls handled here:
        #   - the "with" context manager closes the handle before the file is
        #     reopened/replaced, which otherwise raises a PermissionError (PR #1779)
        #   - encoding="utf-8" reads/writes UTF-8 rather than the locale default,
        #     which would mis-decode UTF-8 math/HTML on a cp1252 locale (PR #3003)
        with fileinput.FileInput(mjinput, inplace=True, encoding="utf-8") as file:
            for line in file:
                print(line.replace(r"\(", r"\(\mathstrut "), end="")

    # shell out to process with MathJax/SRE node program
    msg = (
        "calling MathJax to convert LaTeX from {} into raw representations as {} in {}"
    )
    log.debug(msg.format(mjinput, math_format, mjoutput))

    # process with  pretext.js  executable from  MathJax (Davide Cervone, Volker Sorge)
    node_exec_cmd = common.get_executable_cmd("node")
    mjsre_page = os.path.join(common.get_ptx_path(), "script", "mjsre", "mj-sre-page.js")
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
    with common.working_directory(tmp_dir):
        html_file = mjoutput
        # fileinput's in-place mode rewrites each file line by line: print() writes
        # back onto the file, and end="" suppresses the extra newline it would add
        # (the line already carries its own).  Two Windows pitfalls handled here:
        #   - the "with" context manager closes the handle before the file is
        #     reopened/replaced, which otherwise raises a PermissionError (PR #1779)
        #   - encoding="utf-8" reads/writes UTF-8 rather than the locale default,
        #     which would mis-decode UTF-8 math/HTML on a cp1252 locale (PR #3003)
        with fileinput.FileInput(html_file, inplace=True, encoding="utf-8") as file:
            for line in file:
                print(xhtml_elt.sub(repl, line), end="")

    # clean up and package MJ representations, font data, etc
    derivedname = common.get_output_filename(
        xml_source, out_file, dest_dir, "-" + math_format + ".xml"
    )
    log.debug(
        "packaging math as {} from {} into XML file {}".format(
            math_format, mjoutput, out_file
        )
    )
    common.xsltproc(cleaner_xslt, mjoutput, derivedname)
    log.info("XML file of math representations deposited as {}".format(derivedname))


##############################################
#
#  Graphics Language Extraction and Processing
#
##############################################

def prefigure_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat, ext_converter):
    """Extract PreFigure code for diagrams and convert to graphics formats"""
    # ext_converter: an optinal hook for external libraries to patch
    #                the conversion of individual images.  The intent is that ext_converter
    #                attempts to use a cached version of the image, or else calls
    #                individual_prefigure_conversion() to generate the image (and cache it).
    #
    # stringparams is a dictionary, best for lxml parsing
    import glob

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    msg = 'converting PreFigure diagrams from {} to {} graphics for placement in {}'
    log.info(msg.format(xml_source, outformat.upper(), dest_dir))

    tmp_dir = common.get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    ptx_xsl_dir = common.get_ptx_xsl_path()
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

    common.xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)

    # Resulting prefigure files are in tmp_dir, switch there to work
    with common.working_directory(tmp_dir):
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

        # Need to copy entire "external" directory
        # Also data (e.g. for plots) is made available
        # NB: we might really do this sooner, but then all
        # the files in "external" and "data" get added
        # into the list of source files, pf_source_files
        _, external_dir = common.get_managed_directories(xml_source, pub_file)
        data_dir = common.get_source_directories(xml_source)
        common.copy_managed_directories(tmp_dir, external_abs=external_dir, data_abs=data_dir)

        # make output/tactile directory if the outformat is "all"
        # PreFigure makes 'output' but we also want to create 'output/tactile'
        if outformat == "all":
            os.mkdir('output')
            os.mkdir('output/tactile')

        # Process each pf_source_file for requested format
        for pfdiagram in pf_source_files:
            if ext_converter:
                ext_converter(pfdiagram, outformat, tmp_dir)
            else:
                individual_prefigure_conversion(pfdiagram, outformat)

        # Check to see if we made some diagrams before copying the tree
        if os.path.exists('output'):
            log.info("copying PreFigure output to {}".format(dest_dir))
            shutil.copytree(
                'output',
                dest_dir,
                dirs_exist_ok=True
            )

def individual_prefigure_conversion(pfdiagram, outformat):
    # We need to import prefig for this function.  Okay that we do it for each
    # diagram; python will cache the module after the first import.
    try:
        import prefig
    except ImportError:
        raise ImportError(__module_warning.format("prefig"))

    if outformat == "tactile" or outformat == "all":
        # THe tactile outformat produces a pdf, but is different from the pdf outformat.
        # After producing the output, it must be moved to the tactile subdirectory.
        # NB we must do this before the pdf outformat option to avoid overwriting the regular pdf.
        log.info("compiling PreFigure source file {} to tactile PDF".format(pfdiagram))
        prefig.engine.pdf('tactile', pfdiagram)
        pdf_name = pfdiagram[:-4] + '.pdf'
        shutil.move('output/'+pdf_name, 'output/tactile/'+pdf_name)

    if outformat == "svg" or outformat == "all":
        log.info("compiling PreFigure source file {} to SVG".format(pfdiagram))
        prefig.engine.build('svg', pfdiagram)

    if outformat == "pdf" or outformat == "all":
        log.info("compiling PreFigure source file {} to PDF".format(pfdiagram))
        prefig.engine.pdf('svg', pfdiagram, dpi=100)

    if outformat == "png" or outformat == "all":
        log.info("compiling PreFigure source file {} to PNG".format(pfdiagram))
        prefig.engine.png('svg', pfdiagram)



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
        raise ImportError(__module_warning.format("requests"))

    msg = 'converting Asymptote diagrams from {} to {} graphics for placement in {} with method "{}"'
    log.info(msg.format(xml_source, outformat.upper(), dest_dir, method))

    # front-ends and calling routines should guarantee the following
    if not (method in ["local", "server"]):
        raise ValueError(
            "{} is not a method for Asymptote diagram generation".format(method)
        )

    tmp_dir = common.get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    ptx_xsl_dir = common.get_ptx_xsl_path()
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
    common.xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    # Resulting *.asy files are in tmp_dir, switch there to work
    with common.working_directory(tmp_dir):
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
                asy_executable_cmd = common.get_executable_cmd("asy")
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
                    asy_cli += ["-noprc", "-offscreen", "-tex", "xelatex", "-batchMask"]
                elif outform in ["svg", "png"]:
                    asy_cli += ["-render=4", "-tex", "xelatex", "-offscreen"]
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
    tmp_dir = common.get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    sage_executable_cmd = common.get_executable_cmd("sage")
    # TODO why this debug line? get_executable_cmd() outputs the same debug info
    log.debug("sage executable: {}".format(sage_executable_cmd[0]))
    ptx_xsl_dir = common.get_ptx_xsl_path()
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
    common.xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    with common.working_directory(tmp_dir):
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
    tmp_dir = common.get_temporary_directory()
    log.debug("temporary directory for latex-image conversion: {}".format(tmp_dir))
    ptx_xsl_dir = common.get_ptx_xsl_path()
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
    _, external_dir = common.get_managed_directories(xml_source, pub_file)
    data_dir = common.get_source_directories(xml_source)
    common.copy_managed_directories(tmp_dir, external_abs=external_dir, data_abs=data_dir)
    # now create all the standalone LaTeX source files
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-latex-image.xsl")
    # no output (argument 3), stylesheet writes out per-image file
    common.xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    # now work in temporary directory
    with common.working_directory(tmp_dir):
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
        latex_key = common.get_deprecated_tex_fallback(method)
        tex_executable_cmd = common.get_executable_cmd(latex_key)
        # TODO why this debug line? get_executable_cmd() outputs the same debug info
        log.debug("tex executable: {}".format(tex_executable_cmd[0]))
        latex_cmd = tex_executable_cmd + ["-interaction=nonstopmode", "-halt-on-error", latex_image]
        log.info("converting {} to {}".format(latex_image, latex_image_pdf))
        result = _latex_compile(latex_cmd, latex_image_log, latex_image, capture_output=True)

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
            log.debug(result.stdout)
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
                pdfeps_executable_cmd = common.get_executable_cmd("pdfeps")
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

    tmp_dir = common.get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    ptx_xsl_dir = common.get_ptx_xsl_path()
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
    common.xsltproc(extraction_xslt, xml_source, the_files, None, stringparams)

    # Copy in external resources (e.g., js code)
    generated_abs, external_abs = common.get_managed_directories(xml_source, pub_file)

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
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-trace.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's, languages, sources into a scratch directory/file
    tmp_dir = common.get_temporary_directory()
    code_filename = os.path.join(tmp_dir, "codelens.txt")
    log.debug("Program sources for traces temporarily in {}".format(code_filename))
    common.xsltproc(extraction_xslt, xml_source, code_filename, None, stringparams)
    # get trace file contents minus trailing blank line
    with open(code_filename, "r") as code_file:
        contents = code_file.read().rstrip()

    if contents == "":
        log.info("no traces found to generate in {}".format(code_filename))
        return

    # special line separates groups
    program_groups = contents.split("!end_codelens_trace_group!")
    # will be one extra empty group, remove it
    program_groups.pop()
    for program_group in program_groups:
        lines = program_group.split("\n")
        visible_id = lines[0]
        runestone_id = lines[1]
        if runestone_id.strip() == "":
            log.error("No runestone_id found for visible_id {}. Codelens must have a label or be the child of exercise like element with a label.".format(visible_id))
            continue
        trace_filename = lines[2]
        language = lines[3]
        source = lines[4]
        starting_instruction = int(lines[5])
        questions = lines[6:]

        if language == 'python':
            url = url_string.format('py')
        else:
            # c, cpp, java
            url = url_string.format(language)
        # instead use  .decode('string_escape')  somehow
        # as part of reading the file?
        source = source.replace("\\n", "\n")
        log.info("converting {} source {} to tracefile {}...".format(language, visible_id, trace_filename))

        # success will replace this empty string
        trace = ""
        if (language == "c") or (language == "cpp"):
            try:
                r = requests.post(url, data=dict(src=source), timeout=30)
                if r.status_code == 200:
                    trace = r.text[r.text.find('{"code":') :]
            except Exception as e:
                log.debug(traceback.format_exc())
                log.error(server_error_msg.format(url, visible_id))
        elif language == "java":
            try:
                r = requests.post(url, data=dict(src=source), timeout=30)
                if r.status_code == 200:
                    trace = r.text
            except Exception as e:
                log.debug(traceback.format_exc())
                log.error(server_error_msg.format(url, visible_id))
        elif language == "python":
            try:
                r = requests.post(url, data=dict(src=source), timeout=30)
                if r.status_code == 200:
                    trace = r.text
            except Exception as e:
                log.debug(traceback.format_exc())
                log.error(server_error_msg.format(url, visible_id))

        # should now have a trace, except for timing out
        # no trace, then do not even try to produce a file
        if trace:
            import json
            trace_dict = json.loads(trace)
            # add startingInstruction to the trace
            trace_dict["startingInstruction"] = starting_instruction
            # inject questions into trace
            if questions:
                trace_steps = trace_dict.get("trace")
                for question in questions:
                    if question.strip() == '':
                        continue
                    question_line, answer_raw, feedback, prompt = question.split(":||:")
                    question_line = int(question_line)
                    answer_type, answer_value = answer_raw.split("-", 2)
                    question_dict = {
                      "text": prompt,
                      ("correctText" if answer_type == "literal" else "correct"): answer_value
                    }
                    if feedback:
                        question_dict['feedback'] = feedback

                    for trace_step in trace_steps:
                        if trace_step['line'] == question_line and trace_step['event'] == "step_line":
                            trace_step['question'] = question_dict
            trace = json.dumps(trace_dict)

            # We will hardcode in the ID based on the runestone_id as built. It will be a fallback.
            # But also try to dynamically grab the ID of the containing codelens so
            # Eventually we could maybe deprecate the hardcoded value.
            script_template = """
                if (allTraceData === undefined) {{
                    var allTraceData = {{}};
                }}
                (function() {{ // IIFE to avoid variable collision
                    let codelensID = "{}";  //fallback
                    let partnerCodelens = document.currentScript.parentElement.querySelector(".pytutorVisualizer");
                    if (partnerCodelens) {{
                        codelensID = partnerCodelens.id;
                    }}
                    allTraceData[codelensID] = {};
                }})();"""
            script_template = textwrap.dedent(script_template)
            trace = script_template.format(runestone_id, trace.rstrip())
            trace_file = os.path.join(dest_dir, trace_filename)
            with open(trace_file, "w") as f:
                f.write(trace)


################################
#
#  Dynamic Exercise Static Representations
#
################################
def dynamic_substitutions(xml_source, pub_file, stringparams, xmlid_root, dest_dir, ext_rs_methods):
    # Standard reference locations
    ptx_dir = common.get_ptx_path()
    ptx_xsl_dir = common.get_ptx_xsl_path()
    node_exec_cmd = common.get_executable_cmd("node")
    # Identify resource files to process dynamic exercises
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-dynamic.xsl")
    script = os.path.join(ptx_dir, "script", "dynsub", "dynamic_extract.mjs")
    # Where to store the results
    dyn_subs_file = os.path.join(dest_dir, "dynamic_substitutions.xml")

    # Make a copy of stringparams to modify
    stringparams = stringparams.copy()

    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Always act as though web is the target
    stringparams["host-platform"] = "web"

    # Build temporary json file to include how each dynamic problem is setup
    # and all of the substitutions that will be required
    tmp_dir = common.get_temporary_directory()
    json_file = os.path.join(tmp_dir, "dynamic-setup.json")
    log.info("Creating temporary dynamic exercise setup JSON: {}".format(json_file))
    common.xsltproc(extraction_xslt, xml_source, json_file, tmp_dir, stringparams)

    # Use Node (Deno) to process the JSON to create the XML substitution file
    log.info("Generating substitutions.")
    import subprocess
    try:
        result = subprocess.run(
            node_exec_cmd + [
            # The next two arguments would be used for permissions when change to deno
            #"--allow-read={}".format(json_file),
            #"--allow-write={}".format(dyn_subs_file),
            script,
            "--input={}".format(json_file),
            "--output={}".format(dyn_subs_file)
            ],
            capture_output=True, text=True
        )
        # See if successful (empty stdout)
        if (len(result.stderr) > 0):
            log.error(f"Dynamic substitution process failed: {result.stderr}")
    except Exception as e:
        root_cause = str(e)
        msg = ("PTX:ERROR:   There was a problem generating dynamic substitutions.\n")
        raise ValueError(msg + root_cause)

################################
#
#  WeBWorK Extraction Processing
#
################################



################################
#
#  WeBWorK Problem Sets
#
################################




################################
#
#  WeBWorK PG Macro Library
#
################################



############################################################
#
#  References and Citations via Citation Stylesheet Language
#
############################################################

# A helper function to clean up references and Citations
# Likely preferable to use a CiteProc formatter object
def _pretextify(biblio):
    """Convert a string from CiteProc light HTML markup to PreTeXt internal markup"""

    # biblio: some string formated by the CiteProc HTML formatter
    # Return: string with better PreTeXt (internal) markup

    # italics
    biblio = re.sub(r'<i>', r'<pi:italic>', biblio)
    biblio = re.sub(r'</i>', r'</pi:italic>', biblio)
    # bold
    biblio = re.sub(r'<b>', r'<pi:bold>', biblio)
    biblio = re.sub(r'</b>', r'</pi:bold>', biblio)
    # Unicode en dash, U+2013, e.g. for date ranges
    # Escape sequence only, not "raw" r
    biblio = re.sub('\u2013', r'<ndash/>', biblio)
    # TODO: curly quotes as left/right pair/group
    # THEN as left/right characters, U+201C, U+201D
    biblio = re.sub('\u201C', r'<lq/>', biblio)
    biblio = re.sub('\u201D', r'<rq/>', biblio)

    return biblio


def references(xml_source, pub_file, stringparams, xmlid_root, dest_dir):

    ### Verify need for CSL processing ###
    #
    # * Examine publisher file, get string for CSL file name
    # * Use of CSL styles in "opt-in", condition here
    # * Abandon with an error message if not possible

    # Compute publisher variable report one time, collecting results
    pub_vars = common.get_publisher_variable_report(xml_source, pub_file, stringparams)
    # style file name selected by the publisher, no path information
    # citeproc-py looks in their DATAPATH/STYLES_PATH = data/styles
    # so place by a given style file by hand right now
    # Call below does not need an extension, so we do not supply it
    csl_style = common.get_publisher_variable(pub_vars, 'csl-style-file')
    # XSL "value-of" for boolean reports strings "true" or "false"
    using_csl_styles = common.get_publisher_variable(pub_vars, 'b-using-csl-styles')

    if using_csl_styles == "false":
        msg = " ".join(["requesting formatted references and citations is not possible",
              "without a CSL style file specified in the publication file.",
              "No action is being taken."])
        log.error(msg)
        # bail out and do not do *anything*
        return

    ### Imports, Constants, Helpers ###
    #
    import json  # parse JSON CSL for cite

    # Requires the "citeproc-py" Python package to do
    # most (all?) of the processing of a citation
    # https://github.com/citeproc-py/citeproc-py

    import citeproc.source.json  # CiteProcJSON
    import citeproc  # CitationStylesStyle, CitationStylesBibliography, formatter, CitationItem, Citation

    # Necessary namespace information for creating
    # a file of bibliographic information later
    # "cs"/CSL might be avoided when we better
    #   understand querying the style with CiteProc
    XML = "http://www.w3.org/XML/1998/namespace"
    PI = "http://pretextbook.org/2020/pretext/internal"
    CSL = "http://purl.org/net/xbiblio/csl"
    NSMAP = {"xml": XML, "pi": PI, "cs": CSL}

    # callback for non-existent citation
    # copied from citeproc-py example
    def warn(citation_item):
        log.warning("PTX:WARNING: Reference with key '{}' not found in the bibliography."
          .format(citation_item.key))

    ### XSL Stylesheet To Analyze Author's Source Bibliography ###
    #
    # * xsl/extract-biblio-csl.xsl
    # * JSON blob of "biblio" information, indexed by biblio/@xml:id
    # * Note that author's markup (e.g. "m" in a title) was converted
    #   to text as it entered the JSON blob
    # * Space separated list of xref/@ref, indexed by xref/@xml:id,
    #   only when the xref/@ref points to backmatter/references/biblio

    stringparams = stringparams.copy()

    if pub_file:
        stringparams["publisher"] = pub_file
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-biblio-csl.xsl")

    # And a place to work and a file there for result tree
    tmp_dir = common.get_temporary_directory()
    biblio_xml = os.path.join(tmp_dir, "biblio-csl.xml")

    # Harvest bibliographic items and citations, converted to JSON
    common.xsltproc(extraction_xslt, xml_source, biblio_xml, None, stringparams)

    # parse for lxml access
    biblio_tree = ET.parse(biblio_xml)

    ### Initialize CSL Style File ###
    #
    # * Examine publisher file, get string for CSL file name
    # * Needs to be moved manually to <cite-proc>/data/styles
    # * Need to automate placing the style file
    # * We interrogate the punctuation of citations

    # Initialize use of the chosen style
    style = citeproc.CitationStylesStyle(csl_style, validate=False)

    # The citepoc-py "CitationStylesStyle" object is derived ultimately
    # from an lxml Element Tree in a "xml" property of the object.  We
    # can inspect this as needed, but there are better ways provided by
    # the package.  Still, we preserve a bit of code that was functional
    # on 2025-05-29 in case an example is useful later.  The
    # CSL  /style/citation/layout  XML element has children that describe
    # how a citation is rendered.  Compare this with ways to access
    # (and manipulate!) these elements below.
    #
    # style_layout = style.xml.xpath("/cs:style/cs:citation/cs:layout", namespaces=NSMAP)[0]
    # citation_punct = style_layout.attrib
    # if "prefix" in citation_punct:
    #     prefix = citation_punct["prefix"]
    # else:
    #     prefix = ""

    # Some aspects of styles are not supported
    # and some influence behavior later.

    # style/@class: "in-text" or "note"
    style_class = style.root.get("class")
    # Bail-out on a value we do not know
    if not(style_class in ["in-text", "note"]):
        msg = " ".join(['The requested CSL style file ("{}") has a /style/@class',
                        'attribute value ("{}") we do not recognize.',
                        'No action is being taken.'])
        log.error(msg.format(csl_style, style_class))
        return
    # Bail-out for footnote/endnote styles
    if style_class == "note":
        msg = " ".join(['The requested CSL style file ("{}") uses a footnote/endnote',
                        'style for citations, which PreTeXt does not yet support.',
                        'No action is being taken.'])
        log.error(msg.format(csl_style))
        return


    # We need to know about a "numeric" style later
    # style/info/category/@citation-format: "numeric", "author-date", "note"
    style_citation_format = style.root.info.category.get("citation-format")
    # Bail-out on a value we do not know
    if not(style_citation_format in ["numeric", "author-date", "note"]):
        msg = " ".join(['The requested CSL style file ("{}") has a'
                        '/style/info/category/@citation-format',
                        'attribute value ("{}") we do not recognize.',
                        'No action is being taken.'])
        log.error(msg.format(csl_style, style_citation_format))
        return
    is_numeric = (style_citation_format == "numeric")

    """
    Typical CSL XML structure for the suffix used with numeric
    identification, for example
        "6. "    ->  ". "
        "[6]"    ->  "]"
        "(6)  "  ->  ")  "

    <bibliography entry-spacing="0" second-field-align="flush">
        <layout suffix=".">
            <text variable="citation-number" prefix="[" suffix="]"/>
    """

    # Assume reference is identified numerically until shown otherwise.
    # If numeric, grab the "suffix" to help with parsing out numeric
    # identification is loosely structured/formatted output from the
    # cite processor.
    numeric_suffix = None
    if is_numeric:
        layout_element  = style.xml.xpath("/cs:style/cs:bibliography/cs:layout/cs:text[@variable = 'citation-number']", namespaces=NSMAP)[0]
        numeric_suffix = layout_element.get("suffix")


    ### Import JSON References to CiteProc ###
    #
    # "references" collects a single overall JSON blob of the
    # PTX "references" backmatter division. We "load" the json
    # and feed it to the CiteProcJSON constructor
    # lxml makes a list of length 1, which we massage some

    references_blob = biblio_tree.xpath("/pi:pretext-biblio-csl/pi:biblio-csl", namespaces=NSMAP)
    json_raw = references_blob[0].text
    json_parsed = json.loads(json_raw)
    # Process the JSON data to generate a citeproc-py BibliographySource.
    references_source = citeproc.source.json.CiteProcJSON(json_parsed)
    # Initialize a CitationStylesBibliography with a style,
    # the internalized source, and a formatter.  You would think
    # we had nicely formatted reference items now. No, we need
    # to supply the actual citations
    references = citeproc.CitationStylesBibliography(style, references_source, citeproc.formatter.html)
    # You would think we had nicely formatted reference items now.
    # No, we need to supply the actual citations since their
    # appearance and order affects the references.  For example,
    # if a reference is never cited, it does not appear in the
    # references.

    ### Citations ###
    #
    # * Retrieve citations/xref from analysis of author's source,
    #   as a space separated list of @ref that point to "biblio"
    # * Per citation/xref make a list of CitationItem that
    #   correspond to the @ref values/ids.
    # * Wrap as a Citation object representing a multi-target
    #   citation from the author.
    # * Register each one with the CiteProc references (bibliography)

    citation_xref = biblio_tree.xpath("/pi:pretext-biblio-csl/pi:xref-csl", namespaces=NSMAP)

    # citations/xref never get sorted until part of a
    # multi-part overall citation.  Here are two useful
    # parallel Python lists we can make now and use later

    # A citation has an @xml:id on an originating xref, it is
    # the @id attribute in the XML derived from the author's source
    xref_ids = [c.attrib["id"] for c in citation_xref]

    # Each citation is a list, @ref in author's source of the
    # values of @xml:id on the biblio.  XML has a space-separated list
    xref_refs = [c.text.split() for c in citation_xref]

    # Now make CiteProc objects, and register
    citeproc_citations = []
    for ref_list in xref_refs:
        citeproc_citation_items = []
        for ref in ref_list:
            citeproc_citation_items.append(citeproc.CitationItem(ref))
        citeproc_citation = citeproc.Citation(citeproc_citation_items)
        citeproc_citations.append(citeproc_citation)
        # CiteProc *must* see a Citation() being registered.
        references.register(citeproc_citation)

    ### References formatted ###
    #
    # * Sort the references since we will eventually absorb "biblio"
    #   from an external BibTeX-like file. And have no real control
    #   over ordering.  Presumably different styles will have different
    #   sort orders.
    # * Replace resuts of HTML formatter with PreTeXt internal
    #   non-semantic font-changing markup.  And other sensible
    #   PreTeXt markup.
    # * Eventually we will have an integrated formatter
    # * Wrap up as "csl-biblio" elements to pass into PreTeXt

    # Here is the formatted version: a string representation of each reference
    # Author's XML is here still and is still text.
    # Note: attributes the pre-processor added are being capitalized?
    # str() is necessary here, and results are strings, not objects [checked]
    # Note markup conversion from CiteProc HTML to "internal" PreTeXt (mostly)
    references.sort()
    references_formatted = [_pretextify(str(item)) for item in references.bibliography()]


    # references.keys gets sorted along, since these are the biblio/@xml:id,
    # so we can continue to track the sorted version of the references
    # for references with numeric identifiers, we split that identifier
    # off as an attribute, which presumes it has no markup
    references_wrapped = []
    biblio_pattern = '<pi:csl-biblio numeric="{}" xml:id="{}" xmlns:{}="{}">{}</pi:csl-biblio>'
    for k, rf in zip(references.keys, references_formatted):
        numeric = ""
        if numeric_suffix:
            numeric, rf = rf.split(numeric_suffix, 1)
            numeric = numeric + numeric_suffix
            #(strip down numeric trailing whitespace?)

        # references are text right now, we make a proper
        # snippet of XML that can be parsed by the lxml
        # "fromstring()" function into an ET element object.
        # "xml" namespace seems to be known to lxml anyway
        references_wrapped.append(biblio_pattern.format(numeric, k, "pi", PI, rf))

    ### Citations formatted ###
    #
    # Now the formatted versions of the citations.  These are multi-part,
    # which is going to be a big problem, as we want each part to be
    # realized as a cross-refeence in various outputs as hyperlinks, knowls, etc.

    #  Strategy
    #  We will get back from CiteProc citations that might look like
    #
    #    (Brown, et al. 2025, Blue 1933)
    #
    #  and we want to turn them into PreTeXt source that looks like
    #
    #    (<xref ref="brown-paper">Brown, et al. 2025</xref>, <xref ref="blue-book">Grey 1933</xref>)
    #
    #  Not only is it hard to reliably find the separator (", ") but
    #  the actual citations get re-ordered from whatever order the
    #  actual "xref" are made.  So..
    #
    #  We first *replace* the separator, so we can reliably split
    #  the multi-part citation, and then we mimic the sorting operation

    # A faux separator on citations, which should be so rare
    # that we can reliably match it.  Linux mkpasswd of "beezer"
    rare = "P1zXvPN5SACeY"

    # citeproc.py has a slew of objects that encapsulate parts of
    # the CSL XML specification. These can be located from our
    # style variable via a hierarchy from the root. Here we get
    # the layout for citations, to retrieve the overall formatting
    # of citation AND we make a change, by *inserting* our rare
    # separator (delimiter).
    layout = style.root.citation.layout
    prefix = layout.get("prefix", "")
    real_delimiter = layout.get("delimiter", "")
    suffix = layout.get("suffix", "")
    layout.set("delimiter", rare)

    # Similarly citeproc-py has a "sort" *object* inside
    # "citation" which in turn has an optional "sort" object,
    # which has a "sort" method
    citation = style.root.citation
    sorter = citation.sort

    # Here we go, we collect formatted citations
    citations_wrapped = []
    solo_xref_pattern = '<xref ref="{}" pi:custom-text="yes" xmlns:{}="{}">{}</xref>'
    citation_pattern = '<pi:csl-citation xml:id="{}" xmlns:{}="{}">{}</pi:csl-citation>'
    for c, xref_id in zip(citeproc_citations, xref_ids) :
        # version with rare separator
        # strip the prefix and suffix,
        # and blow it up into pieces
        rough = references.cite(c, warn)
        rough = rough[len(prefix):-len(suffix)]
        rough = rough.split(rare)

        # get the permutation from the re-ordering
        # this is all borrowed from the Layout Class
        # and its render_citation() method
        cites = c.cites
        # generic sort on keys, this is the "natural" order
        # of the appearnce in the sorted bibliography
        cites.sort(key=lambda x: references.keys.index(x.key))
        # but if there is a sorting specified, do that
        if sorter is not None:
            cites = sorter.sort(cites, layout)
        one_citation = []
        for text_cite, cite_cite in zip(rough, cites):
            ptx_cite = solo_xref_pattern.format(cite_cite.key, "pi", PI, text_cite)
            one_citation.append(ptx_cite)
        a_cite = _pretextify(prefix + real_delimiter.join(one_citation) + suffix)
        a_cite = citation_pattern.format(xref_id, "pi", PI, a_cite)
        citations_wrapped.append(a_cite)

    ### Produce Useful XML ###
    #
    # * Build up a simple XML tree from pieces above
    # * Make available as a generated product to be saved
    # * Components will be assembled into source, as
    #   replacements of backmatter/references and xref

    # Root element of produced XML file, "pi:csl-references"
    csl_references = ET.Element(ET.QName(NSMAP["pi"], "csl-references"), nsmap=NSMAP)
    # Somewhat like "versioning" a file, set an attribute
    # (@csl-style-file) on the root element of the file.
    # In the XSL processing this can be compared to the
    # value from the current publication file as a check
    # that production and consumption are in-sync at the
    # time of consumption.  The Python string here was
    # determined at the time of production (i.e. now).
    csl_references.set("csl-style-file", csl_style)

    index = 1
    for rw in references_wrapped:
        biblio_tree = ET.fromstring(rw)
        csl_references.insert(index, biblio_tree)
        index = index + 1
    # not sure how to *start* with next_child,
    # so keep index running for more insertions
    for cw in citations_wrapped:
        xref_tree = ET.fromstring(cw)
        csl_references.insert(index, xref_tree)
        index = index + 1

    # Fill an XML file with the  csl_references  tree
    bib_file = os.path.join(dest_dir, "csl-bibliography.xml")

    try:
        with open(bib_file, "wb") as f:
            f.write(ET.tostring(csl_references, encoding="utf-8",
                    xml_declaration=True, pretty_print=True))
    except Exception as e:
        root_cause = str(e)
        msg = "PTX:ERROR: there was a problem writing a references file: {}\n"
        raise ValueError(msg.format(f) + root_cause)


##############################
#
#  GDScript interactive packing
#
##############################

def gd_pack(source_dir, dest_zip_file, pack_name,version):
    source_path = pathlib.Path(source_dir).resolve()
    try:
        godot_cmd = common.get_executable_cmd("godot")
    except Exception as e:
        log.error("{}".format(e))
        godot_cmd = "godot"

    godot_cmd = godot_helper.resolve_godot(godot_cmd,version)
    godot_helper.ensure_export_templates(version)

    PROJECT_FILENAME = "project.godot"
    EXPORTS_FILENAME  = "export_presets.cfg"
    EXPORT_FILENAME  = "export_preset.cfg"
    # Work on a disposable copy of the project so we never modify source_dir.
    tmp_dir = common.get_temporary_directory()
    log.debug("temporary directory for Godot pack build: {}".format(tmp_dir))
    shutil.copytree(source_path, tmp_dir, dirs_exist_ok=True)

    source_config_path = os.path.join(tmp_dir,"practice_solutions",pack_name,EXPORT_FILENAME)

    # Define the destination path for the config file in the project folder
    target_config_path = os.path.join(tmp_dir, EXPORTS_FILENAME)
    # Define the destination path for the project file in the project folder
    target_project_path = os.path.join(tmp_dir, PROJECT_FILENAME)

    godot_template_path = os.path.join(get_ptx_path(), "pretext","lib","godot")
    template_project_path = os.path.join(godot_template_path,PROJECT_FILENAME)
    shutil.copy2(source_config_path,target_config_path)
    shutil.copy2(template_project_path,target_project_path)

    # dry run: Godot needs this pass to build/import files that are
    # missing before it can export the pack in the step below.
    command = [
        godot_cmd,
        "--headless",
        "--path", tmp_dir,
        "--editor",
        "--quit"
    ]

    # Execute the command
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    # Check for success or failure of dry run
    if result.returncode == 0:
        log.info("Trial successful!")
        log.info(result.stdout)
        log.info(result.stderr)
    else:
        log.error("Trial failed. Godot Output:")
        log.error(result.stdout)
        log.error(result.stderr)
        raise OSError(result.stderr)
    command = [
        godot_cmd,
        "--headless",
        "--path", tmp_dir,
        "--export-pack", pack_name,
        dest_zip_file
    ]

    # Execute the command
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    # Check for success or failure
    if result.returncode == 0:
        log.info("Export successful! File saved to: {}".format(dest_zip_file))
        log.info(result.stdout)
        log.info(result.stderr)
    else:
        log.error("Export failed. Godot Output:")
        log.error(result.stdout)
        log.error(result.stderr)
        raise OSError(result.stderr)

def gdscript_pck(xml_source, pub_file, stringparams, xmlid_root, dest_dir):
    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()
    source_dir = common.get_source_path(xml_source)
    log.info(
        "exporting GDScript interactives from {} for placement in {}".format(
            source_dir, dest_dir
        )
    )
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-gdscript.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = common.get_temporary_directory()
    id_filename = os.path.join(tmp_dir, "gdscript-ids.txt")
    log.debug("GDScript id list temporarily in {}".format(id_filename))
    # this builds the gdscript names
    common.xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)
    # "run" an assignment for the list of quads of strings
    with open(id_filename, "r") as id_file:
        # read lines, but only lines that are comma delimited
        quads = [p.strip() for p in id_file.readlines() if "," in p]
    for quad in quads:
        src = path = name = version = None
        try:
            # first item is destination name, second item is source,
            # third item is scene to derive export name
            quad_a = quad.split(",")
            src = os.path.join(source_dir,quad_a[1])
            # this is the path to the destination file
            path = os.path.join(dest_dir, quad_a[0] + ".zip")
            # split third item on path separator
            parts = quad_a[2].split("/")
            # the second to last part should be the problem name
            name = parts[-2]
            # get the version
            version = quad_a[3]
            log.info("exporting {} as {} using {} ...".format(src, path, name))
            gd_pack(src, path,name,version)
        except Exception as e:
            log.error(
                "GDScript pack export failed for quad {} "
                "(src={}, dest={}, pack_name={}, version={}): "
                "{}: {}".format(
                    quad, src, path, name, version,
                    type(e).__name__, e
                )
            )
            log.debug(traceback.format_exc())

    log.info("GDScript pck exporting complete")


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
        raise ImportError(__module_warning.format("requests"))

    log.info(
        "downloading YouTube thumbnails from {} for placement in {}".format(
            xml_source, dest_dir
        )
    )
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-youtube.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = common.get_temporary_directory()
    id_filename = os.path.join(tmp_dir, "youtube-ids.txt")
    log.debug("YouTube id list temporarily in {}".format(id_filename))
    common.xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)
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

    ptx_xsl_dir = common.get_ptx_xsl_path()
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
        pub_vars = common.get_publisher_variable_report(xml_source, pub_file, stringparams)
        image = common.get_publisher_variable(pub_vars, 'qrcode-image')
        _, external_dir = common.get_managed_directories(xml_source, pub_file)
        image_path = os.path.join(external_dir, image)
        if (image != '' and os.path.exists(image_path)):
            has_image = True
    except:
        pass

    # https://pypi.org/project/qrcode/
    try:
        import qrcode  # YouTube server
    except ImportError:
        raise ImportError(__module_warning.format("qrcode"))

    import qrcode.image.styledpil

    log.info(
        "manufacturing QR codes from {} for placement in {}".format(
            xml_source, dest_dir
        )
    )
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-qrcode.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    import xml.etree.ElementTree as ET

    # Extraction writes a sidecar XML file per element (via exsl:document,
    # holding the standalone and in-context URLs) and returns a manifest of
    # exactly the elements that earn a QR code in the current document or
    # subtree.  Iterating that manifest, rather than whatever "*-url.xml"
    # files happen to be in dest_dir, ensures a stale sidecar (from an
    # element since relabeled or removed) cannot spawn a QR code.
    pi_ns = {'pi': 'http://pretextbook.org/2020/pretext/internal'}
    manifest = common.xsltproc(extraction_xslt, xml_source, None, dest_dir, stringparams)
    for entry in manifest.getroot().findall('pi:qrcode', pi_ns):
        the_id = entry.get('id')
        url_file = os.path.join(dest_dir, the_id + "-url.xml")
        tree = ET.parse(url_file)
        url = tree.find('pi:standalone-url', pi_ns).text
        path = os.path.join(dest_dir, the_id + ".png")
        log.info('creating URL with content "{}" as {}...'.format(url, path))
        # Using more elaborate (class) calls to simply get a zero border,
        # rather than cropping (ala https://stackoverflow.com/questions/9870876)
        # Simple version: qr_image = qrcode.make(url), has border
        if has_image:
            # error correction up to 30%
            # 2025-08-29: upgraded, as "Q" produces fatal errors
            error_correction = qrcode.constants.ERROR_CORRECT_H
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
            qr_image = qr.make_image(image_factory=qrcode.image.styledpil.StyledPilImage, embedded_image_path=image_path)
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

def mermaid_images(xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat):

    import glob  # locate *.mmd files
    import json  # Mermaid configuration files

    msg = 'converting Mermaid diagrams from {} to {} graphics for placement in {}'
    log.info(msg.format(xml_source, outformat, dest_dir))

    mmd_executable_cmd = common.get_executable_cmd("mermaid")
    log.debug("Mermaid executable command: {}".format(mmd_executable_cmd))

    tmp_dir = common.get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    ptx_xsl_dir = common.get_ptx_xsl_path()
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
    common.xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)

    pub_vars = common.get_publisher_variable_report(xml_source, pub_file, stringparams)
    mermaid_theme = common.get_publisher_variable(pub_vars, 'mermaid-theme')
    mermaid_layout_engine = common.get_publisher_variable(pub_vars, 'mermaid-layout-engine')

    # Resulting *.mmd files are in tmp_dir, switch there to work
    with common.working_directory(tmp_dir):
        # Write a config file as JSON in working directory
        mmd_config = {
            "theme": mermaid_theme,
            "layout": mermaid_layout_engine
        }
        mmd_config_file = os.path.join(tmp_dir, "mermaid-config.json")
        with open(mmd_config_file, 'w') as config_file:
            json.dump(mmd_config, config_file, indent=4)
        log.debug("Mermaid configuration file: {}".format(mmd_config_file))
        # mmdc switches output on the filename extension; there is nothing
        # to do for a format it cannot produce.  Guard once, before the
        # loop, so every iteration below has a valid output filename.
        if outformat not in ["png", "svg"]:
            log.error("cannot make Mermaid diagrams in {} file format".format(outformat))
            return
        # loop over each diagram
        for mmddiagram in glob.glob(os.path.join(tmp_dir, "*.mmd")):
            filebase, _ = os.path.splitext(mmddiagram)
            mmdout = "{}.{}".format(filebase, outformat)
            mmd_cmd = mmd_executable_cmd + ["-i", mmddiagram, "-o", mmdout, "-s", "4", "-c", "mermaid-config.json"]
            log.debug("mermaid conversion command: {}".format(" ".join(mmd_cmd)))
            subprocess.call(mmd_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
            if os.path.exists(mmdout):
                shutil.copy2(mmdout, dest_dir)
            else:
                msg = "the Mermaid output {} was not built"
                log.warning(msg.format(mmdout))


#####################################
#
#  STACK exercises (static)
#
#####################################









#####################################
#
#  Interactive preview screenshotting
#
#####################################


def preview_images(xml_source, pub_file, stringparams, xmlid_root, dest_dir, method):
    """
    Generate preview images for interactive elements using playwright.
    'method' is expected to be "fast" or "slow", corresponding to a 5000 or 10000 ms timeout.
    """
    import asyncio  # get_event_loop()

    # external module, often forgotten
    # imported here, used only in interior
    # routine to launch browser
    try:
        import playwright.async_api  # launch()
    except ImportError:
        raise ImportError(__module_warning.format("playwright"))

    # Interior asynchronous routine to manage the Chromium headless browser.
    # Use the same page instance for the generation of all interactive previews
    async def generate_previews(interactives, baseurl, dest_dir, timeout):

        # interactives:  list containing the interactive hash/fragment ids [1:]
        # baseurl:       local server's base url (includes local port)
        # dest_dir:      folder where images are saved
        # timeout:       delay in milliseconds to wait for the interactive to load

        # Open playwright's asynchronous api to load a browser and page
        async with playwright.async_api.async_playwright() as pw:
            browser = await pw.chromium.launch()
            page = await browser.new_page()
            # One uncooperative interactive should warn and be skipped, not
            # abort the whole batch.  "fail_ms" bounds how long we wait on a
            # broken interactive before abandoning it; it is separate from the
            # fast/slow settle delay below, which paces a working interactive.
            fail_ms = 5000
            failures = []
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

                try:
                    # goto page and wait for content to load
                    await page.goto(input_page, wait_until='domcontentloaded', timeout=fail_ms)
                    # wait again, according to the value of the timeout,
                    # for more than just splash screens, etc
                    await page.wait_for_timeout(timeout)
                    # list of locations, need first (and only) one
                    elt = page.locator(xpath)
                    await elt.screenshot(path=filename, scale="css", timeout=fail_ms)
                    # copy
                    shutil.copy2(filename, dest_dir)
                except Exception as e:
                    failures.append(preview_fragment)
                    msg = 'could not capture a preview image for the interactive with identifier "{}" ({}); a static substitute will be used'
                    log.error(msg.format(preview_fragment, type(e).__name__))
            if failures:
                msg = '{} of {} interactive preview images captured; none produced for: {}'
                log.error(msg.format(len(interactives) - len(failures), len(interactives), ", ".join(failures)))
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

    # Translate the fast/slow timeout to a time in milliseconds
    timeout = 10000 if method == "slow" else 5000

    # Identify interactives that will be processed
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-interactive.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = common.get_temporary_directory()
    id_filename = os.path.join(tmp_dir, "interactives-ids.txt")
    log.debug("Interactives id list temporarily in {}".format(id_filename))
    log.debug("Interactives html files temporarily in {}".format(tmp_dir))
    # This next call may be unique in that the stylesheet outputs the
    # list of ids *and* produce a pile of files (the "standalone") pages
    common.xsltproc(extraction_xslt, xml_source, id_filename, tmp_dir, stringparams)
    # read the list of interactive identifiers just generated
    with open(id_filename, "r") as id_file:
        interactives = [f.strip() for f in id_file.readlines() if not f.isspace()]

    # Copy in external resources (e.g., js code)
    _, external_abs = common.get_managed_directories(xml_source, pub_file)
    common.copy_managed_directories(tmp_dir, external_abs=external_abs)
    # place JS in scratch directory
    copy_html_js(tmp_dir)

    # filenames lead to placement in current working directory
    # so change to temporary directory, and copy out
    # TODO: just write to "dest_dir"?
    with common.working_directory(tmp_dir):
        # event loop and copy, terminating server process even if interrupted
        try:
            log.debug("Starting event loop for playwright, after starting server")
            port, server = start_server()
            baseurl = "http://localhost:{}".format(port)
            asyncio.run(generate_previews(interactives, baseurl, dest_dir, timeout))
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
    has_gdscript = bool(src_tree.xpath("/pretext/*[not(docinfo)]//program[@pck and @interactive='activecode']"))
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
    generated_dir, _ = common.get_managed_directories(xml, pub_file)

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

    # gdscript pck
    #
    if has_gdscript:
        dest_dir = os.path.join(generated_dir, "gdscript", "")
        if not (os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        # call gdscript_pck
        gdscript_pck(xml, pub_file, stringparams, xmlid_root, dest_dir)

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
    import PIL.Image # save images provided by MOM
    import shutil
    import asyncio # for playwright

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    try:
        import requests  # to access MyOpenMath server
    except ImportError:
        raise ImportError(__module_warning.format("requests"))
    try:
        import playwright.async_api # for conversion to PDF and PNG
    except ImportError:
        raise ImportError(__module_warning.format("playwright"))

    log.info(
        "downloading MyOpenMath static problems from {} for placement in {}".format(
            xml_source, dest_dir
        )
    )
    ptx_xsl_dir = common.get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-mom.xsl")
    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build list of id's into a scratch directory/file
    tmp_dir = common.get_temporary_directory()
    id_filename = os.path.join(tmp_dir, "mom-ids.txt")
    log.debug("MyOpenMath id list temporarily in {}".format(id_filename))
    common.xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)
    images_dir = os.path.join(dest_dir, 'images')
    if not (os.path.isdir(images_dir)):
        os.mkdir(images_dir)
    # "run" an assignment for the list of problem numbers
    with open(id_filename, "r") as id_file:
        # read lines, skipping blank lines
        problems = [p.strip() for p in id_file.readlines() if not p.isspace()]

    for problem in problems:
        # &preservesvg=true is MOM flag to preserve embedded SVG
        url = f"https://www.myopenmath.com/util/mbx.php?id={problem}&preservesvg=true"
        path = os.path.join(dest_dir, f"mom-{problem}.xml")
        log.info(f"downloading MOM #{problem} to {path}...")

        try:
            r = requests.get(url, timeout=10)
            r.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)

            xml_content = f'<?xml version="1.0" encoding="utf-8"?>\n{r.text}'
            xml_content = xml_content.replace('<myopenmath', '<myopenmath xmlns:pi="http://pretextbook.org/2020/pretext/internal"')
            tree = ET.fromstring(xml_content.encode("utf-8"))

            # Process images
            image_elements = tree.xpath("//image[contains(@source, 'http')]")
            count = 1
            for image_element in image_elements:
                image_url = image_element.get("source")
                image_url_parsed = urllib.parse.urlparse(image_url)
                source_filename = os.path.basename(image_url_parsed.path)
                _, source_ext = os.path.splitext(source_filename)
                if source_ext:
                    image_filename = f'mom-{problem}-{count}{source_ext}'
                # uncertain this is necessary: MOM won't likely allow file without extension
                else:
                    image_filename = f'mom-{problem}-{count}'
                    log.info(f'No file name extension for MOM {problem} image {count}; results are unpredictable.')
                imageloc = f'problems/images/{image_filename}'
                image_path = os.path.join(images_dir, image_filename)

                try:
                    imageresp = requests.get(image_url, stream=True, timeout=10)
                    imageresp.raise_for_status()
                    # save the image file
                    with open(image_path, "wb") as imagefile:
                        imageresp.raw.decode_content = True
                        shutil.copyfileobj(imageresp.raw, imagefile)
                    # find the width of the image for setting PreTeXt width tag
                    try:
                        img = PIL.Image.open(image_path)
                        imgwidthtag = min(100, round(img.width / 6))
                        img.close()
                        image_element.set("width", "{}%".format(imgwidthtag))
                    except Exception as e:
                        log.error("Unable to read image width of {}: {}".format(image_path, e))

                    del image_element.attrib["source"]
                    image_element.set("{http://pretextbook.org/2020/pretext/internal}generated", imageloc)
                except requests.exceptions.RequestException as e:
                    log.error(f"Error downloading image {image_url}: {e}")
                count += 1

            # Process embedded SVGs
            image_svg_elements = tree.xpath("//image/*[local-name()='svg']")
            for svg_element in image_svg_elements:
                if svg_element is not None:
                    svg_string = f'<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n{ET.tostring(svg_element, encoding="unicode")}'
                    # kludge: no nice way to remove namespace inherited from MyOpenMath element
                    svg_string = svg_string.replace(' xmlns:pi="http://pretextbook.org/2020/pretext/internal"','')
                    # generate file names for image files
                    svgname = f'images/mom-{problem}-{count}'
                    svgname_ext = f'{svgname}.svg'
                    svgpath = os.path.join(dest_dir, svgname_ext)
                    pdfname_ext = f'{svgname}.pdf'
                    pdfpath = os.path.join(dest_dir, pdfname_ext)
                    pngname_ext = f'{svgname}.png'
                    pngpath = os.path.join(dest_dir, pngname_ext)

                    # write out the embedded SVG to file
                    with open(svgpath, 'w', encoding='utf-8') as svgfile:
                        svgfile.write(svg_string)
                        svgfile.close()

                    # SVG width and height needed for PDF conversion and PreTeXt <image>
                    # Note that these are assumed to be present, if not, fix the SVG image in MOM
                    svg_width = svg_element.get('width')
                    svg_height = svg_element.get('height')
                    svg_viewbox = svg_element.get('viewBox')
                    svg_width_parsed = re.search(r"([0-9\.]+)([a-zA-Z%]*)",svg_width)
                    svg_height_parsed = re.search(r"([0-9\.]+)([a-zA-Z%]*)",svg_height)
                    if svg_width:
                        svg_units = svg_width_parsed.group(2).lower()
                        # assume that width and height have the same units

                    width = svg_width
                    height = svg_height
                    if svg_units == '%':
                        # if height or width is in percentage fall back to viewBox
                        height = None
                        width = None
                    elif svg_units == 'pt':
                        # playwright doesn't support pt units, transform to px
                        height = str(float(svg_height_parsed.group(1)) / 72 * 96) + 'px'
                        width = str(float(svg_width_parsed.group(1)) / 72 * 96) + 'px'

                    if (not height or not width) and svg_viewBox:
                        viewBox_values = svg_viewbox.split(' ')
                        height = str(float(viewBox_values[3]) - float(viewBox_values[1])) + 'px'
                        width = str(float(viewBox_values[2]) - float(viewBox_values[0])) + 'px'

                    async def write_pdf(svg_string):
                        # convert SVG to PDF and PNG
                        static_html = f'''
                        <!DOCTYPE html>
                        <html lang="en">
                        <head>
                            <meta charset="utf-8" />
                            <meta name="viewport" content="width=device-width,initial-scale=1" />
                            <style>
                            /* prevent page breaks after svg */
                            * {{
                                margin:0;
                                padding:0;
                                white-space:nowrap;
                                overflow: hidden;
                                line-height: 0;
                            }}
                            </style>
                            </head>
                        <body>
                        {svg_string}
                        </body>
                        </html>'''

                        async with playwright.async_api.async_playwright() as pw:
                            browser = await pw.chromium.launch()
                            page = await browser.new_page()
                            await page.set_content(static_html)
                            await page.pdf(path=pdfpath, width=width, height=height)
                            await page.locator("svg").screenshot(path=pngpath,scale="device")

                            await browser.close()

                    # convert to PDF; asyncio.run requires a synchronous caller
                    # and raises if a containing tool already runs an event loop
                    asyncio.run(write_pdf(svg_string))

                    # Try to read the SVG width and set PreTeXt width based on document width assumptions
                    if svg_width_parsed:
                        if svg_units:
                            if svg_units=="mm":
                                svg_scale = 158.8
                            elif svg_units=="cm":
                                svg_scale = 15.88
                            elif svg_units=="in":
                                svg_scale = 6.25
                            else:
                                svg_scale = 600
                            imgwidthtag = min(100, round(100*float(svg_width_parsed.group(1)) / svg_scale))
                        else:
                            # this condition should never happen: implies badly formed width element
                            imgwidthtag = 100
                    else:
                        imgwidthtag = 100
                    svg_element.getparent().set("width", f"{imgwidthtag}%")
                    # update the <image> element in MyOpenMath xml to reference the file
                    svg_element.getparent().set("{http://pretextbook.org/2020/pretext/internal}generated", f'problems/{svgname}')
                    svg_element.getparent().remove(svg_element)

                    count += 1

            # Write the modified XML back to file
            with open(path, "wb") as f:
                f.write(ET.tostring(tree, encoding="utf-8", xml_declaration=True))

        except requests.exceptions.RequestException as e:
            log.error(f"Error downloading MOM #{problem}: {e}")
        except ET.XMLSyntaxError as e:
            log.error(f"Error parsing XML for MOM #{problem}: {e}")
        except Exception as e:
            log.error(f"An unexpected error occurred for MOM #{problem}: {e}")

    log.info("MyOpenMath static problem download complete")


####################
# Conversion to Text
####################


def text(xml, pub_file, stringparams, out_file, dest_dir, text_format):
    """
    Convert XML source to a plain text or markdown rendering.

    Args:
        xml (str): Path to the XML source file.
        pub_file (str or None): Path to the publisher configuration file, or None if not used.
        stringparams (dict): Dictionary of string parameters to control the transformation.
        out_file (str or None): Path to the output file.  If None, the file lands in dest_dir.
        dest_dir (str): Directory for the output file when out_file is not specified.
        text_format (str): "text", "markdown", or "markdown-zip", naming the
            stylesheet and the file extension.  The last bundles a markdown
            rendering (with its image directories) as a single zip file.

    Returns:
        None

    Side Effects:
        - Generates a text (or markdown) file in the specified destination.
    """

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # support publisher file, not subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file

    text_format_stylesheets = {
        "text": "pretext-text.xsl",
        "markdown": "pretext-markdown.xsl",
        "markdown-zip": "pretext-markdown.xsl",
    }
    text_format_extensions = {
        "text": ".txt",
        "markdown": ".md",
        "markdown-zip": ".md",
    }

    msg = "converting {} to {} format in {}"
    log.info(msg.format(xml, text_format, dest_dir))

    conversion_xslt = os.path.join(
        common.get_ptx_xsl_path(), text_format_stylesheets[text_format]
    )
    # A zip bundle is staged in a temporary directory, inside a folder
    # named for the source, so the archive unpacks tidily
    b_zip = text_format == "markdown-zip"
    if b_zip:
        basename = os.path.splitext(os.path.basename(xml))[0]
        staging_parent = common.get_temporary_directory()
        work_dir = os.path.join(staging_parent, basename)
        os.mkdir(work_dir)
    else:
        work_dir = dest_dir
    # One transform serves both shapes of output.  A positive chunking
    # election (common/chunking/@level in the publication file) makes
    # the stylesheet write one file per division into the working
    # directory and leave the result tree empty; otherwise the result
    # tree is the entire rendering, deposited as a single file
    result_tree = common.xsltproc(conversion_xslt, xml, None, work_dir, stringparams)
    if str(result_tree):
        derivedname = common.get_output_filename(
            xml, None if b_zip else out_file, work_dir, text_format_extensions[text_format]
        )
        result_tree.write_output(derivedname)
        log.info("{} file deposited as {}".format(text_format, derivedname))
    else:
        log.info("{} files deposited in {}".format(text_format, work_dir))
    # Markdown references image files with relative paths matching the
    # HTML conversion, so the managed directories ride along
    if text_format in ("markdown", "markdown-zip"):
        generated_abs, external_abs = common.get_managed_directories(xml, pub_file)
        if external_abs:
            shutil.copytree(
                external_abs, os.path.join(work_dir, "external"), dirs_exist_ok=True
            )
        if generated_abs:
            shutil.copytree(
                generated_abs, os.path.join(work_dir, "generated"), dirs_exist_ok=True
            )
    if b_zip:
        zip_filename = shutil.make_archive(
            os.path.join(dest_dir, basename), "zip", staging_parent, basename
        )
        log.info("markdown bundle deposited as {}".format(zip_filename))


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
    tmp_dir = common.get_temporary_directory()
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
    mathjax_latex(xml_source, pub_file, math_representations, None, math_format, False)

    # use XSL to make a simplified BRF-like XML version, "preprint"
    msg = "converting source ({}) and clean representations ({}) into preprint XML file ({})"
    stringparams["mathfile"] = math_representations.replace(os.sep, "/")
    # pass in the page format (for messages about graphics, etc.)
    stringparams["page-format"] = page_format
    if pub_file:
        stringparams["publisher"] = pub_file
    preprint = os.path.join(tmp_dir, "preprint.xml")
    braille_xslt = os.path.join(common.get_ptx_xsl_path(), "pretext-braille-preprint.xsl")
    common.xsltproc(braille_xslt, xml_source, preprint, tmp_dir, stringparams)

    # use Python to translate all print text to contracted braille,
    # then to format the result as a real BRF
    from . import braille_translate
    from . import braille_format

    # Translate the preprint: all print text becomes UEB braille,
    # one liblouis call per stretch of text, typeforms and all
    translated = os.path.join(tmp_dir, "translated.xml")
    msg = "translating print text of preprint ({}) into braille ({})"
    log.debug(msg.format(preprint, translated))
    braille_translate.translate_document(preprint, translated)

    # Build a BRF in the *temporary* directory: final or chunkable
    temp_brf = os.path.join(tmp_dir, "temporary.brf")
    # Python formatting call
    braille_format.parse_segments(translated, temp_brf, page_format)

    # move out of temporary directory as final product(s)
    # chunk level is either '0' or '1' (exclusive "if" follow)
    if chunk_level == '0':
        # monolithic file
        final_brf = common.get_output_filename(xml_source, out_file, dest_dir, ".brf")
        shutil.copyfile(temp_brf, final_brf)
        log.info("Single BRF file deposited as {}".format(final_brf))
    if chunk_level == '1':
        # chunked into chapters
        # directory switch could be moved to split routine,
        # or it could be done in temporary directory and copied out
        with common.working_directory(dest_dir):
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


def _sanitize_svg_for_epub(directory):
    """Rewrite SVG images beneath a directory into EPUB-legal form

    EPUB forbids a document type declaration with an external
    identifier, and the external entity declarations riding along in
    an SVG 1.1 DOCTYPE (Sage, and some editors, produce these).
    Parsing and re-serializing sheds the DOCTYPE.  Two content
    repairs ride along, for defects observed from image generators:
    a "path" with no data draws nothing but is a validity error, so
    it is removed; and a "role" attribute on the root must be one of
    the three values EPUB sanctions for a foreign resource, so any
    other value becomes "img".
    """
    import glob

    parser = ET.XMLParser(load_dtd=False, no_network=True, resolve_entities=False)
    for svg_file in glob.glob(os.path.join(directory, "**", "*.svg"), recursive=True):
        try:
            tree = ET.parse(svg_file, parser=parser)
        except Exception:
            log.warning("could not parse {} to sanitize it for EPUB; it will be employed unchanged and may cause validation errors".format(svg_file))
            continue
        root = tree.getroot()
        svg_namespace = "http://www.w3.org/2000/svg"
        xlink_namespace = "http://www.w3.org/1999/xlink"
        # fragments referenced within the image, so an (empty) target
        # is never removed out from under a "use" reference
        referenced = set()
        for element in root.iter():
            for key in ["{{{}}}href".format(xlink_namespace), "href"]:
                value = element.get(key)
                if value and value.startswith("#"):
                    referenced.add(value[1:])
        for path in root.iter("{{{}}}path".format(svg_namespace)):
            if not path.get("d"):
                if path.get("id") in referenced:
                    # an empty-but-referenced path is a legitimate
                    # no-op (a font's space glyph, say) but the
                    # attribute is required, so draw nothing, validly
                    path.set("d", "M0 0")
                else:
                    parent = path.getparent()
                    if parent is not None:
                        parent.remove(path)
        # a "name" attribute is not valid on any SVG element
        # (mermaid decorates shapes with them)
        for element in root.iter("{{{}}}*".format(svg_namespace)):
            if element.get("name") is not None:
                del element.attrib["name"]
        if root.get("role") and root.get("role") not in ["application", "document", "img"]:
            root.set("role", "img")
        # serializing the root element omits the document type
        # declaration; serializing the whole document would write
        # back the declaration lxml recorded when reading the file
        with open(svg_file, "wb") as handle:
            handle.write(ET.tostring(root, xml_declaration=True, encoding="utf-8"))


def epub(xml_source, pub_file, out_file, dest_dir, file_format, math_format, stringparams):
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
    tmp_dir = common.get_temporary_directory()
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

    source_dir = common.get_source_path(xml_source)
    epub_xslt = os.path.join(common.get_ptx_xsl_path(), "pretext-epub.xsl")
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
    mathjax_latex(xml_source, pub_file, math_representations, None, math_format, False)
    # optionally, build a file of speech versions of the math
    if math_format == "svg":
        log.debug(msg.format(xml_source, "speech", speech_representations))
        mathjax_latex(xml_source, pub_file, speech_representations, None, "speech", False)

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
    common.xsltproc(epub_xslt, xml_source, packaging_file, tmp_dir, {**params, **stringparams})

    # XHTML files lack an overall namespace,
    # while EPUB validation expects it
    # Kindle needs an encoding declaration to avoid assuming ASCII
    # regex inplace to end up with:
    #   <?xml version="1.0" encoding="UTF-8"?>
    #   <html xmlns="http://www.w3.org/1999/xhtml">
    orig = "<html"
    repl = __xml_header + '<html xmlns="http://www.w3.org/1999/xhtml"'
    with common.working_directory(xhtml_dir):
        html_elt = re.compile(orig)
        for root, dirs, files in os.walk(xhtml_dir):
            for fn in files:
                # fileinput's in-place mode rewrites each file line by line: print() writes
                # back onto the file, and end="" suppresses the extra newline it would add
                # (the line already carries its own).  Two Windows pitfalls handled here:
                #   - the "with" context manager closes the handle before the file is
                #     reopened/replaced, which otherwise raises a PermissionError (PR #1779)
                #   - encoding="utf-8" reads/writes UTF-8 rather than the locale default,
                #     which would mis-decode UTF-8 math/HTML on a cp1252 locale (PR #3003)
                with fileinput.FileInput(fn, inplace=True, encoding="utf-8") as file:
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
        css = os.path.join(common.get_ptx_xsl_path(), "..", "css", "dist", "kindle.css")
        shutil.copy2(css, css_dir)
    else:
        css = os.path.join(common.get_ptx_xsl_path(), "..", "css", "dist", "epub.css")
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
            latex_key = common.get_deprecated_tex_fallback("xelatex")
            tex_executable_cmd = common.get_executable_cmd(latex_key)
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
            with common.working_directory(tmp_dir):
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
        except Exception as e:
            msg = 'PTX:BUG: error copying image with sourcename "{}" and filename "{}".  Traceback follows:'
            # traceback.print_exc()
            log.warning(msg.format(sourcename, filename))
            log.warning(traceback.format_exc())

    # staged SVG images arrive as generated, or as an author provides
    # them; neither is guaranteed to satisfy EPUB's restrictions
    _sanitize_svg_for_epub(xhtml_dir)

    # The build/temp directory has a lot of cruft
    # Leave it for the nozip option (debugging)
    # Remove it before zipping
    #
    # cover manufacture (cover.log, cover.aux, etc)
    # os.remove(packaging_file)
    # os.remove(math_representations)

    ##########################################
    # Notes on packaging an EPUB as a ZIP file
    ##########################################

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

    if file_format == 'epub':
        title_file_element = packaging_tree.xpath("/packaging/filename")[0]
        title_file = ET.tostring(title_file_element, method="text").decode("ascii")
        epub_file = "{}-{}.epub".format(title_file, math_format)
        log.info("packaging an EPUB temporarily as {}".format(epub_file))
        with common.working_directory(tmp_dir):
            with zipfile.ZipFile(epub_file, mode="w", compression=zipfile.ZIP_DEFLATED) as epub:
                epub.write("mimetype", compress_type=zipfile.ZIP_STORED)
                for root, dirs, files in os.walk("EPUB"):
                    for name in files:
                        epub.write(os.path.join(root, name))
                for root, dirs, files in os.walk("META-INF"):
                    for name in files:
                        epub.write(os.path.join(root, name))
            derivedname = common.get_output_filename(xml_source, out_file, dest_dir, ".epub")
            log.info("EPUB file deposited as {}".format(derivedname))
            shutil.copy2(epub_file, derivedname)
    elif file_format == 'nozip':
        common.copy_build_directory(tmp_dir, dest_dir)
        msg = 'EPUB build files produced, but not zipped into a single file; results placed in {}'
        log.info(msg.format(dest_dir))
    else:
        msg = 'PTX:BUG: conversion to EPUB got an unrecognized file format ("{}").  No output results.'
        log.warning(msg.format(file_format))


#######################
# Conversion to Jupyter
#######################

def jupyter(xml_source, pub_file, stringparams, file_format, out_file, dest_dir):
    """Produce a collection of Jupyter notebooks, one per chunk

    file_format - 'collection' deposits the files in dest_dir;
                  'zip' bundles them as a single zip file, deposited
                  as out_file, else with a name derived from the
                  source filename
    """

    # The XSL stylesheet writes one XML *description* of a notebook
    # for each chunk of the document: a flat list of "cell" elements
    # holding strings.  Here each description becomes the JSON of a
    # Jupyter notebook via the "nbformat" package, which owns string
    # escaping, cell boilerplate, and conformance with the notebook
    # schema.  Every notebook is validated before it is written.

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    try:
        import nbformat
    except ImportError:
        raise ImportError(__module_warning.format("nbformat"))
    # filename globbing for the notebook descriptions
    import glob

    log.info("converting {} into Jupyter notebooks in {}".format(xml_source, dest_dir))

    tmp_dir = common.get_temporary_directory()
    log.debug("Jupyter notebook manufacture in temporary directory: {}".format(tmp_dir))
    # The notebook descriptions are moved here once converted: out of
    # the shipped product, but preserved for inspection (a temporary
    # directory survives when verbosity is at the debug level)
    description_dir = common.get_temporary_directory()
    log.info("notebook descriptions are retained in {}".format(description_dir))

    if pub_file:
        stringparams["publisher"] = pub_file
    extraction_xslt = os.path.join(common.get_ptx_xsl_path(), "pretext-jupyter.xsl")
    # stylesheet writes "*.ipynb.xml" notebook descriptions, one per
    # chunk, into the scratch directory; the result tree is empty
    common.xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)

    # notebooks reference images relative to their own location
    generated_abs, external_abs = common.get_managed_directories(xml_source, pub_file)
    common.copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs)

    # display names a reader sees in the Jupyter kernel menu
    kernel_display = {"sagemath": "SageMath", "python3": "Python 3"}

    invalid = []
    descriptions = sorted(glob.glob(os.path.join(tmp_dir, "*.ipynb.xml")))
    if not descriptions:
        log.warning("PTX:BUG: the Jupyter conversion produced no notebook descriptions")
    for description in descriptions:
        tree = ET.parse(description)
        root = tree.getroot()
        notebook = nbformat.v4.new_notebook()
        kernel = root.get("kernel")
        notebook.metadata["kernelspec"] = {
            "name": kernel,
            "display_name": kernel_display.get(kernel, kernel),
        }
        for cell in root.iter("cell"):
            source = cell.text if cell.text else ""
            # attributes beyond the cell type are structure recorded
            # by the stylesheet (containing element, its identifier,
            # fragment position); preserve them for tools and themes
            structure = {k: v for k, v in cell.attrib.items() if k != "type"}
            # a special purpose is instruction to this routine,
            # not structure worth preserving in the metadata
            purpose = structure.pop("purpose", None)
            if cell.get("type") == "code":
                new_cell = nbformat.v4.new_code_cell(source)
            else:
                new_cell = nbformat.v4.new_markdown_cell(source)
            if structure:
                new_cell.metadata["pretext"] = structure
            if purpose == "styling":
                # collapse the input in JupyterLab and Notebook (v7+),
                # and hide it entirely in a Jupyter Book build
                new_cell.metadata["jupyter"] = {"source_hidden": True}
                new_cell.metadata["tags"] = ["hide-input"]
                # ship the cell's effect as a pre-rendered output, so
                # a *trusted* notebook is styled on opening, with no
                # execution; the notebook's own security model decides,
                # and an untrusted notebook just offers the cell to run
                html = source.split("\n", 1)[1] if source.startswith("%%html") else source
                new_cell.outputs.append(
                    nbformat.v4.new_output("display_data", data={"text/html": html})
                )
            notebook.cells.append(new_cell)
        # the final filename is the description's, less the "xml" suffix
        notebook_file = os.path.splitext(description)[0]
        try:
            nbformat.validate(notebook)
        except Exception:
            invalid.append(os.path.basename(notebook_file))
            log.error('PTX:BUG: notebook "{}" failed validation.  Traceback follows:'.format(os.path.basename(notebook_file)))
            log.error(traceback.format_exc())
        nbformat.write(notebook, notebook_file)
        # the description does not ship, but is retained for inspection
        shutil.move(description, description_dir)
    log.info("converted {} notebook descriptions, {} failed validation".format(len(descriptions), len(invalid)))

    if file_format == "collection":
        common.copy_build_directory(tmp_dir, dest_dir)
        log.info("Jupyter notebooks deposited in {}".format(dest_dir))
    elif file_format == "zip":
        # working in the temporary directory gets simple paths in the
        # zip file; the model is the HTML bundle above
        with common.working_directory(tmp_dir):
            zip_file = "jupyter-output.zip"
            log.info("packaging a zip file temporarily as {}".format(os.path.join(tmp_dir, zip_file)))
            with zipfile.ZipFile(zip_file, mode="w", compression=zipfile.ZIP_DEFLATED) as bundle:
                for root, dirs, files in os.walk("."):
                    for name in files:
                        # avoid recursively zipping the zip file
                        if name != zip_file:
                            bundle.write(os.path.join(root, name))
            derivedname = common.get_output_filename(xml_source, out_file, dest_dir, ".zip")
            shutil.copy2(zip_file, derivedname)
            log.info("Jupyter notebooks bundled as {}".format(derivedname))
    else:
        msg = 'PTX:BUG: conversion to Jupyter notebooks got an unrecognized file format ("{}").  No output results.'
        log.warning(msg.format(file_format))


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

# Update stringparams with Runestone Services information
def _set_runestone_stringparams(stringparams, rs_js, rs_css, rs_version):
    stringparams["rs-js"] = rs_js
    stringparams["rs-css"] = rs_css
    stringparams["rs-version"] = rs_version

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
        rs_js, rs_css, rs_cdn_url, rs_version, services_xml = _runestone_debug_service_info()
        _set_runestone_stringparams(stringparams, rs_js, rs_css, rs_version)
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
    _set_runestone_stringparams(stringparams, rs_js, rs_css, rs_version)
    return (rs_js, rs_css, rs_cdn_url, rs_version, services_xml)

def _runestone_debug_service_info():
    """Return hardcoded values used for debugging Runestone Services (debug.rs.dev)"""
    rs_js = "prefix-runtime.bundle.js:prefix-runtime-libs.bundle.js:prefix-runestone.bundle.js"
    rs_css = "prefix-runtime-libs.css:prefix-runestone.css"
    rs_cdn_url = None
    rs_version = "dev"
    services_xml = None
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
                common.download_file(rs_cdn_url + services_file_name, services_build_path)
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
    css_src = os.path.join(common.get_ptx_path(), "css", "dist")
    css_dest = os.path.join(tmp_dir, "_static", "pretext", "css")

    src = os.path.join(common.get_ptx_path(), "css", "dist", "theme-{}.css".format(theme_name))
    dest = os.path.join(common.get_ptx_path(), os.path.join(css_dest, "theme.css"))

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

    # map file copied to theme.css.map
    if os.path.exists(src + ".map"):
        shutil.copy(src + ".map", dest + ".map")

    # print-worksheet
    for file in ["print-worksheet.css", "print-worksheet.css.map"]:
        src = os.path.join(css_src, file)
        dest = os.path.join(css_dest, file)
        if os.path.exists(src):
            shutil.copy(src, dest)


# Helper to build a custom version of a theme
def _build_custom_theme(xml, theme_name, theme_opts, tmp_dir):
    ptx_path = common.get_ptx_path()
    script = os.path.join(ptx_path, "script", "cssbuilder", "cssbuilder.mjs")
    css_dest = os.path.join(tmp_dir, "_static", "pretext", "css")

    # if doing building a completely custom theme, update entry-point to include full path as string
    if theme_name == "custom":
        theme_opts['options']['entry-point'] = os.path.join(common.get_source_path(xml), theme_opts['options']['entry-point'])

    # attempt build
    error_message = "Node.js is required to build themes other than default-modern. Make sure it is installed and in your PATH. Then do 'npm install' in the pretext/script/cssbuilder directory. https://pretextbook.org/doc/guide/html/node-and-npm.html"
    try:
        import subprocess, json
        node_exec_cmd = common.get_executable_cmd("node")
        # theme name is prefixed with "theme-" in the cssbuilder script output
        full_name = "theme-{}".format(theme_name)
        log.info("Building custom css theme: " + full_name)
        log.debug("Theme options:" + json.dumps(theme_opts))
        result = subprocess.run(node_exec_cmd + [script, "-t", full_name, "-o", css_dest, "-c", json.dumps(theme_opts)], capture_output=True, timeout=60)
        if result.stdout:
            log.debug(result.stdout.decode().rstrip())
        if result.stderr:
            error_message = result.stderr.decode()
            raise Exception("Failed to build custom theme")
    except Exception as e:
        log.error(error_message)
        raise e

def check_color_contrast(color1, color2):
    try:
        import coloraide
        contrast = coloraide.Color(color1).contrast(color2, method='wcag21')
        if contrast < 4.5:
            log.warning("Color " + color1 + " does not have enough contrast with expected background color " + color2 + ". Contrast ratio is " + str(contrast) + " but should be at least 4.5. Adjust your publisher file html/css/variables to ensure sufficient contrast.")
    except ImportError:
        log.warning("The coloraide module is not available and is necessary for checking color contrast. Install it with 'pip install coloraide' or by using the requirements.txt file.")

def build_or_copy_theme(xml, pub_var_dict, tmp_dir):
    theme_name = common.get_publisher_variable(pub_var_dict, 'html-theme-name')
    theme_opts_json = common.get_publisher_variable(pub_var_dict, 'html-theme-options')
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
            common.get_executable_cmd("node")
            if not os.path.exists(os.path.join(common.get_ptx_path(), "script", "cssbuilder", "node_modules")):
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
    tmp_dir = common.get_temporary_directory()
    pub_vars = common.get_publisher_variable_report(xml_source, publication_file, stringparams)
    build_or_copy_theme(xml_source, pub_vars, tmp_dir)
    common.copy_build_directory(tmp_dir, dest_dir)



def html(xml, pub_file, stringparams, xmlid_root, file_format, extra_xsl, out_file, dest_dir, ext_rs_methods):
    """Convert XML source to HTML files, in destination directory or as zip file"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    log_time_info = stringparams.get("debug.profile", False) == "yes"
    time_logger = Stopwatch("html()", log_time_info)

    # Consult publisher file for locations of images
    generated_abs, external_abs = common.get_managed_directories(xml, pub_file)
    # Consult source for additional files
    data_dir = common.get_source_directories(xml)

    # names for scratch directories
    tmp_dir = common.get_temporary_directory()

    pub_vars = common.get_publisher_variable_report(xml, pub_file, stringparams)
    include_static_files = common.get_publisher_variable(pub_vars, 'b-cdn-resources') != "true"
    time_logger.log("pubvars loaded")

    if include_static_files:
        # interrogate Runestone server (or debugging switches) and populate
        # NB: stringparams is augmented with Runestone Services information
        _place_runestone_services(tmp_dir, stringparams, ext_rs_methods)
    else:
        # even if we don't need static files, we need to set stringparams for
        # Runestone Services information.
        _cdn_runestone_services(stringparams, ext_rs_methods)
    time_logger.log("runestone placed")

    # support publisher file, and subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Build SCORM manifest if requested
    if file_format == "scorm":
        stringparams["html.scorm"] = "yes"
    # Optional extra XSL could be None, or sanitized full filename
    if extra_xsl:
        extraction_xslt = extra_xsl
    else:
        extraction_xslt = os.path.join(common.get_ptx_xsl_path(), "pretext-html.xsl")

    # place managed directories - some of these (Asymptote HTML) are
    # consulted during the XSL run and so need to be placed beforehand
    common.copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs, data_abs=data_dir)
    time_logger.log("managed directories copied")

    if include_static_files:
        # Copy js and css, but only if not building portable html
        # place JS in scratch directory
        copy_html_js(tmp_dir)
        build_or_copy_theme(xml, pub_vars, tmp_dir)
        time_logger.log("css/js copied")

    # Write output into temporary directory
    log.info("converting {} to HTML in {}".format(xml, tmp_dir))
    common.xsltproc(extraction_xslt, xml, None, tmp_dir, stringparams)
    time_logger.log("xsltproc complete")

    if common.get_publisher_variable(pub_vars, 'host-platform') == "runestone":
        log.info("building Runestone page template for {} in {}".format(xml, tmp_dir))
        runestone_page_template_xslt = os.path.join(
            common.get_ptx_xsl_path(), "extract-runestone-page-template.xsl"
        )
        common.xsltproc(runestone_page_template_xslt, xml, None, tmp_dir, stringparams)
        time_logger.log("runestone page template extraction complete")

    if not(include_static_files):
        # remove latex-image generated directories for portable builds
        shutil.rmtree(os.path.join(tmp_dir, "generated", "latex-image"), ignore_errors=True)

    if file_format  == "html":
        # with multiple files, we need to copy a tree
        # see comments at  copy_build_directory()
        # before replacing with  shutil.copytree()
        common.copy_build_directory(tmp_dir, dest_dir)
    elif file_format == "zip" or file_format == "scorm":
        # working in temporary directory gets simple paths in zip file
        with common.working_directory(tmp_dir):
            zip_file = "html-output.zip"
            log.info(
                "packaging a zip file temporarily as {}".format(
                    os.path.join(tmp_dir, zip_file)
                )
            )
            with zipfile.ZipFile(zip_file, mode="w", compression=zipfile.ZIP_DEFLATED) as epub:
                for root, dirs, files in os.walk("."):
                    for name in files:
                        # Avoid recursively zipping the zip file
                        # Small chance we might be clobbering an existing
                        # "html-output.zip" that could be part of a project.
                        # TODO: zip directly into the derivedname below?
                        #       Or, zip into some new temporary directory?
                        if name != zip_file:
                            epub.write(os.path.join(root, name))
            derivedname = common.get_output_filename(xml, out_file, dest_dir, ".zip")
            shutil.copy2(zip_file, derivedname)
            log.info("zip file of HTML output deposited as {}".format(derivedname))
    else:
        raise ValueError("PTX:BUG: HTML file format not recognized")

    time_logger.log("build completed")


def _inline_reveal_resources(html_file, local_dir, reveal_root):
    """Inline CSS/JS resources so a slideshow is a single HTML file"""

    # The slideshow references reveal.js files at a CDN (the
    # "reveal_root" prefix) plus local stylesheets (PreTeXt's own, and
    # any publisher custom CSS).  Each stylesheet "link" becomes a
    # "style" element, each reveal.js "script" reference becomes an
    # inline "script", and font files referenced from within a
    # stylesheet become data: URIs.  Online services (Sage cells, say)
    # are left alone.  Requires a network connection at build time.
    #
    # The replacements are textual, on machine-generated tags of known
    # shape.  A parse-and-reserialize of the whole document damages
    # everything the serializer normalizes (the banner comments ahead
    # of the "html" element, a synthesized Content-Type "meta", the
    # final newline), so the surgery must touch nothing but the tags.

    import base64
    import mimetypes
    import re
    import urllib.parse

    import requests

    # mimetypes may not know modern font types
    font_types = {
        ".woff2": "font/woff2",
        ".woff": "font/woff",
        ".ttf": "font/ttf",
        ".otf": "font/otf",
    }

    def fetch(url):
        # prefer the minified variant the CDN generates on demand
        base, dot, extension = url.rpartition(".")
        candidates = ["{}.min.{}".format(base, extension), url] if dot else [url]
        for candidate in candidates:
            response = requests.get(candidate, timeout=30)
            if response.status_code == 200:
                return response
        raise OSError(
            "failed to retrieve {} while embedding slideshow resources".format(url)
        )

    def embed_css_urls(css_text, css_url):
        # a url(...) reference relative to its stylesheet (a font,
        # typically) becomes a data: URI; absolute references and
        # existing data: URIs are left alone
        def replacement(match):
            reference = match.group(1).strip("'\" ")
            if reference.startswith(("data:", "http:", "https:", "//", "#")):
                return match.group(0)
            target = urllib.parse.urljoin(css_url, reference)
            response = requests.get(target, timeout=30)
            if response.status_code != 200:
                log.warning(
                    "could not retrieve {} referenced by an embedded stylesheet".format(
                        target
                    )
                )
                return match.group(0)
            extension = "." + target.rpartition(".")[2].lower()
            mime = font_types.get(extension) or mimetypes.guess_type(target)[0] or "application/octet-stream"
            encoded = base64.b64encode(response.content).decode("ascii")
            return "url(data:{};base64,{})".format(mime, encoded)

        return re.sub(r"url\(([^)]+)\)", replacement, css_text)

    def guard(text, element):
        # inside a raw-text element only the closing tag terminates
        # early; escape the sequence should it ever occur (inside a
        # string literal, in practice, where the escape is equivalent)
        sequence = "</{}".format(element)
        if sequence in text.lower():
            log.warning(
                "escaping a premature closing sequence while embedding a {} element".format(
                    element
                )
            )
            text = re.sub(
                "</{}".format(element), "<\\\\/{}".format(element), text, flags=re.I
            )
        return text

    with open(html_file, "r") as page_file:
        page = page_file.read()

    # every stylesheet "link", whatever its attribute order
    for tag in re.findall(r'<link[^>]*rel="stylesheet"[^>]*>', page):
        href_match = re.search(r'href="([^"]*)"', tag)
        if not href_match:
            continue
        href = href_match.group(1)
        if href.startswith(reveal_root):
            response = fetch(href)
            css = embed_css_urls(response.text, response.url)
        elif href.startswith(("http:", "https:", "//")):
            # publisher custom CSS hosted remotely
            response = requests.get(href, timeout=30)
            if response.status_code != 200:
                log.warning("could not retrieve {} for embedding".format(href))
                continue
            css = embed_css_urls(response.text, response.url)
        else:
            # local stylesheet, staged in the build directory
            with open(os.path.join(local_dir, href), "r") as css_file:
                css = css_file.read()
        page = page.replace(tag, "<style>\n{}\n</style>".format(guard(css, "style")))

    # a "script" loaded by reference and nothing more; online services
    # (never at the reveal.js location) stay untouched
    for tag, src in re.findall(r'(<script src="([^"]*)"></script>)', page):
        if src.startswith(reveal_root):
            js = fetch(src).text
        elif not src.startswith(("http:", "https:", "//")):
            # local script, staged in the build directory
            with open(os.path.join(local_dir, src), "r") as js_file:
                js = js_file.read()
        else:
            continue
        page = page.replace(tag, "<script>\n{}\n</script>".format(guard(js, "script")))

    with open(html_file, "w") as page_file:
        page_file.write(page)


def revealjs(
    xml, pub_file, stringparams, xmlid_root, file_format, extra_xsl, out_file, dest_dir
):
    """Convert XML source "slideshow" to reveal.js HTML file"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # Consult publisher file for locations of images
    generated_abs, external_abs = common.get_managed_directories(xml, pub_file)

    # names for scratch directories
    tmp_dir = common.get_temporary_directory()

    # support publisher file, and subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root
    # Optional extra XSL could be None, or sanitized full filename
    if extra_xsl:
        extraction_xslt = extra_xsl
    else:
        extraction_xslt = os.path.join(common.get_ptx_xsl_path(), "pretext-revealjs.xsl")

    # place managed directories - some of these (Asymptote HTML) are
    # consulted during the XSL run and so need to be placed beforehand
    common.copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs)

    # place JS in scratch directory
    # TODO: audit what JS is really needed/used
    copy_html_js(tmp_dir)

    # copy CSS
    css_src = os.path.join(common.get_ptx_path(), "css", "dist", "pretext-reveal.css")
    css_dest = os.path.join(tmp_dir, "_static", "pretext", "css", "pretext-reveal.css")
    with open(css_src, 'r') as theme_file:
        filedata = theme_file.read()
        os.makedirs(os.path.dirname(css_dest), exist_ok=True)
        with open(css_dest, 'w+') as file:
            file.write(filedata)

    # The publication file may elect embedded mathematics: every "m"
    # and "md" is replaced by an SVG image with a speech string, both
    # manufactured here, and the slideshow does not load MathJax
    pub_vars = common.get_publisher_variable_report(xml, pub_file, stringparams)
    math_source = common.get_publisher_variable(pub_vars, "reveal-math-source")
    if math_source == "embedded":
        # a separate scratch directory: the whole of  tmp_dir  is copied
        # to the output, and these files should not ride along
        math_tmp_dir = common.get_temporary_directory()
        math_representations = os.path.join(math_tmp_dir, "math-representations-svg.xml")
        speech_representations = os.path.join(math_tmp_dir, "math-representations-speech.xml")
        msg = "converting raw LaTeX from {} into clean {} format placed into {}"
        log.debug(msg.format(xml, "svg", math_representations))
        mathjax_latex(xml, pub_file, math_representations, None, "svg", False)
        log.debug(msg.format(xml, "speech", speech_representations))
        mathjax_latex(xml, pub_file, speech_representations, None, "speech", False)
        stringparams["mathfile"] = math_representations.replace(os.sep, "/")
        stringparams["speechfile"] = speech_representations.replace(os.sep, "/")

    # Write output into temporary directory
    log.info("converting {} to HTML in {}".format(xml, tmp_dir))
    derivedname = common.get_output_filename(xml, out_file, dest_dir, ".html")
    common.xsltproc(extraction_xslt, xml, derivedname, tmp_dir, stringparams)
    # The publication file may elect embedded resources: the reveal.js
    # files, and all stylesheets, are folded into the one HTML file
    resources_host = common.get_publisher_variable(pub_vars, "reveal-resources-host")
    if resources_host == "embedded":
        reveal_root = common.get_publisher_variable(pub_vars, "reveal-root")
        log.info("embedding reveal.js resources for a single-file slideshow")
        _inline_reveal_resources(derivedname, tmp_dir, reveal_root)
    # with multiple files, we need to copy a tree
    # see comments at  copy_build_directory()
    # before replacing with  shutil.copytree()
    common.copy_build_directory(tmp_dir, dest_dir)


##################
# Assembled Source
##################

# AKA the aftermath of the pre-processor
# Parameterized by static v. dynamic exercises

# N.B. Keep this in-sync with the `assembly_internal` method

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
    elif method == "assembly-id":
        stringparams["assembly.assembly-id-only"] = "yes"
    else:
        log.error("assembly method {} not recognized".format(method))
    # "extra_xsl" would be silly in this context (?)
    extraction_xslt = os.path.join(
        common.get_ptx_xsl_path(), "utilities", "pretext-enhanced-source.xsl"
    )
    # form output filename based on source filename,
    # unless an  out_file  has been specified
    derivedname = common.get_output_filename(xml, out_file, dest_dir, ".xml")
    # Write output into working directory, no scratch space needed
    log.info(
        "converting {} to enhanced (pre-processed) PreTeXt source as {}".format(
            xml, derivedname
        )
    )
    common.xsltproc(extraction_xslt, xml, derivedname, None, stringparams)

# lxml element tree as return value. for use internally

# N.B. Keep this in-sync with the `assembly` method

def assembly_internal(xml, pub_file, stringparams, method):
    """Assembled source as an lxml element tree, provided as a return value"""
    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()
    # support publisher file
    if pub_file:
        stringparams["publisher"] = pub_file
    # method dictates which type of exercises are produced
    if method in ["static", "dynamic", "pg-problems"]:
        stringparams["debug.assembly.exercise"] = method
    elif method == "version":
        stringparams["assembly.version-only"] = "yes"
    elif method == "assembly-id":
        stringparams["assembly.assembly-id-only"] = "yes"
    else:
        log.error("assembly method {} not recognized".format(method))
    # use the right xsl template
    extraction_xslt = os.path.join(
        common.get_ptx_xsl_path(), "utilities", "pretext-enhanced-source.xsl"
    )
    log.debug("converting {} to enhanced (pre-processed) PreTeXt source for internal use".format(xml))
    return common.xsltproc(extraction_xslt, xml, None, None, stringparams)

#####################
# Conversion to LaTeX
#####################

def get_latex_style(xml, pub_file, stringparams):
    """
    Returns the name of a latex_style to be used for processing to latex.
      - Checks the value of the publisher variable 'journal-name'.
      - If it finds a journal name, tries to resolve that using the list of
        journals, returning the corresponding latex-style entry for that journal.
        Also adds the texstyle file name to the string params
      - If there is no journal-name publisher variable, or the variable is not in the
        list of journals, checks for the publisher variable 'latex-style' and returns this.
    """
    pub_vars = common.get_publisher_variable_report(xml, pub_file, stringparams)
    journal_name = common.get_publisher_variable(pub_vars, "journal-name")
    pub_latex_style = common.get_publisher_variable(pub_vars, "latex-style")
    if len(journal_name) > 0:
        journal_info = get_journal_info(journal_name)
        log.debug(f"Journal Info: {journal_info}")
        stringparams["journal.texstyle.file"] = journal_info.get("texstyle-file", "")
        latex_style = journal_info.get("latex-style", "")
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

def latex_package(xml, pub_file, stringparams, dest_dir):
    """
    Fetch latex packages (.sty/.cls files) required for building a
    latex document in a particular journal's style (as specified by
    a texstyle file).  This always downloads a fresh version of the files.
    """
    pub_vars = common.get_publisher_variable_report(xml, pub_file, stringparams)
    journal_name = common.get_publisher_variable(pub_vars, "journal-name")
    if journal_name:
        tmp_dir = common.get_temporary_directory()
        # place_latex_package_files checks if tmp_dir already has the files, which it won't, so new files will always be downloaded.
        dest_dir = os.path.join(dest_dir, journal_name)
        place_latex_package_files(dest_dir, journal_name, tmp_dir)
        log.info("latex package files downloaded to " + dest_dir)
    else:
        log.warning("No journal name found in publication file, so no latex package files downloaded.")


# This is not a build target, there is no such thing as a "latex build."
# Instead, this is a conveience for developers who want to compare
# different versions of this file during development and testing.
def latex(xml, pub_file, stringparams, extra_xsl, out_file, dest_dir, latex_format):
    """
    Convert XML source to LaTeX in destination directory.

    Args:
        xml (str): Path to the XML source file.
        pub_file (str or None): Path to the publisher configuration file, or None if not used.
        stringparams (dict): Dictionary of string parameters to control the transformation.
        extra_xsl (str or None): Path to an additional XSL stylesheet, or None if not used.
        out_file (str or None): Path to the output LaTeX file. If None, the file is copied to dest_dir.
        dest_dir (str): Directory where the output LaTeX file should be placed if out_file is not specified.
        latex_format (str): The LaTeX-family output format (e.g. 'latex' or 'beamer'), naming the base stylesheet.

    Returns:
        None

    Side Effects:
        - Generates a LaTeX file in the specified destination directory.
    """

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # support publisher file, not subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file

    # Get potential extra XSL for LaTeX style from publication file
    latex_style = get_latex_style(xml, pub_file, stringparams)

    # The base stylesheet for each LaTeX-family output format.  For "latex"
    # a publisher's "latex-style" (a styled variant) or an author's extra XSL
    # can still override this (below).
    latex_format_stylesheets = {
        "latex": "pretext-latex.xsl",
        "beamer": "pretext-beamer.xsl",
    }

    # Choose the stylesheet in priority order: an author's extra XSL (from
    # the command line) overrides everything; then a publisher's latex-style
    # variant of the regular LaTeX; otherwise the base stylesheet for the
    # requested LaTeX-family format.
    if extra_xsl:
        extraction_xslt = extra_xsl
        if latex_style:
            log.warning("Ignoring the publisher file's latex-style in favor of the extra XSL specified.")
    elif latex_style and (latex_format == "latex"):
        log.debug("Using LaTeX style: {}".format(latex_style))
        extraction_xslt = os.path.join(common.get_ptx_xsl_path(), "latex", f"pretext-latex-{latex_style}.xsl")
    else:
        extraction_xslt = os.path.join(common.get_ptx_xsl_path(), latex_format_stylesheets[latex_format])
    # form output filename based on source filename,
    # unless an  out_file  has been specified
    derivedname = common.get_output_filename(xml, out_file, dest_dir, ".tex")
    # Write output into working directory, no scratch space needed
    log.info("converting {} to LaTeX as {}".format(xml, derivedname))
    common.xsltproc(extraction_xslt, xml, derivedname, None, stringparams)


# Like latex() above, this is mostly a convenience for developers:
# the XSL-FO file is an intermediate format on the way to a PDF,
# though it does stand alone as the input to any XSL-FO formatter.
def fo(xml, pub_file, stringparams, out_file, dest_dir):
    """Convert XML source to XSL-FO in destination directory"""

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # support publisher file, not subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file

    extraction_xslt = os.path.join(common.get_ptx_xsl_path(), "pretext-fo.xsl")
    # form output filename based on source filename,
    # unless an  out_file  has been specified
    derivedname = common.get_output_filename(xml, out_file, dest_dir, ".fo")
    # The stylesheet may write companion files (e.g. a publisher's
    # watermark image) via exsl:document, which resolve against the
    # current working directory; aim them beside the FO file, where
    # relative references resolve when Apache FOP renders it
    companion_dir = os.path.dirname(os.path.abspath(derivedname))
    log.info("converting {} to XSL-FO as {}".format(xml, derivedname))
    common.xsltproc(extraction_xslt, xml, derivedname, companion_dir, stringparams)


###################
# Conversion to PDF
###################


def _latex_compile(latex_cmd, log_file, source_name, max_passes=10, capture_output=False):
    """Compile a LaTeX file, rerunning until cross-references settle.

    Runs the initial pass, then reruns while the log file requests
    "Rerun to get" and the pass limit has not been reached.

    Returns the CompletedProcess from the final pass.  Sets returncode
    to 1 if the pass limit is reached without convergence.
    """
    run_kwargs = {"stdout": subprocess.PIPE, "encoding": "utf-8"} if capture_output else {}
    result = subprocess.run(latex_cmd, **run_kwargs)
    pass_count = 1
    while (result.returncode == 0
           and os.path.isfile(log_file)
           and "Rerun to get" in open(log_file).read()
           and pass_count < max_passes):
        log.info("Rerunning LaTeX for {} (pass {})".format(source_name, pass_count + 1))
        result = subprocess.run(latex_cmd, **run_kwargs)
        pass_count += 1
    if pass_count == max_passes and result.returncode == 0:
        log.warning("LaTeX compilation of {} required {} passes and may not have converged.".format(source_name, max_passes))
        result.returncode = 1
    return result


def pdf(xml, pub_file, stringparams, extra_xsl, out_file, dest_dir, method, outputs, latex_format):
    """
    Generate a PDF from an XML source using LaTeX as an intermediate format.

    Args:
        xml (str): Path to the XML source file.
        pub_file (str or None): Path to the publisher configuration file, or None if not used.
        stringparams (dict): Dictionary of string parameters to control the transformation.
        extra_xsl (str or None): Path to an additional XSL stylesheet, or None if not used.
        out_file (str or None): Path to the output PDF file. If None, the PDF is copied to      dest_dir.
        dest_dir (str): Directory where the output PDF should be placed if out_file is not specified.
        method (str): The LaTeX engine or processing method to use (e.g., 'pdflatex', 'xelatex').
        outputs (str or None): Specify which files should be copied to dest_dir.  Possible values are pdf-only (default), all (.tex, assets, pdf, and *.log, *.aux, etc), all-clean (same as all but no *.log, *.aux, etc), or prebuild (same as all-clean but no pdf).
        latex_format (str): The LaTeX-family output format (e.g. 'latex' or 'beamer'), naming the base stylesheet.

    Returns:
        None

    Side Effects:
        - Copies the generated PDF to the specified output location.
    """
    # Warn if outputs variable is something other than expected options
    outputs_options = ["pdf-only", "prebuild", "all", "all-clean"]
    if (outputs not in outputs_options):
        log.warning("You requested outputs of {}, but this is not a recognized option.  Defaulting to 'pdf-only'.".format(outputs))
    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    generated_abs, external_abs = common.get_managed_directories(xml, pub_file)
    # Consult source for additional files
    data_dir = common.get_source_directories(xml)

    # perhaps necessary (so drop "if"), but maybe not; needs to be supported
    if pub_file:
        stringparams["publisher"] = pub_file
    # names for scratch directories
    tmp_dir = common.get_temporary_directory()

    # make the LaTeX source file in scratch directory
    # (1) pass None as out_file to derive from XML source filename
    # (2) pass tmp_dir (scratch) as destination directory
    latex(xml, pub_file, stringparams, extra_xsl, None, tmp_dir, latex_format)

    # Create localized filenames for pdflatex conversion step
    # sourcename  needs to match behavior of latex() with above arguments
    basename = os.path.splitext(os.path.split(xml)[1])[0]
    sourcename = basename + ".tex"
    pdfname = basename + ".pdf"

    # Copy directories as indicated in publisher file
    # A "None" value will indicate there was no information
    # (an empty string is impossible due to a slash always being present?)

    # Make data files available, such as for TikZ images
    common.copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs, data_abs=data_dir)

    # If we are building for a journal, we might need extra files
    pub_vars = common.get_publisher_variable_report(xml, pub_file, stringparams)
    journal_name = common.get_publisher_variable(pub_vars, "journal-name")
    if journal_name:
        place_latex_package_files(tmp_dir, journal_name, os.path.join(generated_abs, "latex-packages"))

    # If requested, copy the LaTeX source and asset folders to dest_dir.
    # Note that outputs == "all" needs to wait until after the build to copy build_dir.
    if outputs == "all-clean" or outputs == "prebuild":
        common.copy_build_directory(tmp_dir, dest_dir)
        # prebuild means no pdf, so stop here.
        if outputs == "prebuild":
            return

    # now work in temporary directory since LaTeX is a bit incapable
    # of working outside of the current working directory
    with common.working_directory(tmp_dir):
        # process with a  latex  engine
        latex_key = common.get_deprecated_tex_fallback(method)
        latex_exec_cmd = common.get_executable_cmd(latex_key)
        # -halt-on-error will give an exit code to examine
        # First pass always needed, second resolves cross-references.
        # Additional passes may be required by packages like nicematrix
        # (which uses TikZ "remember picture" for cell coloring) or
        # tcolorbox.  We check the .log for "Rerun to get" requests,
        # matching the strategy used for standalone latex-image compilation.
        latex_cmd = latex_exec_cmd + ["-halt-on-error", sourcename]
        logname = basename + ".log"
        result = _latex_compile(latex_cmd, logname, sourcename)

        # If we want all outputs, we copy the entire build directory now that the PDF is built
        # so we can get the *.log, *.aux, etc build files.
        if outputs == "all":
            common.copy_build_directory(tmp_dir, dest_dir)
        else:
            # Copy just the PDF output
            # out_file: not(None) only if provided in CLI
            # dest_dir: always defined, if only current directory of CLI invocation
            if out_file:
                shutil.copy2(pdfname, out_file)
            else:
                shutil.copy2(pdfname, dest_dir)


def _pdf_fo_accessibility_repairs(pdfname):
    """
    Post-process a FOP-rendered PDF to repair two PDF/UA conformance
    gaps that Apache FOP (observed with version 2.8) cannot fill from
    the XSL-FO side.  PyMuPDF performs the (small, incremental)
    repairs; it is already a dependency of this script, used for
    image format conversions.

    Repair one, link descriptions:

    PDF/UA-1 (ISO 14289-1, Clause 7.18.5) requires each link
    annotation to provide an alternate description in the /Contents
    key of its annotation dictionary (per ISO 32000-1, 14.9.3); this
    is what assistive technology announces for the link, and what a
    validator such as veraPDF inspects.  The XSL-FO conversion
    decorates every "fo:basic-link" with a description, via the
    "fox:alt-text" extension attribute, but FOP records it only as
    the /Alt entry of the link's *structure element*, in the
    structure tree -- it has no mechanism at all for writing the
    /Contents key of the Link *annotation*.  So walk the structure
    tree's /ParentTree to recover each annotation's intended
    description from its structure element (falling back to the
    link's URI, or generic text) and write it into /Contents.

    Repair two, footnote identifiers:

    PDF/UA-1 (Clause 7.9) requires each /Note structure element
    (FOP's tag for the body of a footnote) to carry a unique /ID
    entry, which FOP never writes.  Manufacture one from the
    object number.

    N.B. Remove this routine (and its one call, in pdf_fo()) the day
    FOP handles both itself.  The test: render with a newer FOP,
    skip this pass, and check the report of
        verapdf --flavour ua1 <the-pdf>
    for Clauses 7.18.5 and 7.9.
    """
    try:
        import fitz  # pyMuPDF
    except ImportError:
        log.warning("the 'pyMuPDF' module is not installed, so PDF link annotations lack the alternate descriptions PDF/UA requires")
        return

    import re

    doc = fitz.open(pdfname)
    # Map a /StructParent index to the /Alt of its structure element by
    # walking the /ParentTree number tree, whose nodes are inline
    # dictionaries or indirect objects, with /Kids subtrees or /Nums
    # leaf arrays.  Entries mapping an index to an *array* (the marked
    # content of a page) do not concern us, and do not match the pair
    # pattern.  Any miss just engages the fallback below.
    alternate_text = {}

    def harvest(node_type, node_value):
        if node_type == "xref":
            node = int(node_value.split()[0])
            kids = doc.xref_get_key(node, "Kids")
            nums = doc.xref_get_key(node, "Nums")
        elif node_type == "dict":
            kids_match = re.search(r"/Kids\s*(\[[^\]]*\])", node_value)
            kids = ("array", kids_match.group(1)) if kids_match else ("null", "null")
            nums_match = re.search(r"/Nums\s*(\[[^\]]*\])", node_value)
            nums = ("array", nums_match.group(1)) if nums_match else ("null", "null")
        else:
            return
        if kids[0] == "array":
            for reference in re.findall(r"(\d+)\s+0\s+R", kids[1]):
                harvest("xref", reference + " 0 R")
        if nums[0] == "array":
            for index, element in re.findall(r"(\d+)\s+(\d+)\s+0\s+R", nums[1]):
                alt = doc.xref_get_key(int(element), "Alt")
                if alt[0] == "string":
                    alternate_text[int(index)] = alt[1]

    struct_root = doc.xref_get_key(doc.pdf_catalog(), "StructTreeRoot")
    if struct_root[0] == "xref":
        harvest(*doc.xref_get_key(int(struct_root[1].split()[0]), "ParentTree"))
    additions = 0
    for page in doc:
        for link in page.links():
            xref = link["xref"]
            if doc.xref_get_key(xref, "Contents")[0] != "null":
                continue
            description = None
            struct_parent = doc.xref_get_key(xref, "StructParent")
            if struct_parent[0] == "int":
                description = alternate_text.get(int(struct_parent[1]))
            if description is None:
                description = link.get("uri") or "internal cross-reference"
            doc.xref_set_key(xref, "Contents", fitz.get_pdf_str(description))
            additions += 1
    # repair two: a unique /ID for each /Note structure element
    for xref in range(1, doc.xref_length()):
        if doc.xref_get_key(xref, "S")[1] == "/Note" and doc.xref_get_key(xref, "ID")[0] == "null":
            doc.xref_set_key(xref, "ID", "(Note-{})".format(xref))
            additions += 1

    # repair three: tag the link annotations FOP leaves untagged.  Apache
    # Batik turns the SVG "a" that MathJax emits for a cross-reference
    # inside display mathematics into a Link annotation, but -- unlike
    # FOP's own "fo:basic-link" -- does not nest it in a Link structure
    # element, which PDF/UA-1 (Clause 7.18.5) requires.  Wrap each such
    # annotation (a Link with no /StructParent) in a new Link structure
    # element under the document's structure element, with an /OBJR back
    # to the annotation, and register its /StructParent in the number
    # tree.  Nesting under the math's own figure would read better, but
    # needs per-figure geometry that FOP and PyMuPDF do not expose; this
    # keeps the PDF conformant.
    struct_root = doc.xref_get_key(doc.pdf_catalog(), "StructTreeRoot")
    if struct_root[0] == "xref":
        root_xref = int(struct_root[1].split()[0])
        root_kids = doc.xref_get_key(root_xref, "K")
        if root_kids[0] == "xref":
            document_element = int(root_kids[1].split()[0])
        elif root_kids[0] == "array":
            document_refs = re.findall(r"(\d+)\s+0\s+R", root_kids[1])
            document_element = int(document_refs[0]) if document_refs else None
        else:
            document_element = None

        # The /ParentTree is a number tree, given inline on the structure
        # root or as an indirect object.  Read a node's /Nums and /Kids
        # whichever way it is stored.
        def tree_node(node_type, node_value):
            if node_type == "xref":
                node = int(node_value.split()[0])
                nums = doc.xref_get_key(node, "Nums")
                kids = doc.xref_get_key(node, "Kids")
                return (nums[1] if nums[0] == "array" else None,
                        kids[1] if kids[0] == "array" else None)
            nums = re.search(r"/Nums\s*(\[.*\])", node_value)
            kids = re.search(r"/Kids\s*(\[[^\]]*\])", node_value)
            return (nums.group(1) if nums else None,
                    kids.group(1) if kids else None)

        # an indirect leaf to extend (follow /Kids to its last child), the
        # highest key already in the tree (a page's /StructParents or an
        # annotation's /StructParent), so new keys sit above it
        def resolve_leaf(node_type, node_value):
            nums, kids = tree_node(node_type, node_value)
            if kids:
                refs = re.findall(r"(\d+)\s+0\s+R", kids)
                if refs:
                    return resolve_leaf("xref", refs[-1] + " 0 R")
            return int(node_value.split()[0]) if node_type == "xref" else None

        def tree_max_key(node_type, node_value):
            nums, kids = tree_node(node_type, node_value)
            keys = [-1]
            if nums:
                keys += [int(k) for k in re.findall(r"(\d+)\s+(?:\d+\s+0\s+R|<<|\[)", nums)]
            if kids:
                keys += [tree_max_key("xref", r + " 0 R") for r in re.findall(r"(\d+)\s+0\s+R", kids)]
            return max(keys)

        parent_tree = doc.xref_get_key(root_xref, "ParentTree")
        leaf = resolve_leaf(*parent_tree) if document_element is not None else None
        if leaf is not None:
            next_key = doc.xref_get_key(root_xref, "ParentTreeNextKey")
            key = int(next_key[1]) if next_key[0] == "int" else tree_max_key(*parent_tree) + 1

            new_links = []
            for page in doc:
                page_xref = page.xref
                for link in page.links():
                    annot = link["xref"]
                    if doc.xref_get_key(annot, "Subtype")[1] != "/Link":
                        continue
                    if doc.xref_get_key(annot, "StructParent")[0] == "int":
                        continue
                    link_element = doc.get_new_xref()
                    objr = "<</Type/OBJR/Pg {} 0 R/Obj {} 0 R>>".format(page_xref, annot)
                    doc.update_object(link_element, "<</Type/StructElem/S/Link/P {} 0 R/Pg {} 0 R/K {}>>".format(document_element, page_xref, objr))
                    doc.xref_set_key(annot, "StructParent", str(key))
                    new_links.append((key, link_element))
                    key += 1
                    additions += 1

            if new_links:
                # the new Link elements become children of the document
                new_refs = " ".join("{} 0 R".format(x) for _, x in new_links)
                k_entry = doc.xref_get_key(document_element, "K")
                if k_entry[0] == "array":
                    document_kids = k_entry[1].rstrip()[:-1] + " " + new_refs + "]"
                elif k_entry[0] == "xref":
                    document_kids = "[{} {}]".format(k_entry[1], new_refs)
                else:
                    document_kids = "[{}]".format(new_refs)
                doc.xref_set_key(document_element, "K", document_kids)
                # map each annotation's /StructParent to its Link element,
                # extending the leaf's /Nums (kept sorted, as the new keys
                # are all above the existing ones) and its /Limits
                nums = " ".join("{} {} 0 R".format(k, x) for k, x in new_links)
                leaf_nums = doc.xref_get_key(leaf, "Nums")
                existing = leaf_nums[1].strip()[1:-1].strip() if leaf_nums[0] == "array" else ""
                doc.xref_set_key(leaf, "Nums", "[{}]".format((existing + " " + nums).strip()))
                leaf_limits = doc.xref_get_key(leaf, "Limits")
                low = re.findall(r"-?\d+", leaf_limits[1])[0] if (leaf_limits[0] == "array" and existing) else str(new_links[0][0])
                doc.xref_set_key(leaf, "Limits", "[{} {}]".format(low, new_links[-1][0]))
                doc.xref_set_key(root_xref, "ParentTreeNextKey", str(key))

    if additions > 0:
        doc.saveIncr()
    doc.close()
    log.debug("made {} accessibility repairs in {}".format(additions, pdfname))


def _downgrade_svg2_for_batik(directory):
    """Rewrite SVG 2 constructs that Apache Batik (via FOP) cannot render.

    * context-stroke / context-fill in marker content: for each referencing
      element a resolved copy is created using that element's concrete
      stroke / fill; copies with the same colour pair are shared.
    * orient="auto-start-reverse": changed to "auto"; elements that use
      the marker as marker-start get a rotated (180°) copy (id suffix
      "-start").
    * Plain href on any SVG element: migrated to xlink:href.
    * fill="transparent" → fill="none"; hsl()/rgb() colour functions and
      CSS filter functions in <style> blocks rewritten to values Batik
      accepts.
    * dominant-baseline="central/middle" and alignment-baseline on <text>:
      converted to an explicit numeric y coordinate (alphabetic baseline),
      with all dy attributes removed to avoid Batik dy/tspan quirks.
    * <foreignObject> containing XHTML spans (mermaid class diagrams):
      replaced by SVG <text> elements with equivalent content and position.
    """
    # TODO (2026-07-03) This function may modify SVG 1.1 files coming
    # from PreFigure that are known to be good for Batik to ingest.
    # With access to source, we can determine filenames to avoid.

    import glob, copy, re, colorsys
    import lxml.etree as ET

    SVG           = "http://www.w3.org/2000/svg"
    XLINK         = "http://www.w3.org/1999/xlink"
    XHTML         = "http://www.w3.org/1999/xhtml"
    ET.register_namespace("xlink", XLINK)
    tag           = lambda t: f"{{{SVG}}}{t}"
    xhref         = f"{{{XLINK}}}href"
    POSITIONS     = ("marker-start", "marker-end", "marker-mid")
    _URL_RE       = re.compile(r"^url\(#([^)]+)\)$")
    _HSL_RE       = re.compile(r"hsl\(\s*([\d.]+)\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%\s*\)")
    _RGB_RE       = re.compile(r"rgb\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)")
    _FILTER_FN_RE = re.compile(r"(filter\s*:)\s*([^;{}]+)")
    _TRANS_RE     = re.compile(r"translate\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)")

    def parse_style(el):
        d = {}
        for part in (el.get("style") or "").split(";"):
            k, sep, v = part.partition(":")
            if sep: d[k.strip()] = v.strip()
        return d

    def emit_style(d): return ";".join(f"{k}:{v}" for k, v in d.items())

    def get_prop(el, prop):
        return parse_style(el).get(prop) or el.get(prop)

    def _hsl_to_hex(m):
        h, s, l = float(m.group(1))/360, float(m.group(2))/100, float(m.group(3))/100
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        return "#{:02x}{:02x}{:02x}".format(round(r*255), round(g*255), round(b*255))

    def _rgb_to_hex(m):
        return "#{:02x}{:02x}{:02x}".format(
            round(float(m.group(1))), round(float(m.group(2))), round(float(m.group(3)))
        )

    def _strip_filter_fn(m):
        val = m.group(2).strip()
        if "(" in val and not val.startswith("url("):
            return m.group(1) + "none"
        return m.group(0)

    def has_context_paint(marker):
        return any(
            get_prop(el, attr) in ("context-stroke", "context-fill")
            for el in marker.iter() for attr in ("fill", "stroke")
        )

    def is_svg2_marker(m):
        return has_context_paint(m) or m.get("orient") == "auto-start-reverse"

    def resolve_paint(v, stroke, fill):
        if v == "context-stroke": return stroke
        if v == "context-fill":   return fill
        return v

    def make_marker(orig, new_id, stroke, fill, rotate):
        m = copy.deepcopy(orig)
        m.set("id", new_id)
        if m.get("orient") == "auto-start-reverse":
            m.set("orient", "auto")
        if rotate:
            g = ET.Element(tag("g"))
            g.set("transform",
                  f"rotate(180 {m.get('refX', '0')} {m.get('refY', '0')})")
            for child in list(m): m.remove(child); g.append(child)
            m.append(g)
        for el in m.iter():
            sty = parse_style(el)
            sty2 = {k: resolve_paint(v, stroke, fill) for k, v in sty.items()}
            if sty2 != sty: el.set("style", emit_style(sty2))
            for attr in ("fill", "stroke"):
                v = el.get(attr)
                if v: el.set(attr, resolve_paint(v, stroke, fill))
        return m

    def get_marker_ref(el, pos):
        sty = parse_style(el)
        raw = (sty.get(pos) or el.get(pos) or "").strip()
        mo  = _URL_RE.match(raw)
        return mo.group(1) if mo else None

    def set_marker_ref(el, pos, url):
        sty = parse_style(el)
        if pos in sty:
            sty[pos] = url; el.set("style", emit_style(sty))
        else:
            el.set(pos, url)

    for svg_file in glob.glob(
        os.path.join(directory, "**", "*.svg"), recursive=True
    ):
        try:
            tree = ET.parse(svg_file)
        except ET.XMLSyntaxError:
            continue
        root    = tree.getroot()
        changed = False

        for el in root.iter():
            if not (isinstance(el.tag, str) and el.tag.startswith("{" + SVG + "}")):
                continue
            href = el.get("href")
            if href and el.get(xhref) is None:
                el.set(xhref, href); del el.attrib["href"]; changed = True

        # "transparent" is a CSS3 colour keyword, not SVG 1.1;
        # hsl()/rgb() in presentation attributes are also rewritten here.
        for el in root.iter():
            if el.get("fill") == "transparent":
                el.set("fill", "none"); changed = True
            for attr in ("fill", "stroke"):
                v = el.get(attr)
                if v:
                    nv = _HSL_RE.sub(_hsl_to_hex, v)
                    nv = _RGB_RE.sub(_rgb_to_hex, nv)
                    if nv != v:
                        el.set(attr, nv); changed = True
        for el in root.iter(tag("style")):
            if not el.text: continue
            t = el.text.replace("transparent", "none")
            t = _HSL_RE.sub(_hsl_to_hex, t)
            t = _RGB_RE.sub(_rgb_to_hex, t)
            t = _FILTER_FN_RE.sub(_strip_filter_fn, t)
            if t != el.text:
                el.text = t; changed = True

        # alignment-baseline is not valid on <text> in SVG 1.1 and
        # dominant-baseline is not reliably supported by Batik on <text>.
        # For centering values, compute the intended visual centre from
        # y + dy (resolving em to px), add a fixed 0.35em baseline offset
        # for centering, write the result as a plain numeric y on the
        # <text>, and strip all dy attributes.  Using explicit px avoids
        # all the Batik dy/tspan interaction quirks.
        def _em_px(val, font_px):
            try:
                if (val or "").endswith("em"): return float(val[:-2]) * font_px
                if (val or "").endswith("px"): return float(val[:-2])
                return 0.0
            except (ValueError, TypeError):
                return 0.0

        for el in root.iter(tag("text")):
            if el.get("alignment-baseline"):
                del el.attrib["alignment-baseline"]; changed = True
            db = el.get("dominant-baseline")
            if db in ("central", "middle"):
                sty = parse_style(el)
                fs  = sty.get("font-size") or el.get("font-size", "16px")
                try:
                    font_px = float(fs[:-2]) if fs.endswith("px") else 16.0
                except ValueError:
                    font_px = 16.0
                centre = float(el.get("y", 0)) + _em_px(el.get("dy"), font_px)
                el.set("y", f"{centre + 0.35 * font_px:.4g}")
                if "dy" in el.attrib: del el.attrib["dy"]
                for ts in el:
                    if ts.tag == tag("tspan") and "dy" in ts.attrib:
                        del ts.attrib["dy"]
                changed = True
            if db:
                del el.attrib["dominant-baseline"]; changed = True

        # Mermaid git diagrams position branch labels via
        #   <text><tspan dy="1em">label</tspan></text>
        # (no y attribute on the <text> element).  Batik ignores the tspan's
        # dy in this case and places the text at y=0 in the parent g's space.
        # Fix: promote the first tspan's dy to an explicit y on the <text>
        # element, so Batik picks up the correct baseline.
        for el in root.iter(tag("text")):
            if el.get("y") is not None:
                continue
            if el.get("dominant-baseline") or el.get("alignment-baseline"):
                continue   # already handled above
            tspans = [c for c in el if c.tag == tag("tspan")]
            if not tspans:
                continue
            ts    = tspans[0]
            ts_dy = ts.get("dy", "")
            if not ts_dy:
                continue
            el.set("y", ts_dy)
            del ts.attrib["dy"]
            changed = True

        # Convert <foreignObject> elements used by mermaid class diagrams to
        # SVG <text> elements that Batik can render.  Each foreignObject holds
        # an XHTML div/span whose text content needs to become an SVG text
        # node.  The foreignObject's transform gives its (tx, ty) offset within
        # the parent <g>, and its width/height determine the text position.
        # classTitle elements are horizontally centred; all others are left-
        # aligned from the foreignObject's left edge.
        fo_tag   = tag("foreignObject")
        xspan    = f"{{{XHTML}}}span"
        for fo in list(root.iter(fo_tag)):
            text = "".join((el.text or "") for el in fo.iter(xspan)).strip()
            if not text:
                continue  # leave empty foreignObjects in place; Batik ignores them
            t   = fo.get("transform", "")
            m   = _TRANS_RE.search(t)
            tx  = float(m.group(1)) if m else 0.0
            ty  = float(m.group(2)) if m else 0.0
            w   = float(fo.get("width",  0))
            h   = float(fo.get("height", 18))
            if fo.get("class") == "classTitle":
                x, anchor = tx + w / 2, "middle"
            else:
                x, anchor = tx, "start"
            y = ty + h - 3          # approximate SVG alphabetic baseline
            tel = ET.Element(tag("text"))
            tel.set("x", f"{x:.4g}")
            tel.set("y", f"{y:.4g}")
            tel.set("text-anchor", anchor)
            tel.text = text
            parent = fo.getparent()
            if parent is not None:
                idx = list(parent).index(fo)
                parent.remove(fo)
                parent.insert(idx, tel)
            changed = True

        bad = {el.get("id"): el for el in root.iter(tag("marker"))
               if el.get("id") and is_svg2_marker(el)}
        if bad:
            defs = root.find(tag("defs"))
            if defs is None:
                defs = ET.SubElement(root, tag("defs"))
            key_map  = {}   # (orig_id, stroke, fill, rotate) → new_id
            new_mkrs = {}   # new_id → marker element
            used_ids = set()

            for el in root.iter():
                for pos in POSITIONS:
                    mid = get_marker_ref(el, pos)
                    if not mid or mid not in bad: continue
                    stroke = get_prop(el, "stroke") or "black"
                    fill   = get_prop(el, "fill")   or "black"
                    rotate = (pos == "marker-start" and
                              bad[mid].get("orient") == "auto-start-reverse")
                    key = (mid, stroke, fill, rotate)
                    if key not in key_map:
                        suffix = "start" if rotate else "end"
                        base   = f"{mid}-{suffix}"
                        nid    = base
                        n      = 0
                        while nid in used_ids: n += 1; nid = f"{base}-{n}"
                        used_ids.add(nid)
                        key_map[key] = nid
                        new_mkrs[nid] = make_marker(bad[mid], nid, stroke, fill, rotate)
                    set_marker_ref(el, pos, f"url(#{key_map[key]})")

            for m in new_mkrs.values(): defs.append(m)
            for m in bad.values():
                if m.getparent() is not None: defs.remove(m)
            changed = True

        if changed:
            tree.write(svg_file)


def _math_links_for_batik(math_file):
    """Make a cross-reference inside mathematics a live link in the PDF.

    When asked for cross-reference links, MathJax wraps the reference in
    an SVG "a" element carrying a plain SVG 2 "href".  Apache Batik (the
    SVG engine inside FOP) honors only the SVG 1.1 "xlink:href", so the
    link is present but dead until the value is moved over -- exactly the
    fix  _downgrade_svg2_for_batik  applies to a "use".  Operates on the
    math representations file, where these "a" elements live.
    """
    import lxml.etree as ET

    svg_namespace = "http://www.w3.org/2000/svg"
    xlink_namespace = "http://www.w3.org/1999/xlink"
    anchor_tag = "{{{}}}a".format(svg_namespace)
    xlink_href = "{{{}}}href".format(xlink_namespace)

    try:
        tree = ET.parse(math_file)
    except (ET.XMLSyntaxError, OSError):
        return
    root = tree.getroot()
    changed = False
    for anchor in root.iter(anchor_tag):
        target = anchor.get("href")
        if target is not None and anchor.get(xlink_href) is None:
            anchor.set(xlink_href, target)
            del anchor.attrib["href"]
            changed = True
    if changed:
        tree.write(math_file)


def pdf_fo(xml, pub_file, stringparams, out_file, dest_dir):
    """
    Generate a PDF from an XML source using XSL-FO as an intermediate
    format, rendered by Apache FOP.  This is a LaTeX-free route to a
    PDF, experimental and very incomplete.

    Args:
        xml (str): Path to the XML source file.
        pub_file (str or None): Path to the publisher configuration file, or None if not used.
        stringparams (dict): Dictionary of string parameters to control the transformation.
        out_file (str or None): Path to the output PDF file. If None, the PDF is copied to dest_dir.
        dest_dir (str): Directory where the output PDF should be placed if out_file is not specified.

    Returns:
        None

    Side Effects:
        - Copies the generated PDF to the specified output location.
    """
    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    generated_abs, external_abs = common.get_managed_directories(xml, pub_file)
    # Consult source for additional files
    data_dir = common.get_source_directories(xml)

    if pub_file:
        stringparams["publisher"] = pub_file
    # name for scratch directory
    tmp_dir = common.get_temporary_directory()

    # Mathematics as SVG images, produced by MathJax, and passed to
    # the FO stylesheet as the  $mathfile  string parameter, which
    # melds each image into the page (the model is  epub()  above)
    math_representations = os.path.join(tmp_dir, "math-representations-svg.xml")
    # The final argument requests live cross-reference links inside the
    # mathematics.  This (single-file) PDF is the only conversion that
    # asks for them: a link is a bare "#id" fragment, which resolves
    # only within one file, and FOP renders it from the SVG that MathJax
    # emits.  Chunked conversions (HTML, EPUB) would need real filenames,
    # and not every reader honors an SVG link, so they pass False.
    mathjax_latex(xml, pub_file, math_representations, None, "svg", True)
    # let Batik honor the cross-reference links MathJax placed in the math
    _math_links_for_batik(math_representations)
    stringparams["mathfile"] = math_representations.replace(os.sep, "/")

    # Speech versions of the mathematics become the alternate text
    # of the SVG images, as PDF/UA requires; again the model is epub()
    speech_representations = os.path.join(tmp_dir, "math-representations-speech.xml")
    mathjax_latex(xml, pub_file, speech_representations, None, "speech", False)
    stringparams["speechfile"] = speech_representations.replace(os.sep, "/")

    # make the XSL-FO file in scratch directory
    # (1) pass None as out_file to derive from XML source filename
    # (2) pass tmp_dir (scratch) as destination directory
    fo(xml, pub_file, stringparams, None, tmp_dir)

    # Create localized filenames for the FOP rendering step
    # foname  needs to match behavior of fo() with above arguments
    basename = os.path.splitext(os.path.split(xml)[1])[0]
    foname = os.path.join(tmp_dir, basename + ".fo")
    pdfname = os.path.join(tmp_dir, basename + ".pdf")

    # Make image files available, relative to the FO file
    common.copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs, data_abs=data_dir)

    # Bundled fonts (the symbol fallback face) are named by a relative
    # path in  fop.xconf , so they must sit in the scratch directory
    # where FOP runs, beside the FO file and the image directories.
    fonts_src = os.path.join(common.get_ptx_path(), "fonts")
    shutil.copytree(fonts_src, os.path.join(tmp_dir, "fonts"))

    # FOP renders SVG through Batik (SVG 1.1); downgrade the SVG 2
    # constructs in the staged images so the diagrams render
    _downgrade_svg2_for_batik(tmp_dir)

    # render the FO file as a PDF with Apache FOP, configured
    # by the  fop.xconf  file maintained in this distribution
    fop_exec_cmd = common.get_executable_cmd("fop")
    fop_xconf = os.path.join(common.get_ptx_path(), "pretext", "fop.xconf")
    fop_cmd = fop_exec_cmd + ["-c", fop_xconf, "-fo", foname, "-pdf", pdfname]
    log.info("rendering {} as {} with Apache FOP".format(foname, pdfname))
    log.debug("FOP command: {}".format(" ".join(fop_cmd)))
    # run FOP in the scratch directory, where the managed directories
    # were just copied, so relative image paths in the FO file resolve
    result = subprocess.run(fop_cmd, cwd=tmp_dir)
    if result.returncode != 0:
        raise OSError("Apache FOP rendering of {} failed".format(foname))

    # post-process: repair PDF/UA conformance gaps FOP leaves behind
    _pdf_fo_accessibility_repairs(pdfname)

    # Copy just the PDF output
    # out_file: not(None) only if provided in CLI
    # dest_dir: always defined, if only current directory of CLI invocation
    if out_file:
        shutil.copy2(pdfname, out_file)
    else:
        shutil.copy2(pdfname, dest_dir)


#################
# XSLT Processing
#################



########################
#
# JaaS
# Jing as a Service
# (Validation with Jing)
#
########################

# the "pi" namespace attribute recording an element's originating file
PI_SOURCE_URI = "{http://pretextbook.org/2020/pretext/internal}source-uri"


def validate(xml_source, pub_file, stringparams, out_file, dest_dir, method):
    """Validate source against the RELAX-NG schema, locally or via a server"""

    # "local" validates against the production schema and "local-dev"
    # against the development schema, each with a report meant for an
    # author.  "terse" is the production schema with machine-readable
    # output, one tab-separated message per line, meant for a program.
    # "server" is "local" with the "jing" run delegated to a remote
    # service; the consolidated report is identical.
    if method == "local-dev":
        schema_file = "pretext-dev.rng"
    else:
        schema_file = "pretext.rng"
    terse = method == "terse"
    server = method == "server"
    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    # the consolidated report, and the assembled source deposited
    # alongside it (wherever the report lands)
    reportname = common.get_output_filename(
        xml_source, out_file, dest_dir, "-validation.txt"
    )
    assembled_source = os.path.join(
        os.path.dirname(os.path.abspath(reportname)),
        os.path.splitext(os.path.basename(xml_source))[0] + "-assembled.xml",
    )

    tmp_dir = common.get_temporary_directory()

    # Modular source files are knitted together here, rather than
    # during assembly, so each included file can be recorded on its
    # root element (as a @pi:source-uri attribute) and problems can
    # then be attributed to the file where they lie
    source_dir = os.path.dirname(os.path.abspath(xml_source))
    main_file = os.path.basename(xml_source)

    def _stamping_loader(href, parse, encoding=None):
        if parse == "xml":
            elt = ET.parse(href).getroot()
            elt.set(PI_SOURCE_URI, href)
            return elt
        with open(href, "r", encoding=(encoding or "utf-8")) as f:
            return f.read()

    merged_source = os.path.join(tmp_dir, "merged.xml")
    source_tree = ET.parse(xml_source)
    try:
        from lxml import ElementInclude

        ElementInclude.include(
            source_tree.getroot(), loader=_stamping_loader, max_depth=20
        )
    except Exception as e:
        log.warning(
            "file attribution of validation problems unavailable ({})".format(e)
        )
        source_tree = ET.parse(xml_source)
        source_tree.xinclude()
    # The temporary merged file must resolve relative references (a
    # customizations file, say) as the original source would, which is
    # exactly the job of an @xml:base (assembly drops it from output)
    source_tree.getroot().set(
        "{http://www.w3.org/XML/1998/namespace}base", os.path.abspath(xml_source)
    )
    source_tree.write(merged_source, encoding="utf-8", xml_declaration=True)

    # Validation is performed on the "version" tree: the merged source
    # reduced by any "version" support elected in a publication file.
    # The paths of any messages refer to this assembled source, so it
    # is deposited next to the report, for cross-referencing, rather
    # than evaporating with a temporary directory.
    stringparams["assembly.file-attribution"] = "yes"
    attributed_source = os.path.join(tmp_dir, "assembled-attributed.xml")
    assembly(merged_source, pub_file, stringparams, attributed_source, None, "version")

    # Tree "A" retains the file attributions, which are stripped to
    # make the deposited assembled source (what "jing" examines, since
    # the schema knows nothing of the attribute).  Tree "B" is that
    # deposited file re-parsed, so line numbers agree with what "jing"
    # reports; elements of the two trees correspond in document order.
    tree_a = ET.parse(attributed_source)
    file_of_a = {}
    current_files = {tree_a.getroot(): main_file}
    for elt in tree_a.iter():
        if not isinstance(elt.tag, str):
            continue
        uri = elt.attrib.pop(PI_SOURCE_URI, None)
        if uri is not None:
            filename = os.path.relpath(uri, start=source_dir)
        else:
            parent = elt.getparent()
            filename = file_of_a.get(parent, main_file)
        file_of_a[elt] = filename
    tree_a.write(assembled_source, encoding="utf-8", xml_declaration=True)
    tree_b = ET.parse(assembled_source)
    a_elements = [e for e in tree_a.iter() if isinstance(e.tag, str)]
    b_elements = [e for e in tree_b.iter() if isinstance(e.tag, str)]
    file_of = {b: file_of_a[a] for a, b in zip(a_elements, b_elements)}
    # the last element to *begin* on each line, in document order
    opening = {}
    for elt in b_elements:
        opening[elt.sourceline] = elt
    with open(assembled_source) as f:
        source_lines = f.readlines()

    # fresh schema from the PreTeXt distribution, in XML syntax
    schema_filename = os.path.join(common.get_ptx_path(), "schema", schema_file)

    # The RELAX-NG check runs "jing" against the assembled source and
    # yields its raw report as a list of lines.  A local run uses an
    # installed "jing"; the "server" method sends the same assembled
    # source to a remote "jing" service.  Either way the lines below feed
    # an identical consolidated report.
    if server:
        jing_messages = _jing_server(schema_filename, assembled_source)
        if jing_messages is None:
            # the server could not be reached; a clear error was logged
            return
    else:
        # "jing" is a Java program, so a configuration can be simply the
        # name of an executable ("jing", from a system package), or a
        # command with options ("java -jar /usr/share/java/jing.jar")
        jing_exec_cmd = common.get_executable_cmd("jing")
        full_cmd = jing_exec_cmd + [schema_filename, assembled_source]
        log.debug("jing command: {}".format(" ".join(full_cmd)))
        result = subprocess.run(full_cmd, capture_output=True, text=True)
        # jing exits 0 when the document is valid, 1 when messages result
        if result.returncode == 0:
            log.info("the source validates with no schema errors")
        elif result.returncode > 1:
            log.warning('the "jing" program failed (code {})'.format(result.returncode))
        jing_messages = result.stdout.splitlines()

    # The "validation-plus" stylesheet performs checks the RELAX-NG
    # schema cannot express, and provides extra advice and explanation
    # besides.  Applied to the same assembled source, so locations are
    # consistent with the schema messages.  Single-line output, one
    # message per line.
    plus_xsl = os.path.join(
        common.get_ptx_path(), "schema", "pretext-validation-plus.xsl"
    )
    plus_scratch = os.path.join(tmp_dir, "validation-plus.txt")
    params = {"single.line.output": "yes"}
    common.xsltproc(plus_xsl, assembled_source, plus_scratch, None, params)
    with open(plus_scratch, "r") as f:
        plus_messages = [line.strip() for line in f if line.startswith("PTX:")]

    # helpers for locating a message's element in tree "B"

    def _numbered_path(elt, squelch):
        # With "squelch" the path is presented for a human: a count is
        # only informative among like-named siblings, so the count of
        # an only child is omitted.  Without, every element carries
        # its count, for uniform consumption by a program.
        parts = []
        while elt is not None and isinstance(elt.tag, str):
            name = ET.QName(elt).localname
            position = 1 + sum(
                1
                for sib in elt.itersiblings(preceding=True)
                if isinstance(sib.tag, str) and ET.QName(sib).localname == name
            )
            alone = position == 1 and not any(
                isinstance(sib.tag, str) and ET.QName(sib).localname == name
                for sib in elt.itersiblings()
            )
            if squelch and alone:
                parts.append(name)
            else:
                parts.append("{}[{}]".format(name, position))
            elt = elt.getparent()
        return "/" + "/".join(reversed(parts))

    def _element_at_path(path):
        # follow a numbered path (as validation-plus produces); a
        # segment without a bracketed count means the only element
        # of that name at its location, so a count of one
        elt = tree_b.getroot()
        segments = path.strip("/").split("/")
        segment_pattern = re.compile(r"([^\[\]]+)(?:\[(\d+)\])?$")
        first = segment_pattern.match(segments[0])
        if not first or ET.QName(elt).localname != first.group(1):
            return None
        for segment in segments[1:]:
            match = segment_pattern.match(segment)
            if not match:
                return None
            name = match.group(1)
            position = int(match.group(2)) if match.group(2) else 1
            count = 0
            found = None
            for child in elt:
                if isinstance(child.tag, str) and ET.QName(child).localname == name:
                    count += 1
                    if count == position:
                        found = child
                        break
            if found is None:
                return None
            elt = found
        return elt

    def _excerpt(line_number):
        if 0 < line_number <= len(source_lines):
            text = source_lines[line_number - 1].strip()
            if len(text) > 100:
                text = text[:100] + "..."
            return text
        return None

    # assemble the consolidated report
    report = []
    banner = "=" * 70

    if not terse:
        report.extend(_validation_report_preamble(schema_filename, assembled_source))
        report.extend([banner, "Messages: RELAX-NG schema validation, from \"jing\"", banner, ""])
    # "jing" messages lead with filename:line:column.  The line number
    # refers to the assembled source (which is deposited alongside the
    # report), so it is reported as such, supplemented by the
    # originating file, a path into the assembled source, and an
    # excerpt of the offending text.  An element's extent is not
    # available, so for a message about a line where no element begins,
    # the location is the closest element beginning on an earlier line:
    # very often the container, and always a good place to start looking.
    location = re.compile(r"^.*?:(\d+):(\d+): (.*)$")
    for message in jing_messages:
        match = location.match(message)
        if not match:
            report.append(message)
            continue
        line_number = int(match.group(1))
        body = match.group(3)
        near = max((n for n in opening if n <= line_number), default=None)
        elt = opening[near] if near is not None else None
        filename = file_of.get(elt, main_file)
        # every schema message is one check, named "schema"
        if terse:
            path = _numbered_path(elt, False) if elt is not None else ""
            report.append(
                "{}\t{}\t{}\tschema\t{}".format(filename, path, line_number, body)
            )
        else:
            path = _numbered_path(elt, True) if elt is not None else ""
            report.append(body)
            report.append("    file: {}".format(filename))
            report.append("    path: {}".format(path))
            report.append("    line: {}".format(line_number))
            excerpt = _excerpt(line_number)
            if excerpt:
                report.append("    text: {}".format(excerpt))
            report.append("    check: schema")
            report.append("")
    if not terse and not jing_messages:
        report.extend(["(no messages)", ""])

    if not terse:
        report.extend([banner, "Messages: PreTeXt \"validation-plus\" stylesheet", banner, ""])
    plus_form = re.compile(r"^(PTX:[A-Z]+): (/\S+) (.*)$")
    # the message id trails the message text, set off in brackets
    id_form = re.compile(r"^(.*) \[([a-z0-9-]+)\]$")
    for message in plus_messages:
        match = plus_form.match(message)
        if not match:
            report.append(message)
            continue
        severity, path, body = match.group(1), match.group(2), match.group(3)
        id_match = id_form.match(body)
        if id_match:
            body, check_id = id_match.group(1), id_match.group(2)
        else:
            check_id = "no-validation-message-id-assigned"
        elt = _element_at_path(path)
        filename = file_of.get(elt, main_file)
        line_number = elt.sourceline if elt is not None else ""
        if terse:
            report.append(
                "{}\t{}\t{}\t{}\t{}: {}".format(
                    filename, path, line_number, check_id, severity, body
                )
            )
        else:
            # for a human, squelch the counts of only children
            if elt is not None:
                path = _numbered_path(elt, True)
            report.append("{}: {}".format(severity, body))
            report.append("    file: {}".format(filename))
            report.append("    path: {}".format(path))
            report.append("    line: {}".format(line_number))
            if elt is not None:
                excerpt = _excerpt(elt.sourceline)
                if excerpt:
                    report.append("    text: {}".format(excerpt))
            report.append("    check: {}".format(check_id))
            report.append("")
    if not terse and not plus_messages:
        report.extend(["(no messages)", ""])

    with open(reportname, "w") as f:
        f.write("\n".join(report))

    if jing_messages:
        log.info("schema validation raised {} messages".format(len(jing_messages)))
    if plus_messages:
        log.info("validation-plus stylesheet raised {} messages".format(len(plus_messages)))
    else:
        log.info("validation-plus stylesheet raised no messages")
    log.info("consolidated validation report in {}".format(reportname))
    log.info("locations refer to the assembled source in {}".format(assembled_source))


def _validation_report_preamble(schema_filename, assembled_source):
    """The fixed introductory text of a validation report"""

    return [
        "Validation Report",
        "=================",
        "",
        "Two tools have examined an assembled version of your source:",
        "",
        "  (1) \"jing\" checked conformance with the RELAX-NG schema at",
        "      {}".format(schema_filename),
        "      (a schema can only describe parent-child relationships,",
        "      plus the attributes of each element)",
        "  (2) the PreTeXt \"validation-plus\" stylesheet made checks that",
        "      no RELAX-NG schema could ever express, and offers extra",
        "      advice and explanation besides",
        "",
        "Locations refer to the ASSEMBLED version of your source: your",
        "modular source files have been knitted together, and any version",
        "support has been applied (as elected by a \"version\" element",
        "within the \"source\" element of the publication file you",
        "supplied).  In particular, an element excluded from the version",
        "being built cannot raise a message here.  The assembled source",
        "has been deposited at",
        "    {}".format(assembled_source),
        "",
        "Each message locates its problem four ways, and then names",
        "the check that raised it:",
        "",
        "    file:   the source file where the problem lies",
        "    path:   the location within the assembled source",
        "    line:   the line number within the assembled source",
        "    text:   an excerpt of the offending content",
        "    check:  a short name for the check (\"schema\" for any",
        "            message from \"jing\")",
        "",
        "Only \"file\" points into your own source files.  In particular,",
        "\"line\" is a line number of the deposited assembled source named",
        "above, never of one of your files.",
        "",
        "To read a \"path\", count elements of each name.  For example,",
        "",
        "    /pretext/book/chapter[7]/section[2]/p[13]/em[2]",
        "",
        "is the second \"em\" within the thirteenth \"p\" (paragraph) of the",
        "second \"section\" of the seventh \"chapter\" of the book.  Counts",
        "are of elements with the same name: that paragraph is the",
        "thirteenth \"p\" of its section, though other elements may precede",
        "it or intervene.  An element without a count, like the \"book\"",
        "above, is the only element of that name at its location, so a",
        "count would just be clutter.",
        "",
        "",
    ]


def _jing_server(schema_filename, assembled_source):
    """Validate the assembled source with a remote "jing" service.

    Returns the raw "jing" report as a list of lines -- a drop-in for the
    output of a local "jing" run on the same file -- or None if the server
    could not be reached (a clear error is logged in that case).
    """
    try:
        import requests  # post()
    except ImportError:
        raise ImportError(__module_warning.format("requests"))

    # A future move to a server more closely tied to the project need only
    # change this URL (and, if the reply format changes, the parsing below).
    server_url = "https://mathgenealogy.org:9000/validate"

    # The service expects "assembled_source" and "schema" plus the PreFigure
    # companions of the schema.  Here the "assembled_source" is the
    # single, already-assembled file, so the locations in the report line
    # up with the deposited assembled source, exactly as a local run does.
    tmp_dir = common.get_temporary_directory()

    # The service resolves the schema's includes from these companion
    # files, so they travel alongside the schema (see PR #3036).
    # The service expects all keys other than "assembled_source" and "schema"
    # to be the basename of any auxiliary schema files.
    schema_dir = os.path.join(common.get_ptx_path(), "schema")
    field_paths = {
        "assembled_source": assembled_source,
        "schema": schema_filename,
        "pf-adapter.rng": os.path.join(schema_dir, "pf-adapter.rng"),
        "pf_schema.rng": os.path.join(schema_dir, "pf_schema.rng"),
        "pf-preamble-adapter.rng": os.path.join(schema_dir, "pf-preamble-adapter.rng"),
    }

    log.info("communicating with validation server at {}".format(server_url))
    # The service is expecting to receive the files as strings in form fields,
    # so read files into strings stored in the data dictionary.
    # Use with so files are automatically closed after reading.
    data = dict()
    for field, path in field_paths.items():
        with open(path, "r", encoding="utf-8") as file:
            data[field] = file.read()

    try:
        r = requests.post(server_url, data=data, timeout=60)
    except requests.exceptions.RequestException as e:
        log.error("could not reach the validation server at {} ({})".format(server_url, e))
        log.error("no validation report was produced; retry, or validate with a local method")
        return None

    if r.status_code != 200:
        log.error("the validation server reported an error (code {}): {}".format(r.status_code, r.text.strip()))
        return None

    # Reduce the reply to the raw "jing" lines.  This service prefaces a
    # report with a fixed sentence, and answers with a success sentence
    # when there are no messages; a future service might return "jing"
    # output verbatim.  Handle all three.
    body = r.text
    if "Report from jing follows:" in body:
        body = body.split("Report from jing follows:", 1)[1]
    elif "no schema violations" in body:
        log.info("the source validates with no schema errors")
        return []
    return body.strip("\n").splitlines()


###################
#
# Utility Functions
#
###################


        

def python_version():
    """Return 'major.minor' version number as string/info"""

    return "{}.{}".format(sys.version_info[0], sys.version_info[1])


def check_python_version():
    """Raise an error for Python 2 (or less); warn for Python 3 before 3.10"""

    # This test could be more precise,
    # but only handling 2to3 switch when introduced
    msg = "".join(
        [
            "PreTeXt script/module expects Python 3.10, not Python 2 or older\n",
            "You have Python {}\n",
            "** Try prefixing your command-line with 'python3 ' **",
        ]
    )
    if sys.version_info[0] <= 2:
        raise (OSError(msg.format(python_version())))
    # Warn, but do not error, for Python 3 older than the minimum below
    #   2026-07-06: Python 3.10 or newer
    if sys.version_info[:2] < (3, 10):
        log.warning(
            "PreTeXt expects Python 3.10 or newer\n"
            "You have Python {}, and some operations may fail".format(
                python_version()
            )
        )












































def copy_html_js(work_dir):
    '''Copy all necessary CSS and JS into working directory'''

    # Place support files where expected.
    # We are not careful about placing only modules that are needed, all are copied.
    js_src = os.path.join(common.get_ptx_path(), "js")
    js_dest = os.path.join(work_dir, "_static", "pretext", "js")
    shutil.copytree(js_src, js_dest)











def get_journal_info(journal_name):
    """
    Returns a dictionary of data for a journal based on
    a master list of journals in journals/journals.xml.

    Arguments:
    journal_name: The code name of the journal to look up, such as bull-amer-math-soc. This is the <code> element of the journals.xml file, and will usually agree with the name of the texstyle file.
    """
    journal_xml = os.path.join(common.get_ptx_path(), "journals", "journals.xml")
    log.debug("Reading list of journals in {}".format(journal_xml))
    journals_tree = ET.parse(journal_xml)
    journals_tree.xinclude()

    # Find the node with <code> value journal_name:
    try:
        journal = journals_tree.xpath(f"//journal[code='{journal_name.lower()}']")[0]
    except Exception as e:
        log.warning("The journal name {} specified in the publication file is not supported.".format(journal_name))
        return {"latex-style": ""}

    # name, code, and publisher are nodes containing text
    keys = ["name", "code", "publisher"]
    journal_info = {}
    for key in keys:
        element = journal.find(key)
        journal_info[key] = element.text if element is not None else None
    # get the attribute values of the optional 'method' element.  Possible attributes are @latex-style, @texstyle, and @dependent
    if journal.find("method") is not None:
        for attr in ["latex-style", "texstyle", "dependent"]:
            if attr in journal.find("method").attrib:
                journal_info[attr] = journal.find("method").attrib[attr]

    # If any of these are not yet set (or are None), set them to the default values
    journal_info["latex-style"] = journal_info.get("latex-style", "texstyle")
    journal_info["texstyle"] = journal_info.get("texstyle", journal_info.get("code"))
    journal_info["dependent"] = journal_info.get("dependent", "no")
    log.debug("Using the journal code {} as the texstyle value.".format(journal_info.get("texstyle")))

    # If the latex-style is "texstyle", then find a filename for the texstyle file (as a relative path inside journals/texstyles).  What this is depends on whether dependent is "yes"
    if journal_info["latex-style"] == "texstyle":
        # If dependent is "yes", then we need to set the texstyle-file to the filename of the texstyle file, which is the code value.
        if journal_info["dependent"] == "yes":
            journal_info["texstyle-file"] = "dependents/" + journal_info.get("texstyle") + ".xml"
            log.debug("Using texstyle-file {}.".format(journal_info["texstyle-file"]))
        # If dependent is "no", then we need to set the texstyle-file to the filename of the texstyle file, which is the code value.
        else:
            journal_info["texstyle-file"] =  journal_info.get("texstyle") + ".xml"
            log.debug("Using texstyle-file {}.".format(journal_info["texstyle-file"]))

    return journal_info

def place_latex_package_files(dest_dir, journal_name, cache_dir):
    """
    Check whether the latex requires additional files specified in a texstyle file.
    If so, either copy them from cache_dir or download them from the internet (and also store a copy in the cache_dir).
    """
    # Get the texstyle file for the journal name
    texstyle_file = get_journal_info(journal_name).get("texstyle-file")
    # Double check that there is a texstyle file
    if texstyle_file is None:
        return
    # Otherwise, parse this file and check for any <file> elements.
    texstyle_tree = ET.parse(os.path.join(common.get_ptx_path(), "journals", "texstyles", texstyle_file))
    texstyle_file_elements = texstyle_tree.xpath("//required-files/file")
    if not texstyle_file_elements:
        log.debug("No required files found in the texstyle file.")
        return
    # Check whether the journal code is present in the metadata element of the texstyle file
    journal_code = texstyle_tree.xpath("//metadata/code")[0].text
    cache_dir = os.path.join(cache_dir, journal_code)
    # Create the cache_dir if it doesn't exist
    os.makedirs(cache_dir, exist_ok=True)

    for file in texstyle_file_elements:
        file_path = os.path.join(cache_dir, file.attrib["name"])
        if not os.path.exists(file_path):
            # download the file if it is not already in the cache_dir
            log.debug("Downloading required file {} from {}".format(file.attrib["name"], file.attrib["href"]))
            url = file.attrib["href"]
            # The url might be to the file, or to a compressed archive.  We do slightly different things in each case.  TODO: other archive formats.
            if url.endswith(".zip"):
                tmp_zip = os.path.join(cache_dir, "tmp.zip")
                common.download_file(url, tmp_zip)
                with zipfile.ZipFile(tmp_zip, 'r') as zip_ref:
                    with open(file_path, 'wb') as f:
                        f.write(zip_ref.read(file.attrib["path"]))
                os.remove(tmp_zip)
            else:
                common.download_file(url, file_path)
            log.debug("Saved file {} to {}".format(file.attrib["name"], file_path))
        else:
            log.debug("File {} already exists in the generated assets directory.".format(file.attrib["name"]))
        # Copy required resource to the destination directory
        shutil.copy2(file_path, dest_dir)


class Stopwatch:
    """A simple stopwatch class for measuring elapsed time.

    print_log controls whether log messages are printed when the log() is called
    """

    def __init__(self, name:str="", print_log:bool=True):
        self.name = name
        self.print_log = print_log
        self.start_time = time.time()
        self.last_log_time = self.start_time

    def reset(self):
        """Reset the log timer to the current time."""
        self.last_log_time = time.time()

    def log(self, timepoint_description:str=""):
        """Print a log message with the elapsed time since the last log event."""
        if self.print_log:
            cur_time = time.time()
            elapsed_time = cur_time - self.start_time
            since_last_log_time = cur_time - self.last_log_time
            self.reset()
            log.info(f"** Timing report from {self.name}: {timepoint_description}, {since_last_log_time:.2f}s since last watch reset. {elapsed_time:.2f}s total elapsed time.")


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






# Re-export helpers relocated to "common.py" so the public ptx.NAME
# interface used by the driver script is unchanged.
PreTeXtFatal = common.PreTeXtFatal
build_info_message = common.build_info_message
download_file = common.download_file
get_executable_cmd = common.get_executable_cmd
get_managed_directories = common.get_managed_directories
get_platform_host = common.get_platform_host
get_ptx_path = common.get_ptx_path
get_ptx_xsl_path = common.get_ptx_xsl_path
get_publisher_variable_report = common.get_publisher_variable_report
release_temporary_directories = common.release_temporary_directories
set_executables = common.set_executables
set_ptx_path = common.set_ptx_path
verify_input_directory = common.verify_input_directory
xsltproc = common.xsltproc



# Re-export webwork routines so the public ptx.NAME interface is unchanged.
webwork_to_xml = webwork.webwork_to_xml
webwork_sets = webwork.webwork_sets
pg_macros = webwork.pg_macros



# Re-export stack routines so the public ptx.NAME interface is unchanged.
stack_extraction = stack.stack_extraction
