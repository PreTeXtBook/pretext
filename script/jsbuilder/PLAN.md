# JS Modernization Plan

Modernize how PreTeXt provides JavaScript to the HTML it builds — mirroring
the existing CSS build system (`script/cssbuilder/` → `css/dist/`).

## Goals

- Convert JS source files to ES modules (import/export)
- Remove jQuery dependency (replace with vanilla DOM APIs)
- Bundle with esbuild into `js/dist/` (pre-built files committed to repo)
- Update XSL and Python to reference the new bundles
- Ship pre-built dist so users without Node can still build

## Bundle Targets

| Bundle | Source files | When loaded | Output |
|--------|-------------|-------------|--------|
| `pretext-core` | `pretext.js`, `pretext_add_on.js`, `knowl.js`, `lti_iframe_resizer.js` | Always | `js/dist/pretext-core.js` |
| `pretext-search` | `pretext_search.js`, `ptx_search.js` | `$has-native-search` only | `js/dist/pretext-search.js` |

## Out of Scope

These are left untouched:

- `js/pretext-webwork/` — versioned, complex server integration
- `js/pretext-stack/` — specialized server integration
- `js/diagcess/` — already an npm-bundled package
- `js/mathjaxknowl3.js` — loaded dynamically by MathJax via
  `"paths": {"pretext": "_static/pretext/js"}`; must stay a standalone file

## Final Directory Structure

```
js/
├── pretext.js               ← ES module source
├── pretext_add_on.js        ← ES module source
├── knowl.js                 ← ES module source
├── lti_iframe_resizer.js    ← ES module source
├── pretext_search.js        ← ES module source
├── ptx_search.js            ← ES module source
├── mathjaxknowl3.js         ← unchanged (MathJax extension)
├── pretext-webwork/         ← unchanged
├── pretext-stack/           ← unchanged
├── diagcess/                ← unchanged
└── dist/
    ├── pretext-core.js      ← built bundle (committed)
    ├── pretext-core.js.map
    ├── pretext-search.js    ← built bundle (committed)
    └── pretext-search.js.map

script/jsbuilder/            ← new (this directory)
├── package.json
├── jsbuilder.mjs
├── README.md
└── PLAN.md                  ← this file
```

`js/jquery.min.js` is deleted once jQuery is removed from all source files.

## jQuery → Vanilla DOM Cheatsheet

| jQuery | Vanilla |
|--------|---------|
| `$(fn)` / `$(document).ready(fn)` | `document.addEventListener('DOMContentLoaded', fn)` |
| `$('.sel')` | `document.querySelectorAll('.sel')` |
| `$(el)` wrapping | work directly on `el` |
| `$el.addClass/removeClass/toggleClass` | `el.classList.add/remove/toggle` |
| `$el.on/off` | `el.addEventListener/removeEventListener` |
| `$el.attr(k, v)` / `$el.prop` | `el.setAttribute(k, v)` / `el.getAttribute(k)` |
| `$el.find('.sel')` | `el.querySelectorAll('.sel')` |
| `$el.closest('.sel')` | `el.closest('.sel')` (native) |
| `$el.html(s)` | `el.innerHTML = s` |
| `$el.text(s)` | `el.textContent = s` |
| `$el.show()` / `$el.hide()` | `el.style.display = ''` / `'none'` |
| `$el.slideUp()` / `slideDown()` | CSS `max-height` transition or Web Animations API |
| `$el.append(child)` | `el.append(child)` (native) |
| `$el.prepend(child)` | `el.prepend(child)` (native)  |
| `$el.remove()` | `el.remove()` (native) |
| `$.ajax(...)` | `fetch(...)` |
| `$el.trigger('click')` | `el.dispatchEvent(new Event('click'))` |
| `$el.data(k, v)` | `el.dataset.k = v` |

## Tasks (in order)

### Phase 1 — Build infrastructure
- [ ] Create `script/jsbuilder/package.json` (esbuild dep, build/watch scripts)
- [ ] Create `script/jsbuilder/jsbuilder.mjs` (two entry points, output to `js/dist/`)
- [ ] Create `script/jsbuilder/README.md`

### Phase 2 — ES module conversion + jQuery removal
Each file: add `import`/`export`, remove jQuery, replace with vanilla DOM.

- [ ] `js/pretext.js` (261 lines — TOC, sidebar, hash nav)
- [ ] `js/knowl.js` (338 lines — slide animations → CSS transitions)
- [ ] `js/lti_iframe_resizer.js` (54 lines — likely minimal jQuery)
- [ ] `js/pretext_search.js` (315 lines) + `js/ptx_search.js` (112 lines)
- [ ] `js/pretext_add_on.js` (1,339 lines — largest; image magnify, permalink, GeoGebra)

### Phase 3 — Bundle entry points
- [ ] `js/pretext-core-entry.js` — imports + inits core modules
- [ ] `js/pretext-search-entry.js` — imports + inits search modules

### Phase 4 — Build and commit dist
- [ ] Run `npm run build` in `script/jsbuilder/`
- [ ] Commit `js/dist/` pre-built files
- [ ] Delete `js/jquery.min.js`

### Phase 5 — XSL update (`xsl/pretext-html.xsl`)
- [ ] `pretext-js` template: replace 3 `<script>` tags → 1 loading `dist/pretext-core.js`
- [ ] `native-search-box-js` template: load `dist/pretext-search.js` instead
- [ ] Remove `lti_iframe_resizer.js` standalone tag (now in core bundle)
- [ ] Keep MathJax loader path `"pretext": "_static/pretext/js"` unchanged

### Phase 6 — Python update (`pretext/lib/pretext.py`)
- [ ] Ensure JS file copy to `_static/pretext/js/` includes `dist/` subdirectory
- [ ] Verify `mathjaxknowl3.js`, `pretext-webwork/`, `pretext-stack/`, `diagcess/` still copied

## Notes

- `ptx_search.js` may be mergeable into `pretext_search.js` — evaluate during conversion
- The `pretext_add_on.js?x=1` cache-buster query string can be dropped with named bundles
- The `$b-debug-react` XSL branch in `pretext-js` template is unrelated — leave untouched
- `script/jsbuilder/node_modules` should be in `.gitignore`
