# The PreTeXt Guide

PDF and HTML versions of this guide are available at the [PreTeXt](https://pretextbook.org) site in the Documentation area.

If you wish to build from source, possibly as part of contributing improvements, follow these steps:

1.  To build LaTeX for input to `pdflatex`:
    cd /path/to/guide
    pretext build latex -d -w
1.  And for HTML output:
    cd /path/to/guide
    pretext build html -d -w
1.  The preceeding two steps will attempt to build all of the webwork representations and diagrams needed for your book. You may be missing some of the prerequisites, such as Sage that will need to be installed before a full build can be completed.

If you are contributing new material, note that there are three important elements in use. Please make use of them in your contribution.

-   `tag` - for element names
-   `tage` - for names of empty elements
-   `attr` - for names of attributes
