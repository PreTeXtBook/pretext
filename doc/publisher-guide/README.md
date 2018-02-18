PreTeXt Publisher's Guide
=========================

PDF and HTML versions of this guide are available at the [MathBook XML](http://mathbook.pugetsound.edu) site in the Documentation area.

If you wish to build from source, possibly as part of contributing improvements, follow these steps:

1.  Copy all three files in the `mathbook/doc/publisher-guide/xsl` directory to the `mathbook/user` directory (creating this directory if necessary).
1.  To build LaTeX for input to `pdflatex`:
        cd /path/to/mathbook
        xsltproc --xinclude user/publisher-guide-latex.xsl doc/publisher-guide/publisher-guide.xml
1.  And for HTML output:
        cd /path/to/mathbook
        xsltproc --xinclude user/publisher-guide-html.xsl doc/publisher-guide/publisher-guide.xml
1.  You might prefer to set your default directory to someplace outside the MathBook XML distribution and include full paths to the XSL and XML files in the `xsltproc` command, so the output is not mixed in with the source.

If you are contributing new material, note that there are three non-standard elements in use:
* `tag` - for element names
* `tage` - for names of empty elements
* `attribute` - for names of attributes
Please make use of them in your contribution.  Use should be obvious to deduce by looking at examples in existing source.  The instructions above are meant to insure that templates for these tags are available and used.
