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

<!-- Indicated basic utilities are from:                      -->
<!-- XSLT Cookbook, 2nd Edition                               -->
<!-- Copyright 2006, O'Reilly Media, Inc.                     -->
<!--                                                          -->
<!-- From the section of the Preface, "Using Code Examples"   -->
<!-- "You do not need to contact us for permission unless     -->
<!-- you're reproducing a significant portion of the code.    -->
<!-- For example, writing a program that uses several chunks  -->
<!-- of code from this book does not require permission."     -->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" 
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
    xmlns:mb="http://mathbook.pugetsound.edu/"
    exclude-result-prefixes="mb"
>

<!-- MathBook XML common templates                        -->
<!-- Text creation/manipulation common to HTML, TeX, Sage -->

<!-- This collection of XSL routines is like a base library,          -->
<!-- it has no entry template and hence used by itself almost         -->
<!-- nothing should happen.  Typically the situation looks like this: -->
<!-- (example is LaTeX-specific but generalizes easily)               -->
<!--                                                                  -->
<!-- your-book-latex.xsl                                              -->
<!--   (a) is what you use on the command line                        -->
<!--   (b) contains very specific, atomic overrides for your project  -->
<!--   (c) imports xsl/mathbook-latex.xsl                             -->
<!--                                                                  -->
<!-- xsl/mathbook-latex.xsl                                           -->
<!--   (a) general conversion from MBX to LaTeX                       -->
<!--   (b) could be used at the command line for default conversion   -->
<!--   (c) imports xsl/mathbook-common.xsl                            -->
<!--                                                                  -->
<!-- xsl/mathbook-common.xsl                                          -->
<!--   (a) this file                                                  -->
<!--   (b) ensures commonality, such as text versions                 -->
<!--       of numbers for theorems, equations, etc                    -->
<!--   (c) has some abstract routines that require implementation     -->
<!--       in files above, such as file wrapping for a LaTeX file     -->
<!--       in this case                                               -->
<!--                                                                  -->
<!-- This creates a linear sequence of imports, so overrides          -->
<!-- behave as you might expect or predict.                           -->
<!-- To do otherwise is to invite confusion.                          -->

<!-- Output methods here are just pure text -->
<xsl:output method="text" />

<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!-- These here are independent of the output format as well                  -->
<!--                                                                          -->
<!-- Depth to which a document is broken into smaller files/chunks -->
<!-- Sentinel indicates no choice made                             -->
<xsl:param name="chunk.level" select="''" />

<!-- DO NOT USE -->
<!-- HTML-specific deprecated 2015/06, but still functional -->
<xsl:param name="html.chunk.level" select="''" />
<!-- DO NOT USE -->

<!-- An exercise has a statement, and may have hints,      -->
<!-- answers and solutions.  An answer is just the         -->
<!-- final number, expression, whatever; while a solution  -->
<!-- includes intermediate steps. Parameters here control  -->
<!-- the *visibility* of these four parts                  -->
<!--                                                       -->
<!-- Parameters are:                                       -->
<!--   'yes' - immediately visible                         -->
<!--   'knowl' - adjacent, but requires action to reveal   -->
<!--    NB: HTML - 'knowl' not implemented or recognized   -->
<!--       'yes' makes knowls for hints, etc *always*      -->
<!--   'no' - not visible at all                           -->
<!--                                                       -->
<!-- First, an exercise in exercises section.              -->
<!-- Default is "yes" for every part, so experiment        -->
<!-- with parameters to make some parts hidden.            -->
<xsl:param name="exercise.text.statement" select="'yes'" />
<xsl:param name="exercise.text.hint" select="'yes'" />
<xsl:param name="exercise.text.answer" select="'yes'" />
<xsl:param name="exercise.text.solution" select="'yes'" />
<!-- Second, an exercise in a solutions list in backmatter.-->
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
<!-- How many levels in numbering of projects, etc     -->
<!-- PROJECT-LIKE gets independent numbering -->
<xsl:param name="numbering.projects.level" select="''" />
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
<!-- Pointers to realizations of the actual document -->
<xsl:param name="address.html" select="''" />
<xsl:param name="address.pdf" select="''" />

<!-- Whitespace discussion: http://www.xmlplease.com/whitespace               -->
<!-- Describes source expectations, DO NOT override in subsequent conversions -->
<!-- Strip whitespace text nodes from container elements                      -->
<!-- Improve source readability with whitespace control in text output mode   -->
<!-- Newlines with &#xa; : http://stackoverflow.com/questions/723226/producing-a-new-line-in-xslt -->
<!-- Removing whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->
<xsl:strip-space elements="mathbook book article memo letter" />
<xsl:strip-space elements="frontmatter chapter appendix index-part section subsection subsubsection exercises references introduction conclusion paragraphs paragraph subparagraph backmatter" />
<xsl:strip-space elements="docinfo author abstract" />
<xsl:strip-space elements="titlepage preface acknowledgement biography foreword dedication colophon" />
<!-- List is elements in DEFINITION-LIKE entity -->
<!-- definition -->
<xsl:strip-space elements="definition" />
<!-- List is elements in THEOREM-LIKE entity                           -->
<!-- theorem|corollary|lemma|algorithm|proposition|claim|fact|identity -->
<xsl:strip-space elements="theorem corollary lemma algorithm proposition claim fact identity" />
<xsl:strip-space elements="statement" />
<xsl:strip-space elements="proof" />
<!-- List is elements in AXIOM-LIKE entity                  -->
<!-- axiom|conjecture|principle|heuristic|hypothesis|assumption -->
<xsl:strip-space elements="axiom conjecture principle heuristic hypothesis assumption" />
<!-- List is elements in REMARK-LIKE entity             -->
<!-- remark|convention|note|observation|warning|insight -->
<xsl:strip-space elements="remark convention note observation warning insight" />
<!-- List is elements in EXAMPLE-LIKE entity -->
<!-- example|question|problem                -->
<xsl:strip-space elements="example question problem" />
<!-- List is elements in PROJECT-LIKE entity -->
<!-- project|activity|exploration|task|investigation -->
<xsl:strip-space elements="project activity exploration task investigation" />
<xsl:strip-space elements="exercise hint answer solution" />
<xsl:strip-space elements="blockquote" />
<xsl:strip-space elements="list" />
<xsl:strip-space elements="sage program console" />
<xsl:strip-space elements="exercisegroup" />
<xsl:strip-space elements="ul ol dl li" />
<xsl:strip-space elements="md mdn" />
<xsl:strip-space elements="sage figure listing index" />
<xsl:strip-space elements="sidebyside paragraphs" />
<xsl:strip-space elements="table tabular col row" />
<xsl:strip-space elements="webwork setup" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- We set this variable a bit differently -->
<!-- for different conversions, so this is  -->
<!-- basically an abstract implementation   -->
<xsl:variable name="chunk-level">
    <xsl:text>0</xsl:text>
</xsl:variable>

<xsl:variable name="toc-level">
    <xsl:choose>
        <xsl:when test="$toc.level != ''">
            <xsl:value-of select="$toc.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article/section">1</xsl:when>
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
        <xsl:when test="/mathbook/book/part">3</xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article/section">1</xsl:when>
        <xsl:when test="/mathbook/article">0</xsl:when>
        <xsl:when test="/mathbook/letter">0</xsl:when>
        <xsl:when test="/mathbook/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Theorem numbering level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- User-supplied Numbering for Projects, etc    -->
<!-- Respect switch, or provide sensible defaults -->
<!-- PROJECT-LIKE -->
<xsl:variable name="numbering-projects">
    <xsl:choose>
        <xsl:when test="$numbering.projects.level != ''">
            <xsl:value-of select="$numbering.projects.level" />
        </xsl:when>
        <xsl:when test="/mathbook/book/part">3</xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article/section">1</xsl:when>
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
        <xsl:when test="/mathbook/book/part">3</xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article/section">1</xsl:when>
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
        <xsl:when test="/mathbook/book/part">3</xsl:when>
        <xsl:when test="/mathbook/book">2</xsl:when>
        <xsl:when test="/mathbook/article/section">1</xsl:when>
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
            <xsl:when test="/mathbook/book/part">5</xsl:when>
            <xsl:when test="/mathbook/book">4</xsl:when>
            <xsl:when test="/mathbook/article/section">3</xsl:when>
            <xsl:when test="/mathbook/article">0</xsl:when>
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
        <!-- PROJECT-LIKE -->
        <xsl:when test="$candidate &lt; $numbering-projects">
            <xsl:message terminate="yes">MBX:FATAL: project numbering level cannot exceed sectioning level</xsl:message>
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

<!-- We read the document language translation -->
<!-- nodes out of the right file, which relies -->
<!-- on filenames with country codes           -->
<xsl:variable name="localization-file">
    <xsl:text>localizations/</xsl:text>
    <xsl:value-of select="$document-language" />
    <xsl:text>.xsl</xsl:text>
</xsl:variable>
<xsl:variable name="translation-nodes" select="document($localization-file)" />

<!-- Document may exist in a variety of formats in  -->
<!-- various locations.  These parameters can be    -->
<!-- hard-coded in the docinfo and/or specified on  -->
<!-- the command line. Command line takes priority. -->
<!-- TODO: More formats could be implemented.       -->
<xsl:variable name="address-html">
    <xsl:choose>
        <xsl:when test="not($address.html = '')">
            <xsl:value-of select="$address.html" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="/mathbook/docinfo/address/html" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="address-pdf">
    <xsl:choose>
        <xsl:when test="not($address.pdf = '')">
            <xsl:value-of select="$address.pdf" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="/mathbook/docinfo/address/pdf" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- File extensions can be set globally for a conversion, -->
<!-- we set it here to something outlandish                -->
<!-- This should be overridden in an importing stylesheet  -->
<xsl:variable name="file-extension" select="'.need-to-set-file-extension-variable'" />

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- We never process using just this file, and often want  -->
<!-- to import it elsewhere for the utilities it contains.  -->
<!-- So there is no entry template, nor should there be.    -->
<!-- An importing file, designed for a specific conversion, -->
<!-- can have an entry template and use the general         -->
<!-- "chunking" templates defined below.                    -->


<!--        -->
<!-- Levels -->
<!--        -->

<!-- (Relative) Levels -->
<!-- Chase any element up full XML tree,      -->
<!-- but adjust for actual document root      -->
<!-- XML document root is always -2           -->
<!-- mathbook element is always -1            -->
<!-- book, article, letter, memo, etc is 0    -->
<!-- sectioning works its way down from there -->
<!-- http://bytes.com/topic/net/answers/572365-how-compute-nodes-depth-xslt -->
<!-- NB: a * instead of node() seems to break things, unsure why            -->
<xsl:template match="*" mode="level">
    <xsl:value-of select="count(ancestor::node())-2" />
</xsl:template>

<!-- Enclosing Level -->
<!-- For any element, work up the tree to a structural -->
<!-- node and then compute level as above              -->
<xsl:template match="*" mode="enclosing-level">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural = 'true'">
            <xsl:apply-templates select="." mode="level" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="enclosing-level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Relative level offset -->
<!-- Document root on absolute level scale (not XML root)            -->
<!-- See "absolute" scale in use just below                          -->
<!-- For example, article with sections has document root at level 1 -->
<!-- So:  absolute-level = (relative-)level + root-level             -->
<xsl:variable name="root-level">
    <xsl:choose>
        <xsl:when test="/mathbook/book/part">-1</xsl:when>
        <xsl:when test="/mathbook/book/chapter">0</xsl:when>
        <!-- An article is rooted just above sections, -->
        <!-- on par with chapters of a book            -->
        <xsl:when test="/mathbook/article">1</xsl:when>
        <xsl:when test="/mathbook/letter">1</xsl:when>
        <xsl:when test="/mathbook/memo">1</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: Level offset undefined for this document type</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Names for Levels -->
<!-- Levels (ie depths in the tree) translate to MBX element           -->
<!-- names and LaTeX sections, which are generally the same            -->
<!-- This is useful for "new" sections (like exercises and references) -->
<!-- used with standard LaTeX sectioning and numbering                 -->

