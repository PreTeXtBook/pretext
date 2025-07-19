import esbuild from 'esbuild';
import { sassPlugin } from 'esbuild-sass-plugin';
import commandLineArgs from 'command-line-args';
import commandLineUsage from 'command-line-usage';
import path from 'path';
import * as url from 'url';

// Path to pretext/css relative to the pretext/script/cssbuilder directory
const __dirname = url.fileURLToPath(new URL('.', import.meta.url));
const cssRoot = path.join(__dirname, '../../css/');

function getOptions() {
  const optionDefinitions = [
    { name: 'output-directory', alias: 'o', type: String },
    { name: 'watch', alias: 'w', type: Boolean },
    { name: 'selected-target', alias: 't', type: String },
    { name: 'config-options', alias: 'c', type: String },
    { name: 'list-targets', alias: 'l', type: Boolean },
    { name: 'help', alias: 'h', type: Boolean },
    { name: 'verbose', alias: 'v', type: Boolean },
  ]
  let configs = commandLineArgs(optionDefinitions);

  if (configs['config-options']) {
    // Convert the JSON string to an object
    const configOptions = JSON.parse(configs['config-options']);
    configs['config-options'] = configOptions;
  }

  return configs;
}

const helpContents = [
  {
    header: 'PreTeXt CSS Builder',
    content: 'Generates CSS files for PreTeXt themes. By default, all build targets are built to the css/dist directory.'
  },
  {
    header: 'Options',
    optionList: [
      {
        name: 'config-options',
        typeLabel: '{underline json-text}',
        description: 'A string containing a JSON blob with configuration options for the build. This includes variables and options for building a customized version of a theme. This might look like {bold \'\\{"options": \\{"primary-color": "#801811", "primary-color-dark": "#801811", "secondary-color": "#2a5ea4"\\}\\}\'}.',
      },
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
        description: 'Directory to place output in. Can be absolute or relative to the {bold pretext/script/cssbuilder/} directory.',
        alias: 'o',
      },
      {
        name: 'selected-target',
        description: 'Which one target to build. Use {underline list-targets} option to see available targets. If there is an {underline output-directory} set and the target is not a module, the target will be build with the name {bold theme.css} regardless of the input target name.',
        alias: 't',
      },
      {
        name: 'verbose',
        description: 'Print extra output.',
        alias: 'v',
      },
      {
        name: 'watch',
        description: 'Continuously watch for changes to css/scss and rebuild.',
        alias: 'w',
      }
    ]
  },
  {
    header: 'Usage',
    content: [
      {
        desc: 'Build one or more themes. Note that options must be separated from the command with --.',
        example: '$ npm run build [-- options...]'
      },
      {},
      {
        desc: 'Build one target to a specified output directory, rebuilding with any changes.',
        example: '$ npm run build -- -t theme-default-modern -o /path/to/output -w'
      },
    ]
  },
]

function getOutDir(options) {
  if (options['output-directory'])
    return options['output-directory'];
  else
    return path.join(cssRoot, 'dist');
}

