<!--********************************************************************
Copyright (C) 2026  Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*****************************************************************-->

# Roadmap: Journal Styles and Bibliography Styles

PreTeXt has two independent mechanisms that both concern "publishing
an article in a particular journal":

* **Journal styles** (texstyles) — a publisher names a journal and the
  LaTeX conversion produces a document in that journal's house style.
  Working and in use.
* **CSL bibliographies** — a publisher names a Citation Style Language
  style file and references and citations are rendered by citeproc-py
  in that style.  Working, experimental, and opt-in.

Nothing connects them.  An author submitting to a journal chooses a
journal code for the LaTeX and must separately know, find, and name
the matching CSL style — with no guidance about which one is right,
and (today) no realistic way to obtain the file.

This roadmap describes joining the two so that naming a journal also
selects that journal's bibliography style.

## Current architecture

### Journal to LaTeX style

    /publication/common/journal/@name
        -> $journal-name                   publisher-variables.xsl
        -> get_journal_info()              pretext/lib/pretext.py
             (lookup in journals/journals.xml, resolving
              <method @texstyle @dependent @latex-style>)
        -> get_latex_style()               chooses top-level stylesheet
        -> stringparam journal.texstyle.file
        -> document() in xsl/latex/pretext-latex-texstyle.xsl,
           merged with any base file named by <extends>

Supporting machinery: `place_latex_package_files()` reads
`<required-files>` from the texstyle metadata and downloads each
`.cls`/`.sty` to `generated/latex-packages/`, caching between builds.

### CSL bibliography

    /publication/common/citation-stylesheet-language/@style
        -> $csl-style-file, $b-using-csl-styles
                                           publisher-variables.xsl
        -> references()                    pretext/lib/pretext.py
             citeproc-py renders every biblio entry and every
             citation, written to
             generated/references/csl-bibliography.xml with the
             style name stamped on the root as @csl-style-file
        -> pretext-assembly.xsl substitutes backmatter/references
           and biblio-targeting xref for the rendered forms

The substitution happens **at assembly**, before any format-specific
conversion, so a CSL style governs HTML, LaTeX, and FO alike.  The
stamped `@csl-style-file` is compared against the publisher variable
at conversion time; a mismatch produces a warning and a graceful
fallback to default PreTeXt bibliography handling.

## Gaps this roadmap closes

1. No journal-to-CSL mapping exists anywhere in `journals/`.
2. Texstyle metadata carries `<bibliography-style>spbasic</...>`
   (a BibTeX `.bst` name, in `journals/texstyles/ams.xml`) which no
   code reads.  Likewise `<bib-file/>`, and the
   `texstyle/bibliography` template in
   `xsl/latex/pretext-latex-texstyle.xsl` is a stub that warns
   "Bibliographies are not implemented correctly yet."
3. **Only `harvard1.csl` ships with citeproc-py.**  Any real journal
   style names a file the user does not have.  `citeproc-py-styles`
   is not a CLI dependency.  This, not the data model, is the
   substantive work.
4. `citation-stylesheet-language` is absent from
   `schema/publication-schema.rnc` (`journal` is present).
5. In the CLI, `references` generation is short-circuited to fire only
   on an explicit `pretext generate references`, and its asset hash
   covers `.//biblio` only — not citations, not the style choice.
6. The journal-to-texstyle resolver runs only on the LaTeX path.  A
   CSL style must be resolved for every format.

## Design decisions

**Where the style is declared.**  The texstyle metadata is the source
of truth, with a per-journal override in `journals.xml`.  A texstyle
file describes a journal family's house style, and the bibliography
style is part of that; it also sits naturally beside the existing
`<bibliography-style>`.  The override exists because several journals
share one texstyle (all the Elsevier ones) but need not share one
bibliography style.

**Precedence.**  A journal supplies a *default*.  An explicit
`citation-stylesheet-language/@style` in the publication file wins,
with an informational message naming the journal's default.  This
differs deliberately from `latex-style`, where the journal overrides
with a warning: an author preparing an arXiv preprint of a paper
destined for a journal has a legitimate reason to keep the journal's
LaTeX style while using a different bibliography style, and there is
no cost to allowing it.

**Obtaining the file.**  Download on demand from an `@href` on the
declaration, cached under `generated/`, exactly as `<required-files>`
already handles `.cls` files.  No new dependency, offline after the
first fetch, one mental model for "external resources a journal style
needs".  `citeproc.CitationStylesStyle` accepts a filesystem path
before it falls back to bundled names, so a downloaded file needs no
special handling.

## Data model

In texstyle metadata, alongside the existing entries:

```xml
<metadata>
    <code>ams</code>
    <name>AMS journals</name>
    <publisher>American Mathematical Society</publisher>
    <latex-engine command="pdflatex"/>
    <bibliography-style>spbasic</bibliography-style>
    <csl-style name="american-mathematical-society"
               href="https://raw.githubusercontent.com/citation-style-language/styles/master/american-mathematical-society.csl"/>
</metadata>
```

