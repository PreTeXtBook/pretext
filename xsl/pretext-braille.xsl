<?xml version='1.0'?>

<!--********************************************************************
Copyright 2019 Robert A. Beezer

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

<!-- A conversion to "stock" PreTeXt HTML, but optimized as an     -->
<!-- eventual input for teh liblouis system to produce Grade 2     -->
<!-- and Nemeth Braille into BRF format with ASCII Braille         -->
<!-- (encoding the 6-dot-patterns of cells with 64 well-behaved    -->
<!-- ASCII characters).  By itself theis conversion is not useful. -->
<!-- The math bits (as LaTeX) need to be converted to Braille by   -->
<!-- MathJax and Speech Rules Engine, and then fed to              -->
<!-- liblouisutdml's  file2brl  program.                           -->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    >

<!-- desire HTML output, but primarily content -->
<xsl:import href="mathbook-html.xsl" />

<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<!-- This variable is exclusive to the (imported) HTML conversion -->
<!-- stylesheet.  It is defined there as false() and here we      -->
<!-- redefine it as true().  This allows for minor variations     -->
<!-- to be made in that stylesheet conditionally.                 -->
<xsl:variable name="b-braille" select="true()"/>

<!-- Only need one monolithic file, how to chunk -->
<!-- is not obvious, so we set this here         -->
<xsl:param name="chunk.level" select="0"/>

<!-- NB: This will need to be expanded with terms like //subsection/exercises -->
<xsl:variable name="b-has-subsubsection" select="boolean($document-root//subsubsection)"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- These two templates are similar to those of  mathbook-html.xsl. -->
<!-- Primarily the production of cross-reference ("xref") knowls     -->
<!-- has been removed.                                               -->

<xsl:template match="/">
    <xsl:apply-templates/>
</xsl:template>

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<!-- We process structural nodes via chunking routine in xsl/mathbook-common.xsl    -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<xsl:template match="/mathbook|/pretext">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">This template is under development.&#xa;It will not produce Braille directly, just a precursor.</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="$root" mode="generic-warnings" />
    <xsl:apply-templates select="$root" mode="deprecation-warnings" />
    <xsl:apply-templates mode="chunking" />
</xsl:template>

<!-- ################# -->
<!-- Page Construction -->
<!-- ################# -->

<!-- A greatly simplified file-wrap template      -->
<!-- Drop file output, so we can script on stdout -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />

    <html>
        <head>
        <!-- some MathJax config? -->
        </head>
        <body>
            <xsl:call-template name="latex-macros" />
            <xsl:copy-of select="$content" />
        </body>
    </html>
</xsl:template>

<!-- The "frontmatter" and "backmatter" of the HTML version are possibly -->
<!-- summary pages and need to step the heading level (h1-h6) for screen -->
<!-- readers and accessibility.  But here we want to style items at      -->
<!-- similar levels to be at the same HTML level so we can use liblouis' -->
<!-- device for this.  So, for example, we want  book/preface/chapter    -->
<!-- to be h2, not h3.  Solution: we don't need the frontmatter and      -->
<!-- backmatter distinctions in Braille, so we simply recurse with a     -->
<!-- pass-through of the heading level.  This is a very tiny subset of   -->
<!-- the HTML template matching &STRUCTURAL;.                            -->
<xsl:template match="frontmatter|backmatter">
    <xsl:param name="heading-level"/>

    <xsl:apply-templates>
        <xsl:with-param name="heading-level" select="$heading-level"/>
    </xsl:apply-templates>
</xsl:template>


<!-- ########## -->
<!-- Title Page -->
<!-- ########## -->

