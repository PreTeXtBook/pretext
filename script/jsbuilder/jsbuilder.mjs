/*******************************************************************************
 * jsbuilder.mjs
 *******************************************************************************
 * PreTeXt JavaScript Builder.
 *
 * Bundles and minifies the PreTeXt JavaScript source files in js/ into
 * distributable artifacts in js/dist/.  The architecture mirrors the CSS
 * builder in script/cssbuilder/cssbuilder.mjs; refer to that file for the
 * overall design philosophy.
 *
 * OUTPUT TARGETS
 * --------------
 * Not every source file maps 1-to-1 to a dist file.  The targets fall into
 * four categories based on how they are loaded and whether they need bundling:
 *
 *  IIFE bundles  — multiple source files combined into one IIFE.
 *    pretext-core    js/src/pretext-core.js  (pretext.js + pretext_add_on.js + knowl.js)
 *
 *  ES module     — loaded via `import` from an inline <script type="module">.
 *    mathjax_startup  js/mathjax_startup.js
 *
 *  Plain scripts — processed individually; loaded as regular <script> elements.
 *    pretext_search          js/pretext_search.js
 *    ptx_scorm_events        js/ptx_scorm_events.js
 *    lti_iframe_resizer      js/lti_iframe_resizer.js
 *    knowl                   js/knowl.js
 *    pretext-webwork/2.X/pretext-webwork   (versions: 2.19–2.20)
 *
 *  Copied verbatim — pre-built third-party bundles; esbuild copies them as-is.
 *    diagcess/diagcess       js/diagcess/diagcess.js
 *
 * MINIFICATION POLICY
 * -------------------
 * When building all targets (the default, used to update the committed dist
 * files), minification is OFF so that git diffs remain readable.  When
 * building a single target with -t, minification is ON — this is the path
 * used when the CLI (or a developer) is building directly to a book's output
 * directory with -o.
 *
 * This matches the cssbuilder behaviour.
 *
 * USAGE (run from this directory, or via npm scripts)
 * -----
 *   npm run build                       Build all targets → js/dist/
 *   npm run build -- -t pretext-core    Build one target (minified)
 *   npm run build -- -o /abs/path -t pretext-core   Build to a custom dir
 *   npm run build -- -w                 Watch for changes and rebuild
 *   npm run build -- -l                 List all target names
 *   npm run build -- -h                 Print help
 ******************************************************************************/

import esbuild from 'esbuild';
import commandLineArgs from 'command-line-args';
import commandLineUsage from 'command-line-usage';
import path from 'path';
import * as url from 'url';

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

// Resolve the pretext/js directory relative to this script's location.
// __dirname is not available in ES modules, so we derive it from import.meta.
const __dirname = url.fileURLToPath(new URL('.', import.meta.url));

// Root of the js/ source tree (two directories up from script/jsbuilder/).
const jsRoot = path.join(__dirname, '../../js/');

// ---------------------------------------------------------------------------
// CLI option parsing
// ---------------------------------------------------------------------------

const optionDefinitions = [
  { name: 'output-directory', alias: 'o', type: String },
  { name: 'watch',            alias: 'w', type: Boolean },
  { name: 'selected-target',  alias: 't', type: String },
  { name: 'list-targets',     alias: 'l', type: Boolean },
  { name: 'help',             alias: 'h', type: Boolean },
  { name: 'verbose',          alias: 'v', type: Boolean },
];

