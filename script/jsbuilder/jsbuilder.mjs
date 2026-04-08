import esbuild from 'esbuild';
import commandLineArgs from 'command-line-args';
import commandLineUsage from 'command-line-usage';
import path from 'path';
import * as url from 'url';

const __dirname = url.fileURLToPath(new URL('.', import.meta.url));
const jsRoot = path.join(__dirname, '../../js/');

function getOptions() {
  const optionDefinitions = [
    { name: 'output-directory', alias: 'o', type: String },
    { name: 'watch', alias: 'w', type: Boolean },
    { name: 'selected-target', alias: 't', type: String },
    { name: 'list-targets', alias: 'l', type: Boolean },
    { name: 'help', alias: 'h', type: Boolean },
    { name: 'verbose', alias: 'v', type: Boolean },
  ];
  return commandLineArgs(optionDefinitions);
}

const helpContents = [
  {
    header: 'PreTeXt JS Builder',
    content: 'Bundles PreTeXt JavaScript source modules into distribution files. By default, all targets are built to the js/dist directory.',
  },
  {
    header: 'Options',
    optionList: [
      {
        name: 'help',
        description: 'Print this usage guide.',
        alias: 'h',
      },
      {
        name: 'list-targets',
        description: 'List all build targets.',
        alias: 'l',
      },
      {
        name: 'output-directory',
        description: 'Directory to place output in. Can be absolute or relative to the {bold pretext/script/jsbuilder/} directory.',
        alias: 'o',
      },
      {
        name: 'selected-target',
        description: 'Which one target to build. Use {underline list-targets} to see available targets.',
        alias: 't',
      },
      {
        name: 'verbose',
        description: 'Print extra output.',
        alias: 'v',
      },
      {
        name: 'watch',
        description: 'Continuously watch for changes and rebuild.',
        alias: 'w',
      },
    ],
  },
  {
    header: 'Usage',
    content: [
      {
        desc: 'Build all targets to js/dist/.',
        example: '$ npm run build',
      },
      {},
      {
        desc: 'Build one target to a specific directory, watching for changes.',
        example: '$ npm run build -- -t pretext-core -o /path/to/output -w',
      },
    ],
  },
];

function getTargets(options) {
  let targets = [
    {
      out: 'pretext-core',
      in: path.join(jsRoot, 'src/pretext-core-entry.js'),
    },
    {
      out: 'pretext-search',
      in: path.join(jsRoot, 'src/pretext-search-entry.js'),
    },
  ];

  if (options['selected-target']) {
    targets = targets.filter((t) => t.out === options['selected-target']);
    if (targets.length === 0) {
      console.error(
        `Target "${options['selected-target']}" not found. Use --list-targets to see available targets.`
      );
      process.exit(1);
    }
  }

  return targets;
}

function getOutDir(options) {
  if (options['output-directory']) return options['output-directory'];
  return path.join(jsRoot, 'dist');
}

async function getESBuildConfig(options) {
  const targets = getTargets(options);
  const outDir = getOutDir(options);

  const ctx = await esbuild.context({
    entryPoints: targets,
    bundle: true,
    sourcemap: true,
    minify: false,
    outdir: outDir,
    format: 'iife',
    // External globals that are loaded separately
    external: ['MathJax'],
    logLevel: 'info',
    metafile: true,
  });

  return ctx;
}

// --------------------------------------------------------------------------
// Main
const options = getOptions();

if (options['help']) {
  console.log(commandLineUsage(helpContents));
} else if (options['list-targets']) {
  const targets = getTargets({});
  console.log('Available targets:');
  for (const target of targets) {
    console.log(`  ${target.out}`);
  }
} else {
  const ctx = await getESBuildConfig(options);
  if (options['verbose']) console.log('JSBuilder options', options);

  if (options.watch) {
    await ctx.watch();
    console.log('Watching for changes...');
  } else {
    await ctx.rebuild();
    await ctx.dispose();
    console.log('JS build complete!');
  }
}
