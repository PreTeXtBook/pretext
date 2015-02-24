<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2013 Robert A. Beezer

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

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" 
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl date"
    xmlns:mb="http://mathbook.pugetsound.edu/"
    exclude-result-prefixes="mb"
>

<!-- MathBook XML common templates                        -->
<!-- Text creation/manipulation common to HTML, TeX, Sage -->

<!-- So output methods here are just text -->
<xsl:output method="text" />

<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!-- These here are independent of the output format as well                  -->
<!--                                                                          -->
<!-- An exercise has a statement, and may have a hint,     -->
<!-- an answer and a solution.  An answer is just the      -->
<!-- final number, expression, whatever; while a solution  -->
<!-- includes intermediate steps. Parameters here control  -->
<!-- what is visible where.                                -->
<!--                                                       -->
<!-- Parameters are:                                       -->
<!--   'yes' - immediately visible                         -->
<!--   'knowl' - adjacent, but requirres action to reveal  -->
<!--   'no' - not visible at all                           -->
<!--                                                       -->
<!-- First, an exercise in exercises section.              -->
<!-- Default is "yes" for every part, so experiment        -->
<!-- with parameters to make some parts hidden.            -->
<xsl:param name="exercise.text.statement" select="'yes'" />
<xsl:param name="exercise.text.hint" select="'yes'" />
<xsl:param name="exercise.text.answer" select="'yes'" />
<xsl:param name="exercise.text.solution" select="'yes'" />
<!-- Second, an exercise in solutions list in backmatter.  -->
<xsl:param name="exercise.backmatter.statement" select="'yes'" />
<xsl:param name="exercise.backmatter.hint" select="'yes'" />
<xsl:param name="exercise.backmatter.answer" select="'yes'" />
<xsl:param name="exercise.backmatter.solution" select="'yes'" />
<!-- Author tools are for drafts, mostly "todo" items                 -->
<!-- and "provisional" citations and cross-references                 -->
<!-- Default is to hide todo's, inline provisionals                   -->
<!-- Otherwise ('yes'), todo's in red paragraphs, provisionals in red -->
<xsl:param name="author-tools" select="'no'" />
<!-- Cross-references like Section 5.2, Theorem 6.7.89    -->
<!-- "know" what they point to, so we can get the "name"  -->
<!-- part automatically (and have it change with editing) -->
<!-- This switch is global, override with @autoname='no'  -->
<!-- on an <xref> where it is unjustified or a problem    -->
<!-- Default is to have this feature off                  -->
<xsl:param name="autoname" select="'no'" />
<!-- How many levels to table of contents  -->
<!-- Not peculiar to HTML or LaTeX or etc. -->
<!-- Sentinel indicates no choice made     -->
<xsl:param name="toc.level" select="''" />
<!-- How many levels in numbering of theorems, etc     -->
<!-- Followed by a sequential number across that level -->
<!-- For example "2" implies Theorem 5.3.12 is         -->
<!-- 12-th theorem, lemma, etc in 5.2                  -->
<xsl:param name="numbering.theorems.level" select="''" />
<!-- How many levels in numbering of equations     -->
<!-- Analagous to numbering theorems, but distinct -->
<xsl:param name="numbering.equations.level" select="''" />
<!-- Level where footnote numbering resets                                -->
<!-- For example, "2" would be sections in books, subsections in articles -->
<xsl:param name="numbering.footnotes.level" select="''" />
<!-- Last level where subdivision (section) numbering takes place     -->
<!-- For example, "2" would mean subsections of a book are unnumbered -->
<!-- N.B.: the levels above cannot be numerically larger              -->
<xsl:param name="numbering.maximum.level" select="''" />
<!-- Image files, media files and knowls are placed in directories    -->
<!-- The defaults are relative to wherever principal output goes      -->
<!-- These can be overridden at the command-line or in customizations -->
<xsl:param name="directory.images" select="'images'" />
<xsl:param name="directory.media"  select="'media'" />
<xsl:param name="directory.knowls" select="'knowls'" />
<!-- Table captions can be placed above or below the table -->
<!-- according to the value of table.caption.position      -->
<xsl:param name="table.caption.position" select="'below'" />
<!-- Strip whitespace text nodes from container elements                    -->
<!-- Improve source readability with whitespace control in text output mode -->
<!-- Newlines with &#xa; : http://stackoverflow.com/questions/723226/producing-a-new-line-in-xslt -->
<!-- Removing whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->
<xsl:strip-space elements="mathbook book article letter" />
<xsl:strip-space elements="frontmatter chapter appendix section subsection subsubsection exercises references introduction conclusion paragraph subparagraph backmatter" />
<xsl:strip-space elements="docinfo author abstract" />
<xsl:strip-space elements="titlepage preface acknowledgement biography foreword dedication colophon" />
<xsl:strip-space elements="theorem corollary lemma proposition claim fact conjecture proof" />
<xsl:strip-space elements="definition axiom principle" />
<xsl:strip-space elements="statement" />
<xsl:strip-space elements="example remark exercise hint solution" />
<xsl:strip-space elements="exercisegroup" />
<xsl:strip-space elements="note" />  <!-- TODO: biblio, record, etc too -->
<xsl:strip-space elements="ul ol dl" />
<xsl:strip-space elements="md mdn" />
<xsl:strip-space elements="sage figure index" />
<xsl:strip-space elements="table tgroup thead tbody row coltypes col" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<xsl:variable name="toc-level">
    <xsl:choose>
        <xsl:when test="$toc.level != ''">
            <xsl:value-of select="$toc.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article and /mathbook/article/section">1</xsl:when>
        <xsl:when test="/mathbook/article">0</xsl:when>
        <xsl:when test="/mathbook/letter">0</xsl:when>
        <xsl:when test="/mathbook/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Table of Contents level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- User-supplied Numbering for Theorems, etc    -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-theorems">
    <xsl:choose>
        <xsl:when test="$numbering.theorems.level != ''">
            <xsl:value-of select="$numbering.theorems.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article and /mathbook/article/section">1</xsl:when>
        <xsl:when test="/mathbook/article">0</xsl:when>
        <xsl:when test="/mathbook/letter">0</xsl:when>
        <xsl:when test="/mathbook/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Theorem numbering level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- User-supplied Numbering for Equations    -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-equations">
    <xsl:choose>
        <xsl:when test="$numbering.equations.level != ''">
            <xsl:value-of select="$numbering.equations.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article and /mathbook/article/section">1</xsl:when>
        <xsl:when test="/mathbook/article">0</xsl:when>
        <xsl:when test="/mathbook/letter">0</xsl:when>
        <xsl:when test="/mathbook/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Equation numbering level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- User-supplied Numbering for Footnotes        -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-footnotes">
    <xsl:choose>
        <xsl:when test="$numbering.footnotes.level != ''">
            <xsl:value-of select="$numbering.footnotes.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article and /mathbook/article/section">1</xsl:when>
        <xsl:when test="/mathbook/article">0</xsl:when>
        <xsl:when test="/mathbook/letter">0</xsl:when>
        <xsl:when test="/mathbook/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Footnote numbering level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- User-supplied Numbering for Maximum Level    -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-maxlevel">
    <xsl:variable name="max-feasible">
        <xsl:choose>
            <xsl:when test="/mathbook/book">4</xsl:when>
            <xsl:when test="/mathbook/article">3</xsl:when>
            <xsl:when test="/mathbook/letter">0</xsl:when>
            <xsl:when test="/mathbook/memo">0</xsl:when>
            <xsl:otherwise>
                <xsl:message>MBX:BUG: New document type for maximum level defaults</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- If not provided, try the biggest possible for consistency -->
    <xsl:variable name="candidate">
        <xsl:choose>
            <xsl:when test="$numbering.maximum.level = ''">
                <xsl:value-of select="$max-feasible" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering.maximum.level" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$candidate &lt; $numbering-theorems">
            <xsl:message terminate="yes">MBX:FATAL: theorem numbering level cannot exceed sectioning level</xsl:message>
        </xsl:when>
        <xsl:when test="$candidate &lt; $numbering-equations">
            <xsl:message terminate="yes">MBX:FATAL: equation numbering level cannot exceed sectioning level</xsl:message>
        </xsl:when>
        <xsl:when test="$candidate &lt; $numbering-footnotes">
            <xsl:message terminate="yes">MBX:FATAL: footnote numbering level cannot exceed sectioning level</xsl:message>
        </xsl:when>
        <xsl:when test="$candidate &gt; $max-feasible">
            <xsl:message terminate="yes">MBX:FATAL: sectioning level exceeds maximum possible for this document (<xsl:value-of select="$max-feasible" />)</xsl:message>
        </xsl:when>
        <!-- Survived the gauntlet, spit it out candidate as $numbering-maxlevel -->
        <xsl:otherwise>
            <xsl:value-of select="$candidate" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Document language comes from the mathbook element -->