const helpContents = [
  {
    header: 'PreTeXt JS Builder',
    content:
      'Bundles and minifies PreTeXt JavaScript source files into js/dist/.\n' +
      'By default all targets are built without minification (suitable for\n' +
      'committing the dist files to the repository).  Use -t to build a\n' +
      'single target; that build is always minified.',
  },
  {
    header: 'Options',
    optionList: [
      {
        name: 'help',
        alias: 'h',
        description: 'Print this usage guide.',
      },
      {
        name: 'list-targets',
        alias: 'l',
        description: 'List all available target names.',
      },
      {
        name: 'output-directory',
        alias: 'o',
        typeLabel: '{underline path}',
        description:
          'Directory to write output files into.  Accepts an absolute path or\n' +
          'a path relative to {bold pretext/script/jsbuilder/}.  Defaults to\n' +
          '{bold pretext/js/dist/}.',
      },
      {
        name: 'selected-target',
        alias: 't',
        typeLabel: '{underline name}',
        description:
          'Build only the named target (see -l for the list).  The output is\n' +
          'minified.  When combined with -o, the file is written directly to\n' +
          'that directory.',
      },
      {
        name: 'verbose',
        alias: 'v',
        description: 'Print extra output from esbuild.',
      },
      {
        name: 'watch',
        alias: 'w',
        description: 'Continuously watch source files for changes and rebuild.',
      },
    ],
  },
  {
    header: 'Usage examples',
    content: [
      { desc: 'Rebuild all dist files (for committing to git):', example: '$ npm run build' },
      {},
      { desc: 'Watch for changes while developing:', example: '$ npm run build -- -w' },
      {},
      { desc: 'Build a single minified target:', example: '$ npm run build -- -t pretext-core' },
      {},
      { desc: 'Build one target to a book output directory:', example: '$ npm run build -- -t pretext-core -o /path/to/book/_static/pretext/js/dist' },
    ],
  },
];

function getOptions() {
  return commandLineArgs(optionDefinitions);
}

// ---------------------------------------------------------------------------
// Target definitions
// ---------------------------------------------------------------------------

// Each target describes one output file.  The `group` field controls which
// esbuild configuration is used (see buildAllGroups):
//
//   'bundle'  — bundle: true, format: 'iife'
//               Use for entry points in js/src/ that import multiple files.
//               The resulting IIFE scopes everything internally; symbols meant
//               to be accessed by other scripts must be assigned to window.
//
//   'esm'     — bundle: false, format: 'esm'
//               Use for files that export named functions that the XSL loads
//               with `import { ... } from '...'` inside a <script type="module">.
//
//   'script'  — bundle: false, no format override
//               Use for stand-alone plain-JS files loaded via <script src="...">.
//               Their top-level declarations stay in the global scope.
//
//   'copy'    — loader: { '.js': 'copy' }
//               Use for pre-built third-party bundles that must NOT be
//               transformed by esbuild at all.  The file is copied verbatim.
//               Example: diagcess.js ships already minified from npm; any
//               esbuild transformation breaks its UMD self-registration.

// The supported WeBWorK server minor versions.  Each ships its own copy
// of the integration shim so that the correct iframe API can be targeted.
const WEBWORK_VERSIONS = ['2.19', '2.20'];

