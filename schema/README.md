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
* `pretext-dev.rnc`, `pretext-dev.rng`: the development schema, an overlay
  of the production schema holding experimental constructs.  The overlay
  must stay *purely additive*: a bare `include` of the production schema
  (never with a replacement body), wholly new named patterns, and additions
  to production patterns only via `|=` (`combine="choice"`).  This makes
  the development language a strict superset of the production language,
  by construction, which is what lets validation report development-schema
  messages as genuine errors and production-only messages as experimental
  constructs.  Validation checks the invariant on every run.
* `experimental-features.xml`: advisory prose that validation attaches to
  experimental constructs it reports.  Purely decorative: what gets
  flagged is decided by comparing the two grammars, so a stale entry
  never misleads.  When a construct is promoted to the production schema,
  its entry simply stops firing (and can be deleted at leisure).

## Build Script

* `build.sh`: build script for above. Copy and edit local paths,
  or consult as documentation
