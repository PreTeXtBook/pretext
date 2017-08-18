MathBook XML Author's Guide
===========================

PDF and HTML versions of this guide are available at the [MathBook XML](http://mathbook.pugetsound.edu) site in the Documentation area.

If you wish to build from source, possibly as part of contributing improvements, follow these steps:

1.  Copy all three files in the `mathbook/doc/author-guide/xsl` directory to the `mathbook/user` directory (creating this directory if necessary).
1.  To build LaTeX for input to `pdflatex`:
        cd /path/to/mathbook
        xsltproc --xinclude user/author-guide-latex.xsl doc/author-guide/author-guide.xml
1.  And for HTML output:
        cd /path/to/mathbook
        xsltproc --xinclude user/author-guide-html.xsl doc/author-guide/author-guide.xml
1.  You might prefer to set your default directory to someplace outside the MathBook XML distribution and include full paths to the XSL and XML files in the `xsltproc` command, so the output is not mixed in with the source.
