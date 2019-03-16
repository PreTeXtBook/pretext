#!/bin/bash
#
# Conversion Script
# PreTeXt to Braille (UEB Grade 2 + Nemeth)
#
# History
#
#  2019-01-31  Initiated
#  2019-01-04  Reworked: build HTML files, not text files
#  2019-02-14  Integrate mathjax-node-sre

# Usage:
# PreTeX::  $1
# Output:   ${SCRATCH}/final.brf

# Script Prerequisites
#   install -d to make directories
#   PreTeXt distribution, xsl/braille/pretext-braille.xsl
#   node (on path)
#   mathjax-node-page (via npm, provides mjpage)
#       needs: mathjax-node
#   sed (temporary?)
#   mathjax-node-sre (via npm, supports JS script)
#       needs: speech-rules-engine
#   liblouis (we use the Ubuntu package)


# Paths
declare SCRATCH=/tmp/brf
declare HOME=/home/rob
declare PTX=${HOME}/mathbook/mathbook
declare PTXXSL=${PTX}/xsl
declare SCRIPT=${PTX}/script/braille
declare NODE=${HOME}/node_modules

# Setup
install -d ${SCRATCH}

# XSL to convert PreTeXt original source to a mildly
# custom HTML.  Mostly this strips styling and
# interactive bits, but also manages transitions
# between "literary" and "math" text.  Math is
# preserved as LaTeX in forms mathJax expects
echo "Applying XSLT conversion, creating purpose-built HTML"
xsltproc -xinclude ${PTXXSL}/pretext-braille.xsl ${1} > ${SCRATCH}/html-latex.html

# MathJax  mjpage  script will interpret all (delimited)
# LaTeX content on the page and replace it with MathML,
# wrapped in a new MathJax span followed by the 
# outermost "math" element of the replacement MathML
echo "Apply mjpage conversion, to convert LaTeX to MathML"
${NODE}/mathjax-node-page/bin/mjpage --speech false --format TeX --output MML < ${SCRATCH}/html-latex.html > ${SCRATCH}/html-mml.html

# MathJax is making HTML, and JSDOM below does not like 
# the entity &nbsp; (we should be able to obsolete this step) 
sed -i -e "s/\&nbsp;/\&#xa;/g" ${SCRATCH}/html-mml.html

# This custom Javascript is provided by Peter Krautzberger, 
# of the MathJax project, and is edited for our purposes.  
# It functions much like the  mjpage  script, finding all 
# of the MathML, and then applying Volker Sorge's 
# "Speech Rule Engine" via the routines in the  mathjax-node-sre  
# package.  Each MathML piece is replaced by an SVG (which we 
# promptly totally ignore), but the "title" element of the SVG 
# is given in Nemeth Braille using Unicode characters for 
# the 6-dot Braille cells
echo "Apply mjpage-sre conversion, to convert MathML to Braille"
node ${SCRIPT}/mjpage-sre.js ${SCRATCH}/html-mml.html ${SCRATCH}/html-braille.html

# liblouis  can be configured via a configuration file
# (for lines, pages, etc) as well as with a "semantic" 
# file that specifies rules for how to interpret HTML
# elements semantically
# TODO: get  basename  of $1 and use that
echo "Apply liblouis conversion to produce BRF file"
file2brl -f ${SCRIPT}/pretext-liblouis.cfg ${SCRATCH}/html-braille.html ${SCRATCH}/final.brf