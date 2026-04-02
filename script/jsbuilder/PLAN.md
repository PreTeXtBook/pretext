# JS Modernization Plan

Modernize how PreTeXt provides JavaScript to the HTML it builds — mirroring
the existing CSS build system (`script/cssbuilder/` → `css/dist/`).

## Goals

- Break the monolithic `pretext_add_on.js` into focused, maintainable modules
- Convert all JS source files to ES modules (import/export)
- Remove jQuery dependency (only `pretext_add_on.js` still uses it — ~35 calls)
- Bundle with esbuild into `js/dist/` (pre-built files committed to repo)
- Update XSL and Python to reference the new bundles
- Ship pre-built dist so users without Node can still build
- Flag suspected dead code for future removal

## Current State (validated April 2026)

**jQuery status by file:**
| File | Lines | jQuery? | Notes |
|------|-------|---------|-------|
| `pretext.js` | 227 | ✅ Clean | Vanilla DOM already |
| `knowl.js` | 286 | ✅ Clean | Vanilla DOM already |
| `lti_iframe_resizer.js` | 50 | ✅ Clean | Vanilla DOM already |
| `pretext_search.js` | 296 | ✅ Clean | Vanilla DOM already |
| `ptx_search.js` | 104 | ✅ Clean | ⚠️ **Dead code** — never loaded in HTML output |
| `pretext_add_on.js` | 1,234 | ❌ ~35 calls | Only file needing jQuery removal |

**Dead / broken code identified:**
| Code | Location | Status | Reason |
|------|----------|--------|--------|
| `ptx_search.js` | entire file | **Dead** | Never loaded in HTML; `pretext_search.js` handles all search |
| `knowl_focus_stack` ESC handler | `pretext_add_on.js:366-374` | **Broken** | References globals that don't exist — would throw `ReferenceError` |
| Video magnification | `pretext_add_on.js:192-259` | **Dead** | Selector `body iframeXXXX` intentionally matches nothing |
| ENTER/ESC switch fallthrough | `pretext_add_on.js:353-358` | **Bug** | Case 13 (ENTER) has no `break`, falls through to case 27 (ESC) |
| Auto-ID generation | `pretext_add_on.js:142-190` | **Suspicious** | Heavy console.log spam; unclear if output uses generated IDs |