<!-- or defaults to US English if not present          -->
<xsl:variable name="document-language">
    <xsl:choose>
        <xsl:when test="/mathbook/@xml:lang">
            <xsl:value-of select="/mathbook/@xml:lang" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="'en-US'" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- ############## -->
<!-- Entry template -->
<!-- ############## -->

<!-- docinfo is metadata, kill and retrieve as needed     -->
<!-- Otherwise, processs book, article, letter, memo, etc -->
<xsl:template match="/mathbook">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="docinfo" />

<!-- ########################### -->
<!-- Mathematics (LaTeX/MathJax) -->
<!-- ########################### -->

<!-- Since MathJax interprets a large subset of LaTeX,  -->
<!-- there is little difference between LaTeX and HTML  -->
<!-- output.  See "abstract" templates for intertext    -->
<!-- elements and numbering of equations (automatic for -->
<!-- LaTeX, managed for HTML)                           -->

<!-- Inline Math -->
<!-- We use the LaTeX delimiters \( and \)                                       -->
<!-- MathJax: needs to be specified in the tex2jax/inlineMath configuration list -->
<!-- LaTeX: these are not "robust", hence break moving itmes (titles, index), so -->
<!-- use the "fixltx2e" package, which declares \MakeRobust\( and \MakeRobust\)  -->
<xsl:template match= "m">
    <xsl:text>\(</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- Displayed Math -->
<!-- Single displayed equation, unnumbered                         -->
<!-- Output follows source line breaks                             -->
<!-- MathJax: out-of-the-box support                               -->
<!-- LaTeX: with AMS-TeX, \[,\] tranlates to equation* environment -->
<!-- LaTeX: without AMS-TEX, it is improved version of $$, $$      -->
<!-- See: http://tex.stackexchange.com/questions/40492/what-are-the-differences-between-align-equation-and-displaymath -->
<xsl:template match="me">
    <xsl:text>\[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\]</xsl:text>
</xsl:template>

<!-- Single displayed equation, numbered                        -->
<!-- MathJax: out-of-the-box support                            -->
<!-- LaTeX: with AMS-TeX, equation* environment supported       -->
<!-- LaTeX: without AMS-TEX, $$ with equation numbering         -->
<!-- "tag" modal template is abstract, see specialized versions -->
<!-- We do tag HTML, but not LaTeX.  See link above, also.      -->
<xsl:template match="men">
    <xsl:text>\begin{equation}</xsl:text>
    <xsl:value-of select="." />
    <xsl:apply-templates select="." mode="label"/>
    <xsl:apply-templates select="." mode="tag"/>
    <xsl:text>\end{equation}</xsl:text>
</xsl:template>

<!-- Multi-Line Math -->
<!-- Multi-line displayed equations container, globally unnumbered or numbered   -->
<!-- mrow logic controls numbering, based on variant here, and per-row overrides -->
<!-- align environment if ampersands are present, gather environment otherwise   -->
<!-- Output follows source line breaks                                           -->
<!-- The intertext element is an abstract template, see specialized versions     -->
<xsl:template match="md">
    <xsl:choose>
        <xsl:when test="contains(., '&amp;')">
            <xsl:text>\begin{align*}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow|intertext" />
            <xsl:text>\end{align*}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\begin{gather*}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow" />
            <xsl:text>\end{gather*}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="mdn">
    <xsl:choose>
        <xsl:when test="contains(., '&amp;')">
            <xsl:text>\begin{align}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow|intertext" />
            <xsl:text>\end{align}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\begin{gather}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow" />
            <xsl:text>\end{gather}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Rows of a multi-line math display                 -->
<!-- (1) MathJax config turns off all numbering        -->
<!-- (1) Numbering controlled here with \tag{}, \notag -->
<!-- (2) Labels are TeX-style, created by MathJax      -->
<!-- (2) MathJax config makes span id's predictable    -->
<!-- (3) "tag" modal template is abstract              -->
<!-- (4) Last row special, has no line-break marker    -->
<xsl:template match="md/mrow">
    <xsl:value-of select="." />
    <xsl:if test="@number='yes'">
        <xsl:apply-templates select="." mode="label" />
        <xsl:apply-templates select="." mode="tag"/>
    </xsl:if>
    <xsl:if test="position()!=last()">
       <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="mdn/mrow">
    <xsl:value-of select="." />
    <xsl:choose>
        <xsl:when test="@number='no'">
            <xsl:text>\notag</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="label" />
            <xsl:apply-templates select="." mode="tag"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="position()!=last()">
       <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Sage Cells -->
<!-- Contents are text manipulations (below)     -->
<!-- Two abstract named templates in other files -->
<!-- provide the necessary wrapping, per format  -->

<!-- Type; empty element                      -->
<!-- Provide an empty cell to scribble in     -->
<!-- Or break text cells in the Sage notebook -->
<xsl:template match="sage[not(input) and not(output) and not(@type) and not(@copy)]">
    <xsl:call-template name="sage-active-markup">
        <xsl:with-param name="in" select="''"/>
        <xsl:with-param name="out" select="''" />
    </xsl:call-template>
</xsl:template>

<!-- Type: "invisible"; to doctest, but never show to a reader -->
<xsl:template match="sage[@type='invisible']" />

<!-- Type: "practice"; empty, but with practice announcement -->
<!-- We override this in LaTeX, since it is useless          -->
<!-- (and we can't tell in the abstract wrapping template)   -->
<xsl:template match="sage[@type='practice']">
    <xsl:call-template name="sage-active-markup">
        <xsl:with-param name="in" select="'# Sage practice area&#xa;'"/>
        <xsl:with-param name="out" select="''" />
    </xsl:call-template>
</xsl:template>

<!-- Type: "copy"; used for replays     -->
<!-- Mostly when HTML is chunked        -->
<!-- Just handle the same way as others -->
<xsl:template match="sage[@copy]">
    <xsl:apply-templates select="id(@copy)" />
</xsl:template>

<!-- Type: "display"; input portion as uneditable, unevaluatable -->
<!-- This calls a slightly different abstract template           -->
<!-- We do not pass along any output, since this is silly        -->
<!-- These cells are meant to be be incorrect or incomplete      -->
<xsl:template match="sage[@type='display']">
    <xsl:call-template name="sage-display-markup">
        <xsl:with-param name="in">
            <xsl:call-template name="sanitize-sage">
                <xsl:with-param name="raw-sage-code" select="input" />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Type: "full" (the default)         -->
<!-- Absent meeting any other condition -->
<xsl:template match="sage|sage[@type='full']">
    <xsl:call-template name="sage-active-markup">
        <xsl:with-param name="in">
            <xsl:call-template name="sanitize-sage">
                <xsl:with-param name="raw-sage-code" select="input" />
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="out">
            <xsl:if test="output">
                <xsl:call-template name="sanitize-text-output" >
                    <xsl:with-param name="text" select="output" />
                </xsl:call-template>
            </xsl:if>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>


<!-- Sanitize Sage code                 -->
<!-- No leading whitespace, no trailing -->
<!-- http://stackoverflow.com/questions/1134318/xslt-xslstrip-space-does-not-work -->
<xsl:variable name="whitespace"><xsl:text>&#x20;&#x9;&#xD;&#xA;</xsl:text></xsl:variable>

<!-- Trim all whitespace at end of code hunk -->
<!-- Append carriage return to mark last line, remove later -->
<xsl:template name="trim-end">
   <xsl:param name="text"/>
   <xsl:variable name="last-char" select="substring($text, string-length($text), 1)" />
   <xsl:choose>
        <xsl:when test="$last-char=''">
            <xsl:text>&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="contains($whitespace, $last-char)">
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
        <xsl:when test="contains($whitespace, $first-char)">
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
        <xsl:when test="contains($whitespace, $first-char)">
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
<!-- A blank line will cause 0 width,    -->
<!-- which is OK for Sage doctesting but -->
<!-- maybe not general enough            -->
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
            <!-- Compute margin as smaller of incoming and computed -->
            <xsl:variable name="new-margin">
                <xsl:choose>
                    <xsl:when test="$margin > $pad-top-line">
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

<!--
1) Trim all trailing whitespace, add carriage return marker to last line
2) Strip all totally blank leading lines
3) Determine indentation of first line
4) Strip indentation from all lines
5) Allow intermediate blank lines
-->
<xsl:template name="sanitize-sage">
    <xsl:param name="raw-sage-code" />
    <xsl:variable name="trimmed-sage-code">
        <xsl:call-template name="trim-start-lines">
            <xsl:with-param name="text">
                <xsl:call-template name="trim-end">
                    <xsl:with-param name="text" select="$raw-sage-code" />
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="pad-length">
        <xsl:call-template name="count-pad-length">
            <xsl:with-param name="text" select="$trimmed-sage-code" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="strip-indentation" >
        <xsl:with-param name="text" select="$trimmed-sage-code" />
        <xsl:with-param name="indent" select="$pad-length" />
    </xsl:call-template>
