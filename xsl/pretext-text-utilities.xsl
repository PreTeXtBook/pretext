<?xml version='1.0'?>

<!--********************************************************************
Copyright 2022 Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- Indicated basic utilities are from:                      -->
<!-- XSLT Cookbook, 2nd Edition                               -->
<!-- Copyright 2006, O'Reilly Media, Inc.                     -->
<!--                                                          -->
<!-- From the section of the Preface, "Using Code Examples":  -->
<!-- "You do not need to contact us for permission unless     -->
<!-- you're reproducing a significant portion of the code.    -->
<!-- For example, writing a program that uses several chunks  -->
<!-- of code from this book does not require permission."     -->

<!-- This stylesheet is meant to xsl:include'd into other stylesheets.     -->
<!-- All the templates were once part of "pretext-common.xsl" (2022-03-27) -->
<!-- and so are being included at the point where the vast majority were   -->
<!-- originally created.  Perhaps the include can move to a more obvious   -->
<!-- location near the top of that file.  There is no entry template and   -->
<!-- every template is a named template which relies on parameters, not    -->
<!-- context or a match/select mechanism.  (With some exceptions.)         -->
<!--                                                                       -->
<!-- Used in:                                                              -->
<!--     xsl/pretext-common.xsl (2022-03-27)                               -->
<!--     xsl/pretext/pretext-runestone-static.xsl (2022-03-28)             -->

<!-- There are &LOWERCASE; and &UPPERCASE; entities  -->
<!-- in the "file-extension" template (only?) -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- EXSL needed for token list template (only?) -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="pi str"
>

<!-- ########################## -->
<!-- Text Manipulation Routines -->
<!-- ########################## -->

<!-- Various bits of textual material            -->
<!-- (eg Sage, code, verbatim, LaTeX)            -->
<!-- require manipulation to                     -->
<!--                                             -->
<!--   (a) behave in some output format          -->
<!--   (b) produce human-readable output (LaTeX) -->

<!-- We need to identify particular characters   -->
<!-- space, tab, carriage return, newline        -->
<xsl:variable name="whitespaces">
    <xsl:text>&#x20;&#x9;&#xD;&#xA;</xsl:text>
</xsl:variable>

<!-- Sanitize Code -->
<!-- No leading whitespace, no trailing -->
<!-- http://stackoverflow.com/questions/1134318/xslt-xslstrip-space-does-not-work -->
<!-- Trim all whitespace at end of code hunk -->
<!-- Append carriage return to mark last line, remove later -->
<xsl:template name="trim-end">
   <xsl:param name="text"/>
   <xsl:variable name="last-char" select="substring($text, string-length($text), 1)" />
   <xsl:choose>
        <xsl:when test="$last-char=''">
            <xsl:text>&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="contains($whitespaces, $last-char)">
            <xsl:call-template name="trim-end">
                <xsl:with-param name="text" select="substring($text, 1, string-length($text) - 1)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text" />
            <xsl:text>&#xA;</xsl:text>
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- Trim all totally whitespace lines from beginning of code hunk -->
<xsl:template name="trim-start-lines">
   <xsl:param name="text"/>
   <xsl:param name="pad" select="''"/>
   <xsl:variable name="first-char" select="substring($text, 1, 1)" />
   <xsl:choose>
        <!-- Possibly nothing, return just final carriage return -->
        <xsl:when test="$first-char=''">
            <xsl:text>&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="$first-char='&#xA;'">
            <xsl:call-template name="trim-start-lines">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="contains($whitespaces, $first-char)">
            <xsl:call-template name="trim-start-lines">
                <xsl:with-param name="text" select="substring($text, 2)" />
                <xsl:with-param name="pad"  select="concat($pad, $first-char)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="concat($pad, $text)" />
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- Compute length of indentation of first line                   -->
<!-- Assumes no leading blank lines                                -->
<!-- Assumes each line, including last, ends in a carriage return  -->
<xsl:template name="count-pad-length">
   <xsl:param name="text"/>
   <xsl:param name="pad" select="''"/>
   <xsl:variable name="first-char" select="substring($text, 1, 1)" />
   <xsl:choose>
        <xsl:when test="$first-char='&#xA;'">
            <xsl:value-of select="string-length($pad)" />
        </xsl:when>
        <xsl:when test="contains($whitespaces, $first-char)">
            <xsl:call-template name="count-pad-length">
                <xsl:with-param name="text" select="substring($text, 2)" />
                <xsl:with-param name="pad"  select="concat($pad, $first-char)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="string-length($pad)" />
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- Compute width of left margin        -->
<!-- Assumes each line ends in a newline -->
<!-- A blank line will not contribute    -->
<xsl:template name="left-margin">
    <xsl:param name="text" />
    <xsl:param name="margin" select="32767" />  <!-- 2^15 - 1 as max? -->
    <xsl:choose>
        <xsl:when test="$text=''">
            <!-- Nothing left, then done, return -->
            <xsl:value-of select="$margin" />
        </xsl:when>
        <xsl:otherwise>
            <!-- Non-destructively count leading whitespace -->
            <xsl:variable name="pad-top-line">
                <xsl:call-template name="count-pad-length">
                    <xsl:with-param name="text" select="$text" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="content-top-line" select="substring-before($text, '&#xa;')" />
            <!-- Compute margin as smaller of incoming and computed -->
            <!-- Unless incoming is 0 due to blank line             -->
            <xsl:variable name="new-margin">
                <xsl:choose>
                    <xsl:when test="($margin > $pad-top-line) and not(string-length($content-top-line) = 0)">
                        <xsl:value-of select="$pad-top-line" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$margin" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- Recursive call with one less line, new margin -->
            <xsl:call-template name="left-margin">
                <xsl:with-param name="margin" select="$new-margin" />
                <xsl:with-param name="text" select="substring-after($text,'&#xA;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An "out-dented" line is assumed to be intermediate blank line     -->
