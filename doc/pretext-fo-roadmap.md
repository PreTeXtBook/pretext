# Roadmap: PreTeXt to PDF via XSL-FO (LaTeX-free)

This documents the long-running development of `xsl/pretext-fo.xsl`, a
conversion from PreTeXt source to XSL Formatting Objects (XSL-FO),
rendered as a PDF by Apache FOP.  This is a **LaTeX-free** route to a
PDF: the motivation is to escape LaTeX idiosyncrasies, render
mathematics with MathJax (as SVG images, equally beautiful), and gain
better Unicode, multi-font, and multi-script support.  The conversion
is experimental and incomplete; this file records the architecture,
the development workflow, and the phased plan.

## Architecture

Source flows through the pipeline

    PreTeXt source -> (pretext-fo.xsl) -> *.fo -> (Apache FOP) -> *.pdf

with the pieces:

* `xsl/pretext-fo.xsl` — the conversion.  XSLT 1.0, importing the
  standard groundwork: `publisher-variables.xsl`,
  `pretext-assembly.xsl`, `pretext-common.xsl`.
* `pretext/fop.xconf` — FOP configuration (fonts, resolutions).
* `pretext/lib/pretext.py` — `fo()` produces the `*.fo` file;
  `pdf_fo()` continues through FOP to a PDF.
* `pretext/pretext` — formats `-f fo` (intermediate only, runs
  without FOP installed) and `-f pdf-fo` (full pipeline).

Mathematics will be produced exactly as the EPUB conversion does:
`mathjax_latex(..., 'svg')` in `pretext/lib/pretext.py` renders every
math element to SVG, collected in a `pi:math-representations` file,
which is passed to the stylesheet as the `$mathfile` string parameter.
The stylesheet melds each SVG into the page inside an
`fo:instream-foreign-object`.  Until that step, math elements render
as boxed placeholders showing the authored LaTeX.

## Development workflow (the coverage harness)

The stylesheet ends with a lowest-priority `match="*"` template that
reports any element lacking an implementation and recurses through
element children (dropping interior text, so output is always legal
XSL-FO).  Every unimplemented element in a build is reported on the
console as `PTX:FO-TODO: <element-name>`.  The loop:

1. Build (see below) and collect a counted summary of what remains:

       /home/rob/.claude/pretext-venv/bin/python3 pretext/pretext \
           -v -c doc -f fo -p examples/pdf-fo-development/publication.xml \
           -d /tmp/fo examples/pdf-fo-development/pdf-fo-development.xml \
           2>&1 | grep 'PTX:FO-TODO' | sort | uniq -c | sort -rn

2. Pick the most consequential element, implement it with a template
   in `pretext-fo.xsl` (which removes it from the report).
3. Verify the `*.fo` file is well-formed (`xmllint --noout`), then
   render with `-f pdf-fo` and inspect the PDF.
4. Commit granularly, one focused topic per commit.

Because the harness has higher import precedence than everything
imported, an element only leaves the report when *this* stylesheet
handles it — the report is the authoritative to-do list.

## Conventions

* Reuse, do not reinvent: `pretext-common.xsl` supplies structure,
  numbering, cross-reference, and localization machinery; the FO
  conversion should override *output* templates only.
  `pretext-assembly.xsl` supplies the assembled tree (`$document-root`)
  and identifiers.
* Honor publisher variables from the `<latex>` element of a
  publication file when they map cleanly (`$font-size`,
  `$latex-sides`, paper size).  The raw `$latex-page-geometry` string
  is LaTeX-specific: map the *intent*, never parse the string.
* Test documents: `examples/pdf-fo-development/` now, growing toward the
  sample article (`examples/sample-article/`), and eventually the
  sample book.
* Build only with the repository script, `pretext/pretext`
  (`-c doc -f fo` or `-c doc -f pdf-fo`); never pretext-cli, never
  raw `xsltproc`.

## Phases

1. **Traditional divisions** — `book`, `article`, `chapter`,
   `section`, `subsection`, `subsubsection`: titled headings, then
   recurse.  Skip specialized divisions and front/back matter for now.
2. **Paragraphs** — complete `p` handling: interruptions by displayed
   items, and the rich inline markup (`em`, `term`, `c`, `q`, foreign,
   quotes, dashes, ...).
3. **Basic blocks** — theorem-like, remark-like, example-like:
   titled, numbered blocks via the machinery of `pretext-common.xsl`.
4. **Lists** — `ol`, `ul`, `dl` as `fo:list-block`.
5. **Mathematics** — wire the MathJax-SVG meld (`$mathfile`,
   `fo:instream-foreign-object`), replacing the placeholders;
   model is `epub()` and `pretext-epub.xsl`.
6. **Images** — `fo:external-graphic`, again on the EPUB model.
7. **The hard parts, later** — `sidebyside`, tables, figures and
   captions, front and back matter, specialized divisions, footnotes,
   index, Runestone static versions.

Targets: full coverage of the sample article, then the sample book
(parts, Runestone static exercises).

## Saved for later

* Explicit font embedding in `fop.xconf`, including a math-compatible
  font, replacing reliance on operating-system font auto-detection.
* Page headers and footers (`fo:static-content`), page numbers.
* Two-page-spread refinements: running heads, blank verso pages at
  chapter boundaries (`$latex-open-odd`).
* Cross-references as live PDF links (`fo:basic-link`).
* PDF bookmarks (`fo:bookmark-tree`) and document metadata.
* Accessibility: tagged PDF (FOP's PDF/UA support).
* A way to pass `-X` extra XSL through to the FO conversion, once
  there is a use case.