<!-- This has the same @match as in the HTML conversion,        -->
<!-- so keep them in-sync.  Here we make adjustments:           -->
<!--   * One big h1 for liblouis styling (centered, etc)        -->
<!--   * No extra HTML, just line breaks                        -->
<!--   * exchange the subtitle semicolon/space for a line break -->
<!--   * dropped credit, and included edition                   -->
<!-- See [BANA-2016, 1.8.1]                                     -->
<xsl:template match="titlepage">
    <xsl:variable name="b-has-subtitle" select="parent::frontmatter/parent::*/subtitle"/>
    <div class="fullpage">
        <xsl:apply-templates select="parent::frontmatter/parent::*" mode="title-full" />
        <br/>
        <xsl:if test="$b-has-subtitle">
            <xsl:apply-templates select="parent::frontmatter/parent::*" mode="subtitle" />
            <br/>
        </xsl:if>
        <!-- We list authors and editors in document order -->
        <xsl:apply-templates select="author|editor" mode="full-info"/>
        <!-- A credit is subsidiary, so follows -->
        <!-- <xsl:apply-templates select="credit" /> -->
        <xsl:if test="colophon/edition or date">
            <br/> <!-- a small gap -->
            <xsl:if test="colophon/edition">
                <xsl:apply-templates select="colophon/edition"/>
                <br/>
            </xsl:if>
            <xsl:if test="date">
                <xsl:apply-templates select="date"/>
                <br/>
            </xsl:if>
        </xsl:if>
    </div>
    <!-- A marker for generating the Table of Contents,      -->
    <!-- content of the element is the title of the new page -->
    <div data-braille="tableofcontents">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'toc'" />
        </xsl:call-template>
    </div>
</xsl:template>

<xsl:template match="titlepage/author|titlepage/editor" mode="full-info">
    <xsl:apply-templates select="personname"/>
    <xsl:if test="self::editor">
        <xsl:text> (Editor)</xsl:text>
    </xsl:if>
    <br/>
    <xsl:if test="department">
        <xsl:apply-templates select="department"/>
        <br/>
    </xsl:if>
    <xsl:if test="institution">
        <xsl:apply-templates select="institution"/>
        <br/>
    </xsl:if>
</xsl:template>


<!-- ######### -->
<!-- Divisions -->
<!-- ######### -->


<!-- Unnumbered, chapter-level headings, just title text -->
<xsl:template match="preface|acknowledgement|biography|foreword|dedication|solutions[parent::backmatter]|references[parent::backmatter]|index|colophon" mode="header-content">
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- We override the "section-header" template to place classes   -->
<!--                                                              -->
<!--     fullpage centerpage center cell5 cell7                   -->
<!--                                                              -->
<!-- onto the header so liblouis can style it properly            -->
<!-- This is greatly simplified, "hX" elements just become "div", -->
<!-- which is all we need for the  liblouis  sematic action file  -->


<xsl:template match="*" mode="section-header">
    <div>
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="division-class"/>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="header-content" />
    </div>
</xsl:template>

<!-- Verbatim from -html conversion read about it there -->
<xsl:template match="book|article" mode="section-header" />

<!-- Default is indeterminate (seacrch while debugging) -->
<xsl:template match="*" mode="division-class">
    <xsl:text>none</xsl:text>
</xsl:template>

<!-- Part is more like a title page -->
<xsl:template match="part" mode="division-class">
    <xsl:text>fullpage</xsl:text>
</xsl:template>

<!-- Chapters headings are always centered -->
<xsl:template match="chapter" mode="division-class">
    <xsl:text>centerpage</xsl:text>
</xsl:template>

<!-- Chapter-level headings are always centered -->
<xsl:template match="preface|acknowledgement|biography|foreword|dedication|solutions[parent::backmatter]|references[parent::backmatter]|index|colophon" mode="division-class">
    <xsl:text>centerpage</xsl:text>
</xsl:template>

<!-- Section and subsection is complicated, since it depends on -->
<!-- the depth.  The boolean variable is true with a depth of 4 -->
<!-- or greater, starting from "chapter".                       -->

<xsl:template match="section" mode="division-class">
    <xsl:choose>
        <xsl:when test="$b-has-subsubsection">
            <xsl:text>center</xsl:text>
        </xsl:when>
        <!-- terminal -->
        <xsl:otherwise>
            <xsl:text>cell5</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template match="subsection" mode="division-class">
    <xsl:choose>
        <xsl:when test="$b-has-subsubsection">
            <xsl:text>cell5</xsl:text>
        </xsl:when>
        <!-- terminal -->
        <xsl:otherwise>
            <xsl:text>cell7</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- terminal always, according to schema -->