<!-- indent parameter is a number giving number of characters to strip -->
<xsl:template name="strip-indentation">
    <xsl:param name="text" />
    <xsl:param name="indent" />
    <xsl:if test="$text != ''">
        <xsl:variable name="first-line" select="substring-before($text, '&#xA;')" />
        <xsl:if test="string-length($first-line) > $indent" >
            <xsl:value-of select="substring($first-line, $indent + 1)" />
        </xsl:if>
        <xsl:text>&#xA;</xsl:text>
        <xsl:call-template name="strip-indentation">
            <xsl:with-param name="text" select="substring-after($text, '&#xA;')" />
            <xsl:with-param name="indent" select="$indent" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Add a common string in front of every line of a block -->
<!-- Typically spaces to format output block for doctest   -->
<!-- indent parameter is a string                          -->
<!-- Assumes last character is xA                          -->
<!-- Result has trailing xA                                -->
<xsl:template name="add-indentation">
    <xsl:param name="text" />
    <xsl:param name="indent" />
    <xsl:if test="$text != ''">
        <xsl:value-of select="concat($indent,substring-before($text, '&#xA;'))" />
        <xsl:text>&#xA;</xsl:text>
        <xsl:call-template name="add-indentation">
            <xsl:with-param name="text" select="substring-after($text, '&#xA;')" />
            <xsl:with-param name="indent" select="$indent" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Main template for cleaning up hunks of raw text      -->
<!--                                                      -->
<!-- 1) Trim all trailing whitespace                      -->
<!-- 2) Add carriage return marker to last line           -->
<!-- 3) Strip all totally blank leading lines             -->
<!-- 4) Determine indentation of left-most non-blank line -->
<!-- 5) Strip indentation from all lines                  -->
<!-- 6) Allow intermediate blank lines                    -->

<xsl:template name="sanitize-text">
    <xsl:param name="text" />
    <xsl:variable name="trimmed-text">
        <xsl:call-template name="trim-start-lines">
            <xsl:with-param name="text">
                <xsl:call-template name="trim-end">
                    <xsl:with-param name="text" select="$text" />
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="left-margin">
        <xsl:call-template name="left-margin">
            <xsl:with-param name="text" select="$trimmed-text" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="strip-indentation" >
        <xsl:with-param name="text" select="$trimmed-text" />
        <xsl:with-param name="indent" select="$left-margin" />
    </xsl:call-template>
</xsl:template>

<!-- Substrings at last markers               -->
<!-- XSLT Cookbook, 2nd Edition               -->
<!-- Copyright 2006, O'Reilly Media, Inc.     -->
<!-- Recipe 2.4, nearly verbatim, reformatted -->
<xsl:template name="substring-before-last">
    <xsl:param name="input" />
    <xsl:param name="substr" />
    <xsl:if test="$substr and contains($input, $substr)">
        <xsl:variable name="temp" select="substring-after($input, $substr)" />
        <xsl:value-of select="substring-before($input, $substr)" />
        <xsl:if test="contains($temp, $substr)">
            <xsl:value-of select="$substr" />
            <xsl:call-template name="substring-before-last">
                <xsl:with-param name="input" select="$temp" />
                <xsl:with-param name="substr" select="$substr" />
            </xsl:call-template>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- If the substring is not contained, the first substring-after()   -->
