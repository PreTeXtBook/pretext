PreTeXt Publisher's Guide
=========================

PDF and HTML versions of this guide are available at the [PreTeXt](https://pretextbook.org) site in the Documentation area.

If you wish to build from source, possibly as part of contributing improvements, follow these steps:

1.  To build LaTeX for input to `pdflatex`:
        cd /path/to/mathbook
        xsltproc --xinclude xsl/mathbook-latex.xsl doc/publisher-guide/publisher-guide.xml
1.  And for HTML output:
        cd /path/to/mathbook
        xsltproc --xinclude xsl/mathbook-html.xsl doc/publisher-guide/publisher-guide.xml
1.  You might prefer to set your default directory to someplace outside the MathBook XML distribution and include full paths to the XSL and XML files in the `xsltproc` command, so your output is not mixed in with your source.

If you are contributing new material, note that there are three important elements in use.  Please make use of them in your contribution.
* `tag` - for element names
* `tage` - for names of empty elements
* `attribute` - for names of attributes
