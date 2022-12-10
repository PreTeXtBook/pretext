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
# 2021-05-21: this module expects Python 3.6 or newer
#     copying HTML into cwd twice, might be better with
#     shutil.copytree(dirs_exist_ok), requires Python 3.8
#     see comments near copytree() and copy_tree()
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

# primarily directory manipulations (creating, switching)
import os

# primarily joining paths, but sometimes splitting
import os.path

# primarily copying entire directory trees of files, also which()
# TODO: copy() vs copy2() vs copyfile() vs copyfileobj()?
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
    owd = os.getcwd()
    os.chdir(tmp_dir)
    html_file = mjoutput
    with fileinput.FileInput(html_file, inplace=True) as file:
        for line in file:
            print(xhtml_elt.sub(repl, line), end="")
    os.chdir(owd)

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


def asymptote_conversion(
    xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat, method
):
    """Extract asymptote code for diagrams and convert to graphics formats"""
    # stringparams is a dictionary, best for lxml parsing
    # method == 'local': use a system executable from pretext.cfg
    # method == 'server': hit a server at U of Alberta, Asymptote HQ
    #
    # If buggy, and server/communication is suspected, try an Asy
    # source file generated by this script (located in temporary
    # directory preserved by -vv), using, e.g.,
    #   curl --data-binary @source.asy 'asymptote.ualberta.ca:10007?f=svg' > output.svg
    import glob

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
    os.chdir(tmp_dir)
    devnull = open(os.devnull, "w")
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
        # setup, depending on the method
        if method == "local":
            asy_executable_cmd = get_executable_cmd("asy")
            # perhaps replace following stock advisory with a real version
            # check using the (undocumented) distutils.version module, see:
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
            asy_cli = asy_executable_cmd + ["-f", outform]
            if outform in ["pdf", "eps"]:
                asy_cli += ["-noprc", "-iconify", "-tex", "xelatex", "-batchMask"]
            elif outform in ["svg", "png"]:
                asy_cli += ["-render=4", "-tex", "xelatex", "-iconify"]
        if method == "server":
            alberta = "http://asymptote.ualberta.ca:10007?f={}".format(outform)
        # loop over .asy files, doing conversions
        for asydiagram in glob.glob(os.path.join(tmp_dir, "*.asy")):
            filebase, _ = os.path.splitext(asydiagram)
            asyout = "{}.{}".format(filebase, outform)
            log.info("converting {} to {}".format(asydiagram, asyout))
            # do the work, depending on method
            if method == "local":
                asy_cmd = asy_cli + [asydiagram]
                log.debug("asymptote conversion {}".format(asy_cmd))
                subprocess.call(asy_cmd, stdout=devnull, stderr=subprocess.STDOUT)
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
    xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat
):

    # To make all four formats, just call this routine
    # four times and halt gracefully with an explicit "return"
    if outformat == "all":
        log.info('Pass 1 for "all" formats, now generating PDF')
        sage_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, "pdf")
        log.info('Pass 2 for "all" formats, now generating SVG')
        sage_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, "svg")
        log.info('Pass 3 for "all" formats, now generating PNG')
        sage_conversion(xml_source, pub_file, stringparams, xmlid_root, dest_dir, "png")
        log.info('Pass 4 for "all" formats, now generating HTML')
        sage_conversion(
            xml_source, pub_file, stringparams, xmlid_root, dest_dir, "html"
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
    os.chdir(tmp_dir)
    devnull = open(os.devnull, "w")
    for sageplot in os.listdir(tmp_dir):
        filebase, _ = os.path.splitext(sageplot)
        sageout = "{0}.{1}".format(filebase, outformat)
        sage_cmd = sage_executable_cmd + [sageplot]
        log.info("converting {} to {}".format(sageplot, sageout))
        log.debug("sage conversion {}".format(sage_cmd))
        subprocess.call(sage_cmd, stdout=devnull, stderr=subprocess.STDOUT)
        shutil.copy2(sageout, dest_dir)


def latex_image_conversion(
    xml_source, pub_file, stringparams, xmlid_root, dest_dir, outformat, method
):
    # stringparams is a dictionary, best for lxml parsing

    # external module, often forgotten
    try:
        import pdfCropMargins
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("pdfCropMargins"))

    log.info(
        "converting latex-image pictures from {} to {} graphics for placement in {}".format(
            xml_source, outformat, dest_dir
        )
    )
    # for killing output
    devnull = open(os.devnull, "w")
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
    # copytree() does not overwrite since tmp_dir is created anew on each use
    _, external_dir = get_managed_directories(xml_source, pub_file)
    if external_dir:
        external_dest = os.path.join(tmp_dir, "external")
        shutil.copytree(external_dir, external_dest)
    # now create all the standalone LaTeX source files
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-latex-image.xsl")
    # no output (argument 3), stylesheet writes out per-image file
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, stringparams)
    # now work in temporary directory
    os.chdir(tmp_dir)
    # and maintain a list of failures for later
    failed_images = []
    # files *only*, from top-level
    files = list(filter(os.path.isfile, os.listdir(tmp_dir)))
    for latex_image in files:
        if outformat == "source":
            shutil.copy2(latex_image, dest_dir)
            log.info("copying {} to {}".format(latex_image, dest_dir))
        else:
            filebase, _ = os.path.splitext(latex_image)
            latex_image_pdf = "{}.pdf".format(filebase)
            latex_image_svg = "{}.svg".format(filebase)
            latex_image_png = "{}.png".format(filebase)
            latex_image_eps = "{}.eps".format(filebase)
            # process with a  latex  engine
            latex_key = get_deprecated_tex_fallback(method)
            tex_executable_cmd = get_executable_cmd(latex_key)
            # TODO why this debug line? get_executable_cmd() outputs the same debug info
            log.debug("tex executable: {}".format(tex_executable_cmd[0]))
            latex_cmd = tex_executable_cmd + ["-halt-on-error", latex_image]
            log.info("converting {} to {}".format(latex_image, latex_image_pdf))
            # Run LaTeX on the image file, usual console transcript is stdout.
            # "result" is a "CompletedProcess" object.  Specifying an encoding
            # causes captured output to be a string, which is convenient.
            result = subprocess.run(latex_cmd, stdout=subprocess.PIPE, encoding="utf-8")
            if result.returncode != 0:
                # failed
                failed_images.append(latex_image)
                # and we help as much as we can
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
                    pdfsvg_executable_cmd = get_executable_cmd("pdfsvg")
                    # TODO why this debug line? get_executable_cmd() outputs the same debug info
                    log.debug("pdfsvg executable: {}".format(pdfsvg_executable_cmd[0]))
                    svg_cmd = pdfsvg_executable_cmd + [latex_image_pdf, latex_image_svg]
                    log.info(
                        "converting {} to {}".format(latex_image_pdf, latex_image_svg)
                    )
                    subprocess.call(svg_cmd)
                    if not os.path.exists(latex_image_svg):
                        log.error(
                            "There was a problem converting {} to svg and {} was not created".format(
                                latex_image_pdf, latex_image_svg
                            )
                        )
                    shutil.copy2(latex_image_svg, dest_dir)
                if outformat == "png" or outformat == "all":
                    # create high-quality png, presumes "convert" executable
                    pdfpng_executable_cmd = get_executable_cmd("pdfpng")
                    # TODO why this debug line? get_executable_cmd() outputs the same debug info
                    log.debug("pdfpng executable: {}".format(pdfpng_executable_cmd[0]))
                    png_cmd = pdfpng_executable_cmd + [
                        "-density",
                        "300",
                        latex_image_pdf,
                        "-quality",
                        "100",
                        latex_image_png,
                    ]
                    log.info(
                        "converting {} to {}".format(latex_image_pdf, latex_image_png)
                    )
                    subprocess.call(png_cmd)
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


