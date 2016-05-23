# MathBook XML Sample Book

**2015-02-17**: this is a work in-progress, so may not always reflect best practice.

This sample book began as a subset of Tom Judson's "Abstract Algebra: Theory and Applications" textbook.  Superfluous material has been added to demonstrate and test various aspects of a book-length project.  So this should not be taken as representative of the real version of Judson's book.

It is meant to illustrate
- how to structure the "extra" parts of a book, such as the preface, appendices, index, and so on.
- how to modularize a large project across multiple files

To build and test, use a scratch directory like `/tmp/sb`:

1. PREP:  `/tmp/sb$ cp -av /path/to/mathbook/examples/sample-book/* .`
2. HTML:  `/tmp/sb$ xsltproc --xinclude /path/to/mathbook/xsl/mathbook-html.xsl sample-book.xml`
3. LaTeX: `/tmp/sb$ xsltproc --xinclude /path/to/mathbook/xsl/mathbook-latex.xsl sample-book.xml`

Look for `sample-book.tex` and `sample-book.html` for futher processing or viewing.  Note that these filenames come from the xml:id on the book element, not from the filename of the master XML file.

Notes:

1.  This sample has "Parts" where the chapter numbering resets with each new part.  There are plans for the default to have chapter numbering continue consecutively across parts.
2.  2015-02-17: The front matter is in good shape, but the back matter needs work and most errors when validating against the DTD can be traced to the backmatter.
