<!--********************************************************************
Copyright (C) 2020-2026  Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*****************************************************************-->

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

Requires Python 3.10, as of 2026-07-06.

Execute  pretext -h  to see the various command-line options.

Example: TikZ code for graphics images can be extracted and written
into "standalone" files with XSL, and then this script will continue
on to apply LaTeX to the files, creating a PDF, then optionally
convert these PDFS into other formats, e.g. creating  SVG images
via the  pyMuPDF library.

`pretext.cfg`
-------------

An INI-style configuration file, mostly for specifying the location,
or choice, of executables necessary for the `pretext` script to
perform various tasks.  Look inside the file for instructions on
making, placing, and employing a customized version.

**NEVER EDIT THE ORIGINAL VERSION OF** `pretext.cfg`

`runestone`
-----------

Selected modules from RunestoneComponents to support the formulation of trace data for
Python programs to CodeLens interactive programs written in Python.
