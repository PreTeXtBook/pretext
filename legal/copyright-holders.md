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
*********************************************************************-->

Copyright Holders
=================

Most files in this repository are copyright Robert A. Beezer alone, and are
covered by the GNU General Public License (see `COPYING`, and the license texts
in this directory).  This file records every exception.

Keep it current.  When a file listed here is removed from the repository, drop
its row.  When permission is obtained to change a notice, add an entry under
Permissions below and set that row's status to `permitted`, with the date.

Status values:

* `as-is` — leave the notice alone, including its years.
* `permitted` — permission obtained; see Permissions, with the date.

## Beezer with co-holders

The date range in these notices is maintained along with the rest of the
repository.  The list of holders is not changed.

| Holders | Files | Location | Status |
|---|---|---|---|
| Beezer, David Farmer, Alex Jordan, Mitchel T. Keller | 6 | `doc/guide/` — `COPYING`, `guide.xml`, `guideinfo.xml`, front and back matter | as-is |
| Beezer, Michael Gage, Geoff Goehle, Alex Jordan | 7 | WeBWorK support — `xsl/extract-pg.xsl`, `xsl/pretext-ww-problem-sets.xsl`, `examples/webwork/` | as-is |
| Beezer, David Farmer, Alex Jordan | 5 | `doc/guide/developer/` | as-is |
| Oscar Levin, Andrew Rechnitzer, Steven Clontz, Beezer | 1 | `xsl/pretext-beamer.xsl` | as-is |
| Andrew Rechnitzer, Steven Clontz, Beezer | 1 | `xsl/pretext-revealjs.xsl` | as-is |
| Beezer, Alex Jordan | 1 | `xsl/pretext-merge.xsl` | as-is |

## Other holders

These notices are not altered at all, years included.

| Holder | Files | Location | Status |
|---|---|---|---|
| Thomas W. Judson | 17 | `examples/sample-book/` — the *Abstract Algebra: Theory and Applications* content | as-is |
| Glyph & Cog, LLC | 8 | `examples/showcase/generated/latex-image/` — produced files | as-is |
| The PreTeXt Organization | 7 | `examples/showcase/source/` | as-is |
| Free Software Foundation | 5 | `legal/gpl-license-v2.txt`, `legal/gpl-license-v3.txt`, `doc/guide/COPYING`, `doc/guide/appendices/gfdl-pretext.xml`, `examples/sample-book/gfdl-mathbook.xml` | as-is — verbatim license texts, whose own terms forbid modification |
| O'Reilly Media, Inc. | 3 | `xsl/entities.ent`, `xsl/pretext-epub.xsl`, `xsl/pretext-text-utilities.xsl` | as-is — the headers quote O'Reilly's own permission for code examples |
| Aalto University | 2 | `js/pretext-stack/stackjsvle.js` and its copy under `js/dist/` | as-is — carries no license statement and has no nearby README |
| Andrew Rechnitzer | 1 | `xsl/latex/pretext-latex-CLP.xsl` | as-is |
| Oscar Levin | 1 | `xsl/latex/pretext-latex-texstyle.xsl` | as-is |
| Jason Siefken | 1 | `xsl/xml-to-json.xsl` | as-is |
| Evan Lenz | 1 | `xsl/xml-to-string.xsl` | as-is |
| The MathJax Consortium | 1 | `script/mjsre/mj-sre-page.js` | as-is |
| Mitchel T. Keller | 1 | `doc/guide/appendices/gfdl-pretext.xml` | as-is |
| three.js authors | 1 | `examples/sample-article/media/code/threejs/splines.js` | as-is — the full MIT license text is inline |
| STIX Fonts Project Authors, Adobe Systems, Elsevier, MicroPress | 1 | `fonts/LICENSE-STIX.txt` — one upstream license naming all four | as-is |
| The Inconsolata Project Authors | 1 | `fonts/LICENSE-Inconsolata.txt` | as-is |
| American Mathematical Society, The LaTeX Project, Radical Eye Software | 1 | `examples/showcase/generated/asymptote/AreaUnderCurve.eps` — a produced file | as-is |

## Files carrying no notice

| Files | Location | Note |
|---|---|---|
| 6 | `contrib/hitchman/`, `contrib/ups-writers/` | Contributed stylesheets, no notice at all.  Each directory has a README but no license.  Needs a decision. |
| 1 | `xsl/support/play-button/README.md` | Left deliberately: it states that its content does not meet the threshold of originality for copyright protection. |

## Permissions

When a holder grants permission to change a notice, record it here and set that
row's status above to `permitted`, referring to the date.

Say precisely what was granted.  Permission to relicense is not the same as
permission to restate a notice, and neither is the same as an upstream project
changing its own license; naming the scope per entry keeps a narrow permission
from being read broadly later.

For evidence, record where it lives rather than reproducing it.  Pasting
correspondence into a public repository publishes a third party's address and
words, so prefer a mailing list archive link, a message identifier, or an issue
or pull request number.  Public artifacts, such as an upstream license change,
can be linked directly.

| Date | Holder | Files | What was granted | Evidence |
|---|---|---|---|---|
| | | | | |

## Maintaining the notices

The notice for Beezer-held files reads

    Copyright (C) <first year>-2026  Robert A. Beezer

on one line, or with the holders on the line following, for files with several.
An annual update advances the end year in both shapes.  Two rules:

1. **Never move a start year later.**  Many files carry a notice that predates
   the file's own history in the repository, because the file was split out of a
   larger one or moved into a subdirectory.  A start year taken from the
   repository would shorten those claims.  Use the earlier of the two.
2. **Leave verbatim license texts alone.**  They carry copyright lines that look
   like ordinary notices, but each one reproduces somebody else's license, and
   their own terms forbid modification: `legal/gpl-license-v2.txt`,
   `legal/gpl-license-v3.txt`, `doc/guide/appendices/gfdl-pretext.xml`,
   `examples/sample-book/gfdl-mathbook.xml`, and the `fonts/LICENSE-*.txt`
   files.  `doc/guide/COPYING` needs care rather than exclusion: the guide's own
   notice at the top is maintained, while the GNU Free Documentation License
   appended below it is not.

Note also that a few files carry two distinct notices: those under
`examples/sample-book/sage/` have a PreTeXt file header and a separate notice
for the book content, with an earlier start year.  Both are maintained
independently.

## Rebuilding this list

    git grep -nIE "[Cc]opyright[^A-Za-z]*(\(c\)|\(C\)|\(©\))? *[0-9]{4}" \
      | grep -viE "showCopyright|\.copyright|localization|string-id=|ref name=|threshold of originality"

For each result, the holder is the text following the year range — or, when that
is empty, the *next* line.  A search that reads only the matching line will miss
holders, and a search for a name alone will pick up prose: `Elsevier` appears as
a journal publisher in `journals/journals.xml`, and `STIX` as a font name in
`pretext/fop.xconf`.
