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
import louis

# A  Cursor  object tracks location in a BRF file:
# location in a line, line in a page, overall page number
# It is initialized with the overall shape/body of a page
# The location in a line is redundant given that it is easily
# computable from the state of the line buffer.  But we can
# base an assertion on a comparison of the two objects.  So
# during active development we use both objects as a check
# on the use of the line buffer.

class Cursor:

    # spaces prior to a page number, duplicated in BRF
    page_num_sep = 3

    def __init__(self, width, height, page_format):
        # page shape, dimensions, at creation time
        self.width = width
        self.height = height
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
        self.maxchars = width
        # initialize clean slate
        # chars, lines are *remaining* room
        # they will decrement to zero
        self.chars = self.maxchars
        # Default brehavior is to form pages for embossing, which requires
        # a lot of attention to page breaks and page numbers.  BUT, if we
        # start with an absurd number of lines available, AND we never
        # decrement the number of lines available then we will never think
        # we are at the bottom of a page.  No page breaks, no adjustment of
        # the page number, no writing out page numbers.   It is like the
        # file is an infinitely long page.  See companion discussion
        # at Cursor.new_line().
        if self.emboss:
            self.lines = self.height
        else:
            self.lines = 2*self.height
        # page_num is the page being produced
        # increment as a new page begins
        self.page_num = 1

    # this includes the line currently under formation
    def remaining_lines(self):
        return self.lines

    def remaining_characters(self):
        return self.chars

    def at_page_start(self):
        return (self.chars == self.maxchars) and (self.lines == self.height)

    def page_number(self):
        return self.page_num

    #########
    # Actions
    #########

    def new_page(self):
        # refresh maxchars, chars and lines
        self.maxchars = self.width
        self.chars = self.maxchars
        self.lines = self.height
        # increment page number
        self.page_num += 1

    def new_line(self):
        # decrement the lines available
        # This is where we decrement the number of lines available
        # on a page.  And it is the only place.  If not embossing,
        # then no page, so we conspire to never change the lines
        # available count.  It is like the file is an infinitely
        # long page.  See companion discussion at Cursor.__init__().
        if self.emboss:
            self.lines -= 1
        else:
            pass

        # reset maxchars, chars
        # limit line length when we need room for a page number
        # at least a space, a number indicator, the digits
        # Sloppy: assumes ASCII number translates to additional
        # character, the number sign (#)
        if self.lines == 1:
            self.maxchars = self.width - (Cursor.page_num_sep + 1 + len(str(self.page_num)))
        else:
            self.maxchars = self.width

        self.chars = self.maxchars
        # falling off page end provokes new page
        if self.lines == 0:
            self.new_page()

    def advance(self, nchars):
        # do not do this unless there is room
        # does not provoke a new line
        self.chars -= nchars
        if self.chars < 0:
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
        self.default_size = width
        self.size = self.default_size

    # Properties

    def max_width(self):
        return self.default_size

    def is_room(self, text):
        return len(self.contents) + len(text) <= self.size

    def is_empty(self):
        return self.contents == ''

    def remaining_chars(self):
        return self.size - len(self.contents)

    # Actions

    def add(self, text):
        self.contents += text

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

    def reset(self, size):
        self.contents = ''
        self.size = size

class Segment:

    def __init__(self, s):

        self.xml = s

        # decipher, record attributes
        attrs = s.attrib
        if ("newpage" in attrs) and (attrs["newpage"] == "yes"):
            self.newpage = True
        else:
            self.newpage = False

        if ("centered" in attrs) and (attrs["centered"] == "yes"):
            self.centered = True
        else:
            self.centered = False

        if ("breakable" in attrs) and (attrs["breakable"] == "no"):
            self.breakable = False
        else:
            self.breakable = True

        if "indentation" in attrs:
            self.indentation = attrs["indentation"]
        else:
            self.indentation = 0

        if "runover" in attrs:
            self.runover = attrs["runover"]
        else:
            self.runover = 0

        if "lines-before" in attrs:
            self.lines_before = attrs["lines-before"]
        else:
            self.lines_before = 0

        if "lines-after" in attrs:
            self.lines_after = attrs["lines-after"]
        else:
            self.lines_after = 0

        if "lines-following" in attrs:
            self.lines_following = attrs["lines-following"]
        else:
            self.lines_following = 0


