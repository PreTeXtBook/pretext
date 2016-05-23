# sed script for MathBook XML EPUB experiments
# Fixes for SVG images, to not confuse validator
#
# History
#
#  2016-05-10  Initiated

# MatPlotLib, asymptote, etc  creations

# Remove DTD reference that validator wants to follow
# Delete, possibly two lines
/DOCTYPE svg PUBLIC/d
/"http:\/\/www.w3.org\/Graphics\/SVG\/1.1\/DTD\/svg11.dtd"/d
