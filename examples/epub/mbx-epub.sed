# sed script for MathBook XML EPUB experiments
# Fix-up mathjax-node creations
#
# History
#
#  2016-05-10  Initiated

# Non-breaking spaces (Unicode: A0) are converted to "&nbsp;" along the way
# Careful, the single whitespace below is character "&xa0;" in XML notation
s/&nbsp;/ /g

# Close image tags, br tags, link tags
s/<img \([^>]*\)>/<img \1\/>/g
s/<br>/<br \/>/g
s/<link \([^>]*\)>/<link \1\/>/g

# SVG Per-file, remove from  .MathJax_SVG  style
s/direction: ltr;//g

# SVG, per-image, add SVG namespace
# No longer necessary after the move from page2svg to mjpage
# s/<svg /<svg xmlns="http:\/\/www.w3.org\/2000\/svg" /g

# But mjpage doesn't put the necessary namespace on the glyphs tag. Grrrr.
# Fortunately, that svg looks like <svg style, so it's easy for sed to find
s/<svg style/<svg xmlns="http:\/\/www.w3.org\/2000\/svg" style/g

# SVG, per-image, removals
s/role="img"//g
s/focusable="false"//g

# MML, per-file, macro-container left-behind, remove entirely
/<div style="display:none;"><math xmlns="http:\/\/www.w3.org\/1998\/Math\/MathML"><\/math><\/div>/d

# MML, per-math, validator wants  @alttext  attribute
s/<math /<math alttext="" /g