<xsl:template match="subsubsection" mode="division-class">
    <xsl:text>cell7</xsl:text>
</xsl:template>

<!-- ################### -->
<!-- Environments/Blocks -->
<!-- ################### -->

<!-- Born-hidden behavior is generally configurable,  -->
<!-- but we do not want any automatic, or configured, -->
<!-- knowlization to take place.  Ever.  Never.       -->

<!-- Everything configurable by author, 2020-01-02    -->
<!-- Roughly in the order of  html.knowl.*  switches  -->
<xsl:template match="&THEOREM-LIKE;|proof|&DEFINITION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task|&FIGURE-LIKE;|&REMARK-LIKE;|&GOAL-LIKE;|exercise" mode="is-hidden">
    <xsl:text>no</xsl:text>
</xsl:template>

<!-- A hook in the HTML conversion allows for the addition of a @data-braille attribute to the "body-element".  Then liblouis can select on these values to apply the "boxline" style which delimits the blocks.  Here we define these values.  The stub in the HTML conversion does nothing (empty text) and so is a signal to not employ this attribute at all.  So a non-empty definition here also activates the attribute's existence. -->

<xsl:template match="&REMARK-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>remark-like</xsl:text>
</xsl:template>

<xsl:template match="&COMPUTATION-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>computation-like</xsl:text>
</xsl:template>

<xsl:template match="&DEFINITION-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>definition-like</xsl:text>
</xsl:template>

<xsl:template match="&ASIDE-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>aside-like</xsl:text>
</xsl:template>

<xsl:template match="&FIGURE-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>figure-like</xsl:text>
</xsl:template>

<xsl:template match="assemblage" mode="data-braille-attribute-value">
    <xsl:text>assemblage-like</xsl:text>
</xsl:template>

<xsl:template match="&GOAL-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>goal-like</xsl:text>
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>example-like</xsl:text>
</xsl:template>

<xsl:template match="&PROJECT-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>project-like</xsl:text>
</xsl:template>

<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="data-braille-attribute-value">
    <xsl:text>theorem-like</xsl:text>
</xsl:template>

<xsl:template match="proof" mode="data-braille-attribute-value">
    <xsl:text>proof</xsl:text>
</xsl:template>

<!-- Absent an implementation above, empty text signals  -->
<!-- that the @data-braille attribute is not desired.    -->
<xsl:template match="*" mode="data-braille-attribute-value"/>

<!-- The HTML conversion has a "block-data-braille-attribute" -->
<!-- hook with a no-op stub template.  Here we activate the   -->
<!-- attribute iff a non-empty value is defined above.  Why   -->
<!-- do this?  Because liblouis can only match attributes     -->
<!-- with one value, not space-separated lists like many of   -->
<!-- our @class attributes.                                   -->
<xsl:template match="*" mode="block-data-braille-attribute">
    <xsl:variable name="attr-value">
        <xsl:apply-templates select="." mode="data-braille-attribute-value"/>
    </xsl:variable>
    <xsl:if test="not($attr-value = '')">
        <xsl:attribute name="data-braille">
            <xsl:value-of select="$attr-value"/>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- ################ -->
<!-- Subsidiary Items -->
<!-- ################ -->

<!-- These tend to "hang" off other structures and/or are routinely -->
<!-- rendered as knowls.  So we turn off automatic knowlization     -->
<xsl:template match="&SOLUTION-LIKE;" mode="is-hidden">
    <xsl:text>no</xsl:text>
</xsl:template>

<!-- We extend their headings with an additional colon. -->
<!-- These render then like "Hint:" or "Hint 6:"        -->
<xsl:template match="&SOLUTION-LIKE;" mode="heading-simple">
    <xsl:apply-imports/>
    <xsl:text>:</xsl:text>
</xsl:template>

<!-- ########## -->
<!-- Sage Cells -->
<!-- ########## -->

