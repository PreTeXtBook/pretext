#! /usr/bin/env node

/*************************************************************************
 *
 *  pretext
 *
 *  Uses MathJax v3 to convert all TeX in an HTML document to forms
 *  needed by PreTeXt
 *
 * ----------------------------------------------------------------------
 *
 *  Copyright (c) 2020 The MathJax Consortium
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

// Distributed to the PreTeXt project by Davide Cervone, Volker Sorge
// via https://gist.github.com/dpvc/386e8aac18c010361ef362b9237c71e9
// AIM braille textbook workshop, 2020-08

//
//  Load the packages needed for MathJax
//
require('mathjax-full/js/util/asyncLoad/node.js');
const {mathjax} = require('mathjax-full/js/mathjax.js');
const {TeX} = require('mathjax-full/js/input/tex.js');
//  RAB 2021-09-01, MathML only needed for  svgenhanced  mode
const {MathML} = require('mathjax-full/js/input/mathml.js');
const {SVG} = require('mathjax-full/js/output/svg.js');
const {RegisterHTMLHandler} = require('mathjax-full/js/handlers/html.js');
const {liteAdaptor} = require('mathjax-full/js/adaptors/liteAdaptor.js');
const {STATE, newState} = require('mathjax-full/js/core/MathItem.js');
//  RAB 2021-09-01, Enrichhandler only needed for  svgenhanced  mode
const {EnrichHandler} = require('mathjax-full/js/a11y/semantic-enrich.js');

const {AllPackages} = require('mathjax-full/js/input/tex/AllPackages.js');

//
//  Get the command-line arguments
//
var argv = require('yargs')
    .demand(0).strict()
    .usage('$0 [options] infile.html > outfile.html')
    .options({
      speech: {
        boolean: true,
        default: false,
        describe: 'produce speech output'
      },
      braille: {
        boolean: true,
        default: false,
        describe: 'produce braille output'
      },
      svg: {
        boolean: true,
        default: false,
        describe: 'produce svg output'
      },
      svgenhanced: {
        boolean: true,
        default: false,
        describe: 'produces speech enhanced svg output'
      },
      depth: {
        default: 'shallow',
        describe: 'The speech depth for SVG elements'
      },
      mathml: {
        boolean: true,
        default: false,
        describe: 'produce MathML output'
      },
      fontPaths: {
        boolean: true,
        default: false,
        describe: 'use svg paths not cached paths'
      },
      em: {
        default: 16,
        describe: 'em-size in pixels'
      },
      locale: {
        default: 'en',
        describe: 'the locale to use for speech output'
      },
      packages: {
        default: AllPackages.sort().join(', '),
        describe: 'the packages to use, e.g. "base, ams"'
      },
      rules: {
        default: 'mathspeak',
        describe: 'the rule set to use for speech output'
      }
    })
    .argv;

const needsSRE = argv.speech || argv.braille || argv.svgenhanced;

//
//  Load SRE if needed for speech or braille
//
const {Sre} = needsSRE ? require('mathjax-full/js/a11y/sre.js') :
      {Sre: {sreReady: Promise.resolve()}};

//
//  Read the HTML file
//
const htmlfile = require('fs').readFileSync(argv._[0], 'utf8');

//
//  Create DOM adaptor and register it for HTML documents
//
const adaptor = liteAdaptor({fontSize: argv.em});
const handler = RegisterHTMLHandler(adaptor);

//
//  Create a MathML serializer
//
const {SerializedMmlVisitor} = require('mathjax-full/js/core/MmlTree/SerializedMmlVisitor.js');
const visitor = new SerializedMmlVisitor();
const toMathML = (node => visitor.visitTree(node, html));


//
//  Create a renderAction that calls a function for each math item
//
function action(state, code, setup = null) {
  return [state, (doc) => {
    const adaptor = doc.adaptor;
    setup && setup();
    for (const math of doc.math) {
      try {
        code(math, doc, adaptor);
      } catch (err) {
        const id = adaptor.getAttribute(adaptor.parent(math.start.node), 'id');
        console.error('Error on item ' + id + ': ' + err.message);
      }
    }
  }];
}


//
//  States for PreTeXt actions
//
newState('PRETEXT', STATE.METRICS + 10);
newState('PRETEXTACTION', STATE.PRETEXT + 10);

//
//  The renderActions to use
//
const renderActions = {
  //
  //  An aciton to set up the pretext data array
  //  and enrich the MathML, if needed
  //
  pretext: action(STATE.PRETEXT, (math, doc, adaptor) => {
    math.outputData.pretext = [adaptor.text('\n')];
    if (needsSRE) {
      math.outputData.mml = toMathML(math.root).toString();
    }
  }),
  //
  //  Override the typeset action to make the mjx-data element
  //
  typeset: action(STATE.TYPESET, (math, doc, adaptor) => {
    math.typesetRoot = adaptor.node('mjx-data', {}, math.outputData.pretext);
  })
};

//
//  If SVG is requested, add an action to add it to the output
//
if (argv.svg) {
  renderActions.svg = action(STATE.PRETEXTACTION, (math, doc, adaptor) => {
    math.outputData.pretext.push(adaptor.firstChild(doc.outputJax.typeset(math, doc)));
    math.outputData.pretext.push(adaptor.text('\n'));
  });
}

//
//  If SVG is requested, add an action to add it to the output
//  RAB 2021-09-01,  svgenhanced  mode not being used (yet)
//
const mmldoc = mathjax.document('', {
  InputJax: new MathML(),
  OutputJax: new SVG({fontCache: (argv.fontPaths ? 'none' : 'local')}),
});
if (argv.svgenhanced) {
  renderActions.svg = action(STATE.PRETEXTACTION, (math, doc, adaptor) => {
    let out = mmldoc.convert(Sre.toEnriched(math.outputData.mml).toString());
    math.outputData.pretext.push(out);
    math.outputData.pretext.push(adaptor.text('\n'));
  }, () => {
    Sre.setupEngine({speech: argv.depth, modality: 'speech', locale: argv.locale, domain: argv.rules});
  });
}

//
//  If MathML is requested, add an action to add it to the output
//
if (argv.mathml) {
  renderActions.mathml = action(STATE.PRETEXTACTION, (math, doc, adpator) => {
    const mml = adaptor.firstChild(adaptor.body(adaptor.parse(toMathML(math.root), 'text/html')));
    math.outputData.pretext.push(mml);
    math.outputData.pretext.push(adaptor.text('\n'));
  });
}

//
//  If speech is requested, add an action to add it to the output
//  and set up the speech engine for speech in the correct locale
//
if (argv.speech) {
  renderActions.speech = action(STATE.PRETEXTACTION, (math, doc, adaptor) => {
    const speech = Sre.toSpeech(math.outputData.mml);
    math.outputData.pretext.push(adaptor.node('mjx-speech', {}, [adaptor.text(speech)]));
    math.outputData.pretext.push(adaptor.text('\n'));
  }, () => {
    Sre.setupEngine({modality: 'speech', locale: argv.locale, domain: argv.rules});
  });
}

//
//  If braille is requested, add an action to add it to the output
//  and set up the speech engine for nemeth braille
//
if (argv.braille) {
  renderActions.braille = action(STATE.PRETEXTACTION, (math, doc, adaptor) => {
    const speech = Sre.toSpeech(math.outputData.mml);
    math.outputData.pretext.push(adaptor.node('mjx-braille', {}, [adaptor.text(speech)]));
    math.outputData.pretext.push(adaptor.text('\n'));
  }, () => {
    Sre.setupEngine({modality: 'braille', locale: 'nemeth', markup: 'layout', domain: 'default'});
  });
}

//
// Patch MathJax 3.0.5 SVG bug:
//
if (mathjax.version === '3.0.5') {
  const {SVGWrapper} = require('mathjax-full/js/output/svg/Wrapper.js');
  const CommonWrapper = SVGWrapper.prototype.__proto__;
  SVGWrapper.prototype.unicodeChars = function (text, variant) {
    if (!variant) variant = this.variant || 'normal';
    return CommonWrapper.unicodeChars.call(this, text, variant);
  }
}

//
//  Create an HTML document using the html file and a new TeX input jax
//
const html = mathjax.document(htmlfile, {
  renderActions,
  InputJax: new TeX({packages: argv.packages.split(/\s*,\s*/)}),
  OutputJax: new SVG({fontCache: (argv.fontPaths ? 'none' : 'local')})
});

//
//  Don't add the stylesheet unless SVG output is requested
//
if (!(argv.svg || argv.svgenhanced)) {
  html.addStyleSheet = () => {};
}

(async function () {
  //
  //  Wait for SRE, if needed
  //
  if (needsSRE) {
    const feature = {
      xpath: require.resolve('wicked-good-xpath/dist/wgxpath.install-node.js'),
      json: require.resolve('speech-rule-engine/lib/mathmaps/base.json').replace(/\/base\.json$/, '')
    };
    Sre.setupEngine(feature);
    if (argv.braille) {
      Sre.setupEngine({locale: 'nemeth'});
    }
    if (argv.speech || argv.svgenhanced) {
      Sre.setupEngine({locale: argv.locale});
    }
    await Sre.sreReady();
  }
  //
  //  Render the document
  //
  await mathjax.handleRetriesFor(() => html.render());
  //
  //  Output the resulting document
  //
  console.log(adaptor.outerHTML(adaptor.root(html.document)));
})()
  .catch((err) => console.error(err));