</xsl:template>

<!-- Santitize Sage Output -->
<!-- (1) Trim leading and ending blank lines -->
<!-- (2) Scan *all* lines for left margin    -->
<!-- (3) Remove left margin                  -->
<!-- TODO: very similar to "sanitize-sage", but <BLANKLINE> is necessary -->
<!-- TODO: sanitize <BLANKLINE> for print output -->
<xsl:template name="sanitize-text-output">
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

<!-- Date and Time Functions -->
<!-- http://stackoverflow.com/questions/1437995/how-to-convert-2009-09-18-to-18th-sept-in-xslt -->
<!-- http://remysharp.com/2008/08/15/how-to-default-a-variable-in-xslt/ -->
<xsl:template match="today">
    <xsl:variable name="format">
        <xsl:choose>
            <xsl:when test="@format"><xsl:value-of select="@format" /></xsl:when>
            <xsl:otherwise>month-day-year</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="datetime" select="substring(date:date-time(),1,10)" />
    <xsl:choose>
        <xsl:when test="$format='month-day-year'">
            <xsl:value-of select="date:month-name($datetime)" />
            <xsl:text> </xsl:text>
            <xsl:value-of select="date:day-in-month($datetime)" />
            <xsl:text>, </xsl:text>
            <xsl:value-of select="date:year($datetime)" />
        </xsl:when>
        <xsl:when test="$format='yyyy/mm/dd'">
            <xsl:value-of select="substring($datetime, 1, 4)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($datetime, 6, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($datetime, 9, 2)" />
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Could use a format to suppress/manipulate time zone -->
<xsl:template match="timeofday">
    <xsl:value-of select="substring(date:date-time(),12,8)" />
    <xsl:text> (</xsl:text>
    <xsl:value-of select="substring(date:date-time(),20)" />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Levels -->
<!-- root is -2, mathbook is -1    -->
<!-- book, article, etc is 0       -->
<!-- sectioning works its way down -->
<!-- http://bytes.com/topic/net/answers/572365-how-compute-nodes-depth-xslt -->
<xsl:template match="*" mode="level">
    <xsl:value-of select="count(ancestor::node())-2" />
</xsl:template>

<!-- Structural Nodes -->
<!-- Some elements of the XML tree -->
<!-- are part of the document tree -->
<xsl:template match="*" mode="is-structural">
    <xsl:value-of select="self::book or self::article or self::frontmatter or self::chapter or self::appendix or self::preface or self::acknowledgement or self::biography or self::foreword or self::dedication or self::colophon or self::section or self::subsection or self::subsubsection or self::exercises or self::references or self::backmatter" />
</xsl:template>

<!-- Structural Leaves -->
<!-- Some elements of the document tree -->
<!-- are the leaves of that tree        -->
<xsl:template match="*" mode="is-leaf">
    <xsl:variable name="structural"><xsl:apply-templates select="." mode="is-structural" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:value-of select="not(child::book or child::article or child::chapter or child::frontmatter or child::appendix or child::preface or child::acknowledgement or child::biography or child::foreword or child::dedication or child::colophon or child::section or child::subsection or child::subsubsection or child::exercises or child::references or child::backmatter)" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$structural" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Names of Objects -->
<!-- Ultimately translations are all contained in the           -->
<!-- mathbook-localization.xsl file, which provides upper-case, -->
<!-- singular versions.  In this way, we only ever hardcode a   -->
<!-- string (like "Chapter") once                               -->
<!-- First template is modal, and calls subsequent named        -->
<!-- template where translation with keys happens               -->
<!-- This template allows a node to report its name             -->
<xsl:template match="*" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="local-name(.)" />
    </xsl:call-template>
</xsl:template>

<!-- This template translates an string to an upper-case language-equivalent -->
<!-- Sometimes we must call this directly, but usually better to apply the   -->
<!-- template mode="type-name" to the node, which then calls this routine    -->
<!-- TODO: perhaps allow mixed languages, so don't set document language globally,  -->
<!-- but search up through parents until you find a lang tag                        -->
<xsl:key name="localization-key" match="localization" use="concat(../@name, @string-id)"/>

<xsl:template name="type-name">
    <xsl:param name="string-id" />
    <xsl:variable name="translation">
        <xsl:for-each select="document('mathbook-localization.xsl')">
            <xsl:value-of select="key('localization-key', concat($document-language,$string-id) )"/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$translation!=''"><xsl:value-of select="$translation" /></xsl:when>
        <xsl:otherwise>
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$string-id" />
            <xsl:text>]&#xa;</xsl:text>
            <xsl:message>MBX:WARNING: could not translate string with id "<xsl:value-of select="$string-id" />" into language for code "<xsl:value-of select="$document-language" />"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################## -->