#######################
#
#  LaTeX Tactile Images
#
#######################


def latex_tactile_image_conversion(
    xml_source, pub_file, stringparams, dest_dir, outformat
):

    # Outline:
    #   1.  Locate, isolate, convert math to Unicode braille
    #   2.  Locate, isolate labels in images, replace math
    #   3.  Translate labels to Grade 1 + Nemeth, save as XML
    #   for each image:
    #     4.  Locate, isolate in TeX file, replace label by exact space for labels' cells
    #     5.  Process with "latex" to a DVI file
    #     6.  Process DVI file with  dvisvgm  to make a structured SVG
    #     7.  Process with XSL to insert braille and other modifications

    # NB: latex (in (5)) and dvisvgm (in (6)) are hard-coded

    log.info(
        "converting latex-image from {} to {} graphics for placement in {}".format(
            xml_source, outformat, dest_dir
        )
    )
    # for killing output
    devnull = open(os.devnull, "w")
    tmp_dir = get_temporary_directory()
    log.debug("temporary directory for latex-image tactile graphics: {}".format(tmp_dir))
    ptx_xsl_dir = get_ptx_xsl_path()

    # 1. Create an XML file of Nemeth representations for entire
    # document, which will include any math in a label (overkill)
    math_file = os.path.join(tmp_dir, "math-representations.xml")
    mathjax_latex(xml_source, pub_file, math_file, tmp_dir, "nemeth")

    # 2. Extract labels themselves and replace math bits by Nemeth from (1)
    # support publisher file, but not subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    # Pass the just-created math representation file
    stringparams["mathfile"] = math_file.replace(os.sep, "/")
    log.info(
        "string parameters passed to label extraction stylesheet: {}".format(
            stringparams
        )
    )
    label_file = os.path.join(tmp_dir, "latex-image-labels.xml")
    extraction_xslt = os.path.join(
        ptx_xsl_dir, "support", "extract-latex-image-labels.xsl"
    )
    # Output is a single file, whose name includes the temporary directory
    xsltproc(extraction_xslt, xml_source, label_file, None, stringparams)

    # 3. Read all the labels that are a mix of text and Unicode for the math.
    # Convert each one into ASCII/BRF using the liblouis  lou_translate  tool.
    # Save into an XML file.
    label_tree = ET.parse(label_file)
    label_tree.xinclude()
    NSMAP = {"pi": "http://pretextbook.org/2020/pretext/internal"}
    # Grab internal label elements from label file
    labels = label_tree.xpath(
        "/pi:latex-image-labels/pi:latex-image-label", namespaces=NSMAP
    )
    # initiate XML structure to hold braille labels
    root = ET.Element(
        "{http://pretextbook.org/2020/pretext/internal}braille-labels", nsmap=NSMAP
    )
    # Unicode braille gets translated to ASCII automatically
    # Convert the remainder to Grade 1
    liblouis_cmd = ["lou_translate", "--forward", "en-us-g1.ctb"]
    for alabel in labels:
        # Following is from Python 3.5 documentation
        # input is basically piped to stdin, which is how lou_translate functions
        # Setting stdout is necessary and sufficient
        # universal_newlines is necessary to treat input and output as strings, not byte sequences
        # may need  to replace universal_newlines by text=True  in later versions
        result = subprocess.run(
            liblouis_cmd,
            input=alabel.text,
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        label_element = ET.Element(
            "{http://pretextbook.org/2020/pretext/internal}braille-label",
            id=alabel.get("id"),
        )
        label_element.text = result.stdout
        root.append(label_element)
    # output the constructed XML full of BRF labels
    braille_label_file = os.path.join(tmp_dir, "braille-labels.xml")
    with open(braille_label_file, "wb") as bf:
        bf.write(
            ET.tostring(root, pretty_print=True, encoding="utf-8", xml_declaration=True)
        )

    # 4.  Convert each  latex-image  into its own *.tex file, but with a
    # parameter to the standard stylesheet, have labels replaced by a LaTeX
    # \rule{}{} that simply creates space for TikZ to place carefully
    log.info("applying latex-image-extraction stylesheet with tactile option")
    extraction_params = stringparams
    extraction_params["format"] = "tactile"
    extraction_params["labelfile"] = braille_label_file
    # Need to copy entire external directory in the managed case.
    # Making data files available for latex image compilation is
    # not supported outside of the managed directory scheme (2021-07-28)
    # copytree() does not overwrite since tmp_dir is created anew on each use
    _, external_dir = get_managed_directories(xml_source, pub_file)
    if external_dir:
        external_dest = os.path.join(tmp_dir, "external")
        shutil.copytree(external_dir, external_dest)
    # now create all the standalone LaTeX source files
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-latex-image.xsl")
    # Output is multiple *.tex files
    xsltproc(extraction_xslt, xml_source, None, tmp_dir, extraction_params)

    # now work in temporary directory for latex runs
    os.chdir(tmp_dir)
    # files *only*, from top-level
    files = list(filter(os.path.isfile, os.listdir(tmp_dir)))
    for latex_image in files:
        filebase, extension = os.path.splitext(latex_image)
        # avoid some XML files left around
        if extension == ".tex":
            latex_image_dvi = "{}.dvi".format(filebase)
            latex_image_svg = "{}.svg".format(filebase)

            # 5. Process to DVI with old-school LaTeX
            log.info("converting {} to {}".format(latex_image, latex_image_dvi))
            latex_cmd = ["latex", "-interaction=batchmode", latex_image]
            subprocess.call(latex_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            if not os.path.exists(latex_image_dvi):
                log.error(
                    "There was a problem compiling {}, so {} was not created".format(
                        latex_image, latex_image_dvi
                    )
                )

            # 6. Process to SVG with  dvisvgm  utility
            log.info("converting {} to {}".format(latex_image_dvi, latex_image_svg))
            divsvgm_cmd = ["dvisvgm", latex_image_dvi, "--bbox=papersize"]
            subprocess.call(divsvgm_cmd, stdout=devnull, stderr=subprocess.STDOUT)
            if not os.path.exists(latex_image_svg):
                log.error(
                    "There was a problem processing {}, so {} was not created".format(
                        latex_image, latex_image_svg
                    )
                )

            # 7.  Place the label content as SVG "text" elements using SVG
            # rectangles as the guide to placement, via an XSL stylesheet
            log.info("applying latex-image-extraction stylesheet with tactile option")
            manipulation_params = stringparams
            manipulation_params["labelfile"] = braille_label_file
            svg_source = os.path.join(tmp_dir, latex_image_svg)
            svg_result = os.path.join(dest_dir, latex_image_svg)
            manipulation_xslt = os.path.join(ptx_xsl_dir, "support", "tactile-svg.xsl")
            xsltproc(
                manipulation_xslt, svg_source, svg_result, None, manipulation_params
            )


#####################
# Traces for CodeLens
#####################

# Convert program source code into traces for the interactive
# CodeLens tool in Runestone

def tracer(xml_source, pub_file, stringparams, xmlid_root, dest_dir):

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
    code_file = open(code_filename, "r")
    for program in code_file.readlines():
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
    # where the keys are the internal-ids for the problems
    # origin, copy, seed, source, pghuman, pgdense
    # also get the localization as a string
    # The XSL gets the problems in document order, and the
    # Python dictionaries (v3.5+?) will maintain the order
    # in which the problems are added, which aids in debugging
    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "extract-pg.xsl")

    # Build dictionaries and localization string into a scratch directory/file
    tmp_dir = get_temporary_directory()
    ww_filename = os.path.join(tmp_dir, "webwork-dicts.txt")
    log.debug("WeBWorK dictionaries temporarily in {}".format(ww_filename))
    xsltproc(extraction_xslt, xml_source, ww_filename, None, stringparams)
    # "run" an assignment for the list of triples of strings
    ww_file = open(ww_filename, "r")
    problem_dictionaries = ww_file.read()
    ww_file.close()
    # "run" the dictionaries and localization string
    # protect backslashes in LaTeX code
    # globals() necessary for success
    exec(problem_dictionaries.replace("\\", "\\\\"), globals())

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
            outputformat='raw'
        )
        version_determination_json = requests.get(url=ww_domain_path, params=params_for_version_determination).json()
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
            landing_page = requests.get(ww_domain_ww2)
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
            "ERROR caught by Translator while processing problem file:" in response.text
        )

        bad_xml = False
        try:
            response_root = ET.fromstring(response.text)
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
        if file_empty:
            badness_msg = "PTX:ERROR: WeBWorK problem {} was empty\n"
            badness_tip = ""
            badness_type = "empty"
            badness_base64 = "RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBGaWxlIFdhcyBFbXB0eQoKRU5EX1BHTUwKCkVORERPQ1VNRU5UKCk7"
        elif no_compile:
            badness_msg = (
                "PTX:ERROR: WeBWorK problem {} with seed {} did not compile  \n{}\n"
            )
            badness_tip = (
                "  Use -a to halt with full PG and returned content"
                if (origin[problem] == "ptx")
                else "  Use -a to halt with returned content"
            )
            badness_type = "compile"
            badness_base64 = "RE9DVU1FTlQoKTsKbG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIsIlBHTUwucGwiLCJQR2NvdXJzZS5wbCIsKTtURVhUKGJlZ2lucHJvYmxlbSgpKTtDb250ZXh0KCdOdW1lcmljJyk7CgpCRUdJTl9QR01MCldlQldvcksgUHJvYmxlbSBEaWQgTm90IENvbXBpbGUKCkVORF9QR01MCgpFTkRET0NVTUVOVCgpOw=="
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
                image_url = ww_domain + "/" + ww_image_full_path
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
                response_text = response_text.replace(
                    ww_image_full_path, os.path.join("webwork", "images", ptx_image)
                )
            else:
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

        # Start appending XML children
        response_root = ET.fromstring(response_text)
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
                answer_names = read.xpath(".//fillin/@name|.//var/@name")
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
        # Remove elements we'd rather not keep
        # p with only a single fillin, not counting those inside an li without preceding siblings
        for unwanted in static.xpath(
            "//p[not(normalize-space(text()))][count(fillin)=1 and count(*)=1][not(parent::li) or (parent::li and preceding-sibling::*)]"
        ):
            unwanted.getparent().remove(unwanted)

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
#  WeBWorK PG Macro Library
#
################################


