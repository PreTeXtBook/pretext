#!/bin/bash
#
# MathBook XML EPUB example, build script
#
# History
#
#  2016-05-10  Initiated
#  2016-05-19  Published, improved

shopt -s -o nounset

# MathBook XML paths
declare MB=${HOME}/mathbook/mathbook
declare MBXSL=${MB}/xsl
declare EPUBSCRIPT=${MB}/examples/epub

# mathjax-node-page paths
# requires installation, see
# https://github.com/pkra/mathjax-node-page
declare MJNODE=/opt/node_modules/mathjax-node-page

# Working areas
# DEBUG saves post-xsltproc, pre-mathjax-node
# and also post-mathjax-node, pre-sed
declare SCRATCH=/tmp/scratch
declare EPUBOUT=${SCRATCH}/epub
declare DEBUG=${SCRATCH}/debug

# Sources
# 1.  Assumes an "images" directory below source directory
# 2.  Cover image must be a PNG, and in "images" directory

# EPUB Sampler, test file
declare SRC=${MB}/examples/epub
declare SRCMASTER=${SRC}/epub-sampler.xml
declare COVERIMAGE=Verne_Tour_du_Monde.png
declare OUTFILE=sampler.epub

# The MBX sample book
# declare SRC=${MB}/examples/sample-book
# declare SRCMASTER=${SRC}/sample-book.xml
# declare COVERIMAGE=cover_aata_2014.png
# declare OUTFILE=sample-book.epub

# Judson's AATA, an entire book
# declare SRC=${HOME}/books/aata/aata/src
# declare SRCMASTER=${SRC}/aata.xml
# declare COVERIMAGE=cover_aata_2014.png
# declare OUTFILE=aata.epub

# Keller/Trotter, Applied Combinatorics, an entire book
# declare SRC=${HOME}/books/app-comb/applied-combinatorics/mbx
# declare SRCMASTER=${SRC}/index.mbx
# declare COVERIMAGE=../front-cover.png
# declare OUTFILE=applied-combinatorics.epub

# removal of detritus (clear $SCRATCH by hand before execution)

# create directory structure
install -d ${EPUBOUT} ${EPUBOUT}/EPUB/xhtml ${EPUBOUT}/EPUB/xhtml/images
install -d ${EPUBOUT}/EPUB/css
# debugging directory
install -d ${DEBUG}

# copy/place image files
# move cover image to stock name (fix this in XSL transform)
# fix up SVGs
cp -a ${SRC}/images ${EPUBOUT}/EPUB/xhtml
mv ${EPUBOUT}/EPUB/xhtml/images/${COVERIMAGE} ${EPUBOUT}/EPUB/xhtml/images/cover.png
for f in ${EPUBOUT}/EPUB/xhtml/images/*.svg; do 
    sed -i -f ${EPUBSCRIPT}/mbx-epub-images.sed $f
done

# make files via xsltproc, into existing directory structure
cd ${EPUBOUT}
xsltproc --xinclude  ${MBXSL}/mathbook-epub.xsl ${SRCMASTER}

# fixup file header to make obviously XHTML
declare GLOBIGNORE="${EPUBOUT}/EPUB/xhtml/cover.xhtml:${EPUBOUT}/EPUB/xhtml/title-page.xhtml:${EPUBOUT}/EPUB/xhtml/table-contents.xhtml"
for f in ${EPUBOUT}/EPUB/xhtml/*.xhtml; do
    sed -i -f ${EPUBSCRIPT}/mbx-epub-xhtml-header.sed $f
done
unset GLOBIGNORE

# Add CSS file. Temporarily stored alongside the ePub script
cp -a ${EPUBSCRIPT}/pretext-epub.css ${EPUBOUT}/EPUB/css

# need working directory right for mathjax-node-page
# copy to temp, replace math, fixup with sed
# TODO: place content files someplace for processing, deletion
cd ${MJNODE}
declare GLOBIGNORE="${EPUBOUT}/EPUB/xhtml/cover.xhtml:${EPUBOUT}/EPUB/xhtml/title-page.xhtml:${EPUBOUT}/EPUB/xhtml/table-contents.xhtml"
for f in ${EPUBOUT}/EPUB/xhtml/*.xhtml; do
    echo "Working on" $f
    mv $f $f.temp;
    ${MJNODE}/bin/mjpage < $f.temp > $f;
    # ${MJNODE}/bin/page2mml < $f.temp > $f;
    # rm $f.temp;
    mv $f.temp ${DEBUG};
    cp -a $f ${DEBUG};
    sed -i -f ${EPUBSCRIPT}/mbx-epub.sed $f;
done
unset GLOBIGNORE

# Remove any PDFs from the images directory, since
# those images are meant for PDF output and are never
# embedded into the XHTML files that we create
#
# TODO: We really should only include the images we put
# in the manifest
rm ${EPUBOUT}/EPUB/xhtml/images/*.pdf

# Back to usual default directory
# zip with  mimetype  first
cd ${EPUBOUT}
zip -0Xq  ${OUTFILE} mimetype
zip -Xr9Dq ${OUTFILE} *

# exit cleanly
exit 0
