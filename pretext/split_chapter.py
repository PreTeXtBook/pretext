#!/usr/bin/env python3

import re

brf_numbers = 'abcdefghij'
num_numbers = '1234567890'

brf_to_num_dict = dict(zip(brf_numbers,num_numbers))
num_to_brf_dict = dict(zip(num_numbers,brf_numbers))

# Wrapper class for chapter number, chapter page range,
# chapter body
class Chapter():
    def __init__(self,start_page_num, numbered_chapter,chapter_number): 
        self.start_page = start_page_num
        self.numbered = numbered_chapter
        self.number = chapter_number
        # Placeholder values
        self.end_page = -1
        self.body = []
        self.front_matter = True
        
    def get_body(self,pages):
        for page_num in range(self.start_page,self.end_page):
            self.body += pages[page_num]
            
    def write_body(self):
    # The last two cases will be used if we want to split frontmatter or backmatter
        if self.numbered:
            out_filename = f"chapter_{self.number}.brf"    
        elif self.front_matter:
            out_filename = f"frontmatter_{self.number}.brf"
        else:
            out_filename = f"backmatter_{self.number}.brf"

        with open(out_filename,'w') as g:
            g.writelines(self.body)
        
            
def brf_to_num(string):
    out = ''
    for char in string:
        out += brf_to_num_dict[char]
    return(int(out))

def num_to_brf(num):
    out = ''
    for char in str(num):
        out += num_to_brf_dict[char]
    return(out)


def is_chapter_name(line):
    # If a TOC line starts with two spaces followed by "," (capital letter sign) or "#"
    # then it is a chapter line
    if len(re.findall("^[ ]{2}[,|#]", line)) > 0:
        chapter_name = True
        if len(re.findall("^[ ]{2}#([a-j]+?) ", line)) > 0:
            numbered_chapter = True
            chapter_number = brf_to_num(re.findall("^[ ]{2}#([a-j]+?) ", line)[0])
        elif len(re.findall("^[ ]{2},\*apt} #([a-j]+?) ", line)) > 0:
            numbered_chapter = True
            chapter_number = brf_to_num(re.findall("^[ ]{2},\*apt} #([a-j]+?) ", line)[0])
        else:
            numbered_chapter = False
            chapter_number = -1
    else:
        chapter_name = False
        numbered_chapter = False
        chapter_number = -1
# Return whether the TOC line starts a chapter name, whether it is a numbered chapter
# and if yes, the chapter number (-1 if not a numbered chapter).
    return(chapter_name, numbered_chapter, chapter_number)


"""
Input line, output a pair (page_num_found, page_num)
The first is a Boolean; True if the page number is found on the line,
the second is an integer

Logic:

* Are there lead-to characters?

If yes, we win:
,foo ''''''' #abc
abc is the page of chapter 'foo'; the number at the end of the lead-to characters is the page number

If not, either the chapter name is too long to have lead-to characters, but the page number is there,
or the number will be on one of the next lines. There are two cases:

If the line is short <40 characters, then definitely the number is on a line below

If the line is not short, there are three subcases:
    * If the line ends with " #abc #de", then the first one is the chapter
        page number and the second is the TOC page number
    * If the line ends with only one number precedeed by more than 3 spaces, then the chapter page
        number is on a line below.
    * If the line ends with only one number precedeed by no more than 3 spaces, then this is the
        chapter page number.

This does take into account some crazy chapter names:
"Key algebro-topological properties of 42  123"
Asked Michael more about spacing, he is saying the Liblouis spacing
we have is incorrect.

"""
def find_chapter_page_num(line):
    # Are there lead-to characters " ' "?
    if len(re.findall(" [']{2,35} #",line)) > 0:
        m = re.search("[']{2,35} #(.+?)[ |\n]",line)

        return(True, brf_to_num(m.group(1)))
    elif len(line) < 40:
        return(False, -1)
    elif len(re.findall(" #([a-j]+?)  #[a-j]+?$",line)) > 0:
        page = brf_to_num(re.findall(" #([a-j]+?)  #[a-j]+?$",line)[0])
        return(True, page)
    elif len(re.findall("[ ]{4,35}#[a-j]+?$",line)) > 0:
        return(False, -1)
    elif len(re.findall("[ ]{1,3}#([a-j]+?)$",line)) > 0:
        page = brf_to_num(re.findall("[ ]{1,3}#([a-j]+?)$",line)[0])
        return(True, page)
    else:
        raise ValueError(f"A weird long TOC line found:\n{line}")

