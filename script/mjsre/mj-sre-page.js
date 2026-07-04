#! /usr/bin/env node

/*************************************************************************
 *
 *  pretext
 *
 *  Uses MathJax v4 to convert all TeX in an HTML document to forms
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
// Upgraded to MathJax v4 (package "@mathjax/src") and Speech Rule
// Engine v5, 2026-07-04.  The interface is unchanged.

//
//  Load the packages needed for MathJax
//
//  The node module loader is synchronous, so MathJax (4.1.3 and
//  later) can load font ranges on demand inside the synchronous
//  render actions below
require('@mathjax/src/js/util/asyncLoad/node.js');
const {mathjax} = require('@mathjax/src/js/mathjax.js');
const {TeX} = require('@mathjax/src/js/input/tex.js');
//  MathML input only needed for  svgenhanced  mode
const {MathML} = require('@mathjax/src/js/input/mathml.js');
const {SVG} = require('@mathjax/src/js/output/svg.js');
const {RegisterHTMLHandler} = require('@mathjax/src/js/handlers/html.js');
const {liteAdaptor} = require('@mathjax/src/js/adaptors/liteAdaptor.js');
const {STATE, newState} = require('@mathjax/src/js/core/MathItem.js');
//  MathJax v4 fonts are separate packages; "newcm" is the default font
const {MathJaxNewcmFont} = require('@mathjax/mathjax-newcm-font/js/svg.js');

//
//  MathJax v4 has no "AllPackages" module.  The component map in
//  "source.js" is the authoritative list of the TeX extensions
//  distributed within MathJax itself (the documented replacement for
//  the version 3 module).  Each extension's configuration module
//  registers the package when loaded, and is located just as
//  MathJax's own node demos locate it.  The "base" package is built
//  into the TeX input jax, but must still be named in the "packages"
//  option.  Exceptions: "autoload" and "require" presume the
//  in-browser loader; "colorv2" is superseded by "color" (these were
//  also absent from version 3's "AllPackages"); "bbm", "bboldx",
//  and "dsfont" commandeer blackboard bold, wanting font extensions
//  we do not load; and "physics" hijacks core macros by design
//  (version 4 lets its \div, divergence, defeat the division sign).
//
const {source} = require('@mathjax/src/components/js/source.js');
const path = require('path');
const fs = require('fs');
const texdir = path.join(require.resolve('@mathjax/src/js/input/tex.js'), '..', 'tex');
const excluded = new Set(['autoload', 'require', 'colorv2', 'bbm', 'bboldx', 'dsfont', 'physics']);
const extensions = Object.keys(source)
      .filter((key) => key.substring(0, 6) === '[tex]/')
      .map((key) => key.substring(6));
const AllPackages = [];
for (const name of ['base', ...extensions]) {
  if (excluded.has(name)) continue;
  const dir = path.join(texdir, name);
  const configuration = fs.existsSync(dir)
        ? fs.readdirSync(dir).find((file) => file.endsWith('Configuration.js'))
        : null;
  if (!configuration) {
    console.error('Could not find TeX package "' + name + '"');
    continue;
  }
  try {
    require(path.join(dir, configuration));
    AllPackages.push(name);
  } catch (err) {
    console.error('Could not load TeX package "' + name + '": ' + err.message);
  }
}

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

const sreOutputs = [argv.speech, argv.braille, argv.svgenhanced].filter(Boolean).length;
const needsSRE = sreOutputs > 0;

//
//  Load the Speech Rule Engine if needed for speech or braille.
//  This is the same engine MathJax itself depends upon, used
//  directly since our conversion is string-to-string.
//
const Sre = needsSRE ? require('speech-rule-engine') : null;

//
//  The engine configurations for the requested outputs, applied (and
//  their locales loaded) before rendering begins.
//
const sreConfigurations = [];

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
//  Create MathML serializers.  The version 4 TeX input records the
//  originating LaTeX on every node as "data-latex" attributes.  The
//  Speech Rule Engine intends to consult them one day, so they stay
//  in the internal tree, and in the serialization the engine is
//  handed; but no PreTeXt consumer has a use for them, they bloat
//  every output, and a raw "<" inside one is fatal to the XML
//  parsing downstream.  So MathML destined for output is serialized
//  by the contextual menu's visitor, which filters them away.
//
const {SerializedMmlVisitor} = require('@mathjax/src/js/core/MmlTree/SerializedMmlVisitor.js');
const visitor = new SerializedMmlVisitor();
const toMathML = (node => visitor.visitTree(node, html));
const {MmlVisitor} = require('@mathjax/src/js/ui/menu/MmlVisitor.js');
const filteringVisitor = new MmlVisitor();
const toFilteredMathML = ((node, math) => filteringVisitor.visitTree(node, math));

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
  //  An action to set up the pretext data array
  //  and serialize the MathML, if needed
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
//  An author's explicit "\\" (a newline) inside mathematics is
//  recorded faithfully in the MathML (and so heard in the speech and
//  braille), but the version 3 SVG output never rendered it, and
//  honoring it produces percentage-width SVG unusable downstream.  So
//  the SVG rendering, only, ignores such newlines, as version 3 did.
//  (A TeX input post-filter could scrub them at parse time, but the
//  one parse is shared by every output, and the MathML, speech, and
//  braille must keep the newline when outputs are combined in a
//  single run.)
//
function removeNewlines(root) {
  root.walkTree((node) => {
    if (node.attributes?.getExplicit('linebreak') === 'newline') {
      node.attributes.unset('linebreak');
    }
  });
}

//
//  If SVG is requested, add an action to add it to the output
//
if (argv.svg) {
  renderActions.svg = action(STATE.PRETEXTACTION, (math, doc, adaptor) => {
    removeNewlines(math.root);
    math.outputData.pretext.push(adaptor.firstChild(doc.outputJax.typeset(math, doc)));
    math.outputData.pretext.push(adaptor.text('\n'));
  });
}

//
//  The SVG output must not carry "data-latex" attributes either (see
//  the MathML serializers above); the wrapper class is told to skip
//  them when transcribing node attributes.
//
const {CommonWrapper} = require('@mathjax/src/js/output/common/Wrapper.js');
CommonWrapper.skipAttributes['data-latex'] = true;

//
//  If enhanced SVG is requested, add an action to add it to the output
//  (this mode is not currently employed by PreTeXt)
//
//
//  Version 4 breaks in-line mathematics into several SVG fragments for
//  reflowing, by default.  Our consumers require a single SVG per math
//  item, as version 3 produced, so in-line breaking is disabled.
//
const svgOptions = {
  fontData: MathJaxNewcmFont,
  fontCache: (argv.fontPaths ? 'none' : 'local'),
  linebreaks: {inline: false}
};

const mmldoc = mathjax.document('', {
  InputJax: new MathML(),
  OutputJax: new SVG(svgOptions),
});
if (argv.svgenhanced) {
  const configuration = {speech: argv.depth, modality: 'speech', locale: argv.locale, domain: argv.rules};
  sreConfigurations.push(configuration);
  renderActions.svg = action(STATE.PRETEXTACTION, (math, doc, adaptor) => {
    let out = mmldoc.convert(Sre.toEnriched(math.outputData.mml).toString());
    math.outputData.pretext.push(out);
    math.outputData.pretext.push(adaptor.text('\n'));
  }, sreOutputs > 1 ? () => Sre.setupEngine(configuration) : null);
}

//
//  If MathML is requested, add an action to add it to the output
//
if (argv.mathml) {
  renderActions.mathml = action(STATE.PRETEXTACTION, (math, doc, adaptor) => {
    const mml = adaptor.firstChild(adaptor.body(adaptor.parse(toFilteredMathML(math.root, math), 'text/html')));
    math.outputData.pretext.push(mml);
    math.outputData.pretext.push(adaptor.text('\n'));
  });
}

//
//  If speech is requested, add an action to add it to the output
//  and record the engine configuration for speech in the correct
//  locale
//
if (argv.speech) {
  const configuration = {modality: 'speech', locale: argv.locale, domain: argv.rules};
  sreConfigurations.push(configuration);
  renderActions.speech = action(STATE.PRETEXTACTION, (math, doc, adaptor) => {
    const speech = Sre.toSpeech(math.outputData.mml);
    math.outputData.pretext.push(adaptor.node('mjx-speech', {}, [adaptor.text(speech)]));
    math.outputData.pretext.push(adaptor.text('\n'));
  }, sreOutputs > 1 ? () => Sre.setupEngine(configuration) : null);
}

//
//  If braille is requested, add an action to add it to the output
//  and record the engine configuration for nemeth braille
//
if (argv.braille) {
  const configuration = {modality: 'braille', locale: 'nemeth', markup: 'layout', domain: 'default'};
  sreConfigurations.push(configuration);
  renderActions.braille = action(STATE.PRETEXTACTION, (math, doc, adaptor) => {
    const speech = Sre.toSpeech(math.outputData.mml);
    math.outputData.pretext.push(adaptor.node('mjx-braille', {}, [adaptor.text(speech)]));
    math.outputData.pretext.push(adaptor.text('\n'));
  }, sreOutputs > 1 ? () => Sre.setupEngine(configuration) : null);
}

//
//  Create an HTML document using the html file and a new TeX input jax
//
const html = mathjax.document(htmlfile, {
  renderActions,
  InputJax: new TeX({packages: argv.packages.split(/\s*,\s*/)}),
  OutputJax: new SVG(svgOptions)
});

