# ********************************************************************
# Copyright 2010-2020 Robert A. Beezer
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

# The braille renderer: the second of two passes.  The first pass
# (braille_translate.py) made contracted UEB braille of all print
# text, so this module knows nothing of translation; it knows cells,
# lines, and pages.  It works in two stages:
#
#   * The LINE STAGE (LineComposer) forms the lines of one segment:
#     word-wrapping, first-line indentation and runover, centering,
#     Nemeth indicator fusing for inline mathematics.  It is
#     position-aware -- the width of a line depends on whether it
#     lands on the last line of an embossed page, where a page
#     number lives -- but it writes nothing: it returns lines.
#
#   * The PAGE STAGE (PageComposer) pours lines onto pages: blank
#     lines and their suppression at page tops, page-break avoidance
#     for unbreakable material (arithmetic on line counts, computed
#     by running the line stage as a trial), page numbers, and form
#     feeds.
#
# The two stages communicate through Position objects (row on page,
# page number), which advance deterministically, so a trial run of
# the line stage answers "how many lines, crossing which pages?"
# without rendering anything twice.

import lxml.etree as ET

# "common" holds the canonical __module_warning; we alias it here so the
# warning below reads the same as everywhere else
from . import common
__module_warning = common.__module_warning
# the shared PreTeXt logger (with .bug()/.fallback()/.fatal())
log = common.log

# could import in a routine, but will do here in the module
try:
    import louis
except ImportError:
    raise ImportError(__module_warning.format("louis"))


class Segment:

    def __init__(self, s):

        self.xml = s

        # decipher, record attributes
        attrs = s.attrib
        if ("newpage" in attrs) and (attrs["newpage"] == "yes"):
            self.newpage = True
        else:
            self.newpage = False

        if ("ownpage" in attrs) and (attrs["ownpage"] == "yes"):
            self.ownpage = True
        else:
            self.ownpage = False

        if ("centered" in attrs) and (attrs["centered"] == "yes"):
            self.centered = True
        else:
            self.centered = False

        if ("breakable" in attrs) and (attrs["breakable"] == "no"):
            self.breakable = False
        else:
            self.breakable = True

        if "indentation" in attrs:
            self.indentation = int(attrs["indentation"])
        else:
            self.indentation = 0

        if "runover" in attrs:
            self.runover = int(attrs["runover"])
        else:
            self.runover = 0

        if "lines-before" in attrs:
            self.lines_before = int(attrs["lines-before"])
        else:
            self.lines_before = 0

        if "lines-after" in attrs:
            self.lines_after = int(attrs["lines-after"])
        else:
            self.lines_after = 0

        if "lines-following" in attrs:
            self.lines_following = int(attrs["lines-following"])
        else:
            self.lines_following = 0

        if "heading-id" in attrs:
            self.heading_id = attrs["heading-id"]
        else:
            self.heading_id = None


class Block:

    def __init__(self, b):

        self.xml = b

        # decipher, record attributes
        attrs = b.attrib

        if ("newpage" in attrs) and (attrs["newpage"] == "yes"):
            self.newpage = True
        else:
            self.newpage = False

        if ("ownpage" in attrs) and (attrs["ownpage"] == "yes"):
            self.ownpage = True
        else:
            self.ownpage = False

        if ("breakable" in attrs) and (attrs["breakable"] == "no"):
            self.breakable = False
        else:
            self.breakable = True

        if "lines-before" in attrs:
            self.lines_before = int(attrs["lines-before"])
        else:
            self.lines_before = 0

        if "lines-after" in attrs:
            self.lines_after = int(attrs["lines-after"])
        else:
            self.lines_after = 0

        if "lines-following" in attrs:
            self.lines_following = int(attrs["lines-following"])
        else:
            self.lines_following = 0

        if "box" in attrs:
            self.box = attrs["box"]
        else:
            self.box = None

        if "punctuation" in attrs:
            self.punctuation = attrs["punctuation"]
        else:
            self.punctuation = None