"""
The idea is to scan the BRF file for the word 'contents', or '3t5ts' in ASCII Braille
that appears on a short centered line. This would mark the beginning of the TOC.

Then keep scanning the TOC until we get the next chapter.
Adding running heads will mess with this! So need to revisit when that happens.


Will return three things: TOC, the entire front matter (ending with TOC), and the "body"
All are returned as lists of lines.
"""
def get_TOC(filename):
    f = open(filename,'r', encoding="latin-1")
    front_matter = [] # We want to keep the entire front matter up to and including TOC, it'll be one of the chunks
    TOC = [] # This will keep the TOC only
    text_body = [] # We want to get the text body, to be split into pages and then chapters

    is_contents = False

    while not is_contents:
        line = f.readline()
        front_matter.append(line)
        if line == '':
            raise ValueError("Reached the end of file while looking for Table of Contents")
        
        if len(re.findall("3t5ts",line)) > 0: # if a line contains the word 'contents', in the middle
            if re.search("3t5ts",line).start() > 10 and re.search("3t5ts",line).end() < 30:
                is_contents = True

    while is_contents:
        line = f.readline()
        
        if line == '':
            raise ValueError("Reached end of file while reading the Table of Contents")

        # Check if the line is likely centered and at the top of the page:
        trailing_spaces = 40 - len(line) - 2 # -2 for good luck
        pattern = f"\f[ ]{ {trailing_spaces} }"
        if len(re.findall(pattern,line)) == 0:
            # if not centered at the top, then add to the TOC list and move on
            TOC.append(line)
            front_matter.append(line)
        else:
            temp_line = line
            line = f.readline()
            
            if line == '\n':
                # if the line after the centered one is empty,
                # then we are likely at the start of the next chapter, so done with TOC
                is_contents = False
                text_body.append(temp_line)
                text_body.append(line)
            else:
                # False alarm
                TOC.append(temp_line)
                TOC.append(line)
                front_matter.append(temp_line)
                front_matter.append(line)

    while line != '':
        line = f.readline()
        text_body.append(line)

    f.close()
    return(TOC, front_matter, text_body)

"""
Scan TOC, if a Chapter line is detected (two spaces followed by [,|#] -- anything else?),
then look for a page number of the chapter and append to the list of chapter pages
"""

def get_chapter_list(TOC):
    chapter_list = []
    line_number = 0

    while line_number < len(TOC) - 1:
        line = TOC[line_number]
        (chapter_name, numbered_chapter, chapter_number) = is_chapter_name(line)
        if chapter_name:
            (page_num_found, start_page_num) = find_chapter_page_num(line)
            while not page_num_found:
                line_number += 1
                if line_number == len(TOC)-1:
                    raise ValueError("Reached end of TOC while looking for the page number")

                line = TOC[line_number]
                (page_num_found, start_page_num) = find_chapter_page_num(line)
                
            chapter_list.append(Chapter(start_page_num, numbered_chapter,chapter_number))
            
        line_number += 1
    return(chapter_list)



def split_body_into_pages(text_body):
    # text_body is a list of lines, let's make it into a dictionary of pages
    # Each element of 'pages' is a list of lines on the same page, indexed by the
    # number of the page in BRF file
    pages = dict()
    
    if len(re.findall("\f", text_body[0])) == 0:
        raise ValueError("Unexpected first line of body text: does not start with new page character")
    current_page = [text_body[0]]
    
    for number, line in enumerate(text_body[1:]):
        if line != '': # if we are not at the end
            if len(re.findall("\f", line)) == 0:
            # if we are not starting a new page
                current_page.append(line)            else: # get the page number of the current page, put it in dict and start a new current page
                prev_line = text_body[number] # not 'number - 1' because we are starting with text_body[1]

                if len(re.findall("[ ]{2}#([a-j]+?)$",prev_line)) == 0:
                    raise ValueError(f"Page number not found, expected to be on the line\n{prev_line}")
                    break
                else:
                    page_num = brf_to_num(re.findall("[ ]{2}#([a-j]+?)$",prev_line)[0])
                    pages[page_num] = current_page
                    current_page = [line]
        # if we are at the last line, nothing to be done
        
    return(pages)

    

def write_chapters(chapter_list, front_matter, text_body, \
                   split_frontmatter = False, split_backmatter = False):

    pages = split_body_into_pages(text_body)
    is_front_matter = True
    unnumbered_counter = 1
    back_matter = []
    
    for index in range(len(chapter_list)):
        # Assume that un-numbered chapters at the start are part of front matter.
        # Followed by numbered chapters
        # Followed by un-numbered back-matter

        chapter = chapter_list[index]
        # End page of a chapter is either the first page of the next chapter
        # (keeping in mind Python range conventions) or the last page of the document
        if index < len(chapter_list) - 1:
            chapter.end_page = chapter_list[index + 1].start_page
        else:
            chapter.end_page = max([num for num in pages.keys()]) + 1
        # Now we get the pages for each chapter:
        chapter.get_body(pages)
        
        if chapter.numbered:
            is_front_matter = False # Somewhat inefficient because we do it
            unnumbered_counter = 1  # more than once, but no harm
            
            chapter.write_body()
            
        elif is_front_matter:
            chapter.front_matter = True
            if split_frontmatter:
                chapter.number = unnumbered_counter
                chapter.write_body()
                unnumbered_counter += 1
            else:
                front_matter += chapter.body

        else: # Must be back matter
            chapter.front_matter = False
            if split_backmatter:
                chapter.number = unnumbered_counter
                chapter.write_body()
                unnumbered_counter += 1
            else:
                back_matter += chapter.body


        # Now everything was written except the TOC front matter and backmatter
        # if we were not splitting

        with open("frontmatter.brf",'w') as g:
            g.writelines(front_matter)
        if back_matter != []:
            with open("backmatter.brf",'w') as g:
                g.writelines(back_matter)

def _split_brf(filename):
    toc, frontmatter, bodytext = get_TOC(filename)
    chapters = get_chapter_list(toc)
    write_chapters(chapters, frontmatter, bodytext)


