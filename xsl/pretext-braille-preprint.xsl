<?xml version='1.0'?>

<!--********************************************************************
Copyright 2018 Robert A. Beezer

This file is part of MathBook XML.

MathBook XML is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

MathBook XML is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<!-- We choose to not include a default namespace       -->
<!-- (in particular  http://www.w3.org/1999/xhtml),     -->
<!-- even if this complicates adding namespaces onto    -->
<!-- derivatives, such as HTML destined for EPUB output -->
<!-- xmlns="http://www.w3.org/1999/xhtml"               -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="pi exsl date str"
>

<!-- Standard conversion groundwork -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- With @indent="yes" the (intermediate) file is much easier to study    -->
<!-- and debug, but it introduces whitespace we can not (or do not want    -->
<!-- to) control for.  The situation is a single isolated sentence that    -->
<!-- is entirely a font change.  Here "isolated" means it becomes an       -->
<!-- entire "segment", such as being between two "displays" when breaking  -->
<!-- up a paragraph.  For example, an entire sentence could be in italics, -->
<!-- thus leading to a "segment" with a child "italic" and nothing else.   -->
<!-- The indentation provided introduces whitespace where we are expecting -->
<!-- mixed content.  In old parlance, we expect a "segment" to be "tight". -->
<!-- We saw this just twice in all of AATA (2023-04-07) where a lone "m"   -->
<!-- (plus absorbed punctuation) was caught between displays in a          -->
<!-- paragraph, and the whitespace bled into a diff when the previous      -->
<!-- commit led to the @indent suddenly being effective.                   -->

<xsl:output method="xml" indent="no" encoding="UTF-8"/>

<xsl:variable name="exercise-style" select="'static'"/>

<!-- Not so much "include" as "manipulate"            -->
<xsl:param name="math.punctuation.include" select="'all'"/>

<!-- ############################## -->
<!-- Incorporate (Meld) Mathematics -->
<!-- ############################## -->

<!-- We do a pass (similar to those in the "pretext-assembly.xsl"   -->
<!-- stylesheet.  Purpose is to incorporate Nemeth braille versions -->
<!-- of mathematics, produced by MathJax/Speech RTule Engine.       -->

<!-- Necessary to get pre-constructed Nemeth braille for math elements. -->
<!-- This file of math representations will come from another process   -->
<!-- that involves mathJax and Speech Rule Engine (SRE).                -->
<!-- Note: this is a manual step during development.                    -->
<xsl:param name="mathfile" select="''"/>
<xsl:variable name="math-repr"  select="document($mathfile)/pi:math-representations"/>

<!-- Default xerox machine for "meld-math" pass -->
<xsl:template match="node()|@*" mode="meld-math">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="meld-math"/>
    </xsl:copy>
</xsl:template>

<!-- $math-repr is a "global" variable with "pi:math" elements -->
<xsl:key name="math-elts" match="pi:math" use="@id"/>

<!-- Replace math elements with a substructure: -->
<!--     math-original: the guts, simply xeroxed, necessary for -->
<!--         examining simple situations which do not require a -->
<!--         switch to Nemeth, or use simpler indicators        -->
<!--     math-nemeth: unicode from SRE                          -->
<xsl:template match="m|me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]" mode="meld-math">
    <!-- preserve author's element -->
    <xsl:copy>
        <!-- preserve attributes -->
        <xsl:apply-templates select="@*" mode="meld-math"/>
        <!-- get braille from representations file -->
        <xsl:variable name="id">
            <xsl:apply-templates select="." mode="unique-id"/>
        </xsl:variable>
        <math-original>
            <xsl:apply-templates select="node()|@*" mode="meld-math"/>
        </math-original>
        <math-nemeth>
            <xsl:for-each select="$math-repr">
                <xsl:value-of select="key('math-elts', $id)/div[@class = 'braille']"/>
            </xsl:for-each>
        </math-nemeth>
    </xsl:copy>
</xsl:template>

<!-- Convert to "real" XML, starting with "$augment" the   -->
<!-- (current) final tree produced by the -assembly phase. -->
<xsl:variable name="math-meld-rtf">
    <xsl:apply-templates select="$augment" mode="meld-math"/>
</xsl:variable>
<xsl:variable name="melded-math" select="exsl:node-set($math-meld-rtf)"/>

<!-- Replace the "standard" key landmarks normally  -->
<!-- produced by the -assembly stylesheet. -->
<xsl:variable name="root" select="$melded-math/pretext"/>
<xsl:variable name="docinfo" select="$root/docinfo"/>
<xsl:variable name="document-root" select="$root/*[not(self::docinfo)]"/>

<!-- Source analysis -->

<!-- We need to determine "how deep" the division hierarchy goes, so       -->
<!-- we probe for depths of four and five.  Note how specialized           -->
<!-- divisions result in additional depth beyond traditional divisions.    -->
<!-- (exercises|worksheet|handout|reading-questions|solutions|references|glossary) -->

<xsl:variable name="b-has-level-four" select="boolean(
      $document-root//subsubsection
    | $document-root//subsection/exercises
    | $document-root//subsection/worksheet
    | $document-root//subsection/handout
    | $document-root//subsection/reading-questions
    | $document-root//subsection/solutions
    | $document-root//subsection/references
    | $document-root//subsection/glossary)"/>

<xsl:variable name="b-has-level-five" select="boolean(
      $document-root//subsubsection/exercises
    | $document-root//subsubsection/worksheet
    | $document-root//subsubsection/handout
    | $document-root//subsubsection/reading-questions
    | $document-root//subsubsection/solutions
    | $document-root//subsubsection/references
    | $document-root//subsubsection/glossary)"/>

<!-- And anything less -->
<xsl:variable name="b-has-level-three-or-less" select="not($b-has-level-four) and not($b-has-level-five)"/>

<!-- ###################### -->
<!-- Conversion to Segments -->
<!-- ###################### -->

<!-- A "segment" is a chunk of text that begins on a new line and finishes  -->
<!-- with a partial line followed by a newline, ready for another segment.  -->
<!-- Various properties, akin to the main tools of braille formatting,      -->
<!-- affect how it is formatted into a BRF.  The XSL analyzes the nature of -->
<!-- the text and its surrounding from preTeXt markup, so then Python gets  -->
<!-- something that just describes how it should be formatted.              -->
<!--                                                                        -->
<!-- This documents much of the transition from PreTeXt XML to an XML meant -->
<!-- only for Python text processing.                                       -->
<!--                                                                        -->
<!-- Here we do not write anything when a default is correct, and then      -->
<!-- Python (lxml) will interpret a "missing" attribute as the default,     -->
<!-- and create something of the correct datatype for Python.               -->
<!--                                                                        -->
<!--     @newpage - default: no, else yes                                   -->
<!--     @centered - default: no, else yes                                  -->
<!--     @breakable - default: yes, else no                                 -->
<!--     @indentation - default: 0, else positive integer                   -->
<!--     @runover - default: 0, else positive integer                       -->
<!--     @lines-before - default: 0, else positive integer                  -->
<!--     @lines-after - default: 0, else positive integer                   -->
<!--     @lines-following - default: 0, else positive integer               -->

<!-- This is the main event, hidden within the formulation of a  -->
<!-- variable holding an RTF.  This is formed by the totality of -->
<!-- non-modal templates.  It will be converted into a node set, -->
<!-- for a post-processing step to incorporate "runin"           -->
<!-- title/heading elements into a subsequent segment.           -->
<xsl:variable name="segmented-rtf">
    <xsl:call-template name="warning-unimplemented"/>
    <xsl:call-template name="missing-warning"/>
    <xsl:apply-templates select="$root"/>
</xsl:variable>

<!-- And we sneak in a warning that this conversion is underway, but not complete. -->
<xsl:template name="warning-unimplemented">
    <xsl:message>** Some PreTeXt elements lack full implementation in the braille conversion.</xsl:message>
    <xsl:message>** Smaller items will simply be missing from your output.</xsl:message>
    <xsl:message>** Larger items may have all-caps placeholders in your output.</xsl:message>
    <xsl:message>** These will all be reported as "Overlooked" in the log.</xsl:message>
    <xsl:message>** Please report the complete list in the PreTeXt support forum,</xsl:message>
    <xsl:message>** so we can prioritize making the output for your project complete.</xsl:message>
</xsl:template>

<!-- The entry template "waits" for the "$math-meld-rtf" and    -->
<!-- "$segmented-rtf" global variables to form, then the actual -->
<!-- output is a run of modal "meld-runin" templates as a sort  -->
<!-- of post-processing step.                                   -->
<xsl:template match="/">
    <xsl:apply-templates select="exsl:node-set($segmented-rtf)/brf" mode="meld-runin"/>
</xsl:template>

<!-- Process segments here, looking for run-in titles/headings -->
<xsl:template match="segment" mode="meld-runin">
    <!-- Look for "run-in" material just prior -->
    <xsl:variable name="adjacent-runin" select="preceding-sibling::*[1][self::runin]"/>
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="meld-runin"/>
        <xsl:apply-templates select="$adjacent-runin/@indentation|$adjacent-runin/@lines-before" mode="meld-runin"/>
        <xsl:apply-templates select="$adjacent-runin/node()" mode="meld-runin"/>
        <xsl:value-of select="$adjacent-runin/@separator"/>
        <xsl:apply-templates select="node()" mode="meld-runin"/>
    </xsl:copy>
</xsl:template>

<!-- It is entirely possible for a segment to be preceded by     -->
<!-- consecutive "runin" elements.  Three examples:              -->
<!--                                                             -->
<!--   "proof" then "case"                                       -->
<!--   "hint" then "li" (and other SOLUTION-LIKE)                -->
<!--   "exercise" then "li" (but should probably be "task"?)     -->
<!--                                                             -->
<!-- Likely a structure with an immediate "p" with an immediate  -->
<!-- list could result in a run-in title for the structure and   -->
<!-- a run-in title for the first list item.  Experimentation on -->
<!-- 2023-04-05 with Judson's AATA did not reveal any runs of    -->
<!-- three (or more) consecutive "runin" elements.  So our       -->
<!-- solution is ad-hoc for the double case, with a bug report   -->
<!-- for three or more.                                          -->
<!-- We convert the first "runin" to a "segment" (rather than    -->
<!-- killing it) and let the second "runin" get absorbed by the  -->
<!-- subsequent "segment".                                       -->
<xsl:template match="runin[following-sibling::*[1][self::runin]]" mode="meld-runin">
    <segment>
        <xsl:apply-templates select="@*|node()" mode="meld-runin"/>
    </segment>
    <xsl:if test="following-sibling::*[2][self::runin]">
        <xsl:message>BUG: the braille conversion has encountered three "run-in" titles in a row,</xsl:message>
        <xsl:message>which we had not expected.  Please report me.  Thank-you.</xsl:message>
        <xsl:message>First: <xsl:value-of select="."/></xsl:message>
        <xsl:message>Second: <xsl:value-of select="following-sibling::*[1][self::runin]"/></xsl:message>
        <xsl:message>Third: <xsl:value-of select="following-sibling::*[2][self::runin]"/></xsl:message>
    </xsl:if>
</xsl:template>

<!-- Every "runin" has been absorbed into a trailing "segment" or -->
<!-- perhaps converted into a "segment".  This will prevent the   -->
<!-- absorbed ones from persisting.                               -->
<xsl:template match="runin" mode="meld-runin"/>

<!-- Xerox machine -->
<xsl:template match="@*|node()" mode="meld-runin">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()" mode="meld-runin"/>
    </xsl:copy>
</xsl:template>

<!-- with /, so a plain generator can match others -->
<xsl:template match="/pretext">
    <!-- Need an overall container   -->
    <!-- Maybe copy a language code? -->
    <brf>
        <!-- centered heading on line 1 -->
        <segment centered="yes" lines-after="1">Transcriber Notes</segment>
        <!-- Literal text for each note, control whitespace,  -->
        <!-- etc here, since it will not be handled otherwise -->
        <xsl:if test="//c">
        <!-- See "c" template for explanation -->
            <segment indentation="2">
                <xsl:text>Literal, or verbatim, computer code used in sentences is indicated by a set of transcriber-defined emphasis given by the following indicators, which all begin with the two cells dot-4 and dot-3456.  Single letter: 4-3456-23.  Begin, end word: 4-3456-2, 4-3456-3.  Begin, end phrase: 4-3456-2356, 4-3456-3.</xsl:text>
            </segment>
        </xsl:if>
        <!--  -->
        <xsl:if test="//image">
            <segment indentation="2">
                <xsl:text>Images are replaced by authors' descriptions, and then in an embossed version, a full (numbered) page comes next, which can be manually replaced by a tactile version of the image.</xsl:text>
            </segment>
        </xsl:if>
        <!--  -->
        <xsl:if test="//sidebyside">
            <segment indentation="2">
                <xsl:text>A "side-by-side" is a horizontal layout of document elements.  The components of a side-by-side are called "panels".  Typically panels are images or figures, but can also be items like program listings, tables, or paragraphs.  For braille, we let each panel use the full width of the page, so we announce the start, indicating the total number of panels.  Then we preface each panel with its number in the sequence.  Finally we announce the end because it may be hard to distinguish a final panel from the ensuing text.</xsl:text>
            </segment>
        </xsl:if>
        <!--  -->
        <!-- automatically infers we have a note already for "sidebyside" -->
        <xsl:if test="//sbsgroup">
            <segment indentation="2">
                <xsl:text>A "side-by-side group" is a sequence down the page of "side-by-side" (see previous note).  We announce the start with the number of side-by-side in the group to expect, and let the beginning and ending notes for each side-by-side delineate the sequence.</xsl:text>
            </segment>
        </xsl:if>
        <!-- mention how "tabular" are implenented and suggest possible improvements-->
        <xsl:if test="//tabular">
            <segment indentation="2">
                <xsl:text>Tabular material is always implemented using a "linear table format".  A human transcriber may be able to improve small tables, or larger tables that could use multiple pages when embossed, by using a different format.</xsl:text>
            </segment>
        </xsl:if>
        <!-- process segments and blocks of "brf" -->
        <xsl:apply-templates select="*"/>
    </brf>
</xsl:template>

<!-- ######### -->
<!-- Divisions -->
<!-- ######### -->

<!-- [BANA, 2016] 4.2.1 -->
<!-- As a general rule, centered headings are used to represent     -->
<!-- the print headings of major sections of the text, and cell-5   -->
<!-- and cell-7 headings are used to represent the print headings   -->
<!-- for subsections shown within major sections. When there are    -->
<!-- more than three distinct heading levels in print, cell-7       -->
<!-- headings are applied only to the lowest hierarchy level; the   -->
<!-- use of centered headings is extended to one or more subsection -->
<!-- levels as necessary.                                           -->

<!-- Braille division headings are centered, indented 4 cells ("cell-5"),   -->
<!-- or indented 6 cells ("cell-7"), along with blank lines possibly        -->
<!-- before and after.  Cell-7 is always terminal and is only used at one   -->
<!-- level.   To "fill" when there are more than three levels, centered     -->
<!-- headings get extended.  At the chapter level of a book, we start at    -->
<!-- the top of a page, which somewhat distinguishes the centered style     -->
<!-- of a chapter.  From PreTeXt, division numbers (if used) are            -->
<!-- unambiguous indicators of levels.                                      -->
<!--                                                                        -->
<!-- Level                        book                      article         -->
<!-- 1 chapter           center  center  center                             -->
<!-- 2 section           cell-5  center  center      center  center  center -->
<!-- 3 subsection        cell-7  cell-5  center      cell-7  cell-5  center -->
<!-- 4 subsubsection             cell-7  cell-5              cell-7  cell-5 -->
<!-- 5 (specialized)                     cell-7                      cell-7 -->

<!-- Divisions apparent in a rendered BRF. -->
<xsl:template match="chapter|appendix|index[index-list]|index-part|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|slide|exercises|worksheet|handout|reading-questions|solutions|references|glossary">

    <!-- Determine: newpage, centered, cell5, cell7 -->
    <xsl:variable name="heading-style">
        <xsl:apply-templates select="." mode="heading-style"/>
    </xsl:variable>

    <segment breakable="no" lines-following="1">
        <!-- various attributes are fixed (above) or -->
        <!-- vary according to the heading-style     -->
        <xsl:attribute name="newpage">
            <xsl:choose>
                <xsl:when test="$heading-style = 'newpage'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Explicit defaults for Python, partially to get types right -->
                    <xsl:text>no</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <!--  -->
        <xsl:attribute name="centered">
            <xsl:choose>
                <xsl:when test="($heading-style = 'newpage') or ($heading-style = 'centered')">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <!-- Explicit defaults for Python, partially to get types right -->
                <xsl:otherwise>
                    <xsl:text>no</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <!--  -->
        <xsl:variable name="indentation">
            <xsl:choose>
                <xsl:when test="$heading-style = 'cell5'">
                    <xsl:text>4</xsl:text>
                </xsl:when>
                <xsl:when test="$heading-style = 'cell7'">
                    <xsl:text>6</xsl:text>
                </xsl:when>
                <!-- Explicit defaults for Python, partially to get types right -->
                <xsl:otherwise>
                    <xsl:text>0</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!--  -->
        <xsl:attribute name="indentation">
            <xsl:value-of select="$indentation"/>
        </xsl:attribute>
        <!--  -->
        <xsl:attribute name="runover">
            <xsl:value-of select="$indentation"/>
        </xsl:attribute>
        <!-- Indicate a "line-before" whenever necessary for an     -->
        <!-- electronic version.  Page formatting for an embossed   -->
        <!-- version will not include these at the start of a page. -->
        <xsl:attribute name="lines-before">
            <xsl:choose>
                <xsl:when test="$heading-style = 'newpage'">
                    <xsl:text>1</xsl:text>
                </xsl:when>
                <!-- [BANA 2016], 4.4.1                                           -->
                <!-- A centered heading is preceded and followed by a blank line. -->
                <xsl:when test="$heading-style = 'centered'">
                    <xsl:text>1</xsl:text>
                </xsl:when>
                <xsl:when test="$heading-style = 'cell5'">
                    <xsl:text>1</xsl:text>
                </xsl:when>
                <xsl:when test="$heading-style = 'cell7'">
                    <xsl:text>1</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:attribute>
        <!--  -->
        <xsl:attribute name="lines-after">
            <xsl:choose>
                <xsl:when test="$heading-style = 'newpage'">
                    <xsl:text>1</xsl:text>
                </xsl:when>
                <!-- [BANA 2016], 4.4.1                                           -->
                <!-- A centered heading is preceded and followed by a blank line. -->
                <xsl:when test="$heading-style = 'centered'">
                    <xsl:text>1</xsl:text>
                </xsl:when>
                <xsl:when test="$heading-style = 'cell5'">
                    <xsl:text>0</xsl:text>
                </xsl:when>
                <xsl:when test="$heading-style = 'cell7'">
                    <xsl:text>0</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:attribute>
        <!-- division headings go to the Table of Contents -->
        <xsl:attribute name="heading-id">
            <xsl:apply-templates select="." mode="unique-id"/>
        </xsl:attribute>
        <!-- TODO: record heading levels for indentation/runover in ToC -->
        <!--  -->
        <!-- Finally, the heading content itself -->
       <xsl:variable name="the-number">
            <xsl:apply-templates select="." mode="number"/>
        </xsl:variable>
        <xsl:if test="not($the-number = '')">
            <xsl:value-of select="$the-number"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="title-full"/>
    </segment>
    <!-- end heading segment, recurse into the -->
    <!-- contents of the (structured) division -->
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Overall document "types/classes", level 0/-1 -->
<!-- Normalize so that: "chapter" is always level 1, "section"  -->
<!-- is always level 2.  We do not ever consult these specific  -->
<!-- values for the document type/class, they are not imporant. -->
<!--  Also, the climb up the tree ends here.                    -->
<xsl:template match="book|article|slideshow|letter|memo" mode="braille-level">
    <xsl:choose>
        <!-- "book" with parts, make "part" level 0 -->
        <xsl:when test="$b-has-parts">
            <xsl:text>-1</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Containiers, inherit from parent -->
<xsl:template match="frontmatter|backmatter" mode="braille-level">
    <xsl:apply-templates select="parent::*" mode="braille-level"/>
</xsl:template>

<!-- True divisions, +1 from parent -->
<xsl:template match="part|chapter|appendix|index[index-list]|index-part|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|slide|exercises|worksheet|handout|reading-questions|solutions|references|glossary" mode="braille-level">
    <xsl:variable name="parent-level">
        <xsl:apply-templates select="parent::*" mode="braille-level"/>
    </xsl:variable>
    <xsl:value-of select="$parent-level + 1"/>
</xsl:template>

<!-- Divisions apparent in a BRF.  Four headings styles,       -->
<!-- which we use to "define" how headings are formatted.      -->
<!-- Specialized divisions can appear at many levels, but will -->
<!-- be formatted according to their level in the hierarchy.   -->
<!-- See table above for explanation of choices here.          -->
<xsl:template match="chapter|appendix|index[index-list]|index-part|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|slide|exercises|worksheet|handout|reading-questions|solutions|references|glossary" mode="heading-style">
    <xsl:variable name="braille-level">
        <xsl:apply-templates select="." mode="braille-level"/>
    </xsl:variable>
    <xsl:choose>
        <!-- chapters (of books) -->
        <xsl:when test="$braille-level = 1">
            <xsl:text>newpage</xsl:text>
        </xsl:when>
        <!-- sections (of books or articles) -->
        <xsl:when test="$braille-level = 2">
            <xsl:choose>
                <xsl:when test="$b-has-level-three-or-less and $b-is-book">
                    <xsl:text>cell5</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>centered</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!--  -->
        <xsl:when test="$braille-level = 3">
            <xsl:choose>
                <xsl:when test="$b-has-level-five">
                    <xsl:text>centered</xsl:text>
                </xsl:when>
                <xsl:when test="$b-has-level-four">
                    <xsl:text>cell5</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>cell7</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!--  -->
        <xsl:when test="$braille-level = 4">
            <xsl:choose>
                <xsl:when test="$b-has-level-five">
                    <xsl:text>cell5</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>cell7</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!--  -->
        <xsl:when test="$braille-level = 5">
            <xsl:text>cell7</xsl:text>
         </xsl:when>
        <!--  -->
        <xsl:otherwise>
            <xsl:text>UNDEFINED</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ###################### -->
<!-- Exceptional Containers -->
<!-- ###################### -->

<!-- A special division: "paragraphs" -->
<xsl:template match="paragraphs">
    <!-- Should be run-in with automatic space afterward -->
    <xsl:if test="title">
        <segment lines-before="1">
            <xsl:apply-templates select="." mode="title-full"/>
        </segment>
    </xsl:if>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Very lightweight, title is optional,    -->
<!-- and does not default to "SubExercises". -->
<xsl:template match="subexercises">
    <xsl:if test="title">
        <segment lines-before="1">
            <xsl:apply-templates select="." mode="title-full"/>
        </segment>
    </xsl:if>
    <xsl:apply-templates select="introduction"/>
    <xsl:apply-templates select="exercise|exercisegroup"/>
    <xsl:apply-templates select="conclusion"/>
</xsl:template>

<!-- An "exercisegroup" is very visual, so  -->
<!-- we delimit it with a transcriber note. -->
<xsl:template match="exercisegroup">
    <xsl:apply-templates select="." mode="transcriber-note">
        <xsl:with-param name="message">
            <xsl:text>An exercise group follows.  </xsl:text>
            <!-- optional, so with trailing space -->
            <xsl:if test="introduction">
                <xsl:text>It begins with an introduction.  </xsl:text>
            </xsl:if>
            <xsl:text>The exercises run from number </xsl:text>
            <xsl:apply-templates select="exercise[1]" mode="serial-number"/>
            <xsl:text> to number </xsl:text>
            <xsl:apply-templates select="exercise[last()]" mode="serial-number"/>
            <xsl:text>.</xsl:text>
            <!-- optional, so with leading space -->
            <xsl:if test="conclusion">
                <xsl:text>  It finishes with a conclusion.</xsl:text>
            </xsl:if>
        </xsl:with-param>
    </xsl:apply-templates>
    <!--  -->
    <xsl:apply-templates select="introduction"/>
    <xsl:apply-templates select="exercise"/>
    <xsl:apply-templates select="conclusion"/>
</xsl:template>


<!-- ###### -->
<!-- Blocks -->
<!-- ###### -->

<!-- "Blocks" are major components of PreTeXt output.  Typically  -->
<!-- numbered, titled, set-off, and sometimes with subsidiary     -->
<!-- pieces hanging off them.  For braille, they might not        -->
<!-- cross page boundaries, and may have box lines, etc.          -->
<!--                                                              -->
<!-- We handle the title as a heading of sorts, which might not   -->
<!-- cross a page boundary, and which might be "stuck" on a       -->
<!-- certain number of following lines.  See the discussion below -->
<!-- about titles.                                                -->

<!-- "Regular" blocks, including inline "exercise" (aka "Checkpoint") -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&GOAL-LIKE;|&OPENPROBLEM-LIKE;|exercise[&INLINE-EXERCISE-FILTER;]|assemblage">
    <block breakable="no" box="standard" lines-before="1" lines-after="1">
        <xsl:apply-templates select="." mode="block-title"/>
        <xsl:apply-templates select="*[not(self::title)]"/>
    </block>
</xsl:template>

<!-- "Other" exercises (in "exercises" divisions, in "reading questions", -->
<!-- in worksheets) are not as prominent and have run-in titles           -->
<xsl:template match="exercise[not(&INLINE-EXERCISE-FILTER;)]">
    <xsl:apply-templates select="." mode="block-title"/>
    <xsl:apply-templates select="*[not(self::title)]"/>
</xsl:template>

<!-- The appendages are not yet blocks, they live inside blocks           -->
<!-- NOTE: if these become contained blocks, that is a structural change  -->
<!-- that will require changes in the Python lxml which assumes otherwise -->
<xsl:template match="&PROOF-LIKE;|&SOLUTION-LIKE;|&DISCUSSION-LIKE;">
    <xsl:apply-templates select="." mode="block-title"/>
    <xsl:apply-templates select="*[not(self::title)]"/>
</xsl:template>

<!-- A "case" is a further division of a PROOF-LIKE -->
<xsl:template match="case">
    <runin indentation="2" separator="&#x20;">
        <xsl:apply-templates select="." mode="title-full"/>
    </runin>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Titles of blocks can be an entire "segment" if they finish with a  -->
<!-- newline.  Other titles are "runin" and are consolidated in a final -->
<!-- post-processing step.                                              -->

<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&OPENPROBLEM-LIKE;|exercise[&INLINE-EXERCISE-FILTER;]" mode="block-title">
    <segment lines-before="0">
        <!--  -->
        <xsl:apply-templates select="." mode="type-name"/>
        <!--  -->
        <xsl:variable name="the-number">
            <xsl:apply-templates select="." mode="number"/>
        </xsl:variable>
        <xsl:if test="not($the-number = '')">
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
        </xsl:if>
        <!--  -->
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
        <!--  -->
    </segment>
</xsl:template>

<!-- An assemblage is not numbered, it is just a box.  The title is optional. -->
<xsl:template match="assemblage" mode="block-title">
    <xsl:if test="title">
        <segment lines-before="0">
        <xsl:apply-templates select="." mode="title-full"/>
        </segment>
    </xsl:if>
</xsl:template>

<!-- Should be run-in with automatic space afterward -->
<!-- There may be multiple proofs, but we do not number them at birth, -->
<!-- the number only gets used in a cross-reference.  Maybe standalone -->
<!-- is different??                                                    -->
<!-- TENTATIVE: DISCUSSION-LIKE may be identical                       -->
<xsl:template match="&PROOF-LIKE;|&DISCUSSION-LIKE;" mode="block-title">
        <runin indentation="0" lines-before="1" separator="&#x20;">
        <!--  -->
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text>.</xsl:text>
        <!--  -->
        <xsl:if test="title">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
        <!--  -->
    </runin>
</xsl:template>

<!-- Should be run-in with automatic space afterward -->
<xsl:template match="exercise[not(&INLINE-EXERCISE-FILTER;)]" mode="block-title">
    <runin indentation="0" lines-before="1" separator="&#x20;">
        <xsl:apply-templates select="." mode="serial-number"/>
        <xsl:text>.</xsl:text>
        <!--  -->
        <xsl:if test="title">
            <xsl:text> (</xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
        <!--  -->
    </runin>
</xsl:template>

<!-- Should be run-in with automatic space afterward -->
<xsl:template match="&SOLUTION-LIKE;" mode="block-title">
    <runin indentation="0" lines-before="1" separator="&#x20;">
        <!--  -->
        <xsl:apply-templates select="." mode="type-name"/>
        <!--  -->
        <xsl:variable name="the-number">
             <xsl:apply-templates select="." mode="non-singleton-number"/>
        </xsl:variable>
        <xsl:if test="not($the-number = '')">
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
        </xsl:if>
        <xsl:text>.</xsl:text>
        <!--  -->
        <xsl:if test="title">
            <xsl:text> (</xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
        <!--  -->
    </runin>
</xsl:template>

<!-- Print is "Type: Title", no number, since there is only one per     -->
<!-- division and the number is implicitly that of the parent division. -->
<xsl:template match="&GOAL-LIKE;" mode="block-title">
    <segment lines-before="0">
        <!--  -->
        <xsl:apply-templates select="." mode="type-name"/>
        <!--  -->
        <xsl:if test="title">
            <xsl:text>: </xsl:text>
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
        <!--  -->
    </segment>
</xsl:template>


<!-- ########### -->
<!-- FIGURE-LIKE -->
<!-- ########### -->

<!-- [BANA, 2016] 6.2.2 -->
<!-- 7-5 margins for captions of "Illustrative Materials" -->
<!-- We generalize to titles of "table" and "list" blocks -->

<!-- [BANA, 2016] 6.2.2(e) -->
<!-- When both a print caption and a transcriber-generated description    -->
<!-- are needed, begin the description (enclosed in transcriber's note    -->
<!-- indicators) on the line following the caption.                       -->
<!-- Figures are treated different for the case where their contents are  -->
<!-- images (thus requiring a tactile graphic page to follow the figure). -->
<xsl:template match="figure[image]">
    <block breakable="no" box="standard" lines-before="1" lines-after="1">
        <segment indentation="6" runover="4">
            <xsl:apply-templates select="." mode="block-title"/>
        </segment>
        <xsl:apply-templates select="*[not(self::image)]"/>
        <xsl:apply-templates select="image" mode="braille-representation"/>
    </block>
    <!-- Form a page to be replaced by tactile version -->
    <block ownpage="yes">
        <xsl:apply-templates select="." mode="transcriber-note">
            <xsl:with-param name="message">
                <xsl:text>Replace this page with </xsl:text>
                <xsl:apply-templates select="." mode="block-title"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </block>
</xsl:template>

<!-- Other FIGURE-LIKE can be handled together -->
<xsl:template match="figure|listing|table|list">
    <block breakable="no" box="standard" lines-before="1" lines-after="1">
        <segment indentation="6" runover="4">
            <!-- [BANA, 2016, 11.17.1a] "Leave a blank line after the title." -->
            <!-- Guidance for tables, we mimic for PTX "list" block.          -->
            <xsl:if test="self::table or self::list">
                <xsl:attribute name="lines-after">
                    <xsl:text>1</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="." mode="block-title"/>
        </segment>
        <xsl:apply-templates select="*"/>
    </block>
</xsl:template>

<!-- Caption/title, with label, number, etc.  "caption" and -->
<!-- "title" elements are metadata, killed in -common,      -->
<!-- obtained as needed via modal templates.                -->
<xsl:template match="figure|listing|table|list" mode="block-title">
    <xsl:apply-templates select="." mode="type-name"/>
    <!--  -->
    <xsl:variable name="the-number">
         <xsl:apply-templates select="." mode="number"/>
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <xsl:text> </xsl:text>
        <xsl:value-of select="$the-number"/>
    </xsl:if>
    <xsl:text>. </xsl:text>
    <xsl:choose>
        <xsl:when test="self::figure">
            <xsl:apply-templates select="." mode="caption-full"/>
        </xsl:when>
        <xsl:when test="self::table|self::list|self::listing">
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- A bare image becomes a transcriber note with a small amount -->
<!-- of identification, and then generates a replacement page.   -->
<xsl:template match="image">
    <!-- A "segment" with the ID of the image to identify it, -->
    <xsl:apply-templates select="." mode="transcriber-note">
        <xsl:with-param name="message">
            <xsl:apply-templates select="." mode="block-title"/>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- Then the author's descriptions -->
    <xsl:apply-templates select="." mode="braille-representation"/>
    <!-- Form a page to be replaced by tactile version -->
    <block ownpage="yes">
        <xsl:apply-templates select="." mode="transcriber-note">
            <xsl:with-param name="message">
                <xsl:text>Replace this page with </xsl:text>
                <xsl:apply-templates select="." mode="block-title"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </block>
</xsl:template>

<!-- A transcriber note replacing an image when included -->
<!-- in some other (identifying) structure.              -->
<xsl:template match="image" mode="braille-representation">
    <!-- A "segment" with the author's "shortdescription" -->
    <xsl:if test="shortdescription">
        <xsl:apply-templates select="." mode="transcriber-note">
            <xsl:with-param name="message">
                <xsl:apply-templates select="shortdescription"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- Not really a title, but a repeated identification of an image  -->
<!-- to coordinate text and manually inserted tactile versions.     -->
<xsl:template match="image" mode="block-title">
    <xsl:text>Image: </xsl:text>
    <xsl:apply-templates select="." mode="visible-id"/>
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Side-by-Side -->
<!-- ############ -->

<!-- We delimit the panels of a "sidebyside" with an introductory        -->
<!-- transcriber note and a concluding note.  Each panel is preceded     -->
<!-- by a very short transcriber note giving its number in the sequence. -->
<!-- An "sbsgroup" only announces its start, but each "sidebyside"       -->
<!-- introduction provides the number within the group.                  -->
<!--                                                                     -->
<!-- Otherwise, a "sidebyside" is just "linearized" and strung out down  -->
<!-- pages, rather than across, since horizontal real estate is limited  -->
<!-- and images are going full (own) page.                               -->
<!-- From discussion with Michael Cantino and Al Maneki, 2023-03-30      -->

<xsl:template match="sidebyside">
    <xsl:variable name="npanels" select="count(*)"/>
    <!-- Intro -->
    <!-- At a 40-character width, this will fit on one line with -->
    <!-- two cells to spare when the count is single-digit.      -->
    <xsl:apply-templates select="." mode="transcriber-note">
        <xsl:with-param name="message">
            <xsl:text>side-by-side: </xsl:text>
            <!-- panels are simply child elements -->
            <xsl:value-of select="$npanels"/>
            <xsl:text> panels</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- Panels -->
    <xsl:for-each select="*">
        <xsl:variable name="number" select="count(preceding-sibling::*) + 1"/>
        <xsl:apply-templates select="." mode="transcriber-note">
            <xsl:with-param name="message">
                <xsl:text>panel: </xsl:text>
                <xsl:value-of select="$number"/>
                <xsl:text>/</xsl:text>
                <xsl:value-of select="$npanels"/>
            </xsl:with-param>
        </xsl:apply-templates>
        <!-- context switch, so self -->
        <xsl:apply-templates select="."/>
    </xsl:for-each>
    <!-- Outro -->
    <!-- This message mimics the format of the opening note -->
    <xsl:apply-templates select="." mode="transcriber-note">
        <xsl:with-param name="message">
            <xsl:text>side-by-side: end</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="sbsgroup">
    <xsl:variable name="nsbs" select="count(sidebyside)"/>
    <xsl:apply-templates select="." mode="transcriber-note">
        <xsl:with-param name="message">
            <xsl:text>side-by-side group: </xsl:text>
            <xsl:value-of select="$nsbs"/>
            <xsl:text> sbs</xsl:text>
        </xsl:with-param>
    </xsl:apply-templates>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- A "stack" is strictly a side-by-side panel and we just -->
<!-- process its children.  No need to get carried away for -->
<!-- braille, and maybe an "apply-imports" (or nothing at   -->
<!-- all) is the right thing to do.                         -->
<xsl:template match="stack">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Lists are containers full of list items.  All by   -->
<!-- themselves they have no real impact on the braille -->
<!-- output.  The list items are another matter.        -->
<!-- 2023-04-06: very prelimnary, e.g. no runover       -->
<!-- 2023-04-10: excessive nesting => excessive run-in  -->
<xsl:template match="ul|ol|dl">
    <xsl:apply-templates select="li"/>
</xsl:template>

<xsl:template match="li">
    <!-- Marker as a "runin" element -->
    <runin indentation="0" separator="&#x20;">
        <xsl:choose>
            <xsl:when test="parent::ol">
                <xsl:apply-templates select="." mode="item-number"/>
                <xsl:text>.</xsl:text>
            </xsl:when>
            <xsl:when test="parent::ul">
                <xsl:apply-templates select="." mode="unicode-list-marker"/>
                <xsl:text>.</xsl:text>
            </xsl:when>
            <xsl:when test="parent::dl">
                <xsl:apply-templates select="." mode="title-full"/>
            </xsl:when>
        </xsl:choose>
    </runin>
    <xsl:apply-templates select="node()"/>
</xsl:template>

<xsl:template match="ul/li" mode="unicode-list-marker">
    <xsl:variable name="format-code">
        <xsl:apply-templates select="parent::ul" mode="format-code"/>
    </xsl:variable>
    <!-- The list label.  The file  en-ueb-chardefs.uti        -->
    <!-- associates these Unicode values with the indicated    -->
    <!-- dot patterns.  This jibes with [BANA-2016, 8.6.2],    -->
    <!-- which says the open circle needs a Grade 1 indicator. -->
    <!-- The file  en-ueb-g2.ctb  lists  x25cb  and  x24a0  as -->
    <!-- both being "contraction" and so needing a             -->
    <!-- Grade 1 indicator.                                    -->
    <xsl:choose>
        <!-- Unicode Character 'BULLET' (U+2022)       -->
        <!-- Dot pattern: 456-256                      -->
        <xsl:when test="$format-code = 'disc'">
            <xsl:text>&#x2022; </xsl:text>
        </xsl:when>
        <!-- Unicode Character 'WHITE CIRCLE' (U+25CB) -->
        <!-- Dot pattern: 1246-123456                  -->
        <xsl:when test="$format-code = 'circle'">
            <xsl:text>&#x25cb; </xsl:text>
        </xsl:when>
        <!-- Unicode Character 'BLACK SQUARE' (U+25A0) -->
        <!-- Dot pattern: 456-1246-3456-145            -->
        <xsl:when test="$format-code = 'square'">
            <xsl:text>&#x25a0; </xsl:text>
        </xsl:when>
        <!-- a bad idea for Braille -->
        <xsl:when test="$format-code = 'none'">
            <xsl:text/>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- ####################### -->
<!-- Tabular (table content) -->
<!-- ####################### -->

<!-- Simple tables can be realized nicely in braille by a human transcriber. -->
<!-- We are not even sure how to identify a table as being "simple enough."  -->
<!--                                                                         -->
<!-- So we implement "Wide Tables: Linear Table Format" [BANA, 2016, 11.17], -->
<!-- which is never wrong, and is more or less sympatico with our markup.    -->
<!--                                                                         -->
<!-- TODO: Suppose a transcriber *does* replace one of our tables with       -->
<!-- something better?  We could perhaps capture the BRF version in a new    -->
<!-- "braille" element that lived in source and which was used               -->
<!-- preferentially once discovered.                                         -->

<xsl:template match="tabular">
    <xsl:variable name="n-column-headings" select="count(row[(@header = 'yes') or (@header = 'vertical')])"/>
    <xsl:variable name="b-column-headings" select="$n-column-headings > 0"/>
    <xsl:variable name="b-row-headings" select="@row-headers = 'yes'"/>
    <block breakable="no">
        <!-- Transcriber note, if necessary to explain headings -->
        <xsl:if test="$b-column-headings or $b-row-headings">
            <xsl:apply-templates select="." mode="transcriber-note">
                <xsl:with-param name="message">
                    <xsl:if test="$b-column-headings">
                        <xsl:text>The first </xsl:text>
                        <xsl:value-of select="$n-column-headings"/>
                        <xsl:text> rows are columm headings, described next.</xsl:text>
                    </xsl:if>
                    <!-- separate two sentences, if we have both -->
                    <xsl:if test="$b-column-headings and $b-row-headings">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:if test="$b-row-headings">
                        <xsl:text>The first column of this table contains headings for the rows.</xsl:text>
                    </xsl:if>
                </xsl:with-param>
            </xsl:apply-templates>
            <!-- [BANA, 2016] 11.17.1e "Leave a blank line after the note." -->
            <segment lines-after="1"/>
        </xsl:if>
        <!-- enforce header row(s) first -->
        <!-- BANA says put column headings inside the transcriber note, -->
        <!-- but switch to 1-3 margins.  We ignore this and write the   -->
        <!-- column headings out just tlike all the other rows.  One    -->
        <!-- concession: a blank line separator.                        -->
        <xsl:apply-templates select="row[(@header = 'yes') or (@header = 'vertical')]"/>
        <xsl:if test="$b-column-headings">
            <segment lines-after="1"/>
        </xsl:if>
        <!-- now the "regular" lines, possibly with row-headings -->
        <xsl:apply-templates select="row[not((@header = 'yes') or (@header = 'vertical'))]"/>
    </block>
</xsl:template>

<!-- [BANA, 2016] 11.17.1f Each row has 1-3 margins                     -->
<!-- [BANA, 2016] 11.17.1g "Do not divide a row between braille pages." -->
<xsl:template match="tabular/row">
    <segment breakable="no" indentation="0" runover="2">
        <xsl:choose>
            <xsl:when test="(@header = 'yes') or (@header = 'vertical')">
                <xsl:apply-templates select="cell[1]" mode="describe-column-headings"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="cell"/>
            </xsl:otherwise>
        </xsl:choose>
    </segment>
</xsl:template>

<!-- "Regular" cells in non-header rows (more typical) -->
<xsl:template match="tabular/row/cell">
    <xsl:apply-templates/>
    <xsl:choose>
        <!-- First cell, trailed by a colon -->
        <xsl:when test="not(preceding-sibling::cell)">
            <xsl:text>: </xsl:text>
        </xsl:when>
        <!-- Last cell, trailed by nothing -->
        <xsl:when test="not(following-sibling::cell)"/>
        <!-- Interior cells, trailed by semi-colons -->
        <xsl:otherwise>
            <xsl:text>; </xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="@colspan">
        <xsl:call-template name="duplicate-string">
             <xsl:with-param name="count" select="@colspan - 1"/>
             <xsl:with-param name="text" select="';'"/>
         </xsl:call-template>
     </xsl:if>
</xsl:template>

<xsl:template match="tabular/row/cell" mode="describe-column-headings">
    <xsl:param name="prior-column-number" select="0"/>

    <!-- Analyze  @colspan  implications.  Note this is correct for -->
    <!-- no attribute at all and a (silly) attribute value of 1.    -->
    <xsl:variable name="first-column" select="$prior-column-number + 1"/>
    <xsl:variable name="n-columns">
        <xsl:choose>
            <xsl:when test="@colspan">
                <xsl:value-of select="@colspan"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="last-column" select="$prior-column-number + $n-columns"/>
    <xsl:variable name="b-multicolumns" select="$last-column > $first-column"/>

    <xsl:text>Column</xsl:text>
    <xsl:if test="$b-multicolumns">
        <xsl:text>s</xsl:text>
    </xsl:if>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$first-column"/>
    <xsl:if test="$b-multicolumns">
        <xsl:text> - </xsl:text>
        <xsl:value-of select="$last-column"/>
    </xsl:if>
    <xsl:text> </xsl:text>
    <xsl:apply-templates/>
    <xsl:choose>
        <!-- First cell, trailed by a colon -->
        <xsl:when test="not(preceding-sibling::cell)">
            <xsl:text>: </xsl:text>
        </xsl:when>
        <!-- Last cell, trailed by nothing -->
        <xsl:when test="not(following-sibling::cell)"/>
        <!-- Interior cells, trailed by semi-colons -->
        <xsl:otherwise>
            <xsl:text>; </xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- recurse if there is more to do -->
    <xsl:if test="following-sibling::cell">
        <xsl:apply-templates select="following-sibling::cell" mode="describe-column-headings">
            <xsl:with-param name="prior-column-number" select="$last-column"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- A "p" normally becomes a "segment".  But an entire row of a "tabular" -->
<!-- is a segment and we can't nest them.  So we just dribble out the      -->
<!-- entire "p" without any indentation or anything, so it becomes one     -->
<!-- very long cell in the braille.  Worse, two "p" in a cell will just    -->
<!-- get concatenated and the distinction between the two will be lost.    -->
<xsl:template match="cell/p">
    <xsl:apply-templates select="node()"/>
    <!-- At least provide a space between consecutive "p" -->
    <xsl:if test="following-sibling::p">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- ########## -->
<!-- References -->
<!-- ########## -->

<!-- Bibliography [BANA-2016, 22.2.1]                           -->
<!-- Bibliographic items in a "references" division have a      -->
<!-- bracketed number leading each new entry, then two spaces   -->
<!-- of indentation for the remainder .                         -->
<!-- TODO: expand to accomodate annotations ("note"), BANA 22.3 -->
<xsl:template match="biblio[@type='raw']">
    <runin indentation="0" separator="&#x20;">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="." mode="serial-number"/>
        <xsl:text>]</xsl:text>
    </runin>
    <segment indentation="0" runover="2">
        <xsl:apply-templates/>
    </segment>
</xsl:template>

<!-- Override usual killing of title, but perhaps a generic -->
<!-- template (without punctuation!) would be saner?        -->
<xsl:template match="biblio/title">
    <italic>
        <xsl:apply-templates/>
    </italic>
</xsl:template>

<xsl:template match="volume">
    <bold>
        <xsl:apply-templates/>
    </bold>
</xsl:template>

<!-- Generators -->

<xsl:template match="pretext">
    <xsl:text>PreTeXt</xsl:text>
</xsl:template>

<xsl:template match="tex">
    <xsl:text>TeX</xsl:text>
</xsl:template>

<xsl:template match="latex">
    <xsl:text>LaTeX</xsl:text>
</xsl:template>

<!-- static, all "webwork" as problems are gone -->
<xsl:template match="webwork">
    <xsl:text>WeBWorK</xsl:text>
</xsl:template>

<xsl:template match="ie">
    <xsl:text>i.e.</xsl:text>
</xsl:template>

<xsl:template match="etc">
    <xsl:text>etc.</xsl:text>
</xsl:template>


<!-- Empty Elements, Characters -->

<!-- Generally Unicode values get translated into UEB equivalents  -->
<!-- by liblouis.  This is based on a reading of                   -->
<!--                                                               -->
<!--     /usr/share/liblouis/tables/en-ueb-chardefs.uti            -->
<!--                                                               -->
<!-- which is incorporated via the English-UEB Grade 1 and Grade 2 -->
<!-- tables.  As of 2023-05-12.  We document the Unicode character -->
<!-- and the cells described in the liblouis table.                -->

<!-- Unicode Character 'NO-BREAK SPACE' (U+00A0)   -->
<!-- yields a template for "nbsp" in -common       -->
<!-- liblouis seems to pass this through in-kind   -->
<!-- Used in the manufacture of a cross-reference, -->
<!-- we will want to strip just before it ends up  -->
<!-- in BRF .                                      -->
<xsl:template name="nbsp-character">
    <xsl:text>&#x00A0;</xsl:text>
</xsl:template>

<!-- Unicode Character 'EN DASH' (U+2013) -->
<!-- Liblouis: 6-36                       -->
<xsl:template name="ndash-character">
    <xsl:text>&#x2013;</xsl:text>
</xsl:template>

<!-- Unicode Character 'EM DASH' (U+2014) -->
<!-- Liblouis: 6-36                       -->
<xsl:template name="mdash-character">
    <xsl:text>&#x2014;</xsl:text>
</xsl:template>

<!-- Unicode Character 'COPYRIGHT SIGN' (U+00A9) -->
<!-- Liblouis: 45-14                             -->
<xsl:template name="copyright-character">
    <xsl:text>&#x00A9;</xsl:text>
</xsl:template>

<!-- Unicode Character 'REGISTERED SIGN' (U+00AE) -->
<!-- Liblouis: 45-1235                            -->
<xsl:template name="registered-character">
    <xsl:text>&#x00AE;</xsl:text>
</xsl:template>

<!-- Unicode Character 'TRADE MARK SIGN' (U+2122) -->
<!-- Liblouis: 45-2345                            -->
<xsl:template name="trademark-character">
    <xsl:text>&#x2122;</xsl:text>
</xsl:template>

<!-- Unicode Character 'DEGREE SIGN' (U+00B0) -->
<!-- Liblouis: 45-245                         -->
<xsl:template name="degree-character">
    <xsl:text>&#x00B0;</xsl:text>
</xsl:template>

<!-- Unicode Character 'PRIME' (U+2032) -->
<!-- Liblouis: 2356                     -->
<xsl:template name="prime-character">
    <xsl:text>&#x2032;</xsl:text>
</xsl:template>

<!-- Unicode Character 'DOUBLE PRIME' (U+2033) -->
<!-- Liblouis: 2356-2356                       -->
<xsl:template name="dblprime-character">
    <xsl:text>&#x2033;</xsl:text>
</xsl:template>

<!-- Unicode Character 'LEFT SINGLE QUOTATION MARK' (U+2018) -->
<!-- Liblouis: 6-236                                         -->
<xsl:template name="lsq-character">
    <xsl:text>&#x2018;</xsl:text>
</xsl:template>

<!-- Unicode Character 'RIGHT SINGLE QUOTATION MARK' (U+2019) -->
<!-- Liblouis: 6-356                                          -->
<xsl:template name="rsq-character">
    <xsl:text>&#x2019;</xsl:text>
</xsl:template>

<!-- Unicode Character 'LEFT DOUBLE QUOTATION MARK' (U+201C) -->
<!-- Liblouis: 236                                           -->
<xsl:template name="lq-character">
    <xsl:text>&#x201C;</xsl:text>
</xsl:template>

<!-- Unicode Character 'RIGHT DOUBLE QUOTATION MARK' (U+201D) -->
<!-- Liblouis: 356                                            -->
<xsl:template name="rq-character">
    <xsl:text>&#x201D;</xsl:text>
</xsl:template>

<!-- Unicode Character 'LEFT ANGLE BRACKET' (U+3008) -->
<!-- Liblouis: 4-126                                 -->
<xsl:template name="langle-character">
    <xsl:text>&#x3008;</xsl:text>
</xsl:template>

<!-- Unicode Character 'RIGHT ANGLE BRACKET' (U+3009) -->
<!-- Liblouis: 4-345                                  -->
<xsl:template name="rangle-character">
    <xsl:text>&#x3009;</xsl:text>
</xsl:template>

<!-- Unicode Character 'HORIZONTAL ELLIPSIS' (U+2026) -->
<!-- Liblouis: 256-256-256                            -->
<!-- [BANA-2016] Appendix G, UEB is three periods/256 -->
<xsl:template name="ellipsis-character">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>

<!-- Unicode Character 'MIDDLE DOT' (U+00B7) -->
<!-- Liblouis: 4-16                          -->
<xsl:template name="midpoint-character">
    <xsl:text>&#x00B7;</xsl:text>
</xsl:template>

<!-- Unicode Character 'SWUNG DASH' (U+2053) -->
<!-- instead faking it with                  -->
<!-- Unicode Character 'TILDE' (U+007E)      -->
<xsl:template name="swungdash-character">
    <xsl:text>&#x007E;</xsl:text>
</xsl:template>

<!-- Unicode Character 'PILCROW SIGN' (U+00B6) -->
<!-- Liblouis: 45-1234                         -->
<xsl:template name="pilcrow-character">
    <xsl:text>&#x00B6;</xsl:text>
</xsl:template>

<!-- Unicode Character 'SECTION SIGN' (U+00A7) -->
<!-- Liblouis: 45-234                          -->
<xsl:template name="section-mark-character">
    <xsl:text>&#x00A7;</xsl:text>
</xsl:template>

<!-- Unicode Character 'MINUS SIGN' (U+2212) -->
<!-- Liblouis: 5-36                          -->
<xsl:template name="minus-character">
    <xsl:text>&#x2212;</xsl:text>
</xsl:template>

<!-- Unicode Character 'MULTIPLICATION SIGN' (U+00D7) -->
<!-- Liblouis: 5-236                                  -->
<xsl:template name="times-character">
    <xsl:text>&#x00D7;</xsl:text>
</xsl:template>

<!-- Unicode Character 'FRACTION SLASH' (U+2044) -->
<!-- instead faking it with                      -->
<!-- Unicode Character 'SOLIDUS' (U+002F)        -->
<xsl:template name="solidus-character">
    <xsl:text>&#x002F;</xsl:text>
</xsl:template>

<!-- Unicode Character 'DIVISION SIGN' (U+00F7) -->
<!-- Liblouis: 5-34                             -->
<xsl:template name="obelus-character">
    <xsl:text>&#x00F7;</xsl:text>
</xsl:template>

<!-- Unicode Character 'PLUS-MINUS SIGN' (U+00B1) -->
<!-- Liblouis: 456-235                            -->
<xsl:template name="plusminus-character">
    <xsl:text>&#x00B1;</xsl:text>
</xsl:template>

<!-- Icons -->
<!-- Just the four arrows, unsure about the rest -->
<!-- Arrows are in liblouis table                -->

<xsl:template match="icon">
    <xsl:choose>
        <xsl:when test="@name = 'arrow-left'">
            <xsl:text>&#x2190;</xsl:text>
        </xsl:when>
        <xsl:when test="@name ='arrow-up'">
            <xsl:text>&#x2191;</xsl:text>
        </xsl:when>
        <xsl:when test="@name = 'arrow-right'">
            <xsl:text>&#x2192;</xsl:text>
        </xsl:when>
        <xsl:when test="@name ='arrow-down'">
            <xsl:text>&#x2193;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>WARNING:  &quot;icon&quot; with @name attribute value "<xsl:value-of select="@name"/>" does not have an implementation for braille.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ############ -->
<!-- Font Changes -->
<!-- ############ -->

<!-- Certain PreTeXt groupings in running text naturally yield just  -->
<!-- a font change.  Braille and liblouis have facilities for italic -->
<!-- and bold.  This is "internal" markup that eventually gets       -->
<!-- interpreted by  lxml  in Python.                                -->

<!-- Italics -->
<xsl:template match="em|foreign|articletitle|pubtitle">
    <!-- Python will assume "italic" as element name -->
    <italic>
        <xsl:apply-templates select="node()"/>
    </italic>
</xsl:template>

<!-- Bold -->
<xsl:template match="term|alert">
    <!-- Python will assume "bold" as element name -->
    <bold>
        <xsl:apply-templates select="node()"/>
    </bold>
</xsl:template>

<!-- Biological Names -->
<xsl:template match="taxon">
    <!-- In italic font -->
    <italic>
        <xsl:choose>
            <!-- both substructures -->
            <xsl:when test="genus and species">
                <xsl:apply-templates select="genus"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="species"/>
            </xsl:when>
            <!-- just one -->
            <xsl:when test="genus">
                <xsl:apply-templates select="genus"/>
            </xsl:when>
            <!-- just the other one -->
            <xsl:when test="species">
                <xsl:apply-templates select="species"/>
            </xsl:when>
            <!-- not structured, use content -->
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </italic>
</xsl:template>

<!-- Code -->
<!-- Accomplished in UEB Grade 2, but with transcriber emphasis scheme 1 -->
<!-- from liblouis (where is this defined?).  See liblouis table         -->
<!-- "en-ueb-g1.ctb" for exact definition of emphasis code "trans1".     -->
<!--                                                                     -->
<!--     emphletter trans1 4-3456-23                                     -->
<!--     begemphword trans1 4-3456-2                                     -->
<!--     endemphword trans1 4-3456-3                                     -->
<!--     lenemphphrase trans1 3                                          -->
<!--     begemphphrase trans1 4-3456-2356                                -->
<!--     endemphphrase trans1 after 4-3456-3                             -->
<xsl:template name="code-wrapper">
    <xsl:param name="content"/>

    <code>
        <xsl:value-of select="$content"/>
    </code>
</xsl:template>

<!-- Pass-through/Dropped -->
<xsl:template match="abbr|acro|init">
    <xsl:apply-templates select="node()"/>
</xsl:template>

<!-- "idx" must be dealt with from source otherwise during    -->
<!-- index construction, but when encountered in a paragraph  -->
<!-- or a block they should just be killed.  Should never     -->
<!-- reach an interior "h".  Entirely similar for "notation"  -->
<!-- and an interior "usage", and "description".              -->

<xsl:template match="idx|notation"/>

<!-- Documenting PreText itself -->

<xsl:template match="tag">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>&gt;</xsl:text>
</xsl:template>

<xsl:template match="tage">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>/&gt;</xsl:text>
</xsl:template>

<xsl:template match="attr">
    <xsl:text>@</xsl:text>
    <xsl:value-of select="."/>
</xsl:template>

<!-- #### -->
<!-- Math -->
<!-- #### -->

<xsl:template match="m[not(contains(math-nemeth, '&#xa;'))]">
    <!-- Unicode braille cells from Speech Rule Engine (SRE)   -->
    <!-- Not expecting any markup, so "value-of" is everything -->
    <xsl:variable name="raw-braille">
        <xsl:value-of select="math-nemeth"/>
    </xsl:variable>
    <!-- We investigate actual source for very simple math   -->
    <!-- such as one-letter variable names as Latin letters  -->
    <!-- or positive integers, so we process the orginal     -->
    <!-- content outside of a MathJax/SRE translation (which -->
    <!-- could have "xref", etc)                             -->
    <xsl:variable name="content">
        <xsl:value-of select="math-original/node()"/>
    </xsl:variable>
    <xsl:variable name="original-content" select="normalize-space($content)"/>
    <!-- Note: this mark is *always* removed from the trailing text node,    -->
    <!-- so we need to *always* restore it.  In other wordds, we usually     -->
    <!-- put it into an attribute to get picked up by  lxml  in the Python.  -->
    <!-- But if we short-circuit that process here by turning integers into  -->
    <!-- digits or making single-letter variables unadorned, then we need to -->
    <!-- restore the mark in this template.                                  -->
    <xsl:variable name="clause-ending-mark">
        <xsl:apply-templates select="." mode="get-clause-punctuation-mark"/>
    </xsl:variable>
    <!-- Various cases, more specific first -->
    <xsl:choose>
        <!-- Inline math with just one Latin letter. No formatting,  -->
        <!-- no italics, according to BANA rules via Michael Cantino -->
        <!-- (2023-01-26) so drop-in $original.  C'est la vie.       -->
        <xsl:when test="(string-length($original-content) = 1) and contains(&ALPHABET;, $original-content)">
            <xsl:value-of select="$original-content"/>
            <!-- restore clause-ending punctuation -->
            <xsl:value-of select="$clause-ending-mark"/>
        </xsl:when>
        <!-- Test is true for non-negative integers, which we drop into -->
        <!-- the stream as if they were never authored as math anyway   -->
        <xsl:when test="translate($original-content, &DIGIT; ,'') = ''">
            <xsl:value-of select="$original-content"/>
            <!-- restore clause-ending punctuation -->
            <xsl:value-of select="$clause-ending-mark"/>
        </xsl:when>
        <!-- We construct a fragment for the Python formatter.   -->
        <!-- SRE may convert inline "m" into a spatial layout,   -->
        <!-- such as a fraction or column vector authored inline -->
        <!-- We treat this elsewhere, more like "md" elements    -->
        <xsl:otherwise>
            <math>
                <!-- Add punctuation as an attribute conditionally. -->
                <!-- We could probably just add an empty string     -->
                <!-- routinely and push that through to the closing -->
                <!-- Nemeth indicator, but we take a bit more care. -->
                <xsl:if test="not($clause-ending-mark = '')">
                    <xsl:attribute name="punctuation">
                        <xsl:value-of select="$clause-ending-mark"/>
                    </xsl:attribute>
                </xsl:if>
                <xsl:value-of select="$raw-braille"/>
            </math>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="m[contains(math-nemeth, '&#xa;')]|me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]">
    <xsl:variable name="nemeth">
        <xsl:value-of select="math-nemeth"/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>
    <block breakable="no" box="nemeth">
        <xsl:attribute name="punctuation">
            <xsl:apply-templates select="." mode="get-clause-punctuation-mark"/>
        </xsl:attribute>
        <xsl:call-template name="segmentize-display-math">
            <xsl:with-param name="display-math" select="$nemeth"/>
        </xsl:call-template>
    </block>
</xsl:template>

<xsl:template name="segmentize-display-math">
    <xsl:param name="display-math"/>

    <xsl:choose>
        <!-- done, nothing left to work on -->
        <xsl:when test="$display-math = ''"/>
        <xsl:otherwise>
            <!-- first line into a segment -->
            <segment>
                <xsl:call-template name="trim-nemeth-trailing-whitespace">
                   <xsl:with-param name="text" select="substring-before($display-math, '&#xa;')"/>
               </xsl:call-template>
            </segment>
            <!-- recurse on remainder -->
            <xsl:call-template name="segmentize-display-math">
                <xsl:with-param name="display-math" select="substring-after($display-math, '&#xa;')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Simple implementations of the basic -->
<!-- components of a cross-reference     -->

<!-- This device is just for the LaTeX conversion -->
<xsl:template match="*" mode="xref-number">
    <xsl:apply-templates select="." mode="number"/>
</xsl:template>

<!-- Nothing much to be done, we just -->
<!-- xerox the text representation    -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" />
    <xsl:param name="content" />

    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- #### -->
<!-- URLs -->
<!-- #### -->

<!-- Some technical debt: these to variables (or at least one) should -->
<!-- perhaps be placed in -common rather than duplicating them.       -->

<!-- 2023-03-06: these two vraiables have been copied verbatim from the HTML conversion -->

<xsl:template match="url|dataurl">
    <!-- link/reference/location may be external -->
    <!-- (@href) or internal (dataurl[@source])  -->
    <xsl:variable name="uri">
        <xsl:choose>
            <!-- "url" and "dataurl" both support external @href -->
            <xsl:when test="@href">
                <xsl:value-of select="@href"/>
            </xsl:when>
            <!-- a "dataurl" might be local, @source is      -->
            <!-- indication, so prefix with a local path/URI -->
            <xsl:when test="self::dataurl and @source">
                <!-- empty when not using managed directories -->
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:when>
            <!-- empty will be non-functional -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <!-- visible portion of HTML is the URL itself,   -->
    <!-- formatted as code, or content of PTX element -->
    <xsl:variable name="visible-text">
        <xsl:choose>
            <xsl:when test="node()">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <code class="code-inline tex2jax_ignore">
                    <xsl:choose>
                        <xsl:when test="@visual">
                            <xsl:value-of select="@visual"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$uri"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </code>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:value-of select="$visible-text"/>
</xsl:template>


<!-- ######### -->
<!-- Footnotes -->
<!-- ######### -->

<!-- Drop a mark at sight, Need to devise an        -->
<!-- add-on to division-processing to make endnotes -->
<!-- [BANA-2016] 16.1.4(g): (print observations)  -->
<!-- In a note section, either at the end of each -->
<!-- chapter or at the back of the book.          -->
<!-- [BANA-2016] 16.1.5(c): (braille placement)   -->
<!-- At the end of the chapter or volume.         -->

<!-- BANA 16.2.2: superscripted number          -->
<!-- (two-cell indicator, number sign, number). -->
<!-- TODO: collect footnote *content* at division ends -->
<xsl:template match="fn">
    <!--  5-6  3-5  -->
    <xsl:text>&#x2830;&#x2814;</xsl:text>
    <!-- A number sign is supplied by liblouis translation -->
    <!-- 2-4-5-6  U+283C                                   -->
    <xsl:apply-templates select="." mode="number"/>
    <!-- trailing space necessary to end superscript?  -->
    <!-- will get merged with any that already exists? -->
    <xsl:text> </xsl:text>
</xsl:template>


<!-- ################# -->
<!-- Verbatim, Program -->
<!-- ################# -->

<!-- Various templates elsewhere manipulate large chunks of verbatim text, -->
<!-- such as for a "program".  We leverage those as much as possible.      -->
<!-- Ideally we easily get a chunk of text, given as a sequence of lines   -->
<!-- defined by newline characters.   The recursive "braille-source-code"  -->
<!-- template makes a "segment" for each line, this will allow for runover -->
<!-- and *code* indentation without any ambiguity.  So most of the braille -->
<!-- formatting happens in this template.                                  -->
<!--                                                                       -->
<!-- IMPORTANT: ensure that $text has a final newline character.           -->

<xsl:template name="braille-source-code">
    <xsl:param name="text"/>

    <xsl:choose>
        <!-- $text always ends in a newline, so final recursive call will    -->
        <!-- have an empty string.  This is the indication that we are done. -->
        <xsl:when test="$text = ''"/>
        <!-- Nonempty $text, so split it, and recurse -->
        <xsl:otherwise>
            <segment indentation="0" runover="0">
                <code>
                    <xsl:value-of select="substring-before($text, '&#xa;')"/>
                </code>
            </segment>
            <xsl:call-template name="braille-source-code">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A "cd" is structured with "cline" or not.  We do not sanitize, that   -->
<!-- tis what the "cline"element is for - control over leading whitespace. -->
<!-- We provide a final newline here for a bare "cd", otherwise the        -->
<!-- "cline" template provides it.                                         -->
<xsl:template match="cd">
    <block breakable="no">
        <xsl:call-template name="braille-source-code">
            <xsl:with-param name="text">
                <xsl:choose>
                    <xsl:when test="cline">
                        <xsl:apply-templates select="cline"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                        <xsl:text>&#xa;</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </block>
</xsl:template>

<!-- "pre" and "pre[cline]" are handled by the "interior" -->
<!-- modal template in -common.                           -->
<!-- "pre" uses "sanitize-text", which provides a final   -->
<!-- newline, while "pre[cline]" uses the base "cline"    -->
<!-- template, which also provides a final newline.       -->
<xsl:template match="pre">
    <block breakable="no">
        <xsl:call-template name="braille-source-code">
            <xsl:with-param name="text">
                <xsl:apply-templates select="." mode="interior"/>
            </xsl:with-param>
        </xsl:call-template>
    </block>
</xsl:template>

<!-- A "program" gets a lot of treatment in other formats to recognize   -->
<!-- the language an author specifies and then do some sort of syntax    -->
<!-- highlighting with fonts and colors.  That would be hard in braille, -->
<!-- and we don't know of a good tool anyway.  So we just echo the       -->
<!-- "input" portion.                                                    -->
<!-- "sanitize-text" provides a final newline, always                    -->
<xsl:template match="program">
    <!-- build up full program text so we can apply sanitize-text to entire blob -->
    <!-- and thus allow relative indentation for preamble/code/postamble         -->
    <xsl:variable name="program-text">
        <xsl:variable name="program-text">
            <xsl:if test="preamble[not(@visible = 'no')]">
                <xsl:call-template name="substring-before-last">
                    <xsl:with-param name="input" select="preamble" />
                    <xsl:with-param name="substr" select="'&#xA;'" />
                </xsl:call-template>
            </xsl:if>
            <xsl:call-template name="substring-before-last">
                <xsl:with-param name="input" select="code" />
                <xsl:with-param name="substr" select="'&#xA;'" />
            </xsl:call-template>
            <xsl:text>&#xA;</xsl:text>
            <xsl:if test="postamble[not(@visible = 'no')]">
                <xsl:value-of select="substring-after(postamble,'&#xA;')" />
            </xsl:if>
        </xsl:variable>
    </xsl:variable>
    <block breakable="no">
        <xsl:call-template name="braille-source-code">
            <xsl:with-param name="text">
                <xsl:call-template name="sanitize-text">
                    <xsl:with-param name="text" select="$program-text" />
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </block>
</xsl:template>

<!-- For a "console" session, we work hardest on the "input", pulling in -->
<!-- a preceding prompt, and considering the possibility of no "output". -->
<!-- For "output", if extant, we provide necessary separators.           -->

<xsl:template match="console">
    <!-- entire session as a block -->
    <block breakable="no" lines-before="1" lines-after="1">
        <!-- respect authored order, so don't split these -->
        <xsl:apply-templates select="input|output"/>
    </block>
</xsl:template>

<xsl:template match="console/input">
    <xsl:variable name="console-input">
        <!-- prompt first, if provided; author provides -->
        <!-- any space that prompt would create         -->
        <xsl:value-of select="preceding-sibling::*[1][self::prompt]"/>
        <!-- remainder of the input -->
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
    </xsl:variable>
    <!-- now feed to braille-ification -->
    <xsl:call-template name="braille-source-code">
        <xsl:with-param name="text" select="$console-input"/>
    </xsl:call-template>
    <!-- add a blank line, only when not provided by the output -->
    <xsl:if test="not(following-sibling::*[1][self::output])">
        <segment lines-before="1"/>
    </xsl:if>
</xsl:template>

<xsl:template match="console/output">
    <xsl:variable name="console-output">
        <!-- separate from the input -->
        <!-- NB: newline here necessary for textual version -->
        <xsl:text>---------------&#xa;</xsl:text>
        <!-- remainder of the input -->
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
    </xsl:variable>
    <!-- now feed to braille-ification -->
    <xsl:call-template name="braille-source-code">
        <xsl:with-param name="text" select="$console-output"/>
    </xsl:call-template>
    <!-- and a blank line to help with session -->
    <segment lines-before="1"/>
</xsl:template>

<!-- Sage cells rely on per-conversion overrides of presumed   -->
<!-- abstract templates, to handle the numerous possibilities. -->
<!-- Using a long line to simulate input/output split          -->

<xsl:template match="sage" mode="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />

    <block breakable="no" lines-before="1" lines-after="1">
        <xsl:call-template name="braille-source-code">
            <xsl:with-param name="text" select="$in"/>
        </xsl:call-template>

        <xsl:if test="not($out = '')">
            <segment>
                <xsl:text>-----------------</xsl:text>
            </segment>
            <xsl:call-template name="braille-source-code">
                <xsl:with-param name="text" select="$out"/>
            </xsl:call-template>
        </xsl:if>
    </block>
</xsl:template>

<!-- Display only, just input -->
<xsl:template name="sage-display-markup">
    <xsl:param name="in" />

    <block breakable="no" lines-before="1" lines-after="1">
        <xsl:call-template name="braille-source-code">
            <xsl:with-param name="text" select="$in"/>
        </xsl:call-template>
    </block>
</xsl:template>


<!-- ############# -->
<!-- Miscellaneous -->
<!-- ############# -->

<!-- Containers that have zero metadata (no title, etc.) -->
<xsl:template match="statement|introduction|conclusion">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Just text nodes, but might have a WeBWorK -->
<!-- "var", so process all children            -->
<xsl:template match="shortdescription">
    <xsl:apply-templates/>
</xsl:template>

<!-- fillin blanks, outside math -->
<!-- A fillin inside math will have disappeared on us by now, -->
<!-- it was mixed into some LaTeX syntax and has been gobbled -->
<!-- up by MathJax by now.  So the conditional here is really -->
<!-- moot and not necessary.                                  -->
<!-- [BANA, 2016] 10.6.2 and Michael Cantino: an underscore   -->
<!-- Seems to translate as a "sign": 46-36 in liblouis table  -->
<xsl:template match="fillin[not(parent::m or parent::me or parent::men or parent::md[not(mrow)] or parent::mdn[not(mrow)] or parent::mrow)]">
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Fillin blanks, inside math -->
<!-- For math see https://nemeth.aphtech.org/lesson3.5 4x U+2824 -->

<!-- ############ -->
<!-- EXPERIMENTAL -->
<!-- ############ -->

<!-- A paragraph without "displays" is straightforward and -->
<!-- we can bypass the more complicated procedure next.    -->
<xsl:template match="p">
    <segment indentation="2">
        <xsl:apply-templates select="node()"/>
    </segment>
</xsl:template>

<!-- Two-dimensional displayed itmes will get their own segment and   -->
<!-- we will explode the rest of a "p" into pieces that are segments. -->
<!-- But with indentation only on the first piece.                    -->
<!-- Note: leading with a display in a "p" means no indentation.      -->
<!-- Note: this is derived from a similar template in the HTML        -->
<!-- conversion.                                                      -->
<xsl:template match="p[ol|ul|dl|m[contains(math-nemeth, '&#xa;')]|me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]|cd]">
    <!-- will later loop over displays within paragraph      -->
    <!-- match guarantees at least one for $initial variable -->
    <xsl:variable name="displays" select="ul|ol|dl|m[contains(math-nemeth, '&#xa;')]|me|men|md[not(mrow)]|mdn[not(mrow)]|md[mrow]|mdn[mrow]|cd" />
    <!-- content prior to first display is exceptional, but if empty,   -->
    <!-- as indicated by $initial, we do not produce an empty paragraph -->
    <!--                                                                -->
    <!-- all interesting nodes of paragraph, before first display       -->
    <xsl:variable name="initial" select="$displays[1]/preceding-sibling::node()"/>
    <xsl:variable name="initial-content">
        <xsl:apply-templates select="$initial"/>
    </xsl:variable>
    <xsl:if test="not(normalize-space($initial-content) = '')">
        <segment indentation="2">
            <xsl:apply-templates select="$initial"/>
        </segment>
    </xsl:if>
    <!-- for each display, output the display, plus trailing content -->
    <xsl:for-each select="$displays">
        <!-- do the display proper -->
        <xsl:apply-templates select="."/>
        <!-- look through remainder, all element and text nodes, and the next display -->
        <xsl:variable name="rightward" select="following-sibling::node()" />
        <xsl:variable name="next-display" select="following-sibling::*[self::ul or self::ol or self::dl or self::m[contains(math-nemeth, '&#xa;')] or self::me or self::men or self::md[not(mrow)] or self::mdn[not(mrow)] or self::md[mrow] or self::mdn[mrow] or self::cd][1]" />
        <xsl:choose>
            <xsl:when test="$next-display">
                <xsl:variable name="leftward" select="$next-display/preceding-sibling::node()" />
                <!-- device below forms set intersection -->
                <xsl:variable name="common" select="$rightward[count(. | $leftward) = count($leftward)]" />
                <!-- Careful, punctuation after display math      -->
                <!-- gets absorbed into display and so is a node  -->
                <!-- that produces no content (cannot just count) -->
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$common"/>
                </xsl:variable>
                <xsl:if test="not(normalize-space($common-content) = '')">
                    <segment>
                        <xsl:apply-templates select="$common"/>
                    </segment>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- finish the trailing content, if nonempty -->
                <xsl:variable name="final-content">
                    <xsl:apply-templates select="$rightward"/>
                </xsl:variable>
                <xsl:if test="not(normalize-space($final-content) = '')">
                    <segment>
                        <xsl:apply-templates select="$rightward"/>
                    </segment>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
</xsl:template>

<!-- We support books and articles, though nothing in particular -->
<!-- needs to be done at these root elements.  Yet?              -->
<xsl:template match="book|article">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- "docinfo" should *always* be mined directly for pieces that affect output -->
<xsl:template match="docinfo"/>

<!-- Many pieces of the "frontmatter" have templates designed for divisions -->
<xsl:template match="frontmatter">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- The "titlepage" and front "colophon" should be mined to form front -->
<!-- matter material in the right places, etc.  We kill them for now so -->
<!-- we don't see their children being overlooked.                      -->
<xsl:template match="titlepage"/>
<xsl:template match="frontmatter/colophon"/>

<!-- Many pieces of the "backmatter" have templates designed for divisions -->
<xsl:template match="backmatter">
    <xsl:apply-templates select="*"/>
</xsl:template>


<!-- ############ -->
<!-- EXPERIMENTAL -->
<!-- ############ -->

<!-- Uncaught elements for debugging reporting                     -->
<!-- These elements have full implementations in -common, or       -->
<!-- partial/abstract implementations which we extend hee.         -->
<!-- So we just hit them with "apply-imports" so they do not       -->
<!-- all into the (temporary, development) template below          -->
<!-- reporting missed elements.   "Commenting out this template    -->
<!-- should have zero effect, except to generate more debugging    -->
<!-- messages, since this reporting template will take precedence. -->

<!-- "apply-imports" items necessary during development -->

<!-- nbsp, ndash, mdash characters defined above -->
<xsl:template match="nbsp|ndash|mdash">
    <xsl:apply-imports/>
</xsl:template>

<!-- empty elements, characters, defined above -->
<xsl:template match="copyright|registered|trademark|degree|prime|dblprime|lsq|rsq|lq|rq|langle|rangle|ellipsis|midpoint|pilcrow|section-mark|minus|times|obelus|plusminus">
    <xsl:apply-imports/>
</xsl:template>

<!-- These elements/characters lack translations in liblouis.      -->
<!-- We get/use their versions in -common, which will throw an     -->
<!-- "unimplemented character" warning, which is accurate now,     -->
<!-- *and* accurate later when the "overlooked" warning goes away. -->
<!-- As characters get implemented, move to above template         -->
<!-- (in proper order) as a way to keep track of the situation.    -->
<xsl:template match="phonomark|copyleft|servicemark|ldblbracket|rdblbracket|swungdash|permille|solidus">
    <xsl:apply-imports/>
</xsl:template>

<!-- Groupings, based on characters defined above -->
<!-- dblbrackets raises warnings since left/right -->
<!-- characters are not implemented               -->
<xsl:template match="q|sq|dblbrackets|angles">
    <xsl:apply-imports/>
</xsl:template>

<!-- xref-number, xref-link defined above -->
<xsl:template match="xref">
    <xsl:apply-imports/>
</xsl:template>

<!-- pure text in -common -->
<xsl:template match="today|timeofday">
    <xsl:apply-imports/>
</xsl:template>

<!-- Latin Abbreviations -->
<!-- Fully defined as text in -common, including an "abbreviation-period" -->
<xsl:template match="ad|am|bc|ca|eg|etal|etc|ie|nb|pm|ps|vs|viz">
    <xsl:apply-imports/>
</xsl:template>

<!-- titles get killed in -common so we don't need to see them here -->
<xsl:template match="title|subtitle|shorttitle|plaintitle|creator">
    <xsl:apply-imports/>
</xsl:template>

<!-- captions get killed in -common so we don't need to see them here -->
<xsl:template match="caption">
    <xsl:apply-imports/>
</xsl:template>

<!-- We expect the simple template in -common to be active -->
<xsl:template match="cline">
    <xsl:apply-imports/>
</xsl:template>

<!-- We expect the simple template in -common to be active -->
<xsl:template match="c">
    <xsl:apply-imports/>
</xsl:template>

<!-- Action is in -common, this will catch all occurences? -->
<xsl:template match="sage">
    <xsl:apply-imports/>
</xsl:template>

<!-- Localizations happen in -common, so need the "rename" template there -->
<xsl:template match="rename">
    <xsl:apply-imports/>
</xsl:template>


<!-- Larger structures, needing implementation, *along with* interior -->
<!-- structures.  We report AND include a textual place holder.       -->

<xsl:template match="notation-list">
    <xsl:text>NOTATIONLIST</xsl:text>
</xsl:template>

<xsl:template match="index-list">
    <xsl:text>INDEXLIST</xsl:text>
</xsl:template>

<xsl:template match="poem">
    <segment>POEM</segment>
</xsl:template>

<!-- Next two are not structures, so as "text" -->

<xsl:template match="quantity">
    <xsl:text>QUANTITY</xsl:text>
</xsl:template>

<xsl:template match="kbd">
    <xsl:text>KBD</xsl:text>
</xsl:template>

<xsl:template name="missing-warning">
    <xsl:if test="//notation-list">
        <xsl:call-template name="missing-implementation">
            <xsl:with-param name="element" select="'notation-list'"/>
            <xsl:with-param name="ntimes" select="count(//notation-list)"/>
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:if test="//index-list">
        <xsl:call-template name="missing-implementation">
            <xsl:with-param name="element" select="'index-list'"/>
            <xsl:with-param name="ntimes" select="count(//index-list)"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:if test="//poem">
        <xsl:call-template name="missing-implementation">
            <xsl:with-param name="element" select="'poem'"/>
            <xsl:with-param name="ntimes" select="count(//poem)"/>
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:if test="//quantity">
        <xsl:call-template name="missing-implementation">
            <xsl:with-param name="element" select="'quantity'"/>
            <xsl:with-param name="ntimes" select="count(//quantity)"/>
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:if test="//kbd">
        <xsl:call-template name="missing-implementation">
            <xsl:with-param name="element" select="'kbd'"/>
            <xsl:with-param name="ntimes" select="count(//kbd)"/>
        </xsl:call-template>
    </xsl:if>
    <!--  -->
</xsl:template>

<xsl:template name="missing-implementation">
    <xsl:param name="element"/>
    <xsl:param name="ntimes"/>

    <xsl:message>Unimplemented: <xsl:value-of select="$element"/> (<xsl:value-of select="$ntimes"/> times)</xsl:message>
</xsl:template>

<xsl:template match="*" mode="overlooked">
    <xsl:message>Overlooked: <xsl:value-of select="local-name()"/></xsl:message>
</xsl:template>

<!-- *Every* element needs an implementation, or it ends up here being -->
<!-- reported as overlooked.  This is temporary during development.    -->
<xsl:template match="*">
    <xsl:apply-templates select="." mode="overlooked"/>
    <!-- <xsl:message>Overlooked: <xsl:value-of select="local-name()"/></xsl:message> -->
    <!-- recurse into child elements to find more "missing" elements -->
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

<!-- Transcriber Notes -->

<!-- Here code is the transcriber, so we can explain places where we   -->
<!-- have done something different than it might be realized in print. -->
<!--                                                                   -->
<!-- [BANA 2016] 3.2.1                                                 -->
<!-- Two three-cell sequences indicate the begin and end of a          -->
<!-- transcriber note.  Additionally, the indentation is 7-5 margins.  -->
<!--                                                                   -->
<!-- The content provided in the "message" parameter by a calling      -->
<!-- instance will be placed into a segment, so this is not an         -->
<!-- "embedded" note (which is for seven words or less).  Content can  -->
<!-- contain the *internal* markup used here, such as "italic" or      -->
<!-- "bold", and that will be copied into the note for processing when -->
<!-- converted to braille                                              -->
<!--                                                                   -->
<!-- Template could be context-free for literal messages, but the      -->
<!-- $message will sometimes come from the context of an element       -->
<!-- (e.g. the "shortdescription" of an "image")                       -->
<xsl:template match="*" mode="transcriber-note">
    <xsl:param name="message"/>

    <segment indentation="7" runover="5">
        <!-- dot 4, dot 46, dot 126 -->
        <xsl:text>&#x2808;&#x2828;&#x2823;</xsl:text>
        <!-- *Copy* literal markup, or result of applying templates -->
        <xsl:copy-of select="$message"/>
        <!-- dot 4, dot 46, dot 345 -->
        <xsl:text>&#x2808;&#x2828;&#x281C;</xsl:text>
    </segment>
</xsl:template>


</xsl:stylesheet>
