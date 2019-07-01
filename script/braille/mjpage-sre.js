// Original gist from Peter Krautzberger
// https://gist.github.com/pkra/7ccdd351838f0bbdfe0080a4eacda7ca
// Rob Beezer: 2019-02-14

// Alexei S. Kolesnikov: 2019-06-27
// Modified render(node) method to produce cleaner output
// and remove extraneous spaces.

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

const render = async (node) => {
  let mathinput = node.outerHTML;
  const result = await mj({
    math: mathinput, // This is the MathML expression that will be converted
    format: "MathML",
    mml:true, // I think it does not matter which we pick, mml or svg; we are not using it anyway
    sre: ['domain', 'default', 'locale', 'nemeth'], // This is important!
    });

  // result.speech contains Nemeth Braille code for mathinput
  // with extra spaces that we kill now. This also needs to be
  // enclosed in some tags. I picked 'title'; we may want to
  // come up with something like <nemeth>.
  node.innerHTML = '<title>'+result.speech.replace(/ /g,'')+'</title>';
};

const main = async argv => {
  const xhtml = fs.readFileSync(argv[2]).toString();
  const dom = new JSDOM(xhtml, {
    contentType: 'application/xhtml+xml'
  });
  const document = dom.window.document;
  const nodes = document.querySelectorAll('math');
  for (let node of nodes) await render(node)
  fs.writeFileSync(
    argv[3],
    '<?xml version="1.0" encoding="utf-8"?>' + dom.serialize()
  );
};

main(process.argv);