def pg_macros(xml_source, dest_dir):

    ptx_xsl_dir = get_ptx_xsl_path()
    extraction_xslt = os.path.join(ptx_xsl_dir, "support/pretext-pg-macros.xsl")
    os.chdir(dest_dir)
    xsltproc(extraction_xslt, xml_source, None)


##############################
#
#  You Tube thumbnail scraping
#
##############################


def youtube_thumbnail(xml_source, pub_file, stringparams, xmlid_root, dest_dir):

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
    id_file = open(id_filename, "r")
    # read lines, but only lines that are comma delimited
    thumbs = [t.strip() for t in id_file.readlines() if "," in t]

    for thumb in thumbs:
        thumb_pair = thumb.split(",")
        url = "http://i.ytimg.com/vi/{}/default.jpg".format(thumb_pair[0])
        path = os.path.join(dest_dir, thumb_pair[1] + ".jpg")
        log.info("downloading {} as {}...".format(url, path))
        # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests/13137873
        # removed some settings wrapper from around the URL, otherwise verbatim
        r = requests.get(url, stream=True)
        if r.status_code == 200:
            with open(path, "wb") as f:
                r.raw.decode_content = True
                shutil.copyfileobj(r.raw, f)
        else:
            msg = "PTX:ERROR: download returned a bad status code ({}), perhaps try {} manually?"
            raise OSError(msg.format(r.status_code, url))
    log.info("YouTube thumbnail download complete")