class Position:
    """Where the next line of content will land.

    row is 1-based: the line on the page about to be formed.  page
    is the page number that row belongs to.  For electronic (single,
    endless page) output, the row never advances past 1 of page 1 in
    any meaningful way; see PageLayout.
    """

    def __init__(self, row, page):
        self.row = row
        self.page = page

    def copy(self):
        return Position(self.row, self.page)


class PageLayout:
    """The shape of a page, and what geometry implies for each line.

    Embossed pages have a page number in the lower-right corner: the
    last line of every page reserves separating space and the digits
    of the number, so lines landing there are narrower.  Electronic
    output is one endless page: no last lines, no numbers, no form
    feeds.
    """

    # blank cells between content and a page number
    page_num_sep = 3

    def __init__(self, width, height, page_format):
        self.width = width
        self.height = height
        if page_format == 'emboss':
            self.emboss = True
        elif page_format == 'electronic':
            self.emboss = False
        else:
            log.bug("page format not recognized, so embossing")
            self.emboss = True

    def is_last_row(self, position):
        return self.emboss and (position.row == self.height)

    def text_width(self, position, reduction):
        """Width available for content of the line at this position.

        reduction is the caller's own reservation (centering margins,
        table-of-contents page-number columns).
        """
        width = self.width - reduction
        if self.is_last_row(position):
            width -= (PageLayout.page_num_sep + len(braille_number(position.page)))
        return width

    def advance(self, position):
        """The position of the line after this one."""
        if self.emboss and (position.row == self.height):
            return Position(1, position.page + 1)
        else:
            return Position(position.row + 1, position.page)

    def at_page_start(self, position):
        # The top of an embossed page.  Electronic output is never
        # at a page start, not even at the very beginning -- so
        # requested blank lines always appear.  (This mirrors
        # long-standing behavior of the electronic layout.)
        return self.emboss and (position.row == 1)


# The UEB Grade 2 table includes Grade 1 explicitly
_TABLES = ["en-ueb-g2.ctb"]

# Nemeth switch indicators, Unicode braille cells
NEMETH_OPEN = "⠸⠩"
NEMETH_CLOSE = "⠸⠱"


def translate_print(aline):
    # Renderer-generated print (page numbers, guide dots) and
    # Unicode braille cells (which convert dot-for-dot) become
    # BRF ASCII symbols.  Body text never passes through here:
    # it arrives already translated, typeforms and all, from the
    # translation pass (braille_translate.py).
    return louis.translateString(_TABLES, aline, None, 0)


def contains_unicode_braille(aline):
    # The blank cell U+2800 is excluded: alone it says nothing,
    # since genuine mathematics always carries patterned cells
    return any(("\u2801" <= c) and (c <= "\u28FF") for c in aline)


# Page numbers appear on every embossed page, and every line of the
# renderer's geometry needs their braille length, so memoize them
_braille_numbers = {}

def braille_number(number):
    """The braille form of a page number (memoized)."""
    if number not in _braille_numbers:
        _braille_numbers[number] = translate_print(str(number))
    return _braille_numbers[number]


