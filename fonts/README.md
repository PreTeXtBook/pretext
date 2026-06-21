# Fonts bundled with PreTeXt

The XSL-FO / Apache-FOP route to a PDF (the `pdf-fo` format of the
`pretext/pretext` script) embeds fonts directly, because a PDF must
carry its own fonts and PreTeXt's accessibility target (PDF/UA-1)
requires every glyph to come from an embedded, fully-embedded face.
Most of those faces are found on the host (Latin Modern from a TeX
installation, DejaVu, FontAwesome).  This directory holds the fonts
that PreTeXt itself ships, so the route does not depend on the host
having them.

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
  PDF — an author may license a book however they wish.  Permissive
  licenses (e.g. Bitstream Vera/DejaVu), the SIL Open Font License
  (which states outright that an embedding document is not subject to
  it), and the LaTeX Project Public License / GUST license (Latin
  Modern) all satisfy this.  A bare GPL font would *not*, because
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