########################
#
#  QR Code manufacturing
#
########################


def qrcode(xml_source, pub_file, stringparams, xmlid_root, dest_dir):

    # https://pypi.org/project/qrcode/
    try:
        import qrcode  # YouTube server
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("qrcode"))

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
    id_file = open(id_filename, "r")
    # read lines, but only lines that are comma delimited
    interactives = [inter.strip() for inter in id_file.readlines() if "," in inter]

    for inter in interactives:
        inter_pair = inter.split(",")
        url = inter_pair[0]
        path = os.path.join(dest_dir, inter_pair[1] + ".png")
        log.info('creating URL with content "{}" as {}...'.format(url, path))
        # Using more elaborate (class) calls to simply get a zero border,
        # rather than cropping (ala https://stackoverflow.com/questions/9870876)
        # Simple version: qr_image = qrcode.make(url), has border
        qr = qrcode.QRCode(version=None,
                           error_correction=qrcode.constants.ERROR_CORRECT_L,
                           box_size=10,
                           border=0
                           )
        qr.add_data(url)
        qr_image = qr.make_image(fill_color="black", back_color="white")
        # Now save as a PNG
        qr_image.save(path)
    log.info("QR code creation complete")


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
        import pyppeteer  # launch()
    except ImportError:
        global __module_warning
        raise ImportError(__module_warning.format("pyppeteer"))

    # Interior asynchronous routine to manage the Chromium
    # headless browser and snapshot the desired iframe
    async def snapshot(input_page, fragment, out_file):

        # input_page: the "standalone" page of the interactive
        #             hosted at the base URL
        # fragement:  the hash/fragement identifier of the iframe
        # out_file:   resulting image file in scratch directory

        # the "standalone" page has one "iframe" known by
        # the HTML id coming in here as "fragment"
        xpath = "//iframe[@id='{}'][1]".format(fragment)

        browser = await pyppeteer.launch()
        page = await browser.newPage()
        await page.goto(input_page)
        await page.waitForXPath(xpath);
        # wait again, 5 seconds, for more than just splash screens, etc
        await page.waitFor(5000)
        # list of locations, need first (and only) one
        elt = await page.xpath(xpath);
        await elt[0].screenshot({'path': out_file})
        await browser.close()
    # End of interior routine

    log.info(
        "using Pyppeteer package to create previews for interactives from {} for placement in {}".format(
            xml_source, dest_dir
        )
    )

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
    xsltproc(extraction_xslt, xml_source, id_filename, None, stringparams)

    # "run" an assignment for the list of problem numbers
    id_file = open(id_filename, "r")
    # read lines, skipping blank lines
    interactives = [f.strip() for f in id_file.readlines() if not f.isspace()]

    # Cheating a bit, base URL is *always* first item
    # Presumed to not have a trailing slash
    # Once this is a publisher option, then the xsltproc
    # call will need to accept the override as a stringparam
    baseurl = interactives[0]

    # filenames lead to placement in current working directory
    # so change to temporary directory, and copy out
    # TODO: just write to "dest_dir"?
    owd = os.getcwd()
    os.chdir(tmp_dir)

    # Start after the leading base URL sneakiness
    for preview in interactives[1:]:
        # parameters
        input_page = os.path.join(baseurl, preview + ".html")
        filename = preview + "-preview.png"
        # progress report
        msg = 'automatic screenshot of interactive with identifier "{}" on page {} to file {}'
        log.info(msg.format(preview, input_page, filename))
        # event loop and copy
        asyncio.get_event_loop().run_until_complete(snapshot(input_page, preview, filename))
        shutil.copy2(filename, dest_dir)

    # restore working directory
    os.chdir(owd)


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
        latex_image_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "pdf")
        latex_image_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "svg")

    # Asymptote
    #
    if has_asymptote:
        dest_dir = os.path.join(generated_dir, "asymptote", "")
        if not (os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        asymptote_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "pdf")
        asymptote_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "html")

    # Sage plots
    #
    if has_sageplot:
        dest_dir = os.path.join(generated_dir, "sageplot", "")
        if not (os.path.isdir(dest_dir)):
            os.mkdir(dest_dir)
        # for 3D images might produce a single PNG instead of an SVG and a PDF
        # conversions look for this PNG as a fallback absent SVG or PDF
        sage_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "pdf")
        sage_conversion(xml, pub_file, stringparams, xmlid_root, dest_dir, "svg")

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
    # "run" an assignment for the list of problem numbers
    id_file = open(id_filename, "r")
    # read lines, skipping blank lines
    problems = [p.strip() for p in id_file.readlines() if not p.isspace()]
    xml_header = '<?xml version="1.0" encoding="UTF-8" ?>\n'
    for problem in problems:
        url = "https://www.myopenmath.com/util/mbx.php?id={}".format(problem)
        path = os.path.join(dest_dir, "mom-{}.xml".format(problem))
        log.info("downloading MOM #{} to {}...".format(problem, path))
        # http://stackoverflow.com/questions/13137817/how-to-download-image-using-requests/13137873
        # removed some settings wrapper from around the URL, otherwise verbatim
        r = requests.get(url, stream=True)
        with open(path, "wb") as f:
            f.write(xml_header.encode("utf-8"))
            if r.status_code == 200:
                r.raw.decode_content = True
                shutil.copyfileobj(r.raw, f)
            else:
                msg = "PTX:ERROR: download returned a bad status code ({}), perhaps try {} manually?"
                raise OSError(msg.format(r.status_code, url))
    log.info("MyOpenMath static problem download complete")


#######################
# Conversion to Braille
#######################