function getAllTargets() {
  return [
    // ------------------------------------------------------------------
    // IIFE bundles
    // ------------------------------------------------------------------

    // Core bundle: always-loaded scripts for navigation, UI helpers, and
    // knowl (cross-reference) expansion.  Combining them saves two HTTP
    // requests on every page load.
    // Entry point: js/src/pretext-core.js
    {
      name: 'pretext-core',
      group: 'bundle',
      in: path.join(jsRoot, 'src/pretext-core.js'),
    },

    // ------------------------------------------------------------------
    // ES module
    // ------------------------------------------------------------------

    // MathJax startup: sets window.MathJax options before MathJax itself
    // loads.  The XSL generates an inline <script type="module"> that does
    //   import { startMathJax } from './mathjax_startup.js';
    //   startMathJax({ hasWebworkReps: ..., ... });
    // so the file must remain an ES module (export preserved).
    {
      name: 'mathjax_startup',
      group: 'esm',
      in: path.join(jsRoot, 'mathjax_startup.js'),
    },

    // ------------------------------------------------------------------
    // Plain script targets
    // ------------------------------------------------------------------

    // Search UI: depends on lunr (loaded from CDN) and on PTXDialog from
    // the core bundle.  Conditional: only loaded when native search is
    // enabled in the publication file.
    {
      name: 'pretext_search',
      group: 'script',
      in: path.join(jsRoot, 'pretext_search.js'),
    },

    // SCORM tracking: hooks into RunestoneBase to report exercise
    // submissions to an LMS.  Only loaded when html.scorm = 'yes'.
    {
      name: 'ptx_scorm_events',
      group: 'script',
      in: path.join(jsRoot, 'ptx_scorm_events.js'),
    },

    // LTI frame resize: handles lti.frameResize messages from an LMS so
    // embedded iframes size themselves correctly.
    {
      name: 'lti_iframe_resizer',
      group: 'script',
      in: path.join(jsRoot, 'lti_iframe_resizer.js'),
    },

    // Standalone knowl script: used by the WeBWorK problem iframe to enable
    // knowl expansion inside problem content.  knowl.js is also bundled into
    // pretext-core.js (for the main page), but the WW iframe loads it
    // separately as a plain script, so we need a standalone dist file too.
    {
      name: 'knowl',
      group: 'script',
      in: path.join(jsRoot, 'knowl.js'),
    },

    // ------------------------------------------------------------------
    // Verbatim copy targets (pre-built third-party bundles)
    // ------------------------------------------------------------------

    // Diagram accessibility: pre-built npm package (diagcess@1.3.3).
    // Must be copied verbatim — esbuild transformation breaks its UMD
    // self-registration pattern, causing diagcess.Base to be undefined.
    {
      name: 'diagcess/diagcess',
      group: 'copy',
      in: path.join(jsRoot, 'diagcess/diagcess.js'),
    },

    // STACK/Moodle VLE integration.  These two files are always loaded
    // together when STACK problems are present.  They are kept as separate
    // dist files (rather than bundled) because this code is in active
    // development; keeping source and dist in 1-to-1 correspondence makes
    // incremental changes easier to review.
    {
      name: 'pretext-stack/stackjsvle',
      group: 'script',
      in: path.join(jsRoot, 'pretext-stack/stackjsvle.js'),
    },
    {
      name: 'pretext-stack/stackapicalls',
      group: 'script',
      in: path.join(jsRoot, 'pretext-stack/stackapicalls.js'),
    },

    // WeBWorK integration: one file per server minor version (2.19–2.20).
    // Loaded conditionally; the version is selected at build time based on
    // the WeBWorK server minor version reported in the processed XML.
    ...WEBWORK_VERSIONS.map(v => ({
      name: `pretext-webwork/${v}/pretext-webwork`,
      group: 'script',
      in: path.join(jsRoot, `pretext-webwork/${v}/pretext-webwork.js`),
    })),
  ];
}

// ---------------------------------------------------------------------------
// Target filtering
// ---------------------------------------------------------------------------

function getSelectedTargets(options) {
  const all = getAllTargets();

  if (!options['selected-target']) {
    return all;
  }

  const filtered = all.filter(t => t.name === options['selected-target']);
  if (filtered.length === 0) {
    console.error(
      `Error: target "${options['selected-target']}" not found.\n` +
      `Run with -l to see available targets.`
    );
    process.exit(1);
  }
  return filtered;
}

function getOutDir(options) {
  if (options['output-directory']) {
    return options['output-directory'];
  }
  // Default: js/dist/ relative to the repository root
  return path.join(jsRoot, 'dist');
}

// ---------------------------------------------------------------------------
// esbuild helpers
// ---------------------------------------------------------------------------

/**
 * Build (or watch) one group of targets that all share the same esbuild config.
 *
 * @param {Array}   targets     - array of { name, in } objects for this group
 * @param {string}  outDir      - absolute path to the output directory
 * @param {object}  esbuildOpts - esbuild-specific options merged into the context
 * @param {boolean} watch       - whether to enter watch mode instead of one-shot build
 * @param {boolean} verbose     - whether to enable detailed esbuild logging
 */
