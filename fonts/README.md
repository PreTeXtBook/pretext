# Fonts bundled with PreTeXt

The XSL-FO / Apache-FOP route to a PDF (the `pdf-fo` format of the
`pretext/pretext` script) embeds fonts directly, because a PDF must
carry its own fonts and PreTeXt's accessibility target (PDF/UA-1)
requires every glyph to come from a fully-embedded face.  **This
directory is the single source of those fonts**: every face the route
uses is bundled here, taken from its canonical upstream, so a build
depends on no host font installation.

At build time the `pdf-fo` route copies this directory into its scratch
working directory; `pretext/fop.xconf` then refers to each bundled face
by a path relative to that directory.

## What makes a font suitable to bundle

A font we ship in this repository, and embed in every reader's PDF, is
weighed against four criteria.

- **Coverage.**  The font must actually contain the glyphs PreTeXt
  needs it for.  A symbol companion, for instance, has to cover the
  currency signs, primes, geometric end-of-block marks, and dingbats
  that the Latin Modern body font omits.

- **License — ours, and the publisher's.**  Two separate questions.
  *Ours*: the license must permit us to redistribute the font in this
  repository, and (if we adapt it, see *Size* below) to modify it, on
  terms compatible with PreTeXt's own GPL.  *The publisher's*: a font
  embedded in an author's PDF must **not** impose any obligation on that
  PDF — an author may license a book however they wish.  The SIL
  Open Font License (which states outright that an embedding document
  is not subject to it — Inconsolata, Font Awesome, and STIX Two Text
  here) and the LaTeX Project Public License / GUST license (Latin
  Modern) both satisfy this.  A bare GPL font would *not*, because
  embedding copies the font program into the document; only a GPL font
  carrying the **font exception** (which explicitly exempts embedding
  documents) is acceptable.

- **Maturity.**  Prefer a font whose glyph set is stable and rarely
  revised, so a bundled copy does not drift from upstream and need
  constant refreshing.

- **Size.**  PDF/UA forbids subsetting a font as it is embedded (FOP's
  subset embedding writes an incomplete `CIDSet` that fails validation),
  so the *entire* bundled file lands in every PDF that uses even one of
  its glyphs.  Size is therefore a first-class concern.  When a font
  earns its place on coverage but is large because it also carries
  scripts we never draw from it, the remedy is to **subset the source
  ourselves**, once, to just the blocks we use, and bundle the small
  result.  A subset is a modified work, so this is only an option when
  the license permits modification and redistribution.

## Latin Modern — the body and code text