<!-- These are are the "absolute" level numbers        -->
<!-- We convert a level to a LaTeX/MBX sectioning name -->
<xsl:template name="level-number-to-latex-name">
    <xsl:param name="level" />
    <xsl:choose>
        <xsl:when test="$level=0">part</xsl:when>
        <xsl:when test="$level=1">chapter</xsl:when>
        <xsl:when test="$level=2">section</xsl:when>
        <xsl:when test="$level=3">subsection</xsl:when>
        <xsl:when test="$level=4">subsubsection</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Level computation is out-of-bounds (<xsl:value-of select="$level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Nodes to Subdivision Names -->
<!-- Compute relative level of a node, adjust to absolute -->
<!-- Subdivision name comes from named template above     -->
<!-- Note: frontmatter and backmatter are structural, so  -->
<!-- get considered in level computation.  However, they  -->
<!-- are just containers, so we subtract them away        -->
<xsl:template match="*" mode="subdivision-name">
    <xsl:variable name="relative-level">
        <xsl:apply-templates select="." mode="level" />
    </xsl:variable>
    <xsl:call-template name="level-number-to-latex-name">
        <xsl:with-param name="level">
            <xsl:choose>
                <!-- With parts, the *matter is a peer of a part and +1 and -1 counteract -->
                <xsl:when test="(ancestor::frontmatter or ancestor::backmatter) and /mathbook/book/part">
                    <xsl:value-of select="$relative-level + $root-level" />
                </xsl:when>
                <!-- *matter is considered structural, but shouldn't be counted    -->
                <!-- in building the right names at different levels, absent parts -->
                <xsl:when test="ancestor::frontmatter or ancestor::backmatter">
                    <xsl:value-of select="$relative-level + $root-level - 1" />
                </xsl:when>
                <!-- in the body this is right -->
                <xsl:otherwise>
                    <xsl:value-of select="$relative-level + $root-level" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- ################################ -->
<!-- Mathematics (LaTeX/HTML/MathJax) -->
<!-- ################################ -->

<!-- Since MathJax interprets a large subset of LaTeX,   -->
<!-- there are only subtle differences between LaTeX     -->
<!-- and HTML output.  See LaTeX- and HTML-specific       -->
<!-- templates for intertext elements and the numbering   -->
<!-- of equations (automatic for LaTeX, managed for HTML) -->

<!-- Inline Math -->
<!-- We use the LaTeX delimiters \( and \)                                       -->
<!-- MathJax: needs to be specified in the tex2jax/inlineMath configuration list -->
<!-- LaTeX: these are not "robust", hence break moving itmes (titles, index), so -->
<!-- use the "fixltx2e" package, which declares \MakeRobust\( and \MakeRobust\)  -->
<!-- WeBWorK: allow the "var" element                                            -->
<xsl:template match= "m">
    <xsl:text>\(</xsl:text>
    <xsl:choose>
        <xsl:when test="ancestor::webwork">
            <xsl:apply-templates select="text()|var" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="text()|fillin" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- We get some clues about the right LaTeX environment to      -->
<!-- use for display mathematics, but some of this is guesswork. -->
<!-- But we can consolidate this textual analysis (input/output) -->
<!-- here in the common routines.  Attribute allows overrides.   -->

<!-- Always an "equation" for an me-variant -->
<!-- The equation* is AMS-Math-specific,    -->
<!-- "displaymath" is base-LaTeX equivalent -->
<xsl:template match="me" mode="displaymath-alignment">
    <xsl:text>equation*</xsl:text>
</xsl:template>

<xsl:template match="men" mode="displaymath-alignment">
    <xsl:text>equation</xsl:text>
</xsl:template>

<!-- We sniff around for ampersands, to decide between "align" -->
<!-- and "gather", plus an asterisk for the unnumbered version -->
<xsl:template match="md|mdn" mode="displaymath-alignment">
    <xsl:choose>
        <xsl:when test="contains(., '&amp;') or contains(., '\amp')">
            <xsl:text>align</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>gather</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="self::md">
        <xsl:text>*</xsl:text>
    </xsl:if>
</xsl:template>

<!-- User intervention is necessary/desired in some situations,   -->
<!-- such as a LaTeX macro hiding &amp;, \amp, or spacing control -->
<!-- @alignment = align|gather|alignat as a specific override     -->
<xsl:template match="md[@alignment]|mdn[@alignment]" mode="displaymath-alignment">
    <xsl:choose>
        <xsl:when test="@alignment='gather'">
            <xsl:text>gather</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment='alignat'">
            <xsl:text>alignat</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment='align'">
            <xsl:text>align</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: display math @alignment attribute "<xsl:value-of select="@alignment" />" is not recognized (should be "align", "gather", "alignat")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="self::md">
        <xsl:text>*</xsl:text>
    </xsl:if>
</xsl:template>

<!-- count ampersands in a string              -->
<!-- both as LaTeX macro and as bare character -->
<xsl:template name="count-ampersands">
    <xsl:param name="text" />
    <xsl:variable name="amp-char">
        <xsl:call-template name="count-substring">
            <xsl:with-param name="text" select="$text" />
            <xsl:with-param name="word" select="'&amp;'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="amp-macro">
        <xsl:call-template name="count-substring">
            <xsl:with-param name="text" select="$text" />
            <xsl:with-param name="word" select="'\amp'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$amp-char + $amp-macro" />
</xsl:template>

<!-- With alignment="alignat" we need the number of columns as an argument -->
<!-- Mostly we call this plentifully and usually empty template is null    -->
<xsl:template match="me|men|md|mdn" mode="alignat-columns" />

<xsl:template match="md[@alignment='alignat']|mdn[@alignment='alignat']" mode="alignat-columns">
    <xsl:variable name="first-row-content">
        <xsl:for-each select="mrow[1]/text()">
            <xsl:value-of select="." />
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="number-ampersands">
        <xsl:call-template name="count-ampersands">
            <xsl:with-param name="text" select="$first-row-content" />
        </xsl:call-template>
    </xsl:variable>
    <!-- amps + 1, divide by 2, round up; 0.5 becomes 0.25, round behaves -->
    <xsl:variable name="number-equation-columns" select="round(($number-ampersands + 1.5) div 2)" />
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$number-equation-columns" />
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- ############ -->
<!-- LaTeX Macros -->
<!-- ############ -->

<!-- We pick up user-supplied macros, and         -->
<!-- add three of our own that are useful         -->
<!-- for avoiding conflicts with XML reserved     -->
<!-- characters.  Even though MathJax defines     -->
<!-- \lt  and  \gt  we go ahead and do it         -->
<!-- anyway for completeness.  We add these       -->
<!-- last with a \newcommand to minimize the      -->
<!-- possibility author defines them earlier      -->
<!-- This should be the primary and only          -->
<!-- interface to the macros list, though         -->
<!-- it might need some extra                     -->
<!-- conversion-specific wrapping in use          -->
<!-- and it may be necessary/desirable to replace -->
<!-- newline line-endings with something like {}  -->
<!-- First, we move left-margin as far left as    -->
<!-- possible, then strip all comments,  without  -->
<!-- stripping too much, such as useful \%        -->
<!-- We save in a variable, so only here once     -->
<xsl:variable name="latex-macros">
    <xsl:variable name="latex-left-justified">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text">
                <xsl:value-of select="/mathbook/docinfo/macros" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="latex-macro-first-percent">
        <xsl:with-param name="latex-code">
            <xsl:value-of select="$latex-left-justified" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>\newcommand{\lt}{ &lt; }&#xa;</xsl:text>
    <xsl:text>\newcommand{\gt}{ &gt; }&#xa;</xsl:text>
    <xsl:text>\newcommand{\amp}{ &amp; }&#xa;</xsl:text>
</xsl:variable>

<!-- Recursively, line-by-line, find first %                             -->
<!-- If preceded by \, then output and reform with rest of line          -->
<!-- If a naked %, then drop rest of line, tidy up and move to next line -->
<!-- Every output line ends with a newline                               -->
<xsl:template name="latex-macro-first-percent">
    <xsl:param name="latex-code" />
    <xsl:variable name="first-line" select="concat(substring-before($latex-code, '&#xA;'), '&#xA;')" />
    <xsl:variable name="remainder" select="substring-after($latex-code, '&#xA;')" />
    <xsl:choose>
        <!-- done, quit recursing -->
        <xsl:when test="not($latex-code)" />
        <!-- first potential comment character-->
        <xsl:when test="contains($first-line, '%')">
            <xsl:variable name="initial" select="substring-before($first-line, '%')" />
            <xsl:choose>
                <xsl:when test="substring($initial, string-length($initial))='\'">
                    <!-- false positive, output symptom and reorganize -->
                    <xsl:value-of select="concat($initial, '%')" />
                    <xsl:call-template name="latex-macro-first-percent">
                        <xsl:with-param name="latex-code" select="concat(substring-after($first-line, '%'), $remainder)" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- comment character in first column is no line        -->
                    <!-- else, content prior, with stripped newline restored -->
                    <xsl:if test="$initial">
                        <xsl:value-of select="concat($initial, '&#xA;')" />
                    </xsl:if>
                    <!-- move on to remaining lines -->
                    <xsl:call-template name="latex-macro-first-percent">
                        <xsl:with-param name="latex-code" select="$remainder" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <!-- no action, just echo and work the rest -->
            <xsl:value-of select="$first-line" />
            <xsl:call-template name="latex-macro-first-percent">
                <xsl:with-param name="latex-code" select="substring-after($latex-code, '&#xA;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Sage Cells -->
<!-- Contents are text manipulations (below)     -->
<!-- Two abstract named templates in other files -->
<!-- provide the necessary wrapping, per format  -->

<!-- Type; empty element                      -->
<!-- Provide an empty cell to scribble in     -->
<!-- Or break text cells in the Sage notebook -->
<!-- This cell does respect @language         -->
<xsl:template match="sage[not(input) and not(output) and not(@type) and not(@copy)]">
    <xsl:call-template name="sage-active-markup">
        <!-- OK to send empty string, implementation reacts -->
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="@language" />
        </xsl:with-param>
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
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="'practice'" />
        </xsl:with-param>
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
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="'display'" />
        </xsl:with-param>
        <xsl:with-param name="in">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="input" />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Type: "full" (the default)         -->
<!-- Absent meeting any other condition -->
<xsl:template match="sage|sage[@type='full']">
    <xsl:call-template name="sage-active-markup">
        <!-- OK to send empty string, implementation reacts -->
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="@language" />
        </xsl:with-param>
        <xsl:with-param name="in">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="input" />
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="out">
            <xsl:if test="output">
                <xsl:call-template name="sanitize-text" >
                    <xsl:with-param name="text" select="output" />
                </xsl:call-template>
            </xsl:if>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Console Session -->
<!-- An interactive command-line session with a prompt, input and output -->
<!-- Generic template here, specifics of input and output elsewhere      -->
<xsl:template match="console">
    <!-- ignore prompt, and pick it up in trailing input -->
    <xsl:apply-templates select="input|output" />
</xsl:template>

<!-- ################# -->
<!-- Preformatted Text -->
<!-- ################# -->

<!-- The content of a "pre" element is wrapped many ways, -->
<!-- but the content itself is always strictly text       -->

<!-- With no "cline", we adjust left margin -->
<xsl:template match="pre" mode="interior">
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
</xsl:template>

<!-- With a "cline", we process the lines -->
<xsl:template match="pre[cline]" mode="interior">
    <xsl:apply-templates select="cline" />
</xsl:template>

<!-- Code Lines -->
<!-- A "cline" is used to (optionally) structure hunks     -->
<!-- of verbatim text.  Due to its simplicity, it should   -->
<!-- be universal and the only efffect is to add a newline -->
<!-- character, which the output format should recognize   -->
<!-- via its own devices.                                  -->
<xsl:template match="cline">
    <xsl:apply-templates select="text()" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- Sanitize Code -->
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
<!-- Note: this is not in use and has seen only limited testing    -->
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

<!-- File Extension -->
<!-- Input: full filename                       -->
<!-- Output: extension (no period), lowercase'd -->
<xsl:template name="file-extension">
    <xsl:param name="filename" />
    <xsl:variable name="extension">
        <xsl:call-template name="substring-after-last">
            <xsl:with-param name="input" select="$filename" />
            <xsl:with-param name="substr" select="'.'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="translate($extension, &UPPERCASE;, &LOWERCASE;)" />
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

<!-- ################## -->
<!-- Document Structure -->
<!-- ################## -->

<!-- Structural Nodes -->
<!-- Some elements of the XML tree are structural elements of the document tree  -->
<!-- This is our logical overlay on the (finer, larger, more expansive) XML tree -->
<!-- Example: <section> is structural, and ancestors are all structural          -->
<!-- Example: <title> is not structural, but does have a structural ancestor     -->
<!-- NB: These elements need only be specified here, and in leaf template (next) -->
<xsl:template match="&STRUCTURAL;" mode="is-structural">
    <xsl:value-of select="true()" />
</xsl:template>

<xsl:template match="*" mode="is-structural">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Structural Leaves -->
<!-- Some structural elements of the document tree    -->
<!-- are the leaves of that tree, meaning they do     -->
<!-- not contain any structural nodes themselves      -->
<!-- frontmatter and backmatter are always structured -->
<!-- otherwise, we look for definitive markers        -->
<!-- Note: references and exercises are not markers   -->
<xsl:template match="&STRUCTURAL;" mode="is-leaf">
    <xsl:choose>
        <xsl:when test="self::frontmatter or self::backmatter or child::part or child::chapter or child::section or child::subsection or child::subsubsection">
            <xsl:value-of select="false()" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="true()" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="is-leaf">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- We also want to identify smaller pieces of a document,          -->
<!-- such as when they contain an index element or defined term,     -->
<!-- so we can reference back to them.  We call these "blocks" here, -->
<!-- which mostly corresponds to the use of the term in the DTD.     -->
<!-- The difference is that a paragraph is a "block" if and only if  -->
<!-- it is a direct descendant of a structural node or a directly    -->
<!-- descended introduction or conclusion .                          -->
<!-- Also, list items are considered blocks.                         -->
<xsl:template match="md|mdn|ul|ol|dl|blockquote|pre|sidebyside|sage|figure|table|listing|poem|program|image|tabular|paragraphs|&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|list|exercise|li" mode="is-block">
    <xsl:value-of select="true()" />
</xsl:template>

<xsl:template match="p" mode="is-block">
    <xsl:choose>
        <xsl:when test="parent::introduction or parent::conclusion">
            <xsl:variable name="interloper" select="parent::*" />
            <xsl:apply-templates select="$interloper/parent::*" mode="is-structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="is-structural" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="is-block">
    <xsl:value-of select="false()" />
</xsl:template>


<!-- ####################### -->
<!-- Chunking Document Nodes -->
<!-- ####################### -->

<!--
When we break a document into pieces, known as "chunks,"
there is a configurable level (the "chunk-level") where
the document nodes at that level are always a chunk.
At a lesser level, document nodes are "intermediate" nodes
and so are output as summaries of their children.
However, an intermediate node may have no children
(is a "leaf") and hence is output as a chunk.

Said differently, chunks are natural leaves of the document
tree, or leaves (dead-ends) manufactured by an arbitrary
cutoff given by the chunk-level variable
-->

<!--
So we have three types of document nodes:
Intermediate: structural node, not a document leaf, smaller level than chunk-level
  Realization: some content (title, introduction, conclusion), links/includes to children
Leaf: structural node, at chunk-level or a leaf at smaller level than chunk-level
  Realization: a chunk will all content
Neither: A structural node that is simply a (visual) subdivision of a chunk
  Realization: usual presentation, but wtithin the enclosing chunk
-->

<!-- An intermediate node is at lesser level than chunk-level and is not a leaf -->
 <xsl:template match="*" mode="is-intermediate">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:variable name="current-level">
                <xsl:apply-templates select="." mode="level" />
            </xsl:variable>
            <xsl:variable name="leaf">
                <xsl:apply-templates select="." mode="is-leaf" />
            </xsl:variable>
            <xsl:value-of select="($leaf='false') and ($chunk-level > $current-level)" />
        </xsl:when>
        <xsl:when test="$structural='false'">
            <xsl:value-of select="$structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: Structural determination (<xsl:value-of select="$structural" />) failed for is-intermediate at <xsl:apply-templates select="." mode="long-name"/></xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A chunk node is at the chunk-level, or a leaf at a lesser level -->
<xsl:template match="*" mode="is-chunk">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:variable name="current-level">
                <xsl:apply-templates select="." mode="level" />
            </xsl:variable>
            <xsl:variable name="leaf">
                <xsl:apply-templates select="." mode="is-leaf" />
            </xsl:variable>
            <xsl:value-of select="($chunk-level = $current-level) or ( ($leaf='true') and ($chunk-level > $current-level) )" />
        </xsl:when>
        <xsl:when test="$structural='false'">
            <xsl:value-of select="$structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: Structural determination (<xsl:value-of select="$structural" />) failed for is-chunk at <xsl:apply-templates select="." mode="long-name"/></xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- #################################### -->
<!-- Abstract Chunking of Structural Nodes-->
<!-- #################################### -->

<!-- Implementations get structural nodes of two types          -->
<!--                                                            -->
<!--   1) "chunk"                                               -->
<!--       usually realizable as a single file by               -->
<!--       applying default templates                           -->
<!--                                                            -->
<!--   2) "intermediate":                                       -->
<!--       usually realizable as a single file with a title,    -->
<!--       introduction and conclusion surrounding a summary    -->
<!--       of the subdivisions it contains                      -->
<!--                                                            -->
<!-- So an implementation must implement two modal templates    -->
<!--                                                            -->
<!--   1) match="&STRUCTURAL;" mode="chunk"                     -->
<!--   2) match="&STRUCTURAL;" mode="intermediate"              -->
<!--                                                            -->
<!-- Similarities can be consolidated within the implementation -->
<!-- See  xsl/mathbook-html.xsl  a typical example              -->

<xsl:template match="&STRUCTURAL;" mode="chunking">
    <xsl:variable name="chunk">
        <xsl:apply-templates select="." mode="is-chunk" />
    </xsl:variable>
     <xsl:choose>
        <xsl:when test="$chunk='true'">
            <!-- <xsl:message>CHUNK: <xsl:apply-templates select="." mode="long-name" /></xsl:message> -->
            <xsl:apply-templates select="." mode="chunk" />
        </xsl:when>
        <xsl:otherwise>
            <!-- <xsl:message>INTER: <xsl:apply-templates select="." mode="long-name" /></xsl:message> -->
            <xsl:apply-templates select="." mode="intermediate" />
            <xsl:apply-templates select="&STRUCTURAL;" mode="chunking" />
        </xsl:otherwise>
    </xsl:choose>
 </xsl:template>

<!-- docinfo, and anything else, is immune and dead-ends -->
<xsl:template match="*" mode="chunking" />

<!-- With an implementation of a file-wrapping routine,     -->
<!-- a typical use is to                                    -->
<!--                                                        -->
<!--   (a) apply a default template to the structural       -->
<!--       node for a complete (chunk'ed) node              -->
<!--                                                        -->
<!--   (b) apply a modal template to the structural         -->
<!--       node for a summary (intermediate) node           -->
<!--                                                        -->
<!-- The file-wrap routine should accept two parameters     -->
<!--                                                        -->
<!--   1) a "page-type" string to identify the type of page -->
<!--   2) the "content" to be wrapped                       -->

<!-- A complete page for a structural subdivision -->
<xsl:template match="&STRUCTURAL;" mode="chunk">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="page-type" select="'complete'" />
        <xsl:with-param name="content">
            <xsl:apply-templates select="." />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- A summary page for a structural subdivision -->
<xsl:template match="&STRUCTURAL;" mode="intermediate">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="page-type" select="'summary'" />
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="summary" />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- A default summary page can just ignore the structural      -->
<!-- divisions within though usually you might want to do       -->
<!-- something with them, so you would override this template   -->
<!-- with an implementation.  See xsl/mathbook-sage-doctest.xsl -->
<!-- which uses all of these general routines here              -->
<xsl:template match="&STRUCTURAL;" mode="summary">
    <xsl:apply-templates select="*[not(&STRUCTURAL-FILTER;)]" />
</xsl:template>


<!-- Containing Filenames, URLs -->
<!-- Relative to the chunking in effect, every -->
<!-- XML element is born within some file.     -->
<!-- That filename will have a different       -->
<!-- suffix in different conversions.          -->
<!-- Parameter: $file-extension, set globally  -->
<xsl:template match="*" mode="containing-filename">
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:variable name="chunk">
        <xsl:apply-templates select="." mode="is-chunk" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true' or $chunk='true'">
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:value-of select="$file-extension" />
            <!-- DEPRECATION: May 2015, replace with terminate=yes if present without an xml:id -->
            <xsl:if test="@filebase">
                <xsl:message>MBX:WARNING: filebase attribute (value=<xsl:value-of select="@filebase" />) is deprecated, use xml:id attribute instead</xsl:message>
            </xsl:if>
        </xsl:when>
        <!-- Halts since "mathbook" element will be chunk (or earlier) -->
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="containing-filename" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Every XML element has a URL associated with it -->
<!-- A containing filename, plus an optional anchor/id  -->
<xsl:template match="*" mode="url">
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:variable name="chunk">
        <xsl:apply-templates select="." mode="is-chunk" />
    </xsl:variable>
    <xsl:apply-templates select="." mode="containing-filename" />
    <xsl:if test="$intermediate='false' and $chunk='false'">
        <xsl:text>#</xsl:text>
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:if>
</xsl:template>


<!-- ###### -->
<!-- Titles -->
<!-- ###### -->

<!-- Titles are like metadata, they are a useful property    -->
<!-- of many things and they migrate many different places.  -->
<!-- So principally, we kill them on sight.  But we provide  -->
<!-- modal templates as interfaces to titles and derivatives -->
<!-- of them for purposes where only a restricted subset of  -->
<!-- their content is allowed.                               -->
<!--                                                         -->
<!-- Also, many subdivisions have natural default titles,    -->
<!-- so we want to accomodate that option, and do so via     -->
<!-- the localization routines.                              -->

