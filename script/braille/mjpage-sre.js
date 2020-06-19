#! /usr/bin/env node

// Original gist from Peter Krautzberger
// https://gist.github.com/pkra/7ccdd351838f0bbdfe0080a4eacda7ca
// Rob Beezer: 2019-02-14

// Alexei S. Kolesnikov: 2019-06-27
// Modified render(node) method to produce cleaner output
// and remove extraneous spaces.

// Rob Beezer: 2019-07-24
// Minor updates to accomodate SRE 3.0.0-beta.5

// Rob Beezer: 2020-06-08
// Add she-bang, so script is executable
// Parameterize with argv[2]:  'nemeth', 'speech'
// Place result in outerHTML, to match mathjax-node-page

const fs = require('fs');
const mjnode = require('mathjax-node-sre');
const jsdom = require('jsdom');
const { JSDOM } = jsdom;
process.on('unhandledRejection', r => console.log(r));

mjnode.config({
  MathJax: {
    // default config is okay
  }
});
const mj = mjnode.typeset;

const render = async (node, format) => {
  let mathinput = node.outerHTML;
  let params
  if (format == 'nemeth') {
    params = ['domain', 'default', 'locale', 'nemeth', 'modality', 'braille']
  } else {
    params = ['domain', 'clearspeak', 'locale', 'en', 'modality', 'speech'];
  }
  const result = await mj({
    math: mathinput, // This is the MathML expression that will be converted
    format: "MathML",
    mml:true, // I think it does not matter which we pick, mml or svg; we are not using it anyway
    sre: params,
    });

  // result.speech contains Nemeth Braille code for mathinput
  // *replace* the MathML "math" element
  node.outerHTML = result.speech;
};

const main = async argv => {
  const xhtml = fs.readFileSync(argv[3]).toString();
  const dom = new JSDOM(xhtml, {
    contentType: 'application/xhtml+xml'
  });
  const document = dom.window.document;
  const nodes = document.querySelectorAll('math');
  const format = argv[2]
  for (let node of nodes) await render(node, format)
  fs.writeFileSync(
    argv[4],
    '<?xml version="1.0" encoding="utf-8"?>' + dom.serialize()
  );
};

main(process.argv);