<!-- will return empty and entire template will return empty.  To     -->
<!-- get the whole string, prepend $input with $substr prior to using -->
<xsl:template name="substring-after-last">
    <xsl:param name="input"/>
    <xsl:param name="substr"/>
    <!-- Extract the string which comes after the first occurrence -->
    <xsl:variable name="temp" select="substring-after($input,$substr)"/>
    <xsl:choose>
        <!-- If it still contains the search string then recursively process -->
        <xsl:when test="$substr and contains($temp,$substr)">
            <xsl:call-template name="substring-after-last">
                <xsl:with-param name="input" select="$temp"/>
                <xsl:with-param name="substr" select="$substr"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$temp"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Duplicating Strings                      -->
<!-- XSLT Cookbook, 2nd Edition               -->
<!-- Copyright 2006, O'Reilly Media, Inc.     -->
<!-- Recipe 2.5, nearly verbatim, reformatted -->
<xsl:template name="duplicate-string">
     <xsl:param name="text" />
     <xsl:param name="count" select="1" />
     <xsl:choose>
          <xsl:when test="not($count) or not($text)" />
          <xsl:when test="$count = 1">
               <xsl:value-of select="$text" />
          </xsl:when>
          <xsl:otherwise>
               <!-- If $count is odd, append one copy of input -->
               <xsl:if test="$count mod 2">
                    <xsl:value-of select="$text" />
               </xsl:if>
               <!-- Recursively apply template, after -->
               <!-- doubling input and halving count  -->
               <xsl:call-template name="duplicate-string">
                    <xsl:with-param name="text" select="concat($text,$text)" />
                    <xsl:with-param name="count" select="floor($count div 2)" />
               </xsl:call-template>
          </xsl:otherwise>
     </xsl:choose>
</xsl:template>

<!-- Prepending Strings -->
<!-- Add  count  copies of the string  pad  to  each line of  text -->
<!-- Presumes  text  has a newline character at the very end       -->
<xsl:template name="prepend-string">
    <xsl:param name="text" />
    <xsl:param name="pad" />
    <xsl:param name="count" select="1" />
    <xsl:variable name="bigpad">
        <xsl:call-template name="duplicate-string">
            <xsl:with-param name="text" select="$pad" />
            <xsl:with-param name="count" select="$count" />
        </xsl:call-template>
    </xsl:variable>
    <!-- Quit when string becomes empty -->
    <xsl:if test="string-length($text)">
        <xsl:variable name="first-line" select="substring-before($text, '&#xa;')" />
        <xsl:value-of select="$bigpad" />
        <xsl:value-of select="$first-line" />
        <xsl:text>&#xa;</xsl:text>
        <!-- recursive call on remaining lines -->
        <xsl:call-template name="prepend-string">
            <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            <xsl:with-param name="pad" select="$bigpad" />
            <xsl:with-param name="count" select="1" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Counting Substrings -->
<xsl:template name="count-substring">
    <xsl:param name="text" />
    <xsl:param name="word" />
    <xsl:param name="count" select="'0'" />
    <xsl:choose>
        <xsl:when test="not(contains($text, $word))">
            <xsl:value-of select="$count" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="count-substring">
                <xsl:with-param name="text" select="substring-after($text, $word)" />
                <xsl:with-param name="word" select="$word" />
                <xsl:with-param name="count" select="$count + 1" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Remove empty lines -->
<!-- These are lines with no characters -->
<!-- at all, just a newline             -->
<!-- 2017-01-22: UNUSED, UNTESTED, incorporate with caution  -->
<xsl:template name="strip-empty-lines">
    <xsl:param name="text" />
    <xsl:choose>
        <!-- no more splitting, output $text, empty or not -->
        <xsl:when test="not(contains($text, '&#xa;'))">
            <xsl:value-of select="$text" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="firstline" select="substring-before($text, '&#xa;')" />
            <xsl:choose>
                <!-- silently drop an empty line, newline already gone -->
                <xsl:when test="not($firstline)" />
                <!-- output first line with restored newline -->
                <xsl:otherwise>
                    <xsl:value-of select="concat($firstline, '&#xa;')" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- recurse with remainder -->
            <xsl:call-template name="strip-empty-lines">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Gobble leading whitespace -->
