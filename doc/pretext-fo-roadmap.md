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
3. Validate the `*.fo` file against the (locally amended) schema of
   FOP's FO subset, which catches in one pass the structural errors
   FOP would otherwise report fatally, one render at a time
   (see `~/mathbook/fo-schema/README.md`):

       xmllint --noout --schema ~/mathbook/fo-schema/fop-amended.xsd <the-fo>

   Then render with `-f pdf-fo` and inspect the PDF.
4. Validate PDF/UA-1 conformance (veraPDF is installed locally):

       ~/mathbook/verapdf/verapdf --flavour ua1 <the-pdf>

5. Commit granularly, one focused topic per commit.

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
* **Accessible by default.**  Every construct is born accessible:
  FOP runs with `accessibility` on and declares PDF/UA-1 (ISO
  14289-1) conformance, *hard-failing* on violations.  So new
  templates supply what the structure tree needs as they are
  written: `role` tags (headings), `fox:alt-text` (math speech,
  image `shortdescription`), `xml:lang`, embedded-font families
  only (never generic `serif`/`monospace`), and WCAG 2.1 details
  (contrast, no color-only signaling, language of parts).

## Phases

Phases one through six are **done** (divisions, paragraphs and
inlines, blocks with run-in headings, lists, the MathJax-SVG math
meld, images), as is the bulk of phase seven: tables, figures and
captions, `sidebyside`, footnotes, active links (`url`, `email`,
live `xref`), the verbatim family, exercises and projects and tasks,
specialized divisions, bibliographies, units, poetry, front and back
matter (titlepage, abstract, colophon, generated `solutions`), page
folios, PDF bookmarks, and more.  **The complete sample article
passes veraPDF validation of PDF/UA-1, with no exceptions.**

Worksheets and handouts are full printouts: their own pages,
authored `page` pagination, and elastic `@workspace` below
exercises (the request is the natural size; the space stretches to
fill out a page, in the manner of LaTeX's `\vfill`, or surrenders a
quarter when crowded; `space-before.conditionality="retain"` sends
space interrupted by a page break wholly onto the next page).

Publisher variables honored so far, beyond `$font-size` and
`$latex-sides`: `right-alignment` (flush/ragged), `print` (link
color, pageref default, sidedness default), `pageref` (page numbers
in cross-references via native `fo:page-number-citation` — no
second pass), `open-odd` (chapter-level divisions of a book;
`skip-pages` degrades to `add-blanks`), `worksheet/@formatted`,
`draft` (visible workspace hairlines), `insertions/@pagebreaks`
(forced page breaks by `@xml:id`), `fillin` text styles
(underline/box/shade), and the `common/watermark` (an SVG companion
file painted as the body-region background, so the structure tree
is undisturbed).

The generated lists are done, all on the abstract hooks of
`pretext-common.xsl`: the back-of-the-book index (`index-list`,
every `idx` dropping an invisible `fo:wrapper` anchor, locators as
live page-number citations — no `makeindex`, no second run), the
notation list (a table; sample usage, description, a link to the
enclosure), and `list-of` (scoped lists of blocks as live
cross-references).  Every `p` now carries an id, so a top-level
paragraph works as a link target (the notation list needs this).

The static forms of interactive content render: cardsort/matching
solutions (`premise`/`response`), server-rendered text blanks
(XHTML `input` becomes a fill-in rule of the same width), STACK's
`div`/`br` scraps, an `interactive`'s authored `static` image.
Also: literate programming (`fragment`, `fragref` with linked page
numbers), the DISCUSSION-LIKE commentary of open problems, `pf`,
`docinfo` renames (the harness had been blanking renamed type
names), and symbol-font fallbacks for glyphs the serif face lacks
(angle brackets, the equation-tag star, white square brackets —
FOP prints `#` for a missing glyph).

**Element coverage of the sample article is complete except for
the structured bibliography.**

What remains, roughly in order of value:

1. **Structured bibliography** — `biblio[@type='book'|'article']`
   with `author/name/given|family`, `collection-title`, `issued`;
   currently only `@type='raw'` renders.
2. **Refinements flagged in stylesheet comments** —
   `@header='vertical'` and `@row-headers` tables,
   `exercisegroup/@cols`, a keep for the proof tombstone, a
   two-column index (needs its own page-sequence).

Targets: full coverage of the sample article, then the sample book
(parts, Runestone static exercises).

## Saved for later

* Publisher-configurable fonts (a math-compatible face) in
  `fop.xconf`; page geometry intent (`top`/`bottom`/`margin` of
  formatted worksheets).
* `bottom-alignment` flush: FO expresses it only through stretchy
  space everywhere; ragged (the FO default) matches LaTeX's
  one-sided default anyway.
* `skip-pages` flavor of `open-odd`: a single `fo:page-sequence`
  cannot omit a page number; would need a page-sequence per
  chapter.
* Crop marks, front/back cover images.
* Accessibility refinements: a true PDF "artifact" mechanism for
  decorative images; PDF/UA-2 and MathML association are beyond
  FOP today.
* A way to pass `-X` extra XSL through to the FO conversion, once
  there is a use case.
