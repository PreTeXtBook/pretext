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

# A routine PreTeXt package/module, so
# natural to import at the module level
# needs warning if not available
import lxml.etree as ET

# could import in a routine, but will do here in the module
# Note: an import into the BRF class requires changes to the static method
try:
    import louis
except ImportError:
    raise ImportError("The 'louis' python binding for LibLouis is required for Braille output.  See https://pretextbook.org/doc/guide/html/liblouis.html for instructions.")

# A  Cursor  object tracks location in a BRF file:
# location in a line, line in a page, overall page number
# It is initialized with the overall shape/body of a page
# The location in a line is redundant given that it is easily
# computable from the state of the line buffer.  But we can
# base an assertion on a comparison of the two objects.  So
# during active development we use both objects as a check
# on the use of the line buffer.

class Cursor:

    def __init__(self, width, height, page_format):
        # page shape, dimensions, at creation time
        self.page_width = width
        self.page_height = height
        # Finally, we interpret `page_format`
        if page_format == 'emboss':
            self.emboss = True
        elif page_format == 'electronic':
            self.emboss = False
        else:
            print("BUG: page format not recognized, so embossing")
            self.emboss = True
        # we allow for variable length lines, in
        # order to allow for insertion of page numbers
        self.text_width = width
        # initialize clean slate
        # chars, lines are *remaining* room
        # they will decrement to zero
        self.chars_left = self.text_width
        # Default brehavior is to form pages for embossing, which requires
        # a lot of attention to page breaks and page numbers.  BUT, if we
        # start with an absurd number of lines available, AND we never
        # decrement the number of lines available then we will never think
        # we are at the bottom of a page.  No page breaks, no adjustment of
        # the page number, no writing out page numbers.   It is like the
        # file is an infinitely long page.  See companion discussion
        # at Cursor.advance_line().
        if self.emboss:
            self.lines_left = self.page_height
        else:
            self.lines_left = 2*self.page_height
        # page_num is the page being produced
        # increment as a new page begins
        self.page_num = 1

    # this includes the line currently under formation
    def remaining_lines(self):
        return self.lines_left

    def remaining_characters(self):
        return self.chars_left

    def at_page_start(self):
        return (self.chars_left == self.text_width) and (self.lines_left == self.page_height)

    def page_number(self):
        return self.page_num

    def embossing(self):
        return self.emboss

    #########
    # Actions
    #########

    def new_page(self):
        # refresh lines remaining
        self.lines_left = self.page_height
        # increment page number
        self.page_num += 1

    def advance_line(self):
        # decrement the lines available
        # This is where we decrement the number of lines available
        # on a page.  And it is the only place.  If not embossing,
        # then no page, so we conspire to never change the lines
        # available count.  It is like the file is an infinitely
        # long page.  See companion discussion at Cursor.__init__().
        if self.emboss:
            self.lines_left -= 1
        else:
            pass

        # Restore the number of available characters
        self.chars_left = self.text_width

        # falling off page end provokes new page
        if self.lines_left == 0:
            self.new_page()

    # Note: it is possible to adjust text width
    # while in the middle of forming a line
    def adjust_text_width(self, adjustment):
        self.text_width  += adjustment
        self.chars_left  += adjustment

    def advance(self, nchars):
        # do not do this unless there is room
        # does not provoke a new line
        self.chars_left -= nchars
        if self.chars_left < 0:
            print("BUG: negative chars")

# The line buffer is used to break a long line of words into
# a sequence of lines that fit width-wise on a braille page.
# The orignal `fragment` is assumed to have no line-breaks.
# As we fill the line buffer, some spaces become newlines.
# So in the usual parlance this is "text-wrapping".  However,
# we also manage automatic page breaks once a page is full.


class LineBuffer:

    def __init__(self, width):
        self.contents = ''
        self.page_width = width
        self.text_width = width

    # Properties

    def is_room(self, text):
        return len(self.contents) + len(text) <= self.text_width

    def is_empty(self):
        return self.contents == ''

    def remaining_chars(self):
        return self.text_width - len(self.contents)

    # Actions

    def add(self, text):
        self.contents += text

    def adjust_text_width(self, adjustment):
        self.text_width += adjustment

    def flush(self, brf):
        # Flushing the line buffer places the contents into
        # the `out_buffer` of the BRF object provided.

        # this does not write a newline character as we
        # may want to end without provoking a new page
        # Non-breaking spaces have done their job, and we
        # do not want to see them in the BRF file.  Thanks,
        # you are dismissed.
        self.contents = self.contents.replace("\xA0", " ")

        # Unlikely a non-breaking space may be at the end of a line,
        # but we do this in a particular order just in case.
        # Remove trailing spaces which are important for spacing off
        # mixed content, but can end up at the end of a line where they
        # are not needed.  This does not harm line-breaking, since if
        # another word would fit, then the space would need to be there.
        if not(self.contents == '') and self.contents[-1] == " ":
            self.contents = self.contents[:-1]

        # OK, the main event
        brf.write(self.contents)
        # Once written, reset contents
        self.contents = ''


