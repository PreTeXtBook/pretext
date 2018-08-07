# PreTeXt RELAX-NG Schema

A RELAX-NG schema is the formal specification of the PreTeXt vocabulary, with additional Schematron rules.  Read the Author's Guide for complete documentation.

## RELAX-NG Grammar

* `pretext.xml`: original version of the RELAX-NG schema, using
   compact notation, as a PreTeXt literate program.  Submit pull requests
   against this version only, all the others are derived copies.
* `pretext.rnc`: direct product from `pretext.xml`, RELAX-NG compact syntax
* `pretext.rng`: conversion from `pretext.xml` via `trang`, RELAX-NG XML syntax
* `pretext.xsd`: conversion from `pretext.rng` via `trang`, to W3C XSD syntax,
   with resultant minor inaccuracies

## Schematron Rules

* `pretext.sch`: original version of Schematron rules
* `iso_schematron_cli.xsl`: extension using Schematron API.
  For developer use and requires a copy of the Schematron distribution.
* `pretext-schematron.xsl`: stylesheet for author use.  Invoke with
  an xslt processor (e.g. `xsltproc`) on your PreTeXt source to get 
  messages from the Schematron rules.

## Build Script

* `build.sh`: build script for above. Copy and edit local paths,
  or consult as documentation