<!-- Drop consecutive leading spaces and tabs, only     -->
<!-- Designed for a single line as input                -->
<!-- Used after maniplating sentence ending punctuation -->
<xsl:template name="strip-leading-blanks">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- if empty, done -->
        <xsl:when test="not($first-char)" />
        <!-- first character is space, tab, drop it -->
        <xsl:when test="contains('&#x20;&#x9;', $first-char)">
            <xsl:call-template name="strip-leading-blanks">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- finished stripping, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Shove text left -->
<!-- Remove all leading whitespace from every line -->
<!-- Note: very similar to "sanitize-latex" below           -->
<!-- 2017-01-22: UNUSED, UNTESTED, incorporate with caution -->
<xsl:template name="slide-text-left">
    <xsl:param name="text" />
    <xsl:choose>
        <!-- no more splitting, strip leading whitespace -->
        <xsl:when test="not(contains($text, '&#xa;'))">
            <xsl:call-template name="strip-leading-blanks">
                <xsl:with-param name="text">
                    <xsl:value-of select="$text" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="strip-leading-blanks">
                <xsl:with-param name="text" select="concat(substring-before($text, '&#xa;'), '&#xa;')" />
            </xsl:call-template>
            <!-- recurse with remainder -->
            <xsl:call-template name="slide-text-left">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Sanitize Nemeth Braille -->
<!-- We receive Nemeth braille from MathJax and Speech Rule Engine (SRE) as -->
<!--                                                                        -->
<!--   1. Optional indentation U+2800 for second, and subsequent lines of   -->
<!--      2D layout display math                                            -->
<!--   2. Actual content with U+2800 as spaces                              -->
<!--   3. An optional run of U+2800 to form a uniform right margin for      -->
<!--      (eventual) 2D physical devices.                                   -->
<!--                                                                        -->
<!--  To play nice with liblouis we let U+2800 be an unbreakable space      -->
<!--  and U+0020 ("regular" space) be a breakable space.  So                -->
<!--    -->
<!--   1.  We preserve indentation as unbreakable spaces.                   -->
<!--   2.  We convert content spaces to "regular" spaces.  In some cases    -->
<!--       we make convert them back to unbreakable spaces.                 -->
<!--   3.  We drop trailing (right margin) whitespace, as unnecessary,      -->
<!--       and even problematic.                                            -->


<!-- Break on newlines.  Trim trailing whitespace, massage whitespace in   -->
<!-- remainder.  Reconstitute with same patter of newlines.  Note: for     -->
<!-- single-line braille from SRE there is no indentation and no trailing  -->
<!-- whitespace for a right margin.                                        -->
<!-- NB: "otherwise" might be simpler if some conditioning was different   -->
<!-- in the "when.                                                         -->

<xsl:template name="sanitize-nemeth-braille">
    <xsl:param name="text"/>
    <xsl:choose>
        <xsl:when test="contains($text, '&#xa;')">
            <xsl:variable name="one-line" select="substring-before($text, '&#xa;')"/>
            <!-- strip end of a single line of U+2800, a braille empty cell -->
            <xsl:variable name="end-trimmed">
                <xsl:call-template name="trim-nemeth-trailing-whitespace">
                    <xsl:with-param name="text" select="$one-line"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="convert-nemeth-whitespace">
                <xsl:with-param name="text" select="$end-trimmed"/>
            </xsl:call-template>
            <!-- restore "split-out" newline -->
            <xsl:text>&#xa;</xsl:text>
            <!-- recursively process remainder -->
            <xsl:call-template name="sanitize-nemeth-braille">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <!-- last line, needs manipulation -->
            <xsl:variable name="end-trimmed">
                <xsl:call-template name="trim-nemeth-trailing-whitespace">
                    <xsl:with-param name="text" select="$text"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="convert-nemeth-whitespace">
                <xsl:with-param name="text" select="$end-trimmed"/>
            </xsl:call-template>
            <!-- no newline to restore     -->
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Work in from right margin, dropping consecutive U+2800 -->
<xsl:template name="trim-nemeth-trailing-whitespace">
   <xsl:param name="text"/>
   <xsl:variable name="last-char" select="substring($text, string-length($text), 1)" />
   <xsl:choose>
        <xsl:when test="$last-char = '&#x2800;'">
            <xsl:call-template name="trim-nemeth-trailing-whitespace">
                <xsl:with-param name="text" select="substring($text, 1, string-length($text) - 1)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- Work in from the left.  The $b-indentation boolean signals that       -->
