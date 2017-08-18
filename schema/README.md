PreTeXt RELAX-NG Schema
=======================

A RELAX-NG schema as the formal specification of the PreTeXt vocabulary.  Read the Author's Guide for complete documentation.

* `pretext.xml`: original version as a PreTeXt literate program.  Submit pull requests against this version only, all the others are derived copies.
* `pretext.rnc`: direct product from `pretext.xml`, RELAX-NG compact syntax
* `pretext.rng`: conversion from `pretext.xml` via `trang`, RELAX-NG XML syntax
* `pretext.xsd`: conversion from `pretext.rng` via `trang`, W3C XSD syntax, with resultant minor inaccuracies
* `build.sh`: build script for above. Copy and edit local paths, or use as documentation