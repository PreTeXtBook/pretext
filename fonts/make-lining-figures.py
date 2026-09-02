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
Regenerate a bundled text face so that its *default* figures are lining.
Used for the Alegreya faces,  Alegreya-{Regular,Bold,Italic,BoldItalic}.otf ;
see  README.md  in this directory for why.  The short version follows.

Apache FOP cannot switch OpenType features on at render time, so the glyph
a font maps a character to by default is the glyph that reaches the page.
Alegreya, as released, maps the digits to oldstyle figures and offers the
lining set through its  lnum  feature.  PreTeXt documents mix prose with
numbered items, tables and mathematics, where lining figures are wanted, so
this script re-points the ten digits in the character map to the very
glyphs the font's own  lnum  feature substitutes, and marks the version
string.  Nothing else changes: outlines, metrics, kerning, features and
names are the upstream release's.

Alegreya's SIL Open Font License declares no Reserved Font Name, so this
modified copy may keep the family name.

Usage:    python3 make-lining-figures.py <upstream-face.otf> [...]
Output:   a file of the same name beside this script.  Requires the
          fonttools  package -- a maintainer-only dependency, never needed
          to build a document.
"""

import os
import sys

from fontTools.ttLib import TTFont

HERE = os.path.dirname(os.path.abspath(__file__))
DIGITS = range(0x0030, 0x003A)
VERSION_NOTE = "; lining figures by default (PreTeXt)"


def lining_substitutions(font):
    """The glyph-to-glyph map of every single-substitution lookup that
    the  lnum  feature reaches."""
    gsub = font["GSUB"].table
    mapping = {}
    for record in gsub.FeatureList.FeatureRecord:
        if record.FeatureTag != "lnum":
            continue
        for index in record.Feature.LookupListIndex:
            for subtable in gsub.LookupList.Lookup[index].SubTable:
                # an extension lookup wraps the real subtable
                if hasattr(subtable, "ExtSubTable"):
                    subtable = subtable.ExtSubTable
                if getattr(subtable, "mapping", None):
                    mapping.update(subtable.mapping)
    return mapping


for source in sys.argv[1:]:
    font = TTFont(source)
    lining = lining_substitutions(font)
    remapped = 0
    for table in font["cmap"].tables:
        for codepoint in DIGITS:
            glyph = table.cmap.get(codepoint)
            if glyph in lining:
                table.cmap[codepoint] = lining[glyph]
                remapped += 1
    if remapped == 0:
        sys.exit("{}: no  lnum  substitutions for the digits; nothing to do".format(source))
    name = font["name"]
    for record in name.names:
        if record.nameID == 5 and VERSION_NOTE not in record.toUnicode():
            record.string = record.toUnicode() + VERSION_NOTE
    output = os.path.join(HERE, os.path.basename(source))
    font.save(output)
    print("{} -> {}  ({} digit entries re-pointed, now {})".format(
        source, output, remapped, name.getDebugName(5)))
