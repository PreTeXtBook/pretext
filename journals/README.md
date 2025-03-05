# Journals supported by PreTeXt

This folder contains a single `journals.xml` file which holds all relevant data about the journals currently supported by PreTeXt.

This file is the one source of truth for data about these journals.  It is used in the following ways:

- By running the `build.sh` file, the `journals.xml` file will be transformed into a pretext table (via the `journals-to-table.xsl` file) that is placed in the correct location for when the pretext guide is built.
- The pretext script parses `journals.xml` to find the correct latex-style to apply based on the journal code provided in the authors publication file.

