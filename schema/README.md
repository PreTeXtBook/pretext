<!--********************************************************************
Copyright (C) 2017-2026  Robert A. Beezer

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

# PreTeXt RELAX-NG Schema

A RELAX-NG schema is the formal specification of the PreTeXt vocabulary.  Read the Author's Guide for complete documentation.

## RELAX-NG Grammar

* `pretext.xml`: original version of the RELAX-NG schema, using
   compact notation, as a PreTeXt literate program.  Submit pull requests
   against this version only, all the others are derived copies.
* `pretext.rnc`: direct product from `pretext.xml`, RELAX-NG compact syntax
* `pretext.rng`: conversion from `pretext.xml` via `trang`, RELAX-NG XML syntax

## Build Script

* `build.sh`: build script for above. Copy and edit local paths,
  or consult as documentation