`@name` is the CSL repository identifier, without the `.csl` suffix,
matching the convention already documented for the publication file
entry.  `@href` is optional: with no `@href` the name is handed to
citeproc-py as-is, which still finds `harvard1` and anything supplied
by `citeproc-py-styles` if a user has installed it.

In `journals.xml`, an override on the existing `<method>`:

```xml
<journal>
  <code>exp-math</code>
  <name>Experimental Mathematics</name>
  <publisher>Taylor &amp; Francis</publisher>
  <method texstyle="taylor-francis"
          csl="taylor-and-francis-chicago-author-date"/>
</journal>
```

A `@csl` override names a style but cannot supply an `@href`; if a
journal needs a style file not reachable from its texstyle family,
that is a signal the journal deserves its own texstyle file or a
`<csl-style>` entry in a dependent.

### Inheritance

`include-base` in `xsl/latex/pretext-latex-texstyle.xsl` merges only
children of `texstyle`, replacing a base node wholesale when the
extending file has a node of the same name.  A dependent such as
`journals/texstyles/dependents/bull-amer-math-soc.xml` has its own
`<metadata>`, so it does **not** inherit the base file's
`<csl-style>` through that path.  The Python resolver must follow
`<extends>` itself:

    csl-style := journals.xml <method @csl>
              || texstyle <metadata><csl-style>
              || (follow <extends>) base texstyle <csl-style>
              || none

Only the first `<csl-style>` found is used; `@name` and `@href` travel
together and are never mixed across files.  A file declaring a
`<csl-style>` keeps it whole, even when it carries no `@href`.  A
single level of `<extends>` is followed, matching what `include-base`
does, so Python and XSL always agree about a family; a deeper chain
would need both to change together.

## Resolution

Extend `get_journal_info()` (`pretext/lib/pretext.py`) to include
`csl-style` and `csl-href`, reading the texstyle file and walking
`<extends>` as above.  Add a resolver with the precedence ladder:

1. If `citation-stylesheet-language/@style` is non-empty in the
   publication file, use it.  If a journal default also exists and
   differs, log at INFO naming both.
2. Otherwise, if the journal resolves to a CSL style, use it.
3. Otherwise, CSL processing stays off, exactly as today.

The resolved value reaches XSL as a stringparam.  Add

```xml
<citation-stylesheet-language>
    <pi:pub-attribute name="style" default="" freeform="yes"
                      stringparam="journal.csl.style"/>
</citation-stylesheet-language>
```

in `xsl/publisher-variables.xsl`.  `set-pubfile-variable` gives a
stringparam top precedence over the publication file, which is why
the ladder above must be evaluated in Python — it reads the
publication file's value from the publisher variable report and
folds it in before deciding what to inject.  One stringparam then
moves `$csl-style-file`, `$b-using-csl-styles`, `$csl-file`, and the
report that `references()` itself consults, all together.

**Chokepoint.**  Unlike `journal.texstyle.file`, this stringparam is
needed by every conversion.  Resolution belongs where a target's
stringparams are assembled in the CLI (`pretext/project/__init__.py`),
with `references()` in core also calling the resolver defensively so
that direct users of the core library and `pretext generate
references` agree with builds.

## Phases

### Phase 1 — data model and resolver

* `<csl-style>` in the five family texstyle files; `@csl` support in
  `journals.xml` where a journal diverges.
* `get_journal_info()` returns `csl-style`/`csl-href`, following
  `<extends>`.
* New resolver implementing the precedence ladder.
* Unit tests over `get_journal_info()` for: family style, dependent
  inheriting through `<extends>`, per-journal `@csl` override,
  journal with no CSL style at all, unknown journal code.  These
  belong in the CLI's `tests/`, since core has no Python test
  infrastructure; they can only run against a released core, so they
  are written after this lands rather than alongside it.

No build behavior changes yet — the resolver is not wired in.

### Phase 2 — style file acquisition

* `place_csl_style_file()` modelled on `place_latex_package_files()`:
  download `@href` to a cache (`generated/csl/<name>.csl`), reuse when
  present, return an absolute path.
* `references()` passes that path to `CitationStylesStyle` instead of
  a bare name; a bare name remains the fallback when no `@href` is
  known.
* Failure to download is a clear error naming the URL and the manual
  workaround (drop the file in the cache directory), not a silent
  fallback to a different bibliography style.
* Decide whether `pretext generate references` should be offline-safe
  in CI; the cache directory makes vendoring possible.

### Phase 3 — wiring

* `stringparam="journal.csl.style"` on the pub-attribute.
* Resolver called at the CLI stringparam chokepoint and inside
  `references()`.
