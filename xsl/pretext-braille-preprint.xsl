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

<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<xsl:variable name="exercise-style" select="'static'"/>

<!-- Not so much "include" as "manipulate"            -->
<!-- Switch to "all" when display math is accomodated -->
<xsl:param name="math.punctuation.include" select="'inline'"/>

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
<xsl:template match="m|me|men|md|mdn" mode="meld-math">
    <!-- preserve author's element -->
    <xsl:copy>
        <!-- preserve attributes -->
        <xsl:apply-templates select="@*" mode="meld-math"/>
        <!-- get braille from representations file -->
        <xsl:variable name="id">
            <xsl:apply-templates select="." mode="internal-id"/>
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
<!-- (exercises|worksheet|reading-questions|solutions|references|glossary) -->

<xsl:variable name="b-has-level-four" select="boolean(
      $document-root//subsubsection
    | $document-root//subsection/exercises
    | $document-root//subsection/worksheet
    | $document-root//subsection/reading-questions
    | $document-root//subsection/solutions
    | $document-root//subsection/references
    | $document-root//subsection/glossary)"/>

<xsl:variable name="b-has-level-five" select="boolean(
      $document-root//subsubsection/exercises
    | $document-root//subsubsection/worksheet
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
    <xsl:apply-templates select="$root"/>
</xsl:variable>

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
        <segment>Temporary Transcriber Notes: </segment>
        <!-- See "c" template for explanation -->
        <segment>1. Literal, or verbatim, computer code used in sentences is indicated by a set of transcriber-defined emphasis given by the following indicators, which all begin with the two cells dot-4 and dot-3456.  Single letter: 4-3456-23.  Begin, end word: 4-3456-2, 4-3456-3.  Begin, end phrase: 4-3456-2356, 4-3456-3.</segment>
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
<xsl:template match="chapter|appendix|index[index-list]|index-part|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|slide|exercises|worksheet|reading-questions|solutions|references|glossary">

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
<xsl:template match="part|chapter|appendix|index[index-list]|index-part|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|slide|exercises|worksheet|reading-questions|solutions|references|glossary" mode="braille-level">
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
<xsl:template match="chapter|appendix|index[index-list]|index-part|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|slide|exercises|worksheet|reading-questions|solutions|references|glossary" mode="heading-style">
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
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&OPENPROBLEM-LIKE;|exercise[&INLINE-EXERCISE-FILTER;]">
    <block box="standard" lines-before="1" lines-after="1">
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

<!-- Should be run-in with automatic space afterward -->
<!-- There may be multiple proofs, but we do not number them at birth, -->
<!-- the number only gets used in a cross-reference.  Maybe standalone -->
<!-- is different??                                                    -->
<!-- TENTATIVE: DISCUSSION-LIKE may be identical                       -->
<xsl:template match="&PROOF-LIKE;|&DISCUSSION-LIKE;" mode="block-title">
        <runin indentation="0" lines-before="1" separator="&#x20;&#x20;">
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
    <runin indentation="0" lines-before="1" separator="&#x20;&#x20;">
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
    <runin indentation="0" lines-before="1" separator="&#x20;&#x20;">
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

<!-- TODO: GOAL-LIKE -->

<!-- ########### -->
<!-- FIGURE-LIKE -->
<!-- ########### -->


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

<xsl:template match="copyright">
    <xsl:text>(c)</xsl:text>
</xsl:template>

<!-- [BANA-2016] Appendix G                 -->
<!-- Says UEB uses three periods (dots-256) -->
<!-- liblouis seems to translate as such    -->
<xsl:template match="ellipsis">
    <xsl:text>...</xsl:text>
</xsl:template>


<!-- Empty Elements, Characters -->

<!-- Unicode Character 'NO-BREAK SPACE' (U+00A0)     -->
<!-- yields a template for "nbsp" in -common         -->
<!-- liblouis seems to pass this through in-kind     -->
<!-- Used in teh manufacture of a cross-reference,   -->
<!--we'll want to strip just before it eds up in BRF -->
<xsl:template name="nbsp-character">
    <xsl:text>&#x00A0;</xsl:text>
</xsl:template>

<!-- Unicode Character 'EN DASH' (U+2013) -->
<!-- Seems to become ",-"                 -->
<xsl:template name="ndash-character">
    <xsl:text>&#x2013;</xsl:text>
</xsl:template>