async function buildGroup(targets, outDir, esbuildOpts, watch, verbose) {
  if (targets.length === 0) return;

  // Map our target descriptors to the {in, out} shape esbuild expects.
  // The `out` value is the output basename without extension, relative to
  // outDir.  Sub-paths (e.g. 'diagcess/diagcess') create subdirectories.
  const entryPoints = targets.map(t => ({ in: t.in, out: t.name }));

  const ctx = await esbuild.context({
    entryPoints,
    outdir: outDir,
    sourcemap: true,
    logLevel: verbose ? 'debug' : 'info',
    metafile: true,
    ...esbuildOpts,
  });

  if (watch) {
    // esbuild's watch mode re-runs on every source change and prints timing.
    await ctx.watch();
  } else {
    await ctx.rebuild();
    await ctx.dispose();
  }
}

// ---------------------------------------------------------------------------
// Main build orchestration
// ---------------------------------------------------------------------------

async function buildAll(options) {
  const targets = getSelectedTargets(options);
  const outDir  = getOutDir(options);
  const watch   = !!options.watch;
  const verbose = !!options.verbose;

  // Minify only when building a single target.  Multi-target (full dist)
  // builds are left unminified so that committed files produce readable diffs
  // in git.  This mirrors the cssbuilder behaviour.
  const minify = targets.length === 1;

  if (verbose) {
    console.log('JSBuilder options:', options);
    console.log('Output dir:', outDir);
    console.log('Minify:', minify);
  }

  // Partition targets into their four build groups.
  const bundleTargets = targets.filter(t => t.group === 'bundle');
  const esmTargets    = targets.filter(t => t.group === 'esm');
  const scriptTargets = targets.filter(t => t.group === 'script');
  const copyTargets   = targets.filter(t => t.group === 'copy');

  // Run all non-empty groups in parallel.  Each group gets its own esbuild
  // context so that different bundle/format settings can be applied.
  await Promise.all([

    // Group 1: IIFE bundles.
    // bundle: true  — resolve imports and combine into one file
    // format: 'iife' — wrap in an IIFE so internal names don't pollute globals
    buildGroup(
      bundleTargets,
      outDir,
      { bundle: true, format: 'iife', minify },
      watch,
      verbose
    ),

    // Group 2: ES module.
    // bundle: false — transform/minify the single file without resolving imports
    // format: 'esm' — preserve the `export` keyword so the file can be
    //                 `import`-ed from an inline <script type="module">
    buildGroup(
      esmTargets,
      outDir,
      { bundle: false, format: 'esm', minify },
      watch,
      verbose
    ),

    // Group 3: Plain scripts.
    // bundle: false — no import resolution; each file is processed individually
    // No format override — esbuild infers the format from each file's content.
    // Files with no import/export statements are treated as plain scripts, so
    // their top-level function declarations remain globally accessible.
    buildGroup(
      scriptTargets,
      outDir,
      { bundle: false, minify },
      watch,
      verbose
    ),

    // Group 4: Verbatim copies.
    // loader: { '.js': 'copy' } — esbuild copies the file without any
    // transformation, syntax changes, or minification.  Use this for
    // pre-built third-party bundles where esbuild processing would break
    // the file.  Source maps are not generated for copied files.
    buildGroup(
      copyTargets,
      outDir,
      { loader: { '.js': 'copy' }, sourcemap: false },
      watch,
      verbose
    ),

  ]);

  if (!watch) {
    console.log('JS build complete!');
  }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

const options = getOptions();

if (options.help) {
  console.log(commandLineUsage(helpContents));

} else if (options['list-targets']) {
  console.log('Available targets:');
  for (const t of getAllTargets()) {
    console.log(`  ${t.name}  [${t.group}]`);
  }

} else {
  await buildAll(options);
}
