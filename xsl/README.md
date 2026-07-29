<!--********************************************************************
Copyright (C) 2019-2026  Robert A. Beezer

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

eXtensible Stylesheet Language (XSL) Stylesheets
================================================

XSL stylesheets are the primary vehicle for converting PreTeXt XML
source into various output formats.  As such, they are sometimes
simply called "conversions."  Here we list **some** of the available
conversions, the list is not exhaustive.  See _The PreTeXt Guide_
for detailed documentation of use, in chapters of the part
titled _Publisher's Guide_.

* `pretext-latex.xsl` - conversion to LaTeX, which can then
be converted to PDF, in print or electronic flavors.
* `pretext-html.xsl` - conversion to HTML for online use.
* `pretext-epub.xsl` - conversion to EPUB, which
requires significant additional processing.  So this stylesheet
is not meant to be applied in isolation.  See the `pretext/pretext`
Python script for an option to initiate the processing pipeline.
* `pretext-jupyter.xsl` - conversion to Jupyter notebooks.
* `pretext-revealjs.xsl` - conversion of slideshows to HTML.
* `pretext-beamer.xsl` - conversion of slideshows to PDF.
* `pretext-braille.xsl` - conversion to a precursor for braille output, which
requires significant further processing.  So this stylesheet
is not meant to be applied in isolation.  See the `pretext/pretext`
Python script for an option to initiate the processing pipeline.
* `pretext-common.xsl` - base templates, and not useful in isolation.
* `pretext-assembly.xsl` - pre-processing stylesheet, which creates an
enhanced version of source.  Applied in a controlled way by other stylesheets.
See the `utilities\pretext-enhanced-source.xsl` stylesheet for a demonstration.
* `extract-*.xsl` - used to isolate particular parts of a PreTeXt
document, typically for subsequent processing by a script.

(Updated: 2020-06-12)
