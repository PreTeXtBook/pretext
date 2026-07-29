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

