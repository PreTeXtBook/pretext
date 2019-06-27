PreTeXt Script Directory
========================

`mbx`
-----

A Python "helper" script to do things XSL will not do, or cannot do easily.

Execute  mbx -h  to see the various command-line options.

Example: A Sage Notebook worksheet (`*.sws`) is a zip file of a few related files.  XSL can extract the necessary information, the mbx script automates the process of creating the zip file.

Example: TikZ code for graphics images can be extracted and written into "standalone" files with XSL, this script will apply LaTeX to the files, creating a PDF, then optionally convert them via  pdf2svg  into SVG images.

`\braille`
----------

Files for converting PreTeXt to Braille, see README there.


