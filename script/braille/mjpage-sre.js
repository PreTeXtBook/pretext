// Original gist from Peter Krautzberger
// https://gist.github.com/pkra/7ccdd351838f0bbdfe0080a4eacda7ca
// 2019-02-14
//
const fs = require('fs');
const mjnode = require('mathjax-node-sre');
const jsdom = require('jsdom');
const { JSDOM } = jsdom;
process.on('unhandledRejection', r => console.log(r));

mjnode.config({
  MathJax: {
    // your config
  }
});
const mj = mjnode.typeset;

const render = async (node) => {
  let mathinput = node.outerHTML;
  const result = await mj({
    math: mathinput,
    format: 'MathML',
    svg: true
  });
  node.innerHTML = result.svg
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
