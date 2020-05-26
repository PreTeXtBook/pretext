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
* `pretext-epub.xsl` - conversion to EPUB, needs a supporting script.
* `pretext-jupyter.xsl` - conversion to Jupyter notebooks.
* `pretext-revealjs.xsl` - conversion of slideshows to HTML.
* `pretext-beamer.xsl` - conversion of slideshows to PDF.
* `pretext-braille.xsl` - conversion to precursor of Braille output,
requires significant further processing.
* `pretext-common.xsl` - base templates, and not useful in isolation.
* `extract-*.xsl` - used to isolate particular parts of a PreTeXt
document, typically for subsequent processing by a script.