class LineComposer:
    """The line stage: form the lines of one segment.

    Position-aware but side-effect free: feed it the fragments of a
    segment, collect completed lines (content only -- page numbers
    and form feeds belong to the page stage).  Lines are accounted
    against the layout as they complete, so widths follow the page
    geometry, including the narrower last line of an embossed page.
    """

    def __init__(self, layout, position, seg, symbols_early, reduction):
        self.layout = layout
        self.position = position.copy()
        self.seg = seg
        self.symbols_early = symbols_early
        # a standing reservation of cells (centering, ToC number column)
        self.reduction = reduction
        self.lines = []
        self.contents = ''
        self.first_line = True

    # Properties

    def at_line_start(self):
        return self.contents == ''

    def remaining_characters(self):
        return self.layout.text_width(self.position, self.reduction) - len(self.contents)

    def is_room(self, text):
        return self.remaining_characters() - len(text) >= 0

    # Actions

    def break_line(self):
        """Complete the line under formation, ready or not."""
        # Non-breaking spaces have done their job, and we do not
        # want to see them in the BRF file
        contents = self.contents.replace("\xA0", " ")
        # A trailing space is important for spacing off mixed
        # content, but is not needed at the end of a line
        if (contents != '') and (contents[-1] == " "):
            contents = contents[:-1]
        self.lines.append(contents)
        self.contents = ''
        self.position = self.layout.advance(self.position)

    def blank_line(self):
        assert self.at_line_start(), "BUG: creating a blank line, but not at the start of a line"
        self.break_line()

    def write_fragment(self, typeface, aline, math_punctuation):
        # Body text arrives from the translation pass as braille
        # already, so most fragments ride through untouched.  The
        # exceptions: inline mathematics ("math") gets Nemeth
        # indicators and space fusing; renderer-generated print
        # ("print": page numbers, guide dots) translates here; and
        # anything still holding Unicode braille cells (display
        # mathematics under a "late" election, or print residue from
        # Speech Rule Engine) goes through liblouis, where cells
        # convert dot-for-dot and residue translates as print.
        # After this, `aline` is a BRF string, with spaces, nbsps
        if typeface == "math":
            aline = self.massage_math(aline, math_punctuation)
        elif self.symbols_early and (typeface == "display-math") and not(contains_unicode_braille(aline)):
            # display mathematics, already BRF ASCII symbols; blank
            # cells, arriving as no-break spaces, become the plain
            # spaces that a late election gets from liblouis
            aline = aline.replace("\xA0", " ")
        elif (typeface == "print") or contains_unicode_braille(aline):
            aline = translate_print(aline)

        # When a word is output, it gets the space from the previous
        # split, unless it is the first word of a line and the prior
        # space became a newline character.
        prior_space = ""

        # We chop down `aline` until there is nothing left.  When the
        # first space is at the end of `aline` the split will yield an
        # empty string as the second piece.  We do want this string to
        # pass through the `while` again, to pick up the space we
        # split on via `prior_space`.  THEN the split yields just one
        # piece and the while ends.  This explains why we control the
        # halting of the `while` loop rather than just testing that
        # `aline` is empty.
        while aline != None:
            pieces = aline.split(" ", 1)
            word = pieces[0]
            next_text = prior_space + word

            # first line:  indent and flip switch permanently to False
            # later lines: use runover instead
            if self.at_line_start():
                if self.first_line:
                    pad = self.seg.indentation
                    self.first_line = False
                else:
                    pad = self.seg.runover
                next_text = (" " * pad) + next_text

            if self.is_room(next_text):
                self.contents += next_text
                prior_space = " "
                if len(pieces) == 2:
                    aline = pieces[1]
                else:
                    # A 1-piece list after a split indicates there was
                    # no space to split on, so `word` has been written
                    # out.  Set `aline` to `None` as sentinel.
                    aline = None
            elif not(self.at_line_start()):
                # no room, have a partial line already in place
                # so move to a new line, i.e. "go around again"
                # do not update  aline  as it can split again
                prior_space = ""
                self.break_line()
            else:
                # at the start of a new line and there is *still* not
                # enough room: brutally hyphenate the word to just fit
                room = self.remaining_characters()
                whole_line = word[:(room - 1)] + "-"
                aline = word[(room - 1):]
                if len(pieces) == 2:
                    aline += " " + pieces[1]
                self.contents += whole_line

    def massage_math(self, aline, punctuation):

        # available width will change across lines,
        # so this assumption is mildly flawed
        width = self.layout.width

        # Local versions of the Unicode Nemeth switch indicators,
        # for convenience and manipulation.  We control separating
        # spaces below as a way to influence line-breaking for
        # inline math.
        nemeth_open = NEMETH_OPEN
        nemeth_close = NEMETH_CLOSE

        # Blank cells within the mathematics are just spaces-to-be:
        # make them spaces now, so the fusing below treats every
        # blank alike.  (Blank cells arrive as U+2800 under a late
        # election, and as no-break spaces under an early one.)
        aline = aline.replace("\u2800", " ").replace("\xA0", " ")

        # Join trailing punctuation to the closing indicator and
        # record influence on overall length for line-breaking.
        if punctuation:
            nemeth_close += punctuation
            punct_len = len(punctuation)
        else:
            punct_len = 0

        # The mathematics arrived as BRF ASCII symbols exactly when
        # "early" was elected AND the preprint conversion found only
        # braille cells (mathematics with print residue rides along
        # as Unicode no matter the election, see the preprint XSL).
        early_form = self.symbols_early and not(contains_unicode_braille(aline))

        # For the early form, the Unicode indicator chunks (with
        # punctuation attached) convert here, by the same translation
        # they would otherwise receive below, and the mathematics
        # itself rides along untouched.
        if early_form:
            nemeth_open = translate_print(nemeth_open)
            nemeth_close = translate_print(nemeth_close)

        # Actual Nemeth braille, plus 3, plus 3 for indicators, and punctuation
        math_len = len(aline) + 6 + punct_len

        if math_len <= width:
            # fuse all blanks, force onto one line if needed
            aline = nemeth_open + "\xA0" + aline.replace(" ", "\xA0") + "\xA0" + nemeth_close
        elif math_len <= width + 3:
            # fuse all blanks, except let Nemeth-close break off
            aline = nemeth_open + "\xA0" + aline.replace(" ", "\xA0") + " " + nemeth_close
        elif math_len <= width + 6 + punct_len:
            # fuse all blanks, except let both Nemeth break off
            aline = nemeth_open + " " + aline.replace(" ", "\xA0") + " " + nemeth_close
        else:
            # fuse on the indicators, then break at any space
            aline = nemeth_open + "\xA0" + aline + "\xA0" + nemeth_close

        # Already BRF ASCII symbols throughout (early form); blank
        # cells became plain spaces above, with all the other blanks
        if early_form:
            return aline

        # Unicode characters translate, one for one, into BRF
        # characters and we assume punctuation does the same.
        return translate_print(aline)


