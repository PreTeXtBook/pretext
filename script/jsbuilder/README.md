# PreTeXt JavaScript Builder

Bundles and minifies the PreTeXt JavaScript source files in [`js/`](../../js/)
into distributable artifacts in [`js/dist/`](../../js/dist/).

The design mirrors the CSS builder in
[`script/cssbuilder/`](../cssbuilder/).  If you are familiar with that tool,
the concepts here are identical.

---

## Background

PreTeXt ships several JavaScript files that are loaded by the HTML output.
Some are always present (navigation, knowls, MathJax setup); others are
conditional (search, SCORM, WeBWorK, STACK/Moodle, LTI, diagram
accessibility).  Before this build step existed, each source file was shipped
and loaded as-is.

The builder gives us:

- **Bundling** — always-loaded scripts are combined into a single
  `pretext-core.js`, reducing HTTP requests on every page.
- **Minification** — single-target builds produce smaller files for deployment.
- **Source maps** — `.map` files are always generated so the original source
  can be inspected in browser DevTools even when code is minified.
- **A clear seam for future work** — source files in `js/` and `js/src/` are
  the maintained code; `js/dist/` is generated output.  This lets us
  modularise and add TypeScript gradually without changing what ships.

---

## Output targets

| Dist file | Source | Always loaded? |
|---|---|---|
| `pretext-core.js` | `js/src/pretext-core.js` (bundles `pretext.js` + `pretext_add_on.js` + `knowl.js`) | Yes |
| `mathjax_startup.js` | `js/mathjax_startup.js` | Yes (ES module) |
| `pretext_search.js` | `js/pretext_search.js` | Conditional (native search) |
| `ptx_scorm_events.js` | `js/ptx_scorm_events.js` | Conditional (`html.scorm='yes'`) |
| `pretext-stack/stackjsvle.js` | `js/pretext-stack/stackjsvle.js` | Conditional (STACK problems) |
| `pretext-stack/stackapicalls.js` | `js/pretext-stack/stackapicalls.js` | Conditional (STACK problems) |
| `lti_iframe_resizer.js` | `js/lti_iframe_resizer.js` | Conditional (LTI) |
| `diagcess/diagcess.js` | `js/diagcess/diagcess.js` | Conditional (diagram a11y) |
| `pretext-webwork/2.X/pretext-webwork.js` | `js/pretext-webwork/2.X/pretext-webwork.js` | Conditional (WeBWorK, version-matched) |

**Not included:** `js/jquery.min.js`.  jQuery is loaded separately by the XSL
from `$html.js.root` (the `js/` root, not `js/dist/`), because it is a
third-party library rather than a built artifact.  The WeBWorK integration
scripts call `$("body").trigger(...)` on the page, and the Runestone runtime
also requires jQuery to be present globally.

---

## Build groups and esbuild configurations

Three esbuild configurations are used, determined by the target's `group`
property in `jsbuilder.mjs`:

| Group | `bundle` | `format` | When to use |
|---|---|---|---|
| `bundle` | `true` | `iife` | Entry points in `js/src/` that import multiple files.  Everything is scoped to the IIFE; symbols needed by other scripts must be assigned to `window`.  Currently only used for `pretext-core`. |
| `esm` | `false` | `esm` | Files with `export` that are loaded via `import` from an inline `<script type="module">`.  Currently only `mathjax_startup.js`. |
| `script` | `false` | *(inferred)* | Stand-alone plain-JS files with no import/export.  Top-level declarations remain in global scope.  Used for all remaining targets. |

---

## Minification policy

| Build invocation | Minified? | Intended use |
|---|---|---|
| `npm run build` (all targets) | **No** | Updating the committed `js/dist/` files; readable git diffs |
| `npm run build -- -t <name>` (single target) | **Yes** | Building for deployment or testing locally |
| `npm run build -- -o <dir> -t <name>` | **Yes** | Building directly to a book's `_static/pretext/js/dist/` |

---

## Prerequisites

Node.js ≥ 18 and npm.  Before you build, from **this directory** (`script/jsbuilder/`), install the dependencies by running:

```sh
npm install
```

---

## Usage

Run all commands from **this directory** (`script/jsbuilder/`).

```sh
# Rebuild all dist files (updates js/dist/ for committing)
npm run build

# Watch source files and rebuild on change (useful during development)
npm run build -- -w

# List all target names
npm run build -- -l

# Build a single target (minified)
npm run build -- -t pretext-core

# Build a single target to a specific output directory (minified)
npm run build -- -t pretext-core -o /abs/path/to/_static/pretext/js/dist
```

---

## Adding a new JavaScript file

1. **Add the source file** to `js/` (or a subdirectory).
2. **Decide the build group:**
   - If it is always loaded alongside the existing core scripts, add an
     `import` to `js/src/pretext-core.js`.
   - If it uses `export` and is loaded via `<script type="module">`, add it
     as a new `esm` target in `jsbuilder.mjs`.
   - If it is a stand-alone conditional script, add it as a new `script`
     target in `jsbuilder.mjs`.
   - If it must be combined with another conditional file, create a new
     `js/src/my-bundle.js` entry point and add a `bundle` target.
3. **Add the target** to `getAllTargets()` in `jsbuilder.mjs`.
4. **Load the dist file** from the appropriate template in
   `xsl/pretext-html.xsl`, referencing `{$html.js.dir}/your-file.js`.
5. **Run `npm run build`** and commit the updated `js/dist/` files.

---

## Relationship to the CLI

The PreTeXt CLI (in the `pretext-cli` repository) copies the entire `js/`
tree into the build's `_static/pretext/js/` directory.  The XSL variable
`$html.js.dir` resolves to `_static/pretext/js/dist`, so the HTML output
always references files from `js/dist/`.

When the CLI runs a build it uses the pre-built dist files committed in this
repository.  A future CLI enhancement could optionally run the jsbuilder
(similar to how `build_theme` runs the cssbuilder for custom CSS themes).

---

## Relationship to Runestone

JavaScript that is part of the Runestone integration is **not** managed here.
Runestone's JS is loaded separately by `xsl/pretext-runestone.xsl` via the
`$rs-js` parameter.  The WeBWorK files in `js/pretext-webwork/` do contain
Runestone-aware conditional code, but they are PreTeXt-owned files and are
included here.
