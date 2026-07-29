<!--********************************************************************
Copyright (C) 2015-2026  Robert A. Beezer

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