<!-- Identifiers        -->
<!-- ################## -->

<!-- Internal Identifier                        -->
<!-- A unique text identifier for any element   -->
<!-- Uses:                                      -->
<!--   HTML: filenames (pages and knowls)       -->
<!--   HTML: anchors for references into pages  -->
<!--   LaTeX: labels, ie cross-references       -->
<!-- Format:                                            -->
<!--   the content (text) of an xml:id if provided      -->
<!--   otherwise, element_name-serial_number (doc-wide) -->
<!-- MathJax:                                                   -->
<!--   Can manufacture an HTML id= for equations, so            -->
<!--   we configure MathJax to use the TeX \label contents      -->
<!--   which we must be sure to provide via this routine here   -->
<!--   Then our URL/anchor scheme will point to the right place -->
<!--   So this is applied to men and (numbered) mrow elements    -->
<xsl:template match="*" mode="internal-id">
    <xsl:choose>
        <xsl:when test="@xml:id">
            <xsl:value-of select="@xml:id" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="local-name(.)" />
            <xsl:text>-</xsl:text>
            <xsl:number level="any" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- LaTeX labels get used on MathJax content in HTML, so we -->
<!-- put this template in the common file for universal use  -->
<!-- Insert an identifier as a LaTeX label on anything       -->
<!-- Calls to this template need come from where LaTeX likes -->
<!-- a \label, generally someplace that can be numbered      -->
<xsl:template match="*" mode="label">
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Visual Identifiers -->
<!-- What a reader sees in any cross-referencing system -->
<!-- Two types: -->
<!--     origin: what is displayed to mark the object -->
<!--         - subdivisions: full hierarchical numbers -->
<!--         - exercises: serial number in a list -->
<!--         - and so on -->
<!--     reference: what is displayed to guide to the object -->
<!--         - subdivisions: ditto -->
<!--         - exercises: full hierarchical numbers -->
<!--         - citations: [number] -->
<!--         - equations: (number) -->
<!-- Normally, these are numbers.  But with overrides in a        -->
<!-- customization layer, some objects could be known by          -->
<!-- another system, such as acronyms.  So redirection through    -->
<!-- here is a useful abstraction from simply plunking in numbers -->

<!-- Default is the object's number            -->
<!-- (which will report "[NUMBER]" on failure) -->
<xsl:template match="*" mode="origin-id">
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<xsl:template match="*" mode="ref-id">
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- Exercises in lists are always in an enclosing       -->
<!-- subdivision Their default numbers are hierarchical, -->
<!-- so we strip the serial number for display           -->
<xsl:template match="exercises/exercise|exercisegroup/exercise" mode="origin-id">
    <xsl:call-template name="substring-after-last">
        <xsl:with-param name="input">
            <xsl:apply-templates select="." mode="number" />
        </xsl:with-param>
        <xsl:with-param name="substr" select="'.'" />
    </xsl:call-template>
</xsl:template>