<!-- the last character examined was a U+2800 from the run of indentation  -->
<!-- (which we simply duplicate).  It begins true as the default value,    -->
<!-- which is not present in initial call.  Once it flips false, it stays  -->
<!-- false.  Spaces within content convert to "regular" spaces.            -->
<!-- Note: once $b-indentation flips false, we could just do a             -->
<!-- search/replace on the string to output with a "value-of"              -->

<xsl:template name="convert-nemeth-whitespace">
   <xsl:param name="text"/>
   <xsl:param name="b-indentation" select="true()"/>

   <xsl:choose>
        <xsl:when test="$text">
            <xsl:variable name="first-char" select="substring($text, 1, 1)"/>
            <xsl:variable name="b-found-indentation" select="$b-indentation and ($first-char = '&#x2800;')"/>
            <xsl:choose>
                <!-- echo a leading U+2800 in the indentation-->
                <xsl:when test="$b-found-indentation">
                    <xsl:text>&#x2800;</xsl:text>
                </xsl:when>
                <!-- convert space in content into a regular space -->
                <xsl:when test="$first-char = '&#x2800;'">
                    <xsl:text>&#x0020;</xsl:text>
                </xsl:when>
                <!-- echo any other character -->
                <xsl:otherwise>
                    <xsl:value-of select="$first-char"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- Recurse with all but the first character -->
            <xsl:call-template name="convert-nemeth-whitespace">
                <xsl:with-param name="text" select="substring($text, 2, string-length($text) - 1)"/>
                <xsl:with-param name="b-indentation" select="$b-found-indentation"/>
            </xsl:call-template>
        </xsl:when>
        <!-- $text is empty string, done -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>


<!-- Sanitize LaTex -->
<!-- We allow authors to include whitespace for readability          -->
<!--                                                                 -->
<!-- (1) Newlines used to format complicated math (eg matrices)      -->
<!-- (2) Newlines used to avoid word-wrapping in editing tools       -->
<!-- (3) Newlines to support atomic version control changesets       -->
<!-- (4) Source indentation of above, consonant with XML indentation -->
<!--                                                                 -->
<!-- But once we form LaTeX output we want to                        -->
<!--                                                                 -->
<!--   (i)   Remove 100% whitespace lines                            -->
<!--   (ii)  Remove leading whitespace                               -->
<!--   (iii) Finish without a newline                                -->
<!--                                                                 -->
<!-- So we                                                           -->
<!--                                                                 -->
<!-- (a) Strip all leading whitespace                                -->
<!-- (b) Remove any 100% resulting empty lines (newline only)        -->
<!-- (c) Preserve remaining newlines (trailing after content)        -->
<!-- (d) Preserve remaining whitespace (eg, within expressions)      -->
<!-- (e) Take care with trailing characters, except final newline    -->
<!--                                                                 -->
<!-- We can do this because of the limited purposes of the           -->
<!-- m, me, men, md, mdn elements.  The whitespace we strip is not   -->
<!-- relevant/important, and what we leave does not change output    -->
<xsl:template name="sanitize-latex">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- empty, end recursion -->
        <xsl:when test="$first-char = ''" />
        <!-- first character is whitespace, including newline -->
        <!-- silently drop it as we recurse on remainder      -->
        <xsl:when test="contains($whitespaces, $first-char)">
            <xsl:call-template name="sanitize-latex">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- content followed by newline                           -->
        <!-- split, preserve newline, output, and recurse, but     -->
        <!-- drop a newline that only protects trailing whitespace -->
        <xsl:when test="contains($text, '&#xa;')">
            <xsl:value-of select="substring-before($text, '&#xa;')" />
            <xsl:variable name="remainder" select="substring-after($text, '&#xa;')" />
            <xsl:choose>
                <xsl:when test="normalize-space($remainder) = ''" />
                <xsl:otherwise>
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="sanitize-latex">
                        <xsl:with-param name="text" select="$remainder" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- content, no following newline -->
        <!-- output in full, end recursion -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This collects "clause-ending" punctuation     -->
<!-- from the *front* of a text node.  It does not -->
<!-- change the text node, but simply outputs the  -->
<!-- punctuation for use by another template       -->
<xsl:template name="leading-clause-punctuation">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- empty, quit -->
        <xsl:when test="not($first-char)" />
        <!-- if punctuation, output and recurse -->
        <!-- else silently quit recursion       -->
        <xsl:when test="contains($clause-ending-marks, $first-char)">
            <xsl:value-of select="$first-char" />
            <xsl:call-template name="leading-clause-punctuation">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- consecutive only, stop collecting -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<!-- If we absorb punctuation, we need to scrub it by    -->
