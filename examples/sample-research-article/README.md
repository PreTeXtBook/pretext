<!--********************************************************************
Copyright (C) 2026  Robert A. Beezer

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

# Sample Research Article

A short article with the parts a research article is likely to have: authors with affiliations, an abstract, keywords, sections and subsections, theorems with proofs, numbered equations, a figure, a table, footnotes, an appendix, and a list of references.  The content is a subset of the sample article, `examples/sample-article`, without its interactive material.  It exists to test the journal styles (texstyles) in `journals/`.

## Publication files

Every publication file asks for the same numbering: divisions at level 2, and blocks and equations at level 1.

| File | Journal |
| --- | --- |
| `publication.xml` | none |
| `publication-ams.xml` | `ams`, AMS journals in general |
| `publication-electron-j-combin.xml` | `electron-j-combin`, The Electronic Journal of Combinatorics |
| `publication-elsevier.xml` | `elsevier` |
| `publication-proc-amer-math-soc.xml` | `proc-amer-math-soc`, whose style extends the AMS style |
| `publication-springer-nature.xml` | `springer-nature` |
| `publication-taylor-francis.xml` | `taylor-francis` |

## A journal with its own numbering

The package of The Electronic Journal of Combinatorics defines the theorem-like environments on one counter that runs through an article, and its texstyle file records that in a `numbering` element (see `journals/README.md`).  So with `publication-electron-j-combin.xml`:

- blocks are numbered `Theorem 1`, `Definition 2`, through `Corollary 9`, where `publication.xml` gives `Theorem 2.1`, `Definition 2.2`, through `Corollary A.1`;
- the figure and the table are `Figure 1` and `Table 2`, on a counter of their own;
- equations and divisions are numbered as the publication file asks, since the journal's package leaves them alone;
- every conversion gives these numbers, so the HTML agrees with the PDF;
- a build warns that the level for blocks in the publication file is not used.

## Building

From the root of the repository, for LaTeX and for HTML:

    python3 pretext/pretext -c doc -f latex -p examples/sample-research-article/publication-electron-j-combin.xml -d /tmp/sample-research-article examples/sample-research-article/sample-research-article.xml
    python3 pretext/pretext -c doc -f html -p examples/sample-research-article/publication-electron-j-combin.xml -d /tmp/sample-research-article-html examples/sample-research-article/sample-research-article.xml

A PDF needs the journal's class or package, which a PDF build downloads.  Each journal names a bibliography style, and the references are formatted in it once they have been generated; otherwise a build says so and formats them in the default way.
