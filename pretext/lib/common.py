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
# 2026-06-03: created by splitting the shared low-level helpers out of "pretext.py"

# This module imports nothing from its siblings; the import graph is
# one-way:  common  <-  {webwork, stack, pretext}

import logging

# ------------------------------------------------------------------- #
# PreTeXt message severity                                            #
#                                                                     #
# Every message travels through the shared "ptxlogger" at one of      #
# these levels.  A level is a *severity* -- what happened and who     #
# should act.  "fatal" is unique in being a severity *and* an action: #
# it stops the build.                                                 #
#                                                                     #
#   log.debug     10  fine-grained trace, for pinpointing             #
#                     ("xsltproc command: ...")                       #
#   log.info      20  coarse progress                                 #
#                     ("converting source to HTML")                   #
#   log.fallback  25  bad or absent input, but a sensible default     #
#                     was substituted; output is complete             #
#                     ('no @width, assuming "100%"')                  #
#   log.warning   30  should be addressed                             #
#                     ("a deprecated element was used")               #
#   log.error     40  no good default; localized breakage, output     #
#                     is degraded but processing continues            #
#                     ("cross-reference target does not exist")       #
#   log.bug       45  an internal PreTeXt defect, NOT the author's    #
#                     fault; please report.  A severity only:         #
#                     execution continues (the renderer degrades)     #
#                     ("an 'otherwise' meant to be unreachable")      #
#   log.fatal     50  processing halts, no output expected.  A        #
#                     severity AND an action: it logs, then raises    #
#                     PreTeXtFatal ("invalid source, or a severe bug") #
#                                                                     #
# A defect that cannot be worked around is the rare composition of    #
# the two: log.bug(...) to record it, then log.fatal(...) to stop.    #
#                                                                     #
# KEEP IN SYNC: this table is mirrored, with fuller prose, in the     #
# "Messaging" chapter of the Developer Guide.  Changing a level here  #
# means changing it there, and vice versa.                            #
# ------------------------------------------------------------------- #

# The full severity ladder in one place.  The standard five are Python's
# own; "fallback" and "bug" are PreTeXt additions that interleave with them.
DEBUG_LEVEL    = logging.DEBUG      # 10
INFO_LEVEL     = logging.INFO       # 20
FALLBACK_LEVEL = 25
WARNING_LEVEL  = logging.WARNING    # 30
ERROR_LEVEL    = logging.ERROR      # 40
BUG_LEVEL      = 45
FATAL_LEVEL    = logging.CRITICAL   # 50
logging.addLevelName(FALLBACK_LEVEL, 'FALLBACK')
logging.addLevelName(BUG_LEVEL, 'BUG')
# We prefer "fatal" to Python's "critical" for level 50; a downstream
# consumer (such as the CLI) is free to rebrand it.
logging.addLevelName(FATAL_LEVEL, 'FATAL')


class PreTeXtFatal(Exception):
    '''The build cannot continue and no output is expected.  A fatal-severity
    message (log.fatal) raises this; the program driving PreTeXt catches it
    and reports the halt.  It is internal: an author never sees it directly.'''
    pass


log = logging.getLogger('ptxlogger')


# Convenience methods for the two new levels, plus a "fatal" that is a
# severity *and* an action.  Attached to the shared logger instance, so
# every module that fetches "ptxlogger" gains them.
def _log_fallback(message, *args, **kwargs):
    if log.isEnabledFor(FALLBACK_LEVEL):
        log._log(FALLBACK_LEVEL, message, args, **kwargs)

def _log_bug(message, *args, **kwargs):
    if log.isEnabledFor(BUG_LEVEL):
        log._log(BUG_LEVEL, message, args, **kwargs)

def _log_fatal(message, *args, **kwargs):
    log._log(FATAL_LEVEL, message, args, **kwargs)
    raise PreTeXtFatal(message)

log.fallback = _log_fallback
log.bug = _log_bug
log.fatal = _log_fatal


