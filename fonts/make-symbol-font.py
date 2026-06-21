#!/usr/bin/env python3
#
# Copyright 2026 Robert A. Beezer
#
# This file is part of PreTeXt.
#
# PreTeXt is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 or version 3 of the
# License (at your option).
#
# PreTeXt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.

"""
Regenerate the bundled symbol font  PreTeXtSymbols.otf  from GNU FreeFont's
FreeSerif.  See  README.md  in this directory for why this font is bundled
and how it is used; the short version follows.

The XSL-FO / Apache-FOP PDF route ("pdf-fo") sets text in Latin Modern, to
match the LaTeX route.  Latin Modern carries few non-letter glyphs, so FOP
is told to fall back to this companion face for any glyph the body font
lacks -- currency signs, primes, the geometric end-of-block marks, dingbats.
FreeSerif is the one open *serif* font that covers the whole set, but the
full file is ~2 MB and PDF/UA forbids subsetting a font as it is embedded,
so every PDF would carry the whole 2 MB.  Instead we ship this pre-subset
copy: only the symbol blocks, ~160 KB, identical coverage.

This is a *modified* version of GNU FreeFont (GPLv3-or-later WITH the GNU
font exception).  The font exception is re-stated in the output, as the
upstream license expressly permits, so that a document embedding the font
is not itself placed under the GPL.

Usage:    python3 make-symbol-font.py [FreeSerif.otf] [PreTeXtSymbols.otf]
Defaults: the Debian FreeSerif path, and  PreTeXtSymbols.otf  beside this
          script.  Requires the  fonttools  package -- a maintainer-only
          dependency, never needed to build a document.
"""

import os
import sys

from fontTools.ttLib import TTFont
from fontTools.subset import Subsetter, Options

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = sys.argv[1] if len(sys.argv) > 1 else "/usr/share/fonts/opentype/freefont/FreeSerif.otf"
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "PreTeXtSymbols.otf")

NEW_FAMILY = "PreTeXt Symbols"
PS_NAME = "PreTeXtSymbols-Regular"

# The symbol planes, kept *whole* and generously, so that any glyph the body
# font lacks is almost certainly already here -- we would far rather
# over-populate once than re-subset every time a new symbol turns up.  The
# single 0x2000-0x2BFF sweep is every block from General Punctuation through
# Miscellaneous Symbols and Arrows: punctuation (primes, swung dash, the
# visible-space OPEN BOX), currency, letterlike marks, number forms, arrows,
# mathematical operators, technical and control pictures, enclosed and
# geometric shapes (the end-marks), dingbats.  The remaining ranges add
# supplemental punctuation and the symbol blocks of the Supplementary
# Multilingual Plane (enclosed alphanumerics, alchemical, extended shapes,
# ...).  Letters and scripts are deliberately excluded -- the body font owns
# those -- and FreeSerif carries nothing outside these ranges we would want.
RANGES = [
    (0x2000, 0x2BFF),   # General Punctuation ... Miscellaneous Symbols and Arrows
    (0x2E00, 0x2E7F),   # Supplemental Punctuation
    (0x1F000, 0x1FAFF), # Supplementary Multilingual Plane symbol blocks
]
# Space and no-break space are not letters, so they fit the "symbols only"
# rule; they are kept so a fallback run that happens to include a space (a
# symbol with an adjacent space) sets it instead of reporting a missing glyph.
SPACES = [0x0020, 0x00A0]
unicodes = SPACES + [cp for lo, hi in RANGES for cp in range(lo, hi + 1)]

# The GNU font exception, re-stated for this modified (subset) version so it
# travels with the file -- the upstream exception explicitly allows a modifier
# to extend it.  This is what keeps a publisher's PDF out from under the GPL.
EXCEPTION = (
    "Subset of GNU FreeFont FreeSerif, redistributed under the GNU General "
    "Public License version 3 or later. As a special exception, embedding "
    "this font (or unaltered portions of it) in a document does not by itself "
    "cause the document to be covered by the GNU General Public License."
)

font = TTFont(SRC)
source_version = (font["name"].getDebugName(5) or "unknown").strip()

options = Options()
options.recalc_bounds = True
options.recalc_timestamp = False
options.drop_tables += ["FFTM"]   # FontForge timestamp table: not subsettable
options.name_IDs = ["*"]          # keep the name table, then rewrite identity below
options.glyph_names = True
subsetter = Subsetter(options=options)
subsetter.populate(unicodes=unicodes)
subsetter.subset(font)

# Re-stamp the identity so the file honestly presents itself as a modified
# subset (not "FreeSerif"), and so the font exception is recorded in it.
name = font["name"]
for name_id, value in [
    (1, NEW_FAMILY), (2, "Regular"),
    (4, NEW_FAMILY), (6, PS_NAME),
    (16, NEW_FAMILY), (17, "Regular"),
    (13, EXCEPTION),
]:
    name.setName(value, name_id, 3, 1, 0x409)   # Windows, Unicode BMP, en-US
    name.setName(value, name_id, 1, 0, 0)        # Macintosh, Roman, English

# The PostScript name lives inside the CFF table too; rename it there so an
# embedded copy reports as PreTeXt Symbols rather than FreeSerif.
if "CFF " in font:
    cff = font["CFF "].cff
    cff.fontNames = [PS_NAME]
    top = cff.topDictIndex[0]
    for attribute in ("FullName", "FamilyName"):
        if hasattr(top, attribute):
            setattr(top, attribute, NEW_FAMILY)

font.save(OUT)

retained = sum(1 for cp in unicodes if cp in font.getBestCmap())
print("source : {}  (FreeSerif {})".format(SRC, source_version))
print("output : {}  ({} symbol glyphs, {} bytes)".format(OUT, retained, os.path.getsize(OUT)))
