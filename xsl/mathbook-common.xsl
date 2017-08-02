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
<!-- HTML-specific deprecated 2015-06, but still functional -->
<xsl:param name="html.chunk.level" select="''" />
<!-- html.knowl.sidebyside is deprecated 2017-07  -->
<!-- null value necessary for deprecation message -->
<xsl:param name="html.knowl.sidebyside" select="''" />
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
<!-- Now project-like elements, in main text.              -->
<xsl:param name="project.text.statement" select="'yes'" /> <!-- not implemented -->
<xsl:param name="project.text.hint" select="'yes'" />
<xsl:param name="project.text.answer" select="'yes'" />
<xsl:param name="project.text.solution" select="'yes'" />
<!-- And project-like elements, in back matter (none implemented). -->
<xsl:param name="project.backmatter.statement" select="'yes'" />
<xsl:param name="project.backmatter.hint" select="'yes'" />
<xsl:param name="project.backmatter.answer" select="'yes'" />
<xsl:param name="project.backmatter.solution" select="'yes'" />
<!-- Author tools are for drafts, mostly "todo" items                 -->
<!-- and "provisional" citations and cross-references                 -->
<!-- Default is to hide todo's, inline provisionals                   -->
<!-- Otherwise ('yes'), todo's in red paragraphs, provisionals in red -->
<xsl:param name="author-tools" select="'no'" />
<!-- The autoname parameter is deprecated (2017-07-25) -->
<!-- Replace with docinfo/cross-references/@text       -->
<xsl:param name="autoname" select="''" />
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
<xsl:strip-space elements="frontmatter chapter appendix index-part index section subsection subsubsection exercises references introduction conclusion paragraphs subparagraph backmatter" />
<xsl:strip-space elements="docinfo author abstract" />
<xsl:strip-space elements="titlepage preface acknowledgement biography foreword dedication colophon" />
<!-- List is elements in DEFINITION-LIKE entity -->
<!-- definition -->
<xsl:strip-space elements="definition" />
<!-- List is elements in THEOREM-LIKE entity                           -->
<!-- theorem|corollary|lemma|algorithm|proposition|claim|fact|identity -->
<xsl:strip-space elements="theorem corollary lemma algorithm proposition claim fact identity" />
<xsl:strip-space elements="statement" />
<xsl:strip-space elements="proof case" />
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
<xsl:strip-space elements="ul ol dl" />
<xsl:strip-space elements="md mdn" />
<xsl:strip-space elements="sage figure table listing index" />
<xsl:strip-space elements="sidebyside paragraphs" />
<xsl:strip-space elements="tabular col row" />
<xsl:strip-space elements="webwork setup" />

<!-- A few basic elements are explicitly mixed-content -->
<!-- So we must preserve whitespace-only text nodes    -->
<!-- Example: a space between two marked-up words      -->
<!--                                                   -->
<!--         <em>two</em> <alert>ducks</alert>         -->
<!--                                                   -->
<!-- Describes source expectations, DO NOT             -->
<!-- override in subsequent stylesheets                -->
<xsl:preserve-space elements="p li" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- The latex processing model is overridden in       -->
<!-- imported files, per output format. Any stylesheet -->
<!-- importing this one, should define this            -->
<!-- The purpose is to identify variations in how      -->
<!-- text nodes are manipulated, such as clause-ending -->
<!-- punctuation that has migrated into inline math    -->
<!-- Values are: 'native' and 'mathjax'                -->
<!-- We set the default to 'mathjax' (assistive), and  -->
<!-- then override just in the LaTeX conversion        -->
<!-- Note: this device might be abandoned if browsers  -->
<!-- and MathJax ever cooperate on placing line breaks -->
<!-- TODO: could rename as "inline-math-punctation-absorption" -->
<xsl:variable name="latex-processing" select="'mathjax'" />

<!-- We set this variable a bit differently -->
<!-- for different conversions, so this is  -->
<!-- basically an abstract implementation   -->
<xsl:variable name="chunk-level">
    <xsl:text>0</xsl:text>
</xsl:variable>

<!-- Flag Table of Contents, or not, with boolean variable -->
<xsl:variable name="b-has-toc" select="$toc-level != 0" />

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

<!-- The main "mathbook" element only has two possible children     -->
<!-- One is "docinfo", the other is "book", "article", etc.         -->
<!-- This is of interest by itself, or the root of content searches -->
<!-- And docinfo is the other child                                 -->
<!-- These help prevent searching the wrong half                    -->
<xsl:variable name="document-root" select="/mathbook/*[not(self::docinfo)]" />
<xsl:variable name="docinfo" select="/mathbook/docinfo" />

<!-- Source Analysis -->
<!-- Some boolean variables ("b-*") for -->
<!-- the presence of certain elements -->
<xsl:variable name="b-has-jsxgraph" select="boolean($document-root//jsxgraph)" />


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

<!-- Prior to January 2017 we treated all whitespace as -->
<!-- significant in mixed-content nodes.  With changes  -->
<!-- in this policy we preserve the option to process   -->
<!-- in this older style.  This could avoid frequent    -->
<!-- applications of low-level text-processing routines -->
<!-- and perhaps speed up processing.  Switch here      -->
<!-- controls possible whitespace modes.                -->
<xsl:param name="whitespace" select="'flexible'" />
<xsl:variable name="whitespace-style">
    <xsl:choose>
        <xsl:when test="$whitespace='strict' or $whitespace='flexible'">
            <xsl:value-of select="$whitespace" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="yes">
                <xsl:text>MBX:ERROR: the whitespace parameter can be 'strict' or 'flexible', not '</xsl:text>
                <xsl:value-of select="$whitespace" />
                <xsl:text>'</xsl:text>
            </xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- We preserve action of the "autoname" parameter         -->
<!-- But originally the default was "no", and now is        -->
<!-- equivalent to "yes".  We set to blank on creation,     -->
<!-- so we can see if there is command-line action          -->
<!-- There is a warning that the default behavior has       -->
<!-- changed, and a warning that setting this is deprecated -->
<!-- (Deprecation 2017-07-25) -->
<xsl:variable name="legacy-autoname">
    <xsl:choose>
        <!-- nothing on command-line, nothing in docinfo    -->
        <!-- then this is what will be used globally        -->
        <!-- so preserve this behavior when this is removed -->
        <xsl:when test="$autoname = ''">
            <xsl:text>unset</xsl:text>
        </xsl:when>
        <!-- legacy had zero error-checking -->
        <xsl:otherwise>
            <xsl:value-of select="$autoname" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Employing variants of the text displayed for a cross-reference -->
<!-- affects the words shown to the reader, and hence is a choice   -->
<!-- preserved in the source, and is not just a processing decision -->
<!-- $xref-text-style is the global choice, based on                -->
<!--   docinfo/cross-references/@text                               -->
<!-- We control the possible values with the schema, allowing junk  -->
<!-- NB: blank is not set, and is ignored so the legacy-autoname    -->
<!-- scheme controls the global default.  When that goes away, we   -->
<!-- should set the default here when there is no attribute.        -->
<xsl:variable name="xref-text-style">
    <xsl:choose>
        <xsl:when test="$docinfo/cross-references/@text">
            <xsl:value-of select="$docinfo/cross-references/@text" />
        </xsl:when>
        <xsl:otherwise>
            <text />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>


<!-- Sometimes  xsltproc fails, and fails spectacularly,        -->
<!-- setting this switch will dump lots of location info to the -->
<!-- console, and perhaps will be helpful in locating a failure -->
<!-- You might redirect stderror to a file with "2> errors.txt" -->
<!-- appended to your command line                              -->
<xsl:param name="debug" select="'no'" />
<xsl:variable name="b-debug" select="$debug = 'yes'" />

<xsl:param name="debug.datedfiles" select="'yes'" />
<xsl:variable name="b-debug-datedfiles" select="not($debug.datedfiles = 'no')" />

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

<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Mathematics authored in LaTeX syntax will be        -->
<!-- independent of output format.  Despite MathJax's    -->
<!-- broad array of capabilities, there are enough       -->
<!-- differences that it is easier to maintain separate  -->
<!-- routines for different outputs.  Still, we try to   -->
<!-- isolate some routines in "xsl/mathbook-common.xsl". -->

<!-- Certain options and variants are common in both     -->
<!-- cases, so we provide templates for those decisions  -->
<!-- Elsewhere are low-level manipulation of whitespace  -->
<!-- in processed version of  LaTeX output               -->

<!-- Always an "equation" for an me-variant -->
<!-- The equation* is AMS-Math-specific,    -->
<!-- "displaymath" is base-LaTeX equivalent -->
<xsl:template match="me" mode="displaymath-alignment">
    <xsl:text>equation*</xsl:text>
</xsl:template>

<xsl:template match="men" mode="displaymath-alignment">
    <xsl:text>equation</xsl:text>
</xsl:template>

<!-- We sniff around for ampersands, to decide between "align"    -->
<!-- and "gather", plus an asterisk for the unnumbered version    -->
<!-- Note: this is overridden for LaTeX to make slightly          -->
<!-- cleaner output for the *-version (no numbering)              -->
<!-- User intervention is necessary/desired in some situations,   -->
<!-- such as a LaTeX macro hiding &amp;, \amp, or spacing control -->
<!-- @alignment = align|gather|alignat as a specific override     -->
<xsl:template match="md|mdn" mode="displaymath-alignment">
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
        <xsl:when test="@alignment">
            <xsl:message>MBX:ERROR: display math @alignment attribute "<xsl:value-of select="@alignment" />" is not recognized (should be "align", "gather", "alignat")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <!-- sniff for alignment specifications    -->
        <!-- this can be easily fooled, eg matrices-->
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

<!-- Recurse through "mrow"s of a presumed "md" or "mdn" -->
<!-- counting ampersands and tracking the maximum        -->
<xsl:template match="mrow" mode="max-ampersands">
    <xsl:param name="max" select="0"/>
    <!-- build string/text content -->
    <xsl:variable name="row-content">
        <xsl:for-each select="text()">
            <xsl:value-of select="." />
        </xsl:for-each>
    </xsl:variable>
    <!-- count row's ampersands -->
    <xsl:variable name="ampersands">
        <xsl:call-template name="count-ampersands">
            <xsl:with-param name="text" select="$row-content" />
        </xsl:call-template>
    </xsl:variable>
    <!-- recalculate maximum -->
    <xsl:variable name="new-max">
        <xsl:choose>
            <xsl:when test="$ampersands > $max">
                <xsl:value-of select="$ampersands" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$max" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- recurse or report -->
    <xsl:variable name="following-mrows" select="following-sibling::mrow" />
    <xsl:choose>
        <xsl:when test="$following-mrows">
            <xsl:apply-templates select="$following-mrows[1]" mode="max-ampersands">
                <xsl:with-param name="max" select="$new-max" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$new-max" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- With alignment="alignat" we need the number of columns     -->
<!-- as an argument, complete with the LaTeX group (braces)     -->
<!-- Mostly we call this regularly, and it usually does nothing -->
<xsl:template match="me|men|md|mdn" mode="alignat-columns" />

<xsl:template match="md[@alignment='alignat']|mdn[@alignment='alignat']" mode="alignat-columns">
    <xsl:variable name="number-equation-columns">
        <xsl:choose>
            <!-- override first -->
            <xsl:when test="@alignat-columns">
                <xsl:value-of select="@alignat-columns" />
            </xsl:when>
            <!-- count ampersands, compute columns -->
            <xsl:otherwise>
                <xsl:variable name="number-ampersands">
                    <xsl:apply-templates select="mrow[1]" mode="max-ampersands" />
                </xsl:variable>
                <!-- amps + 1, divide by 2, round up; 0.5 becomes 0.25, round behaves -->
                <xsl:value-of select="round(($number-ampersands + 1.5) div 2)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$number-equation-columns" />
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- ############## -->
<!-- LaTeX Preamble -->
<!-- ############## -->

