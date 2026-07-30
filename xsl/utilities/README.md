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

# Utilities

## Source-to-Source conversions

For utility programs here which rewrite your source, be **sure** to use version control (collect and review changes on a branch, stash and drop undesirable outcomes), or have backups handy.  The effects are not reversible.  Stylesheets will output to standard output, so you can redirect their output, or you can use something like the `-o` flag on the `xsltproc` command-line invocation.  Experiment first.

### `fix-deprecations.xsl`
This will convert any obsolete element names or constructions to their replacements.  As deprecations are added, you may run it anew, and only the new changes will be applied.  Despite the name, it does make some minor changes.  Empty tags will get a single space prior to the closing backslash.

Be sure to read all the details in the Author's Guide before using this on your source.  Here is an absolute minimal example.
```
$ xsltproc /path/to/xsl/utilities/fix-deprecations.xsl -stringparam fix all /path/to/examples/sample-errors-and-warnings.xml > new-sample.xml

$ diff /path/to/examples/sample-errors-and-warnings.xml new-sample.xml
```
(Updated: 2017-07-04)


## Author Report

`author-report.xsl` is a very simple stylesheet which will produce a text version of items in your source that could benefit from your attention.  This is different than validating your PreTeXt source against the schema, but is part of using automated tools to ensure healthy source material.

(Updated: 2018-12-09)

## Intermediate Enhanced Source

`pretext-enhanced-source.xsl` is mainly meant for development use.  It outputs an XML file, which is not necessarily valid PreTeXt, at a key stage of the processing.  It gives you a look under the hood (or bonnet).  So generally not useful (or necessary) for authors.

(Updated: 2020-02-25)