**Cross-file dependencies:**
- `pretext_add_on.js` → `knowl.js`: references `knowl_focus_stack` (broken — var doesn't exist)
- `pretext_add_on.js` → `MathJax`: calls `MathJax.typesetPromise()` (external lib)
- `pretext_add_on.js` → `GeoGebra`: dynamically injects GeoGebra script
- `pretext_search.js` → `lunr`: uses `ptx_lunr_idx` and `ptx_lunr_docs` globals from generated index
- All files are plain scripts with no `import`/`export`; rely on global scope

## Bundle Targets

| Bundle | Source modules | When loaded | Output |
|--------|--------------|-------------|--------|
| `pretext-core` | `js/src/` modules + `pretext.js`, `knowl.js`, `lti_iframe_resizer.js` | Always | `js/dist/pretext-core.js` |
| `pretext-search` | `pretext_search.js` | `$has-native-search` only | `js/dist/pretext-search.js` |

## Out of Scope

These are left untouched:

- `js/pretext-webwork/` — versioned, complex server integration
- `js/pretext-stack/` — specialized server integration
- `js/diagcess/` — already an npm-bundled package
- `js/mathjaxknowl3.js` — loaded dynamically by MathJax via
  `"paths": {"pretext": "_static/pretext/js"}`; must stay a standalone file

## Module Structure

`pretext_add_on.js` (1,234 lines) is broken into focused modules under `js/src/`:

```
js/
├── src/                          ← NEW: ES module sources
│   ├── permalink.js              ← permalink copy-to-clipboard (lines 44–116)
│   ├── image-magnify.js          ← image popup magnification (lines 119–140)
│   ├── geogebra.js               ← GeoGebra calculator integration (lines 291–344)
│   ├── keyboard-nav.js           ← ESC/ENTER key handlers (lines 347–408)
│   ├── print-preview/            ← worksheet/handout print system (~565 lines)
│   │   ├── index.js              ← init + controls (lines 1018–1178)
│   │   ├── pages.js              ← page creation & adjustment (lines 459–590)
│   │   ├── headers-footers.js    ← header/footer management (lines 593–661)
│   │   ├── workspace.js          ← workspace height adjustment (lines 666–730, 867–909)
│   │   ├── page-breaks.js        ← DP page-break algorithm (lines 788–834)
│   │   ├── geometry.js           ← page geometry CSS + unit conversion (lines 837–865, 998–1016)
│   │   ├── paper-size.js         ← paper size detection + geolocation (lines 911–944)
│   │   ├── section-swap.js       ← printout section loading (lines 947–975)
│   │   └── solutions.js          ← details → div rewriting (lines 977–995)
│   ├── theme.js                  ← dark/light mode management (lines 1183–1248)
│   ├── embed.js                  ← embed code + share button + embed mode (lines 1250–1310)
│   ├── code-copy.js              ← code block copy button (lines 1312–1339)
│   └── deprecated/               ← flagged for future removal
│       ├── video-magnify.js      ← ⚠️ DEAD: selector `iframeXXXX` matches nothing
│       ├── auto-id.js            ← ⚠️ SUSPICIOUS: heavy console spam, unclear utility
│       └── scrollbar-width.js    ← utility only used by GeoGebra; may be replaceable
├── pretext.js                    ← ES module (already jQuery-free)
├── knowl.js                      ← ES module (already jQuery-free)
├── lti_iframe_resizer.js         ← ES module (already jQuery-free)
├── pretext_search.js             ← ES module (already jQuery-free)
├── ptx_search.js                 ← ⚠️ DEAD: kept but not bundled
├── mathjaxknowl3.js              ← unchanged (MathJax extension)
├── pretext-webwork/              ← unchanged
├── pretext-stack/                ← unchanged
├── diagcess/                     ← unchanged
└── dist/
    ├── pretext-core.js           ← built bundle (committed)
    ├── pretext-core.js.map
    ├── pretext-search.js         ← built bundle (committed)
    └── pretext-search.js.map

script/jsbuilder/                 ← new (this directory)
├── package.json
├── jsbuilder.mjs
├── README.md
└── PLAN.md                       ← this file
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

### Phase 1 — Build infrastructure ✅
- [x] Create `script/jsbuilder/package.json` (esbuild dep, build/watch scripts)
- [x] Create `script/jsbuilder/jsbuilder.mjs` (entry points, output to `js/dist/`)
- [x] Create `script/jsbuilder/README.md`

### Phase 2 — Modularize `pretext_add_on.js` ✅
Break the monolith into `js/src/` modules. Remove jQuery (~35 calls, concentrated
in image-magnify, auto-id, video-magnify, GeoGebra, and keyboard-nav sections).
Fix known bugs (ENTER/ESC fallthrough, broken `knowl_focus_stack` reference).

- [x] Create `js/src/permalink.js`
- [x] Create `js/src/image-magnify.js` (remove jQuery)
- [x] Create `js/src/geogebra.js` (remove jQuery — heaviest: ~9 calls)
- [x] Create `js/src/keyboard-nav.js` (remove jQuery, fix ESC/ENTER bug, fix broken knowl_focus_stack ref)
- [x] Create `js/src/print-preview/` (9 sub-modules — already jQuery-free)
- [x] Create `js/src/theme.js`
- [x] Create `js/src/embed.js`
- [x] Create `js/src/code-copy.js`
- [x] Create `js/src/deprecated/video-magnify.js` (flagged dead)
- [x] Create `js/src/deprecated/auto-id.js` (flagged suspicious, remove jQuery)
- [x] Create `js/src/deprecated/scrollbar-width.js`

### Phase 3 — Convert existing standalone files to ES modules ✅
Created ES module versions in `js/src/` (originals left intact for backward compat).

- [x] `js/src/toc.js` (from `js/pretext.js` — TOC, sidebar, hash nav)
- [x] `js/src/knowl.js` (from `js/knowl.js` — knowl open/close)
- [x] `js/src/lti-iframe-resizer.js` (from `js/lti_iframe_resizer.js` — LTI message handler)
- [x] `js/src/search.js` (from `js/pretext_search.js` — search UI)

### Phase 4 — Bundle entry points + build ✅
- [x] Create `js/src/pretext-core-entry.js` — imports + inits all core modules
- [x] Create `js/src/pretext-search-entry.js` — imports + inits search
- [x] Run `npm run build` in `script/jsbuilder/`
- [x] Commit `js/dist/` pre-built files
- [x] Delete `js/jquery.min.js`

### Phase 5 — XSL update (`xsl/pretext-html.xsl`) ✅
- [x] `pretext-js` template: replace 3 `<script>` tags → 1 loading `dist/pretext-core.js`
- [x] Knowl template: remove standalone `knowl.js` tag (now in core bundle)
- [x] LTI template: remove standalone `lti_iframe_resizer.js` tag (now in core bundle)
- [x] `native-search-box-js` template: load `dist/pretext-search.js` instead
- [x] Keep MathJax loader path `"pretext": "_static/pretext/js"` unchanged
- [x] The `$b-debug-react` XSL branch is unrelated — left untouched

### Phase 6 — Python update (`pretext/lib/pretext.py`) ✅
- [x] `copy_html_js()`: exclude `js/src/` from deployed copy via `shutil.ignore_patterns`
- [x] `js/dist/` included automatically (copytree copies everything not ignored)
- [x] `mathjaxknowl3.js`, `pretext-webwork/`, `pretext-stack/`, `diagcess/` still copied

## Notes

- **5 of 6 files are already jQuery-free.** Phase 2 is really about modularizing
  and de-jQuery-ing the one remaining file (`pretext_add_on.js`).
- `ptx_search.js` is dead code (never loaded in HTML output). Kept in repo but
  not included in any bundle.
- The `pretext_add_on.js?x=1` cache-buster query string is dropped with named bundles.
- `script/jsbuilder/node_modules` is already covered by `**/**/node_modules/` in `.gitignore`.
- `pretext_search.js` expects `ptx_lunr_idx` and `ptx_lunr_docs` as globals injected by
  the generated `lunr-pretext-search-index.js` — the bundle must not try to resolve these.
- `MathJax` and `ggbApp` are external globals — esbuild config should mark them as external.
- The old theme (CDN-hosted at `pretextbook.org/js/`) loads different JS paths than the new
  theme (local `_static/pretext/js/`). The XSL update should handle both paths.
- The `copy_html_js()` Python function copies the entire `js/` dir via `shutil.copytree`,
  so `js/dist/` will be included automatically. Consider excluding `js/src/` from the copy
  to keep deployed output clean.