<!-- Implementing the abstract templates gives us a lot of       -->
<!-- freedom.  We wrap in an                                     -->
<!--    article/@data-braille="sage"                             -->
<!-- with a                                                      -->
<!--    h6/@class="heading"/span/@class="type"                   -->
<!-- to get  liblouis  styling as a box and to make a heading.   -->
<!--                                                             -->
<!-- div/@data-braille="<table-filename>" is a  liblouis  device -->
<!-- to switch the translation table, and is the best we can     -->
<!-- do to make computer braille                                 -->

<xsl:template match="sage" mode="sage-active-markup">
    <xsl:param name="block-type"/>
    <xsl:param name="language-attribute" />
    <xsl:param name="in" />
    <xsl:param name="out" />
    <xsl:param name="b-original"/>

    <article data-braille="sage">
        <h6 class="heading">
            <span class="type">Sage</span>
        </h6>

        <!-- code marker is literary, not computer braille -->
        <p>Input:</p>
        <div sage-code="en-us-comp6.ctb">
            <xsl:choose>
                <xsl:when test="$in = ''">
                    <!-- defensive, prevents HTML processing  -->
                    <!-- writing non-XML for an empty element -->
                    <xsl:text>&#xa0;&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$in"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
        <xsl:if test="not($out = '')">
            <!-- code marker is literary, not computer braille -->
            <p>Output:</p>
            <div sage-code="en-us-comp6.ctb">
                <xsl:value-of select="$out" />
            </div>
        </xsl:if>
    </article>
</xsl:template>

<xsl:template name="sage-display-markup">
    <xsl:param name="block-type"/>
    <xsl:param name="in" />

    <article data-braille="sage">
        <h6 class="heading">
            <span class="type">Sage</span>
        </h6>
        <!-- code marker is literary, not computer braille -->
        <p>Input:</p>
        <div sage-code="en-us-comp6.ctb">
            <xsl:choose>
                <xsl:when test="$in = ''">
                    <!-- defensive, prevents HTML processing  -->
                    <!-- writing non-XML for an empty element -->
                    <xsl:text>&#xa0;&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$in"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </article>
</xsl:template>


<!-- ###################### -->
<!-- Paragraph-Level Markup -->
<!-- ###################### -->

<!-- Certain PreTeXt elements create characters beyond the -->
<!-- "usual" Unicode range of U+0000-U+00FF.  We defer the -->
<!-- translation to the "pretext-symbol.dis" file which    -->
<!-- liblouis  will consult for characters/code-points it  -->
<!-- does not recognize.  We make notes here, but the file -->
<!-- should be consulted for accurate information.         -->

<!-- PTX: ldblbracket, rdblbracket, dblbrackets     -->
<!-- Unicode:                                       -->
<!-- MATHEMATICAL LEFT WHITE SQUARE BRACKET, x27e6  -->
<!-- MATHEMATICAL RIGHT WHITE SQUARE BRACKET, x27e7 -->
<!-- Translation:  [[, ]]                           -->


<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Nemeth indicator use described in:            -->
<!-- Braille Authority of North America (BANA),    -->
<!-- "Guidance for Transcription Using the Nemeth  -->
<!-- Code within UEB Contexts Revised", April 2018 -->
<!-- Hereafter "BANA Nemeth Guidance"              -->

<!-- BANA Nemeth Guidance quotes "Rules of Unified English Braille 2013" -->
<!--                                                                     -->
<!-- 14.6 Nemeth Code within UEB text                                    -->
<!--                                                                     -->
<!-- 14.6.1 When technical material is transcribed according to the      -->
<!-- provisions of The Nemeth Braille Code for Mathematics and Science   -->
<!-- Notation within UEB text, the following sections provide for        -->
<!-- switching between UEB and Nemeth Code.                              -->
<!--                                                                     -->
<!-- 14.6.2 Place the opening Nemeth Code indicator followed by a        -->
<!-- space before the sequence to which it applies. Its effect is        -->
<!-- terminated by the Nemeth Code terminator preceded by a space.       -->
<!-- Note: The spaces required with the indicator and the terminator     -->
<!-- do not represent spaces in print.                                   -->
<!--                                                                     -->
<!-- 14.6.3 When the Nemeth Code text is displayed on one or more lines  -->
<!-- separate from the UEB text, the opening Nemeth Code indicator and   -->
<!-- the Nemeth Code terminator may each be placed on a line by itself   -->
<!-- or at the end of the previous line of text.                         -->