function getTargets(options) {
  let targets = [
    // -------------------------------------------------------------------------
    // Web targets - pretext assumes output name will be 'theme-XXX'
    // Legacy targets
    { out: 'theme-default-legacy', in: path.join(cssRoot, 'targets/html/legacy/default/theme-default.scss')},
    { out: 'theme-min-legacy', in: path.join(cssRoot, 'targets/html/legacy/min/theme-min.scss')},
    { out: 'theme-crc-legacy', in: path.join(cssRoot, 'targets/html/legacy/crc/theme-crc.scss')},
    { out: 'theme-soundwriting-legacy', in: path.join(cssRoot, 'targets/html/legacy/soundwriting/theme-soundwriting.scss')},
    { out: 'theme-wide-legacy', in: path.join(cssRoot, 'targets/html/legacy/wide/theme-wide.scss')},
    { out: 'theme-oscarlevin-legacy', in: path.join(cssRoot, 'targets/html/legacy/oscarlevin/theme-oscarlevin.scss')},
    // -------------------------------------------------------------------------
    // Modern web targets
    { out: 'theme-default-modern', in: path.join(cssRoot, 'targets/html/default-modern/theme-default-modern.scss')},
    { out: 'theme-salem', in: path.join(cssRoot, 'targets/html/salem/theme-salem.scss')},
    { out: 'theme-denver', in: path.join(cssRoot, 'targets/html/denver/theme-denver.scss') },
    { out: 'theme-greeley', in: path.join(cssRoot, 'targets/html/greeley/theme-greeley.scss') },
    { out: 'theme-boulder', in: path.join(cssRoot, 'targets/html/boulder/theme-boulder.scss') },
    { out: 'theme-tacoma', in: path.join(cssRoot, 'targets/html/tacoma/theme-tacoma.scss') },
    // -------------------------------------------------------------------------
    // Non-web targets
    { out: 'reveal', in: path.join(cssRoot, 'targets/revealjs/reveal.scss')},
    { out: 'kindle', in: path.join(cssRoot, 'targets/ebook/kindle/kindle.scss')},
    { out: 'epub', in: path.join(cssRoot, 'targets/ebook/epub/epub.scss')},
  ]

  if (options['selected-target']) {
    // Build the one selected target
    if(options['selected-target'] !== 'theme-custom') {
      targets = targets.filter(target => target.out === options['selected-target']);
    } else {
      // Custom theme build
      const configOptions = options['config-options'];
      // console.log('configOptions', configOptions);
      if (configOptions && configOptions['options'] && configOptions['options']['entry-point']) {
        // Custom theme build with output directory
        targets = [
          { out: 'theme-custom', in: configOptions['options']['entry-point']}
        ]
        // Remove the entry-point from the options so it doesn't get turned into scss variable
        delete configOptions['options']['entry-point'];
      } else {
        // Custom theme build without output directory
        console.error('Custom theme build requires an entry-point config option. It should be the path to the custom theme SCSS file.');
        process.exit(1);
      }
    }

    if (targets.length === 0) {
      console.error('Selected target not found');
      process.exit(1);
    } else {
      // Change the output name if an output directory is set (assume we building directly to book)
      if (options['output-directory']) {
        const targetName = targets[0].out;
        if (targetName.includes('modules/')) {
          // Modules build directly to destination with no subfolder
          targets[0].out = targets[0].out.replace('modules/', '');
        } else {
          // Others build as theme.css
          targets[0].out = 'theme';
        }
      }
    }
  }

  return targets;
}

// Secondary files that are never the primary target but may need to be built with the theme
function getModules(options) {
  let webModules = [
    // -------------------------------------------------------------------------
    // Modules - these are secondary files
    { out: 'print-worksheet', in: path.join(cssRoot, 'targets/print-worksheet/print-worksheet.scss')}
  ];
  // Could be other types of modules here...

  if (!options['selected-target']) {
    // No particular target, build all
    return webModules;
  }
  else if (options['selected-target'].indexOf('theme-') !== -1) {
    // Building a web theme, build the web modules
    return webModules;
  }

  return [];
}

async function getESBuildConfig(options) {
  const targets = getTargets(options);
  const modules = getModules(options);
  const outDir = getOutDir(options);
  // Only minify if there is only one target
  // when building all the prebuilt themes to dist, we want to preserve new lines
  // as the files are going into git
  const minifyCSS = targets.length === 1;
  const ctx = await esbuild
    .context({
      entryPoints: targets.concat(modules),
      bundle: true,
      sourcemap: true,
      minify: minifyCSS,
      outdir: outDir,
      format: 'esm',
      plugins: [
        sassPlugin({
          'loadPaths': [cssRoot],
          precompile(source, pathname, isRoot) {
            // If this is root file, add custom variables. Anything else is just passed through
            if(!isRoot)
              return source;

            // Tack on any config variables to the top of the file
            let prefix = '';
            if (options['selected-target'] && options['config-options']) {
              for (const [key, value] of Object.entries(options['config-options']['options'])) {
                prefix += `$${key}: ${value};\n`;
              }
            }
            return prefix + source;
          }
        }),
      ],
      metafile: true,
      logLevel: 'info',
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
    console.log(target.out);
  }
} else {
  // Actual build
  const ctx = await getESBuildConfig(options);
  if (options['verbose']) console.log("CSSBuilder options", options);

  if (options.watch) {
    await ctx.watch();
  } else {
    await ctx.rebuild();
    await ctx.dispose();
    console.log('CSS build complete!');
  }
}
