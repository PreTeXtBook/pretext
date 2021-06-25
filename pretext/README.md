PreTeXt `pretext` Python Package
================================

`pretext.py`
------------

A Python module to automate various aspects of manipulating
PreTeXt source via XSL stylesheets and using external programs
on some of the results.

`module-test.py`
----------------

A minimal example of using the `pretext` module to build
a Python application.

`pretext`
---------

A Python "helper" script to do things XSL will not do, or cannot do easily.

Requires Python 3.6, as of 2021-05-21.

Execute  pretext -h  to see the various command-line options.

Example: TikZ code for graphics images can be extracted and written
into "standalone" files with XSL, and then this script will continue
on to apply LaTeX to the files, creating a PDF, then optionally
convert these PDFS into other formats, e.g. creating  SVG images
via the  pdf2svg  utility.

`pretext.cfg`
-------------

An INI-style configuration file, mostly for specifying the location,
or choice, of executables necessary for the `pretext` script to
perform various tasks.  Look inside the file for instructions on
making, placing, and employing a customized version.

**NEVER EDIT THE ORIGINAL VERSION OF** `pretext.cfg`