class Segment:

    def __init__(self, s):

        self.xml = s

        # For switching from indentation to runover
        self.first_line = True

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


class BRF:

    # spaces prior to a page number, duplicated in Cursor
    page_num_sep = 3

    # Nemeth switch indicators, class variables for convenience
    nemeth_open = "\u2838\u2829"
    nemeth_close = "\u2838\u2831"

    # We need to connect the "trans1" emphasis scheme of the liblouis
    # "en-ueb-g1.ctb" table with a typeform bit we can use to switch
    # to this variant when we translate inline code phrases
    trans1_bit = louis.getTypeformForEmphClass(["en-ueb-g2.ctb"], 'trans1')

    def __init__(self, page_format, width, height):
        self.out_buffer = ''
        self.accumulator = []
        self.toc_dict = {}
        self.toc_mode = False
        self.cursor = Cursor(width, height, page_format)
        self.line_buffer = LineBuffer(width)

    # Properties (boolean functions) reported
    # by the current line buffer or default/embedded cursor

    def is_room_on_line(self, text):
        return self.line_buffer.is_room(text)

    def at_line_start(self):
        return self.line_buffer.is_empty()

    # Designed for segments and blocks, to avoid poor placement
    # near a page break.  Key is a trial/sandbox BRF object and
    # its associated cursor.
    #
    #  * Trial does not provoke a page break.  Good.
    #  * Trial provokes two page breaks.  Too bad, nothing to be done.
    #  * Trial provokes exactly one page break.
    #     - if content is more than a page, that's life
    #     - see if content fits on a page, recommend a page advance
    #
    # Note: this is a bit disingenuous.  This allows both a segment
    # and a block as an argument, on the assumption they have common
    # attributes employed here.  Really they should be derived from
    # a common object.  A switch on object type is necessary to call
    # the two different BRF "process" methods, no matter what.
    def needs_page_advance(self, seg):
        import copy

        # A "page" only makes sense if embossing
        if not(self.cursor.embossing()):
            return False

        # If segment explicitly creates a new page,
        # then the question of space is moot
        if seg.ownpage or seg.newpage:
            return False

        # Line numbers could be actual line numbers for first and
        # last line of content produced by the sandbox BRF.
        # Formula would be
        #
        #     line-number = page-height - remaining-lines + 1
        #
        # We will subtract the starting line from the finishing line,
        # so the page-heights and the "+1" will cancel out.  Thus
        # definitions are just the negatives of the remaining lines.
        #
        # Segment processing always ends on a new line, so the finishing
        # line has a "-1" to walk it back a line (and if the segment reset
        # goes to a new page, then the remaining lines would be zero on
        # the previous page, set to negative zero here).

        orginal_cursor = self.cursor
        start_page = orginal_cursor.page_number()
        start_line = -orginal_cursor.remaining_lines()
        # all changes (cursor movement, text-wrapping) will
        # occur in the temporary/sandbox/throwaway cursor
        sandbox_brf = copy.deepcopy(self)
        sandbox_cursor = sandbox_brf.cursor
        # Do the deal, in a sandbox
        # Type will be "Block" or "Segment"
        if type(seg) == Segment:
            sandbox_brf.process_segment(seg)
        else:
            sandbox_brf.process_block(seg)
        # Attach some lines of content, virtually
        for i in range(seg.lines_following):
            sandbox_cursor.advance_line()

        finish_page = sandbox_cursor.page_number()
        finish_line = -sandbox_cursor.remaining_lines() - 1
        # Except, segment finishes ready-to-go,
        # which could be the tip-top of the next page.
        if sandbox_cursor.at_page_start():
            finish_page -= 1
            finish_line = -0

        # Fine as-is, no page boundary has been broached
        if (finish_page - start_page) == 0:
            return False
        # Really long, hopeless, a break doesn't help
        elif (finish_page - start_page) > 1:
            return False
        # Exactly one page-break, so look to line numbers
        # More than a page-full, since finish is later
        elif finish_line - start_line >= 0:
            return False
        # There would be a break, and content would fit on the next
        # page, so go for it and report the need for a page advance
        else:
            return True


    # Actions

    def adjust_text_width(self, adjustment):
        # Temporarily adjust the width of a page
        # For example, to construct a centered heading,
        # or to reserve space for a trailing page number.
        # Argument is an adjustment to the current width
        # (reduce with negative, then quickly restore with positive).
        # A reduction must be while preparing a line, the ensuing
        # expansion can (and often will) occur while mid-line.
        if (adjustment < 0):
            assert self.at_line_start(), "BUG: reducing text width, when not at a line start"
        self.cursor.adjust_text_width(adjustment)
        self.line_buffer.adjust_text_width(adjustment)

    def write(self, text):
        self.out_buffer += text

    def advance_one_line(self):
        # The last line needs a page number at its conclusion, so
        # we need to (a) shorten the buffer going *into* forming
        # that line, and (b) actually tack on the number. These
        # booleans identify the line we are completing as we enter
        # this method.
        finish_penultimate = (self.cursor.remaining_lines() == 2)
        finish_last = (self.cursor.remaining_lines() == 1)

        # We need a braille version of the page number, for actual
        # printing on the last line, or for adjusting the size of
        # the line buffer for the last line prior to its formation.
        if finish_penultimate or finish_last:
            num = str(self.cursor.page_number())
            braille_num = self.translate_segment('text', num)

        # before leaving last line, add a page number, flush right
        if finish_last:
            # a character (period?) here can aid debugging
            gap = " " * (self.line_buffer.remaining_chars() + BRF.page_num_sep)
            # this can exceed buffer, but we have no checks for that
            self.line_buffer.add(gap + braille_num)

        # flush the BRF's line buffer into its
        # `out_buffer` while adding a newline
        # TODO: have line_buffer return contents as
        # a string, and .write() onto `out_buffer`
        self.line_buffer.flush(self)
        self.write("\n")

        # Record the advance to new line.
        # Note: this changes the number of remaining lines, which
        # explains the two booleans above recording the situation
        self.cursor.advance_line()

        # If we flushed penultimate line, set up a reduced
        # buffer for formation of the last line so there
        # will be room for a page number
        # Otherwise, restore the line buffer to its usual width
        if finish_penultimate:
            self.adjust_text_width( -(BRF.page_num_sep + len(braille_num)))
        if finish_last:
            self.adjust_text_width(  (BRF.page_num_sep + len(braille_num)))

        # this can cause the cursor to move to the start of a new
        # page if there were no more lines available on the page.
        # So add FF (trl-L, ASCII 12, hex 0C) to the `out_buffer`
        if self.cursor.at_page_start():
            self.write("\x0C")

    def blank_line(self):
        # We assume this method is only called when
        # we are at the start of a fresh line, so
        # flushing the line buffer does not produce
        # any text (unless a page number is printed)
        assert self.at_line_start(), "BUG: creating a blank line, but not at the start of a line"
        # `advance_one_line()` should flush an empty buffer,
        # write a newline, and manage page number output
        self.advance_one_line()

    def advance_page(self):
        # It might look silly to call this complicated function when we
        # could just drop a bunch of newlines into the `out_buffer`.
        # But we can be sure a partial line is handled correctly and we
        # can be sure a page number gets written properly in all cases.
        # And the FF for the end of the page.

        for i in range(self.cursor.remaining_lines()):
            self.advance_one_line()
        self.flush()
        if self.cursor.embossing():
            assert self.cursor.at_page_start(), "Page advance did not reach exactly the start of a new page"

    def write_word(self, word):
        # This assumes there is room on the current line
        # so no adjustments are made to the cursor
        assert self.line_buffer.remaining_chars() == self.cursor.remaining_characters(), "Cursor and LineBuffer have desynced"
        self.cursor.advance(len(word))
        self.line_buffer.add(word)

    def write_fragment(self, typeface, aline, math_punctuation, seg):

        # Nemeth math needs special care, and is already braille
        # Otherwise, have liblouis translate with correct typeface
        # After this, `aline` is a BRF string, with spaces, nbsps
        if typeface == "math":
            aline = self.massage_math(aline, math_punctuation)
        else:
            aline = BRF.translate_segment(typeface, aline)

        # When a word is output, it gets the space from the previous split,
        # unless it is the first word of a line and the prior space became
        # a newline character.
        prior_space = ""

        # We chop down `aline` until there is nothing left.  When the first
        # space is at the end of `aline` the split will yield an empty string
        # as the second piece.  We do want this string to pass through the
        # `while` again, to pick up the space we split on via `prior_space`.
        # THEN the split yields just one piece and the while ends.  This is
        # all a long excplnation of why we control the halting of the `while`
        # loop rather than just testing that `aline` is empty.

        while aline != None:
            pieces = aline.split(" ", 1)
            word = pieces[0]
            # if we add to current output line, how many characters would
            # be left? A negative number is indicative of no room
            # there *is* room for previous split and next word
            next_text = prior_space + word

            # `aline` is non-empty, check if at line start
            # first line:  indent and flip switch permanently to False
            # later lines: use runover instead
            if self.at_line_start():
                if seg.first_line:
                    pad = seg.indentation
                    seg.first_line = False
                else:
                    pad = seg.runover
                next_text = (" " * pad) + next_text

            if self.is_room_on_line(next_text):
                # TODO: sanitize non-breaking space now, as it has
                # served its purpose, but we don't want it in output
                self.write_word(next_text)
                prior_space = " "
                # update, or nullify, aline
                if len(pieces) == 2:
                    aline = pieces[1]
                else:
                    # A 1-piece list after a split indicates there was no
                    # space to split on, so `word` will have been written out.
                    # Set `aline` to `None` as sentinel.  See above for rationale.
                    aline = None
            elif not(self.at_line_start()):
                # no room, have a partial line already in place
                # so move to a new line, i.e. "go around again"
                # do not update  aline  as it can split again
                prior_space = ""
                self.advance_one_line()
            else:
                # this is bad - we are at the start of a new line already
                # (on accident or by having gone around) and there is
                # *still* not enough room
                # So we brutally hypentate the word to just fit with a hyphen
                whole_line = word[:(self.line_buffer.remaining_chars() - 1)] + "-"
                # Put `aline` back together, but without the string `whole_line`.
                # If there are more pieces we need to add back the space that
                # disappeared in the split.  Otherwise this is the last word
                # and it just got smaller.
                aline = word[(self.line_buffer.remaining_chars() - 1):]
                if len(pieces) == 2:
                    aline += " " + pieces[1]
                self.write_word(whole_line)

    def center(self):
        # Centered headings, may have blank lines
        lines = self.out_buffer.split("\x0A")
        nlines = len(lines)
        # Replacing contents
        self.out_buffer = ""
        for i in range(nlines):
            line = lines[i]
            if line == "":
                self.out_buffer += line
            else:
                pad = " " * ((self.line_buffer.text_width - len(line))//2)
                self.out_buffer += pad + line
            # Restore n-1 separators
            if i != (nlines - 1):
                self.out_buffer += "\x0A"

    def process_segment(self, s):
        '''For actual output, and for trial output with a disposable BRF'''

        # Note: this routine will fill a buffer that is part of a BRF
        # object.  It is independent of any file, so does not ever
        # actually output anything.  There is a separate method for that.
        # In this way, the method can be used in a trial fashion with a
        # scratch/temporary BRF object to see how the Cursor behaves and
        # thus if a segmant might cross a page boundary.

        # Will always start a new segment at a fresh line
        assert self.at_line_start(), "BUG: starting a segment, but not at the start of a line"

        if s.newpage and self.cursor.embossing():
            self.advance_page()

        if s.ownpage and self.cursor.embossing():
            self.advance_page()

        # Lines before (but not if at the start of a page)
        if not(self.cursor.at_page_start()):
            for i in range(s.lines_before):
                self.blank_line()

        # Any page adjustments are now concluded, including a sandbox
        # trial that may have necessitated a move to a new page.  If
        # the segment is a heading it is about to be written on the
        # page and the cursor knows the page number
        if s.heading_id and self.cursor.embossing() and not(self.toc_mode):
            self.toc_dict[s.heading_id] = self.cursor.page_number()

        # Centered
        # [BANA 2016],  4.4.2
        # At least three blank cells must precede and follow a centered heading.
        #
        # So shrink line buffer to get extra space
        if s.centered:
            self.adjust_text_width(-6)

        # If making segments/headings into ToC entries, then
        # reserve 6 spaces to the right at all times, until
        # just about to write the guide dots and page number
        if self.toc_mode:
            self.adjust_text_width(-6)

        sxml = s.xml
        if sxml.text:
            self.write_fragment("text", sxml.text, None, s)
        children = list(sxml)
        for c in children:
            if c.text:
                if 'punctuation' in c.attrib:
                    math_punctuation = c.attrib['punctuation']
                else:
                    math_punctuation = None
                # Following can help debug nested segments
                # print("SUSPECT TYPEFACE", c.tag, c.text)
                self.write_fragment(c.tag, c.text, math_punctuation, s)
            if c.tail:
                self.write_fragment("text", c.tail, None, s)

        # Release width restriction to finish ToC entry
        if self.toc_mode:
            self.adjust_text_width(6)
            # Page numbers iff embossing
            if self.cursor.embossing():
                page_num = str(self.toc_dict[s.heading_id])
                guide_dots = self.cursor.remaining_characters() - (1 + len(page_num))
                guide = ['', '', '']
                if guide_dots > 0:
                    guide[0] = ' '
                    guide_dots -= 1
                if guide_dots > 0:
                    guide[2] = ' '
                    guide_dots -= 1
                if guide_dots > 0:
                    guide[1] = '\u2810' * guide_dots
                self.write_fragment("text", ''.join(guide) + page_num, None, s)

        # finished with a segment
        # flush buffer, move to new line, maybe a new page
        # BUT not if we landed in this state anyway
        if not(self.at_line_start()):
            self.advance_one_line()
        # Necessary to restore for subsequent centering
        if s.centered:
            self.adjust_text_width(6)
        # Lines after
        for i in range(s.lines_after):
            self.blank_line()
        # post-process before any use
        if s.centered:
            self.center()

        # Dedicated page, so off we go (reqires something was written on page)
        if s.ownpage and self.cursor.embossing():
            self.advance_page()


    def massage_math(self, aline, punctuation):

        # available width will change across lines,
        # so this assumption is mildly flawed
        width = self.line_buffer.page_width

        # Unicode versions of Nemeth switch indicators.
        # We control separating spaces below as a way to
        # influence line-breaking for inline math
        # Local versions for convenience and manipulation
        nemeth_open = BRF.nemeth_open
        nemeth_close = BRF.nemeth_close

        # Join trailing punctuation to the closing indicator and
        # record influence on overall length for line-breaking.
        if punctuation:
            nemeth_close += punctuation
            punct_len = len(punctuation)
        else:
            punct_len = 0

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

        # Unicode characters translate, one for one, into BRF
        # characters and we assume punctuation does the same.
        # If not, we could map a few punctuation marks to Unicode.
        # Or perhaps set argument to do uncontracted braille.
        return louis.translateString(["en-ueb-g2.ctb"], aline, None, 0)

    def process_block(self, blk):

        if blk.ownpage and self.cursor.embossing():
            self.advance_page()

        # We don't want to start block material right at the bottom of
        # the page when there are not enough lines to really get moving.
        # Never start when there is one line left.  Most box material needs
        # three lines, a preceding blank line, a box line, and a heading
        # (maybe four lines? but three seems OK experimentally).
        # Likely this needs refinement.
        initial_lines = 1
        if blk.box:
            initial_lines += 2
        if (self.cursor.remaining_lines() < initial_lines) and self.cursor.embossing():
            self.advance_page()

        # Lines before (but not if at the start of a page)
        if not(self.cursor.at_page_start()):
            for i in range(blk.lines_before):
                self.blank_line()

        if blk.box == "standard":
            top_line = "7" * self.line_buffer.text_width
            self.write_word(top_line)
            self.advance_one_line()
        elif blk.box == "nemeth":
            open_brf = louis.translateString(["en-ueb-g2.ctb"], BRF.nemeth_open, None, 0)
            self.write_word(open_brf)
            self.advance_one_line()
            self.blank_line()

        inner_segments = blk.xml.xpath("segment|block")
        for s in inner_segments:
            if s.tag == "segment":
                seg = Segment(s)
                self.write_segment(seg)
            elif s.tag == "block":
                innerblk = Block(s)
                self.write_block(innerblk)

        if blk.box == "standard":
            bottom_line = "g" * self.line_buffer.text_width
            self.write_word(bottom_line)
            self.advance_one_line()
        elif blk.box == "nemeth":
            self.blank_line()
            # add punctuation that was mined from trailing text
            # node.  Note: only for Nemeth box/display math
            close_brf = BRF.nemeth_close
            if blk.punctuation:
                close_brf += blk.punctuation
            close_brf = louis.translateString(["en-ueb-g2.ctb"], close_brf, None, 0)
            self.write_word(close_brf)
            self.advance_one_line()

        # Lines after
        for i in range(blk.lines_after):
            self.blank_line()
            self.flush()

        # Dedicated page, so off we go (reqires something was written on page)
        if blk.ownpage and self.cursor.embossing():
            self.advance_page()


    # The next two "write" routines simply check if a page advance
    # is necessary/desirable for the block or segment in question,
    # and then call the "process" versions, where the real action
    # happens.  Then a flush.

    def write_segment(self, seg):
        # See if a page advance will improve awkward page breaks
        if not(seg.breakable) and self.needs_page_advance(seg):
            self.advance_page()
        self.process_segment(seg)
        self.flush()

    def write_block(self, blk):
        # See if a page advance will improve awkward page breaks
        if not(blk.breakable) and self.needs_page_advance(blk):
            self.advance_page()
        self.process_block(blk)
        self.flush()

    def flush(self):
        # The `accumulator` *is* the final document, as a list of
        # strings, so here we move the (completed) string for the
        # segment into the list that will be concatenated.  And
        # prepare the `out_buffer` for the next segment.
        self.accumulator.append(self.out_buffer)
        self.out_buffer = ''

    # Concatenate the strings of the `accumulator`
    def get_brf(self):
        return ''.join(self.accumulator)

    # Static methods

    @staticmethod
    def translate_segment(typeface, aline):

        # g2 includes g1 explicitly
        tableList = ["en-ueb-g2.ctb"]

        # Typeforms bits
        #    from Python, which is from C header, louis.h
        # plain_text = 0x0000
        # emph_1 = comp_emph_1 = italic = 0x0001 = 1
        # emph_2 = comp_emph_2 = underline = 0x0002 = 2
        # emph_3 = comp_emph_3 = bold = 0x0004 = 4
        # computer_braille = 0x0400 = 1024
        # no_contract = 0x1000 = 4096

        # `BRF.trans1_bit` is a class variable provided by the louis
        # package for switching into a transcriber-defined emphasis class
        # 2023-03-09: apparently  0x0020 = 32  for "trans1" (could change?)

        if typeface == "text":
            typeforms = None
        elif typeface == "italic":
            typeforms = [1] * len(aline)
        elif typeface == "bold":
            typeforms = [4] * len(aline)
        elif typeface == "code":
            typeforms = [BRF.trans1_bit] * len(aline)
        else:
            print('BUG: did not recognize typeface "{}"'.format(typeface) )
            # May be the Python error:
            #    UnboundLocalError: local variable 'typeforms' referenced before assignment
            # When this error message reports "segment" as the typeface,
            # it means there are nested segments.  Search this module for
            # "SUSPECT TYPEFACE" to find a useful debugging statement to use.
            # Setting "typeforms = None" here can keep processing alive but is
            # likely to lead to incorrect reesults.

        return louis.translateString(tableList, aline, typeforms, 0)

    # End BRF object definition


# Current entry point, sort of
def parse_segments(xml_simple, out_file, page_format):

    # Embossed, page shape
    brf = BRF(page_format, 40,25)

    # this routine converts XML information into arguments
    # to Python routines, but not exclusively yet

    huge_parser = ET.XMLParser(huge_tree=True)
    src_tree = ET.parse(xml_simple, parser=huge_parser)

    top_elts = src_tree.xpath("/brf/segment|/brf/block")

    for elt in top_elts:
        if elt.tag == "segment":
            seg = Segment(elt)
            brf.write_segment(seg)
        elif elt.tag == "block":
            blk = Block(elt)
            brf.write_block(blk)
        brf.flush()

    # Prepare a new BRF object, but copy out ToC page numbers
    front = BRF(page_format, 40,25)
    front.toc_mode = True
    front.toc_dict = brf.toc_dict

    headings = src_tree.xpath("/brf/segment[@heading-id]")
    for head in headings:
        seg = Segment(head)
        seg.newpage = False
        seg.ownpage = False
        seg.centered = False
        seg.breakable = False
        # indentation, runover
        seg.lines_before = 0
        seg.lines_after = 0
        seg.lines_following = 0
        front.write_segment(seg)
    # Fill out frontmatter final page
    if page_format == 'emboss':
        front.advance_page()

    # We assume `out_file` has been error-checked
    # It would be better to use a context manager
    brf_file = open(out_file, "w")
    brf_file.write(front.get_brf())
    brf_file.write(brf.get_brf())
    brf_file.close()
