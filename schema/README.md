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
