#!/usr/bin/env python3
#
# Copyright (C) 2026  Robert A. Beezer
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
Regenerate the bundled icon font  material-symbols-outlined.woff2  (and
the list of its icons,  material-symbols-outlined.txt ) from Google's
variable Material Symbols Outlined font.  See  README.md  in this
directory for why this font is bundled and how it is used; the short
version follows.

HTML output draws its buttons and controls with the Material Symbols
Outlined icon font.  Loading it from Google Fonts fails when a reader is
offline, and every icon then shows as its name ("chevron_left").  So HTML
output carries its own copy.  Google's font has about 3,500 icons, in
many styles, and is 4 MB.  PreTeXt uses a few dozen icons, in one style
(optical size 24, weight 400, not filled, grade 0), so we ship a font
with just those, a few KB.

An icon is asked for in one of two ways: by its code point (the
"insert-symbol" template of the HTML conversion), or by its name, which
the font turns into the icon with a ligature (scripts, and "content" in
stylesheets).  So we search PreTeXt's own templates, scripts, and
stylesheets for icons asked for in these ways, add the icons of other
projects PreTeXt loads (EXTRA, below), and keep each icon with its code
points and its ligature.  Any other name would be drawn as plain text,
so run this script again whenever PreTeXt starts using a new icon.

This is a *modified* version of Material Symbols (Apache License 2.0, see
LICENSE-MaterialSymbols.txt): one style, and a subset of the icons.

Obtain the source font, at a recorded commit, from
  https://github.com/google/material-design-icons/tree/master/variablefont
  MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].woff2

Usage:    python3 make-material-symbols.py SOURCE.woff2
Output:   material-symbols-outlined.woff2  and  material-symbols-outlined.txt
          beside this script.  Requires the  fonttools  and  brotli
          packages -- a maintainer-only dependency, never needed to build a
          document.
"""

import glob
import os
import re
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT_FONT = os.path.join(HERE, "material-symbols-outlined.woff2")
OUT_LIST = os.path.join(HERE, "material-symbols-outlined.txt")

# The one style PreTeXt uses, matching the CSS rule for the
# .material-symbols-outlined class and the request once made
# to Google Fonts ("opsz,wght,FILL,GRAD@24,400,0,0")
AXES = {"opsz": 24, "wght": 400, "FILL": 0, "GRAD": 0}

# Icons asked for by name in code PreTeXt loads but does not keep.
# The Runestone Components: search the Runestone Services bundle
# in the "_static" directory of an HTML build for the class
# "material-symbols-outlined" to find these.  Some are not beside
# the class name: the user menu passes each icon's name to a
# function.  Runestone's own icon font, embedded in its stylesheet
# as "Runestone Material Symbols", has every icon Runestone draws.
EXTRA = ["bug_report", "check_circle", "error", "groups_3", "home", "info", "newsstand", "settings"]


def read(filename):
    with open(filename, encoding="utf-8", errors="replace") as f:
        return f.read()


def candidate_names():
    """Strings that may be icon names, searched for in PreTeXt's sources"""
    found = {}

    def note(name, filename):
        found.setdefault(name, set()).add(os.path.relpath(filename, ROOT))

    # templates: calls to "insert-symbol" (code points)
    call_pattern = r'<xsl:call-template name="insert-symbol"\s*>(.*?)</xsl:call-template>'
    param_pattern = r"<xsl:with-param name=\"name\"\s+select=\"'([a-z0-9_]+)'\""
    for filename in glob.glob(os.path.join(ROOT, "xsl", "**", "*.xsl"), recursive=True):
        for call in re.findall(call_pattern, read(filename), re.S):
            for name in re.findall(param_pattern, call):
                note(name, filename)
    # scripts: the content of an icon element, or text given to an element (names)
    element_pattern = r"material-symbols-outlined[^>]*>\s*([a-z0-9_]+)\s*<"
    text_pattern = r"(?:textContent|innerText)\s*=\s*[\"'`]([a-z0-9_]+)[\"'`]"
    for filename in glob.glob(os.path.join(ROOT, "js", "**", "*.js"), recursive=True):
        if "node_modules" in filename:
            continue
        text = read(filename)
        for name in re.findall(element_pattern, text) + re.findall(text_pattern, text):
            note(name, filename)
    # stylesheets: generated content (names)
    content_pattern = r"content\s*:\s*[\"']([a-z0-9_]+)[\"']"
    for filename in glob.glob(os.path.join(ROOT, "css", "**", "*.*css"), recursive=True):
        if os.sep + "dist" + os.sep in filename:
            continue
        for name in re.findall(content_pattern, read(filename)):
            note(name, filename)
    return found


