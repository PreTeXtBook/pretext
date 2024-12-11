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
- how Runestone's chapter/subchapter model maps onto a
PreTeXt `book` with `chapter` and `section`
- as an example for Runestone, many Runestone features
are tested in a new chapter devoted to these features.

The `sample-book.xml` file is the main (and only) source file.
It incorporates two `book` under version control.  So there
are publication files to control which version is created.
In other words, `sample-book-no-parts.xml` and
`sample-book-with-parts.xml` are not meant to be main files.

### With Parts

`sample-book.xml` can be used with two different publication
files to get either "decorative" or "structural" parts.

### No Parts

`sample-book.xml` can be used with a publication file so that
no parts employed.  This would be the vcase for books hosted
on a Runestone server.

### Solution Manual

There is a separate main file and publication file to get
a LaTeX/PDF solution manual.