<!-- With modal templates below, the default template does nothing -->
<xsl:template match="title" />
<xsl:template match="subtitle" />

<!-- Some items have default titles that make sense         -->
<!-- Typically these are one-off subdivisions (eg preface), -->
<!-- or repeated generic divisions (eg exercises)           -->
<xsl:template match="frontmatter|colophon|preface|foreword|acknowledgement|dedication|biography|references|exercises|backmatter|index-part" mode="has-default-title">
    <xsl:text>true</xsl:text>
</xsl:template>
<xsl:template match="*" mode="has-default-title">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="*" mode="title-full">
    <xsl:variable name="default-exists">
        <xsl:apply-templates select="." mode="has-default-title" />
    </xsl:variable>
    <xsl:choose>
        <!-- node() matches text nodes and elements -->
        <xsl:when test="title">
            <xsl:apply-templates select="title/node()" />
        </xsl:when>
        <xsl:when test="$default-exists='true'">
            <xsl:apply-templates select="." mode="type-name" />
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- TODO: ban fn in titles, then maybe this is obsolete -->
<!-- or maybe we should be careful about math            -->
<xsl:template match="*" mode="title-simple">
    <xsl:variable name="default-exists">
        <xsl:apply-templates select="." mode="has-default-title" />
    </xsl:variable>
    <xsl:choose>
        <!-- node() matches text nodes and elements -->
        <xsl:when test="title">
            <xsl:apply-templates select="title/node()[not(self::fn)]"/>
        </xsl:when>
        <xsl:when test="$default-exists='true'">
            <xsl:apply-templates select="." mode="type-name" />
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A version of the title with all abnormal characters stripped --><!-- http://stackoverflow.com/questions/1267934/removing-non-alphanumeric-characters-from-string-in-xsl -->
<xsl:template match="*" mode="title-filesafe">
    <xsl:variable name="raw-title">
        <xsl:apply-templates  select="title/node()[not(self::fn)]" />
    </xsl:variable>
    <xsl:variable name="letter-only-title">
        <xsl:value-of select="translate($raw-title, translate($raw-title,
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ', ''), '')" />
    </xsl:variable>
    <xsl:value-of select="translate($letter-only-title, ' ', '_')" />
</xsl:template>

<!-- This comes from writing out WW problems to filenames    -->
<!-- in some sort of reasonable numbering scheme             -->
<!-- It is not integrated into the above complexity-scheme   -->
<!-- (though does call the "title-filesafe" modal template)  -->
<!-- Consider integration if there is a refactoring of above -->
<xsl:template match="*" mode="numbered-title-filesafe">
    <!-- traditional "dotted" number -->
    <xsl:variable name="dotted-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:variable name="title-string">
        <xsl:apply-templates select="." mode="title-filesafe" />
    </xsl:variable>
    <!-- number output, with dot to dash conversion -->
    <xsl:value-of select="translate($dotted-number, '.', '_')" />
    <!-- separator, if needed -->
    <xsl:if test="not($dotted-number = '' or $title-string = '')">
        <xsl:text>-</xsl:text>
    </xsl:if>
    <xsl:value-of select="$title-string" />
</xsl:template>

<!-- We get subtitles the same way, but with no variations -->
<xsl:template match="*" mode="subtitle">
    <xsl:apply-templates select="subtitle/node()" />
</xsl:template>


<!-- ######################## -->
<!-- Widths of Images, Videos -->
<!-- ######################## -->