<!-- examining and manipulating the text node with       -->
<!-- those characters.  We drop consecutive punctuation. -->
<xsl:template name="drop-clause-punctuation">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- if empty, done -->
        <xsl:when test="not($first-char)" />
        <!-- first character ends sentence, drop it, recurse -->
        <xsl:when test="contains($clause-ending-marks, $first-char)">
            <xsl:call-template name="drop-clause-punctuation">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- no more punctuation, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Remove consecutive run of blanks and  -->
<!-- newlines in first portion of a string -->
<xsl:template name="strip-leading-whitespace">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- if empty, quit -->
        <xsl:when test="not($first-char)" />
        <!-- if first character is whitespace, drop it -->
        <xsl:when test="contains($whitespaces, $first-char)">
            <xsl:call-template name="strip-leading-whitespace">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- else finished stripping, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Remove consecutive run of blanks and -->
<!-- newlines in last portion of a string -->
<xsl:template name="strip-trailing-whitespace">
    <xsl:param name="text" />
    <xsl:variable name="last-char" select="substring($text, string-length($text), 1)" />
    <xsl:choose>
        <!-- if empty, quit -->
        <xsl:when test="not($last-char)" />
        <!-- if last character is whitespace, drop it -->
        <xsl:when test="contains($whitespaces, $last-char)">
            <xsl:call-template name="strip-trailing-whitespace">
                <xsl:with-param name="text" select="substring($text, 1, string-length($text)-1)" />
            </xsl:call-template>
        </xsl:when>
        <!-- else finished stripping, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- spurious newlines introduce whitespace on either side -->
<!-- we split at newlines, strip consecutive whitesapce on either side, -->
<!-- and replace newlines by spaces (could restore a single newline) -->
<xsl:template name="strip-newlines">
    <xsl:param name="text" />
    <xsl:choose>
        <!-- if has newline, modify newline-free front portion -->
        <!-- replace splitting newline with new separator      -->
        <!-- modify trailing portion, and recurse with it      -->
        <xsl:when test="contains($text, '&#xa;')">
            <!-- clean trailing portion of left half -->
            <xsl:call-template name="strip-trailing-whitespace">
                <xsl:with-param name="text" select="substring-before($text, '&#xa;')" />
            </xsl:call-template>
            <!-- restore a separator, blank now -->
            <!-- Note: this could be a newline, perhaps optionally (whitespace="breaks") -->
            <!-- Note: this could be " %\n" in LaTeX output to be super explicit -->
            <xsl:text> </xsl:text>
            <!-- recurse with modified right half -->
            <xsl:call-template name="strip-newlines">
                <xsl:with-param name="text">
                    <!-- clean leading portion of right half -->
                    <xsl:call-template name="strip-leading-whitespace">
                        <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:when>
        <!-- else finished stripping, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- JSON Escaped Strings -->
<!-- Convert a string, just prior to dropping it into a  -->
<!-- JSON data structure, so this presumes nothing       -->
<!-- special has been done with the contents before-hand -->
<!-- In order converted, using the standard JSON names:  -->
<!--     reverse solidus (backslash), solidus (slash),   -->
<!--     quotation mark, backspace, horizontal tab,      -->
<!--     newline, form feed, carriage return             -->
<!-- Escaping solidus (forward slash) is only necessary  -->
<!-- for <\ inside a script tag (or similar?)  It makes  -->
<!-- URLs ugly, but we do it anyway so we don't get bit. -->
<!-- Strictly needed:  backslash, double quote, newline. -->
<!-- XSLT3:                                              -->
<!-- But XML 1.0 does not allow x08 (backspace) and x0c  -->
<!-- (form feed) so we ignore them for now.  Perhaps see -->
<!-- https://stackoverflow.com/questions/404107/         -->
<!-- why-are-control-characters-illegal-in-xml-1-0       -->
<xsl:template name="escape-json-string">
    <xsl:param name="text"/>

    <!-- backslash first since it will be introduced -->
    <!-- later as the escape character itself        -->
    <xsl:variable name="sans-backslash" select="str:replace($text,           '\',      '\\'     )"/>
    <xsl:variable name="sans-slash"     select="str:replace($sans-backslash, '/',      '\/'     )"/>
    <xsl:variable name="sans-quote"     select="str:replace($sans-slash,     '&#x22;', '\&#x22;')"/>
