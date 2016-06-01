#!/usr/bin/env bash
# for pug, install node.js and then run npm install (will read packages.json)
./node_modules/.bin/pug --pretty --extension xml pug.pug
xsltproc ../../xsl/mathbook-html.xsl pug.xml

