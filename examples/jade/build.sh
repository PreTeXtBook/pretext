#!/usr/bin/env bash
# for jade, install node.js and then run npm install (will read packages.json)
./node_modules/.bin/jade --pretty --extension xml jade.jade
xsltproc ../../xsl/mathbook-html.xsl jade.xml

