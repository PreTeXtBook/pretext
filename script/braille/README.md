# Braille Conversion

This directory contains support files for a conversion to braille.  The actual conversion pipeline is initiated by an option in the `pretext/pretext` Python script (and not by a stylesheet alone).

### `mjpage-sre.js`
A Javascript program which does the conversion of MathML to Braille (as Unicode characters for 6-cell dot patterns) with the Speech Rule Engine.

### `pretext-liblouis.cfg`, `pretext.sem`
Configuration files for the file2brl program of the liblouis package.