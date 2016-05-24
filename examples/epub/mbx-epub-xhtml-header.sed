# sed script for MathBook XML EPUB experiments
# Just fix up header of content documents
#
# History
#
#  2016-05-10  Initiated

# MathBook XML  creations

# Fixup namespace on *.xhtml content documents
s/<html>/<html xmlns="http:\/\/www.w3.org\/1999\/xhtml">/g