def braille(xml_source, pub_file, stringparams, out_file, dest_dir, page_format):
    """Produce a complete document in BRF format ( = Braille ASCII, plus formatting control)"""

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

    # Build into a scratch directory
    tmp_dir = get_temporary_directory()
    log.debug("Braille manufacture in temporary directory: {}".format(tmp_dir))

    # use of  math_format is for consistency
    # with MathJax used to make EPUB
    math_format = "nemeth"
    math_representations = os.path.join(
        tmp_dir, "math-representations-{}.xml".format(math_format)
    )
    braille_xslt = os.path.join(get_ptx_xsl_path(), "pretext-braille.xsl")
    #  liblouis-precursor.xml  is hard-coded in  pretext-braille.xsl  stylesheet
    liblouis_xml = os.path.join(tmp_dir, "liblouis-precursor.xml")

    # ripping out LaTeX as math representations
    msg = "converting raw LaTeX from {} into clean {} format placed into {}"
    log.debug(msg.format(xml_source, math_format, math_representations))
    mathjax_latex(xml_source, pub_file, math_representations, None, math_format)

    msg = "converting source ({}) and clean representations ({}) into liblouis precursor XML file ({})"
    log.debug(msg.format(xml_source, math_representations, liblouis_xml))
    stringparams["mathfile"] = math_representations.replace(os.sep, "/")
    # pass in the page format (for messages about graphics, etc.)
    stringparams["page-format"] = page_format
    if pub_file:
        stringparams["publisher"] = pub_file
    xsltproc(braille_xslt, xml_source, None, tmp_dir, stringparams)

    # Main configuration file, two page format files
    liblouis_cfg = os.path.join(
        get_ptx_path(), "script", "braille", "pretext-liblouis.cfg"
    )
    liblouis_emboss_cfg = os.path.join(
        get_ptx_path(), "script", "braille", "pretext-liblouis-emboss.cfg"
    )
    liblouis_electronic_cfg = os.path.join(
        get_ptx_path(), "script", "braille", "pretext-liblouis-electronic.cfg"
    )
    # comma-separated configuration files, with no space
    # so as to not confuse the command construction
    if page_format == "emboss":
        cfg = liblouis_cfg + "," + liblouis_emboss_cfg
    elif page_format == "electronic":
        cfg = liblouis_cfg + "," + liblouis_electronic_cfg
    else:
        raise ValueError("PTX:BUG: braille page format not recognized")

    # Build a BRF in the *temporary* directory: final or chunkable
    temp_brf = os.path.join(tmp_dir, "temporary.brf")
    liblouis_exec_cmd = get_executable_cmd("liblouis")
    msg = "applying liblouis to {} with configurations {}, creating BRF {}"
    log.debug(msg.format(liblouis_xml, cfg, temp_brf))
    liblouis_cmd = liblouis_exec_cmd + ["-f", cfg, liblouis_xml, temp_brf]
    subprocess.run(liblouis_cmd)

    # chunk level is either '0' or '1' (exclusive "if")
    if chunk_level == '0':
        # monolithic file
        final_brf = get_output_filename(xml_source, out_file, dest_dir, ".brf")
        shutil.copyfile(temp_brf, final_brf)
        log.info("Single BRF file deposited as {}".format(final_brf))
    if chunk_level == '1':
        # chunked into chapters
        # directory switch could be moved to split routine,
        # or it could be done in temporary directory and copied out
        os.chdir(dest_dir)
        _split_brf(temp_brf)
        log.info("BRF file chunked and deposited in {}".format(dest_dir))

def _split_brf(filename):
    """Decompose a BRF file for a book into multiple files of chapters"""

    # Original author: Alexei Kolesnikov, 2022-05-28
    # Incorporation into pretext/pretext script: Rob Beezer, 2022-10-28

    # Comments from original version:
    # This is a script to split a long brf document
    # that contains many chapters into shorter brf files with a
    # single chapter each.  The script is not comprehensive:
    # it makes a number of assumptions about the brf document.
    #
    # Assumptions: Chapter titles are at the top of a page,
    # The structure of the chapter title is expected to be:
    # "      ,*apt} #ah ,9tegral ,doma9s" or
    # ",*apt} #ai ,lattices & ,bool1n ,algebras"
    #
    # That is, a number of blank spaces (possibly 0 blank spaces);
    # followed by ",*apt} ", followed by the number indicator and a number.
    # The number of the chapter is followed by a space.
    # The first chapter is Chapter 1; the numbering is consecutive after that.
    #
    # There are limited checks to let the user know when something goes wrong.

    # Assumes 1000 or fewer chapters
    # Will fail with a Chapter 0

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

    # When multiple files are produced, their filenames have
    # "chunk numbers" in them, which should usually be chapter numbers
    # format specifier: 0 = leading zero, 3 = width, d = integer
    # Assumes fewer than 1000 chapters
    # TODO: count chapters w/ lxml, log base 10, replace 3
    filename_template = "chunk{:03d}.brf"

    # A stray U+A0 appears in the Table of Contents heading,
    # and would appear to be a liblooius bug.  Once sorted,
    # perhaps the encoding should be "ascii" with a try/except
    # repreating a "UnicodeDecodeError" exception
    f = open(filename,'r', encoding="latin-1")

    # Lines from the big brf file are stored until the next chapter heading is read
    # When the new chapter heading is read, the stored lines are written in a file.

    chunk_counter = 0
    chapter_counter = 0
    out = []

    for line in f.readlines():
        if re.findall("\f[ ]{0,10}",line) and re.findall(",\*apt\}",line):
            m = re.search('#(.+?) ',line)
            num = brf_to_num(m.group(1))

            if chunk_counter == 0: # If this is the first chapter that we see
                msg = "Material before Chapter {} will be in the file {}"
                log.debug(msg.format(num, filename_template.format(chunk_counter)))
                if num != 1:
                    log.debug("The first chapter is not Chapter 1, it is Chapter {num}.".format(num))
                    chapter_counter = num - 1 # To make it work with the rest of the code
            else:
                msg = "Chapter {} will be in the file {}"
                log.debug(msg.format(chapter_counter, filename_template.format(chunk_counter)))

            # sync chapter counter with text
            if num != chapter_counter + 1:
                msg = '\n'.join([
                                  "Expected Chapter {}, but have Chapter {} instead.",
                                  "Either chapters are not consecutively numbered or something did not parse correctly"
                                  ])
                log.debug(msg(chapter_counter + 1, num))
                chapter_counter = num
            else:
                chapter_counter += 1

            # Report the BRF chapter heading that matched here
            # line seems to have a leading newline (OK)
            # and a trailing nrewline, which we strip
            log.debug("Next chapter heading:" + line[:-1])

            # a chapter has ended, write out its accumulation
            out_filename = filename_template.format(chunk_counter)
            with open(out_filename,'w') as g:
                g.writelines(out)

            # reinitialize with the current line, which is a chapter heading
            out = [line]
            chunk_counter += 1
        else:
            out.append(line)

    # And now writing the last chunk to the file:
    if chunk_counter == 0: # If there are no chapters found
        log.warning("Did not find any chapters, they may be formatted in an unexpected way.")
    else:
        msg = "Chapter {} will be in the file {}"
        log.debug(msg.format(chapter_counter, filename_template.format(chunk_counter)))

    out_filename = filename_template.format(chunk_counter)
    with open(out_filename,'w') as g:
        g.writelines(out)

    f.close()


