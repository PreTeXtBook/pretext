# Copilot Instructions for PreTeXt

## What is PreTeXt

PreTeXt is an XML-based authoring and publishing system for STEM textbooks and academic documents. A single XML source file is transformed into multiple output formats (HTML5, LaTeX/PDF, EPUB, Braille, Jupyter notebooks, reveal.js, etc.) via XSLT stylesheets. The Python CLI orchestrates the conversion pipeline, calling external tools (LaTeX, Asymptote, SageMath, Playwright, etc.) as needed.

## Repository Layout

| Directory | Role |
|-----------|------|
| `xsl/` | XSLT 1.0 stylesheets — the core conversion engine (~72K lines) |
| `pretext/` | Python CLI (`pretext/pretext`) and library (`pretext/lib/pretext.py`) |
| `css/` | SCSS/CSS theming system; `script/cssbuilder/` compiles it |
| `js/` | Client-side JavaScript for interactive HTML output |
| `schema/` | RELAX-NG schema; `pretext.xml` is the **only** file to edit directly |
| `examples/` | Sample PreTeXt documents (`minimal/`, `sample-article/`) |
| `doc/` | Author and Publisher guides |

## Build & Test Commands

### XSLT tests
```bash
cd xsl/tests
xsltproc pretext-text-utilities-test.xsl null.xml
# Success prints "Tests complete!"; failures print error details
```

### CSS build
```bash
cd script/cssbuilder
npm install        # one-time setup
npm run build      # compiles SCSS → css/dist/
```

### Python CLI (development use)
```bash
# Run conversions directly via the CLI entry point:
python3 pretext/pretext -c <component> -f <format> -s <source.xml> -p <pub.xml> -d <dest/>
# Example: build HTML
python3 pretext/pretext -f html -s source/main.ptx -p publication.xml -d output/
```

There is no automated test suite or CI pipeline. For Python, `pretext/module-test.py` is an informal integration example, not a test runner.

## Architecture: How a Conversion Works

1. **Assembly pass** — `xsl/pretext-assembly.xsl` pre-processes source XML into an "enhanced" document (resolves `xi:include`, computes IDs, etc.).
2. **Format pass** — a format-specific stylesheet (e.g., `xsl/pretext-html.xsl`) imports the assembly and common base, then templates match elements to produce output.
3. **Extraction passes** — `xsl/extract-*.xsl` stylesheets isolate embeddable content (LaTeX images, Asymptote diagrams, WeBWorK problems) for separate processing by external tools.
4. **Python orchestration** — `pretext/lib/pretext.py` calls `xsltproc` and external tools in the correct sequence, manages temp directories, and assembles the final output.

### XSL import hierarchy (example for HTML)
```
pretext-html.xsl
  ├── pretext-assembly.xsl
  ├── pretext-common.xsl        ← shared base templates
  ├── pretext-runestone.xsl
  └── html-symbols.xsl  (include, not import)
```
Format-specific sheets override base templates via XSLT import precedence.

## Key Conventions

### XSLT
- All stylesheets use **XSLT 1.0** with EXSL extensions (`exsl`, `str`, `dyn`).
- Internal namespace: `xmlns:pi="http://pretextbook.org/2020/pretext/internal"`.
- Shared entity references live in `entities.ent` and are included via DOCTYPE.
- Template names use `kebab-case`; modes are also `kebab-case` strings.
- `pretext-common.xsl` is the base library; format sheets extend it via `<xsl:import>`.
- `extract-*.xsl` files follow the convention of isolating one content type per file.

### Python
- **Never** use `from foo import *` or `from foo import bar`. Always `import foo` or `import foo as ALIAS` (stated explicitly in the module header).
- Infrequently-used libraries are imported **inside functions**, not at module level.
- All logging goes through `log = logging.getLogger('ptxlogger')`.
- Function names follow `verb_noun()` style; private helpers use `_verb_noun()`.
- The single library module is `pretext/lib/pretext.py` (~6300 lines); there is no split into sub-modules.

### Schema
- **Edit only `schema/pretext.xml`** (literate RELAX-NG compact notation). The `.rnc`, `.rng`, and `.xsd` files are generated via `schema/build.sh` using the `trang` tool.
- Schematron rules for author-facing validation are in `schema/pretext.sch` / `schema/pretext-schematron.xsl`.

## Development Workflow (from CONTRIBUTING.md)

- Discuss changes on the [pretext-dev Google Group](https://groups.google.com/forum/#!forum/pretext-dev) **before** writing code.
- Work on a topic branch; **rebase onto `master`** (never merge `master` into your branch).
- Keep commits minimal — maintainers reorganize history during integration.
- Submit via pull request; do not add commits or rebase after submission unless asked.
