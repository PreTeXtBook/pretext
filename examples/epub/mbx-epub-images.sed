# sed script for MathBook XML EPUB experiments
# Fixes for SVG images, to not confuse validator
#
# History
#
#  2016-05-10  Initiated

# MatPlotLib code, 2017-12-28
# https://github.com/matplotlib/matplotlib/blob/master/lib/matplotlib/backends/backend_svg.py
# "svgProlog" string variable contains
#   (1) xml processing declaration,
#   (2) problematic DTD lines,
#   (3) XML matplotlib origin comment
# so not easy to remove optionally in program source.
# Perhaps we should do this sanitization in the  mbx  script generation phase (not here)

# Remove DTD reference that validator wants to follow
# Delete, recognizing that it may appear split across two lines

/DOCTYPE svg PUBLIC/d
/"http:\/\/www.w3.org\/Graphics\/SVG\/1.1\/DTD\/svg11.dtd"/d