<!-- Bibliographic items are in lists in references section -->
<!-- so we always have a hierarchical number, that we can strip -->
<!-- Or we provide a label if one is given -->
<!-- TODO: probably better to have a processing switch for label use? -->
<xsl:template match="biblio" mode="origin-id">
    <xsl:choose>
        <xsl:when test="label">
            <xsl:apply-templates select="label" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="substring-after-last">
                <xsl:with-param name="input">
                    <xsl:apply-templates select="." mode="number" />
                </xsl:with-param>
                <xsl:with-param name="substr" select="'.'" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Long Names -->
<!-- Simple text representations of structural elements        -->
<!-- Type, number, title typically                             -->
<!-- Ignore footnotes in these constructions                   -->
<!-- Used for author's report, LaTeX typeout during processing -->
<xsl:template match="*" mode="long-name">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="title/node()[not(self::fn)]"/>
    </xsl:if>
</xsl:template>

<!-- Some units don't have titles or numbers -->
<xsl:template match="preface|abstract|acknowledgement|biography|foreword|dedication|colophon" mode="long-name">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text> </xsl:text>
</xsl:template>

<!-- Numbering  -->
<!-- Nodes "know" how to number themselves, -->
<!-- which is helpful in a variety of places -->
<!-- Default is LaTeX's numbering scheme -->

<!-- Any node is enclosed in some structural node,          -->
<!-- this utility template computes the hierarchical number -->
<!-- of the enclosing structural node.                      -->
<!-- Level 0 (book, article) is ignored                     -->
<!-- TODO: need filter, if, to handle appendices formatting with letters-->
<xsl:template match="*" mode="structural-number">
    <xsl:number level="multiple" count="chapter|appendix|section|subsection|subsubsection|references|exercises" />
</xsl:template>

<!-- We truncate a structural number to a               -->
<!-- specfified number of terms.                        -->
<!-- The string ends with a period, for                 -->
<!-- subsequent concatenation, unless no                -->
<!-- terms are requested and then the string is empty   -->
<!-- for use when numbering is sequential document-wide -->
<xsl:template name="level-number" >
    <xsl:param name="number" />
    <xsl:param name="level" />
    <xsl:choose>
        <xsl:when test="$level=0"></xsl:when>
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="$number=''">
                    <xsl:text>0.</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring-before($number, '.')" />
                    <xsl:text>.</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="level-number">
                <xsl:with-param name="number">
                    <xsl:value-of select="substring-after($number, '.')" />
                </xsl:with-param>
                <xsl:with-param name="level">
                    <xsl:value-of select="$level - 1" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Oops -->
<!-- TODO: convert to error/warning once more stable -->
<xsl:template match="*" mode="number">
    <xsl:text>[NUMBER]</xsl:text>
</xsl:template>

<!-- Numbering Structural Subdivisions -->
<!-- A structural node just gets its structural number,              -->
<!-- there is no truncation (can just not number at lower levels)    -->
<!-- The variable  number-maxlevel  controls absence at lower levels -->
<xsl:template match="chapter|appendix|section|subsection|subsubsection|references|exercises" mode="number">
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="level" />
    </xsl:variable>
    <xsl:if test="$level &lt;= $numbering-maxlevel">
        <xsl:apply-templates select="." mode="structural-number" />
    </xsl:if>
</xsl:template>

<!-- Numbering Subdivisions without Numbers -->
<!-- Only one, or not subdivisible, or ... -->
<!-- TODO: add more frontmatter, backmatter as it stabilizes -->
<xsl:template match="book|article|letter|memo|introduction|conclusion|paragraph|frontmatter|preface|abstract|acknowledgement|biography|foreword|dedication|colophon|backmatter" mode="number"/>