<xsl:template match="image|video" mode="image-width">
    <xsl:param name="width-override" select="''" />
    <!-- every (?) image comes here for width, check for height (never was on video) -->
    <xsl:if test="@height">
        <xsl:message>MBX:WARNING: the @height attribute of an &lt;image&gt; is deprecated, it will be ignored (2016-07-31)</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <!-- test for author-provided poorly-constructed width -->
    <xsl:if test="@width">
        <xsl:variable name="improved-width" select="normalize-space(@width)" />
        <xsl:if test="not(substring($improved-width, string-length($improved-width)) = '%')">
            <xsl:message>MBX:ERROR: a @width attribute is not specified as a percentage (<xsl:value-of select="@width" />), the alternative form is deprecated (2016-07-31)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:if>
    <!-- overrides, global default, should be error-checked, sanitized elsewhere -->
    <xsl:choose>
        <!-- in sidebyside, or contained figure, then fill panel -->
        <!-- TODO:  warn if @width on sidebyside/*/image -->
        <xsl:when test="$width-override">
            <xsl:value-of select="$width-override" />
        </xsl:when>
        <!-- if given, use it -->
        <xsl:when test="@width">
            <xsl:value-of select="normalize-space(@width)" />
        </xsl:when>
        <xsl:when test="/mathbook/docinfo/defaults/image-width">
            <xsl:value-of select="normalize-space(/mathbook/docinfo/defaults/image-width)" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>100%</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################ -->
<!-- Names of Objects -->
<!-- ################ -->

<!-- Ultimately translations are all contained in the files of  -->
<!-- the xsl/localizations directory, which provides            -->
<!-- upper-case, singular versions.  In this way, we only ever  -->
<!-- hardcode a string (like "Chapter") once                    -->
<!-- First template is modal, and calls subsequent named        -->
<!-- template where translation with keys happens               -->
<!-- This template allows a node to report its name             -->
<xsl:template match="*" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="local-name(.)" />
    </xsl:call-template>
</xsl:template>

<!-- sidebyside is *always* a specialized Figure, if captioned -->
<xsl:template match="sidebyside" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'figure'" />
    </xsl:call-template>
</xsl:template>

<!-- This template translates an string to an upper-case language-equivalent -->
<!-- Sometimes we must call this directly, but usually better to apply the   -->
<!-- template mode="type-name" to the node, which then calls this routine    -->
<!-- NB: this key concatenation might appear more complicated than           -->
<!--     necessary but may make supporting multiple languages easier?        -->
<!-- TODO: perhaps allow mixed languages, so don't set document language globally,  -->
<!-- but search up through parents until you find a lang tag                        -->
<xsl:key name="localization-key" match="localization" use="concat(../@name, @string-id)"/>

<xsl:template name="type-name">
    <xsl:param name="string-id" />
    <xsl:variable name="translation">
        <xsl:choose>
            <!-- First look in docinfo for document-specific rename -->
            <xsl:when test="/mathbook/docinfo/rename[@element=$string-id and @lang=$document-language]">
                <xsl:apply-templates select="/mathbook/docinfo/rename[@element=$string-id and @lang=$document-language]" />
            </xsl:when>
            <!-- default to a lookup from the localization file's nodes -->
            <xsl:otherwise>
                <xsl:for-each select="$translation-nodes">
                    <xsl:value-of select="key('localization-key', concat($document-language,$string-id) )"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
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


<!-- ########### -->
<!-- Identifiers        -->
<!-- ########### -->

<!--                     -->
<!-- Internal Identifier -->
<!--                     -->

<!-- A *unique* text identifier for any element -->
<!-- Uses:                                      -->
<!--   HTML: filenames (pages and knowls)       -->
<!--   HTML: anchors for references into pages  -->
<!--   LaTeX: labels, ie cross-references       -->
<!-- Format:                                          -->
<!--   the content (text) of an xml:id if provided    -->
<!--   otherwise, elementname-serialnumber (doc-wide) -->
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

<!--                                -->
<!-- Label (cross-reference target) -->
<!--                                -->

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

<!--            -->
<!-- Long Names -->
<!--            -->

<!-- Simple text representations of structural elements        -->
<!-- Type, number (empty?), optional title typically           -->
<!-- Ignore footnotes in these constructions                   -->
<!-- Used for author's report, LaTeX typeout during processing -->
<xsl:template match="*" mode="long-name">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-simple"/>
</xsl:template>


<!-- ######### -->
<!-- Numbering -->
<!-- ######### -->

<!-- We mimic default LaTeX behavior as much as possible    -->
<!--                                                        -->
<!-- There are six numbering schemes in place:              -->
<!-- 1) divisions: sections, subsections, etc.              -->
<!-- 2) environments: theorems, examples, exercises, figures -->
<!-- 3) equations: display mathematics                      -->
<!-- 4) exercises: as part of a section of exercises        -->
<!-- 5) bibliographic items: in multiple sections           -->
<!-- 6) footnotes:                                          -->

<!-- Every such item has two numbers                   -->
<!--                                                   -->
<!-- a) "structural": for example, X.Y.Z for an item   -->
<!--     in Chapter X, Section Y, Subsection Z         -->
<!-- b) "serial": for example N, where the item is     -->
<!--     number N of its scheme, within some division  -->
<!--                                                   -->
<!-- We form a "full number" by concatenating these,   -->
<!-- so "Claim X.Y.Z.N" would be the N-th instance of  -->
<!-- a scheme 2 item with division X.Y.Z. An empty     -->
<!-- serial number is indicative of not being numbered -->
<!--                                                   -->
<!-- Parameters of the form "numbering.<scheme>.level" -->
<!-- control the number of components in these numbers -->

<!--                -->
<!-- Serial Numbers -->
<!--                -->

<!-- These count the occurence of the item, within it's  -->
<!-- scheme and within a natural, or configured, subtree -->

<!-- Serial Numbers: Subdivisions -->
<!-- To respect the maximum level for numbering, we               -->
<!-- return an empty serial number at an excessive level,         -->
<!-- otherwise we call for a serial number relative to peers      -->
<!-- via particular modal templates.  These may include Exercises -->
<!-- and References sections, which can occur at multiple levels  -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|exercises|references" mode="serial-number">
    <xsl:variable name="relative-level">
        <xsl:apply-templates select="." mode="level" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$relative-level > $numbering-maxlevel">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="raw-serial-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="part" mode="raw-serial-number">
    <xsl:number format="I" />
</xsl:template>
<!-- TODO: condition on part/chapter style to use  level='any'; from="book/part"  to cross part boundaries -->
<xsl:template match="chapter" mode="raw-serial-number">
    <xsl:number count="chapter|references|exercises" format="1" />
</xsl:template>
<xsl:template match="appendix" mode="raw-serial-number">
    <xsl:number format="A" />
</xsl:template>
<xsl:template match="section" mode="raw-serial-number">
    <xsl:number count="section|references|exercises" format="1" />
</xsl:template>
<xsl:template match="subsection" mode="raw-serial-number">
    <xsl:number count="subsection|references|exercises" format="1" />
</xsl:template>
<xsl:template match="subsubsection" mode="raw-serial-number">
    <xsl:number count="subsubsection|references|exercises" format="1" />
</xsl:template>
<xsl:template match="exercises|references" mode="raw-serial-number">
    <xsl:number count="part|chapter|appendix|section|subsection|subsubsection|references|exercises" format="1" />
</xsl:template>

<!-- Serial Numbers: Theorems, Examples, Inline Exercise, Figures, Etc. -->
<!-- We determine the appropriate subtree to count within     -->
<!-- given the document root and the configured depth         -->
<!-- Note: the "from" attribute can only take a match pattern -->
<!-- See: the footnote template below for a simpler example   -->

<!-- First, if we are at the maximum numbering level,                            -->
<!-- or less, for a particular scheme then we always base the                    -->
<!-- subtree at the most immediate enclosing structural element                  -->
<!-- If we are at a greater level than the maximum numbering level,              -->
<!-- then we base the subtree at the enclosing structural                        -->
<!-- element that is at the maximum level                                        -->
<!-- This template returns the absolute level necessary based on                 -->
<!-- the particular scheme as a parameter: theorems, equations and footnotes.    -->
<!-- Exercises (in sets) and bibliographic items (in references) will always     -->
<!-- get their serial numbers from within their immediately enclosing structure. -->
<xsl:template match="*" mode="absolute-subtree-level">
    <xsl:param name="numbering-items" />
    <!-- determine enclosing level of numbered item -->
    <xsl:variable name="raw-element-level">
        <xsl:apply-templates select="." mode="enclosing-level" />
    </xsl:variable>
    <!-- if we are deep into the tree, beyond resetting counters,           -->
    <!-- then count from a subtree at the numbering level,                  -->
    <!-- else remain within enclosing level, as structure number will reset -->
    <xsl:variable name="raw-subtree-level">
        <xsl:choose>
            <xsl:when test="$raw-element-level > $numbering-items">
                <xsl:value-of select="$numbering-items" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$raw-element-level" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$raw-subtree-level + $root-level" />
</xsl:template>

<!-- Note on tables and figures:                                         -->
<!-- no caption, no number (mirrors LaTeX behavior),                     -->
<!-- caption on a sibling indicates a subitem of a sidebyside,           -->
<!-- where the subitem is subnumbered due to caption/number on container -->
<!-- TODO: investigate entities for "number='no'" upgrade -->
<!-- http://pimpmyxslt.com/articles/entity-tricks-part1/  -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise|figure|table|listing|sidebyside" mode="serial-number">
    <xsl:variable name="subtree-level">
        <xsl:apply-templates select="." mode="absolute-subtree-level">
            <xsl:with-param name="numbering-items" select="$numbering-theorems" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1"><xsl:number from="book|article|letter|memo" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|table[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|listing[caption]|sidebyside[caption]" /></xsl:when>
        <xsl:when test="$subtree-level=0"><xsl:number from="part" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|table[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|listing[caption]|sidebyside[caption]" /></xsl:when>
        <xsl:when test="$subtree-level=1"><xsl:number from="chapter|book/appendix" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|table[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|listing[caption]|sidebyside[caption]" /></xsl:when>
        <xsl:when test="$subtree-level=2"><xsl:number from="section|article/appendix" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|table[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|listing[caption]|sidebyside[caption]" /></xsl:when>
        <xsl:when test="$subtree-level=3"><xsl:number from="subsection" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|table[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|listing[caption]|sidebyside[caption]" /></xsl:when>
        <xsl:when test="$subtree-level=4"><xsl:number from="subsubsection" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|table[not(preceding-sibling::caption or following-sibling::caption) and child::caption]|listing[caption]|sidebyside[caption]" /></xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for theorem number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<!-- Proofs may be numbered (for cross-reference knowls) -->
<xsl:template match="proof" mode="serial-number">
    <xsl:number />
</xsl:template>

<!-- Serial Numbers: Projects -->
<!-- Category that gets their own numbering scheme -->
<xsl:template match="&PROJECT-LIKE;" mode="serial-number">
    <xsl:variable name="subtree-level">
        <xsl:apply-templates select="." mode="absolute-subtree-level">
            <xsl:with-param name="numbering-items" select="$numbering-projects" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1"><xsl:number from="book|article|letter|memo" level="any" count="&PROJECT-LIKE;" /></xsl:when>
        <xsl:when test="$subtree-level=0"><xsl:number from="part" level="any" count="&PROJECT-LIKE;" /></xsl:when>
        <xsl:when test="$subtree-level=1"><xsl:number from="chapter|book/appendix" level="any" count="&PROJECT-LIKE;" /></xsl:when>
        <xsl:when test="$subtree-level=2"><xsl:number from="section|article/appendix" level="any" count="&PROJECT-LIKE;" /></xsl:when>
        <xsl:when test="$subtree-level=3"><xsl:number from="subsection" level="any" count="&PROJECT-LIKE;" /></xsl:when>
        <xsl:when test="$subtree-level=4"><xsl:number from="subsubsection" level="any" count="&PROJECT-LIKE;" /></xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for project number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Equations -->
<!-- We determine the appropriate subtree to count within  -->
<!-- given the document root and the configured depth      -->
<!-- Note: numbered/unnumbered accounted for here          -->
<xsl:template match="mrow|men" mode="serial-number">
    <xsl:variable name="subtree-level" select="$numbering-equations + $root-level" />
    <xsl:choose>
        <xsl:when test="$subtree-level=-1"><xsl:number from="book|article|letter|memo" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
        <xsl:when test="$subtree-level=0"><xsl:number from="part" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
        <xsl:when test="$subtree-level=1"><xsl:number from="chapter|book/appendix" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
        <xsl:when test="$subtree-level=2"><xsl:number from="section|article/appendix" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
        <xsl:when test="$subtree-level=3"><xsl:number from="subsection" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
        <xsl:when test="$subtree-level=4"><xsl:number from="subsubsection" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for equation number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Exercises in Exercises Sections -->
<!-- We determine the appropriate subtree to count within         -->
<!-- given the document root and the configured depth             -->
<!-- Note: numbers may be hard-coded for longevity                -->
<!-- exercisegroups might be intermediate, but do not hinder      -->
<!-- N.B. Same priority as above, so needs to come in this order, -->
<!-- as we wish hard-coded to have higher priority                -->
<xsl:template match="exercises/exercise|exercises/exercisegroup/exercise" mode="serial-number">
    <xsl:number from="exercises" level="any" count="exercise" />
</xsl:template>
<xsl:template match="exercises/exercise[@number]|exercisegroup/exercise[@number]" mode="serial-number">
    <xsl:apply-templates select="@number" />
</xsl:template>
<!-- Hints, answers, solutions may be numbered (for cross-reference knowls) -->
<xsl:template match="hint|answer|solution" mode="serial-number">
    <xsl:number />
</xsl:template>

<!-- Serial Numbers: Bibliographic Items -->
<!-- Always sequential within a References section -->
<xsl:template match="biblio" mode="serial-number">
    <xsl:number from="references" level="any" count="biblio" />
</xsl:template>
<!-- Notes may be numbered (for cross-reference knowls) -->
<xsl:template match="biblio/note" mode="serial-number">
    <xsl:number />
</xsl:template>


<!-- Serial Numbers: Footnotes -->
<!-- We determine the appropriate subtree to count within -->
<!-- given the document root and the configured depth     -->
<xsl:template match="fn" mode="serial-number">
    <xsl:variable name="subtree-level" select="$numbering-footnotes + $root-level" />
    <xsl:choose>
        <xsl:when test="$subtree-level=-1"><xsl:number from="book|article|letter|memo" level="any" count="fn" /></xsl:when>
        <xsl:when test="$subtree-level=0"><xsl:number from="part" level="any" count="fn" /></xsl:when>
        <xsl:when test="$subtree-level=1"><xsl:number from="chapter|book/appendix" level="any" count="fn" /></xsl:when>
        <xsl:when test="$subtree-level=2"><xsl:number from="section|article/appendix" level="any" count="fn" /></xsl:when>
        <xsl:when test="$subtree-level=3"><xsl:number from="subsection" level="any" count="fn" /></xsl:when>
        <xsl:when test="$subtree-level=4"><xsl:number from="subsubsection" level="any" count="fn" /></xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for footnote number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Subfigures, Subtables -->
<!-- A caption on a side-by-side indicates             -->
<!-- subnumbering for enclosed figures and tables      -->
<!-- The serial number is a sub-number, (a), (b), (c), -->
<!-- *Always* with the parenthetical formatting        -->
<!-- In this case the structure number is the          -->
<!-- full number of the enclosing side-by-side         -->
<xsl:template match="sidebyside[caption]/figure|sidebyside[caption]/table" mode="serial-number">
    <xsl:text>(</xsl:text>
    <xsl:number format="a" count="figure|table"/>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Serial Numbers: List Items -->

<!-- First, the number of a list item within its own list -->
<!-- This trades on the MBX format codes being identical to the XSLT codes -->
<xsl:template match="ol/li" mode="item-number">
    <xsl:variable name="code">
        <xsl:apply-templates select=".." mode="format-code" />
    </xsl:variable>
    <xsl:number format="{$code}" />
</xsl:template>

<!-- Second, the serial number computed recursively             -->
<!-- We first check if the list is inside a named list and      -->
<!-- prefix with that number, using a colon to help distinguish -->
<xsl:template match="li" mode="serial-number">
    <xsl:if test="not(ancestor::li) and ancestor::list">
        <xsl:apply-templates select="ancestor::list" mode="number" />
        <xsl:text>:</xsl:text>
    </xsl:if>
    <xsl:if test="ancestor::li">
        <xsl:apply-templates select="ancestor::li[1]" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="item-number" />
</xsl:template>

<!-- Serial Numbers: the unnumbered     -->
<!-- Empty string signifies not numbered -->
<!-- We do provide a "xref number" of an -->
<!-- exercisegroup, but otherwise not    -->
<xsl:template match="book|article|letter|memo|introduction|conclusion|paragraphs|paragraph|frontmatter|preface|abstract|acknowledgement|biography|foreword|dedication|index-part|colophon|backmatter|exercisegroup|p|assemblage" mode="serial-number" />

<!-- If a list item has any ancestor that is not  -->
<!-- an ordered list, then it gets no number      -->
<xsl:template match="ul//li|dl//li" mode="serial-number" />

<!-- A sidebyside without a caption *always*         -->
<!-- indicates no number for the sidebyside.         -->
<!-- (Relevant subcomponents get their own numbers.) -->
<xsl:template match="sidebyside[not(caption)]" mode="serial-number" />

<!-- Figures, tables, listings without captions do not get numbers either -->
<!-- If they have a title, they can be referenced by that string          -->
<xsl:template match="figure[not(caption)]|table[not(caption)]|listing[not(caption)]" mode="serial-number" />

<!-- References in the backmatter are the "master" version -->
<!-- The subdivision gets no number and the references     -->
<!-- should similarly lack a structural number prefix      -->
<xsl:template match="backmatter/references" mode="serial-number" />

<!-- WeBWorK problems are never numbered, because they live    -->
<!-- in (numbered) exercises.  But they have identically named -->
<!-- components of exercises, so we might need to explicitly   -->
<!-- make webwork/solution, etc to be unnumbered.              -->

<!-- Convert this to a warning?  Should not drop in here ever? -->
<xsl:template match="*" mode="serial-number">
    <xsl:text>[NUM]</xsl:text>
</xsl:template>

<!--                       -->
<!-- Multi-Numbers Utility -->
<!--                       -->

<!-- The X.Y.Z part of the containing structural element of any item -->
<!-- The "levels" parameter controls how many parts there are        -->
<!-- Note: this employs the serial numbers of each division          -->
<xsl:template match="*" mode="multi-number">
    <xsl:param name="levels" />
    <xsl:param name="pad" />
    <!-- when ancestor axis is saved as a variable "mathbook" -->
    <!-- occurs in first slot so on initialization we scrub   -->
    <!-- two elements: mathbook and MBX document root         -->
    <!-- frontmatter and backmatter are irrelevant here,      -->
    <!-- so we scrub three elements in that case              -->
    <!-- NB: when parts become "decorative" or "structural"   -->
    <!--     then this might be a place to slide by, or not   -->
    <xsl:variable name="hierarchy" select="ancestor::*" />
    <xsl:variable name="nodes-scrubbed">
        <xsl:choose>
            <xsl:when test="ancestor::frontmatter or ancestor::backmatter">
                <xsl:text>3</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>2</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="one-multi-number">
        <xsl:with-param name="nodes" select="$hierarchy[position() > $nodes-scrubbed]" />
        <xsl:with-param name="levels" select="$levels" />
        <xsl:with-param name="pad" select="$pad" />
    </xsl:call-template>
</xsl:template>

<!-- We recursively compute serial numbers of structural elements               -->
<!-- A period is the separator, and if not empty, there is a terminating period -->
<!-- We halt when                      -->
<!--   (a) there are no more nodes,    -->
<!--   (b) we have enough levels, or   -->
<!--   (c) we hit non-structural stuff -->
<xsl:template name="one-multi-number">
    <xsl:param name="nodes" />
    <xsl:param name="levels" />
    <xsl:param name="pad" />
    <xsl:variable name="the-node" select="$nodes[1]" />
    <xsl:variable name="structural">
        <xsl:apply-templates select="$the-node" mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <!-- done, always get numbering.maximum.level -->
        <xsl:when test="$levels = 0" />
        <!-- pad when we run out of nodes, or out of structural nodes -->
        <!-- recycle node list unchanged, so this continues           -->
        <!-- but decrement the levels to get right amount of padding  -->
        <xsl:when test="not($nodes) or $structural != 'true'">
            <xsl:choose>
                <xsl:when test="$pad='no'" />
                <xsl:otherwise>
                    <xsl:text>0.</xsl:text>
                    <xsl:call-template name="one-multi-number">
                        <xsl:with-param name="nodes" select="$nodes" />
                        <xsl:with-param name="levels" select="$levels - 1" />
                        <xsl:with-param name="pad" select="$pad" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="$the-node" mode="serial-number"/>
            <xsl:text>.</xsl:text>
            <xsl:call-template name="one-multi-number">
                <xsl:with-param name="nodes" select="$nodes[position() > 1]" />
                <xsl:with-param name="levels" select="$levels - 1" />
                <xsl:with-param name="pad" select="$pad" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!--                         -->
<!-- Structure Numbers       -->
<!--                         -->

<!-- We compute multi-part numbers to the necessary,  -->
<!-- or configured, number of components              -->

<!-- Structure Numbers: Divisions -->
<!-- NB: this is number of the *container* of the division,   -->
<!-- a serial number for the division itself will be appended -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|exercises|references" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-maxlevel - 1" />
        <xsl:with-param name="pad" select="'no'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Theorems, Examples, Projects, Inline Exercises, Figures -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise|figure|table|listing|sidebyside" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-theorems" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>
<!-- PROJECT-LIKE is independent, under control of $numbering-projects -->
<xsl:template match="&PROJECT-LIKE;"  mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-projects" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>
<!-- Proofs get structure number from parent theorem -->
<xsl:template match="proof" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
    <xsl:text>.</xsl:text>
</xsl:template>
<!-- Caption'ed side-by-side indicate subnumbering on enclosed figures and tables   -->
<!-- So the structure number of subitems is the full number of enclosing sidebyside -->
<xsl:template match="sidebyside[caption]/figure|sidebyside[caption]/table" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- Structure Numbers: Equations -->
<xsl:template match="mrow|men" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-equations" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Sectional Exercises -->
<!-- If we set a level for sectional exercises, and pad,        -->
<!-- then we could mimic the AMSMath scheme.  But we control    -->
<!-- these numbers universally, so we do not copy this behavior -->
<xsl:template match="exercises/exercise|exercises/exercisegroup/exercise|exercises/exercise[@number]|exercisegroup/exercise[@number]" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-maxlevel" />
        <xsl:with-param name="pad" select="'no'" />
    </xsl:apply-templates>
</xsl:template>
<!-- Hints, answers, solutions get structure number from parent      -->
<!-- exercise's number. Identical for inline and sectional exercises -->
<xsl:template match="hint|answer|solution" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- Structure Numbers: Bibliographic Items -->
<!-- If we set a level for bibliographic items, and pad,        -->
<!-- then we could mimic the AMSMath scheme.  But we control    -->
<!-- these numbers universally, so we do not copy this behavior -->
<xsl:template match="biblio" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-maxlevel" />
        <xsl:with-param name="pad" select="'no'" />
    </xsl:apply-templates>
</xsl:template>
<!-- "main" bibliography gets unqualified numbers -->
<xsl:template match="backmatter/references/biblio" mode="structure-number">
    <xsl:text />
</xsl:template>
<!-- Notes get structure number from parent biblio's number -->
<xsl:template match="biblio/note" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- Structure Numbers: Footnotes -->
<xsl:template match="fn" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-footnotes" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Lists -->
<!-- Lists themselves are not numbered, though     -->
<!-- some individual list items are, so we just    -->
<!-- provide an empty string to prefix list items. -->
<!-- In effect, references are "local"             -->
<xsl:template match="ol/li" mode="structure-number">
    <xsl:text />
</xsl:template>
<!-- An exception is lists inside of exercises, so we     -->
<!-- use the number of the exercise itself as a prefix    -->
<!-- to the number within the list.  We provide the       -->
<!-- separator here since the list item number is allowed -->
<!-- to be local and has no leading symbol                -->
<!-- NB: these templates have equal priority, so order matters -->
<xsl:template match="exercise//ol/li" mode="structure-number">
    <xsl:apply-templates select="ancestor::exercise[1]" mode="number" />
    <xsl:text>.</xsl:text>
</xsl:template>


<!--              -->
<!-- Full Numbers -->
<!--              -->

<!-- Now trivial, container structure plus serial -->
<!-- We condition on empty serial number in       -->
<!-- order to create empty full numbers           -->
<xsl:template match="*" mode="number">
    <xsl:variable name="serial">
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:variable>
    <xsl:if test="not($serial = '')">
        <xsl:apply-templates select="." mode="structure-number" />
        <xsl:value-of select="$serial" />
    </xsl:if>
</xsl:template>

<!-- ################## -->
<!-- SideBySide Layouts -->
<!-- ################## -->

<!-- Horizontal layouts of "panels" with vertical alignment      -->
<!-- A container for layout of other elements, eg figures        -->
<!-- Behaves much like a figure when captioned                   -->
<!-- No notion of columns, no rules or dividers, no row headings -->

<!-- Debugging information is not documented, nor supported     -->
<!-- Colored boxes in HTML, black boxes in LaTeX with baselines -->
<xsl:param name="sbs.debug" select="'no'" />
<xsl:variable name="sbsdebug" select="boolean($sbs.debug = 'yes')" />

<!-- A side-by-side group ("sbsgroup") is a wrapper     -->
<!-- around a sequence of "sidebyside".  It provides    -->
<!--                                                    -->
<!--   (a) overall title                                -->
<!--   (b) overall caption                              -->
<!--   (c) common margins, widths, vertical alignments  -->
<!--   (d) subcaptioning across entire group            -->
<!--                                                    -->
<!-- The implementation here is a working stub, but     -->
<!-- should be overridden, perhaps with "apply-imports" -->

<xsl:template match="sbsgroup">
    <!-- start any wrapper -->
    <!-- handle title -->
    <xsl:apply-templates select="sidebyside" />
    <!-- handle (optional) overall caption -->
    <!-- finish wrapper -->
</xsl:template>

<!-- A "sidebyside" is a sequence of objects laid out       -->
<!-- horizontally in panels.  This is a deviation from      -->
<!-- the usual vertical rythym of a page.  The "best"       -->
<!-- objects are those that are pliable horizontally,       -->
<!-- such as a paragraph, or a scalable image.  Rigid       -->
<!-- objects, like pre-formatted text or some tables,       -->
<!-- require some care from the author.  Attributes         -->
<!-- that control the layout follow, and override           -->
<!-- identical attributes placed on an enclosing            -->
<!-- "sbsgroup" (if employed).                              -->
<!--                                                        -->
<!-- (a) "margins"                                          -->
<!--  - one percentage for both left and right (nn%)        -->
<!--  - default is 0%                                       -->
<!--  - "auto" => margins are half the space between panels -->
<!-- (b) "widths"                                           -->
<!--  - widths of panels, one per panel                     -->
<!--  - space separated list of percentages                 -->
<!--  - default is equal division of available total width  -->
<!-- (c) "valigns", "valign"                                -->
<!--  - vertical alignment of content within panel          -->
<!--  - space separated list of top, middle, bottom         -->
<!--  - singular is common alignment for all panels         -->
<!--  - default is top                                      -->
<!--                                                        -->
<!-- Default behavior is no margins, no spacing             -->
<!-- between panels and equally wide panels.                -->
<!--                                                        -->
<!-- With widths specified, remaining space is              -->
<!-- used to create equal spacing between panels            -->

<xsl:template match="sidebyside">
    <!-- captions, titles on "sidebyside" ignored when used in an sbsgroup -->
    <xsl:if test="parent::sbsgroup and caption">
        <xsl:message>MBX:WARNING: caption of a &lt;sidebyside&gt; is ignored when contained in an &lt;sbsgroup&gt;</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:if test="parent::sbsgroup and title">
        <xsl:message>MBX:WARNING: title of a &lt;sidebyside&gt; is ignored when contained in an &lt;sbsgroup&gt;</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- count real elements meant for panels, discount others -->
    <xsl:variable name="number-panels" select="count(*[not(&METADATA-FILTER;)])" />
    <xsl:if test="$sbsdebug">
        <xsl:message>N:<xsl:value-of select="$number-panels" />:N</xsl:message>
    </xsl:if>

    <!-- clean up, organize, vertical alignments                  -->
    <!-- Always produces space-separated list with trailing space -->
    <!-- Error-check as $valigns string gets depleted below       -->
    <xsl:variable name="valigns">
        <xsl:choose>
            <!-- individual sbs takes priority -->
            <xsl:when test="@valigns">
                <xsl:value-of select="concat(normalize-space(@valigns), ' ')" />
            </xsl:when>
            <!-- singular form is convenience -->
            <xsl:when test="@valign">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(@valign), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- look to enclosing sidebyside group -->
            <xsl:when test="parent::sbsgroup[@valigns]">
                <xsl:value-of select="concat(normalize-space(parent::sbsgroup/@valigns), ' ')" />
            </xsl:when>
            <!-- look to enclosing sidebyside group for singular convenience -->
            <xsl:when test="parent::sbsgroup[@valign]">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(parent::sbsgroup/@valign), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- default: place all panels at the top    -->
            <!-- NB: space at end of string is separator -->
            <xsl:otherwise>
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="'top '" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
             </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>VA:<xsl:value-of select="$valigns" />:VA</xsl:message>
    </xsl:if>

    <!-- clean up and organize widths                             -->
    <!-- Always produces space-separated list with trailing space -->
    <!-- Error-check as $widths string gets depleted below        -->
    <xsl:variable name="normalized-widths">
        <xsl:choose>
            <!-- individual sbs takes priority -->
            <xsl:when test="@widths">
                <xsl:value-of select="concat(normalize-space(@widths), ' ')" />
            </xsl:when>
            <!-- singular form is convenience -->
            <xsl:when test="@width">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(@width), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- look to enclosing sidebyside group -->
            <xsl:when test="parent::sbsgroup[@widths]">
                <xsl:value-of select="concat(normalize-space(parent::sbsgroup/@widths), ' ')" />
            </xsl:when>
            <!-- look to enclosing sidebyside group for singular convenience -->
            <xsl:when test="parent::sbsgroup[@width]">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(parent::sbsgroup/@width), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- defer default computation post-margins      -->
            <!-- NB: "undetermined" widths is a single space -->
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- clean up margins -->
    <xsl:variable name="normalized-margins">
        <xsl:choose>
            <!-- individual sbs takes priority -->
            <xsl:when test="@margins">
                <xsl:value-of select="normalize-space(@margins)" />
            </xsl:when>
            <!-- look to enclosing sidebyside group -->
            <xsl:when test="parent::sbsgroup[@margins]">
                <xsl:value-of select="normalize-space(parent::sbsgroup/@margins)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>0%</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- total widths used/available    -->
    <!-- no attributes, use 100         -->
    <!-- no width, subtract two margins -->
    <!-- widths given, sum them         -->
    <!-- no percent sign, just internal -->
    <!-- TOD: error-check that sum is 100 or less -->
    <xsl:variable name="sum-widths">
        <xsl:choose>
            <xsl:when test="$normalized-widths = ' ' and $normalized-margins = ''">
                <xsl:text>100</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-widths = ' '">
                <xsl:value-of select="100 - 2 * substring-before($normalized-margins, '%')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="sum-percentages">
                    <xsl:with-param name="percent-list" select="$normalized-widths" />
                    <xsl:with-param name="sum" select="'0'" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- have width totals, determine margin         -->
    <!-- automatic creates margins that will be half -->
    <!-- of the subsequent space-width computation   -->
    <!-- Input assumes % present (unless 'auto')     -->
    <!-- Output preserves % on result                -->
    <!-- TODO: test margin is in [0%, 50%] -->
    <xsl:variable name="margin">
        <xsl:choose>
            <xsl:when test="$number-panels = 0">
                <xsl:text>0%</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-margins = 'auto'">
                <xsl:value-of select="(100 - $sum-widths) div (2 * $number-panels)" />
                <xsl:text>%</xsl:text>
            </xsl:when>
            <!-- TODO: condition on % present, let otherwise report failure -->
            <xsl:otherwise>
                <xsl:value-of select="$normalized-margins" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>M:<xsl:value-of select="$margin" />:M</xsl:message>
    </xsl:if>
    <!-- error check for reasonable values -->
    <xsl:if test="(substring-before($margin, '%') &lt; 0) or (substring-before($margin, '%') &gt; 50)">
        <xsl:message>MBX:ERROR:   margins of a &lt;sidebyside&gt; ("<xsl:value-of select="$margin" />") is outside the interval [0%, 50%], (this may be computed, check consistency of "@margins" and "@widths")</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- if no widths given, distribute excess beyond margins -->
    <!-- NB: with percent signs, blank at end always          -->
    <!-- Error-check as $widths string gets depleted below    -->
    <xsl:variable name="widths">
        <xsl:choose>
            <xsl:when test="$normalized-widths = ' '">
                <xsl:variable name="common-width" select="(100 - 2 * substring-before($margin, '%')) div $number-panels" />
                <!-- transfer as percentages (abstract), with blank at end -->
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat($common-width, '% ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
             </xsl:when>
             <xsl:otherwise>
                <xsl:value-of select="$normalized-widths" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>W:<xsl:value-of select="$widths" />:W</xsl:message>
    </xsl:if>

    <!-- compute common spacing between panels, as percent -->
    <!-- subtract margins and sum-widths from 100,         -->
    <!-- and then distribute to n - 1 spaces               -->
    <!-- includes % for external use                       -->
    <xsl:variable name="space-width">
        <xsl:choose>
            <xsl:when test="$number-panels &lt; 2">
                <!-- no spaces, avoids all division by zero -->
                <xsl:text>0</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="(100 - $sum-widths - 2 * substring-before($margin, '%')) div ($number-panels - 1)" />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>%</xsl:text>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>SW:<xsl:value-of select="$space-width" />:SW</xsl:message>
    </xsl:if>
    <!-- overall error check on space width -->
    <xsl:choose>
        <xsl:when test="substring-before($space-width, '%') &lt; 0">
            <xsl:message>MBX:ERROR:   computed space between panels of a &lt;sidebyside&gt; ("<xsl:value-of select="$space-width" />") is negative (this value is computed, check consistency of "@margins" and "@widths")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <xsl:when test="substring-before($space-width, '%') = 'NaN'">
            <xsl:message>MBX:ERROR:   computed space between panels of a &lt;sidebyside&gt; is not a number (this value is computed, check that margins ("<xsl:value-of select="$margin" />") and widths ("<xsl:value-of select="$widths" />") are percentages of the form "nn%")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
    </xsl:choose>

    <!-- initiate recursing through panels,     -->
    <!-- building up headings, captions, panels -->
    <!-- metadata elements skipped in recursion -->
    <xsl:apply-templates select="." mode="sbs-panel">
        <xsl:with-param name="number-panels" select="$number-panels" />
        <xsl:with-param name="the-panel" select="*[1]" />
        <xsl:with-param name="widths" select="$widths" />
        <xsl:with-param name="margins" select="$margin" />
        <xsl:with-param name="space-width" select="$space-width" />
        <xsl:with-param name="valigns" select="$valigns" />
        <xsl:with-param name="has-headings" select="false()" />
        <xsl:with-param name="has-captions" select="false()" />
        <xsl:with-param name="setup" select="''" />
        <xsl:with-param name="headings" select="''" />
        <xsl:with-param name="panels" select="''" />
        <xsl:with-param name="captions" select="''" />
    </xsl:apply-templates>
</xsl:template>

<!-- recursive template to sum percentages         -->
<!-- input: a space-separated list, with %'s'      -->
<!-- NB: expect trailing space as sentinel for end -->
<!-- Output: total, without %, -common use only    -->
<xsl:template name="sum-percentages">
    <xsl:param name="percent-list" />
    <xsl:param name="sum" />
    <xsl:choose>
        <xsl:when test="$percent-list = ''">
            <xsl:value-of select="$sum" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="sum-percentages">
                <xsl:with-param name="percent-list" select="substring-after($percent-list, ' ')" />
                <xsl:with-param name="sum" select="$sum + substring-before($percent-list, '%')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Recursively handle one panel at a time                   -->
<!-- Implementations need to define modal templates           -->
<!--   panel-setup, panel-heading, panel-panel, panel-caption -->
<!-- Final results are coillectively sent to modal            -->
<!--   compose-panels                                         -->
<!-- template to be arranged                                  -->

<xsl:template match="sidebyside" mode="sbs-panel">
    <xsl:param name="number-panels" />
    <xsl:param name="the-panel" />
    <xsl:param name="widths" />
    <xsl:param name="margins" />
    <xsl:param name="space-width" />
    <xsl:param name="valigns" />
    <xsl:param name="has-headings" />
    <xsl:param name="has-captions" />
    <xsl:param name="setup" />
    <xsl:param name="headings" />
    <xsl:param name="panels" />
    <xsl:param name="captions" />
    <xsl:choose>
        <!-- no more panels -->
        <xsl:when test="not($the-panel)">
            <!-- first, check for leftover widths and valigns  -->
            <xsl:if test="not($widths = '')">
                <xsl:message>MBX:WARNING: &lt;sidebyside&gt; has extra "@widths" (did you confuse singular and plural?)</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
            <xsl:if test="not($valigns = '')">
                <xsl:message>MBX:WARNING: &lt;sidebyside&gt; has extra "@valigns" (did you confuse singular and plural?)</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
            <xsl:if test="$sbsdebug">
                <xsl:message>HH: <xsl:value-of select="$has-headings" /> :HH</xsl:message>
                <xsl:message>HC: <xsl:value-of select="$has-captions" /> :HC</xsl:message>
                <xsl:message>----</xsl:message>
            </xsl:if>
            <!-- if there are no headers or captions, we *could* set to an empty string -->
            <!-- now collect components into output wrappers -->
            <xsl:apply-templates select="." mode="compose-panels">
                <xsl:with-param name="number-panels" select="$number-panels" />
                <xsl:with-param name="margins" select="$margins" />
                <xsl:with-param name="space-width" select="$space-width" />
                <xsl:with-param name="setup" select="$setup" />
                <xsl:with-param name="headings" select="$headings" />
                <xsl:with-param name="panels" select="$panels" />
                <xsl:with-param name="captions" select="$captions" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- the overall row can carry metadata (title, caption)  -->
        <!-- so just skip ahead a panel, with no other net effect -->
        <xsl:when test="$the-panel[&METADATA-FILTER;]">
            <xsl:apply-templates select="." mode="sbs-panel">
                <xsl:with-param name="number-panels" select="$number-panels" />
                <xsl:with-param name="the-panel" select="$the-panel/following-sibling::*[1]" />
                <xsl:with-param name="widths" select="$widths" />
                <xsl:with-param name="margins" select="$margins" />
                <xsl:with-param name="space-width" select="$space-width" />
                <xsl:with-param name="valigns" select="$valigns" />
                <xsl:with-param name="has-headings" select="$has-headings" />
                <xsl:with-param name="has-captions" select="$has-captions" />
                <xsl:with-param name="setup" select="$setup" />
                <xsl:with-param name="headings" select="$headings" />
                <xsl:with-param name="panels" select="$panels" />
                <xsl:with-param name="captions" select="$captions" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <!-- collect options from front of attribute strings, and error-check -->
            <!-- first, get and check panel width                                 -->
            <xsl:variable name="width" select="substring-before($widths, ' ')" />
            <xsl:choose>
                <xsl:when test="substring-before($width, '%') &lt; 0">
                    <xsl:message>MBX:ERROR:   panel width in a &lt;sidebyside&gt; ("<xsl:value-of select="$width" />") is negative (this may be computed, check "@margins" and "@widths")</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:when test="substring-before($width, '%') &gt; 100">
                    <xsl:message>MBX:ERROR:   panel width in a &lt;sidebyside&gt; ("<xsl:value-of select="$width" />") is bigger than 100% (this may be computed, check "@margins" and "@widths")</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:when test="$width = ''">
                    <xsl:message>MBX:FATAL:   expecting a &lt;sidebyside&gt; panel width, maybe not enough specified?</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                    <xsl:message terminate="yes">             Quitting...</xsl:message>
                </xsl:when>
            </xsl:choose>

            <!-- next, get and check panel vertical alignment -->
            <xsl:variable name="valign" select="substring-before($valigns, ' ')" />
            <xsl:choose>
                <!-- "top" is default, check first -->
                <xsl:when test="$valign = 'top'" />
                <xsl:when test="$valign = 'bottom'" />
                <xsl:when test="$valign = 'middle'" />
                <xsl:when test="$valign = ''">
                    <xsl:message>MBX:FATAL:   expecting a &lt;sidebyside&gt; panel vertical alignment, maybe not enough specified?</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                    <xsl:message terminate="yes">             Quitting...</xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR:   vertical alignment ("<xsl:value-of select="$valign" />") in &lt;sidebyside&gt; is not "top," "middle" or "bottom"</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- update outputs by appending to recursive calls -->
            <!-- parameter passing is maximum amount, the       -->
            <!-- union of LaTeX and HTML implementations        -->
            <xsl:variable name="new-setup">
                <xsl:value-of select="$setup" />
                <xsl:apply-templates select="$the-panel" mode="panel-setup">
                    <xsl:with-param name="width" select="$width" />
                </xsl:apply-templates>
            </xsl:variable>

            <xsl:variable name="new-headings">
                <xsl:copy-of select="$headings" />
                <xsl:apply-templates select="$the-panel" mode="panel-heading">
                    <xsl:with-param name="width" select="$width" />
                    <xsl:with-param name="margins" select="$margins" />
                </xsl:apply-templates>
            </xsl:variable>

            <xsl:variable name="new-panels">
                <xsl:copy-of select="$panels" />
                <xsl:apply-templates select="$the-panel" mode="panel-panel">
                    <xsl:with-param name="width" select="$width" />
                    <xsl:with-param name="margins" select="$margins" />
                    <xsl:with-param name="valign" select="$valign" />
                </xsl:apply-templates>
            </xsl:variable>

            <xsl:variable name="new-captions">
                <xsl:copy-of select="$captions" />
                <xsl:apply-templates select="$the-panel" mode="panel-caption">
                    <xsl:with-param name="width" select="$width" />
                    <xsl:with-param name="margins" select="$margins" />
                </xsl:apply-templates>
            </xsl:variable>

            <!-- move to next panel, passing updated components        -->
            <!-- once incremented "panel-number" here, but not used    -->
            <!-- update booleans for necessity of headings or captions -->
            <xsl:apply-templates select="." mode="sbs-panel">
                <xsl:with-param name="number-panels" select="$number-panels" />
                <xsl:with-param name="the-panel" select="$the-panel/following-sibling::*[1]" />
                <xsl:with-param name="widths" select="substring-after($widths, ' ')" />
                <xsl:with-param name="margins" select="$margins" />
                <xsl:with-param name="space-width" select="$space-width" />
                <xsl:with-param name="setup" select="$new-setup" />
                <xsl:with-param name="valigns" select="substring-after($valigns, ' ')" />
                <xsl:with-param name="has-headings" select="$has-headings or $the-panel/title" />
                <xsl:with-param name="has-captions" select="$has-captions or $the-panel/caption" />
                <xsl:with-param name="headings" select="$new-headings" />
                <xsl:with-param name="panels" select="$new-panels" />
                <xsl:with-param name="captions" select="$new-captions" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############## -->
<!-- List Utilities -->
<!-- ############## -->

<!-- List Levels -->
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

<!-- To indent properly in markdown, we  -->
<!-- need to count every type of list    -->
<xsl:template match="*" mode="list-level">
    <xsl:param name="level" select="0" />
    <xsl:choose>
        <xsl:when test="ancestor-or-self::ol or ancestor-or-self::ul or ancestor-or-self::dl">
            <xsl:choose>
                <!-- at a node to count -->
                <xsl:when test="self::ol or self::ul or self::dl">
                    <xsl:apply-templates select="parent::*" mode="list-level">
                        <xsl:with-param name="level" select="$level + 1" />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- go up a level w/out incrementing-->
                <xsl:otherwise>
                    <xsl:apply-templates select="parent::*" mode="list-level">
                        <xsl:with-param name="level" select="$level" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- now done, report level -->
        <xsl:otherwise>
            <xsl:value-of select="$level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Labels of ordered lists have formatting codes, which  -->
<!-- we detect here and pass on to other more specialized  -->
<!-- templates for implementation specifics                -->
<!-- In order: Arabic, lower-case Latin, upper-case Latin, -->
<!-- lower-case Roman numeral, upper-case Roman numeral    -->
<!-- Absent a label attribute, defaults go 4 levels deep   -->
<!-- (max for Latex) as: Arabic, lower-case Latin,         -->
<!-- lower-case Roman numeral, upper-case Latin            -->
<xsl:template match="ol" mode="format-code">
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:choose>
                <xsl:when test="contains(@label,'1')">1</xsl:when>
                <xsl:when test="contains(@label,'a')">a</xsl:when>
                <xsl:when test="contains(@label,'A')">A</xsl:when>
                <xsl:when test="contains(@label,'i')">i</xsl:when>
                <xsl:when test="contains(@label,'I')">I</xsl:when>
                <xsl:when test="@label=''">
                    <xsl:message>MBX:WARNING: empty labels on ordered list items are deprecated, switch to an unordered list (2015-12-12)</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: ordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="level">
                <xsl:apply-templates select="." mode="ordered-list-level" />
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$level='0'">1</xsl:when>
                <xsl:when test="$level='1'">a</xsl:when>
                <xsl:when test="$level='2'">i</xsl:when>
                <xsl:when test="$level='3'">A</xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: ordered list is more than 4 levels deep (at level <xsl:value-of select="$level" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Labels of unordered list have formatting codes, which -->
<!-- we detect here and pass on to other more specialized  -->
<!-- templates for implementation specifics                -->
<!-- disc, circle, square or blank are the options         -->
<!-- Default order: disc, circle, square, disc             -->
<xsl:template match="ul" mode="format-code">
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:choose>
                <xsl:when test="@label='disc'">disc</xsl:when>
                <xsl:when test="@label='circle'">circle</xsl:when>
                <xsl:when test="@label='square'">square</xsl:when>
                <xsl:when test="@label=''">none</xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: unordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="level">
                <xsl:apply-templates select="." mode="unordered-list-level" />
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$level='0'">disc</xsl:when>
                <xsl:when test="$level='1'">circle</xsl:when>
                <xsl:when test="$level='2'">square</xsl:when>
                <xsl:when test="$level='3'">disc</xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: unordered list is more than 4 levels deep (at level <xsl:value-of select="$level" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- Format-independent construction of a list of    -->
<!-- intermediate elements, in order of appearance,  -->
<!-- with headers from indicated divisions           -->
<!--                                                 -->
<!-- Implementation requires four abstract templates -->
<!--                                                 -->
<!-- 1.  name="list-of-begin"                        -->
<!-- hook for start of list                          -->
<!--                                                 -->
<!-- 2.  mode="list-of-header"                       -->
<!-- Format/output per division                      -->
<!--                                                 -->
<!-- 3.  mode="list-of-element"                      -->
<!-- Format/output per element                       -->
<!--                                                 -->
<!-- 4. name="list-of-end"                           -->
<!-- hook for end of list                            -->

<xsl:template match="list-of">
    <!-- Ring-fence terms so matches are not mistaken substrings -->
    <xsl:variable name="elements">
        <xsl:text>|</xsl:text>
        <xsl:value-of select="str:replace(normalize-space(@elements), ' ', '|')" />
        <xsl:text>|</xsl:text>
    </xsl:variable>
    <xsl:variable name="divisions">
        <xsl:text>|</xsl:text>
        <xsl:value-of select="str:replace(normalize-space(@divisions), ' ', '|')" />
        <xsl:text>|</xsl:text>
    </xsl:variable>
    <!-- display subdivision headers with empty contents? -->
    <xsl:variable name="empty">
        <xsl:choose>
            <xsl:when test="not(@empty)">
                <xsl:text>no</xsl:text>
            </xsl:when>
            <!-- DTD should restrict to 'yes'|'no' -->
            <xsl:otherwise>
                <xsl:value-of select="@empty" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- root of the document subtree for list formation     -->
    <!-- defaults to document-wide                           -->
    <!-- DTD should enforce subdivisions as values for scope -->
    <!-- TODO: perhaps use @ref to indicate $subroot,  -->
    <!-- and protect against both a @scope and a @ref  -->
    <xsl:variable name="scope">
        <xsl:choose>
            <xsl:when test="not(@scope)">
                <xsl:choose>
                    <xsl:when test="//mathbook/book"><xsl:text>book</xsl:text></xsl:when>
                    <xsl:when test="//mathbook/article"><xsl:text>article</xsl:text></xsl:when>
                    <xsl:when test="//mathbook/letter"><xsl:text>letter</xsl:text></xsl:when>
                    <xsl:when test="//mathbook/memo"><xsl:text>memo</xsl:text></xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@scope" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="subroot" select="ancestor-or-self::*[local-name() = $scope]" />
    <!-- variable behavior set, now setup -->
    <xsl:call-template name="list-of-begin" />
    <!-- traverse entire document tree, stopping at desired headers or elements -->
    <!-- <xsl:for-each select="/mathbook/article//*|/mathbook/book//*"> -->
    <xsl:for-each select="$subroot//*">
        <!-- write a division header, perhaps              -->
        <!-- check if desired, check if empty and unwanted -->
        <xsl:if test="contains($divisions, concat(concat('|', name(.)), '|'))">
            <xsl:choose>
                <xsl:when test="$empty='no'">
                    <!-- probe subtree, even if we found empty super-tree earlier -->
                    <xsl:variable name="all-elements" select=".//*[contains($elements, concat(concat('|', name(.)), '|'))]" />
                    <xsl:if test="$all-elements">
                        <xsl:apply-templates select="." mode="list-of-header" />
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$empty='yes'">
                    <xsl:apply-templates select="." mode="list-of-header" />
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        <!-- if a desired element, write out summary/link -->
        <xsl:if test="contains($elements, concat(concat('|', name(.)), '|'))='true'">
            <xsl:apply-templates select="." mode="list-of-element" />
        </xsl:if>
    </xsl:for-each>
    <xsl:call-template name="list-of-end" />
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

<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- These templates provide frequently-used      -->
<!-- functions for the construction of tables.    -->
<!-- Document uses carefully when newly employed. -->

<!-- Translate thickness attribute value to integer short name -->
<!-- HTML: makes portion of CSS class names for cells          -->
<!-- PG: makes portion of optional parameter for DataTable     -->
<!-- macro from niceTable.pl for thickness of table cells      -->
<xsl:template name="thickness-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>1</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>2</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>3</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular rule thickness not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate horizontal alignment to CSS short name    -->
<!-- HTML:  makes portion of CSS class names for cells   -->
<!-- LaTeX: provides standard LaTeX horizontal alignment -->
<!-- PG: provide LaTeX-style alignment string for        -->
<!-- DataTable macro from niceTable.pl                   -->
<xsl:template name="halign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='left'">
            <xsl:text>l</xsl:text>
        </xsl:when>
        <xsl:when test="$align='center'">
            <xsl:text>c</xsl:text>
        </xsl:when>
        <xsl:when test="$align='right'">
            <xsl:text>r</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular horizontal alignment attribute not recognized: use left, center, right</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate vertical alignment to CSS short name         -->
<!-- HTML:  makes portion of CSS class names for cells      -->
<!-- LaTeX: provides one standard LaTeX vertical alignment  -->
<!-- PG: provide LaTeX-style alignment string for           -->
<!-- DataTable macro from niceTable.pl                      -->
<xsl:template name="valign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='top'">
            <xsl:text>t</xsl:text>
        </xsl:when>
        <xsl:when test="$align='middle'">
            <xsl:text>m</xsl:text>
        </xsl:when>
        <xsl:when test="$align='bottom'">
            <xsl:text>b</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular vertical alignment attribute not recognized: use top, middle, bottom</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################ -->
<!-- Poetry Utilities -->
<!-- ################ -->

<xsl:template match="poem|poem/author|stanza|stanza/line" mode="poem-indent">
    <xsl:choose>
        <xsl:when test="@indent">
            <xsl:value-of select="@indent" />
        </xsl:when>
        <xsl:when test="self::poem">
            <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="poem-indent" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="poem|poem/author|stanza|stanza/line" mode="poem-halign">
    <xsl:choose>
        <xsl:when test="@halign">
            <xsl:value-of select="@halign" />
        </xsl:when>
        <xsl:when test="self::poem">
            <xsl:text>left</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="poem-halign" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ##### -->
<!-- Music -->
<!-- ##### -->

<!-- Note -->
<xsl:template match="n">
    <xsl:text>\(</xsl:text>
    <!-- Test that pitch class is NOT castable as a number -->
    <xsl:if test="not(number(@pc) = number(@pc))">
        <xsl:text>\text{</xsl:text>
        <xsl:value-of select="@pc"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <!-- Provide something to place accidental -->
    <!-- on if the pitch class is numeric.     -->
    <xsl:if test="number(@pc) = number(@pc) and @acc">
        <xsl:text>{}</xsl:text>
    </xsl:if>
    <!-- Add an accidental if applicable -->
    <xsl:if test="@acc">
        <xsl:text>^</xsl:text>
        <xsl:call-template name="accidentals">
            <xsl:with-param name="accidental"><xsl:value-of select="@acc"/></xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!-- Test that pitch class IS castable as a number -->
    <!-- Accidentals precede numeric pitch classes     -->
    <xsl:if test="number(@pc) = number(@pc)">
        <xsl:value-of select="@pc"/>
    </xsl:if>
    <!-- Add an octave number if applicable -->
    <xsl:if test="@octave">
        <!-- Consideration: should we accommodate other octave notations?    -->
        <!-- Current support is for scientific pitch notation (the standard), -->
        <!-- other octave notation exists such as "Helmholtz pitch notation"  -->
        <xsl:text>_{</xsl:text>
        <xsl:value-of select="@octave"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- Scale Degrees -->
<xsl:template match="scaledeg">
    <!-- Arabic numeral with circumflex accent above)-->
    <xsl:text>\(\hat{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}\) </xsl:text>
</xsl:template>

<!-- Chord -->
<xsl:template match="chord">
    <xsl:text>\(\left.</xsl:text>
    <!-- Root -->
    <xsl:choose>
        <!-- There is an accidental -->
        <xsl:when test="contains(@root, ' ')">
            <!-- Pitch Class -->
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="substring-before(@root, ' ')"/>
            <xsl:text>}</xsl:text>
            <!-- Accidental -->
            <xsl:text>^</xsl:text>
            <xsl:call-template name="accidentals">
                <xsl:with-param name="accidental"><xsl:value-of select="substring-after(@root, ' ')"/></xsl:with-param>
            </xsl:call-template>
            <!-- prevent "double superscript" error -->
            <xsl:text>{}</xsl:text>
        </xsl:when>
        <!-- There is not an accidental -->
        <xsl:otherwise>
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="@root"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Mode (augmented, major, minor, half-diminished, diminished, etc.) -->
    <xsl:if test="@mode">
        <xsl:choose>
            <!-- There is a two part mode -->
            <xsl:when test="contains(@mode, ' ')">
                <!-- Lower Mode -->
                <xsl:call-template name="chordsymbols">
                    <xsl:with-param name="mode"><xsl:value-of select="substring-before(@mode, ' ')"/></xsl:with-param>
                </xsl:call-template>
                <!-- Raise to be in line with bps -->
                <xsl:text>^</xsl:text>
                <!-- Higher Mode -->
                <xsl:call-template name="chordsymbols">
                    <xsl:with-param name="mode"><xsl:value-of select="substring-after(@mode, ' ')"/></xsl:with-param>
                </xsl:call-template>
                <!-- prevent "double superscript" error -->
                <xsl:text>{}</xsl:text>
            </xsl:when>
            <!-- There is a single mode -->
            <xsl:otherwise>
                <xsl:call-template name="chordsymbols">
                    <xsl:with-param name="mode"><xsl:value-of select="@mode"/></xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Bass Position Symbol -->
    <xsl:if test="@bps">
        <!-- Consideration: Even if it is not standard practice, -->
        <!-- will anyone ever want more than two bps numbers?    -->
        <xsl:choose>
            <!-- We use a space to delineate the breaking point of the bps -->
            <!-- e.g. for 6/4 we write "6 4" -->
            <xsl:when test="contains(@bps, ' ')">
                <xsl:text>^{</xsl:text>
                <xsl:value-of select="substring-before(@bps, ' ')"/>
                <xsl:text>}</xsl:text>
                <xsl:text>_{</xsl:text>
                <xsl:value-of select="substring-after(@bps, ' ')"/>
                <xsl:text>}</xsl:text>
            </xsl:when>
            <!-- If there is no space, then we only need a superscript -->
            <xsl:otherwise>
                <xsl:text>^{</xsl:text>
                <xsl:value-of select="@bps"/>
                <xsl:text>}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Suspended -->
    <xsl:if test="@suspended = 'yes'">
        <!-- Consideration: should we make "sus" localized/customizable? -->
        <xsl:text>\text{sus}</xsl:text>
    </xsl:if>
    <!-- Chord Alterations -->
    <xsl:if test="./*">
        <xsl:choose>
            <!-- Turning off parentheses is usually for showing why parenthesization clarifies meaning. -->
            <xsl:when test="@parentheses = 'no'">
                <xsl:text>\left.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\left(</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- We only use a smallmatrix if we have more than one alteration         -->
        <!-- Using smallmatrix with a single entry makes the alteration too small. -->
        <xsl:if test="count(*) > 1">
            <xsl:text>\begin{smallmatrix}</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="*"/>
        <xsl:if test="count(*) > 1">
            <xsl:text>\end{smallmatrix}</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@parentheses = 'no'">
                <xsl:text>\right.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\right)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Alternate Bass Note (e.g. C/G) -->
    <xsl:if test="@bass">
        <!-- Resizes based on components of chord -->
        <xsl:text>\middle/</xsl:text>
        <xsl:choose>
            <!-- Bass note has an accidental -->
            <xsl:when test="contains(@bass, ' ')">
                <!-- Pitch Class -->
                <xsl:text>\text{</xsl:text>
                <xsl:value-of select="substring-before(@bass, ' ')"/>
                <xsl:text>}</xsl:text>
                <!-- Accidental -->
                <xsl:text>^{</xsl:text>
                <xsl:call-template name="accidentals">
                    <xsl:with-param name="accidental"><xsl:value-of select="substring-after(@bass, ' ')"/></xsl:with-param>
                </xsl:call-template>
                <xsl:text>}</xsl:text>
            </xsl:when>
            <!-- Bass note does not have an accidental -->
            <xsl:otherwise>
                <!-- Pitch Class -->
                <xsl:text>\text{</xsl:text>
                <xsl:value-of select="@bass"/>
                <xsl:text>}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <xsl:text>\right.\)</xsl:text>
</xsl:template>

<!-- Chord Alteration -->
<!-- Put a break after each alteration that is not the last -->
<xsl:template match="chord/alteration">
    <xsl:text>\text{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <!-- Separate alterations -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\</xsl:text>
    </xsl:if>
</xsl:template>

<!--                 -->
<!-- Musical Symbols -->
<!--                 -->

<!-- Accidentals -->

<!-- TODO: If requested, add semi- and sesqui- versions of sharp and flat -->
<!-- (Easy with LilyPond in LaTeX) -->
<!-- (For HTML ,there are Unicode characters, though font support may be iffy) -->

<!-- Double-Sharp -->
<xsl:template match="doublesharp">
    <xsl:call-template name="doublesharp"/>
</xsl:template>

<!-- Sharp -->
<xsl:template match="sharp">
    <xsl:call-template name="sharp"/>
</xsl:template>

<!-- Natural -->
<xsl:template match="natural">
    <xsl:call-template name="natural"/>
</xsl:template>

<!-- Flat -->
<xsl:template match="flat">
    <xsl:call-template name="flat"/>
</xsl:template>

<!-- Double-Flat -->
<xsl:template match="doubleflat">
    <xsl:call-template name="doubleflat"/>
</xsl:template>

<!-- Insert the correct accidental -->
<!-- (For use in <n> and <chord>)  -->
<xsl:template name="accidentals">
    <xsl:param name="accidental"/>
    <xsl:choose>
        <xsl:when test="$accidental = 'doubleflat'">
            <xsl:call-template name="doubleflat"/>
        </xsl:when>
        <xsl:when test="$accidental = 'flat'">
            <xsl:call-template name="flat"/>
        </xsl:when>
        <xsl:when test="$accidental = 'natural'">
            <xsl:call-template name="natural"/>
        </xsl:when>
        <xsl:when test="$accidental = 'sharp'">
            <xsl:call-template name="sharp"/>
        </xsl:when>
        <xsl:when test="$accidental = 'doublesharp'">
            <xsl:call-template name="doublesharp"/>
        </xsl:when>
        <!-- For unknown accidentals, use the given value wrapped in \text{} -->
        <xsl:otherwise>
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="$accidental"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Fall-Back values for Accidentals -->

<!-- Double-Sharp -->
<xsl:template name="doublesharp">
    <xsl:text>[DOUBLESHARP]</xsl:text>
</xsl:template>

<!-- Sharp -->
<xsl:template name="sharp">
    <xsl:text>[SHARP]</xsl:text>
</xsl:template>

<!-- Natural -->
<xsl:template name="natural">
    <xsl:text>[NATURAL]</xsl:text>
</xsl:template>

<!-- Flat -->
<xsl:template name="flat">
    <xsl:text>[FLAT]</xsl:text>
</xsl:template>

<!-- Double-Flat -->
<xsl:template name="doubleflat">
    <xsl:text>[DOUBLEFLAT]</xsl:text>
</xsl:template>

<!-- Insert the correct chord symbol -->
<!-- (For use in <chord>)  -->
<xsl:template name="chordsymbols">
    <xsl:param name="mode"/>
    <xsl:choose>
        <xsl:when test="$mode = 'augmented'">
            <xsl:call-template name="augmentedchordsymbol"/>
        </xsl:when>
        <xsl:when test="$mode = 'major'">
            <xsl:call-template name="majorchordsymbol"/>
        </xsl:when>
        <xsl:when test="$mode = 'minor'">
            <xsl:call-template name="minorchordsymbol"/>
        </xsl:when>
        <xsl:when test="$mode = 'halfdiminished'">
            <xsl:text>^</xsl:text>
            <xsl:call-template name="halfdiminishedchordsymbol"/>
            <xsl:text>{}</xsl:text>
        </xsl:when>
        <xsl:when test="$mode = 'diminished'">
            <xsl:text>^</xsl:text>
            <xsl:call-template name="diminishedchordsymbol"/>
            <xsl:text>{}</xsl:text>
        </xsl:when>
        <!-- For unknown chord symbols, use the given value wrapped in \text{} -->
        <!-- e.g. mode="maj" will use \text{maj}                               -->
        <xsl:otherwise>
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="$mode"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Chord Symbols -->

<!-- Augmented -->
<xsl:template name="augmentedchordsymbol">
    <xsl:text>{+}</xsl:text>
</xsl:template>

<!-- Major -->
<xsl:template name="majorchordsymbol">
    <xsl:text>{\Delta}</xsl:text>
</xsl:template>

<!-- Minor -->
<xsl:template name="minorchordsymbol">
    <xsl:text>{-}</xsl:text>
</xsl:template>

<!-- Half Diminished -->
<xsl:template name="halfdiminishedchordsymbol">
    <xsl:text>\text{\o}</xsl:text>
</xsl:template>

<!-- Diminished -->
<xsl:template name="diminishedchordsymbol">
    <xsl:text>{\circ}</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Any cross-reference can be checked to see if     -->
<!-- it points to something legitimate, since this is -->
<!-- a common mistake and often hard to detect/locate -->
<!-- http://www.stylusstudio.com/xsllist/200412/post20720.html -->
<xsl:template name="check-ref">
    <xsl:param name="ref" />
    <xsl:variable name="target" select="id($ref)" />
    <xsl:if test="not(exsl:node-set($target))">
        <xsl:message>MBX:WARNING: unresolved &lt;xref&gt; due to unknown reference "<xsl:value-of select="$ref"/>"</xsl:message>
        <xsl:variable name="inline-warning">
            <xsl:text>Unresolved xref, reference "</xsl:text>
            <xsl:value-of select="$ref"/>
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
</xsl:template>

<!-- A single "ref" is the most common case of an "xref"   -->
<!-- and we also handle comma-separted lists of refs here. -->
<!-- TODO: split these with a match on @ref with comma?    -->
<xsl:template match="xref[@ref]">
    <xsl:choose>
        <xsl:when test="contains(@ref, ',')">
            <!-- For multiple ref, we print an autoname           -->
            <!-- outside of the link text, similarly any          -->
            <!-- wrapping is done outside of the links.           -->
            <!-- These behaviors are controlled by the first ref. -->
            <xsl:variable name="first-ref" select="normalize-space(substring-before(@ref, ','))" />
            <!-- check is repeated later, but best to verify now -->
            <xsl:call-template name="check-ref">
                <xsl:with-param name="ref" select="$first-ref" />
            </xsl:call-template>
            <!-- autoname outside links, wraps -->
            <xsl:variable name="target" select="id($first-ref)" />
            <!-- include autoname prefix in link text, since just one -->
            <xsl:variable name="prefix">
                <xsl:apply-templates select="." mode="xref-prefix">
                    <xsl:with-param name="target" select="$target" />
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:if test="not($prefix = '')">
                <xsl:value-of select="$prefix" />
                <xsl:apply-templates select="." mode="nbsp"/>
            </xsl:if>
            <!-- optionally wrap with parentheses, brackets -->
            <xsl:apply-templates select="$target" mode="xref-wrap">
                <xsl:with-param name="content">
                    <!-- recurse through refs, making links in the process -->
                    <xsl:call-template name="xref-text-multiple">
                        <xsl:with-param name="refs-string" select="@ref" />
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <!-- First, check that the single @ref is good -->
            <xsl:call-template name="check-ref">
                <xsl:with-param name="ref" select="@ref" />
            </xsl:call-template>
            <xsl:variable name="target" select="id(@ref)" />
            <!-- Send the target and text representation for link to a -->
            <!-- format-specific and target-specific link manufacture. -->
            <!-- LaTeX uses \hyperref and \hyperlink, while HTML uses  -->
            <!-- traditional hyperlinks and also modern knowls.        -->
            <xsl:apply-templates select="$target" mode="xref-link">
                <xsl:with-param name="content">
                    <xsl:apply-templates select="." mode="xref-text-one" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="xref-text-multiple">
    <xsl:param name="refs-string" />
    <xsl:variable name="first-char" select="substring($refs-string, 1, 1)" />
    <xsl:choose>
        <!-- leading spaces: repeat in output and strip -->
        <xsl:when test="contains(' ', $first-char)">
            <xsl:value-of select="$first-char" />
            <xsl:call-template name="xref-text-multiple">
                <xsl:with-param name="refs-string" select="substring($refs-string, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- no more separators, last one, process and quit-->
        <xsl:when test="not(contains($refs-string, ','))">
            <!-- <xsl:value-of select="$refs-string" /> -->
            <!-- Check that refs-string is good -->
            <xsl:call-template name="check-ref">
                <xsl:with-param name="ref" select="$refs-string" />
            </xsl:call-template>
            <xsl:variable name="target" select="id($refs-string)" />
            <!-- Send the target and number (only) for link manufacture -->
            <xsl:apply-templates select="$target" mode="xref-link">
                <xsl:with-param name="content">
                    <xsl:apply-templates select="$target" mode="xref-number" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <!-- break at comma, normalize head, process, duplicate comma, recurse on tail -->
        <xsl:otherwise>
            <xsl:variable name="next-ref" select="normalize-space(substring-before($refs-string, ','))" />
            <!-- Check that next-ref is good -->
            <xsl:call-template name="check-ref">
                <xsl:with-param name="ref" select="$next-ref" />
            </xsl:call-template>
            <xsl:variable name="target" select="id($next-ref)" />
            <!-- Send the target and number (only) for link manufacture -->
            <xsl:apply-templates select="$target" mode="xref-link">
                <xsl:with-param name="content">
                    <xsl:apply-templates select="$target" mode="xref-number" />
                </xsl:with-param>
            </xsl:apply-templates>
            <!-- duplicate comma from split -->
            <xsl:text>,</xsl:text>
            <!-- recurse, as there is more to come -->
            <xsl:call-template name="xref-text-multiple">
                <xsl:with-param name="refs-string" select="substring-after($refs-string, ',')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="xref[@first and @last]">
    <!-- check both refs -->
    <xsl:call-template name="check-ref">
        <xsl:with-param name="ref" select="@first" />
    </xsl:call-template>
    <xsl:call-template name="check-ref">
        <xsl:with-param name="ref" select="@last" />
    </xsl:call-template>
    <!-- form both targets -->
    <xsl:variable name="target-first" select="id(@first)" />
    <xsl:variable name="target-last"  select="id(@last)" />
    <!-- content or autoname prefix consciously outside links -->
    <xsl:variable name="prefix">
        <xsl:apply-templates select="." mode="xref-prefix">
            <xsl:with-param name="target" select="$target-first" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="not($prefix = '')">
        <xsl:value-of select="$prefix" />
        <xsl:apply-templates select="." mode="nbsp"/>
    </xsl:if>
    <!-- first link, number only                    -->
    <!-- optionally wrap with parentheses, brackets -->
    <xsl:apply-templates select="$target-first" mode="xref-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select="$target-first" mode="xref-link">
                <xsl:with-param name="content">
                    <xsl:apply-templates select="$target-first" mode="xref-number" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- ndash as separator -->
    <xsl:apply-templates select="." mode="ndash"/>
    <!-- second link, number only                   -->
    <!-- optionally wrap with parentheses, brackets -->
    <xsl:apply-templates select="$target-first" mode="xref-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select="$target-last" mode="xref-link">
                <xsl:with-param name="content">
                    <xsl:apply-templates select="$target-last" mode="xref-number" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- A single "ref" in an md/mrow needs special treatment       -->
<!-- We call a specialized template for use only within an "md" -->
<!-- We restrict to the case of a single ref                    -->
<xsl:template match="mrow/xref[@ref]">
    <xsl:if test="contains(@ref, ',')">
        <xsl:message>MBX:ERROR:   multiple cross-references in a math display (md/mrow, mdn/mrow) are not supported, results may be erratic</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:call-template name="check-ref">
        <xsl:with-param name="ref" select="@ref" />
    </xsl:call-template>
    <xsl:variable name="target" select="id(@ref)" />
    <!-- Send the target and text representation for link to a -->
    <!-- format-specific and target-specific link manufacture. -->
    <!-- Note the template used here is specific to md/mrow    -->
    <!-- LaTeX uses \hyperref and \hyperlink, while HTML uses  -->
    <!-- traditional hyperlinks and also modern knowls.        -->
    <xsl:apply-templates select="$target" mode="xref-link-md">
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="xref-text-one" />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- TODO: the xref-link should perhaps select/match on      -->
<!-- the xref and not the target, then the location of       -->
<!-- the xref can be accomodated (making the "-md" device    -->
<!-- unnecessary and then just doing an override in the HTML -->
<!-- code).  Presumably we can also determnine/analyze the   -->
<!-- target upon reception and deal with it there.           -->

<!-- This is a base implementation for the xref-link -->
<!-- template, which just repeats the content        -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" />
    <xsl:value-of select="$content" />
</xsl:template>

<!-- Prefix, Autonaming of Cross-References -->
<!-- Content in an xref becomes a prefix, no matter what           -->
<!-- Some references get an autoname prefix (eg Section, Theorem), -->
<!-- subject to global and local options, interpreted here         -->
<!-- Element is the  xref, $target  provides the autoname string   -->
<!-- If autoname="title" and the xref has content, then there      -->
<!-- is no number because of the title request and the xref        -->
<!-- content becomes the link text instead                         -->
<xsl:template match="*" mode="xref-prefix">
    <!-- We need the target for autonaming with type-name or title -->
    <xsl:param name="target" />
    <!-- Variable is the local @autoname of the xref -->
    <!-- Local:  blank, yes/no, title                -->
    <!-- Global: yes/no, so 8 combinations           -->
    <xsl:variable name="local" select="@autoname" />
    <!-- 2016-04-07 autoname="plural" never really was viable -->
    <xsl:if test="$local='plural'">
        <xsl:message>MBX:WARNING: "autoname" attribute with value "plural" is deprecated as of 2016-04-07, and there is no replacement</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:choose>
        <!-- if xref has content, then use it, no matter what -->
        <xsl:when test="normalize-space(.)">
            <xsl:apply-templates />
        </xsl:when>
        <!-- 2 combinations: global no, without local override -->
        <xsl:when test="$autoname='no' and ($local='' or $local='no')" />
        <!-- 1 combination: global yes, but local override -->
        <xsl:when test="$autoname='yes' and $local='no'" />
        <!-- 2 combinations: global yes/no, local title option-->
        <xsl:when test="$local='title'">
            <xsl:apply-templates select="$target" mode="title-simple" />
        </xsl:when>
        <!-- 1 combinations: global no, local yes               -->
        <!-- 2 combinations: global yes, local blank/yes        -->
        <!-- intercept biblio items, which are identified by [] -->
        <xsl:when test="$local='yes' or ($autoname='yes' and not($local!=''))">
            <xsl:if test="not($target[self::biblio])">
                <xsl:apply-templates select="$target" mode="type-name" />
            </xsl:if>
        </xsl:when>
        <!-- just makes error message effective -->
        <xsl:when test="not($local != '')"></xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: "autoname" attribute should be yes|no|title, not <xsl:value-of select="$local" /></xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- For cross-references, we manufacture text that         -->
<!-- includes the possible autoname'd prefix, various       -->
<!-- visual hints as to the nature of the target            -->
<!-- (parentheses on equations, brackets on citations)      -->
<!-- and possible extra detail on a citation.               -->
<!-- These only manufacture generic text, modulo special    -->
<!-- characters like non-breaking spaces provided by        -->
<!-- importing stylesheets, and so can be employed in any   -->
<!-- conversion that provides those characters.             -->

<!-- A single "ref" in a xref may have an autoname,         -->
<!-- wrapping of the number, and detail for a bibliographic -->
<!-- item.  We package up all of it as the link text.       -->
<xsl:template match="*" mode="xref-text-one" >
    <!-- autoname passed straight into prefix routine -->
    <!-- detail flagged inside biblio construction    -->
    <xsl:variable name="target" select="id(@ref)" />
    <!-- include autoname prefix in link text, since just one -->
    <xsl:variable name="prefix">
        <xsl:apply-templates select="." mode="xref-prefix">
            <xsl:with-param name="target" select="$target" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <!-- no title, then construct more involved text -->
        <xsl:when test="not(@autoname='title')">
            <xsl:if test="not($prefix = '')">
                <xsl:value-of select="$prefix" />
                <xsl:apply-templates select="." mode="nbsp"/>
            </xsl:if>
            <!-- optionally wrap citations+detail or equations, with formatting -->
            <xsl:apply-templates select="$target" mode="xref-wrap">
                <xsl:with-param name="content">
                    <!-- call an abstract template for the actual number -->
                    <xsl:apply-templates select="$target" mode="xref-number" />
                    <!-- provide optional detail on bibliographic reference, only -->
                    <xsl:if test="@detail != ''">
                        <xsl:choose>
                            <xsl:when test="local-name($target) = 'biblio'">
                                <xsl:text>,</xsl:text>
                                <xsl:apply-templates select="." mode="nbsp"/>
                                <xsl:apply-templates select="@detail" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>MBX:WARNING: xref attribute detail="<xsl:value-of select="@detail" />" only implemented for single references to biblio elements</xsl:message>
                                <xsl:apply-templates select="." mode="location-report" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <!-- as title, simply return it -->
        <xsl:otherwise>
            <xsl:value-of select="$prefix" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Some references, or lists of references -->
<!-- get visual clues as to their nature.    -->
<!-- Here we wrap those special cases and    -->
<!-- pass-through the remainder              -->
<xsl:template match="*" mode="xref-wrap">
    <xsl:param name="content" />
    <xsl:copy-of select="$content" />
</xsl:template>
<xsl:template match="biblio" mode="xref-wrap">
    <xsl:param name="content" />
    <xsl:text>[</xsl:text>
    <xsl:copy-of select="$content" />
    <xsl:text>]</xsl:text>
</xsl:template>
<xsl:template match="men|mrow" mode="xref-wrap">
    <xsl:param name="content" />
    <xsl:text>(</xsl:text>
    <xsl:copy-of select="$content" />
    <xsl:text>)</xsl:text>
</xsl:template>


<!-- This is an abstract template, to accomodate -->
<!-- hard-coded HTML numbers and for LaTeX the   -->
<!-- \ref and \label mechanism                   -->
<xsl:template match="*" mode="xref-number">
    <xsl:text>[XREFNUM]</xsl:text>
</xsl:template>
<!-- For an exercisegroup we meld the "xref-number"     -->
<!-- for the first and last exercise of the group       -->
<!-- An exercise group is only ever numbered for a xref -->
<xsl:template match="exercisegroup" mode="xref-number">
    <xsl:apply-templates select="exercise[1]" mode="xref-number" />
    <xsl:apply-templates select="." mode="ndash"/>
    <xsl:apply-templates select="exercise[last()]" mode="xref-number" />
</xsl:template>

<!-- Provisional cross-references -->
<!-- A convenience for authors in early stages of writing -->
<!-- Appear both inline and moreso in author tools        -->
<!-- TODO: Make cite/@provisional an error eventually     -->
<xsl:template match="cite[@provisional]|xref[@provisional]">
    <xsl:if test="self::cite">
        <xsl:message>MBX:WARNING: &lt;cite provisional="<xsl:value-of select="@provisional" />"&gt; is deprecated, convert to &lt;xref provisional="<xsl:value-of select="@provisional" />"&gt;</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
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
    <xsl:apply-templates select="." mode="location-report" />
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

<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- We build modal templates for certain characters       -->
<!-- so we can employ these templates in generic templates -->
<!-- The defaults here are meant to be unattractive        -->
<!-- The last importing stylesheet wins, so be careful     -->

<xsl:template match="*" mode="nbsp">
    <xsl:text>[NBSP]</xsl:text>
</xsl:template>

<xsl:template match="*" mode="ndash">
    <xsl:text>[NDASH]</xsl:text>
</xsl:template>

<xsl:template match="*" mode="mdash">
    <xsl:text>[MDASH]</xsl:text>
</xsl:template>

<!-- ################### -->
<!-- Reserved Characters -->
<!-- ################### -->

<!-- If a markup languge reserves some characters,        -->
<!-- then we have to provide special handling.            -->
<!-- These are the *union* of all these characters        -->
<!-- implemented in a totally ugly fashion so that if     -->
<!-- these templates are not overridden we hear about it. -->
<!-- These are just for "normal" text, not mathematics    -->
<!-- in LaTeX syntax, nor to function as special          -->
<!-- characters themselves                                -->

<!--           -->
<!-- XML, HTML -->
<!--           -->

<!-- & < > -->

<!-- Ampersand -->
<xsl:template match="ampersand">
    <xsl:text>[AMPERSAND]</xsl:text>
</xsl:template>

<!-- Less Than -->
<xsl:template match="less">
    <xsl:text>[LESSTHAN]</xsl:text>
</xsl:template>

<!-- Greater Than -->
<xsl:template match="greater">
    <xsl:text>[GREATERTHAN]</xsl:text>
</xsl:template>

<!--       -->
<!-- LaTeX -->
<!--       -->

<!-- # $ % ^ & _ { } ~ \ -->

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template match="hash">
    <xsl:text>[HASH]</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<xsl:template match="dollar">
    <xsl:text>[DOLLAR]</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template match="percent">
    <xsl:text>[PERCENT]</xsl:text>
</xsl:template>

<!-- Circumflex  -->
<xsl:template match="circumflex">
    <xsl:text>[CIRCUMFLEX]</xsl:text>
</xsl:template>

<!-- 2015/01/28: there was a mismatch between HTML and LaTeX names -->
<!-- We only have this warning only here                           -->
<xsl:template match="circum">
    <xsl:text>\textasciicircum{}</xsl:text>
    <xsl:message>MBX:WARNING: the "circum" element is deprecated (2015/01/28), use "circumflex"</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:text>[CIRCUM-DEPRECATED]</xsl:text>
</xsl:template>

<!-- Ampersand -->
<!-- Handled above -->

<!-- Underscore -->
<xsl:template match="underscore">
    <xsl:text>[UNDERSCORE]</xsl:text>
</xsl:template>

<!-- Left Brace -->
<xsl:template match="lbrace">
    <xsl:text>[LEFTBRACE]</xsl:text>
</xsl:template>

<!-- Right  Brace -->
<xsl:template match="rbrace">
    <xsl:text>[RIGHTBRACE]</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template match="tilde">
    <xsl:text>[TILDE]</xsl:text>
</xsl:template>

<!-- Backslash -->
<xsl:template match="backslash">
    <xsl:text>[BACKSLASH]</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Other Characters -->
<!-- ################ -->

<!-- Asterisk -->
<!-- Centered as a character, not an exponent -->
<xsl:template match="asterisk">
    <xsl:text>[ASTERISK]</xsl:text>
</xsl:template>

<!-- Left Single Quote -->
<xsl:template match="lsq">
    <xsl:text>[LEFTSINGLEQUOTE]</xsl:text>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template match="rsq">
    <xsl:text>[RIGHTSINGLEQUOTE]</xsl:text>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template match="lq">
    <xsl:text>[LEFTQUOTE]</xsl:text>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template match="rq">
    <xsl:text>[RIGHTQUOTE]</xsl:text>
</xsl:template>

<!-- Left Bracket -->
<xsl:template match="lbracket">
    <xsl:text>[LEFTBRACKET]</xsl:text>
</xsl:template>

<!-- Right Bracket -->
<xsl:template match="rbracket">
    <xsl:text>[RIGHTBRACKET]</xsl:text>
</xsl:template>

<!-- Left Double Bracket -->
<xsl:template match="ldblbracket">
    <xsl:text>[LEFTDOUBLEBRACKET]</xsl:text>
</xsl:template>

<!-- Right Double Bracket -->
<xsl:template match="rdblbracket">
    <xsl:text>[RIGHTDOUBLEBRACKET]</xsl:text>
</xsl:template>

<!-- Left Angle Bracket -->
<xsl:template match="langle">
    <xsl:text>[LEFTANGLEBRACKET]</xsl:text>
</xsl:template>

<!-- Right Angle Bracket -->
<xsl:template match="rangle">
    <xsl:text>[RIGHTANGLEBRACKET]</xsl:text>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<xsl:template match="midpoint">
    <xsl:text>[MIDPOINT]</xsl:text>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<xsl:template match="swungdash">
    <xsl:text>[SWUNGDASH]</xsl:text>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template match="permille">
    <xsl:text>[PERMILLE]</xsl:text>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template match="pilcrow">
    <xsl:text>[PILCROW]</xsl:text>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template match="section-mark">
    <xsl:text>[SECTION]</xsl:text>
</xsl:template>

<!-- Times -->
<!-- A "multiplication sign" symbol for use in text -->
<xsl:template match="times">
    <xsl:text>[TIMES]</xsl:text>
</xsl:template>

<!-- Slash -->
<!-- Forward slash, or virgule (see solidus) -->
<xsl:template match="slash">
    <xsl:text>[SLASH]</xsl:text>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<xsl:template match="solidus">
    <xsl:text>[SOLIDUS]</xsl:text>
</xsl:template>




<!-- Dots
http://tex.stackexchange.com/questions/19180/which-dot-character-to-use-in-which-context

Swung Dash
http://andrewmccarthy.ie/2014/11/06/swung-dash-in-latex/
 -->
<!-- ######### -->
<!-- Groupings -->
<!-- ######## -->

<!-- Characters with left and right variants naturally  -->
<!-- give rise to tags with begin and end variants      -->
<!-- We implement these here with Result Tree Fragments -->
<!-- using polymorphic techniques for the characters    -->
<!-- Be sure not add a temporary top-level element to   -->
<!-- the result tree fragment, so default template can  -->
<!-- process its contents                               -->

<xsl:template match="q">
    <xsl:variable name="q-rtf">
        <fakeroot>
            <lq />
            <xsl:copy-of select="*|text()"/>
            <rq />
        </fakeroot>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($q-rtf)/fakeroot" />
</xsl:template>

<xsl:template match="sq">
    <xsl:variable name="sq-rtf">
        <fakeroot>
            <lsq />
            <xsl:copy-of select="*|text()"/>
            <rsq />
        </fakeroot>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($sq-rtf)/fakeroot" />
</xsl:template>

<xsl:template match="braces">
    <xsl:variable name="braces-rtf">
        <fakeroot>
            <lbrace />
            <xsl:copy-of select="*|text()"/>
            <rbrace />
        </fakeroot>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($braces-rtf)/fakeroot" />
</xsl:template>

<xsl:template match="brackets">
    <xsl:variable name="brackets-rtf">
        <fakeroot>
            <lbracket />
            <xsl:copy-of select="*|text()"/>
            <rbracket />
        </fakeroot>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($brackets-rtf)/fakeroot" />
</xsl:template>

<xsl:template match="dblbrackets">
    <xsl:variable name="dblbrackets-rtf">
        <fakeroot>
            <ldblbracket />
            <xsl:copy-of select="*|text()"/>
            <rdblbracket />
        </fakeroot>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($dblbrackets-rtf)/fakeroot" />
</xsl:template>

<xsl:template match="angles">
    <xsl:variable name="angles-rtf">
        <fakeroot>
            <langle />
            <xsl:copy-of select="*|text()"/>
            <rangle />
            </fakeroot>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($angles-rtf)/fakeroot" />
</xsl:template>

<!-- ############ -->
<!-- Conveniences -->
<!-- ############ -->

<!-- Conveniences, which can be overridden in format-specific conversions -->
<!-- TODO: kern, etc. into LaTeX, HTML versions -->
<xsl:template match="webwork[not(child::node() or @*)]">
    <xsl:text>WeBWorK</xsl:text>
</xsl:template>

<!-- ################### -->
<!-- Errors and Warnings -->
<!-- ################### -->

<!-- Sometimes we want a big warning as part of  -->
<!-- every use of some conversion.  This is it.  -->
<!-- Feed a linefeed in if you want line breaks. -->
<!-- Designed for an 80 column terminal.         -->
<xsl:template name="banner-warning">
    <xsl:param name="warning" />
    <xsl:message>********************************************************************************</xsl:message>
        <xsl:message><xsl:value-of select="$warning" /></xsl:message>
    <xsl:message>********************************************************************************</xsl:message>
</xsl:template>

<!-- We search up the tree, looking for something -->
<!-- an author will recognize, and then report it -->
<!-- Useful for warnings that do not contain any  -->
<!-- identifying information themselves           -->
<xsl:template match="*" mode="location-report">
    <xsl:choose>
        <xsl:when test="@xml:id or title">
            <!-- print information about location -->
            <xsl:message>
                <xsl:text>             located within: </xsl:text>
                <xsl:if test="@xml:id">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="@xml:id" />
                    <xsl:text>" (xml:id)</xsl:text>
                </xsl:if>
                <xsl:if test="@xml:id and title">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:if test="title">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="title" />
                    <xsl:text>" (title)</xsl:text>
                </xsl:if>
            </xsl:message>
        </xsl:when>
        <xsl:when test="mathbook">
            <!-- at root, fail with no action -->
        </xsl:when>
        <xsl:otherwise>
            <!-- pop up a level and try again -->
            <xsl:apply-templates select="parent::*[1]" mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ############ -->
<!-- Deprecations -->
<!-- ############ -->

<!-- Generic deprecation message for uniformity -->
<xsl:template name="deprecation-message">
    <xsl:param name="date-string" />
    <xsl:param name="message" />
    <xsl:param name="occurences" />
    <xsl:message>
        <xsl:text>MBX:DEPRECATE: (</xsl:text>
        <xsl:value-of select="$date-string" />
        <xsl:text>) </xsl:text>
        <xsl:value-of select="$message" />
        <xsl:text> (</xsl:text>
        <xsl:value-of select="$occurences" />
        <xsl:text> time</xsl:text>
        <xsl:if test="$occurences > 1">
            <xsl:text>s</xsl:text>
        </xsl:if>
        <xsl:text>)</xsl:text>
        <!-- once verbosity is implemented -->
        <!-- <xsl:text>, set log.level to see more details</xsl:text> -->
    </xsl:message>
</xsl:template>

<!-- Using the modular  xinclude  scheme at the top level,      -->
<!-- and forgetting the command-line switch is a common mistake -->
<!-- The following is not perfect, but reasonably effective     -->
<!-- Calling context should be "mathbook" element               -->
<xsl:template match="*" mode="generic-warnings">
    <xsl:if test="book and not(book/chapter)">
        <xsl:message>
            <xsl:text>MBX:WARNING:    </xsl:text>
            <xsl:text>Your &lt;book&gt; does not have any chapters.  Maybe you forgot the '--xinclude' switch on your 'xsltproc' command line?</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:if test="article and not(article/p) and not(article/section)">
        <xsl:message>
            <xsl:text>MBX:WARNING:    </xsl:text>
            <xsl:text>Your &lt;article&gt; does not have any sections, nor any top-level paragraphs.  Maybe you forgot the '--xinclude' switch on your 'xsltproc' command line?</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>


<xsl:template match="*" mode="deprecation-warnings">
    <!-- newer deprecations at the top of this list, user will see in this order -->
    <!--  -->
    <xsl:if test="//image/@width[not(contains(., '%'))]">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2016-07-31'" />
            <xsl:with-param name="message" select="'@width attribute on &lt;image&gt; must be expressed as a percentage'" />
            <xsl:with-param name="occurences" select="count(//image/@width[not(contains(., '%'))])" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:if test="//image[@height]">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2016-07-31'" />
            <xsl:with-param name="message" select="'@height attribute on &lt;image&gt; is no longer effective and will be ignored'" />
            <xsl:with-param name="occurences" select="count(//image[@height])" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:if test="//br">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2016-05-23'" />
            <xsl:with-param name="message" select="'&lt;br&gt; can no longer be used to create multiline output; you may use &lt;line&gt; elements in select situations'" />
            <xsl:with-param name="occurences" select="count(//br)" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:if test="//letter/frontmatter/from[not(line)]|//letter/frontmatter/to[not(line)]|//letter/backmatter/signature[not(line)]">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2016-05-23'" />
            <xsl:with-param name="message" select="'&lt;to&gt;, &lt;from&gt;, and &lt;signature&gt; of a letter must be structured as a sequence of &lt;line&gt;'" />
            <xsl:with-param name="occurences" select="count(//letter/frontmatter/from[not(line)]|//letter/frontmatter/to[not(line)]|//letter/backmatter/signature[not(line)])" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:if test="//xref/@autoname='plural'">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2016-04-07'" />
            <xsl:with-param name="message" select="'a cross-reference (&lt;xref&gt;) may not have an @autoname attribute set to plural.  There is no replacement, use content in the xref.'" />
            <xsl:with-param name="occurences" select="count(//xref[@autoname='plural'])" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:if test="//ol/@label=''">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2015-12-12'" />
            <xsl:with-param name="message" select="'an ordered list (&lt;ol&gt;) may not have empty labels, and numbering will be unpredictable.  Switch to an unordered list  (&lt;ul&gt;)'" />
            <xsl:with-param name="occurences" select="count(//ol[@label=''])" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:if test="$html.chunk.level != ''">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2015/06/26'" />
            <xsl:with-param name="message" select="'the  html.chunk.level  parameter has been replaced by simply chunk.level  and now applies more generally'" />
            <xsl:with-param name="occurences" select="'1'" />
        </xsl:call-template>
    </xsl:if>
    <!-- tables are radically different, tgroup element is a marker -->
    <xsl:if test="//tgroup">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2015/03/17'" />
            <xsl:with-param name="message" select="'tables are done quite differently, the &quot;tgroup&quot; element is indicative'" />
            <xsl:with-param name="occurences" select="count(//tgroup)" />
        </xsl:call-template>
    </xsl:if>
    <!-- tables are radically different, entry to cell shows magnitude -->
    <xsl:if test="//tgroup/thead/row/entry or //tgroup/tbody/row/entry">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2015/03/17'" />
            <xsl:with-param name="message" select="'tables are done quite differently, the &quot;entry&quot; element should be replaced by the &quot;cell&quot; element'" />
            <xsl:with-param name="occurences" select="count(//tgroup/thead/row/entry) + count(//tgroup/tbody/row/entry)" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- paragraph is renamed more accurately to paragraphs -->
    <xsl:if test="//paragraph">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2015/03/13'" />
            <xsl:with-param name="message" select="'the &quot;paragraph&quot; element is deprecated, replaced by functional equivalent &quot;paragraphs&quot;'" />
            <xsl:with-param name="occurences" select="count(//paragraph)" />
        </xsl:call-template>
    </xsl:if>
    <!-- tikz is generalized to latex-image-code -->
    <xsl:if test="//tikz">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2015/02/20'" />
            <xsl:with-param name="message" select="'the &quot;tikz&quot; element is deprecated, convert to &quot;latex-image-code&quot; inside &quot;image&quot;'" />
            <xsl:with-param name="occurences" select="count(//tikz)" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- naked tikz, asymptote, sageplot are banned                -->
    <!-- typically these would be in a figure, but not necessarily -->
    <xsl:if test="//figure/tikz or //figure/asymptote or //figure/sageplot">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2015/02/08'" />
            <xsl:with-param name="message" select="'&quot;tikz&quot;, &quot;asymptote&quot;, &quot;sageplot&quot;, elements must always be contained directly within an &quot;image&quot; element, rather than directly within a &quot;figure&quot; element'" />
            <xsl:with-param name="occurences" select="count(//figure/tikz) + count(//figure/asymptote) + count(//figure/sageplot)" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- once both circum and circumflex existed, circumflex won -->
    <xsl:if test="//circum">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2015/01/28'" />
            <xsl:with-param name="message" select="'the &quot;circum&quot; element has been replaced by the &quot;circumflex&quot; element'" />
            <xsl:with-param name="occurences" select="count(//circum)" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- xref once had variant called "cite" -->
    <xsl:if test="//cite">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2014/06/25'" />
            <xsl:with-param name="message" select="'the &quot;cite&quot; element is deprecated, convert to &quot;xref&quot;'" />
            <xsl:with-param name="occurences" select="count(//cite)" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- @filebase has been replaced in function by @xml:id -->
    <xsl:if test="//@filebase">
        <xsl:call-template name="deprecation-message">
            <xsl:with-param name="date-string" select="'2014/05/04'" />
            <xsl:with-param name="message" select="'the &quot;filebase&quot; attribute is deprecated, convert to &quot;xml:id&quot;'" />
            <xsl:with-param name="occurences" select="count(//@filebase)" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Some specific warnings that can go here  -->
<!-- for items that are totally gone and not  -->
<!-- useful anymore in their original context -->

<xsl:template match="br">
    <xsl:message>MBX:WARNING: the &lt;br&gt; element has been deprecated (2016/05/23); you may use &lt;line&gt; elements in select situations</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>

<xsl:template match="tbody">
    <xsl:message>MBX:WARNING: tables are done very differently now (2015/03/17), the "tbody" element is indicative</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
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

<!-- Converter information for header, generic -->
<!-- params are strings to make comment lines in target file    -->
<!-- "copy-of" supresses output-escaping of HTML/XML characters -->
<xsl:template name="converter-blurb">
    <xsl:param name="lead-in" />
    <xsl:param name="lead-out" />
    <xsl:copy-of select="$lead-in" /><xsl:text>**************************************</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>* Generated from MathBook XML source *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*    on </xsl:text>  <xsl:value-of select="date:date-time()" />
                                                                      <xsl:text>    *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*                                    *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*   http://mathbook.pugetsound.edu   *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*                                    *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>**************************************</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- We issue specialized blurbs with appropriate comment lines -->
<xsl:template name="converter-blurb-latex">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="'%'" />
        <xsl:with-param name="lead-out" select="'%'" />
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-html">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in">
            <xsl:text disable-output-escaping='yes'>&lt;!--</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="lead-out">
            <xsl:text disable-output-escaping='yes'>--&gt;</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-python">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="'#'" />
        <xsl:with-param name="lead-out" select="'#'" />
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-perl">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="'#'" />
        <xsl:with-param name="lead-out" select="'#'" />
    </xsl:call-template>
</xsl:template>

<!-- WeBWorK's editor is not monospaced, so the right border       -->
<!-- looks ragged.  We effectively rubout the right margin,        -->
<!-- then translate all asterisks to octothorpes.  The left margin -->
<!-- becomes three octothorpes to not be confused with metadata    -->
<!-- This can revert to  -perl  if the editor changes              -->
<xsl:template name="converter-blurb-webwork">
    <xsl:variable name="blurb">
        <xsl:call-template name="converter-blurb">
            <xsl:with-param name="lead-in"  select="'##'" />
            <xsl:with-param name="lead-out" select="'XXX'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="str:replace(str:replace($blurb, '*XXX', ''), '*', '#')" />
</xsl:template>


</xsl:stylesheet>