<!-- Opening Nemeth Code indicator -->
<!-- _%,  4-5-6 1-4-6,  x5f x25    -->
<!-- always followed by a space    -->
<!-- technically a UEB symbol      -->
<xsl:template name="open-nemeth">
    <!-- <xsl:text>&#x5f;&#x25; </xsl:text> -->
    <xsl:text>&#x2838;&#x2829;&#x20;</xsl:text>
</xsl:template>

<!-- Nemeth Code terminator      -->
<!-- _:,  4-5-6 1-5-6,  x5f x3a  -->
<!-- always preceded by a space  -->
<!-- technically a Nemeth symbol -->
<xsl:template name="close-nemeth">
    <xsl:text>&#x20;&#x2838;&#x2831;</xsl:text>
</xsl:template>

<!-- Single-word switch indicator ,' -->

<!-- ################## -->
<!-- Inline Mathematics -->
<!-- ################## -->

<!-- We place the Nemeth open/close symbols via   -->
<!-- import of the base HTML/LaTeX representation -->
<xsl:template match="m">
    <!-- we look for very simple math (one-letter variable names) -->
    <!-- so we process the content (which can have "xref", etc)   -->
    <xsl:variable name="content">
        <xsl:apply-templates select="*|text()"/>
    </xsl:variable>
    <xsl:choose>
        <!-- one Latin letter -->
        <xsl:when test="(string-length($content) = 1) and
                        contains('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', $content)">
            <i class="one-letter">
                <xsl:value-of select="."/>
            </i>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-imports/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################### -->
<!-- Display Mathematics -->
<!-- ################### -->


<!-- For single-line math we preserve the  div.displaymath -->
<!-- which we can use to initiate a new line via liblouis. -->
<!-- We also append the tag.  None of this is much tested  -->
<!-- for "md" and "mdn".                                   -->

<xsl:template name="display-math-visual-blank-line"/>

<!-- We add the tag *after* the produced LaTeX environment, but *before* the liblouis-controlled div.displaymath ends, so the tag is on the same line. -->
<xsl:template match="me|men|md|mdn" mode="display-math-wrapper">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="content" />
    <div class="displaymath">
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:copy-of select="$content" />
        <xsl:if test="self::men">
            <xsl:text>&#x20;(</xsl:text>
            <xsl:apply-templates select="." mode="number"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
    </div>
</xsl:template>

<!-- Tags for "men" are accomodated above, so we kill the -->
<!-- usual LaTeX/MathJax routine which employs \tag{}     -->
<xsl:template match="men" mode="tag"/>

<!-- BANA Nemeth Guidance: "All other text, including -->
<!-- punctuation that is logically associated with    -->
<!-- surrounding sentences, should be done in UEB."   -->
<!-- So we do not move "clause-ending punctuation,"   -->
<!-- and we just put it back in place.  ;-)           -->

<!-- Do not grab/use "clause-ending punctuation" -->
<xsl:template match="*" mode="get-clause-punctuation"/>

<!-- Xerox $text, effectively *not* removing any punctuation. -->
<xsl:template name="drop-clause-punctuation">
    <xsl:param name="text" />
    <xsl:value-of select="$text" />
</xsl:template>

<!-- Hack: treat md/mrow as a sequence of me and remove      -->
<!-- alignment points.  This is an experiment at this point, -->
<!-- it has flaws and has not been thoroughly tested.        -->

