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

# The PreTeXt Guide

- Follow [README.md](README.md) for build commands and for the `tag`, `tage`, and `attr` markup used when writing about syntax.
- Follow the [developer documentation contract](developer/coding.xml). Mention a new element briefly in Overview, describe it fully in Topics, and cross-link both locations. Put elaborate examples in the Showcase Article, `examples/showcase`, not in the Guide.
- Give a new publisher option a terse entry in `publisher/publication-file.xml`, ordered lexicographically by its XPath expression. Add the fuller explanation to the relevant Publisher chapter and cross-link the two locations.
- Apply the [Basics Reference rules](basics/README.md) when editing that part, including its identifier, cross-reference, snippet, and index conventions.
- Put a setting in `docinfo` when it changes the document's content or meaning. Put it in the publication file when it changes presentation or selects whole authored units; defaults follow the authored attribute they govern.
- Treat `generated/` as build output.
- Some Guide files have additional copyright holders. Preserve their notices exactly as recorded in [the copyright registry](../../legal/copyright-holders.md).