<!--<xsl:variable name="sans-backspace" select="str:replace($sans-quote,     '&#x08;', '\b'     )"/>-->
    <xsl:variable name="sans-tab"       select="str:replace($sans-quote,     '&#x09;', '\t'     )"/>
    <xsl:variable name="sans-newline"   select="str:replace($sans-tab,       '&#x0a;', '\n'     )"/>
<!--<xsl:variable name="sans-formfeed"  select="str:replace($sans-newline,   '&#x0c;', '\f'     )"/>-->
    <xsl:variable name="sans-return"    select="str:replace($sans-newline,   '&#x0d;', '\r'     )"/>

    <xsl:value-of select="$sans-return" />
</xsl:template>

<!-- File Extension -->
<!-- Input: full filename                       -->
<!-- Output: extension (no period), lowercase'd -->
<!-- Note: appended query string is stripped    -->
<xsl:template name="file-extension">
    <xsl:param name="filename" />
    <!-- Add a question mark, then grab leading substring -->
    <!-- This will fail if "?" is encoded                 -->
    <xsl:variable name="no-query-string" select="substring-before(concat($filename, '?'), '?')" />
    <!-- get extension after last period   -->
    <!-- will return empty if no extension -->
    <xsl:variable name="extension">
        <xsl:call-template name="substring-after-last">
            <xsl:with-param name="input" select="$no-query-string" />
            <xsl:with-param name="substr" select="'.'" />
        </xsl:call-template>
    </xsl:variable>
    <!-- to lowercase -->
    <xsl:value-of select="translate($extension, &UPPERCASE;, &LOWERCASE;)" />
</xsl:template>

<!-- ################# -->
<!-- String Utilities -->
<!-- ################# -->

<!-- Find a delimiter: find a character that can be wrapped around a string -->
<!-- Take a string as one input and a list of characters as another input   -->
<!-- Return the first character from the list that is not in the string     -->
<xsl:template name="find-unused-character">
    <xsl:param name="string" select="''"/>
    <!-- set of characters passed in the original call -->
    <xsl:param name="charset" select="concat($apos,'&quot;|/!?=~')"/>
    <!-- reduced set of characters still in play during a recursive iteration  -->
    <xsl:param name="characters" select="$charset"/>
    <xsl:choose>
        <xsl:when test="$characters = ''">
            <xsl:message>PTX:FATAL:   Unable to find an unused character in:&#xa;<xsl:value-of select="$string" />&#xa;using characters from: <xsl:value-of select="$charset" /></xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <xsl:message terminate="yes">             That's fatal.  Sorry.  Quitting...</xsl:message>
        </xsl:when>
        <xsl:when test="not(contains($string,substring($characters,1,1)))">
            <xsl:value-of select="substring($characters,1,1)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="find-unused-character">
                <xsl:with-param name="string" select="$string"/>
                <xsl:with-param name="charset" select="$charset"/>
                <xsl:with-param name="characters" select="substring($characters,2)"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############### -->
<!-- Token Utilities -->
<!-- ############### -->

<!-- The "tokenize()" function could replace this? -->
<!-- And then dependence on EXSL might be removed. -->

<!-- Routines that can be employed in a recursive      -->
<!-- formulation to process a string (attribute value, -->
<!-- usually) that is separated by spaces or by commas -->

<!-- Replace commas by blanks, constrict blanks to singletons, -->
<!-- add trailing blank for last step of iteration             -->
<xsl:template name="prepare-token-list">
    <xsl:param name="token-list" />
    <xsl:value-of select="concat(normalize-space(str:replace($token-list, ',', ' ')), ' ')" />
</xsl:template>

<!-- Now, to work through the $token-list                          -->
<!--   1. If $token-list = '', end recursion                       -->
<!--   2. Process substring-before($token-list, ' ') as next token -->
<!--   3. Pass substring-after($token-list, ' ') recursively       -->


<!-- ################################## -->
<!-- Runestone Services General Support -->
<!-- ################################## -->

<!-- Some items that are in play relative to Runestone Services -->
<!-- that are independendt of dynamic/static and which can      -->
<!-- promote consistence if defined only once.  End game is the -->
<!-- text of a datafile, so appropriate here.  However, they    -->
<!-- are a bit different than above in spirit, as they involve  -->
<!-- global variables, file manipulations, and are not named    -->
<!-- templates generally.  They are necessary to create static  -->
<!-- versions of Runestone datafile elements during the         -->
<!-- assembly phase, and the enhanced-source stylesheet avoids  -->
<!-- using -common, hence movement here on 2023-10-30.          -->