####################
# Conversion to EPUB
####################


def epub(xml_source, pub_file, out_file, dest_dir, math_format, stringparams):
    """Produce complete document in an EPUB container"""
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
    repl = '<?xml version="1.0" encoding="UTF-8"?>\n<html xmlns="http://www.w3.org/1999/xhtml"'
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
            with fileinput.FileInput(fn, inplace=True) as file:
                for line in file:
                    print(html_elt.sub(repl, line), end="")
    os.chdir(owd)

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
    stylefile = packaging_tree.xpath("/packaging/css/@stylefile")[0]
    colorfile = packaging_tree.xpath("/packaging/css/@colorfile")[0]
    for cssfilename in [
        str(stylefile),
        str(colorfile),
        "pretext_add_on.css",
        "setcolors.css",
    ]:
        css = os.path.join(get_ptx_xsl_path(), "..", "css", cssfilename)
        shutil.copy2(css, css_dir)
    if math_format == "kindle":
        css = os.path.join(get_ptx_xsl_path(), "..", "css", "kindle.css")
        shutil.copy2(css, css_dir)
    if math_format == "svg":
        css = os.path.join(get_ptx_xsl_path(), "..", "css", "epub.css")
        shutil.copy2(css, css_dir)

    # directory of images, relative to master source file, given by publisher
    # build the same directory relative to the XHTML files

    # position cover file
    cov = packaging_tree.xpath("/packaging/cover/@pubfilename")[0]
    cover_dest = os.path.join(xhtml_dir, str(cov))
    if cov != "":
        cover_source = os.path.join(source_dir, str(cov))
        # https://stackoverflow.com/questions/2793789, Python 3.2
        os.makedirs(os.path.dirname(cover_dest), exist_ok=True)
        shutil.copy2(cover_source, cover_dest)
    else:
        cover_source = os.path.join(tmp_dir, "cover.png")
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
            pdfpng_executable_cmd = get_executable_cmd("pdfpng")
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
            os.chdir(tmp_dir)
            subprocess.run(latex_cmd)
            subprocess.run(png_cmd)
            os.chdir(owd)
        except:
            log.warning("failed to construct cover image using LaTeX and ImageMagick")
            log.info("attempting to construct cover image using pageres")
            try:
                pageres_executable_cmd = get_executable_cmd("pageres")
                pageres_cmd = pageres_executable_cmd + [
                    "-v",
                    "--filename=cover",
                    "--css=section.frontmatter{width:480px;height:768px;}h1{padding-top:192px;padding-left:32px;padding-right:32px;}.author{padding-left:32px;padding-right:32px;}",
                    "--selector=.frontmatter",
                    "EPUB/xhtml/cover-page.xhtml",
                    "1280x2048",
                ]
                os.chdir(tmp_dir)
                subprocess.run(pageres_cmd)
                os.chdir(owd)
            except:
                log.warning("failed to construct cover image using pageres")
                log.info(
                    'attempting to construct cover image using "Arial.ttf" and "Arial Bold.ttf"'
                )
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
        source = os.path.join(source_dir, str(im.get("sourcename")))
        dest = os.path.join(xhtml_dir, str(im.get("filename")))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
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

    title_file_element = packaging_tree.xpath("/packaging/filename")[0]
    title_file = ET.tostring(title_file_element, method="text").decode("ascii")
    epub_file = "{}-{}.epub".format(title_file, math_format)
    log.info("packaging an EPUB temporarily as {}".format(epub_file))
    owd = os.getcwd()
    os.chdir(tmp_dir)
    with zipfile.ZipFile(epub_file, mode="w", compression=zipfile.ZIP_DEFLATED) as epub:
        epub.write("mimetype", compress_type=zipfile.ZIP_STORED)
        for root, dirs, files in os.walk("EPUB"):
            for name in files:
                epub.write(os.path.join(root, name))
        for root, dirs, files in os.walk("META-INF"):
            for name in files:
                epub.write(os.path.join(root, name))
        for root, dirs, files in os.walk("css"):
            for name in files:
                epub.write(os.path.join(root, name))
    derivedname = get_output_filename(xml_source, out_file, dest_dir, ".epub")
    log.info("EPUB file deposited as {}".format(derivedname))
    shutil.copy2(epub_file, derivedname)
    os.chdir(owd)


####################
# Conversion to HTML
####################

# A helper function to query the latest Runestone
# Services file, while failing gracefully