def symbol_table():
    """Code points the "insert-symbol" template uses, keyed by name"""
    table = read(os.path.join(ROOT, "xsl", "html-symbols.xsl"))
    entries = re.findall(r'<symbolinfo name="([^"]+)" entity="([0-9a-f]+)"', table)
    return {name: int(entity, 16) for name, entity in entries}


def ligature_subtables(font):
    """The ligature substitutions of the font"""
    for lookup in font["GSUB"].table.LookupList.Lookup:
        for subtable in lookup.SubTable:
            subtable = getattr(subtable, "ExtSubTable", subtable)
            if hasattr(subtable, "ligatures"):
                yield subtable


def icon_glyphs(font):
    """Glyph drawn for each icon name, via the font's ligatures"""
    cmap = font.getBestCmap()
    letter = {cmap[cp]: chr(cp) for cp in cmap if cp < 128}
    glyphs = {}
    for subtable in ligature_subtables(font):
        for first, ligs in subtable.ligatures.items():
            for lig in ligs:
                components = [first] + list(lig.Component)
                if all(c in letter for c in components):
                    glyphs["".join(letter[c] for c in components)] = lig.LigGlyph
    return glyphs


if len(sys.argv) != 2:
    sys.exit(__doc__)

# keep the source timestamp, so regenerating from the same source is reproducible
font = TTFont(sys.argv[1], recalcTimestamp=False)
font = instancer.instantiateVariableFont(font, AXES)
glyph_of = icon_glyphs(font)
cmap = font.getBestCmap()

# keep the candidates which are icons (others are
# just words in the sources), and the extras
candidates = candidate_names()
missing = [name for name in EXTRA if name not in glyph_of]
if missing:
    sys.exit("not icons in this font: {}".format(", ".join(missing)))
names = sorted({name for name in candidates if name in glyph_of} | set(EXTRA))
keep = {glyph_of[name] for name in names}

# the code point used by "insert-symbol" must draw the same icon
table = symbol_table()
for name in names:
    if name in table and cmap.get(table[name]) != glyph_of[name]:
        sys.exit("code point {:x} for {} (xsl/html-symbols.xsl) is not that icon in this font".format(table[name], name))

# only the ligatures for the kept icons, else every icon would be
# kept, since every icon's name is spelled with the letters we keep
for subtable in ligature_subtables(font):
    pruned = {}
    for first, ligs in subtable.ligatures.items():
        ligs = [lig for lig in ligs if lig.LigGlyph in keep]
        if ligs:
            pruned[first] = ligs
    subtable.ligatures = pruned

# letters, digits, underscore (to spell names), and every code point of a kept icon
unicodes = [ord(c) for c in "abcdefghijklmnopqrstuvwxyz0123456789_"]
unicodes += [cp for cp, glyph in cmap.items() if glyph in keep]
options = subset.Options()
options.layout_features = ["*"]
options.name_IDs = ["*"]
options.notdef_outline = True
subsetter = subset.Subsetter(options)
subsetter.populate(unicodes=unicodes, glyphs=sorted(keep))
subsetter.subset(font)
font.flavor = "woff2"
font.save(OUT_FONT)

with open(OUT_LIST, "w", encoding="utf-8") as f:
    f.write("\n".join(names) + "\n")
for name in names:
    print("  {:22} {}".format(name, ", ".join(sorted(candidates.get(name, {"EXTRA"})))))
print("wrote {} ({} icons, {} bytes)".format(OUT_FONT, len(names), os.path.getsize(OUT_FONT)))