* End-to-end check: a publication file naming only
  `<journal name="ams"/>` produces `generated/references/`
  `csl-bibliography.xml` stamped
  `@csl-style-file="american-mathematical-society"`, and both the HTML
  and PDF builds consume it without the mismatch warning firing.

### Phase 4 — references as a first-class asset

* Remove the debug short-circuit in `generate_assets()` so
  `references` generates like any other asset type.
* Widen `ASSET_TO_XPATH["references"]` beyond `.//biblio`: citations
  are rendered into the same file, so `xref` elements targeting
  `backmatter/references` belong in the hash.
* Hash the resolved CSL style name, following the precedent of the
  `qrcode` asset hashing the publication file's base URL.  Without
  this, switching journals leaves a stale `csl-bibliography.xml` and
  the build degrades to the assembly-time mismatch warning instead of
  simply regenerating.
* Generating references on demand requires assembly to survive a
  project whose references do not exist yet, which it did not: every
  pass that imports the assembly stylesheet evaluates its global
  variables, one of which opens the generated file, so any pass at all
  aborted.  XSLT 1.0 cannot test for a file, so Python says instead,
  through a `csl.file.missing` parameter, and silence keeps the old
  assumption that the file is there.  The flag has to be refreshed
  whenever the answer can have changed -- before the first assembly,
  and again once generation has run.
* The citation half of the substitution reached for a literal
  `gen/references/csl-bibliography.xml`, ignoring a publisher's choice
  of generated directory, and had no fallback for a missing or
  mismatched file.  Both now match the bibliography half, so citations
  and references always degrade together.
* The hash is taken from `source_element()`, which is assembled --
  but with `assembly.version-only`, which short-circuits every pass
  after version resolution.  The CSL substitution pass is among them,
  so the hashed tree holds the author's own `biblio` elements and
  there is no circularity to avoid.

### Phase 5 — LaTeX coherence

* Both `<bibliography-style>` and `<bib-file/>` are retired.  With CSL
  substitution happening at assembly, the LaTeX conversion receives
  fully rendered entries and needs no `.bst`; keeping the slots would
  only invite someone to wire them up, and the one value ever set
  (`spbasic`, a Springer style, on the AMS texstyle) was wrong anyway.
  A texstyle's `<bibliography/>` now says only *where* the reference
  list belongs.
* Replace the `texstyle/bibliography` warning stub with a real
  implementation emitting the reference list in the position the
  texstyle file dictates.
* Confirm numeric versus author-date citation styles both survive the
  LaTeX round trip; `references()` already distinguishes them via
  `style/info/category/@citation-format`.  Both do: a numeric style
  yields `[\hyperlink{biblio-lay}{1}]` against `\bibitem[1]{biblio-lay}`,
  an author-date style `(\hyperlink{biblio-lay}{Lay n.d.})` with the
  entries alphabetized by the style.

### Phase 6 — schema and documentation

* Add `citation-stylesheet-language` to
  `schema/publication-schema.rnc` and regenerate `.rng`.
* `journals-to-table.xsl` gains a bibliography-style column, so the
  guide's journal appendix shows which CSL style each journal uses.
  That stylesheet repeats the resolution `get_journal_info()` performs,
  which is acceptable only because `journals/build.sh` runs it by hand
  and no conversion ever does; the two must be kept in step, and a
  cross-check against the Python resolver is cheap to run.
* Guide: extend `common-journal` in
  `doc/guide/publisher/publication-file.xml` to state that a journal
  name also selects the bibliography style and how to override it;
  add a subsection for `citation-stylesheet-language` itself, which
  the guide does not currently document at all.

### Phase 7 — coverage

* A journal-flavored example under `examples/` with a real
  bibliography, built for both HTML and PDF.
* CLI tests: journal-only publication file, journal plus explicit
  override, journal whose texstyle has no CSL style.  These live in
  `tests/test_project.py` against the `journal-bibliography` fixture
  project, and the two that need core to resolve a style skip
  themselves until a core that can is the vendored one.

## Open questions

* **Style file licensing.**  CSL repository styles are CC BY-SA 3.0.
  Downloading at build time keeps them out of the distribution, which
  is the tidiest answer, but if a curated bundle is ever added to
  `journals/csl/` the attribution requirements need handling.
* **Upstream drift.**  An `@href` pinned to `master` in the CSL
  repository will silently change rendering over time.  Consider
  pinning to a tag or commit, at the cost of periodic updates.
* **Footnote styles.**  `references()` bails out on
  `style/@class="note"`.  Several journals genuinely use footnote
  citations; those journals cannot get a working `<csl-style>` until
  that limitation is lifted, and the resolver should say so clearly
  rather than failing obscurely.
* **Per-target styles.**  Nothing here allows one target to build for
  a journal and another for arXiv within the same project, beyond
  separate publication files.  That may be enough.