def _runestone_services(params):
    """Query the very latest Runestone Services file from the RS CDN"""

    # params - string parameter dictionary, just for  debug.rs.version

    # Canonical location of file of redirections to absolute-latest
    # released version of Runestone Services when parameterized by
    # "latest", otherwise will get a specific previous version
    services_url_template = 'https://runestone.academy/cdn/runestone/{}/webpack_static_imports.xml'

    # The  debug.rs.version  string parameter is a bit of a poser.  It is
    # provided via the usual interfaces as if it were really a string parameter
    # but it gets intercepted here in the Python, and while it is provided to
    # the HTML stylesheet, there is no definition there to receive it and it
    # is silently ignored.
    # (If the HTML stylesheet doesn't like it, it could be removed after recording.)

    if "debug.rs.version" in params:
        rs_version = params["debug.rs.version"]
        services_url = services_url_template.format(rs_version)
        msg = '\n'.join(["Requested Runestone Services, version {} from the CDN via the  debug.rs.version  string parameter.",
            "This is strictly for DEBUGGING and not for PRODUCTION.  The requested version may not exist,",
            "or there could be a network error and you will get the version in the PreTrext repository.",
            "Subsequent diagnostic messages may be inaccurate.  Verify your HTML output is as intended."
            ])
        log.info(msg.format(rs_version))
    else:
        services_url = services_url_template.format("latest")

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
            services_response = requests.get(services_url)
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
        msg = '\n'.join(["unable to get the very latest Runestone Services from the Runestone CDN",
                         "this is due to an error reported immediately prior. A slightly older",
                         "version will be used based on information in the PreTeXt repository,",
                         "so this is not a fatal error, and a fallback is being used"
                         ])
        log.debug(msg)
        # and we cannot proceed, so return with a result that is empty
        return ('', '', '', '')

    # Now online_success is still True, we have not return'ed
    # and services_response should be meaningful

    # Convert Runestone file back to XML to unpack with lxml
    services_xml = services_response.text
    services = ET.fromstring(services_xml)

    # Unpack contents into format for XSL string parameters
    # This mirrors the XML file format, including multiple "item"
    #
    # colon-delimited string of the JS files
    altrs_js = ''
    for js in services.xpath("/all/js/item"):
        altrs_js = altrs_js + js.text + ':'
    altrs_js = altrs_js[:-1]
    # colon-delimited string of the CSS files
    altrs_css = ''
    for css in services.xpath("/all/css/item"):
        altrs_css = altrs_css + css.text + ':'
    altrs_css = altrs_css[:-1]
    # single CDN URL
    altrs_cdn_url = services.xpath("/all/cdn-url")[0].text
    # single Runestone Services version
    altrs_version = services.xpath("/all/version")[0].text
    return (altrs_js, altrs_css, altrs_cdn_url, altrs_version)

def html(
    xml, pub_file, stringparams, xmlid_root, file_format, extra_xsl, out_file, dest_dir
):
    """Convert XML source to HTML files, in destination directory or as zip file"""
    import distutils.dir_util  # copy_tree()

    # Consult publisher file for locations of images
    generated_abs, external_abs = get_managed_directories(xml, pub_file)

    # names for scratch directories
    tmp_dir = get_temporary_directory()

    # See if we can get the very latest Runestone Services from the Runestone
    # CDN.  A non-empty version (fourth parameter) indicates success
    #  "altrs" = alternate Runestone
    altrs_js, altrs_css, altrs_cdn_url, altrs_version = _runestone_services(stringparams)
    online_success = (altrs_version != '')
    # report repository version always, supersede if newer found
    msg = 'Runestone Services (via PreTeXt repository): version {}'
    log.info(msg.format(get_runestone_services_version()))
    if online_success:
        msg = 'Runestone Services (using newer, via online CDN query): version {}'
        log.info(msg.format(altrs_version))
    # with a successful online query, we load up some string parameters
    # the receiving stylesheet has the parameters default to empty strings
    # which translates to consulting the services file in the repository,
    # so we do nothing when the online query fails
    if online_success:
        stringparams["altrs-js"] = altrs_js
        stringparams["altrs-css"] = altrs_css
        stringparams["altrs-cdn-url"] = altrs_cdn_url
        stringparams["altrs-version"] = altrs_version

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

    # Managed, generated images
    # copytree() does not overwrite since
    # tmp_dir is created anew on each use
    if external_abs:
        external_dir = os.path.join(tmp_dir, "external")
        shutil.copytree(external_abs, external_dir)

    if generated_abs:
        generated_dir = os.path.join(tmp_dir, "generated")
        shutil.copytree(generated_abs, generated_dir)

    # Write output into temporary directory
    log.info("converting {} to HTML in {}".format(xml, tmp_dir))
    xsltproc(extraction_xslt, xml, None, tmp_dir, stringparams)
    # Only produce a file of directory locations when requested
    if (file_format == "html-with-mapping"):
        map_path_to_xml_id(xml, tmp_dir)

    if file_format in ["html", "html-with-mapping"]:
        # with multiple files, we need to copy a tree, and
        # shutil.copytree() will balk at overwriting directories
        # before Python 3.8.  The  distutils  module is old
        # (being replaced by setup).  So once on Python 3.8 these
        # copies can be replaced with shutil.copytree() using
        # the  dirs_exist_ok  keyword
        distutils.dir_util.copy_tree(tmp_dir, dest_dir)
    elif file_format == "zip":
        # working in temporary directory gets simple paths in zip file
        owd = os.getcwd()
        os.chdir(tmp_dir)
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
        os.chdir(owd)
    else:
        raise ValueError("PTX:BUG: HTML file format not recognized")


# Following is an experimental routine to support online two-panel
# editing with Bryan Jones' CodeChat tool.  Look to see where it is
# called, and chase your way backward to an undocumented switch/format
# in  pretext/pretext  that enables this

