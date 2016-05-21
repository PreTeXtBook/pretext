#!/usr/bin/env bash
# for jade, install node.js and then run npm install
./node_modules/.bin/jade --extension xml jade.jade
xsltproc ../../xsl/mathbook-html.xsl jade.xml