<!-- We round up any author-supplied packages as   -->
<!-- a big string, in LaTeX syntax.  It will need  -->
<!-- manipulation to be usable on the MathJax side -->
<xsl:variable name="latex-packages">
    <xsl:for-each select="/mathbook/docinfo/latex-preamble/package">
        <xsl:text>\usepackage{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
    </xsl:for-each>
</xsl:variable>

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
    <xsl:text>\newcommand{\lt}{&lt;}&#xa;</xsl:text>
    <xsl:text>\newcommand{\gt}{&gt;}&#xa;</xsl:text>
    <xsl:text>\newcommand{\amp}{&amp;}&#xa;</xsl:text>
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
        <xsl:with-param name="internal-id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:with-param>
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
        <xsl:with-param name="internal-id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:with-param>
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="'practice'" />
        </xsl:with-param>
        <xsl:with-param name="in" select="'# Practice area (not linked for Sage Cell use)&#xa;'"/>
        <xsl:with-param name="out" select="''" />
    </xsl:call-template>
</xsl:template>

<!-- Type: "copy"; used for replays     -->
<!-- Mostly when HTML is chunked        -->
<!-- Just handle the same way as others -->
<!-- TODO: HTML copies will get same id! -->
<xsl:template match="sage[@copy]">
    <xsl:apply-templates select="id(@copy)" />
</xsl:template>

<!-- Type: "display"; input portion as uneditable, unevaluatable -->
<!-- This calls a slightly different abstract template           -->
<!-- We do not pass along any output, since this is silly        -->
<!-- These cells are meant to be be incorrect or incomplete      -->
<xsl:template match="sage[@type='display']">
    <xsl:call-template name="sage-display-markup">
        <xsl:with-param name="internal-id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:with-param>
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
        <xsl:with-param name="internal-id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:with-param>
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
    <xsl:value-of select="." />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

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
<!-- space, tab, carriage return, newline        -->
<xsl:variable name="blanks">
    <xsl:text>&#x20;&#x9;</xsl:text>
</xsl:variable>
<!-- Punctuation ending a clause of a sentence   -->
<!-- Asymmetric: no space, mark, space           -->
<xsl:variable name="clause-ending-marks">
    <xsl:text>.?!:;,</xsl:text>
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
<!-- Note: mathbook-webwork-pg has a template with the same name   -->
<!-- and mathbook-webwork-pg is included in both mathbook-html and -->
<!-- mathbook-webwork-archive subsequent to importing              -->
<!-- mathbook-common. Therefore if this template is developed to   -->
<!-- be used more, it should be reconciled with the version in     -->
<!-- mathbook-webwork-pg.                                          -->
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
<!-- Drop consecutive leading spaces and tabs           -->
<!-- Designed for a single line as input                -->
<!-- Used after maniplating sentence ending punctuation -->
<xsl:template name="strip-leading-blanks">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- if empty, done -->
        <xsl:when test="not($first-char)" />
        <!-- first character is space, tab, drop it -->
        <xsl:when test="contains($blanks, $first-char)">
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

<!-- ################## -->
<!-- LaTeX Shortcomings -->
<!-- ################## -->

<!-- Math bits are authored in LaTeX syntax, -->
<!-- but sometimes LaTeX needs a little help -->
<!-- to do the right thing.  This help is    -->
<!-- often common to several output formats, -->
<!-- so we put these modal templates here.   -->

<!-- Clauses ending with math -->
<!-- We look for an immediately adjacent/subsequent text -->
<!-- node and if we get any punctuation, we wrap it for  -->
<!-- inclusion in the final throes of the math part      -->
<!-- See compensating code below for general text        -->
<xsl:template match="m|me|men|md|mdn" mode="get-clause-punctuation">
    <xsl:variable name="trailing-text" select="following-sibling::node()[1]/self::text()" />
    <xsl:variable name="punctuation">
        <xsl:call-template name="leading-clause-punctuation">
            <xsl:with-param name="text" select="$trailing-text" />
        </xsl:call-template>
    </xsl:variable>
    <!-- unclear why  test="$punctuation"  tests true always here -->
    <xsl:if test="not($punctuation='')">
        <xsl:text>\text{</xsl:text>
        <xsl:value-of select="$punctuation" />
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- QED Here -->
<!-- Analyze a final "mrow" or any "me"                            -->
<!-- Strictly LaTeX/amsthm, not a MathJax feature (yet? ever?)     -->
<!--   (1) Locate enclosing proof, quit if no such thing           -->
<!--   (2) Check an mrow for being numbered, do not clobber that   -->
<!--   (3) Locate all trailing element, text nodes                 -->
<!--       strip-space: between "mrow" and "md" or "mdn"           -->
<!--       strip-space: between final "p" and "proof"              -->
<!--   (4) Form nodes interior to proof, and trailing ("remnants") -->
<!--   (5) At very end of proof                                    -->
<!--      (a) if no more nodes, or                                 -->
<!--      (b) one node, totally whitespace and punctuation         -->
<!--          (we don't differentiate whitespace policy here)      -->
<!--   (6) Having survived all this write a \qedhere               -->
<!-- TODO: \qedhere also functions at the end of a list            -->
<xsl:template match="mrow|me" mode="qed-here">
    <!-- <xsl:message>here</xsl:message> -->
    <xsl:variable name="enclosing-proof" select="ancestor::proof" />
    <xsl:if test="$enclosing-proof and not(self::mrow and parent::md and @number='yes') and not(self::mrow and parent::mdn and not(@number='no'))">
        <xsl:variable name="proof-nodes" select="$enclosing-proof/descendant-or-self::node()[self::* or self::text()]" />
        <xsl:variable name="trailing-nodes" select="./following::node()[self::* or self::text()]" />
        <xsl:variable name="proof-remnants" select="$proof-nodes[count(.|$trailing-nodes) = count($trailing-nodes)]" />
        <xsl:choose>
            <xsl:when test="count($proof-remnants) = 0">
                <xsl:text>\qedhere</xsl:text>
            </xsl:when>
            <xsl:when test="(count($proof-remnants) = 1) and (translate(normalize-space($proof-remnants), $clause-ending-marks, '') = '')">
                <xsl:text>\qedhere</xsl:text>
            </xsl:when>
            <xsl:otherwise />
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- ################################## -->
<!-- General Text Handling and Clean-Up -->
<!-- ################################## -->

<!-- Debugging information is not documented, nor supported -->
<!-- Only outputs on a change                               -->
<xsl:param name="ws.debug" select="'no'" />
<xsl:variable name="wsdebug" select="boolean($ws.debug = 'yes')" />

<!-- Text adjustments -->
<!-- This is a general template for every text node.   -->
<!-- We are first using it to adjust for clause-ending -->
<!-- punctuation being absorbed elsewhere into math,   -->
<!-- so we place this near math handling.              -->
<xsl:template match="text()">
    <!-- Scrub clause-ending punctuation immediately after math  -->
    <!-- It migrates and is absorbed in math templates elsewhere -->
    <!-- Side-effect: resulting leading whitespace is scrubbed   -->
    <!-- for displayed mathematics (only) as it is irrelevant    -->
    <!-- Inline math only adjusted for MathJax processing        -->
    <xsl:variable name="first-char" select="substring(., 1, 1)" />
    <xsl:variable name="math-punctuation">
        <xsl:choose>
            <!-- always adjust display math punctuation -->
            <xsl:when test="contains($clause-ending-marks, $first-char) and preceding-sibling::node()[1][self::me or self::men or self::md or self::mdn]">
                <xsl:call-template name="strip-leading-whitespace">
                    <xsl:with-param name="text">
                        <xsl:call-template name="drop-clause-punctuation">
                            <xsl:with-param name="text" select="." />
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <!-- adjust inline math, except for real LaTeX -->
            <xsl:when test="contains($clause-ending-marks, $first-char) and preceding-sibling::node()[1][self::m] and not($latex-processing='native')">
                <xsl:call-template name="drop-clause-punctuation">
                    <xsl:with-param name="text" select="." />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="." />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- TODO: strip leading whitespace above only under  -->
    <!-- 'strict' policy, and combine two when clauses.   -->
    <!-- Below, strip leading and trailing whitespace on  -->
    <!-- either side of displayed objects, math and lists -->
    <!-- (only?), in addition to first and last nodes     -->
    <xsl:choose>
        <!-- pass through if a node within "webwork-tex" -->
        <xsl:when test="ancestor::webwork-tex">
            <xsl:value-of select="$math-punctuation" />
        </xsl:when>
        <!-- pass through if assuming strict adherence to whitespace policy -->
        <xsl:when test="$whitespace='strict'">
            <xsl:value-of select="$math-punctuation" />
        </xsl:when>
        <!-- We must "apply-templates" to math bits in order    -->
        <!-- to process "var", "fillin" and "xref", so we pass  -->
        <!-- through neighboring text nodes under any policy    -->
        <!-- and we handle whitespace specially afterward       -->
        <xsl:when test="parent::*[self::m or self::me or self::men or self::mrow]">
            <xsl:value-of select="$math-punctuation" />
        </xsl:when>
        <!-- manipulate leading, trailing, intermediate whitespace under flexible policy -->
        <!-- if only text node inside parent, all three transformations may apply        -->
        <!-- Note: space after clause-punctuation will not be deleted here               -->
        <xsl:when test="$whitespace='flexible'">
            <xsl:variable name="original" select="$math-punctuation" />
            <xsl:variable name="front-cleaned">
                <xsl:choose>
                    <xsl:when test="not(preceding-sibling::node()[self::* or self::text()]) or preceding-sibling::node()[self::* or self::text()][1][self::me or self::men or self::md or self::mdn or self::cd or self::pre]">
                        <xsl:call-template name="strip-leading-whitespace">
                            <xsl:with-param name="text" select="$original" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$original" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="back-cleaned">
                <xsl:choose>
                    <xsl:when test="not(following-sibling::node()[self::* or self::text()])  or following-sibling::node()[self::* or self::text()][1][self::me or self::men or self::md or self::mdn or self::cd or self::pre]">
                        <xsl:call-template name="strip-trailing-whitespace">
                            <xsl:with-param name="text" select="$front-cleaned" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$front-cleaned" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="middle-cleaned">
                <xsl:call-template name="strip-newlines">
                    <xsl:with-param name="text" select="$back-cleaned" />
                </xsl:call-template>
            </xsl:variable>
            <!-- ACTUAL output -->
            <xsl:value-of select="$middle-cleaned" />
            <xsl:if test="$wsdebug and not($math-punctuation = $middle-cleaned)">
                <!-- DEBUGGING follows, maybe move outward later -->
                <xsl:message>
                    <xsl:text>****&#xa;</xsl:text>
                    <xsl:text>O:</xsl:text>
                    <xsl:value-of select="." />
                    <xsl:text>:O&#xa;</xsl:text>
                    <xsl:text>M:</xsl:text>
                    <xsl:value-of select="$math-punctuation" />
                    <xsl:text>:M&#xa;</xsl:text>
                    <xsl:text>F:</xsl:text>
                    <xsl:value-of select="$front-cleaned" />
                    <xsl:text>:F&#xa;</xsl:text>
                    <xsl:text>B:</xsl:text>
                    <xsl:value-of select="$back-cleaned" />
                    <xsl:text>:B&#xa;</xsl:text>
                    <xsl:text>M:</xsl:text>
                    <xsl:value-of select="$middle-cleaned" />
                    <xsl:text>:M&#xa;</xsl:text>
                    <xsl:text>****&#xa;</xsl:text>
                </xsl:message>
            </xsl:if>
        </xsl:when>
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
<!-- NB: we don't point to a sidebyside, so not included here        -->
<xsl:template match="md|mdn|ul|ol|dl|blockquote|pre|sage|&FIGURE-LIKE;|poem|program|image|tabular|paragraphs|&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|list|exercise|li" mode="is-block">
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
            <!-- Very informative output for debugging purposes, comment/uncomment, but do not remove  -->
            <!-- <xsl:message>CHUNK: <xsl:apply-templates select="." mode="long-name" /></xsl:message> -->
            <xsl:apply-templates select="." mode="chunk" />
        </xsl:when>
        <xsl:otherwise>
            <!-- Very informative output for debugging purposes, comment/uncomment, but do not remove  -->
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
            <!-- DEPRECATION: May 2015, ignore silently here, warning in -common -->
            <!-- could replace with terminate=yes if present without an xml:id   -->
            <xsl:if test="@filebase" />
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
<xsl:template match="frontmatter|colophon|preface|foreword|acknowledgement|dedication|biography|references|exercises|backmatter|index-part|index[index-list]" mode="has-default-title">
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


<!-- ################ -->
<!-- Copies of Images -->
<!-- ################ -->

<xsl:template match="image[@copy]">
    <xsl:variable name="target" select="id(@copy)" />
    <xsl:choose>
        <xsl:when test="$target">
            <xsl:apply-templates select="$target" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: &lt;image&gt; failure due to unknown reference @copy="<xsl:value-of select="@copy"/>"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############################# -->
<!-- Widths of Images, Videos, Etc -->
<!-- ############################# -->

<xsl:template match="image|video|jsxgraph" mode="image-width">
    <xsl:param name="width-override" select="''" />
    <!-- every (?) image comes here for width              -->
    <!-- test for author-provided poorly-constructed width -->
    <xsl:if test="@width">
        <xsl:variable name="improved-width" select="normalize-space(@width)" />
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

<!-- Assumes element may have an @aspect attribute   -->
<!-- Form:  "width:height" or decimal width/height   -->
<!-- Return: real number, unitless for use by caller -->
<!-- Totally blank means caller supplies default     -->
<!-- TODO: add for video, not for image (warn?) -->
<xsl:template match="jsxgraph" mode="aspect-ratio">
    <xsl:choose>
        <xsl:when test="not(@aspect)" />
        <xsl:when test="contains(@aspect, ':')">
            <xsl:variable name="width" select="substring-before(@aspect, ':')" />
            <xsl:variable name="height" select="substring-after(@aspect, ':')" />
            <xsl:value-of select="$width div $height" />
        </xsl:when>
        <!-- NaN does not equal *anything*, so tests if a number -->
        <!-- http://stackoverflow.com/questions/6895870          -->
        <xsl:when test="(number(@aspect)=number(@aspect)) and (@aspect > 0)">
            <xsl:value-of select="@aspect" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: the @aspect attribute should be a ratio, like 4:3, or a positive number, not "<xsl:value-of select="@aspect" />"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
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

<!-- a single objective is authored as a list item -->
<xsl:template match="objectives/ol/li|objectives/ul/li|objectives/dl/li" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'objective'" />
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

<!-- Check once if "index" is available -->
<!-- for use on the root element        -->
<xsl:variable name="b-index-is-available" select="not(//@xml:id[.='index'])" />

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

<!-- Override for document root node,          -->
<!-- slide in "index" as preferential default, -->
<!-- presuming it is not in use anywhere else  -->
<xsl:template match="/mathbook/*[not(self::docinfo)]" mode="internal-id">
    <xsl:choose>
        <xsl:when test="@xml:id">
            <xsl:value-of select="@xml:id" />
        </xsl:when>
        <xsl:when test="$b-index-is-available">
            <xsl:text>index</xsl:text>
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

<!-- Note on tables and figures:                      -->
<!-- If these live in "sidebyside", which is in       -->
<!-- turn contained in a "figure", then they will     -->
<!-- earn a subcaption with a subnumber, so we ignore -->
<!-- them in these counts of top-level numbered items -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise|&FIGURE-LIKE;" mode="serial-number">
    <xsl:variable name="subtree-level">
        <xsl:apply-templates select="." mode="absolute-subtree-level">
            <xsl:with-param name="numbering-items" select="$numbering-theorems" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1"><xsl:number from="book|article|letter|memo" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" /></xsl:when>
        <xsl:when test="$subtree-level=0"><xsl:number from="part" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|" /></xsl:when>
        <xsl:when test="$subtree-level=1"><xsl:number from="chapter|book/backmatter/appendix" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" /></xsl:when>
        <xsl:when test="$subtree-level=2"><xsl:number from="section|article/backmatter/appendix" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" /></xsl:when>
        <xsl:when test="$subtree-level=3"><xsl:number from="subsection" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" /></xsl:when>
        <xsl:when test="$subtree-level=4"><xsl:number from="subsubsection" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise[not(ancestor::exercises)]|figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" /></xsl:when>
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
        <xsl:when test="$subtree-level=1"><xsl:number from="chapter|book/backmatter/appendix" level="any" count="&PROJECT-LIKE;" /></xsl:when>
        <xsl:when test="$subtree-level=2"><xsl:number from="section|article/backmatter/appendix" level="any" count="&PROJECT-LIKE;" /></xsl:when>
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
        <xsl:when test="$subtree-level=1"><xsl:number from="chapter|book/backmatter/appendix" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
        <xsl:when test="$subtree-level=2"><xsl:number from="section|article/backmatter/appendix" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no')]"/></xsl:when>
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
        <xsl:when test="$subtree-level=1"><xsl:number from="chapter|book/backmatter/appendix" level="any" count="fn" /></xsl:when>
        <xsl:when test="$subtree-level=2"><xsl:number from="section|article/backmatter/appendix" level="any" count="fn" /></xsl:when>
        <xsl:when test="$subtree-level=3"><xsl:number from="subsection" level="any" count="fn" /></xsl:when>
        <xsl:when test="$subtree-level=4"><xsl:number from="subsubsection" level="any" count="fn" /></xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for footnote number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Subfigures, Subtables, Sublisting-->
<!-- Subcaptioning only happens with figures           -->
<!-- or tables arranged in a sidebyside, which         -->
<!-- is again contained inside a figure, the           -->
<!-- element providing the overall caption             -->
<!-- The serial number is a sub-number, (a), (b), (c), -->
<!-- *Always* with the parenthetical formatting        -->


<!-- In this case the structure number is the          -->
<!-- full number of the enclosing figure               -->

<!-- a lone sidebyside, not in a sbsgroup -->
<xsl:template match="figure/sidebyside/figure | figure/sidebyside/table | figure/sidebyside/listing" mode="serial-number">
    <xsl:text>(</xsl:text>
    <xsl:number format="a" count="figure|table|listing"/>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- when inside a sbsgroup, subcaptions range across entire group -->
<xsl:template match="figure/sbsgroup/sidebyside/figure | figure/sbsgroup/sidebyside/table | figure/sbsgroup/sidebyside/listing" mode="serial-number">
    <xsl:text>(</xsl:text>
    <xsl:number format="a" count="figure|table|listing" level="any" from="sbsgroup"/>
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


<!-- Serial Numbers: Exercise Groups -->
<!-- We provide the range of the     -->
<!-- group as its serial number.     -->
<xsl:template match="exercisegroup" mode="serial-number">
    <xsl:apply-templates select="exercise[1]" mode="serial-number" />
    <xsl:apply-templates select="." mode="ndash"/>
    <xsl:apply-templates select="exercise[last()]" mode="serial-number" />
</xsl:template>


<!-- Serial Numbers: the unnumbered     -->
<!-- Empty string signifies not numbered -->

<!-- We choose not to number unique, or semi-unique      -->
<!-- (eg prefaces, colophons), elements.  Other elements -->
<!-- are meant as local commentary, and may also carry   -->
<!-- a title for identification and cross-referencing.   -->
<xsl:template match="book|article|letter|memo|paragraphs|blockquote|preface|abstract|acknowledgement|biography|foreword|dedication|index-part|index[index-list]|colophon|webwork|p|assemblage|aside|biographical|historical|case|contributor" mode="serial-number" />

<!-- Some items are "containers".  They are not numbered, you  -->
<!-- cannot point to them, they are invisible to the reader    -->
<!-- in a way.  We kill their serial nuumbers explicitly here. -->
<!-- Lists live in paragraphs, exercises, objectives, so       -->
<!-- should be referenced as part of some enclosing element.   -->
<!-- "mathbook" helps some tree-climbing routines halt -->
<xsl:template match="mathbook|introduction|conclusion|frontmatter|backmatter|sidebyside|ol|ul|dl|statement" mode="serial-number" />

<!-- If a list item has any ancestor that is not  -->
<!-- an ordered list, then it gets no number      -->
<xsl:template match="ul//li|dl//li" mode="serial-number" />

<!-- References in the backmatter are the "master" version -->
<!-- The subdivision gets no number and the references     -->
<!-- should similarly lack a structural number prefix      -->
<xsl:template match="backmatter/references" mode="serial-number" />

<!-- WeBWorK problems are never numbered, because they live    -->
<!-- in (numbered) exercises.  But they have identically named -->
<!-- components of exercises, so we might need to explicitly   -->
<!-- make webwork/solution, etc to be unnumbered.              -->

<!-- Objectives are one-per-subdivision, and so -->
<!-- get their serial number from their parent  -->
<xsl:template match="objectives" mode="serial-number">
    <xsl:apply-templates select="parent::*" mode="serial-number" />
</xsl:template>

<!-- Multi-part WeBWorK problems have MBX elements        -->
<!-- called "stage" which typically render as "Part..."   -->
<!-- Their serial numbers are useful, there is no attempt -->
<!-- above to integrate these into our general scheme     -->
<!-- These are just counted among enclosing "webwork"     -->
<xsl:template match="stage" mode="serial-number">
        <xsl:number count="stage" from="webwork" />
</xsl:template>

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
<!-- NB: *every* structure number should finish with  -->
<!-- a period as a separator, which is often provided -->
<!-- by the "multi-number" template.  Some of the     -->
<!-- cross-reference text code adds a period before   -->
<!-- testing equality of strings                      -->

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
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&EXAMPLE-LIKE;|list|exercise|&FIGURE-LIKE;" mode="structure-number">
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
<!-- Captioned items, arranged in a side-by-side,  -->
<!-- then inside a captioned figure, earn a serial -->
<!-- number that is a letter.  So their structure  -->
<!-- number comes from their grandparent figure    -->
<xsl:template match="figure/sidebyside/figure | figure/sidebyside/table | figure/sidebyside/listing" mode="structure-number">
    <xsl:apply-templates select="parent::sidebyside/parent::figure" mode="number" />
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

<!-- Structure Numbers: Exercise Groups -->
<!-- An exercisegroup gets it structure number from the parent exercises -->
<xsl:template match="exercisegroup" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- Structure Numbers: Objectives -->
<!-- Objectives are one-per-subdivision, and so   -->
<!-- get their structure number from their parent -->
<xsl:template match="objectives" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="structure-number" />
</xsl:template>

<!-- Structure Numbers: Objective -->
<!-- A single objective is a list item -->
<!-- in an objectives environment       -->
<xsl:template match="objectives/ol/li" mode="structure-number">
    <xsl:apply-templates select="ancestor::*[&STRUCTURAL-FILTER;][1]" mode="number" />
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

<!-- Horizontal layouts of "panels" with vertical alignments      -->
<!-- A container for layout of other elements, eg figures, images -->
<!-- No notion of columns, no rules or dividers, no row headings  -->
<!-- This is purely a container to specify layout parameters,     -->
<!-- and place/control the horizontal arrangement in converters   -->

<!-- Debugging information is not documented, nor supported     -->
<!-- Colored boxes in HTML, black boxes in LaTeX with baselines -->
<xsl:param name="sbs.debug" select="'no'" />
<xsl:variable name="sbsdebug" select="boolean($sbs.debug = 'yes')" />

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
<!--  - "auto" => margins are half the space between panels -->
<!--  - default is "auto"                                   -->
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
<!-- Default behavior is automatic margins, no spacing      -->
<!-- between panels and equally wide panels.                -->
<!--                                                        -->
<!-- With widths specified, remaining space is              -->
<!-- used to create equal spacing between panels            -->

<!-- Extensive layout analysis first, main templates follow -->

<!-- We analyze the attributes of a "sidebyside" element -->
<!-- in order to extract/compute the layout parameters   -->
<!-- This template creates a RTF (result tree fragment), -->
<!-- which needs to be captured in one variable, then    -->
<!-- converted to a node-set with an extension function  -->
<xsl:template match="sidebyside" mode="layout-parameters">

    <!-- Number of Panels -->
    <!-- count the elements destined for panels  -->
    <!-- Metadata banned, roughly 2017-07, now pure container  -->
    <!-- Retain filter for backward compatibility              -->
    <xsl:variable name="number-panels" select="count(*[not(&METADATA-FILTER;)])" />
    <xsl:if test="$sbsdebug">
        <xsl:message>N:<xsl:value-of select="$number-panels" />:N</xsl:message>
    </xsl:if>
    <!-- Add to RTF -->
    <number-panels>
        <xsl:value-of select="$number-panels" />
    </number-panels>

    <!-- Vertical Alignments of Panels -->
    <!-- Produce temporary space-separated list, with trailing space     -->
    <!-- Look up into enclosing "sbsgroup" if none given on "sidebyside" -->
    <!-- Error-check attribute values as $valigns string gets unpacked   -->
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
            <!-- look to enclosing sbsgroup -->
            <xsl:when test="parent::sbsgroup[@valigns]">
                <xsl:value-of select="concat(normalize-space(parent::sbsgroup/@valigns), ' ')" />
            </xsl:when>
            <!-- look to enclosing sbsgroup for singular convenience -->
            <xsl:when test="parent::sbsgroup[@valign]">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(parent::sbsgroup/@valign), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- default: place all panels at the top   -->
            <!-- NB: space at end of $text is separator -->
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
    <!-- check length (author-supplied could be wrong) -->
    <xsl:variable name="nspaces-valigns" select="string-length($valigns) - string-length(translate($valigns, ' ', ''))" />
    <xsl:choose>
        <xsl:when test="$nspaces-valigns &lt; $number-panels">
            <xsl:message>MBX:FATAL:   a &lt;sidebyside&gt; or &lt;sbsgroup&gt; does not have enough "@valigns" (maybe you did not specify enough?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <xsl:message terminate="yes">             That's fatal.  Sorry.  Quitting...</xsl:message>
        </xsl:when>
        <xsl:when test="$nspaces-valigns &gt; $number-panels">
            <xsl:message>MBX:WARNING: a &lt;sidebyside&gt; or &lt;sbsgroup&gt; has extra "@valigns" (did you confuse singular and plural attribute names?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
    </xsl:choose>
    <!-- unpack with an error-check on attribute values -->
    <!-- RTF formation happens with unpacking           -->
    <xsl:call-template name="decompose-valigns">
        <xsl:with-param name="valigns" select="$valigns" />
    </xsl:call-template>


    <!-- Margins and Widths -->
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
            <!-- default will make pleasing layout: -->
            <!--   (a) for one panel, no settings -->
            <!--   (b) no margin given, all sensible widths -->
            <xsl:otherwise>
                <xsl:text>auto</xsl:text>
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
            <xsl:when test="$normalized-widths = ' ' and $normalized-margins = 'auto'">
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
    <!-- Add to RTF -->
    <!-- TODO: someday make a "left-margin" and put -->
    <!-- "right-margin" as "gap" after last panel   -->
    <margins>
        <xsl:value-of select="$margin" />
    </margins>

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
    <!-- check length (author-supplied could be wrong) -->
    <xsl:variable name="nspaces-widths" select="string-length($widths) - string-length(translate($widths, ' ', ''))" />
    <xsl:choose>
        <xsl:when test="$nspaces-widths &lt; $number-panels">
            <xsl:message>MBX:FATAL:   a &lt;sidebyside&gt; or &lt;sbsgroup&gt; does not have enough "@widths" (maybe you did not specify enough?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <xsl:message terminate="yes">             That's fatal.  Sorry.  Quitting...</xsl:message>
        </xsl:when>
        <xsl:when test="$nspaces-widths &gt; $number-panels">
            <xsl:message>MBX:WARNING: a &lt;sidebyside&gt; or &lt;sbsgroup&gt; has extra "@widths" (did you confuse singular and plural attribute names?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
    </xsl:choose>
    <!-- unpack with an error-check on attribute values -->
    <!-- RTF formation happens with unpacking           -->
    <xsl:call-template name="decompose-widths">
        <xsl:with-param name="widths" select="$widths" />
    </xsl:call-template>

    <!-- Spacing Between Panels -->
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
    <!-- Add to RTF -->
    <space-width>
        <xsl:value-of select="$space-width" />
    </space-width>
</xsl:template>

<!-- ########################### -->
<!-- SidebySide Layout Utilities -->
<!-- ########################### -->

<!-- From a space-separated list of vertical alignments -->
<!-- create error-checked result tree fragment          -->
<xsl:template name="decompose-valigns">
    <xsl:param name="valigns" />
    <xsl:variable name="the-valign" select="substring-before($valigns, ' ')" />
    <xsl:if test="not($the-valign = '')">
        <!-- error-check, since list bypasses schema -->
        <!-- "top" is default, so check first        -->
        <xsl:choose>
            <xsl:when test="$the-valign = 'top'" />
            <xsl:when test="$the-valign = 'bottom'" />
            <xsl:when test="$the-valign = 'middle'" />
            <xsl:otherwise>
                <xsl:message>MBX:ERROR:   @valign(s) ("<xsl:value-of select="$the-valign" />") in &lt;sidebyside&gt; or &lt;sbsgroup&gt; is not "top," "middle" or "bottom"</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:otherwise>
        </xsl:choose>
        <!-- okay, output element -->
        <valign>
            <xsl:value-of select="$the-valign" />
        </valign>
        <!-- recurse on trailing -->
        <xsl:call-template name="decompose-valigns">
            <xsl:with-param name="valigns" select="substring-after($valigns, ' ')" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- From a space-separated list of widths (percentages) -->
<!-- create error-checked result tree fragment           -->
<xsl:template name="decompose-widths">
    <xsl:param name="widths" />
    <xsl:variable name="the-width" select="substring-before($widths, ' ')" />
    <xsl:if test="not($the-width = '')">
        <!-- error-check, since author-supplied could be wild -->
        <xsl:choose>
            <xsl:when test="substring-before($the-width, '%') &lt; 0">
                <xsl:message>MBX:ERROR:   panel width ("<xsl:value-of select="$the-width" />") in a &lt;sidebyside&gt; or &lt;sbsgroup&gt; is negative (this may be computed, check "@margin(s)" and "@width(s)")</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:when>
            <xsl:when test="substring-before($the-width, '%') &gt; 100">
                <xsl:message>MBX:ERROR:   panel width ("<xsl:value-of select="$the-width" />") in a &lt;sidebyside&gt; or &lt;sbsgroup&gt; is bigger than 100% (this may be computed, check "@margin(s)" and "@width(s)")</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:when>
        </xsl:choose>
        <!-- output element -->
        <width>
            <xsl:value-of select="$the-width" />
        </width>
        <!-- recurse on trailing -->
        <xsl:call-template name="decompose-widths">
            <xsl:with-param name="widths" select="substring-after($widths, ' ')" />
        </xsl:call-template>
    </xsl:if>
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

<!-- ######################## -->
<!-- SideBySide Main Template -->
<!-- ######################## -->

<xsl:template match="sidebyside">
    <xsl:param name="b-original" select="true()" />

    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />

    <!-- local names of objects? -->
    <!-- below useful for debugging, worth keeping for a while, 2017-07 -->
    <!-- 
    <xsl:message>N:<xsl:value-of select="$layout/number-panels" />:N</xsl:message>
    <xsl:message>
        <xsl:text>VA:</xsl:text>
        <xsl:for-each select="$layout/valign">
            <xsl:value-of select="." />
            <xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:text>:VA</xsl:text>
    </xsl:message>
    <xsl:message>
        <xsl:text>W:</xsl:text>
        <xsl:for-each select="$layout/width">
            <xsl:value-of select="." />
            <xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:text>:W</xsl:text>
    </xsl:message>
    <xsl:message>
        <xsl:text>M:</xsl:text>
        <xsl:value-of select="$layout/margins" />
        <xsl:text>:M</xsl:text>
    </xsl:message>
    <xsl:message>
        <xsl:text>SW:</xsl:text>
        <xsl:value-of select="$layout/space-width" />
        <xsl:text>:SW</xsl:text>
    </xsl:message>
    <xsl:message>~~~~~~~~~~~~~~~~~~~~</xsl:message>
     -->

    <!-- Metadata banned, roughly 2017-07, now pure container  -->
    <!-- Retain filter for backward compatibility              -->
     <xsl:variable name="panels" select="*[not(&METADATA-FILTER;)]" />

     <!-- compute necessity of headings (titles) and captions here -->
     <xsl:variable name="has-headings" select="boolean($panels[title])" />
     <xsl:variable name="has-captions" select="boolean($panels[caption])" />
     <xsl:if test="$sbsdebug">
        <xsl:message>HH: <xsl:value-of select="$has-headings" /> :HH</xsl:message>
        <xsl:message>HC: <xsl:value-of select="$has-captions" /> :HC</xsl:message>
        <xsl:message>----</xsl:message>
    </xsl:if>

    <!-- We build up lists of various parts of a panel      -->
    <!-- It has setup (LaTeX), headings (titles), panels,   -->
    <!-- and captions.  These then go to "compose-panels".  -->
    <!-- Implementations need to define modal templates     -->
    <!--   panel-setup, panel-heading,                      -->
    <!--   panel-panel, panel-caption                       -->
    <!-- The parameters passed to each is the union of what -->
    <!-- is needed for LaTeX and HTML implementations.      -->
    <!-- Final results are collectively sent to modal       -->
    <!--   compose-panels                                   -->
    <!-- template to be arranged                            -->
    <!-- TODO: Instead we could pass the $layout to the four,    -->
    <!-- and infer the $panel-number in the receiving templates. -->

    <xsl:variable name="setup">
        <xsl:for-each select="$panels">
            <!-- context is now a particular panel -->
            <xsl:variable name="panel-number" select="count(preceding-sibling::*) + 1" />
            <xsl:apply-templates select="." mode="panel-setup">
                <xsl:with-param name="width" select="$layout/width[$panel-number]" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="headings">
        <xsl:for-each select="$panels">
            <!-- context is now a particular panel -->
            <xsl:variable name="panel-number" select="count(preceding-sibling::*) + 1" />
                <xsl:apply-templates select="." mode="panel-heading">
                    <xsl:with-param name="width" select="$layout/width[$panel-number]" />
                    <xsl:with-param name="margins" select="$layout/margins" />
                </xsl:apply-templates>
        </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="panel-panels">
        <xsl:for-each select="$panels">
            <!-- context is now a particular panel -->
            <xsl:variable name="panel-number" select="count(preceding-sibling::*) + 1" />
            <xsl:apply-templates select="." mode="panel-panel">
                <xsl:with-param name="b-original" select="$b-original" />
                <xsl:with-param name="width" select="$layout/width[$panel-number]" />
                <xsl:with-param name="margins" select="$layout/margins" />
                <xsl:with-param name="valign" select="$layout/valign[$panel-number]" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="captions">
        <xsl:for-each select="$panels">
            <!-- context is now a particular panel -->
            <xsl:variable name="panel-number" select="count(preceding-sibling::*) + 1" />
            <xsl:apply-templates select="." mode="panel-caption">
                <xsl:with-param name="width" select="$layout/width[$panel-number]" />
                <xsl:with-param name="margins" select="$layout/margins" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:variable>

    <!-- now collect components into output wrappers -->
    <xsl:apply-templates select="." mode="compose-panels">
        <xsl:with-param name="b-original" select="$b-original" />

        <xsl:with-param name="layout" select="$layout" />
        <xsl:with-param name="has-headings" select="$has-headings" />
        <xsl:with-param name="has-captions" select="$has-captions" />
        <xsl:with-param name="setup" select="$setup" />
        <xsl:with-param name="headings" select="$headings" />
        <xsl:with-param name="panels" select="$panel-panels" />
        <xsl:with-param name="captions" select="$captions" />
    </xsl:apply-templates>
</xsl:template>

<!-- ########################################### -->
<!-- Side-By-Side Group (sbsgroup) main template -->
<!-- ########################################### -->

<!-- A side-by-side group ("sbsgroup") is a wrapper    -->
<!-- around a sequence of "sidebyside".  It provides   -->
<!-- a place to specify common parameters for several  -->
<!-- side-by-side, for uniformity.  Also sub-captions  -->
<!-- should respect the grouping.  It is as pure a     -->
<!-- container as there can be.  Output is to just     -->
<!-- pile them up vertically.  Note, layout parameters -->
<!-- on enclosed "sidebyside" take precedence, and     -->
<!-- it is the layout template for each sidebyside     -->
<!-- that goes out to the enclosing group to get them  -->

<xsl:template match="sbsgroup">
    <xsl:apply-templates select="sidebyside" />
</xsl:template>


<!-- ############## -->
<!-- List Utilities -->
<!-- ############## -->

<!-- A list item may be:                                        -->
<!--   * unstructured, like a sentence of a "p"                 -->
<!--   * structured into paragraphs, sublists, etc.             -->
<!-- For the first, we cannot automatically strip space         -->
<!-- To be flexible about the second, we kill interstitial text -->
<xsl:template match="li[p|ol|ul|dl]/text()">
    <xsl:variable name="text" select="normalize-space(.)" />
    <xsl:if test="$text">
        <xsl:message>MBX:WARNING: Unstructured content within a list item is being ignored ("<xsl:value-of select="$text" />")</xsl:message>
         <xsl:apply-templates select=".." mode="location-report" />
    </xsl:if>
</xsl:template>

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
                <!-- DEPRECATED 2015-12-12 -->
                <xsl:when test="@label=''" />
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

<!-- CSS class for multi-column lists -->
<!-- Context is element carrying the "cols" attribute   -->
<!-- Value is "colsN" with 2 <= N <= 6                  -->
<!-- Error message of out-of-range, could be made fatal -->
<!-- DTD should enforce this restriction also           -->
<xsl:template match="ol|ul|exercisegroup" mode="number-cols-CSS-class">
    <xsl:choose>
        <xsl:when test="@cols=2 or @cols=3 or @cols=4 or @cols=5 or @cols=6">
            <xsl:text>cols</xsl:text>
            <xsl:value-of select="@cols" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="yes">MBX:ERROR: @cols attribute of lists or exercise groups, must be between 2 and 6 (inclusive), not "cols=<xsl:value-of select="@cols" />"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
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
        <xsl:when test="$align='left' or $align='justify'">
            <xsl:text>l</xsl:text>
        </xsl:when>
        <xsl:when test="$align='center'">
            <xsl:text>c</xsl:text>
        </xsl:when>
        <xsl:when test="$align='right'">
            <xsl:text>r</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular horizontal alignment attribute not recognized: use left, center, right, justify</xsl:message>
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

<!-- The logic of the visible text of a cross-reference is all  -->
<!-- here in the common routines. That text and the target node -->
<!-- is then sent to templates that are output-format-specific. -->

<!-- The actual manufacture of a (active) link is delegated  -->
<!-- to implementations, see abstract (null) implementations -->
<!-- at the end of the "utilities" section below             -->

<!-- Match on:                                       -->
<!--     @ref, no list: the most frequent case       -->
<!--     @ref, a list: mostly for bibliography lists -->
<!--     @first, @last: a range                      -->
<!--     @provisional: author convenience            -->
<!--     remainder: error check                      -->

<!-- Primary case, no separators in @ref -->
<xsl:template match="xref[@ref and not(contains(normalize-space(@ref), ' ')) and  not(contains(normalize-space(@ref), ','))]">
    <!-- sanitize, check, and resolve the reference -->
    <xsl:variable name="ref" select="normalize-space(@ref)" />
    <xsl:apply-templates select="." mode="check-ref">
        <xsl:with-param name="ref" select="$ref" />
    </xsl:apply-templates>
    <xsl:variable name="target" select="id($ref)" />
    <!-- Determine style of visible text in link -->
    <xsl:variable name="text-style">
        <xsl:apply-templates select="." mode="get-text-style" />
    </xsl:variable>
    <!-- if target is a bibliography item, generic -->
    <!-- text template only makes a number, we add -->
    <!-- brackets before link manufacture          -->
    <xsl:variable name="b-is-biblio-target" select="boolean($target/self::biblio)" />
    <!-- form text of the clickable, wrap biblio target -->
    <!-- since xref-text outputs just a number          -->
    <xsl:variable name="text">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:if test="$b-is-biblio-target">
            <xsl:text>[</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="xref-text" >
            <xsl:with-param name="target" select="$target" />
            <xsl:with-param name="text-style" select="$text-style" />
            <!-- pass content as an RTF, test vs. empty string, use copy-of -->
            <xsl:with-param name="custom-text">
                <xsl:apply-templates />
            </xsl:with-param>
        </xsl:apply-templates>
        <!-- a bibliography citation (only) may have extra @detail          -->
        <!-- maybe the detail should migrate to content of a xref to biblio -->
        <xsl:if test="@detail">
            <xsl:choose>
                <xsl:when test="$b-is-biblio-target">
                    <xsl:text>,</xsl:text>
                    <xsl:apply-templates select="." mode="nbsp"/>
                    <!-- this info should not be in an attribute! -->
                    <xsl:apply-templates select="@detail" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:WARNING: &lt;xref @detail="<xsl:value-of select="@detail" />" /&gt; only implemented for single references to &lt;biblio&gt; elements</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="$b-is-biblio-target">
            <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:variable>
    <!-- Send the target and text representation for link to a    -->
    <!-- format-specific and target-specific link manufacture.    -->
    <!-- This depends primarly on the $target, but we also        -->
    <!-- send the location of the link.  Example: a link in       -->
    <!-- display mathematics (rendered by MathJax for HTML)       -->
    <!-- requires radically different constructions as a knowl,   -->
    <!-- or as a hyperlink.  LaTeX barely cares.  We do wrap the  -->
    <!-- xref-text in \text{} for receipt in display mathematics. -->
    <!-- NB: could a xref with title text have math in it and mess-up here? -->
    <xsl:apply-templates select="$target" mode="xref-link">
        <xsl:with-param name="content" select="$text" />
        <xsl:with-param name="xref" select="." />
    </xsl:apply-templates>
</xsl:template>

<!-- A range given by @first, @last            -->
<!-- Makes one chunk of text, linked to @first -->
<!-- Requires same type for targets, since     -->
<!-- type only occurs once in text             -->
<!-- Equations look like (4.2)-(4.8)           -->
<!-- Bibliography looks like [6-14]            -->
<xsl:template match="xref[@first and @last]">
    <!-- sanitize, check, and resolve the two references -->
    <xsl:variable name="ref-one" select="normalize-space(@first)" />
    <xsl:apply-templates select="." mode="check-ref">
        <xsl:with-param name="ref" select="$ref-one" />
    </xsl:apply-templates>
    <xsl:variable name="target-one" select="id($ref-one)" />
    <xsl:variable name="ref-two" select="normalize-space(@last)" />
    <xsl:apply-templates select="." mode="check-ref">
        <xsl:with-param name="ref" select="$ref-two" />
    </xsl:apply-templates>
    <xsl:variable name="target-two" select="id($ref-two)" />
    <!-- Determine style of visible text in link -->
    <xsl:variable name="text-style-one">
        <xsl:apply-templates select="." mode="get-text-style" />
    </xsl:variable>
    <!-- Adjust/set style for end of range          -->
    <!-- Basically supress text manufacture of type -->
    <!-- Also, no content is passed with @last      -->
    <xsl:variable name="text-style-two">
        <xsl:choose>
            <!-- do not replicate type name -->
            <xsl:when test="$text-style-one = 'type-global'">
                <xsl:text>global</xsl:text>
            </xsl:when>
            <xsl:when test="$text-style-one = 'type-local'">
                <xsl:text>local</xsl:text>
            </xsl:when>
            <!-- pass through 'global', 'local', 'title', 'phrase-global' -->
            <xsl:otherwise>
                <xsl:value-of select="$text-style-one" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- enforce @first, @last point to same kind of element, -->
    <!-- since we implicitly recycle the type-name of @first  -->
    <!-- Schematron: possible by inserting id() into XPath test? -->
    <!-- TODO: (2017-07-24) convert to a fatal error after some time? -->
    <xsl:if test="not(local-name($target-one) = local-name($target-two))">
        <xsl:message terminate="no">MBX:ERROR:   &lt;xref @first="<xsl:value-of select="$ref-one" />" @last="<xsl:value-of select="$ref-two" />" /&gt; references two elements with different tags (<xsl:value-of select="local-name($target-one)" /> vs. <xsl:value-of select="local-name($target-two)" />), so are incompatible as endpoints of a range.  Rewrite using two &lt;xref&gt; elements</xsl:message>
    </xsl:if>
    <!-- courtesy check that range is not out-of-order               -->
    <!-- NB: different schemes for "exercise" can make this look odd -->
    <xsl:if test="count($target-one/preceding::*) > count($target-two/preceding::*)">
        <xsl:message terminate="no">MBX:WARNING: &lt;xref @first="<xsl:value-of select="$ref-one" />" @last="<xsl:value-of select="$ref-two" />" /&gt; references two elements that appear to be in the wrong order</xsl:message>
    </xsl:if>
    <!-- Biblio check assumes targets are equal       -->
    <!-- If target is a bibliography item, generic    -->
    <!-- text template only makes numbers, we add     -->
    <!-- brackets and detail before link manufacture  -->
    <!-- Content passes with @first, not with @second -->
    <xsl:variable name="b-is-biblio-target" select="boolean($target-one/self::biblio)" />
    <!-- Compose two text parts with an ndash, perhaps wrappped -->
    <xsl:variable name="text">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:if test="$b-is-biblio-target">
            <xsl:text>[</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="xref-text" >
            <xsl:with-param name="target" select="$target-one" />
            <xsl:with-param name="text-style" select="$text-style-one" />
            <!-- pass content as an RTF, test vs. empty string, use copy-of -->
            <xsl:with-param name="custom-text">
                <xsl:apply-templates />
            </xsl:with-param>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="ndash"/>
        <xsl:apply-templates select="." mode="xref-text" >
            <xsl:with-param name="target" select="$target-two" />
            <xsl:with-param name="text-style" select="$text-style-two" />
        </xsl:apply-templates>
        <xsl:if test="$b-is-biblio-target">
            <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:variable>
    <!-- Send the target and text representation for link to a    -->
    <!-- format-specific and target-specific link manufacture.    -->
    <!-- This depends primarly on the $target, but we also        -->
    <!-- send the location of the link.  Example: a link in       -->
    <!-- display mathematics (rendered by MathJax for HTML)       -->
    <!-- requires radically different constructions as a knowl,   -->
    <!-- or as a hyperlink.  LaTeX barely cares.  We do wrap the  -->
    <!-- xref-text in \text{} for receipt in display mathematics. -->
    <!-- NB: could a xref with title text have math in it and mess-up here? -->
    <xsl:apply-templates select="$target-one" mode="xref-link">
        <xsl:with-param name="content" select="$text" />
        <xsl:with-param name="xref" select="." />
    </xsl:apply-templates>
</xsl:template>

<!-- A comma-, or space-separated list is unusual, -->
<!-- outside of a list of bibliography items.  For -->
<!-- other items we just mimic this case.          -->
<xsl:template match="xref[@ref and (contains(normalize-space(@ref), ' ') or contains(normalize-space(@ref), ','))]">
    <!-- Determine style of visible text in link -->
    <xsl:variable name="text-style">
        <xsl:apply-templates select="." mode="get-text-style" />
    </xsl:variable>
    <!-- commas to blanks, normalize, add trailing blank for parsing   -->
    <!-- initialize with empty previous node, recurse through the list -->
    <xsl:variable name="normalized-ref-list"
        select="concat(normalize-space(str:replace(@ref,',', ' ')), ' ')" />
    <xsl:apply-templates select="." mode="process-ref-list">
        <xsl:with-param name="previous-target" select="/.." />
        <xsl:with-param name="ref-list" select="$normalized-ref-list" />
        <xsl:with-param name="text-style" select="$text-style" />
    </xsl:apply-templates>
</xsl:template>

<!-- $ref-list must always have a trailing blank, if non-empty      -->
<!-- $previous-target serves two purposes:                          -->
<!--     empty signals start of the list, so no separator           -->
<!--     type-checking to preserve a consistent list (unimplmented) -->
<!-- $text-style is set on first call, then just pass-through       -->
<!-- Wrapping for bibiography list is based on first, last element  -->
<!-- No content overrides are allowed, since unclear jut how        -->
<!-- TODO: improve checking to avoid goofy results -->
<xsl:template match="xref" mode="process-ref-list">
    <xsl:param name="previous-target" select="/.." />
    <xsl:param name="ref-list" select="' '" />
    <xsl:param name="text-style" select="''" />
    <!-- split list at first blank, later recurse on $trailing -->
    <xsl:variable name="ref" select="substring-before($ref-list, ' ')" />
    <xsl:variable name="trailing" select="substring-after($ref-list, ' ')" />
    <!-- now work with one $ref and the configured $text-style -->
    <!-- first, error-check and resolve                        -->
    <xsl:apply-templates select="." mode="check-ref">
        <xsl:with-param name="ref" select="$ref" />
    </xsl:apply-templates>
    <!-- get the target as a node -->
    <xsl:variable name="target" select="id($ref)" />
    <!-- bibiographic targets are special -->
    <xsl:variable name="b-is-biblio-target" select="$target/self::biblio" />
    <!-- if starting, begin bibliography list wrapping -->
    <xsl:if test="not($previous-target) and $b-is-biblio-target">
        <xsl:text>[</xsl:text>
    </xsl:if>
    <!-- output a seperator, if not just starting -->
    <!-- protect text in a math display           -->
    <xsl:if test="$previous-target">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:text>, </xsl:text>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- create the visual/clickable/readable text      -->
    <!-- no content is passed, so no override in effect -->
    <xsl:variable name="text">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="xref-text">
            <xsl:with-param name="target" select="$target" />
            <xsl:with-param name="text-style" select="$text-style" />
        </xsl:apply-templates>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:variable>
    <!-- Send the target and text representation for link to a    -->
    <!-- format-specific and target-specific link manufacture.    -->
    <!-- This depends primarly on the $target, but we also        -->
    <!-- send the location of the link.  Example: a link in       -->
    <!-- display mathematics (rendered by MathJax for HTML)       -->
    <!-- requires radically different constructions as a knowl,   -->
    <!-- or as a hyperlink.  LaTeX barely cares.  We do wrap the  -->
    <!-- xref-text in \text{} for receipt in display mathematics. -->
    <!-- NB: could a xref with title text have math in it and mess-up here? -->
    <xsl:apply-templates select="$target" mode="xref-link">
        <xsl:with-param name="content" select="$text" />
        <xsl:with-param name="xref" select="." />
    </xsl:apply-templates>
    <!-- check if we have exhausted the list, -->
    <!-- so check bibliography wrapping       -->
    <xsl:if test="not($trailing) and $b-is-biblio-target">
        <xsl:text>]</xsl:text>
    </xsl:if>
    <!-- recurse into next reference in the list -->
    <xsl:if test="$trailing">
        <xsl:apply-templates select="." mode="process-ref-list">
            <xsl:with-param name="previous-target" select="$target" />
            <xsl:with-param name="ref-list" select="$trailing" />
            <xsl:with-param name="text-style" select="$text-style" />
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- Provisional cross-references -->
<!-- A convenience for authors in early stages of writing -->
<!-- Appear both inline and moreso in author tools        -->
<!-- TODO: Make cite/@provisional an error eventually     -->
<xsl:template match="cite[@provisional]|xref[@provisional]">
    <!-- DEPRECATED: 2014-06-25 -->
    <xsl:if test="self::cite" />
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
<xsl:template match="xref[not(@ref) and not(@first and @last) and not(@provisional)]">
    <xsl:message>MBX:WARNING: A cross-reference (&lt;xref&gt;) must have a @ref attribute, a @first/@last attribute pair, or a @provisional attribute</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:call-template name="inline-warning">
        <xsl:with-param name="warning">
            <xsl:text>xref without ref, first/last, or provisional attribute (check spelling)</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning">
            <xsl:text>xref, no recognized attribute</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- ######################### -->
<!-- Cross-Reference Utilities -->
<!-- ######################### -->

<!-- Any cross-reference can be checked to see if     -->
<!-- it points to something legitimate, since this is -->
<!-- a common mistake and often hard to detect/locate -->
<!-- http://www.stylusstudio.com/xsllist/200412/post20720.html -->
<xsl:template match="xref" mode="check-ref">
    <xsl:param name="ref" />
    <xsl:variable name="target" select="id($ref)" />
    <xsl:if test="not(exsl:node-set($target))">
        <xsl:message>MBX:WARNING: unresolved &lt;xref&gt; due to unknown reference "<xsl:value-of select="$ref"/>"</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
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

<!-- Parse, analyze switches, attributes -->
<!--   global:      5.2                  -->
<!--   type-global: Theorem 5.2          -->
<!--   title:       Smith's Theorem      -->
<xsl:template match="xref" mode="get-text-style">
    <xsl:choose>
        <!-- local specification is override of global  -->
        <!-- new @text attribute first, and if so, bail -->
        <xsl:when test="@text='global'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="@text='local'">
            <xsl:text>local</xsl:text>
        </xsl:when>
        <xsl:when test="@text='hybrid'">
            <xsl:text>hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-global'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-local'">
            <xsl:text>type-local</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-hybrid'">
            <xsl:text>type-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="@text='phrase-global'">
            <xsl:text>phrase-global</xsl:text>
        </xsl:when>
        <xsl:when test="@text='phrase-hybrid'">
            <xsl:text>phrase-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="@text='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <!-- old (deprecated, 2017-07-25) autoname attribute -->
        <xsl:when test="@autoname='no'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="@autoname='yes'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="@autoname='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <!-- otherwise, global setting via attribute/switch  -->
        <!-- New scheme is set from docinfo attribute        -->
        <!-- No setting in docinfo yields empty string for   -->
        <!-- $xref-text-style, so we drop into legacy scheme -->
        <!-- for the default, which is 'yes'/'type-global'   -->
        <xsl:when test="$xref-text-style='global'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='local'">
            <xsl:text>local</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='hybrid'">
            <xsl:text>hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-global'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-local'">
            <xsl:text>type-local</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-hybrid'">
            <xsl:text>type-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='phrase-global'">
            <xsl:text>phrase-global</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='phrase-hybrid'">
            <xsl:text>phrase-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <!-- use this when choose goes away
        <xsl:if test="not($xref-text-style = '')">
            <xsl:value-of select="$xref-text-style" />
        </xsl:if>
        -->
        <!-- legacy-autoname is a pass-thru of old autoname  -->
        <!-- except with no command-line, no docinfo, then   -->
        <!-- a 'unset' will appear here to activate new      -->
        <!-- default this could move later to the "otherwise"-->
        <xsl:when test="$legacy-autoname='unset'">
            <xsl:text>type-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$legacy-autoname='no'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="$legacy-autoname='yes'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="$legacy-autoname='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG:    NO TEXT STYLE DETERMINED</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The text that will be visible and clickable    -->
<!-- Bibliography items return a naked number,      -->
<!-- caller is responsible for adjusting text with  -->
<!-- brackets prior to shipping to link manufacture -->
<xsl:template match="xref" mode="xref-text">
    <xsl:param name="target" />
    <xsl:param name="text-style" />
    <xsl:param name="custom-text" select="''" />
    <!-- an equation target is exceptional -->
    <xsl:variable name="b-is-equation-target" select="$target/self::mrow or $target/self::men" />
    <!-- a bibliography target is exceptional -->
    <xsl:variable name="b-is-biblio-target" select="boolean($target/self::biblio)" />
    <!-- recognize content s potential override -->
    <xsl:variable name="b-has-content" select="not($custom-text = '')" />
    <xsl:choose>
        <!-- equation override -->
        <xsl:when test="$b-is-equation-target">
            <xsl:if test="$b-has-content">
                <xsl:copy-of select="$custom-text" />
                <xsl:apply-templates select="." mode="nbsp"/>
            </xsl:if>
            <xsl:text>(</xsl:text>
            <xsl:apply-templates select="$target" mode="xref-number" />
            <xsl:text>)</xsl:text>
        </xsl:when>
        <!-- bibliography override       -->
        <!-- number only, consumer wraps -->
        <!-- warn about useless content override (use as @detail?) -->
        <xsl:when test="$b-is-biblio-target">
            <xsl:apply-templates select="$target" mode="xref-number" />
        </xsl:when>
        <!-- now not an equation or bibliography target -->
        <!-- custom text is additional, as prefix, with no type -->
        <xsl:when test="$text-style = 'global'">
            <xsl:if test="$b-has-content">
                <xsl:copy-of select="$custom-text" />
                <xsl:apply-templates select="." mode="nbsp"/>
            </xsl:if>
            <xsl:apply-templates select="$target" mode="xref-number" />
        </xsl:when>
        <!-- custom text is additional, as prefix, with no type -->
        <xsl:when test="$text-style = 'local'">
            <xsl:if test="$b-has-content">
                <xsl:copy-of select="$custom-text" />
                <xsl:apply-templates select="." mode="nbsp"/>
            </xsl:if>
            <xsl:apply-templates select="$target" mode="serial-number" />
        </xsl:when>
        <xsl:when test="$text-style = 'type-global'">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                    <xsl:apply-templates select="." mode="nbsp"/>
                    <xsl:apply-templates select="$target" mode="xref-number" />
                </xsl:when>
                <!-- usual, default case -->
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="type-name" />
                    <xsl:apply-templates select="." mode="nbsp"/>
                    <xsl:apply-templates select="$target" mode="xref-number" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="$text-style = 'type-local'">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                    <xsl:apply-templates select="." mode="nbsp"/>
                    <xsl:apply-templates select="$target" mode="serial-number" />
                </xsl:when>
                <!-- usual, default case -->
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="type-name" />
                    <xsl:apply-templates select="." mode="nbsp"/>
                    <xsl:apply-templates select="$target" mode="serial-number" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="$text-style = 'phrase-global' or $text-style = 'phrase-hybrid'">
            <!-- no content override in this case -->
            <!-- maybe we can relax this somehow? -->
            <xsl:if test="$b-has-content">
                <xsl:message>MBX:WARNING: providing content ("<xsl:value-of select="." />") for an "xref" element is ignored for 'phrase-global' and 'phrase-hybrid' styles for xref text</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
            <!-- type-local first, no matter what    -->
            <!-- for each of the two phrase styles   -->
            <xsl:apply-templates select="$target" mode="type-name" />
            <xsl:apply-templates select="." mode="nbsp"/>
            <xsl:apply-templates select="$target" mode="serial-number" />
            <!-- climb up tree to find highest matching structure numbers -->
            <!-- we pass through the two styles so reaction can occur     -->
            <!-- For example for the target Theorem 37.8 of an article,   -->
            <!-- phrase-global: "of Section 37" always                    -->
            <!-- phrase-hybrid: "of Section 37" only if necessary         -->
            <xsl:apply-templates select="$target" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="." />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="/.." />
                <xsl:with-param name="target-structure-number">
                    <xsl:apply-templates select="$target" mode="structure-number" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="($text-style = 'hybrid') or ($text-style = 'type-hybrid')">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <!-- or addtion to plain number      -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                    <xsl:apply-templates select="." mode="nbsp"/>
                </xsl:when>
                <!-- no override, use type as prefix -->
                <xsl:when test="$text-style = 'type-hybrid'">
                    <xsl:apply-templates select="$target" mode="type-name" />
                    <xsl:apply-templates select="." mode="nbsp"/>
                </xsl:when>
                <!-- just a plain number, do nothing at all -->
                <xsl:otherwise />
            </xsl:choose>
            <!-- For example for the target Theorem 37.8 of an article, -->
            <!-- hybrid: 8 or if necessary, 37.8                        -->
            <!-- type-hybrid: Theorem 8 or if necessary, Theorem 37.8   -->
            <xsl:apply-templates select="$target" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="." />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="/.." />
                <xsl:with-param name="target-structure-number">
                    <xsl:apply-templates select="$target" mode="structure-number" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$text-style = 'title'">
            <xsl:choose>
                <!-- content override of title -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="title-full" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG:  NO XREF TEXT GENERATED</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ###################### -->
<!-- Smart Cross-References -->
<!-- ###################### -->

<!-- We climb the tree upward (ancestors) until we hit    -->
<!-- the "mathbook" element, and then quit and assess.    -->
<!-- The "xref" that started all this is used for the     -->
<!-- eventual "hybrid" schemes, to see how close it is.   -->
<!-- We record the oldest ancestor (highest) with a       -->
<!-- *number* that is the *structure number* of the       -->
<!-- target of the cross-reference.  So we know the       -->
<!-- element (and its type) that originates the bulk      -->
<!-- of the target's number.                              -->
<!--                                                      -->
<!-- There is one subtlety.  Usually one, and only one,   -->
<!-- ancestor has the matching number, so we could halt   -->
<!-- once found.  However, the immediately older ancestor -->
<!-- can have the same number.  The "objective" element   -->
<!-- is this way, it shares numbering with its containing -->
<!-- division.  So we track through all the ancestors.    -->
<!--                                                      -->
<!-- To see if a xref is close to its target, we add the  -->
<!-- *single* xref node to the subtree of the (highest)   -->
<!-- node that provides the target's structure number.    -->
<!-- By comparing the sizes of these node-sets, we can    -->
<!-- determine if the xref lies outside the subtree and   -->
<!-- then stick with global numbers.                      -->
<!--                                                      -->
<!-- $text-style                                          -->
<!--   gets passed through, in order to consolidate       -->
<!-- $xref                                                -->
<!--   gets passed through for eventual membership test   -->
<!-- $target                                              -->
<!--   gets passed through for producing hybrid numbers   -->
<!-- $highest-match                                       -->
<!--   starts empty and is updated, if it finishes        -->
<!--   empty then the target is high in the tree          -->
<!--   or a match is a root for the structure number      -->
<!-- $target-structure-number                             -->
<!--   is produced once as a string, and passed through   -->
<!--                                                      -->
<!-- Result is a string that completes the xref text      -->
<!--                                                      -->
<xsl:template match="*" mode="smart-xref-text">
    <xsl:param name="text-style" />
    <xsl:param name="xref" />
    <xsl:param name="target" />
    <xsl:param name="highest-match" select="/.." />
    <xsl:param name="target-structure-number" />
    <!-- step up immediately, else test on  -->
    <!-- structure numbers is vacuous       -->
    <xsl:variable name="parent" select="parent::*" />
    <xsl:variable name="parent-number">
        <xsl:apply-templates select="$parent" mode="number" />
    </xsl:variable>
    <xsl:choose>
        <!-- quit at the top, and examine highest-match,    -->
        <!-- and for phrase-hybrid, we do a membership test -->
        <xsl:when test="$parent/self::mathbook">
            <xsl:variable name="requires-global">
                <xsl:choose>
                    <!-- no match, already high up tree, so no  -->
                    <!-- qualification is needed in either case -->
                    <xsl:when test="not($highest-match)">
                        <xsl:text>false</xsl:text>
                    </xsl:when>
                    <!-- now have a match, so for phrase-global -->
                    <!-- we will always print the global info   -->
                    <xsl:when test="$text-style='phrase-global'">
                        <xsl:text>true</xsl:text>
                    </xsl:when>
                    <!-- now have a match, so for all other styles -->
                    <!-- we check to see if xref is in subtree     -->
                    <xsl:otherwise>
                        <xsl:variable name="target-tree-size" select="count($highest-match/descendant-or-self::*)" />
                        <xsl:variable name="xref-union-tree-size" select="count(($xref | $highest-match/descendant-or-self::*))" />
                        <xsl:value-of select="$xref-union-tree-size = $target-tree-size + 1" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- now know local/global, write trailing portion of text -->
            <!-- here based on the style and the global requirement    -->
            <xsl:choose>
                <!-- phrase styles may need remainder of phrase -->
                <xsl:when test="(($text-style='phrase-global') or ($text-style='phrase-hybrid')) and ($requires-global = 'true')">
                    <!-- connector, internationalize -->
                    <xsl:text> of </xsl:text>
                    <xsl:apply-templates select="$highest-match" mode="type-name" />
                    <xsl:apply-templates select="." mode="nbsp" />
                    <xsl:apply-templates select="$highest-match" mode="xref-number" />
                </xsl:when>
                <!-- hybrid styles need number for remainder -->
                <xsl:when test="($text-style='hybrid') or ($text-style='type-hybrid')">
                    <xsl:choose>
                        <xsl:when test="$requires-global = 'true'">
                            <xsl:apply-templates select="$target" mode="xref-number" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$target" mode="serial-number" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <!-- possible missing implementation bug in numbering -->
        <xsl:when test="$parent-number = '[NUM]'">
            <xsl:message>MBX:BUG:     Looks like a [<xsl:value-of select="local-name($parent)" />] element has an ambiguous number, found while making cross-reference text</xsl:message>
        </xsl:when>
        <!-- no match, just recurse, and preserve $highest-match -->
        <xsl:when test="not(concat($parent-number, '.') = $target-structure-number)">
            <xsl:apply-templates select="$parent" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="$xref" />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="$highest-match" />
                <xsl:with-param name="target-structure-number" select="$target-structure-number" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- a match, record in updated $highest-match -->
        <xsl:when test="concat($parent-number, '.') = $target-structure-number">
            <xsl:apply-templates select="$parent" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="$xref" />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="$parent" />
                <xsl:with-param name="target-structure-number" select="$target-structure-number" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- impossible to get here -->
    </xsl:choose>
</xsl:template>

<!-- This is an abstract template, to accomodate -->
<!-- hard-coded HTML numbers and for LaTeX the   -->
<!-- \ref and \label mechanism                   -->
<xsl:template match="*" mode="xref-number">
    <xsl:text>[XREFNUM]</xsl:text>
</xsl:template>

<!-- This is a base implementation for the xref-link -->
<!-- template, which just repeats the content, with  -->
<!-- an indication that this needs to be overridden  -->
<!--   context -                                     -->
<!--     the target of the link, so the right        -->
<!--     identification can be produced              -->
<!--   content -                                     -->
<!--     an RTF of the visual text,                  -->
<!--     suitable for location of the link           -->
<!--   xref -                                        -->
<!--     the link node itself, typically             -->
<!--     its parent is inspected to vary             -->
<!--   implementation based on location              -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" />
    <xsl:param name="xref" />
    <xsl:text>[LINK: </xsl:text>
    <xsl:apply-templates select="$content" />
    <xsl:text>]</xsl:text>
</xsl:template>


<!-- #################### -->
<!-- Common Constructions -->
<!-- #################### -->

<!-- With no special formatting  -->
<!-- "PreTeXt" can be in -common -->
<xsl:template match="pretext">
    <xsl:text>PreTeXt</xsl:text>
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
<!-- DEPRECATION: 2015-01-28 -->
<xsl:template match="circum">
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

<!-- Characters with left and right variants naturally       -->
<!-- give rise to tags with begin and end variants           -->
<!-- We implement these here with Result Tree Fragments      -->
<!-- as a polymorphic technique for the actual characters    -->
<!-- LaTeX quotes are odd, so we override "q" and "sq" there -->

<xsl:template match="q">
    <xsl:variable name="lq-rtf">
        <lq />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($lq-rtf)" />
    <xsl:apply-templates />
    <xsl:variable name="rq-rtf">
        <rq />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($rq-rtf)" />
</xsl:template>

<xsl:template match="sq">
    <xsl:variable name="lsq-rtf">
        <lsq />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($lsq-rtf)" />
    <xsl:apply-templates />
    <xsl:variable name="rsq-rtf">
        <rsq />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($rsq-rtf)" />
</xsl:template>

<xsl:template match="braces">
    <xsl:variable name="lbrace-rtf">
        <lbrace />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($lbrace-rtf)" />
    <xsl:apply-templates />
    <xsl:variable name="rbrace-rtf">
        <rbrace />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($rbrace-rtf)" />
</xsl:template>

<xsl:template match="brackets">
    <xsl:variable name="lbracket-rtf">
        <lbracket />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($lbracket-rtf)" />
    <xsl:apply-templates />
    <xsl:variable name="rbracket-rtf">
        <rbracket />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($rbracket-rtf)" />
</xsl:template>

<xsl:template match="dblbrackets">
    <xsl:variable name="ldblbracket-rtf">
        <ldblbracket />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($ldblbracket-rtf)" />
    <xsl:apply-templates />
    <xsl:variable name="rdblbracket-rtf">
        <rdblbracket />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($rdblbracket-rtf)" />
</xsl:template>

<xsl:template match="angles">
    <xsl:variable name="langle-rtf">
        <langle />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($langle-rtf)" />
    <xsl:apply-templates />
    <xsl:variable name="rangle-rtf">
        <rangle />
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($rangle-rtf)" />
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
<xsl:template match="*|@*" mode="location-report">
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

<!-- Debugging info -->
<!-- @xml:base attribute of xinclude scheme -->
<!-- @xml:id - self-explanatory             -->
<!-- title - if there is one                -->
<xsl:template match="*" mode="debug-location">
    <xsl:if test="$b-debug">
        <xsl:message>
            <xsl:text>MBX:DEBUG:   </xsl:text>
            <xsl:text>f: </xsl:text>
            <xsl:choose>
                <xsl:when test="@xml:base">
                    <xsl:value-of select="@xml:base" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>|e: </xsl:text>
            <xsl:value-of select="local-name(.)" />
            <xsl:text>|i: </xsl:text>
            <xsl:value-of select="@xml:id" />
            <xsl:text>|t: </xsl:text>
            <xsl:apply-templates select="." mode="title-simple" />
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- ############### -->
<!-- Global Warnings -->
<!-- ############### -->

<!-- Checks for errors that would be time-consuming -->
<!-- if done repeatedly, so a pre-processing step   -->
<!-- Calling context should be "mathbook" element   -->
<xsl:template match="mathbook" mode="generic-warnings">
    <xsl:apply-templates select="." mode="literate-programming-warning" />
    <xsl:apply-templates select="." mode="xinclude-warnings" />
    <xsl:apply-templates select="." mode="xmlid-warning" />
    <xsl:apply-templates select="." mode="webwork-warnings" />
    <xsl:apply-templates select="." mode="text-element-warning" />
    <xsl:apply-templates select="." mode="subdivision-structure-warning" />
</xsl:template>

<!-- Literate Programming support is half-baked, 2017-07-21 -->
<xsl:template match="mathbook" mode="literate-programming-warning">
    <xsl:if test="$document-root//fragment">
        <xsl:call-template name="banner-warning">
            <xsl:with-param name="warning">
                <xsl:text>  Literate Programming support is experimental&#xa;</xsl:text>
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>    1.  Code generation is functional, but does not respect indentation&#xa;</xsl:text>
                <xsl:text>    2.  LaTeX generation is in development, 2017-07-20&#xa;</xsl:text>
                <xsl:text>    3.  MTML generation has not begun&#xa;</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Using the modular  xinclude  scheme at the top level,      -->
<!-- and forgetting the command-line switch is a common mistake -->
<!-- The following is not perfect, but reasonably effective     -->
<xsl:template match="mathbook" mode="xinclude-warnings">
    <xsl:if test="book and not(book/chapter or book/part/chapter)">
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

<!-- We warn about bad xml:id.  Our limits: -->
<!-- 26 Latin letters (upper, lower case),  -->
<!-- 10 digits, hyphen/dash, underscore     -->
<!-- TODO: Added 2016-10-29, make into a fatal error later -->
<xsl:template match="mathbook" mode="xmlid-warning">
    <xsl:variable name="xmlid-characters" select="concat('-_', &SIMPLECHAR;)" />
    <xsl:for-each select="//@xml:id">
        <xsl:if test="not(translate(., $xmlid-characters, '') = '')">
            <xsl:message>
                <xsl:text>MBX:WARNING:    </xsl:text>
                <xsl:text>The @xml:id "</xsl:text>
                <xsl:value-of select="." />
                <xsl:text>" is invalid.  Use only letters, numbers, hyphens and underscores.</xsl:text>
            </xsl:message>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<!-- We warn about WeBWorK table details that ultimately may not be respected -->
<!-- if a problem is archived to .pg, and then that file is used on a WeBWorK -->
<!-- server, and then WeBWorK's print copy mechanism is used to make a pdf    -->
<xsl:template match="mathbook" mode="webwork-warnings">
    <xsl:variable name="coltop" select="//webwork//tabular/col/@top" />
    <xsl:variable name="cellbottom" select="//webwork//tabular/cell/@bottom" />
    <xsl:variable name="medium-major" select="//webwork//tabular//*[@top='medium' or @top='major' or @bottom='medium' or @bottom='major' or @left='medium' or @left='major' or @right='medium' or @right='major']" />
    <xsl:if test="$coltop">
        <xsl:message>
            <xsl:text>MBX:WARNING:   </xsl:text>
            <xsl:text>column-specific top border attributes are not implemented for the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine (</xsl:text>
            <xsl:value-of select="count($coltop)" />
            <xsl:text> time</xsl:text>
            <xsl:if test="count($coltop) > 1">
                <xsl:text>s</xsl:text>
            </xsl:if>
            <xsl:text>)</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:if test="$cellbottom">
        <xsl:message>
            <xsl:text>MBX:WARNING:   </xsl:text>
            <xsl:text>cell-specific bottom border attributes are not implemented for the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine (</xsl:text>
            <xsl:value-of select="count($cellbottom)" />
            <xsl:text> time</xsl:text>
            <xsl:if test="count($cellbottom) > 1">
                <xsl:text>s</xsl:text>
            </xsl:if>
            <xsl:text>)</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:if test="$medium-major">
        <xsl:message>
            <xsl:text>MBX:WARNING:   </xsl:text>
            <xsl:text>'medium' and 'major' table rule attributes will be handled as 'minor' in the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine (</xsl:text>
            <xsl:value-of select="count($medium-major)" />
            <xsl:text> time</xsl:text>
            <xsl:if test="count($medium-major) > 1">
                <xsl:text>s</xsl:text>
            </xsl:if>
            <xsl:text>)</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- Elements should never happen like this, so we     -->
<!-- can match on them and offer pretty good advice    -->
<!-- Last: since both summary and specifics.  We       -->
<!-- can't catch with a template, since we don't apply -->
<!-- templates in the places where elements are banned -->
<!-- c, cline; unstructured cd, pre                    -->
<!-- prompt, input, output for sage, console, program  -->
<xsl:template match="mathbook" mode="text-element-warning">
    <xsl:variable name="bad-elements" select="$document-root//c/*|$document-root//cline/*|$document-root//cd[not(cline)]/*|$document-root//pre[not(cline)]/*|$document-root//prompt/*|$document-root//input/*|$document-root//output/*" />
    <xsl:if test="$bad-elements">
        <xsl:message>
            <xsl:text>MBX:WARNING: </xsl:text>
            <xsl:text>There are apparent XML elements in locations that should be text only (</xsl:text>
            <xsl:value-of select="count($bad-elements)" />
            <xsl:text> times).</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:for-each select="$bad-elements">
        <xsl:message>
            <xsl:text>MBX:WARNING: </xsl:text>
            <xsl:text>There is an apparent XML element (&lt;</xsl:text>
            <xsl:value-of select="local-name(.)" />
            <xsl:text>&gt;) inside an &lt;</xsl:text>
            <xsl:value-of select="local-name(parent::*)" />
            <xsl:text>&gt; element, which should only contain text.  Using an escaped "less than" ('&amp;lt;') might be the solution, or using a CDATA section.</xsl:text>
        </xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:for-each>
</xsl:template>

<!-- New authors often begin a subdivision with some material,     -->
<!-- then begin a run of further subdivisions.  This preliminary   -->
<!-- material belongs in an introduction (or is for a conclusion). -->
<!-- This test is not exhaustive, but will catch most cases.       -->
<xsl:template match="mathbook" mode="subdivision-structure-warning">
    <xsl:for-each select=".//chapter">
        <xsl:if test="p and section">
            <xsl:message>
                <xsl:text>MBX:WARNING: </xsl:text>
                <xsl:text>A chapter containing sections needs to have other content inside an &lt;introduction&gt; and/or  &lt;conclusion&gt;.</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
    <xsl:for-each select=".//section">
        <xsl:if test="p and subsection">
            <xsl:message>
                <xsl:text>MBX:WARNING: </xsl:text>
                <xsl:text>A section containing subsections needs to have other content inside an &lt;introduction&gt; and/or  &lt;conclusion&gt;.</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
    <xsl:for-each select=".//subsection">
        <xsl:if test="p and subsubsection">
            <xsl:message>
                <xsl:text>MBX:WARNING: </xsl:text>
                <xsl:text>A subsection containing subsubsections needs to have other content inside an &lt;introduction&gt; and/or  &lt;conclusion&gt;.</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<!-- ############ -->
<!-- Deprecations -->
<!-- ############ -->

<!-- Generic deprecation message for uniformity   -->
<!-- occurences is a node-list of "problem" nodes -->
<xsl:template name="deprecation-message">
    <xsl:param name="occurences" />
    <xsl:param name="date-string" />
    <xsl:param name="message" />
    <xsl:if test="$occurences">
        <xsl:message>
            <xsl:text>MBX:DEPRECATE: (</xsl:text>
            <xsl:value-of select="$date-string" />
            <xsl:text>) </xsl:text>
            <xsl:value-of select="$message" />
            <xsl:text> (</xsl:text>
            <xsl:value-of select="count($occurences)" />
            <xsl:text> time</xsl:text>
            <xsl:if test="count($occurences) > 1">
                <xsl:text>s</xsl:text>
            </xsl:if>
            <xsl:text>)</xsl:text>
            <!-- once verbosity is implemented -->
            <!-- <xsl:text>, set log.level to see more details</xsl:text> -->
        </xsl:message>
        <xsl:for-each select="$occurences">
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:for-each>
        <xsl:message>
            <xsl:text>--------------</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- pass in a condition, true is a problem -->
<xsl:template name="parameter-deprecation-message">
    <xsl:param name="incorrect-use" select="false()" />
    <xsl:param name="date-string" />
    <xsl:param name="message" />
    <xsl:if test="$incorrect-use">
        <xsl:message>
            <xsl:text>MBX:DEPRECATE: (</xsl:text>
            <xsl:value-of select="$date-string" />
            <xsl:text>) </xsl:text>
            <xsl:value-of select="$message" />
            <!-- once verbosity is implemented -->
            <!-- <xsl:text>, set log.level to see more details</xsl:text> -->
        </xsl:message>
        <xsl:message>
            <xsl:text>--------------</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<xsl:template match="*" mode="deprecation-warnings">
    <!-- older deprecations at the bottom of this list,  -->
    <!-- so author will see new at the tail end          -->
    <!--  -->
    <!-- 2014-05-04  @filebase has been replaced in function by @xml:id -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//@filebase" />
        <xsl:with-param name="date-string" select="'2014-05-04'" />
        <xsl:with-param name="message" select="'the &quot;filebase&quot; attribute is deprecated, convert to &quot;xml:id&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2014-06-25  xref once had cite as a variant -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//cite" />
        <xsl:with-param name="date-string" select="'2014-06-25'" />
        <xsl:with-param name="message" select="'the &quot;cite&quot; element is deprecated, convert to &quot;xref&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-01-28  once both circum and circumflex existed, circumflex won -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//circum" />
        <xsl:with-param name="date-string" select="'2015-01-28'" />
        <xsl:with-param name="message" select="'the &quot;circum&quot; element has been replaced by the &quot;circumflex&quot; element'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-02-08  naked tikz, asymptote, sageplot are banned    -->
    <!-- typically these would be in a figure, but not necessarily -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//tikz[not(parent::image)]|$document-root//asymptote[not(parent::image)]|$document-root//sageplot[not(parent::image)]" />
        <xsl:with-param name="date-string" select="'2015-02-08'" />
        <xsl:with-param name="message" select="'&quot;tikz&quot;, &quot;asymptote&quot;, &quot;sageplot&quot;, elements must always be contained directly within an &quot;image&quot; element, rather than directly within a &quot;figure&quot; element'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-02-20  tikz is generalized to latex-image-code -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//tikz" />
        <xsl:with-param name="date-string" select="'2015-02-20'" />
        <xsl:with-param name="message" select="'the &quot;tikz&quot; element is deprecated, convert to &quot;latex-image-code&quot; inside &quot;image&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-03-13  paragraph is renamed more accurately to paragraphs           -->
    <!-- 2017-07-16  removed all backwards compatibility and added empty template -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//paragraph" />
        <xsl:with-param name="date-string" select="'2015-03-13'" />
        <xsl:with-param name="message" select="'the &quot;paragraph&quot; element is deprecated and any contained content will silently not appear, replaced by functional equivalent &quot;paragraphs&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-03-17  various indicators of table rearrangement -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//tgroup" />
        <xsl:with-param name="date-string" select="'2015-03-17'" />
        <xsl:with-param name="message" select="'tables are done quite differently, the &quot;tgroup&quot; element is indicative'" />
    </xsl:call-template>
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//tgroup/thead/row/entry|$document-root//tgroup/tbody/row/entry" />
        <xsl:with-param name="date-string" select="'2015-03-17'" />
            <xsl:with-param name="message" select="'tables are done quite differently, the &quot;entry&quot; element should be replaced by the &quot;cell&quot; element'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-06-26  chunking became a general thing -->
    <xsl:if test="$html.chunk.level != ''">
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2015-06-26'" />
        <xsl:with-param name="message" select="'the  html.chunk.level  parameter has been replaced by simply  chunk.level  and now applies more generally'" />
            <xsl:with-param name="incorrect-use" select="($html.chunk.level != '')" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- 2015-12-12  empty labels on an ordered list was a bad idea -->
     <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//ol[@label='']" />
        <xsl:with-param name="date-string" select="'2015-12-12'" />
        <xsl:with-param name="message" select="'an ordered list (&lt;ol&gt;) may not have empty labels, and numbering will be unpredictable.  Switch to an unordered list  (&lt;ul&gt;)'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-04-07  'plural' option for @autoname discarded -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//xref[@autoname='plural']" />
        <xsl:with-param name="date-string" select="'2016-04-07'" />
        <xsl:with-param name="message" select="'a &lt;xref&gt; element may not have an @autoname attribute set to plural.  There is no replacement, perhaps use content in the &lt;xref&gt;.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-05-23  Require parts of a letter to be structured (could be relaxed) -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//letter/frontmatter/from[not(line)] | $document-root//letter/frontmatter/to[not(line)] | $document-root//letter/backmatter/signature[not(line)]" />
        <xsl:with-param name="date-string" select="'2016-05-23'" />
        <xsl:with-param name="message" select="'&lt;to&gt;, &lt;from&gt;, and &lt;signature&gt; of a letter must be structured as a sequence of &lt;line&gt;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-05-23  line breaks are not XML-ish, some places allow "line" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//br" />
        <xsl:with-param name="date-string" select="'2016-05-23'" />
        <xsl:with-param name="message" select="'&lt;br&gt; can no longer be used to create multiline output; you may use &lt;line&gt; elements in select situations'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-07-31  ban @height attribute, except within webwork problems -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//image[@height and not(ancestor::*[self::webwork])]" />
        <xsl:with-param name="date-string" select="'2016-07-31'" />
        <xsl:with-param name="message" select="'@height attribute on &lt;image&gt; is no longer effective and will be ignored, except within a WeBWorK exercise'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-07-31  widths of images must be expressed as percentages -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//image[@width and not(contains(@width, '%'))]" />
        <xsl:with-param name="date-string" select="'2016-07-31'" />
        <xsl:with-param name="message" select="'@width attribute on &lt;image&gt; must be expressed as a percentage'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-02-05  hyphen-minus replaces hyphen -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//hyphen" />
        <xsl:with-param name="date-string" select="'2017-02-05'" />
        <xsl:with-param name="message" select="'use the &lt;hyphen-minus/&gt; element as a direct replacement for &lt;hyphen/&gt;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-05  top-level items that should have captions, but don't -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//figure[not(caption) and not(parent::sidebyside)] | $document-root//table[not(caption) and not(parent::sidebyside)] | $document-root//listing[not(caption) and not(parent::sidebyside)]" />
        <xsl:with-param name="date-string" select="'2017-07-05'" />
        <xsl:with-param name="message" select="'a &lt;figure&gt;, &lt;table&gt;, or &lt;listing&gt; as a child of a division must contain a &lt;caption&gt; element.  A &lt;sidebyside&gt; can be used as a functional equivalent, or add a caption element (possibly with empty content) to replace with a numbered version.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-05  sidebyside items that do not have captions, so ineffective -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//figure[not(caption) and parent::sidebyside] | $document-root//table[not(caption) and parent::sidebyside] | $document-root//listing[not(caption) and parent::sidebyside]" />
        <xsl:with-param name="date-string" select="'2017-07-05'" />
        <xsl:with-param name="message" select="'a &lt;figure&gt;, &lt;table&gt;, or &lt;listing&gt; as a child of a &lt;sidebyside&gt;, and without a &lt;caption&gt; element, is ineffective, redundant, and deprecated.  Remove the enclosing element, perhaps migrating an xml:id attribute to the contents.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-05  a sidebyside cannot have a caption -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//sidebyside[caption]" />
        <xsl:with-param name="date-string" select="'2017-07-05'" />
        <xsl:with-param name="message" select="'a &lt;sidebyside&gt; cannot have a &lt;caption&gt;.  Place the &lt;sidebyside&gt; inside a &lt;figure&gt;, employing the &lt;caption&gt;, which will be the functional equivalent.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-05  sidebyside cannot be cross-referenced anymore, so not knowlizable -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2017-07-05'" />
        <xsl:with-param name="message" select="'the  html.knowl.sidebyside  parameter is now obsolete and will be ignored'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.sidebyside != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-14  index specification and production reworked -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//index-part" />
        <xsl:with-param name="date-string" select="'2017-07-14'" />
        <xsl:with-param name="message" select="'the &quot;index-part&quot; element is deprecated, replaced by functional equivalent &quot;index&quot;'" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//index[not(main) and not(index-list)]" />
        <xsl:with-param name="date-string" select="'2017-07-14'" />
        <xsl:with-param name="message" select="'a &quot;index&quot; element is deprecated, replaced by functional equivalent &quot;idx&quot;'" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//index[main]" />
        <xsl:with-param name="date-string" select="'2017-07-14'" />
        <xsl:with-param name="message" select="'a &quot;index&quot; element with &quot;main&quot; and &quot;sub&quot; headings is deprecated, replaced by functional equivalent &quot;idx&quot; with &quot;h&quot; headings'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-14  cosmetic replacement of WW image/@tex_size by image/@tex-size -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//@tex_size" />
        <xsl:with-param name="date-string" select="'2017-07-18'" />
        <xsl:with-param name="message" select="'the &quot;tex_size&quot; attribute is deprecated, replaced by functional equivalent &quot;tex-size&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-25  replacement of three xref/@autoname attributes by @text -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//xref[@autoname='no']" />
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the &quot;xref/autoname&quot; attribute is deprecated, replace  autoname=&quot;no&quot;  by functional equivalent  text=&quot;global&quot;'" />
    </xsl:call-template>
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//xref[@autoname='yes']" />
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the &quot;xref/autoname&quot; attribute is deprecated, replace  autoname=&quot;yes&quot;  by functional equivalent  text=&quot;type-global&quot;'" />
    </xsl:call-template>
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurences" select="$document-root//xref[@autoname='title']" />
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the &quot;xref/autoname&quot; attribute is deprecated, replace  autoname=&quot;title&quot;  by functional equivalent  text=&quot;title&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-25  deprecate null autoname, and warn about switch of default -->
    <!-- We include the existence of "docinfo" as a marker of a mature, non-beginner project -->
    <xsl:if test="($autoname = '') and $docinfo and not(//docinfo/cross-references)">
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the default version of text for cross-references has changed.  Rather than simply numbers, they will be prefixed by type-names as well.  So you could see duplicates like &quot;Theorem Theorem 5.2&quot;.  Set  &quot;docinfo/cross-references/@text&quot;  to  &quot;global&quot;  to restore old behavior'" />
            <xsl:with-param name="incorrect-use" select="($autoname = '') and $docinfo and not(//docinfo/cross-references)" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- 2017-07-25  deprecate intentional autoname without new setting -->
    <xsl:if test="not($autoname = '') and not(//docinfo/cross-references)">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-07-25'" />
            <xsl:with-param name="message" select="'the  autoname  parameter is deprecated, but is still effective since  &quot;docinfo/cross-references/@text&quot;  has not been set.  The following parameter values equate to the attribute values: &quot;no&quot; is &quot;global&quot;, &quot;yes&quot; is &quot;type-global&quot;, &quot;title&quot; is &quot;title&quot;'" />
            <xsl:with-param name="incorrect-use" select="not($autoname = '') and not(//docinfo/cross-references)" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- 2017-07-25  deprecate intentional autoname also with new setting -->
    <xsl:if test="not($autoname = '') and //docinfo/cross-references">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-07-25'" />
            <xsl:with-param name="message" select="'the  autoname  parameter is deprecated, and is being overidden by a  &quot;docinfo/cross-references/@text&quot;  and so is totally ineffective and can be removed'" />
                <xsl:with-param name="incorrect-use" select="not($autoname = '') and //docinfo/cross-references" />
        </xsl:call-template>
    </xsl:if>
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
    <xsl:copy-of select="$lead-in" /><xsl:text>*    Generated from PreTeXt source   *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:if test="$b-debug-datedfiles">
    <xsl:copy-of select="$lead-in" /><xsl:text>*    on </xsl:text>  <xsl:value-of select="date:date-time()" />
                                                                      <xsl:text>    *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    </xsl:if>
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

<!-- ################# -->
<!-- Percent Utilities -->
<!-- ################# -->

<!-- Take as input a node set of attributes -->
<!-- of percentages (with '%' at the end)   -->
<!-- Check that sum is under 100%           -->
<xsl:template name="cap-width-at-one-hundred-percent">
    <xsl:param name="nodeset" />
    <xsl:param name="cap" select="100" />
    <xsl:if test="$nodeset">
        <xsl:if test="substring-before($nodeset[1], '%')&gt;$cap">
            <xsl:message terminate="yes">MBX:ERROR:   percentage attributes sum to over 100%</xsl:message>
        </xsl:if>
        <xsl:call-template name="cap-width-at-one-hundred-percent">
            <xsl:with-param name="nodeset" select="$nodeset[position()&gt;1]" />
            <xsl:with-param name="cap" select="$cap - substring-before($nodeset[1], '%')" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Take a string as input    -->
<!-- Abort if not in the form  -->
<!-- \s*[0-9]*\.?[0-9]*\s*%\s* -->
<!-- Normalize to              -->
<!-- [0-9]*\.?[0-9]*%          -->
<xsl:template name="normalize-percentage">
    <xsl:param name="percentage" />
    <xsl:variable name="stripped-percentage">
        <xsl:value-of select="normalize-space($percentage)" />
    </xsl:variable>
    <xsl:if test="substring($stripped-percentage,string-length($stripped-percentage)) != '%'">
        <xsl:message terminate="yes">MBX:ERROR:   expecting a percentage ending in '%'; got <xsl:value-of select="$stripped-percentage"/></xsl:message>
    </xsl:if>
    <xsl:variable name="percent">
        <xsl:value-of select="normalize-space(substring($stripped-percentage,1,string-length($stripped-percentage) - 1))" />
    </xsl:variable>
    <xsl:if test="number($percent) != $percent">
        <xsl:message terminate="yes">MBX:ERROR:   expecting a numerical value preceding '%'; got <xsl:value-of select="$percent"/></xsl:message>
    </xsl:if>
    <xsl:value-of select="concat($percent,'%')" />
</xsl:template>

<!-- ######## -->
<!-- Bad Bank -->
<!-- ######## -->

<!-- This where old elements go to die.        -->
<!-- Deprecated, then totally discarded later. -->

<!-- 2017-07-16  killed, from 2015-03-13 deprecation -->
<xsl:template match="paragraph" />


</xsl:stylesheet>
