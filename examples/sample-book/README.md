# PreTeXt Sample Book

This sample book began as a subset of Tom Judson's
_Abstract Algebra: Theory and Applications_ textbook.
Superfluous material has been added to demonstrate and
test various aspects of a book-length project.  So
this should not be taken as representative of the
real version of Judson's book.

It is meant to illustrate
- how to structure the "extra" components of a book,
such as the preface, appendices, index, and so on.
- how to modularize a large project across multiple files

### With Parts

`sample-book.xml` can be used with two different publication files to get
either "decorative" or "structural" parts.

### No Parts

`sample-book-noparts.xml` has, as the name implies, no parts employed.
There is a third publication file for this case.  Also, some
cross-references whose targets are parts, have been removed from the
front matter, necessitating a different `frontmatter-noparts.xml`.

### Usage Notes

To build and test, use a scratch directory like `/tmp/sb`:

1. PREP:  `/tmp/sb$ cp -av /path/to/pretext/examples/sample-book/* .`
2. HTML:  `/tmp/sb$ xsltproc -xinclude /path/to/pretext/xsl/pretext-html.xsl sample-book.xml`
3. LaTeX: `/tmp/sb$ xsltproc -o sample-book.tex -xinclude /path/to/pretext/xsl/pretext-latex.xsl sample-book.xml`

Look for `sample-book.tex` and `sample-book.html` for futher
processing or viewing.  Note that the HTML filename came
from the xml:id on the book element, not from the filename
of the master XML file.  There is also an automatic
`index.html` file in the HTML output.

Notes:

1.  This sample has "Parts" where the chapter numbering
resets with each new part.  There are plans for the default
to have chapter numbering continue consecutively across parts.
2.  `codechat_config.yaml` is a CodeChat project configuration file, which assumes processing by Python, with all necessary utilities are in place as part of system software.  We prefer to use a Python virtual ernvironment (via `venv`).  To accomodate that, make teh following changes, where `/path/to` should not be used literally, but instead should be customized for your system.

  Change line 37, which is:
```
args: python3 ../../pretext/pretext --component all --format html --directory {output_path} sample-book.xml
```
to (for Linux/OS X):
```
args: C:/path/to/venv/bin/python ../../pretext/pretext --component all --format html --directory {output_path} sample-book.xml
```
or (for Windows):
```
args: /path/to/venv/Scripts/python ../../pretext/pretext --component all --format html --directory {output_path} sample-book.xml
```
For Windows, replace the drive letter (`C:` in the example above) as necessary. Note that forward slashes (`/`) work on Windows in this context.