//
//  Don't add the stylesheet unless SVG output is requested
//
if (!(argv.svg || argv.svgenhanced)) {
  html.addStyleSheet = () => {};
}

(async function () {
  //
  //  Ready the Speech Rule Engine.  setupEngine() is asynchronous,
  //  complete only when engineReady() resolves, so every
  //  configuration is applied, and its locale loaded, before
  //  rendering begins.  A lone configuration is then simply in
  //  effect.  When outputs need different configurations, each
  //  render action re-applies its own at the start of its pass:
  //  formally that call is asynchronous too, but a render action
  //  must be synchronous, and with no locale left to load the
  //  switch completes synchronously in current engines.
  //
  for (const configuration of sreConfigurations) {
    Sre.setupEngine(configuration);
    await Sre.engineReady();
  }
  //
  //  Render the document
  //
  await html.renderPromise();
  //
  //  Output the resulting document.  This is deliberately the HTML
  //  serialization: the XML serialization would add the XHTML
  //  namespace to the bare "html" root of the mock page, and every
  //  namespace-less element match in the packaging stylesheet
  //  (xsl/support/package-math.xsl) would then miss.  The attribute
  //  escaping it would add is not needed: no output attribute can
  //  hold a raw "<" now that the "data-latex" attributes are
  //  filtered away.
  //
  console.log(adaptor.outerHTML(adaptor.root(html.document)));
})()
  .catch((err) => console.error(err));