# Build a mapping between XML IDs and the resulting generated HTML files. The goal: map from source files to the resulting HTML files produced by the pretext build. The data structure is:
#
# .. code::
#   :number-lines:
#
#   path_to_xml_id: Dict[
#       # A path to the source file
#       str,
#       # A list of XML IDs in this source file which produce HTML files.
#       List[str]
#   ]
#
# This allows a single source file to produce multiple HTML files, as well as supporting a one-to-one relationship. The list captures the order of appearance of the XML IDs in the tree -- element 0 is the first XML ID, etc.
def map_path_to_xml_id(
    # A path to the root XML file in the pretext book being processed.
    xml: str,
    # A path to the destination or output directory. The resulting JSON file will be stored there.
    dest_dir: str,
) -> None:
    import collections  # defaultdict
    import glob  # glob
    import json
    import pathlib  # Path
    import urllib.parse  # urlparse

    # We assume a previous call to ``xsltproc`` has already verified that lxml is installed.
    import lxml.ElementInclude

    path_to_xml_id = collections.defaultdict(list)

    xml = str(pathlib.Path(xml).resolve()) # normalize path separators to current OS

    # This follows the `Python recommendations <https://docs.python.org/3/library/sys.html#sys.platform>`_.
    is_win = sys.platform == "win32"

    # Look at all HTML files in the output directory. Store only their stem, since this is what an XML ID specifies. Note that all output files will have the same path prefix (the ``dest_dir`` and the same suffix (``.html``); the stem is the only unique part.
    html_files = set(
        pathlib.Path(html_file).stem for html_file in glob.glob(dest_dir + "/*.html")
    )

    # lxml turns ``xml:id`` into the string below.
    xml_ns = "{http://www.w3.org/XML/1998/namespace}"
    xml_base_attrib = f"{xml_ns}base"
    xml_id_attrib = f"{xml_ns}id"

    # Define a loader which sets the ``xml:base`` of an xincluded element. While lxml `evidently used to do this in 2013 <https://stackoverflow.com/a/18158472/16038919>`_, a change eliminated this ability per some `dicussion <https://mail.gnome.org/archives/xml/2014-April/msg00015.html>`_, which included a rejected patch fixing this problem. `Current source <https://github.com/GNOME/libxml2/blob/master/xinclude.c#L1689>`_ lacks this patch.
    def my_loader(href, parse, encoding=None, parser=None):
        ret = lxml.ElementInclude._lxml_default_loader(href, parse, encoding, parser)
        # The return value may not be an element.
        if isinstance(ret, ET._Element):
            ret.attrib[xml_base_attrib] = href
        return ret

    # Load the XML, performing xincludes using this loader.
    huge_parser = ET.XMLParser(huge_tree=True)
    src_tree = ET.parse(xml, parser=huge_parser)
    lxml.ElementInclude.include(src_tree, loader=my_loader)

    # Walk though every element with an xml ID.
    for elem in src_tree.iterfind(f"//*[@{xml_id_attrib}]"):
        # Consider only elemets whose ID produced an HTML file. TODO: use a walrus operator after Python 3.7 is EOL.
        xml_id = elem.get(xml_id_attrib)
        if xml_id in html_files:
            # Store this discovered mapping between ID and output file.
            #
            # The `elem.base <https://lxml.de/api/lxml.etree._Element-class.html#base>`_ gives the URL of this file (which is correct due to the custom loader). Extract the path.
            up = urllib.parse.urlparse(elem.base)
            # If this isn't a ``file`` scheme (or an unspecified schema, which seems to default to a file), we're lost.
            assert up.scheme in ("file", "")
            path = up.path
            # On Windows, this produces ``path == "/C:/path/to/file.ptx"``. Remove the slash.
            if is_win:
                path = path[1:]
            # Use ``resolve()`` to standardize capitalization on Windows.
            path = str(pathlib.Path(path).resolve())
            # Add this XML ID to others for this path.
            path_to_xml_id[path].append(xml_id)

    # Save the result as a JSON file in the ``dest_dir``.
    (pathlib.Path(dest_dir) / "mapping.json").write_text(json.dumps(path_to_xml_id))


##################
# Assembled Source
##################

# AKA the aftermath of the pre-processor
# Parameterized by static v. dynamic exercises


def assembly(xml, pub_file, stringparams, out_file, dest_dir, method):
    """Convert XML source to pre-processed PreTeXt in destination directory"""

    # support publisher file, not subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    # method dictates which type of exercises are produced
    # parameter is exclusive to utility styleheet below
    stringparams["debug.assembly.exercise"] = method
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


def latex(xml, pub_file, stringparams, extra_xsl, out_file, dest_dir):
    """Convert XML source to LaTeX in destination directory"""

    # support publisher file, not subtree argument
    if pub_file:
        stringparams["publisher"] = pub_file
    # Optional extra XSL could be None, or sanitized full filename
    if extra_xsl:
        extraction_xslt = extra_xsl
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

    # "dirs_exist_ok" keyword is Python 3.8; necessary?

    # Create localized filenames for pdflatex conversion step
    # sourcename  needs to match behavior of latex() with above arguments
    basename = os.path.splitext(os.path.split(xml)[1])[0]
    sourcename = basename + ".tex"
    pdfname = basename + ".pdf"

    # Copy directories as indicated in publisher file
    # A "None" value will indicate there was no information
    # (an empty string is impossible due to a slash always being present?)

    # Managed, generated images
    # copytree() does not overwrite since
    # tmp_dir is created anew on each use
    if generated_abs:
        generated_dir = os.path.join(tmp_dir, "generated")
        shutil.copytree(generated_abs, generated_dir)
    # externally manufactured images
    if external_abs:
        external_dir = os.path.join(tmp_dir, "external")
        shutil.copytree(external_abs, external_dir)

    # now work in temporary directory since LaTeX is a bit incapable
    # of working outside of the current working directory
    os.chdir(tmp_dir)
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
def xsltproc(xsl, xml, result, output_dir=None, stringparams={}, outputfn=log.info):
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
    outputfn     - a function for routing output of error messages. Any
                   such function should process its parameters like print

    N.B. The value of a "publisher" string parameter passed in the
    "stringparams" argument must be a complete path, since a relative
    path can be rendered incorrect by the change to an "output_dir"
    different than that at the time of the command-line invocation.
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
        outputfn("comprehensive messages, warnings, and errors:")
        parse_t = threading.Thread(target=transform)
        parse_t.start()
        still_alive = True
        start = 0
        while still_alive:
            parse_t.join(0.5)  # Wait 0.5 seconds for thread to complete
            still_alive = parse_t.is_alive()

            end = len(xslt.error_log)
            # print out any unprinted messages from error_log
            for line in range(start, end):
                outputfn(f"    * {xslt.error_log[line].message}")
            start = end
        if texc is None:
            outputfn("successful application of {}".format(xsl))
        else:
            raise (texc)
    except Exception as e:
        outputfn("processing with {} has failed\n".format(xsl))
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
    owd = os.getcwd()
    os.chdir(d)
    with zipfile.ZipFile(zip_filename, mode="w", compression=zipfile.ZIP_DEFLATED) as zip_file:
        # set() will avoid duplicate files included twice (or more)
        for f in set(all_files):
            zip_file.write(f)
    os.chdir(owd)

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
            "PreTeXt script/module expects Python 3.6, not Python 2 or older\n",
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


def get_runestone_services_version():
    """Examine Runestone Services file for version number"""

    services_file = os.path.join(get_ptx_path(), "xsl", "support", "runestone-services.xml")
    services = ET.parse(services_file)
    version_element = services.xpath("/all/version")[0]
    return version_element.text


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
        requests.get(url)
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

    temp_dir = tempfile.mkdtemp()
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
#  __ptx_path - root directory of installed PreTeXt distribution
#              necessary to locate stylesheets and other support
#
#  __config - parsed values from an INI-style configuration file
#
#  __temps - created temporary directories, to report or release
#
#  __module_warning - stock import-failure warning message


# Discover and set distribution path once at start-up
__ptx_path = None
set_ptx_path()

# Configuration as a dictionary
__executables = None

#  cache of temporary directories
__temps = []