<!-- Datafiles have default rows and columns -->
<xsl:variable name="datafile-default-rows" select="20"/>
<xsl:variable name="datafile-default-cols" select="60"/>

<!-- The contents of a datafile may be encoded as text in an XML   -->
<!-- file within the generated/datafile directory.  The filename   -->
<!-- has this construction, even if we do not always consult it.   -->
<!-- NB: these XML files will be read with a "document()" call,    -->
<!-- with a path relative to the author's main source file, hence  -->
<!-- the filename uses the directory name in author's source.      -->
<!-- NB: identical code in static constructions.                   -->
<xsl:template match="datafile" mode="datafile-filename">
    <xsl:value-of select="$generated-directory-source"/>
    <xsl:text>datafile/</xsl:text>
    <!-- context is "datafile", the basis for identifier -->
    <xsl:apply-templates select="." mode="visible-id"/>
    <xsl:text>.xml</xsl:text>
</xsl:template>

<!-- Get a "view" of a chunk of text, from the "upper-left corner".  -->
<!-- Motivation is a static version of a (large) datafile of text    -->
<!-- for interactive programs to consume.                            -->
<!--   text: the text, we provide a version hit by "santitize-tex"   -->
<!--         above, which pulls left, and drops leading blank lines. -->
<!--   nrows: the number of (initial) lines output                   -->
<!--   ncols: the number of (initial) characters on each line        -->
<!--          if not provided, the entire line is output             -->
<!--                                                                 -->
<!-- NB: there can be excess blank lines (nrows in not a maximum)    -->
<!-- TODO: could be extended to have a "start" location other than   -->
<!-- upper left corner.  Consume initial lines with no action,       -->
<!-- decrementing start line, then switch to outputing lines         -->
<!-- themselves.  Substring selection should be obvious.             -->
<xsl:template name="text-viewport">
    <xsl:param name="text"/>
    <xsl:param name="nrows"/>
    <xsl:param name="ncols" select="''"/>

    <xsl:choose>
        <!-- decremented (or initialized) to zero or below -->
        <xsl:when test="$nrows &lt; 1"/>
        <!-- produce a line and recurse -->
        <xsl:otherwise>
            <xsl:variable name="line" select="substring-before($text, '&#xa;')"/>
            <xsl:choose>
                <!-- sentinel: output whole line -->
                <xsl:when test="$ncols = ''">
                    <xsl:value-of select="$line"/>
                </xsl:when>
                <!-- within length limit: output whole line -->
                <xsl:when test="string-length($line) &lt;= $ncols">
                    <xsl:value-of select="$line"/>
                </xsl:when>
                <!-- truncate line to value of $ncols-1, and add  -->
                <!-- a simple right arrow to indicate truncation  -->
                <xsl:otherwise>
                    <xsl:value-of select="substring($line, 1, $ncols - 1)"/>
                    <!-- Unicode Character 'RIGHTWARDS ARROW' -->
                    <xsl:text>&#x2192;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <!-- restore the missing line-break -->
            <xsl:value-of select="'&#xa;'"/>
            <!-- rceurse, with remainder of text, requesting  -->
            <!-- one less row, and simply passing along ncols -->
            <xsl:call-template name="text-viewport">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')"/>
                <xsl:with-param name="nrows" select="$nrows - 1"/>
                <xsl:with-param name="ncols" select="$ncols"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The actual text contents of a "datafile", specified in a "pre" element.  -->
<!-- We assume (enforce) a "pre" child.  Then actual text comes authored in   -->
<!-- the source "pre" element or in an author-provided external file.         -->
<xsl:template match="datafile[pre]" mode="datafile-text-contents">
    <xsl:choose>
        <!-- via an external file -->
        <!-- Once upon a time, we hit the text from a file with   -->
        <!-- "sanitize-text".  This was a bad idea because        -->
        <!--   (a) the manipulations (especially pad-length (?) ) -->
        <!--       caused a false infinite recursion warning, and -->
        <!--   (b) the file should be *exactly* what is desired.  -->
        <xsl:when test="pre/@source">
            <!-- filename is relative to author's source -->
            <xsl:variable name="data-filename">
                <xsl:apply-templates select="."  mode="datafile-filename"/>
            </xsl:variable>
            <xsl:variable name="text-file-elt" select="document($data-filename, $original)/pi:text-file"/>
            <xsl:value-of select="$text-file-elt"/>
        </xsl:when>
        <!-- via source "pre" element content -->
        <xsl:otherwise>
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:value-of select="pre"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


</xsl:stylesheet>