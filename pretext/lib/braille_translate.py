# ********************************************************************
# Copyright 2010-2026 Robert A. Beezer
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
# *********************************************************************

# The braille translation pass.  The "preprint" intermediate arrives
# from the XSL with print text organized into segments, where font
# changes are flat "run" elements carrying "@typeform" tokens, and
# mathematics is already braille (in "math" elements, from Speech
# Rule Engine).  This pass translates all print text into contracted
# UEB braille with liblouis, one call per contiguous stretch of text,
# so liblouis sees whole phrases and can choose correctly among
# symbol-, word-, and passage-level emphasis indicators, and so
# contractions are never severed at markup boundaries.
#
# The element skeleton survives: translated braille is written back
# into the text and tail slots surrounding the "math" islands, the
# "run" elements dissolve, and every attribute (identifiers for the
# table of contents, punctuation for Nemeth indicators) rides along
# untouched.  The renderer downstream knows only braille.

import lxml.etree as ET

# "common" holds the canonical __module_warning; we alias it here so the
# warning below reads the same as everywhere else
from . import common
__module_warning = common.__module_warning
# the shared PreTeXt logger (with .bug()/.fallback()/.fatal())
log = common.log

try:
    import louis
except ImportError:
    raise ImportError(__module_warning.format("louis"))

# The UEB Grade 2 table includes Grade 1 explicitly
_TABLES = ["en-ueb-g2.ctb"]

# Typeform bits, from the C header louis.h:
#     emph_1 = italic = 0x0001
#     emph_3 = bold = 0x0004
# "code" uses the transcriber-defined emphasis class "trans1" of the
# liblouis table, whose bit is assigned at run time
_TYPEFORM_BITS = {
    "italic": 0x0001,
    "bold": 0x0004,
    "code": louis.getTypeformForEmphClass(_TABLES, 'trans1'),
}


def _typeform_bits(typeform):
    """The composite liblouis typeform bits for space-separated tokens"""
    bits = 0
    for token in typeform.split():
        if token in _TYPEFORM_BITS:
            bits |= _TYPEFORM_BITS[token]
        else:
            log.bug('the typeform token "{}" is not recognized, and is ignored'.format(token))
    return bits


def _translate_chunk(chunk):
    """Translate one contiguous stretch of print text, in place.

    A chunk is a list of (element, slot, bits) triples, where slot is
    "text" or "tail", locating a string, and bits are the liblouis
    typeform bits in effect for that string.  The whole stretch goes
    through liblouis in one call, and the resulting braille is placed
    in the first slot; the remaining slots are emptied.
    """
    pieces = []
    typeforms = []
    for (element, slot, bits) in chunk:
        piece = getattr(element, slot) or ''
        pieces.append(piece)
        typeforms.extend([bits] * len(piece))
    whole = ''.join(pieces)
    if whole == '':
        return
    # liblouis behaves identically for all-zero bits and for no bits
    # at all, but no bits is the honest description of plain text
    if not any(typeforms):
        typeforms = None
    braille = louis.translateString(_TABLES, whole, typeforms, 0)
    # braille into the first slot, all other slots emptied
    (element, slot, _) = chunk[0]
    setattr(element, slot, braille)
    for (element, slot, _) in chunk[1:]:
        setattr(element, slot, None)


def _translate_segment(segment):
    """Translate the print text of one segment, in place.

    The text and tail slots of the segment and its children form an
    in-order sequence of strings ("text nodes belong to the element
    preceding them").  "math" elements are braille already and act as
    islands: the stretches of print text between them translate
    independently, each in a single liblouis call.
    """
    chunk = [(segment, "text", 0)]
    for child in segment:
        if child.tag == "math":
            # island: finish the stretch in progress, start anew
            _translate_chunk(chunk)
            chunk = [(child, "tail", 0)]
        elif child.tag == "run":
            chunk.append((child, "text", _typeform_bits(child.get("typeform", ""))))
            chunk.append((child, "tail", 0))
        else:
            # translate anything unexpected as plain print text,
            # rather than lose content or halt a conversion
            log.bug('unexpected element "{}" inside a segment; its content is treated as plain text'.format(child.tag))
            chunk.append((child, "text", 0))
            chunk.append((child, "tail", 0))
    _translate_chunk(chunk)
    # "run" elements have served their purpose: their content has
    # been absorbed (braille placed leftward, slots emptied), so
    # they dissolve without disturbing anything else
    for child in list(segment):
        if child.tag == "run":
            segment.remove(child)


def translate_document(xml_in, xml_out):
    """Translate a preprint file into its brailled counterpart.

    Every segment's print text becomes contracted UEB braille (BRF
    ASCII symbols); the structure, the attributes, and the "math"
    islands are undisturbed.  The root element is stamped with
    @translated for the renderer to verify.
    """
    huge_parser = ET.XMLParser(huge_tree=True)
    tree = ET.parse(xml_in, parser=huge_parser)
    root = tree.getroot()
    for segment in root.iter("segment"):
        # the segments of a Nemeth display block are lines of
        # mathematics, braille already, and are not print text
        in_nemeth_box = any(
            (ancestor.tag == "block") and (ancestor.get("box") == "nemeth")
            for ancestor in segment.iterancestors()
        )
        if not in_nemeth_box:
            _translate_segment(segment)
    root.set("translated", "yes")
    tree.write(xml_out, xml_declaration=True, encoding="UTF-8")
