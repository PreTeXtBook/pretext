<!--********************************************************************
Copyright (C) 2025-2026  Robert A. Beezer

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

# Journals supported by PreTeXt

This folder contains a single `journals.xml` file which holds all relevant data about the journals currently supported by PreTeXt.

This file is the one source of truth for data about these journals.  It is used in the following ways:

- By running the `build.sh` file, the `journals.xml` file will be transformed into a pretext table (via the `journals-to-table.xsl` file) that is placed in the correct location for when the pretext guide is built.
- The pretext script parses `journals.xml` to find the correct latex-style to apply based on the journal code provided in the authors publication file.

## Texstyle features for journals with their own conventions

Any texstyle file may use these, which serve journals such as those of the Mathematical Association of America.

- `<ptx-preamble main-font="journal">`: the journal's class or package sets the text font (as `mathmag.sty` sets Times), so under pdflatex PreTeXt keeps the T1 font encoding but does not load Latin Modern.
- `<appendices>`: the first appendix is preceded by `\appendix`, or by the command named in `@cmd` (without its backslash); inside an environment (`@env`) nothing more is written.  Each appendix is a `\section`.  `@title-prefix` (for example `"Appendix: "`) goes before each appendix title, for journals whose sections are unnumbered.
- `<biographies>`: authors' biographies, from `author/biography`, for journals that set them at the end of an article.  The children are applied once for each author who has a biography, as in an `<author-list>`, with `<ptx-personname/>` and `<ptx-biography/>` available.  `@env` or `@heading` wraps the list, and nothing is written if no author has a biography.
- `<text>` may be a child of `<texstyle>` itself, for raw LaTeX between other elements, as in the Monthly's submission title page.
- The `theorem` counter, which theorem-like environments share, resets at the division where the publisher's numbering of blocks resets.
