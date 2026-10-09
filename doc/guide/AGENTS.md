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

- Follow [README.md](README.md) for the `tag`, `tage`, and `attr` markup used when writing about syntax. Build the Guide with the command in the root [Verification section](../../AGENTS.md), with `doc/guide/guide.xml` as the source file and `doc/guide/publication.xml` as the publication file.
- Describe the language as it is now; an account of how a feature once behaved does not belong in the Guide. Source follows the conventions in the root [PreTeXt source section](../../AGENTS.md).
- Follow the [developer documentation contract](developer/coding.xml). Mention a new element briefly in Overview, describe it fully in Topics, and cross-link both locations. Put elaborate examples in the Showcase Article, `examples/showcase`, not in the Guide.
- Give a new publisher option a terse entry in `publisher/publication-file.xml`, ordered lexicographically by its XPath expression. Add the fuller explanation to the relevant Publisher chapter and cross-link the two locations.
- Apply the [Basics Reference rules](basics/README.md) when editing that part, including its identifier, cross-reference, snippet, and index conventions.
- `generated/` holds tracked assets, as the examples do: regenerate them with `pretext/pretext` components and commit them with the change that needs them; do not edit them by hand.
- Some Guide files have additional copyright holders. Preserve their notices exactly as recorded in [the copyright registry](../../legal/copyright-holders.md).