class PageComposer:
    """The page stage: pour lines onto pages.

    Tracks one Position; emits content lines with page numbers on
    the last line of each embossed page and a form feed at each page
    end; decides page-break avoidance for unbreakable material by
    counting the lines a trial of the line stage produces.
    """

    def __init__(self, layout, symbols_early):
        self.layout = layout
        self.symbols_early = symbols_early
        self.position = Position(1, 1)
        # completed physical lines, tail-joined by newlines
        self.output = []
        # headings noted for the table of contents: identifier to page
        self.toc_dict = {}
        # producing table-of-contents entries (with a column of page
        # numbers on the right)?
        self.toc_mode = False

    # Properties

    def at_page_start(self):
        return self.layout.at_page_start(self.position)

    def remaining_lines(self):
        # lines left on this page, including the one about to form
        return self.layout.height - self.position.row + 1

    # Actions

    def emit_line(self, contents):
        """One completed content line onto the page."""
        if self.layout.is_last_row(self.position):
            # right-justify the page number after the content
            number = braille_number(self.position.page)
            gap = " " * (self.layout.width - len(contents) - len(number))
            contents = contents + gap + number
        self.output.append(contents)
        rollover = self.layout.is_last_row(self.position)
        self.position = self.layout.advance(self.position)
        if rollover:
            # close the page with a form feed, on its own "line"
            # joined to the page's last newline
            self.output[-1] += "\n\x0C"
        else:
            self.output[-1] += "\n"

    def blank_line(self):
        self.emit_line('')

    def advance_page(self):
        # fill the remainder of the page with blank lines (the last
        # of which carries the page number), ending with a form
        # feed.  Note: from the top of a fresh page this produces an
        # entire blank (but numbered) page, deliberately.
        if not(self.layout.emboss):
            return
        for i in range(self.remaining_lines()):
            self.blank_line()

    # Rendering: each piece has a "compose" (line stage, no output)
    # and a "write" (decide page breaks, then emit)

    def compose_segment(self, seg, position):
        """The line stage for one segment: content lines, no page furniture."""
        # centering and table-of-contents entries reserve cells
        reduction = 0
        if seg.centered:
            # [BANA 2016], 4.4.2: at least three blank cells must
            # precede and follow a centered heading
            reduction += 6
        if self.toc_mode:
            # reserve a column for guide dots and a page number,
            # released just before they are written
            reduction += 6

        composer = LineComposer(self.layout, position, seg, self.symbols_early, reduction)

        sxml = seg.xml
        if sxml.text:
            composer.write_fragment("text", sxml.text, None)
        for c in sxml:
            typeface = c.tag
            if typeface != "math":
                log.bug('unexpected element "{}" inside a segment; its text is rendered plain and any nested content is dropped'.format(c.tag))
                typeface = "text"
            if c.text:
                if 'punctuation' in c.attrib:
                    math_punctuation = c.attrib['punctuation']
                else:
                    math_punctuation = None
                composer.write_fragment(typeface, c.text, math_punctuation)
            if c.tail:
                composer.write_fragment("text", c.tail, None)

        # Finish the table-of-contents entry: release the reserved
        # column, add guide dots and the target's page number
        if self.toc_mode:
            composer.reduction -= 6
            if self.layout.emboss:
                page_num = str(self.toc_dict[seg.heading_id])
                guide_dots = composer.remaining_characters() - (1 + len(page_num))
                guide = ['', '', '']
                if guide_dots > 0:
                    guide[0] = ' '
                    guide_dots -= 1
                if guide_dots > 0:
                    guide[2] = ' '
                    guide_dots -= 1
                if guide_dots > 0:
                    guide[1] = '⠐' * guide_dots
                composer.write_fragment("print", ''.join(guide) + page_num, None)

        # complete any partial line
        if not(composer.at_line_start()):
            composer.break_line()

        lines = composer.lines
        # center, in the full width (the reservation was symmetric)
        if seg.centered:
            centered = []
            for line in lines:
                if line == '':
                    centered.append(line)
                else:
                    pad = " " * ((self.layout.width - len(line)) // 2)
                    centered.append(pad + line)
            lines = centered
        return lines

    def compose_display_segment(self, seg, position):
        """The line stage for a segment of a Nemeth display block."""
        composer = LineComposer(self.layout, position, seg, self.symbols_early, 0)
        sxml = seg.xml
        if sxml.text:
            composer.write_fragment("display-math", sxml.text, None)
        if not(composer.at_line_start()):
            composer.break_line()
        return composer.lines

    def segment_lines(self, seg, position, in_nemeth_box):
        if in_nemeth_box:
            return self.compose_display_segment(seg, position)
        else:
            return self.compose_segment(seg, position)

    def needs_page_advance(self, lines_count, lines_following):
        """Would this content cross one page boundary it could avoid?

        Content beginning at the current position, occupying
        lines_count lines (blank lines included), keeping
        lines_following more lines attached beyond that.
        """
        if not(self.layout.emboss):
            return False
        total = lines_count + lines_following
        remaining = self.remaining_lines()
        # fine as-is: no page boundary broached (landing exactly at
        # the top of the next page does not count as broaching)
        if total <= remaining:
            return False
        # hopeless: does not fit whole on a fresh page either
        if total > self.layout.height:
            return False
        # would break, and would fit whole on the next page
        return True

    # The layout of blocks is written positionally below: the
    # "lay_*" methods produce lines from a position, purely -- they
    # serve as the trial machinery, and as the interior of blocks --
    # while the "write_*" methods do the same work against the real
    # position, emitting page furniture as they go.  Both make the
    # identical decisions because both see only positions.

    def lay_block(self, blk, position):
        """Lines of a whole block laid from a position: (lines, position).

        Interior segments make their own page-break-avoidance
        decisions, positionally, just as they would at the top
        level; interior blank-line demands are suppressed at page
        tops; box rules follow the width of the line they land on.
        """
        lines = []
        position = position.copy()

        def emit(line):
            nonlocal position
            lines.append(line)
            position = self.layout.advance(position)

        def fill_page():
            nonlocal position
            if not(self.layout.emboss):
                return
            for i in range(self.layout.height - position.row + 1):
                emit('')

        if blk.box == "standard":
            emit("7" * self.layout.text_width(position, 0))
        elif blk.box == "nemeth":
            emit(translate_print(NEMETH_OPEN))
            emit('')

        for child in blk.xml.xpath("segment|block"):
            if child.tag == "segment":
                seg = Segment(child)
                if seg.newpage and self.layout.emboss:
                    fill_page()
                if seg.ownpage and self.layout.emboss:
                    fill_page()
                blanks = 0 if self.layout.at_page_start(position) else seg.lines_before
                if not(seg.breakable) and self.layout.emboss and not(seg.ownpage or seg.newpage):
                    trial_position = position.copy()
                    for i in range(blanks):
                        trial_position = self.layout.advance(trial_position)
                    trial = self.segment_lines(seg, trial_position, blk.box == "nemeth")
                    remaining = self.layout.height - position.row + 1
                    total = blanks + len(trial) + seg.lines_after + seg.lines_following
                    if (total > remaining) and (total <= self.layout.height):
                        fill_page()
                        blanks = 0
                for i in range(blanks):
                    emit('')
                for line in self.segment_lines(seg, position, blk.box == "nemeth"):
                    emit(line)
                for i in range(seg.lines_after):
                    emit('')
                if seg.ownpage and self.layout.emboss:
                    fill_page()
            elif child.tag == "block":
                inner = Block(child)
                (inner_lines, position) = self.lay_inner_block(inner, position)
                for line in inner_lines:
                    lines.append(line)

        if blk.box == "standard":
            emit("g" * self.layout.text_width(position, 0))
        elif blk.box == "nemeth":
            emit('')
            close_brf = NEMETH_CLOSE
            if blk.punctuation:
                close_brf += blk.punctuation
            emit(translate_print(close_brf))

        return (lines, position)

    def lay_inner_block(self, blk, position):
        """A block, with its surrounding decisions, laid from a position."""
        lines = []
        position = position.copy()

        def emit(line):
            nonlocal position
            lines.append(line)
            position = self.layout.advance(position)

        def fill_page():
            nonlocal position
            if not(self.layout.emboss):
                return
            for i in range(self.layout.height - position.row + 1):
                emit('')

        if blk.ownpage and self.layout.emboss:
            fill_page()
        # avoid starting box material in the last sliver of a page
        initial_lines = 1
        if blk.box:
            initial_lines += 2
        if self.layout.emboss and ((self.layout.height - position.row + 1) < initial_lines):
            fill_page()
        blanks = 0 if self.layout.at_page_start(position) else blk.lines_before
        if not(blk.breakable) and self.layout.emboss and not(blk.ownpage):
            trial_position = position.copy()
            for i in range(blanks):
                trial_position = self.layout.advance(trial_position)
            (trial, _) = self.lay_block(blk, trial_position)
            remaining = self.layout.height - position.row + 1
            total = blanks + len(trial) + blk.lines_after + blk.lines_following
            if (total > remaining) and (total <= self.layout.height):
                fill_page()
                blanks = 0
        for i in range(blanks):
            emit('')
        (block_lines, position) = self.lay_block(blk, position)
        for line in block_lines:
            lines.append(line)
        for i in range(blk.lines_after):
            emit('')
        if blk.ownpage and self.layout.emboss:
            fill_page()
        return (lines, position)

    def write_segment(self, seg):
        if seg.newpage and self.layout.emboss:
            self.advance_page()
        if seg.ownpage and self.layout.emboss:
            self.advance_page()

        # blank lines before, suppressed at an embossed page top
        blanks = 0 if self.at_page_start() else seg.lines_before

        # page-break avoidance for unbreakable segments: count the
        # lines of a trial laid from just past the blank lines
        if not(seg.breakable) and self.layout.emboss and not(seg.ownpage or seg.newpage):
            position = self.position.copy()
            for i in range(blanks):
                position = self.layout.advance(position)
            trial = self.segment_lines(seg, position, False)
            if self.needs_page_advance(blanks + len(trial) + seg.lines_after, seg.lines_following):
                self.advance_page()
                # a page top: blank lines are now suppressed
                blanks = 0

        for i in range(blanks):
            self.blank_line()

        # a heading is about to be written: record its page
        if seg.heading_id and self.layout.emboss and not(self.toc_mode):
            self.toc_dict[seg.heading_id] = self.position.page

        for line in self.segment_lines(seg, self.position, False):
            self.emit_line(line)

        for i in range(seg.lines_after):
            self.blank_line()

        if seg.ownpage and self.layout.emboss:
            self.advance_page()

    def write_block(self, blk):
        if blk.ownpage and self.layout.emboss:
            self.advance_page()

        # We don't want to start block material right at the bottom
        # of the page when there are not enough lines to really get
        # moving.  Most box material needs a blank line, a box line,
        # and a heading.
        initial_lines = 1
        if blk.box:
            initial_lines += 2
        if self.layout.emboss and (self.remaining_lines() < initial_lines):
            self.advance_page()

        blanks = 0 if self.at_page_start() else blk.lines_before

        if not(blk.breakable) and self.layout.emboss and not(blk.ownpage):
            position = self.position.copy()
            for i in range(blanks):
                position = self.layout.advance(position)
            (trial, _) = self.lay_block(blk, position)
            if self.needs_page_advance(blanks + len(trial) + blk.lines_after, blk.lines_following):
                self.advance_page()
                blanks = 0

        for i in range(blanks):
            self.blank_line()

        (block_lines, _) = self.lay_block(blk, self.position)
        for line in block_lines:
            self.emit_line(line)

        for i in range(blk.lines_after):
            self.blank_line()

        if blk.ownpage and self.layout.emboss:
            self.advance_page()

    def get_brf(self):
        return ''.join(self.output)


def parse_segments(xml_simple, out_file, page_format):

    # this routine converts XML information into arguments
    # to Python routines, but not exclusively yet

    huge_parser = ET.XMLParser(huge_tree=True)
    src_tree = ET.parse(xml_simple, parser=huge_parser)

    # This renderer requires input whose body text is braille
    # already; rendering print text would silently produce
    # unreadable output, so refuse it outright.
    if src_tree.getroot().get("translated") != "yes":
        raise ValueError("the braille renderer requires input from the translation pass, and this file has not been through it")

    # how braille cells are represented in the preprint:
    # "late" is Unicode braille cells (the default), "early" is
    # BRF ASCII symbols (a developer convenience for debugging)
    symbols = src_tree.getroot().get("brf-symbols", "late")
    symbols_early = (symbols == "early")

    # page geometry, elected in the publication file and validated
    # upstream: cells in a line, lines on an embossed page
    page_width = int(src_tree.getroot().get("page-width", "40"))
    page_height = int(src_tree.getroot().get("page-height", "25"))

    layout = PageLayout(page_width, page_height, page_format)

    # the body of the document
    body = PageComposer(layout, symbols_early)
    for elt in src_tree.xpath("/brf/segment|/brf/block"):
        if elt.tag == "segment":
            body.write_segment(Segment(elt))
        elif elt.tag == "block":
            body.write_block(Block(elt))

    # The front matter (table of contents) knows the page number of
    # each heading only after the body has been laid out, so it is
    # rendered second, on its own pages, though it appears first in
    # the file.
    front = PageComposer(layout, symbols_early)
    front.toc_mode = True
    front.toc_dict = body.toc_dict
    for head in src_tree.xpath("/brf/segment[@heading-id]"):
        seg = Segment(head)
        seg.newpage = False
        seg.ownpage = False
        seg.centered = False
        seg.breakable = False
        seg.lines_before = 0
        seg.lines_after = 0
        seg.lines_following = 0
        front.write_segment(seg)
    # fill out the final front-matter page
    if page_format == 'emboss':
        front.advance_page()

    with open(out_file, "w") as brf_file:
        brf_file.write(front.get_brf())
        brf_file.write(body.get_brf())
