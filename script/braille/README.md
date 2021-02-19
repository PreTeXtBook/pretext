# Braille Conversion

This directory contains support files for a conversion to braille.  The actual conversion pipeline is initiated by an option in the `pretext/pretext` Python script (and not by a stylesheet alone).

### Configuration Files

`pretext-liblouis.cfg`, `pretext.sem`, `pretext-symbol.dis`

Configuration files for the file2brl program of the liblouis package.

`pretext-liblouis-electronic`, `pretext-liblouis-emboss`

One, and only one, of these two files is necessary, and must be paired with `pretext-liblouis.cfg` on the command-line (via a comma).  They control much of the layout -- "electronic" is for one-line displays and similar, while "emboss" is for files meant to be physically embossed onto braille paper.