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

    # Resulting prefigure files are in tmp_dir, switch there to work
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

        # Need to copy entire "external" directory
        # Also data (e.g. for plots) is made available
        # NB: we might really do this sooner, but then all
        # the files in "external" and "data" get added
        # into the list of source files, pf_source_files
        _, external_dir = get_managed_directories(xml_source, pub_file)
        data_dir = get_source_directories(xml_source)
        copy_managed_directories(tmp_dir, external_abs=external_dir, data_abs=data_dir)

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
    data_dir = get_source_directories(xml_source)
    copy_managed_directories(tmp_dir, external_abs=external_dir, data_abs=data_dir)
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
    ptx_dir = get_ptx_path()
    ptx_xsl_dir = get_ptx_xsl_path()
    node_exec_cmd = get_executable_cmd("node")
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
    tmp_dir = get_temporary_directory()
    json_file = os.path.join(tmp_dir, "dynamic-setup.json")
    log.info("Creating temporary dynamic exercise setup JSON: {}".format(json_file))
    xsltproc(extraction_xslt, xml_source, json_file, tmp_dir, stringparams)

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

    # Various directories need to be established
    # These first two are the source folders which may not have the usual names
    # "generated" and "external"
    generated_dir, external_dir = get_managed_directories(xml_source, pub_file)
    if generated_dir:
        # create the generated_dir if it doesn't actually exist yet
        if not (os.path.isdir(generated_dir)):
            os.mkdir(generated_dir)
        # where the representations file will live
        ww_reps_dir = os.path.join(generated_dir, "webwork")
        # where generated images from webwork exercises will live
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

    # file path for the representations file
    ww_reps_file = os.path.join(ww_reps_dir, "webwork-representations.xml")

    # execute XSL extraction to get back a tree with fundamental
    # information about webwork exercises in the project
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-pg.xsl")

    # Build the tree into a scratch file
    tmp_dir = get_temporary_directory()
    extracted_pg_filename = os.path.join(tmp_dir, "extracted-pg.xml")
    log.debug("Exctracted PG temporarily in {}".format(extracted_pg_filename))
    xsltproc(extraction_xslt, xml_source, extracted_pg_filename, None, stringparams)

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
            webwork2_domain = sanitize_url(split_server_params[0])
            courseID = sanitize_alpha_num_underscore(split_server_params[1])
            user = sanitize_alpha_num_underscore(split_server_params[2])
            passwd = sanitize_alpha_num_underscore(split_server_params[3])
        else:
            webwork2_domain = sanitize_url(server_params)
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
        webwork2_domain = sanitize_url(server_params_pub["webwork2_domain"])
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
        global __module_warning
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
        raise ValueError(msg.format(ww_version, ww_domain))

    # using a "Session()" will pool connection information
    # since we always hit the same server, this should increase performance
    if need_for_webwork2:
        webwork2_session = requests.Session()

    clientsocket = None

    if need_for_socket:
        import socket
        import json

        perl_executable_cmd = get_executable_cmd('perl')[0]
        pgscript = os.path.join(get_ptx_path(), 'script', 'webwork', 'pg-ptx.pl')

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

    # begin XML tree
    # then we loop through all problems, appending children
    NSMAP = {"xml": "http://www.w3.org/XML/1998/namespace"}
    XML = "http://www.w3.org/XML/1998/namespace"
    webwork_representations = ET.Element("webwork-representations", nsmap=NSMAP)
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
            log.info(msg.format(problem, ww_reps_file, origin[problem]))
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
            log.info(msg.format(problem, ww_reps_file, origin[problem]))
            if origin[problem] == "webwork2":
                log.debug(
                    "server-to-ptx: {}\n{}\n{}\n{}".format(
                        problem, webwork2_path, path[problem], ww_reps_file
                    )
                )
            elif origin[problem] == "generated":
                log.debug(
                    "server-to-ptx: {}\n{}\n{}\n{}".format(
                        problem, webwork2_path, pgdense[problem], ww_reps_file
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
        graphics_pattern = re.compile(r'<image.*?source="([^"]*)"')

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

        # Use "webwork-reps" as parent tag for the various representations of a problem
        webwork_reps = ET.SubElement(webwork_representations, "webwork-reps")
        # There once was a "version 1" structure to the representations file before "version 2".
        # For a while, both were supported. Neither was officially defined anywhere, and now
        # "version 1" is a thing of the past. We still mark the current representations file as
        # "version 2" here, but it has no effect as all the code elsewhere now assumes "version 2".
        webwork_reps.set("version", "2")
        webwork_reps.set("webwork2_major_version", str(webwork2_major_version))
        webwork_reps.set("webwork2_minor_version", str(webwork2_minor_version))
        webwork_reps.set("{%s}id" % (XML), "extracted-" + problem)
        webwork_reps.set("ww-id", problem)
        static = ET.SubElement(webwork_reps, "static")
        static.set("seed", seed[problem])
        if origin[problem] == "webwork2":
            static.set("source", path[problem])

        # If there is "badness"...
        # Build 'shell' problems to indicate failures
        if badness:
            log.error(badness_msg.format(path[problem], seed[problem], badness_tip))
            static.set("failure", badness_type)
            statement = ET.SubElement(static, "statement")
            p = ET.SubElement(statement, "p")
            p.text = badness_msg.format(path[problem], seed[problem], badness_tip)
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
    try:
        webwork2_session.close()
    except:
        pass

    # close the socket
    if clientsocket:
        clientsocket.send(b'quit')

################################
#
#  WeBWorK Problem Sets
#
################################


def webwork_sets(xml_source, pub_file, stringparams, dest_dir, tgz, need_macros):

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
    if need_macros:
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
    pub_vars = get_publisher_variable_report(xml_source, pub_file, stringparams)
    # style file name selected by the publisher, no path information
    # citeproc-py looks in their DATAPATH/STYLES_PATH = data/styles
    # so place by a given style file by hand right now
    # Call below does not need an extension, so we do not supply it
    csl_style = get_publisher_variable(pub_vars, 'csl-style-file')
    # XSL "value-of" for boolean reports strings "true" or "false"
    using_csl_styles = get_publisher_variable(pub_vars, 'b-using-csl-styles')

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
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-biblio-csl.xsl")

    # And a place to work and a file there for result tree
    tmp_dir = get_temporary_directory()
    biblio_xml = os.path.join(tmp_dir, "biblio-csl.xml")

    # Harvest bibliographic items and citations, converted to JSON
    xsltproc(extraction_xslt, xml_source, biblio_xml, None, stringparams)

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

def mermaid_images(xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat):

    import glob  # locate *.mmd files
    import json  # Mermaid configuration files

    msg = 'converting Mermaid diagrams from {} to {} graphics for placement in {}'
    log.info(msg.format(xml_source, outformat, dest_dir))

    mmd_executable_cmd = get_executable_cmd("mermaid")
    log.debug("Mermaid executable command: {}".format(mmd_executable_cmd))

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
    mermaid_layout_engine = get_publisher_variable(pub_vars, 'mermaid-layout-engine')

    # Resulting *.mmd files are in tmp_dir, switch there to work
    with working_directory(tmp_dir):
        # Write a config file as JSON in working directory
        mmd_config = {
            "theme": mermaid_theme,
            "layout": mermaid_layout_engine
        }
        mmd_config_file = os.path.join(tmp_dir, "mermaid-config.json")
        with open(mmd_config_file, 'w') as config_file:
            json.dump(mmd_config, config_file, indent=4)
        log.debug("Mermaid configuration file: {}".format(mmd_config_file))
        # loop over each diagram
        for mmddiagram in glob.glob(os.path.join(tmp_dir, "*.mmd")):
            filebase, _ = os.path.splitext(mmddiagram)
            # file format PNG or SVG
            # mmdc executable just switches on filename extension
            if outformat in ["png", "svg"]:
                mmdout = "{}.{}".format(filebase, outformat)
            else:
                log.error("cannot make Mermaid diagrams in {} file format".format(outformat))
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

# 2025-08-16: verbatim from
#   https://github.com/PreTeXtBook/pretext/pull/2576
# procedure name modified
def _stack_replace_latex(text):
    text = re.sub(r"\\\((.*?[^\\])\\\)", r"<m>\1</m>", text)
    text = re.sub(r"\\\[(.*?[^\\])\\]", r"<me>\1</me>", text)
    # We may want to detect align/similar environments inside \[\] and replace them with
    # <md></md> using <mrow></mrow> for each row and \amp for alignment (also \lt, \gt)
    return text

# 2025-08-16: verbatim from
#   https://github.com/PreTeXtBook/pretext/pull/2576
# procedure name modified
def _stack_process_response(qdict):
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
        qtext = qtext.replace(f"[[input:{ansid}]]", f'<fillin characters="{width}" name="{ansid}"/>')

    qtext = _stack_replace_latex(qtext)
    soltext = _stack_replace_latex(soltext)

    return f'''
    <statement>{qtext}</statement>
    <solution>{soltext}</solution>
    ''' + "\n".join(f"<answer>{ans}</answer>" for ans in answers)

def stack_extraction(xml_source, pub_file, stringparams, xmlid_root, dest_dir ):
    '''Convert a STACK question to a static PreTeXt version via a STACK server'''

    import json
    import urllib

    try:
        import requests  # to access STACK server
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("requests"))

    pub_vars = get_publisher_variable_report(xml_source, pub_file, stringparams)
    stack_server = get_publisher_variable(pub_vars, 'stack-server')
    api_url = urllib.parse.urljoin(stack_server, 'render')
    log.info(f"Using STACK API at {api_url}")

    os.makedirs(dest_dir, exist_ok=True)
    msg = 'converting STACK exercises from {} to static forms for placement in {}'
    log.info(msg.format(xml_source, dest_dir))

    tmp_dir = get_temporary_directory()
    log.debug("temporary directory: {}".format(tmp_dir))
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-stack.xsl")

    # support publisher file, subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    if xmlid_root:
        stringparams["subtree"] = xmlid_root

    log.info("extracting STACK exercises from {}".format(xml_source))
    log.info("string parameters passed to extraction stylesheet: {}".format(stringparams) )
    # place verbatim copies of STACK XML into a temporary directory
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)

    # Course over files in temporary directory,
    # converting to PreTeXt XML. Innermosat loop
    # is modeled after work provided in
    #   https://github.com/PreTeXtBook/pretext/pull/2576
    with working_directory(tmp_dir):
        for stack_file in os.listdir(tmp_dir):
            # form output file now, for diagnostic
            # message before it is needed
            # just change extension, easy
            pretext_file = os.path.join(dest_dir, stack_file.replace('.xml', '.ptx'))
            msg = 'converting STACK question file "{}/{}" to static PreTeXt XML file "{}"'
            log.debug(msg.format(tmp_dir, stack_file, pretext_file))

            # Open STACK XML file, send to server, unravel JSON response into
            # a text version of the static PreTeXt XML question
            question_data = open(stack_file).read()
            # JSON blob for STACK API server request
            # TODO: accomodate per-question seed somehow (interrogate XML?)
            request_data = {"questionDefinition": question_data, "seed": None}
            question_json = requests.post(api_url, json=request_data)
            question_dict = json.loads(question_json.text)
            response = _stack_process_response(question_dict)
            # response needs to be a single element, XSL uses it
            # TODO: maybe STACK server can provide this wrapper
            wrap_response = "<stack-static>\n{}\n</stack-static>"
            question_pretext = wrap_response.format(response)

            # PreTeXt filename formed above, write result into dest_dir
            # This well-formed XML file will get picked up by the
            # pretext-assembly.xsl stylesheet as part of forming a version
            # of source suitable for static output formats (that are not
            # as capable as HTML)
            with open(pretext_file, 'w', encoding='utf-8') as ptxfile:
                ptxfile.write(question_pretext)
                ptxfile.close()


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
        global __module_warning
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
                # wait again, according to the value of the timeout,
                # for more than just splash screens, etc
                await page.wait_for_timeout(timeout)
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

    # Translate the fast/slow timeout to a time in milliseconds
    timeout = 10000 if method == "slow" else 5000

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
                generate_previews(interactives, baseurl, dest_dir, timeout)
            )
            # if this blows up, search for 'asyncio.get_event_loop() warning' in this file
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
    import PIL.Image # save images provided by MOM
    import shutil
    import asyncio # for playwright

    # to ensure provided stringparams aren't mutated unintentionally
    stringparams = stringparams.copy()

    try:
        import requests  # to access MyOpenMath server
    except ImportError:
        global __module_warning
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
                    except Exception as e:
                        log.error(f"Unable to read image width of {image_path}: {e}")

                    image_element.set("width", f"{imgwidthtag}%")
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

                    # convert to PDF
                    asyncio.get_event_loop().run_until_complete(write_pdf(svg_string))
                    # asyncio.get_event_loop() warning: this code assumes we are running from an synchronous context.
                    # If called from some asynch function, by an outside tool, this will break. As will other uses in this file.
                    # For a possible emergency fix see:
                    # https://github.com/RunestoneInteractive/rs/pull/723
                    # nested_asyncio did not work for RS as there were conflicts with other libraries.
                    # get_event_loop is deprecated, so at some point we need to replace it - a permanent fix at that point would be nice
                    # Official advice appears to be "rewrite anything that uses async to be async all the way up"
                    # https://discuss.python.org/t/calling-coroutines-from-sync-code-2/24093/5
                    # this warning referenced in other places... search for 'asyncio.get_event_loop() warning'

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
    from . import braille_format as braille

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
        except Exception as e:
            msg = 'PTX:BUG: error copying image with sourcename "{}" and filename "{}".  Traceback follows:'
            # traceback.print_exc()
            log.warning(msg.format(sourcename, filename))
            log.warning(traceback.format_exc())

    # clean-up the trash
    # TODO: squelch knowls or find alternative
    # shutil.rmtree(os.path.join(tmp_dir, 'knowl'))
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
    elif file_format == 'nozip':
        copy_build_directory(tmp_dir, dest_dir)
        msg = 'EPUB build files produced, but not zipped into a single file; results placed in {}'
        log.info(msg.format(dest_dir))
    else:
        msg = 'PTX:BUG: conversion to EPUB got an unrecognized file format ("{}").  No output results.'
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

    # Set a user-agent to mimic a browser. This is what chrome on windows sends as of 2025-11-19.
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36'}

    try:
        services_response = requests.get(url, timeout=(1,10), headers=headers)
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
    # Consult source for additional files
    data_dir = get_source_directories(xml)

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
    # Build SCORM manifest if requested
    if file_format == "scorm":
        stringparams["html.scorm"] = "yes"
    # Optional extra XSL could be None, or sanitized full filename
    if extra_xsl:
        extraction_xslt = extra_xsl
    else:
        extraction_xslt = os.path.join(get_ptx_xsl_path(), "pretext-html.xsl")

    # place managed directories - some of these (Asymptote HTML) are
    # consulted during the XSL run and so need to be placed beforehand
    copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs, data_abs=data_dir)

    if include_static_files:
        # Copy js and css, but only if not building portable html
        # place JS in scratch directory
        copy_html_js(tmp_dir)

        # build or copy theme
        build_or_copy_theme(xml, pub_vars, tmp_dir)

    # Write output into temporary directory
    log.info("converting {} to HTML in {}".format(xml, tmp_dir))
    xsltproc(extraction_xslt, xml, None, tmp_dir, stringparams)

    if not(include_static_files):
        # remove latex-image generated directories for portable builds
        shutil.rmtree(os.path.join(tmp_dir, "generated", "latex-image"), ignore_errors=True)

    if file_format  == "html":
        # with multiple files, we need to copy a tree
        # see comments at  copy_build_directory()
        # before replacing with  shutil.copytree()
        copy_build_directory(tmp_dir, dest_dir)
    elif file_format == "zip" or file_format == "scorm":
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
                        # Avoid recursively zipping the zip file
                        # Small chance we might be clobbering an existing
                        # "html-output.zip" that could be part of a project.
                        # TODO: zip directly into the derivedname below?
                        #       Or, zip into some new temporary directory?
                        if name != zip_file:
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
    else:
        log.error("assembly method {} not recognized".format(method))
    # "extra_xsl" would be silly in this context (?)
    extraction_xslt = os.path.join(
        get_ptx_xsl_path(), "utilities", "pretext-enhanced-source.xsl"
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
    else:
        log.error("assembly method {} not recognized".format(method))
    # use the right xsl template
    extraction_xslt = os.path.join(
        get_ptx_xsl_path(), "utilities", "pretext-enhanced-source.xsl"
    )
    log.debug("converting {} to enhanced (pre-processed) PreTeXt source for internal use".format(xml))
    return xsltproc(extraction_xslt, xml, None, None, stringparams)

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
    pub_vars = get_publisher_variable_report(xml, pub_file, stringparams)
    journal_name = get_publisher_variable(pub_vars, "journal-name")
    pub_latex_style = get_publisher_variable(pub_vars, "latex-style")
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
    pub_vars = get_publisher_variable_report(xml, pub_file, stringparams)
    journal_name = get_publisher_variable(pub_vars, "journal-name")
    if journal_name:
        tmp_dir = get_temporary_directory()
        # place_latex_package_files checks if tmp_dir already has the files, which it won't, so new files will always be downloaded.
        dest_dir = os.path.join(dest_dir, journal_name)
        place_latex_package_files(dest_dir, journal_name, tmp_dir)
        log.info("latex package files downloaded to " + dest_dir)
    else:
        log.warning("No journal name found in publication file, so no latex package files downloaded.")


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


def pdf(xml, pub_file, stringparams, extra_xsl, out_file, dest_dir, method, outputs):
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

    generated_abs, external_abs = get_managed_directories(xml, pub_file)
    # Consult source for additional files
    data_dir = get_source_directories(xml)

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

    # Make data files available, such as for TikZ images
    copy_managed_directories(tmp_dir, external_abs=external_abs, generated_abs=generated_abs, data_abs=data_dir)

    # If we are building for a journal, we might need extra files
    pub_vars = get_publisher_variable_report(xml, pub_file, stringparams)
    journal_name = get_publisher_variable(pub_vars, "journal-name")
    if journal_name:
        place_latex_package_files(tmp_dir, journal_name, os.path.join(generated_abs, "latex-packages"))

    # If requested, copy the LaTeX source and asset folders to dest_dir.
    # Note that outputs == "all" needs to wait until after the build to copy build_dir.
    if outputs == "all-clean" or outputs == "prebuild":
        copy_build_directory(tmp_dir, dest_dir)
        # prebuild means no pdf, so stop here.
        if outputs == "prebuild":
            return

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

        # If we want all outputs, we copy the entire build directory now that the PDF is built
        # so we can get the *.log, *.aux, etc build files.
        if outputs == "all":
            copy_build_directory(tmp_dir, dest_dir)
        else:
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

    Return: an lxml element tree data structure of the result.
    This is whatever the stylesheet creates in the file whose name
    is given by the `result` argument.  It could be empty, or it might
    be only a partial result of the stylesheet, since the stylesheet
    could independently produce multiple files with fixed names.  This
    return value may be useful to consumers of this module (and that
    is the intent).  Normally the return value is ignored.
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
    src_tree = guarded_xml_include_parser(xml)

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
        # Regardless, return the result_tree, which might be useful for the calling function
        return result_tree
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


def guarded_xml_include_parser(xml):
    """
    Attempt parsing of XML including xi:includes processing.
    Returns an lxml element tree.
    On error, generate readable exception trace.
    """

    # Seems a depth of 256 was exceeded for an SVG image:
    # lxml.etree.XMLSyntaxError: Excessive depth in document: 256 use XML_PARSE_HUGE option
    huge_parser = ET.XMLParser(huge_tree=True)
    src_tree = ET.parse(xml, parser=huge_parser)
    try:
        # Try using default xinclude() first. But it does not generate good error messages.
        # So on exception, we redo with a custom loader that will give better error messages.
        # Undefined namespace prefixes (e.g. xi:) go in error log of XInclude object
        # but do not cause it to fail/throw
        includer = ET.XInclude()
        includer(src_tree.getroot())
        if includer.error_log:
            namespace_xi_error = False
            log.debug("XInclude error(s) found:")
            for line in includer.error_log:
                log.debug(f"* {line.message}")
                if "Namespace prefix xi on include is not defined" in line.message:
                    log.error("You are trying to use 'xi:include' in a file that does not contain 'xmlns:xi=\"http://www.w3.org/2001/XInclude\"' in its root element.")
                    namespace_xi_error = True
            # If the error was due to an undefined namespace prefix, raise an error
            if namespace_xi_error:
                raise ET.XIncludeError("Missing namespace declaration for 'xi'")
        return src_tree
    except ET.XIncludeError as e:
        # xinclude() does not show what file a parsing error occured in
        # So if there was an error, build a custom loader and redo with ElementInclude
        # which will include the file name in the stack dump.
        # ElementInclude is a limited version of xinclude(), so can't rely
        # on it for the real include process.

        # Generate custom loader
        from lxml import ElementInclude
        def my_loader(href, parse, encoding=None, parser=None):
            try:
                ret = ElementInclude._lxml_default_loader(href, parse, encoding, parser)
            except Exception as e:
                log.error(f"Error loading {href}: {e}")
                raise
            return ret

        # Reparse the tree (was modified in try clause) and run ElementInclude
        # This should also fail, but will give a better error message
        # NB this might report false positives (duplicate xml:id even if controlled by versions)
        src_tree = ET.parse(xml, parser=huge_parser)
        ElementInclude.include(src_tree, loader=my_loader, max_depth=100)
        return src_tree # should never actually reach
        

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
        # full path to pretext.py module file itself
        # <distribution-root>/pretext/lib/pretext.py
        this_file_path = os.path.abspath(__file__)
        # split off "python.py" off module's full path
        lib_path, _ = os.path.split(this_file_path)
        # now split off the "lib" directory
        module_dir, _ = os.path.split(lib_path)
        # now split off "pretext" directory
        # to arrive at the root of the distribution
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
    # some parameterized error messages used later
    pub_abs_path_error = " ".join(
        [
            "the directory path for a managed directory, given in the",
            'publisher file as "source/directories/@{}" must be relative to',
            'the PreTeXt source file location, and not the absolute path "{}"',
        ]
    )
    pub_missing_dir_error = " ".join(
        [
            'the directory "{}" implied by the value "{}" in the',
            '"source/directories/@{}" entry of the publisher file does not',
            "exist. Check the spelling, create the necessary directory, or entirely",
            'remove the whole "source/directories" element of the publisher file.'
        ]
    )

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
            # attribute absent => None
            if gen_attr in attributes_dict.keys():
                raw_path = attributes_dict[gen_attr]
                if os.path.isabs(raw_path):
                    raise ValueError(pub_abs_path_error.format(gen_attr, raw_path))
                else:
                    abs_path = os.path.join(source_dir, raw_path)
                try:
                    generated = verify_input_directory(abs_path)
                except:
                    raise ValueError(pub_missing_dir_error.format(abs_path, raw_path, gen_attr))
            # attribute absent => None
            if ext_attr in attributes_dict.keys():
                raw_path = attributes_dict[ext_attr]
                if os.path.isabs(raw_path):
                    raise ValueError(pub_abs_path_error.format(ext_attr, raw_path))
                else:
                    abs_path = os.path.join(source_dir, raw_path)
                try:
                    external = verify_input_directory(abs_path)
                except:
                    raise ValueError(pub_missing_dir_error.format(abs_path, raw_path, ext_attr))

    # pair of discovered absolute paths
    return (generated, external)


def get_source_directories(xml_source):
    '''Directories given in source's "docinfo" element'''

    # Examine <source>/docinfo/directories element carefully
    # for attributes which we code here for convenience
    data_attr = "data"

    # prepare for relative paths later
    source_dir = get_source_path(xml_source)

    # some parameterized error messages used later
    source_abs_path_error = " ".join(
        [
            "the directory path for a managed directory, given in the",
            'source file as "docinfo/directories/@{}" must be relative to',
            'the PreTeXt source file location, and not the absolute path "{}"',
        ]
    )
    source_missing_dir_error = " ".join(
        [
            'the directory "{}" implied by the value "{}" in the',
            '"docinfo/directories/@{}" entry of the source file does not',
            "exist. Check the spelling, create the necessary directory, or entirely",
            'remove the whole "docinfo/directories" element of the source file.'
        ]
    )

    # Data holds files necessary for building parts
    # of a project, and are only necessary for that role.
    # As a component of the source it is given in the "docinfo"
    data = None

    src_tree = guarded_xml_include_parser(xml_source)
    directories_list = src_tree.xpath("/pretext/docinfo/directories")
    if directories_list:
        attributes_dict = directories_list[0].attrib
        if data_attr in attributes_dict:
            raw_path = attributes_dict[data_attr]
            if os.path.isabs(raw_path):
                raise ValueError(source_abs_path_error.format(data_attr, raw_path))
            else:
                abs_path = os.path.join(source_dir, raw_path)
            try:
                data = verify_input_directory(abs_path)
            except:
                raise ValueError(source_missing_dir_error.format(abs_path, raw_path, data_attr))

    return data


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


def copy_managed_directories(build_dir, external_abs=None, generated_abs=None, data_abs=None):
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

    if data_abs is not None:
        generated_dir = os.path.join(build_dir, "data")
        shutil.copytree(data_abs, generated_dir)


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

    Arguments:
    journal_name: The code name of the journal to look up, such as bull-amer-math-soc. This is the <code> element of the journals.xml file, and will usually agree with the name of the texstyle file.
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
    texstyle_tree = ET.parse(os.path.join(get_ptx_path(), "journals", "texstyles", texstyle_file))
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
                download_file(url, tmp_zip)
                with zipfile.ZipFile(tmp_zip, 'r') as zip_ref:
                    with open(file_path, 'wb') as f:
                        f.write(zip_ref.read(file.attrib["path"]))
                os.remove(tmp_zip)
            else:
                download_file(url, file_path)
            log.debug("Saved file {} to {}".format(file.attrib["name"], file_path))
        else:
            log.debug("File {} already exists in the generated assets directory.".format(file.attrib["name"]))
        # Copy required resource to the destination directory
        shutil.copy2(file_path, dest_dir)



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
