#!/bin/bash
#
# MathBook XML EPUB example, build script
#
# History
#
#  2016-05-10  Initiated

shopt -s -o nounset

# MathBook XML paths
declare MB=${HOME}/mathbook/mathbook
declare MBXSL=${MB}/xsl
declare EPUBSCRIPT=${MB}/examples/epub

# mathjax-node paths
# requires installation
declare MJNODE=/opt/node_modules/mathjax-node

# Working areas
# DEBUG saves post-xsltproc, pre-mathjax-node
declare SCRATCH=/tmp/scratch
declare EPUBOUT=${SCRATCH}/epub
declare DEBUG=${SCRATCH}/debug

# Sources
# Assumes cover image is a PNG

# EPUB Sampler, test file
declare SRC=${MB}/examples/epub
declare SRCMASTER=${SRC}/epub-sampler.xml
declare COVERIMAGE=${SRC}/Verne_Tour_du_Monde.png
declare OUTFILE=sampler.epub

# Judson's AATA, an entire book
#declare SRC=${HOME}/books/aata/aata/src
#declare SRCMASTER=${SRC}/aata.xml
#declare COVERIMAGE=${SRC}/images/cover_aata_2014.png
#declare OUTFILE=aata.epub

# removal of detritus

# create directory structure
install -d ${EPUBOUT} ${EPUBOUT}/EPUB/xhtml ${EPUBOUT}/EPUB/xhtml/images
# debugging directory
install -d ${DEBUG}

# copy/place image files, fix up SVGs
cp -a ${COVERIMAGE} ${EPUBOUT}/EPUB/xhtml/images/cover.png
cp -a ${SRC}/images ${EPUBOUT}/EPUB/xhtml
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


# need working directory right for mathjax-node
# copy to temp, replace math, fixup with sed
# TODO: place content files someplace for processing, deletion
cd ${MJNODE}
declare GLOBIGNORE="${EPUBOUT}/EPUB/xhtml/cover.xhtml:${EPUBOUT}/EPUB/xhtml/title-page.xhtml:${EPUBOUT}/EPUB/xhtml/table-contents.xhtml"
for f in ${EPUBOUT}/EPUB/xhtml/*.xhtml; do
    echo "Working on" $f
    mv $f $f.temp;
    ${MJNODE}/bin/page2svg < $f.temp > $f;
    # ${MJNODE}/bin/page2mml < $f.temp > $f;
    # rm $f.temp;
    mv $f.temp ${DEBUG};
    sed -i -f ${EPUBSCRIPT}/mbx-epub.sed $f;
done
unset GLOBIGNORE
#
# Back to usual default directory
# zip with  mimetype  first
cd ${EPUBOUT}
zip -0Xq  ${OUTFILE} mimetype
zip -Xr9Dq ${OUTFILE} *

# exit cleanly
exit 0