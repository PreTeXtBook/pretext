# Braille Conversion

### `pretext-braille.sh`
A bash script to automate the steps involved in converting PreTeXt source to a Braille `*.brf` file.  May require editing of paths to be useful.  Heavily annotated, so learn more by reading comments in this file, and see list of prerequisites

### `mjpage-sre.js`
A Javascript program which does the conversion of MathML to Braille (as Unicode characters for 6-cell dot patterns) with the Speech Rule Engine.

### `pretext-liblouis.cfg`, `pretext.sem`
Configuration files for the file2brl program of the liblouis package.