# The level at which to re-log a stylesheet message, by its "PTX:TOKEN".
# The bridge only *records* a message here; a FATAL one is logged like any
# other and does not halt (the transform's own terminating exception carries
# the halt), so every token, fatal included, routes the same way.
_XSL_MESSAGE_LEVELS = {
    'FATAL':     FATAL_LEVEL,
    'BUG':       BUG_LEVEL,
    'ERROR':     ERROR_LEVEL,
    'FALLBACK':  FALLBACK_LEVEL,
    'WARNING':   WARNING_LEVEL,
    'DEPRECATE': WARNING_LEVEL,
    'INFO':      INFO_LEVEL,
    'DEBUG':     DEBUG_LEVEL,
}

import re
import traceback
import os
import os.path
import shutil
import contextlib

# Uniform warning when an optional module fails to load.  This is the
# canonical definition; sibling modules reuse it via common.__module_warning.
__module_warning = "\n".join(
    [
        'PTX ERROR: the "{}" module has failed to load, and',
        "  this is necessary for the task you have requested.  Perhaps",
        "  you have not installed it?  Or perhaps you have forgotten to",
        "  use a Python virtual environment you set up for this purpose?",
    ]
)

try:
    import lxml.etree as ET
except ImportError:
    raise ImportError(__module_warning.format("lxml"))


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
                message = "* {}".format(line.message)
                token = re.match(r'\s*PTX:([\w-]+)', line.message)
                if token:
                    level = _XSL_MESSAGE_LEVELS.get(token.group(1).upper())
                    if level is not None:
                        log.log(level, message)
                    else:
                        # a well-formed but unknown token (e.g. a "PTX:FO-TODO"
                        # work marker); keep it quiet rather than mis-leveling
                        log.debug(message)
                elif re.match(r'\s*(?i:ptx|warning|error|fatal|bug|deprecate)\b', line.message):
                    # looks like it meant to carry a severity token but is
                    # malformed (a stylesheet-authoring slip); flag it
                    log.bug("a PreTeXt stylesheet message has a malformed severity token: {}".format(line.message))
                else:
                    # genuinely tokenless (e.g. a continuation line)
                    log.info(message)
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
        import lxml.ElementInclude
        def my_loader(href, parse, encoding=None, parser=None):
            try:
                ret = lxml.ElementInclude._lxml_default_loader(href, parse, encoding, parser)
            except Exception as e:
                log.error(f"Error loading {href}: {e}")
                raise
            return ret

        # Reparse the tree (was modified in try clause) and run ElementInclude
        # This should also fail, but will give a better error message
        # NB this might report false positives (duplicate xml:id even if controlled by versions)
        src_tree = ET.parse(xml, parser=huge_parser)
        lxml.ElementInclude.include(src_tree, loader=my_loader, max_depth=100)
        return src_tree # should never actually reach


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


def release_temporary_directories(any_log_level):
    """
    Release scratch directories unless requesting debugging info
    - any_log_level: can be set to True by an external tool to force cleanup even if log level is set to debug (log.level == 10)
    """

    global __temps

    # log.level is 10 for debug, greater for all other levels.
    if log.level > 10 or any_log_level:
        try:
            for td in __temps:
                log.info("Removing temporary directory {}".format(td))
                # let a removal failure raise, so it is caught and reported below
                shutil.rmtree(td, ignore_errors=False)
                log.debug("Removed temporary directory {}".format(td))
        except Exception as e:
            log.warning("Failed to remove temporary directories, starting with {} (and maybe some others): {}".format(td, str(e)))
        finally:
            # always empty the list, even if a removal raised partway, so a
            # long-running caller (e.g. a server process) does not accumulate
            # stale entries; this also avoids duplicate removal requests
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
    # file computations change.  Used to ascertain a Runestone build. (2024-09-25)

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
        data_dir = os.path.join(build_dir, "data")
        shutil.copytree(data_abs, data_dir)


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


# Discover and set distribution path once at start-up
__ptx_path = None
set_ptx_path()

# Configuration as a dictionary
__executables = None

#  cache of temporary directories
__temps = []

