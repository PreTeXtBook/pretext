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
# RAB: 2019-05-01 in ~/node_modules; to update
#      ~$ npm install mathjax-node-page
declare MJNODE=/home/rob/node_modules/mathjax-node-page

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

# sed -i is different depending on if you have BSD sed (macOS)
# or GNU sed (Linux and Windows Subystem for Linux)
# To deal with this, we see which is in use and define a function called
# sed_i that we invoke rather than plain sed.
# https://unix.stackexchange.com/questions/92895/how-can-i-achieve-portability-with-sed-i-in-place-editing
case $(sed --help 2>&1) in
  *GNU*) sed_i () { sed -i "$@"; };;
  *) sed_i () { sed -i '' "$@"; };;
esac

# create directory structure
install -d ${EPUBOUT} ${EPUBOUT}/EPUB/xhtml ${EPUBOUT}/EPUB/xhtml/images
install -d ${EPUBOUT}/EPUB/css
# debugging directory
install -d ${DEBUG}

# make files via xsltproc, into existing directory structure
cd ${EPUBOUT}
xsltproc --xinclude  ${MBXSL}/mathbook-epub.xsl ${SRCMASTER}

# copy/place image files
# create the image directory
install -d ${EPUBOUT}/EPUB/xhtml/images
# read in the image-list.txt file and copy over
# only the images actually used in the EPUB
INPUT="${EPUBOUT}/xhtml/image-list.txt"
while IFS= read -r LINE
do
    IMGFILE=${LINE//[$'\t\r\n']}
    cp -a ${SRC}/${IMGFILE} ${EPUBOUT}/EPUB/xhtml/${IMGFILE}
done < "$INPUT"
# make sure the image list doesn't get bundled in the EPUB
rm ${EPUBOUT}/xhtml/image-list.txt #${EPUBOUT}

# move cover image to stock name (fix this in XSL transform)
cp -a ${SRC}/images/${COVERIMAGE} ${EPUBOUT}/EPUB/xhtml/images/cover.png

# fixup file header to make obviously XHTML
declare GLOBIGNORE="${EPUBOUT}/EPUB/xhtml/cover-page.xhtml:${EPUBOUT}/EPUB/xhtml/title-page.xhtml:${EPUBOUT}/EPUB/xhtml/table-contents.xhtml"
for f in ${EPUBOUT}/EPUB/xhtml/*.xhtml; do
    sed_i -f ${EPUBSCRIPT}/mbx-epub-xhtml-header.sed $f
done
unset GLOBIGNORE

# Add CSS file. Temporarily stored alongside the ePub script
cp -a ${EPUBSCRIPT}/pretext-epub.css ${EPUBOUT}/EPUB/css

# need working directory right for mathjax-node-page
# copy to temp, replace math, fixup with sed
# TODO: place content files someplace for processing, deletion
cd ${MJNODE}
declare GLOBIGNORE="${EPUBOUT}/EPUB/xhtml/cover-page.xhtml:${EPUBOUT}/EPUB/xhtml/title-page.xhtml:${EPUBOUT}/EPUB/xhtml/table-contents.xhtml"
for f in ${EPUBOUT}/EPUB/xhtml/*.xhtml; do
    echo "Working on" $f
    mv $f $f.temp;
    ${MJNODE}/bin/mjpage < $f.temp > $f;
    # ${MJNODE}/bin/page2mml < $f.temp > $f;
    # rm $f.temp;
    mv $f.temp ${DEBUG};
    cp -a $f ${DEBUG};
    sed_i -f ${EPUBSCRIPT}/mbx-epub.sed $f;
done
unset GLOBIGNORE

# Back to usual default directory
# zip with  mimetype  first
cd ${EPUBOUT}
zip -0Xq  ${OUTFILE} mimetype
zip -Xr9Dq ${OUTFILE} *

# exit cleanly
exit 0