<!-- Unicode Character 'EM DASH' (U+2014) -->
<!-- Seems to also become ",-"            -->
<xsl:template name="mdash-character">
    <xsl:text>&#x2014;</xsl:text>
</xsl:template>

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
<xsl:template match="c">
    <code>
        <xsl:apply-templates select="node()"/>
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

<!-- non-breaking space -->
<!-- will liblouis preserve? -->
<!-- or do we need markup for page-formatting? -->

<!-- Groupings -->

<xsl:template match="q">
    <xsl:text>"</xsl:text>
    <xsl:apply-templates select="node()"/>
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template match="sq">
    <xsl:text>'</xsl:text>
    <xsl:apply-templates select="node()"/>
    <xsl:text>'</xsl:text>
</xsl:template>



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

<xsl:template match="m">
    <!-- Unicode braille cells from Speech Rule Engine (SRE)   -->
    <!-- Not expecting any markup, so "value-of" is everything -->
    <xsl:variable name="raw-braille">
        <xsl:value-of select="math-nemeth"/>
    </xsl:variable>
    <!-- inline vs. spatial makes a difference -->
    <xsl:variable name="b-multiline" select="contains($raw-braille, '&#xa;')"/>
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
        <!-- We construct a fragment for teh Python formatter.   -->
        <!-- SRE may convert inline "m" into a spatial layout,   -->
        <!-- such as a fraction or column vector authored inline -->
        <!-- We ignore this situation for now                    -->
        <xsl:when test="not($b-multiline)">
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
        </xsl:when>
        <xsl:otherwise>
            <!-- TEMPORARY: Multi-line case -->
            <xsl:text>INLINE MATH (RENDERED WITH NEWLINES)</xsl:text>
            <!-- restore clause-ending punctuation -->
            <xsl:value-of select="$clause-ending-mark"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="me|men|md|mdn">
    <xsl:variable name="nemeth">
        <xsl:value-of select="math-nemeth"/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>
    <block box="nemeth">
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
                <xsl:apply-templates />
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

<!-- See BANA 16.2.2 for superscripted number (two-cell indicator, number sign, number). -->
<xsl:template match="fn">
    <xsl:text> [</xsl:text>
    <xsl:apply-templates select="." mode="number"/>
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- ############# -->
<!-- Miscellaneous -->
<!-- ############# -->

<!-- Containers that have zero metadata (no title, etc.) -->
<xsl:template match="statement|introduction|conclusion">
    <xsl:apply-templates select="*"/>
</xsl:template>

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
<xsl:template match="p[ol|ul|dl|me|men|md|mdn|cd]">
    <!-- will later loop over displays within paragraph      -->
    <!-- match guarantees at least one for $initial variable -->
    <xsl:variable name="displays" select="ul|ol|dl|me|men|md|mdn|cd" />
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
        <xsl:variable name="next-display" select="following-sibling::*[self::ul or self::ol or self::dl or self::me or self::men or self::md or self::mdn or self::cd][1]" />
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

<!-- segment with placeholder content at this stage -->
<xsl:template match="ol|ul|dl">
    <segment>LIST</segment>
</xsl:template>

<!-- segment with placeholder content at this stage -->
<xsl:template match="cd">
    <segment>CODE DISPLAY</segment>
</xsl:template>

<!-- segment with placeholder content at this stage -->
<xsl:template match="tabular">
    <segment>TABULAR</segment>
</xsl:template>

<!-- segment with placeholder content at this stage -->
<xsl:template match="pre">
    <segment>PREFORMATTED TEXT</segment>
</xsl:template>

<!-- segment with placeholder content at this stage -->
<xsl:template match="program">
    <segment>PROGRAM</segment>
</xsl:template>

<!-- segment with placeholder content at this stage -->
<xsl:template match="image">
    <segment>IMAGE</segment>
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

<xsl:template match="nbsp|ndash|mdash|xref">
    <xsl:apply-imports/>
</xsl:template>

<!-- titles get killed in -common so we don't need to see them here -->
<xsl:template match="title|subtitle|shorttitle|plaintitle|creator">
    <xsl:apply-imports/>
</xsl:template>

<xsl:template match="*">
    <!-- target informative messages to "blocks" being considered -->
    <xsl:if test="ancestor::p">
        <xsl:message>Pass: <xsl:value-of select="local-name()"/></xsl:message>
    </xsl:if>
    <!-- recurse into child elements to find more "missing" elements -->
    <xsl:apply-templates select="*"/>
</xsl:template>

</xsl:stylesheet>