class BRF:

    # spaces prior to a page number, duplicated in Cursor
    page_num_sep = 3

    # We need to connect the "trans1" emphasis scheme of the liblouis
    # "en-ueb-g1.ctb" table with a typeform bit we can use to switch
    # to this variant when we translate inline code phrases
    trans1_bit = louis.getTypeformForEmphClass(["en-ueb-g2.ctb"], 'trans1')

    def __init__(self, page_format, width, height):
        self.out_buffer = ''
        self.cursor = Cursor(width, height, page_format)
        self.line_buffer = LineBuffer(width)

    # Properties (boolean functions) reported
    # by the current line buffer or default/embedded cursor

    def is_room_on_line(self, text):
        return self.line_buffer.is_room(text)

    def at_line_start(self):
        return self.line_buffer.is_empty()

    # Provisional
    def is_room_on_page(self, segment):
        import copy

        orginal_cursor = self.cursor
        trial_brf = copy.deepcopy(self)
        # all changes (cursor movement, text-wrapping) will
        # occur in the temporary/trial/throwaway cursor
        trial_brf.process_segment(segment)
        trial_cursor = trial_brf.cursor

        # print("OC", orginal_cursor.page_num)
        # print("TC", trial_cursor.page_num)

        return not(orginal_cursor.page_num + 1 == trial_cursor.page_num)

    # Actions

    def adjust_width(self, adjustment):
        # Temporarily adjust the width of a page
        # For example, to construct a centered heading
        # Argument is an adjustment to current (negative, then positive?)
        self.line_buffer.size += adjustment
        self.cursor.maxchars  += adjustment
        # Reset counters as well
        self.cursor.chars = self.cursor.maxchars

    def write(self, text):
        self.out_buffer += text

    def advance_one_line(self):
        # We need a braille version of the page number, for actual
        # printing on the last line, or for adjusting the size of
        # the line buffer for the last line prior to its formation.
        if (self.cursor.remaining_lines() == 1) or (self.cursor.remaining_lines() == 2):
            num = str(self.cursor.page_number())
            braille_num = self.translate_segment('text', num)

        # before leaving line, possibly add a page number
        if self.cursor.remaining_lines() == 1:
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
        # record the advance to new line
        self.cursor.new_line()

        # If now on last line, use a reduced buffer
        # so there will be room for a page number
        if self.cursor.remaining_lines() == 1:
            buffer_width = self.line_buffer.max_width() - (BRF.page_num_sep + len(braille_num))
        else:
            buffer_width = self.line_buffer.max_width()
        # reset the buffer for subsequent line
        self.line_buffer.reset(buffer_width)

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

        # File is global temporarily
        global brf_file

        for i in range(self.cursor.remaining_lines()):
            self.advance_one_line()
        self.to_file(brf_file)
        if self.cursor.emboss:
            assert self.cursor.at_page_start(), "Page advance did not reach exactly the start of a new page"

    def write_word(self, word):
        # This assumes there is room on the current line
        # so no adjustments are made to the cursor
        assert self.line_buffer.remaining_chars() == self.cursor.remaining_characters(), "Cursor and LineBuffer have desynced"
        self.cursor.advance(len(word))
        self.line_buffer.add(word)

    def write_fragment(self, typeface, aline, math_punctuation):

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
                pad = " " * ((self.line_buffer.size - len(line))//2)
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

        if s.newpage and self.cursor.emboss:
            self.advance_page()

        # Lines before (but not if at the start of a page)
        if not(self.cursor.at_page_start()):
            for i in range(int(s.lines_before)):
                self.blank_line()

        # Lead with any indentation on first line
        indentation = " " * int(s.indentation)
        self.write_fragment("text", indentation, None)

        # Centered
        # [BANA 2016],  4.4.2
        # At least three blank cells must precede and follow a centered heading.
        #
        # So shrink line buffer to get extra space
        if s.centered:
            self.adjust_width(-6)

        sxml = s.xml
        if sxml.text:
            self.write_fragment("text", sxml.text, None)
        children = list(sxml)
        for c in children:
            if c.text:
                if 'punctuation' in c.attrib:
                    math_punctuation = c.attrib['punctuation']
                else:
                    math_punctuation = None
                self.write_fragment(c.tag, c.text, math_punctuation)
            if c.tail:
                self.write_fragment("text", c.tail, None)
        # finished with a segment
        # flush buffer, move to new line, maybe a new page
        # BUT not if we landed in this state anyway
        if not(self.at_line_start()):
            self.advance_one_line()
        # Necessary to restore for subsequent centering
        if s.centered:
            self.adjust_width(6)
        # Lines after
        for i in range(int(s.lines_after)):
            self.blank_line()
        # post-process before any use
        if s.centered:
            self.center()

    def massage_math(self, aline, punctuation):

        # available width will change across lines,
        # so this assumption is mildly flawed
        width = self.line_buffer.default_size

        # Unicode versions of Nemeth switch indicators.
        # We control separating spaces below as a way to
        # influence line-breaking for inline math
        # Note: maybe make these into class variables
        nemeth_open = "\u2838\u2829"
        nemeth_close = "\u2838\u2831"

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

    # File operations

    def to_file(self, out_file):
        out_file.write(self.out_buffer)
        self.out_buffer = ''

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
            print("BUG: did not recognize typeface", typeface)
            # Just to keep going while developing, if necessary
            # typeforms = None

        return louis.translateString(tableList, aline, typeforms, 0)



# Current entry point, sort of
def parse_segments(xml_simple, out_file, page_format):

    # Embossed, page shape
    brf = BRF(page_format, 40,25)

    # We assume `out_file` has been error-checked
    # It would be better to use a context manager
    brf_file = open(out_file, "w")

    # this routine converts XML information into arguments
    # to Python routines, but not exclusively yet

    huge_parser = ET.XMLParser(huge_tree=True)
    src_tree = ET.parse(xml_simple, parser=huge_parser)

    segments = src_tree.xpath("//segment")

    for s in segments:
        brf.process_segment(s)
        brf.to_file(brf_file)

    brf_file.close()