<!-- Numbering Theorems, Definitions, Examples, Inline Exercises, Figures, etc.-->
<!-- Sructural to a configurable depth, then numbered across depth -->
<!-- We include figures and tables, which is different than LaTeX out-of-the-box behavior -->
<xsl:template match="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table" mode="number">
    <xsl:call-template name="level-number">
        <xsl:with-param name="number">
            <xsl:apply-templates select="." mode="structural-number" />
            <xsl:text>.</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="level">
            <xsl:value-of select="$numbering-theorems" />
        </xsl:with-param>
    </xsl:call-template>
    <!-- Books vs articles, translate level to from attribute node in sequential numbering -->
    <xsl:choose>
        <xsl:when test="/mathbook/book">
            <xsl:choose>
                <xsl:when test="$numbering-theorems=0"><xsl:number select="." from="book" level="any" count="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table"/></xsl:when>
                <xsl:when test="$numbering-theorems=1"><xsl:number select="." from="chapter" level="any" count="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table"/></xsl:when>
                <xsl:when test="$numbering-theorems=2"><xsl:number select="." from="section" level="any" count="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table"/></xsl:when>
                <xsl:when test="$numbering-theorems=3"><xsl:number select="." from="subsection" level="any" count="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table"/></xsl:when>
                <xsl:when test="$numbering-theorems=4"><xsl:number select="." from="subsubsection" level="any" count="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table"/></xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: Level for theorem number computation is out-of-bounds (<xsl:value-of select="$numbering-theorems" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="/mathbook/article">
            <xsl:choose>
                <xsl:when test="$numbering-theorems=0"><xsl:number select="." from="article" level="any" count="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table"/></xsl:when>
                <xsl:when test="$numbering-theorems=1"><xsl:number select="." from="section" level="any" count="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table"/></xsl:when>
                <xsl:when test="$numbering-theorems=2"><xsl:number select="." from="subsection" level="any" count="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table"/></xsl:when>
                <xsl:when test="$numbering-theorems=3"><xsl:number select="." from="subsubsection" level="any" count="theorem|corollary|lemma|proposition|claim|fact|definition|conjecture|axiom|principle|example|remark|exercise|figure|table"/></xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: Level for theorem number computation is out-of-bounds (<xsl:value-of select="$numbering-theorems" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Level for theorem number computation implemented only for books, articles</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Numbering Equations -->
<xsl:template match="mrow|men" mode="number">
    <xsl:call-template name="level-number">
        <xsl:with-param name="number">
            <xsl:apply-templates select="." mode="structural-number" />
            <xsl:text>.</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="level">
            <xsl:value-of select="$numbering-equations" />
        </xsl:with-param>
    </xsl:call-template>

    <!-- Books vs articles, translate level to from attribute node in sequential numbering -->
    <xsl:choose>
        <xsl:when test="/mathbook/book">
            <xsl:choose>
                <xsl:when test="$numbering-equations=0"><xsl:number select="." from="book" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
                <xsl:when test="$numbering-equations=1"><xsl:number select="." from="chapter" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
                <xsl:when test="$numbering-equations=2"><xsl:number select="." from="section" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
                <xsl:when test="$numbering-equations=3"><xsl:number select="." from="subsection" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
                <xsl:when test="$numbering-equations=4"><xsl:number select="." from="subsubsection" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: Level for theorem number computation is out-of-bounds (<xsl:value-of select="$numbering-equations" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="/mathbook/article">
            <xsl:choose>
                <xsl:when test="$numbering-equations=0"><xsl:number select="." from="article" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
                <xsl:when test="$numbering-equations=1"><xsl:number select="." from="section" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
                <xsl:when test="$numbering-equations=2"><xsl:number select="." from="subsection" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
                <xsl:when test="$numbering-equations=3"><xsl:number select="." from="subsubsection" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: Level for theorem number computation is out-of-bounds (<xsl:value-of select="$numbering-equations" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Level for theorem number computation implemented only for books, articles</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Numbering Footnotes -->
<!-- At a configurable level                  -->
<!-- Sequential within subdivision,           -->
<!-- not unique across text unless level is 0 -->
<!-- TODO: consider endnotes possibly         -->
<xsl:template match="fn" mode="number">
    <xsl:choose>
        <xsl:when test="/mathbook/book">
            <xsl:choose>
                <xsl:when test="$numbering-footnotes=0"><xsl:number select="." from="book" level="any" count="fn" /></xsl:when>
                <xsl:when test="$numbering-footnotes=1"><xsl:number select="." from="chapter" level="any" count="fn" /></xsl:when>
                <xsl:when test="$numbering-footnotes=2"><xsl:number select="." from="section" level="any" count="fn" /></xsl:when>
                <xsl:when test="$numbering-footnotes=3"><xsl:number select="." from="subsection" level="any" count="fn" /></xsl:when>
                <xsl:when test="$numbering-footnotes=4"><xsl:number select="." from="subsubsection" level="any" count="fn" /></xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: Level for footnote number computation is out-of-bounds (<xsl:value-of select="$numbering-footnotes" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="/mathbook/article">
            <xsl:choose>
                <xsl:when test="$numbering-footnotes=0"><xsl:number select="." from="article" level="any" count="fn" /></xsl:when>
                <xsl:when test="$numbering-footnotes=1"><xsl:number select="." from="section" level="any" count="fn" /></xsl:when>
                <xsl:when test="$numbering-footnotes=2"><xsl:number select="." from="subsection" level="any" count="fn" /></xsl:when>
                <xsl:when test="$numbering-footnotes=3"><xsl:number select="." from="subsubsection" level="any" count="fn" /></xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: Level for footnote number computation is out-of-bounds (<xsl:value-of select="$numbering-footnotes" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Level for footnote number computation implemented only for books, articles</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Numbering Exercises in Exercises Subdivision -->
<!-- Exercises sections can appear at any level, so we need         -->
<!-- the full structural number, then a sequential number           -->
<!-- Groupings of exercise might be intermediate, but do not hinder -->
<xsl:template match="exercises/exercise|exercises/exercisegroup/exercise" mode="number">
    <xsl:apply-templates select="." mode="structural-number" />
    <xsl:text>.</xsl:text>
    <xsl:number from="exercises" level="any" count="exercise" />
</xsl:template>

<!-- If we hard-code a number for an exercise, so be it           -->
<!-- N.B. Same priority as above, so needs to come in this order, -->
<!-- as we wish hard-coded to have higher priority                -->
<!-- TODO: Enforce with numbered priority? -->
<xsl:template match="exercises/exercise[@number]|exercisegroup/exercise[@number]" mode="number">
    <xsl:apply-templates select="." mode="structural-number" />
    <xsl:text>.</xsl:text>
    <xsl:apply-templates select="@number" />
</xsl:template>


<!-- Numbering Bibliography Items in References -->
<!-- Structural number for References section, -->
<!-- plus sequential tacked on -->
<!-- A single number at book/article level -->
<xsl:template match="biblio" mode="number">
    <xsl:apply-templates select="." mode="structural-number" />
    <xsl:text>.</xsl:text>
    <xsl:number from="references" level="any" count="biblio" />
</xsl:template>

<!-- ########### -->
<!-- List Levels -->
<!-- ########### -->

<!-- Utility templates to determine the depth      -->
<!-- of a list, relative to nesting in other lists -->

<!-- We determine the depth of an unordered     -->
<!-- list, relative only to other unordered     -->
<!-- lists in a nesting, so as to determine     -->
<!-- the right label to apply, esp. as defaults -->
<!-- The recursive template should be called    -->
<!-- without a level, since it defaults to zero -->
<xsl:template match="ul" mode="unordered-list-level">
    <!-- Start with level zero, and increment on successive calls -->
    <xsl:param name="level" select="0"/>
    <xsl:choose>
        <!-- Another unordered list above, add one and recurse -->
        <xsl:when test="ancestor::ul">
            <xsl:apply-templates select="ancestor::ul[1]" mode="unordered-list-level">
                <xsl:with-param name="level" select="$level + 1" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- No unordered list above, done, so return level -->
        <xsl:otherwise>
            <xsl:value-of select="$level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Ordered lists follow the same strategy,           -->
<!-- except we implement exercises and references      -->
<!-- elements as ordered lists, so we need to absorb   -->
<!-- them into the general treatment of nested lists   -->
<!-- They do only occur as top-level elements, so that -->
<!-- assumption allows for some economy                -->
<xsl:template match="ol" mode="ordered-list-level">
    <xsl:param name="level" select="0"/>
    <xsl:choose>
        <!-- Since exercises and references are top-level        -->
        <!-- ordered lists, when these are the only interesting  -->
        <!-- ancestor, we add one to the level and return        -->
        <xsl:when test="(ancestor::exercises or ancestor::references) and not(ancestor::ol)">
            <xsl:value-of select="$level + 1" />
        </xsl:when>
        <xsl:when test="ancestor::ol">
            <xsl:apply-templates select="ancestor::ol[1]" mode="ordered-list-level">
                <xsl:with-param name="level" select="$level + 1" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Exercises and References are        -->
<!-- specialized top-level ordered lists -->
<xsl:template match="exercises|references" mode="ordered-list-level">
    <xsl:value-of select="0" />
</xsl:template>

<!-- ################ -->
<!-- Names for Levels -->
<!-- ################ -->

<!-- Levels (ie depths in the tree) translate to            -->
<!-- element names and LaTeX sections, which we keep the    -->
<!-- same primarily.  So this is more general than it looks -->

<!-- Level Numbers to LaTeX Names -->
<!-- Convert a level (integer) to the corresponding LaTeX division name -->
<xsl:template name="level-number-to-latex-name">
    <xsl:param name="level" />
    <xsl:choose>
        <xsl:when test="/mathbook/book">
            <xsl:choose>
                <xsl:when test="$level=0">book</xsl:when>
                <xsl:when test="$level=1">chapter</xsl:when>
                <xsl:when test="$level=2">section</xsl:when>
                <xsl:when test="$level=3">subsection</xsl:when>
                <xsl:when test="$level=4">subsubsection</xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: Level computation is out-of-bounds (<xsl:value-of select="$level" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="/mathbook/article">
            <xsl:choose>
                <xsl:when test="$level=0">article</xsl:when>
                <xsl:when test="$level=1">section</xsl:when>
                <xsl:when test="$level=2">subsection</xsl:when>
                <xsl:when test="$level=3">subsubsection</xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: Level computation is out-of-bounds (<xsl:value-of select="$level" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Level computation only for books, articles</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Nodes to Subdivision Names -->
<!-- Compute level given a node, via this modal template -->
<!-- Subdivision name comes from named template above    -->
<xsl:template match="*" mode="subdivision-name">
    <xsl:call-template name="level-number-to-latex-name">
        <xsl:with-param name="level">
            <xsl:apply-templates select="." mode="level" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Programming Language Names -->
<!-- Packages for listing and syntax highlighting             -->
<!-- have their own ideas about the names of languages        -->
<!-- We use keys to perform the translation                   -->
<!-- See: https://gist.github.com/frabad/4189876              -->
<!-- for motivation and document() syntax for standalone file -->
<!-- Also: see contributors in FCLA work                      -->

<!-- The data: attribute is our usage,    -->
<!-- elements belong to other packages.   -->
<!-- Blank means not explicitly supported -->
<!-- Alphabetical by type                 -->
<!-- Prettify: -->
<!-- Last reviewed 2014/06/28                                                     -->
<!-- http://code.google.com/p/google-code-prettify/source/browse/trunk/src        -->
<!-- Look inside files, it can be a one-handler-to-several-languages relationship -->
<!-- Listings: -->
<!-- Last reviewed 2014/06/28                           -->
<!-- Exact matches, or best guesses, some unimplemented -->

<!-- Our strings (@mbx) are always all-lowercase, no symbols, no punctuation -->
<mb:programming>
    <!-- Procedural -->
    <language mbx="basic"       listings="Basic"        prettify="basic" />     <!-- Prettify handler verified -->
    <language mbx="c"           listings="C"            prettify="" />          <!-- No Prettify handler -->
    <language mbx="cpp"         listings="C++"          prettify="" />          <!-- No Prettify handler -->
    <language mbx="go"          listings="C"            prettify="go" />        <!-- Prettify handler verified -->
    <language mbx="java"        listings="Java"         prettify="" />          <!-- No Prettify handler -->
    <language mbx="lua"         listings="Lua"          prettify="lua" />       <!-- Prettify handler verified -->
    <language mbx="pascal"      listings="Pascal"       prettify="pascal" />    <!-- Prettify handler verified -->
    <language mbx="perl"        listings="Perl"         prettify="" />          <!-- No Prettify handler -->
    <language mbx="python"      listings="Python"       prettify="" />          <!-- No Prettify handler -->
    <language mbx="r"           listings="R"            prettify="r" />         <!-- Prettify handler verified -->
    <language mbx="s"           listings="S"            prettify="s" />         <!-- Prettify handler verified -->
    <language mbx="sas"         listings="SAS"          prettify="s" />         <!-- Prettify handler verified -->
    <language mbx="sage"        listings="Python"       prettify="" />          <!-- No Prettify handler -->
    <language mbx="splus"       listings="[Plus]S"      prettify="Splus" />     <!-- Prettify handler verified -->
    <language mbx="vbasic"     listings="[Visual]Basic" prettify="vb" />        <!-- Prettify handler verified -->
    <language mbx="vbscript"    listings="VBscript"     prettify="vbs" />       <!-- Prettify handler verified -->
    <!-- Others (esp. functional-->
    <language mbx="apollo"      listings=""             prettify="apollo" />    <!-- Prettify handler verified --> 
    <language mbx="clojure"     listings="Lisp"         prettify="clojure" />   <!-- Prettify handler verified -->
    <language mbx="lisp"        listings="Lisp"         prettify="lisp" />      <!-- Prettify handler verified -->
    <language mbx="clisp"       listings="Lisp"         prettify="cl" />        <!-- Prettify handler verified -->
    <language mbx="elisp"       listings="Lisp"         prettify="el" />        <!-- Prettify handler verified -->
    <language mbx="scheme"      listings="Lisp"         prettify="scm" />       <!-- Prettify handler verified -->
    <language mbx="racket"      listings="Lisp"         prettify="rkt" />       <!-- Prettify handler verified -->
    <language mbx="llvm"        listings="LLVM"         prettify="llvm" />      <!-- Prettify handler verified -->
    <language mbx="matlab"      listings="Matlab"       prettify="" />          <!-- No Prettify handler -->
    <language mbx="ml"          listings="ML"           prettify="ml" />        <!-- Prettify handler verified -->
    <language mbx="fsharp"      listings="ML"           prettify="fs" />        <!-- Prettify handler verified -->
    <!-- Text Manipulation -->
    <language mbx="css"         listings=""             prettify="css" />       <!-- Prettify handler verified -->
    <language mbx="latex"       listings="TeX"          prettify="latex" />     <!-- Prettify handler verified -->
    <language mbx="html"        listings="HTML"         prettify="" />          <!-- No Prettify handler -->
    <language mbx="tex"         listings="TeX"          prettify="tex" />       <!-- Prettify handler verified -->
    <language mbx="xml"         listings="XML"          prettify="" />          <!-- No Prettify handler -->
    <language mbx="xslt"        listings="XSLT"         prettify="" />          <!-- No Prettify handler -->
</mb:programming>

<!-- Define the key for indexing into the data list -->
<xsl:key name="proglang" match="language" use="@mbx" />

<!-- A whole <program> node comes in,  -->
<!-- text of listings name comes out -->
<xsl:template match="*" mode="listings-language">
    <xsl:variable name="language"><xsl:value-of select="@language" /></xsl:variable>
    <xsl:for-each select="document('')/*/mb:programming">
        <xsl:value-of select="key('proglang', $language)/@listings" />
    </xsl:for-each>
</xsl:template>

<!-- A whole <program> node comes in,  -->
<!-- text of prettify name comes out -->
<xsl:template match="*" mode="prettify-language">
    <xsl:variable name="language"><xsl:value-of select="@language" /></xsl:variable>
    <xsl:for-each select="document('')/*/mb:programming">
        <xsl:value-of select="key('proglang', $language)/@listings" />
    </xsl:for-each>
</xsl:template>

<!-- This works, without keys, and could be adapted to range over actual data in text -->
<!-- For example, this approach is used for contributors to FCLA                      -->
<!--
<xsl:template match="*" mode="listings-language">
    <xsl:variable name="language"><xsl:value-of select="@language" /></xsl:variable>
    <xsl:value-of select="document('')/*/mb:programming/language[@mbx=$language]/listings"/>
</xsl:template>
-->

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Cross-reference template -->
<!-- Every (non-provisional) cross-reference comes through here            -->
<!-- and is fact-checked before being dispatched to a "ref-id" template    -->
<!-- Qualifiers of cross-references are passed to their templates          -->
<!--                                                                       -->
<!-- LaTeX has several schemes: \ref, \cite, \eqref                        -->
<!-- HTML will do traditional hyperlinks or modern knowls                  -->
<!-- The ref-id templates produce the code to create what a reader sees    -->
<!-- to locate the referenced item                                         -->
<!-- So see specialized routines for those constructions                   -->
<xsl:template match="xref[@ref]">
    <xsl:variable name="target" select="id(@ref)" />
    <!-- Check to see if the ref is any good              -->
    <!-- Set off various alarms if target is non-existent -->
    <!-- http://www.stylusstudio.com/xsllist/200412/post20720.html -->
    <xsl:if test="not(exsl:node-set($target))">
        <xsl:message>MBX:WARNING: unresolved &lt;xref&gt; due to ref="<xsl:value-of select="@ref"/>"</xsl:message>
        <xsl:variable name="inline-warning">
            <xsl:text>Unresolved xref, ref="</xsl:text>
            <xsl:value-of select="@ref"/>
            <xsl:text>"; check spelling or use "provisional" attribute</xsl:text>
        </xsl:variable>
        <xsl:variable name="margin-warning">
            <xsl:text>Unresolved xref</xsl:text>
        </xsl:variable>
        <xsl:call-template name="inline-warning">
            <xsl:with-param name="warning" select="$inline-warning" />
        </xsl:call-template>
        <xsl:call-template name="margin-warning">
            <xsl:with-param name="warning" select="$margin-warning" />
        </xsl:call-template>
    </xsl:if>
    <!-- Cross-references may have qualifiers of their targets, which -->
    <!-- we pass to their ref-id templates to handle appropriately    -->
    <!-- Default is to pass nothing extra, which is not a problem     -->
    <xsl:choose>
        <xsl:when test="@detail">
            <xsl:apply-templates select="$target" mode="ref-id">
                <xsl:with-param name="detail" select="@detail" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="@autoname">
            <xsl:apply-templates  select="$target" mode="ref-id" >
                <xsl:with-param name="autoname" select="@autoname" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="$target" mode="ref-id" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Autonaming of Cross-References -->
<!-- Some references get a prefix (eg Section, Theorem, Exercise), -->
<!-- subject to global and local options, interpreted here         -->
<xsl:template match="*" mode="ref-prefix">
    <!-- Parameter is the local @autoname of the calling xref -->
    <!-- Five values: blank, yes/no, plural, title            -->
    <xsl:param name="local" />
    <!-- Global: yes/no, so 10 combinations -->
    <xsl:choose>
        <!-- 2 combinations: global no, without local override -->
        <xsl:when test="$autoname='no' and ($local='' or $local='no')" />
        <!-- 1 combination: global yes, but local override -->
        <xsl:when test="$autoname='yes' and $local='no'" />
        <!-- 2 combinations: global yes/no, local title option-->
        <xsl:when test="$local='title'">
            <xsl:apply-templates select="title" />
        </xsl:when>
        <!-- 2 combinations: global no, local yes/plural        -->
        <!-- 3 combinations: global yes, local blank/yes/plural -->
        <!-- TODO: migrate ugly English-centric hack to language files! -->
        <xsl:when test="$local='yes' or $local='plural' or ($autoname='yes' and $local='')">
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:if test="$local='plural'">
                <xsl:text>s</xsl:text>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Some autonaming combination slipped through unhandled</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Provisional cross-references -->
<!-- A convenience for authors in early stages of writing -->
<!-- Appear both inline and moreso in author tools        -->
<!-- TODO: Make cite/@provisional an error eventually     -->
<xsl:template match="cite[@provisional]|xref[@provisional]">
    <xsl:if test="self::cite">
        <xsl:message>MBX:WARNING: &lt;cite provisional="<xsl:value-of select="@provisional" />"&gt; is deprecated, convert to &lt;xref provisional="<xsl:value-of select="@provisional" />"&gt;</xsl:message>
    </xsl:if>
    <xsl:variable name="inline-warning">
        <xsl:value-of select="@provisional" />
    </xsl:variable>
    <xsl:variable name="margin-warning">
        <xsl:text>Provisional xref</xsl:text>
    </xsl:variable>
    <xsl:call-template name="inline-warning">
        <xsl:with-param name="warning" select="$inline-warning" />
    </xsl:call-template>
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning" select="$margin-warning" />
    </xsl:call-template>
</xsl:template>

<!-- Warnings for a high-frequency mistake -->
<xsl:template match="xref">
    <xsl:message>MBX:WARNING: Cross-reference (xref) with no ref or provisional attribute, check spelling</xsl:message>
    <xsl:call-template name="inline-warning">
        <xsl:with-param name="warning">
            <xsl:text>xref without ref or provisional attribute, check spelling</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning">
            <xsl:text>xref, no attribute</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Miscellaneous -->

<!-- ToDo's are silent unless requested           -->
<!-- as part of an author's report, then marginal -->
<xsl:template match="todo">
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning">
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text>: </xsl:text>
            <xsl:apply-templates />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

</xsl:stylesheet>
