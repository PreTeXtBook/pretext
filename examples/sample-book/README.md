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

The Sample Book comes in several flavors:

* Wihout any parts, use `sample-book.xml` as the source
with the "no-parts" publication file.
* With parts, use `sample-book-parts.xml` as the source
with the "decorative" or "structural" publication files.
* As a solution manual, use `sample-book-solutions-manual.xsl`
as the source, with the "solution-manual" publication file.

Other than changes in organization, the only difference in content
comes in the front matter, where the Preface has cross-references
to items in parts, or no such cross-references.