The text fonts come from the **GUST e-foundry** Latin Modern family
(<https://www.gust.org.pl/projects/e-foundry/latin-modern>), the OTF
release **2.007** (2026-03-31).  Latin Modern is the default of the
LaTeX route (`lmodern`), so the two PDF routes share a body typeface.

- **Roman** (`lmroman10-{regular,bold,italic,bolditalic}.otf`) is the
  body face.  A second optical design,
  `lmroman12-{regular,bold,italic}.otf`, is selected for a body
  `font-size` of 12pt or more; GUST ships no 12-point bold-italic, so
  that one cell borrows `lmroman10-bolditalic.otf`.  The 10-point Roman
  also answers the `serif` generic family.
- **Sans** (`lmsans10-{regular,bold,oblique,boldoblique}.otf`) answers
  the `sans-serif` generic that author SVG labels (Mermaid, MyOpenMath)
  request.
- **License.**  The GUST Font License (`LICENSE-LatinModern.txt`),
  legally equivalent to the LaTeX Project Public License; it permits
  redistribution and imposes nothing on a document that embeds the font.

## Inconsolata — the monospace face

`Inconsolata-Regular.otf` and `Inconsolata-Bold.otf` set code and
verbatim text, matching the LaTeX route's default (the `inconsolata`
package).  From **googlefonts/Inconsolata**
(<https://github.com/googlefonts/Inconsolata>), release **v3.000**.

- Its stock glyphs already give the slashed zero and upright quotes
  wanted for code.  FOP cannot turn OpenType features on at render time,
  so a font's *default* glyph is what reaches the page; Inconsolata's
  defaults are right, so no modification is needed.
- Inconsolata has a true bold but no italic, so `pretext/fop.xconf` maps
  the italic slots back to the upright faces.  It also answers the
  `monospace` generic family.
- **License.**  SIL Open Font License 1.1 (`LICENSE-Inconsolata.txt`).

## Font Awesome — the icon glyphs

`FontAwesome5Free-Solid-900.otf` (the classic `<icon>` glyphs) and
`FontAwesome5Brands-Regular-400.otf` (the Creative Commons and brand
marks) come from **FortAwesome/Font-Awesome**
(<https://github.com/FortAwesome/Font-Awesome>), release **5.15.4** —
the same version the LaTeX route uses, so icons match across the routes.

- **License.**  SIL Open Font License 1.1 (`LICENSE-FontAwesome.txt`).

## STIX Two Text — the broad text fallback

Latin Modern Roman, like its Computer Modern ancestor, omits a few
characters that occur in ordinary prose — most notably the **micro
sign** U+00B5 (the SI "micro" prefix, as in µm or µF).  The symbol
companion below cannot cover these: FOP falls back *per word*, so a
glyph sitting mid-word cannot be drawn from the symbol face while the
rest of the word keeps the body face.  `STIXTwoText-Regular.otf` is
named last on the document's font list, so FOP sets any whole word the
body font cannot (the unit µm is rendered entirely in STIX), restoring
coverage that DejaVu used to provide implicitly before it was dropped.

- **Source.**  STIX Two Text from the STIX Fonts project
  (<https://www.stixfonts.org/>; distributed as the `stix2-otf` package
  on CTAN), version 2.12.  A Times-like serif with broad Latin, Greek,
  and Cyrillic coverage, so it harmonizes reasonably with the body face
  in the rare word that needs it.  One regular face fills all four
  style/weight slots, as PreTeXt Symbols does.
- **License.**  SIL Open Font License 1.1 (`LICENSE-STIX.txt`).

## `PreTeXtSymbols.otf` — the symbol companion

`PreTeXtSymbols.otf` is the fallback face for the `pdf-fo` route.  FOP
is configured to consult it for any glyph the body font (Latin Modern)
lacks, and `xsl/pretext-fo.xsl` also names it explicitly for the
end-of-block marks and a handful of named symbols.

- **Source.**  A subset of **GNU FreeFont — FreeSerif**
  (<https://www.gnu.org/software/freefont/>), version `0412.2263`.
  FreeSerif is the one open *serif* font (so it matches the Latin Modern
  body) that carries the whole symbol set PreTeXt needs in a single
  face: the geometric end-marks `■ ◆ ▲`, currency signs including the
  Guaraní `₲`, primes, the maltese cross and six-pointed star, and the
  white square brackets.  It is also old and stable, last revised in
  2012.

- **License.**  GNU GPL, version 3 or later, **with the GNU font
  exception**.  The exception means embedding the font in a document
  does not place the document under the GPL — a publisher's book keeps
  whatever license its author chose.  This file is a *modified* (subset)
  version; the exception expressly allows a modifier to extend it, and
  the regeneration script re-states it in the font's name table, so the
  exception travels with the file.  As a GPL work it is fully compatible
  with PreTeXt's own license.

- **Coverage and size.**  The subset keeps whole *symbol* Unicode
  blocks — punctuation (including the visible-space OPEN BOX), currency,
  letterlike marks, number forms, arrows, mathematical operators,
  technical and control pictures, enclosed and geometric shapes (the
  end-marks), dingbats, and the symbol blocks of the Supplementary
  Multilingual Plane — about 1900 glyphs, 230 KB.  The full FreeSerif is
  roughly 2 MB; both render the PreTeXt symbol set identically, so the
  subset is what each PDF carries.  Entire blocks are kept on purpose,
  rather than the exact code points in use today, so a newly-used symbol
  almost always works without regenerating.  Base Latin letters are
  deliberately dropped: the body font supplies those, and this face is
  only ever consulted for a glyph the body font is missing.

- **Regeneration.**  Run

  ```
  python3 make-symbol-font.py [FreeSerif.otf] [PreTeXtSymbols.otf]
  ```

  (it needs the `fonttools` package — a maintainer-only dependency, not
  required to build a document).  Regenerate only when GNU FreeFont
  releases a newer FreeSerif, or in the rare event PreTeXt needs a
  symbol from a Unicode block outside the generous ranges listed at the
  top of the script.