<xsl:template match="md|mdn" mode="body">
    <!-- block-type parameter is ignored, since the          -->
    <!-- representation never varies, no heading, no wrapper -->
    <xsl:param name="block-type" />
    <!-- If original content, or a duplication -->
    <xsl:param name="b-original" select="true()" />
    <!-- If the only content of a knowl ("men") then we  -->
    <!-- do not include adjacent (trailing) punctuation, -->
    <!-- since it is meaningless                         -->
    <xsl:param name="b-top-level" select="false()" />
    <!-- Look across all mrow for 100% no-number rows              -->
    <!-- This just allows for slightly nicer human-readable source -->
    <xsl:variable name="b-nonumbers" select="self::md and not(mrow[@number='yes' or @tag])" />
    <xsl:variable name="complete-latex">
        <xsl:apply-templates select="mrow|intertext" />
    </xsl:variable>
    <xsl:value-of select="$complete-latex" />
</xsl:template>

<xsl:template match="mrow">
    <xsl:variable name="aligned-row">
        <xsl:apply-imports/>
    </xsl:variable>
    <xsl:variable name="unaligned" select="translate($aligned-row, '&amp;', '')"/>
    <!-- there is also a "max-ampersands" template that could be used in the "md" template -->
    <!-- <xsl:message>Amps: <xsl:value-of select="string-length($aligned-row) - string-length(translate($aligned-row, '&amp;', ''))"/></xsl:message> -->
    <xsl:call-template name="open-nemeth"/>
    <xsl:text>\begin{equation*}&#xa;</xsl:text>
        <xsl:value-of select="$unaligned"/>
    <xsl:text>\end{equation*}&#xa;</xsl:text>
    <xsl:call-template name="close-nemeth"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- This is just a device for LaTeX conversion -->
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

<!-- ########## -->
<!-- Paragraphs -->
<!-- ########## -->

<!-- We do not worry about lists, display math, or code  -->
<!-- displays which PreTeXt requires inside paragraphs.  -->
<!-- Especially since the pipeline corrects this anyway. -->
<!-- NB: see p[1] modified in "paragraphs" elsewhere     -->

<!-- ########## -->
<!-- Quotations -->
<!-- ########## -->

<!-- liblouis recognizes the single/double, left/right -->
<!-- smart quotes so we just let wander in from the    -->
<!-- standard HTML conversion, covering the elements:  -->
<!--                                                   -->
<!--   Characters: "lq", "rq", "lsq", "rsq"            -->
<!--   Grouping: "q", "sq"                             -->

<!-- http://www.dotlessbraille.org/aposquote.htm -->

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Preliminary: be sure to notate HTML with regard to override -->
<!-- here.  Template will help locate for subsequent work.       -->
<!-- <xsl:template match="ol/li|ul/li|var/li" mode="body">       -->

<xsl:template match="ol|ul|dl">
    <xsl:copy>
        <xsl:attribute name="class">
            <xsl:text>outerlist</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="li"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="ol/li" mode="body">
    <li>
        <xsl:apply-templates select="." mode="item-number"/>
        <xsl:text>. </xsl:text>
        <xsl:apply-templates/>
    </li>
</xsl:template>

<xsl:template match="ul/li" mode="body">
    <xsl:variable name="format-code">
        <xsl:apply-templates select="parent::ul" mode="format-code"/>
    </xsl:variable>
    <li>
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
        <!-- and the contents -->
        <xsl:apply-templates/>
    </li>
</xsl:template>

<xsl:template match="dl">
    <dl class="outerlist">
        <xsl:apply-templates select="li"/>
    </dl>
</xsl:template>

<xsl:template match="dl/li">
    <li class="description">
        <b>
            <xsl:apply-templates select="." mode="title-full"/>
        </b>
        <xsl:apply-templates/>
    </li>
</xsl:template>


<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- We write a paragraph with the "description"  -->
<!-- (authored as a bare string of sorts) and a   -->
<!-- paragraph with our internal id, which is the -->
<!-- basis of a filename that would be used to    -->
<!-- construct any tactile versions.              -->
<xsl:template match="image">
    <div data-braille="image">
        <p>
            <xsl:text>Image: </xsl:text>
            <xsl:apply-templates select="description"/>
        </p>
        <p>
            <xsl:text>ID: </xsl:text>
            <xsl:apply-templates select="." mode="visible-id" />
        </p>
    </div>
</xsl:template>

</xsl:stylesheet>