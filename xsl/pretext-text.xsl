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
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
>

<!-- Standard conversion groundwork -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- This is a conversion to "plain" text.  Upon initiation it is mainly -->
<!-- meant as a foundation for various simple conversions to things like -->
<!-- doctests or JSON table-of-contents.  But it is designed as a "real" -->
<!-- conversion.  But obviously, there are many PreTeXt constructions    -->
<!-- which cannot be realized in text.                                   -->
<!--                                                                     -->
<!-- Goal is to make it so *no* conversion imports "pretext-common.xsl" -->
<!-- since some foundational conversion (such as this one) can be the    -->
<!-- basis of the conversion and will import the foundationa one instead.-->
<!--                                                                     -->
<!-- Initial work might be to implement certain characters as 7-bit      -->
<!-- ASCII and as Unicode, under the control of a switch.  For example,  -->
<!-- the "q" element could have dumb generic quotes or smart left and    -->
<!-- right quotes.                                                       -->

<xsl:output method="text"/>

<!-- Elect the absorption of clause-ending punctuation into      -->
<!-- display mathematics (only), where our templates re-place it -->
<!-- on the final row; inline mathematics keeps its punctuation  -->
<!-- in the prose, where it reads naturally.                     -->
<xsl:param name="math.punctuation.include" select="'display'"/>

<!-- if chunking, this is the extension of the files produced -->
<xsl:variable name="file-extension" select="'.txt'"/>


<!-- Entry Template -->
<!-- Kickstart the process, ignore "docinfo"  -->
<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Conversion to simple text is incomplete&#xa;But importing this stylesheet could be helpful for certain purposes&#xa;Override the entry template to make this warning go away</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="$document-root"/>
</xsl:template>

<!-- TEMPORARY: defined to stop errors, need stubs in -common -->
<xsl:template name="inline-warning"/>
<xsl:template name="margin-warning"/>
<xsl:template match="sage" mode="sage-active-markup"/>
<xsl:template name="sage-display-markup"/>

<!-- ######### -->
<!-- Divisions -->
<!-- ######### -->

<!-- A heading is the division's usual "Type Number Title" line,     -->
<!-- underlined in the manner of typewritten manuscripts (and,       -->
<!-- happily, of markdown's setext headings for the top two          -->
<!-- levels): one underline character per depth.                     -->
<xsl:variable name="heading-underline-characters" select="'=-~^&quot;'"/>

<xsl:template match="part|chapter|appendix|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|exercises|reading-questions|worksheet|handout|glossary|references|solutions">
    <!-- the heading line, assembled once so it can be measured.    -->
    <!-- Unnumbered peripheral divisions (preface, colophon, ...)   -->
    <!-- take just their title: the default title IS the type-name, -->
    <!-- and "Preface Preface" serves nobody.                       -->
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:variable>
    <xsl:variable name="heading">
        <xsl:if test="not($the-number = '')">
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <!-- Title is required (or default is supplied) -->
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:variable>
    <!-- depth chooses the underline character; anything deeper  -->
    <!-- than the repertoire reuses the last character           -->
    <xsl:variable name="raw-level">
        <xsl:apply-templates select="." mode="level"/>
    </xsl:variable>
    <xsl:variable name="level">
        <xsl:choose>
            <xsl:when test="$raw-level &gt; 5">
                <xsl:text>5</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$raw-level"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- empty line prior -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="$heading"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="str:padding(string-length($heading), substring($heading-underline-characters, $level, 1))"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
    <!-- metadata-ish, eg "title", should be killed by default -->
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- The document itself: its title as the topmost heading, then  -->
<!-- the content.  ("docinfo" is ignored by the entry template.)  -->
<xsl:template match="book|article">
    <xsl:variable name="heading">
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:variable>
    <xsl:value-of select="$heading"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="str:padding(string-length($heading), '*')"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Whole-document containers with no heading of their own -->
<xsl:template match="frontmatter|backmatter|mainmatter">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- The title page is mined for a byline, rather than templates -->
<xsl:template match="titlepage">
    <xsl:for-each select="../../docinfo/../frontmatter/bibinfo/author/personname">
        <xsl:apply-templates/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
</xsl:template>

<!-- Bibliographic metadata: quiet, mined above -->
<xsl:template match="bibinfo"/>

<!-- Unstructured containers: just their content -->
<xsl:template match="introduction|conclusion|statement|paragraphs|subexercises|exercisegroup">
    <xsl:if test="title">
        <xsl:text>&#xa;</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Nothing fancy (like in LaTeX conversion) for  -->
<!-- the number of the target of a cross-reference -->
<xsl:template match="*" mode="xref-number">
    <xsl:apply-templates select="." mode="number"/>
</xsl:template>

<!-- No good way to link/direct to target, so we just   -->
<!-- parrot the text produced typically for a clickable -->
<xsl:template match="xref" mode="xref-link">
    <xsl:param name="target"/>
    <xsl:param name="content"/>

    <xsl:value-of select="$content"/>
</xsl:template>

<!-- ########## -->
<!-- Characters -->
<!-- ########## -->

<!-- Each character element renders per the publication file's       -->
<!-- character repertoire: a genuine Unicode character, or a 7-bit   -->
<!-- ASCII stand-in in the long plain-text tradition.  The file is   -->
<!-- UTF-8 either way; with the "ascii" election that fact is        -->
<!-- invisible.  ($b-text-unicode arrives from the publication       -->
<!-- machinery; "unicode" is the default.)                           -->

<!-- TODO: quotation marks should localize by language in the        -->
<!-- unicode repertoire, as other conversions do.                    -->

<xsl:template name="nbsp-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xa0;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="ndash-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2013;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>-</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="mdash-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2014;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>--</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The abstract template for "mdash" consults a publisher option -->
<!-- for thin space, or no space, surrounding an em-dash.  So the  -->
<!-- "thin-space-character" is needed for that purpose, and does   -->
<!-- not have an associated empty PTX element.                     -->
<xsl:template name="thin-space-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2009;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="lsq-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2018;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>'</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="rsq-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2019;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>'</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="lq-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x201C;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>"</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="rq-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x201D;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>"</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="ellipsis-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2026;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>...</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="copyright-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xa9;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>(c)</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="registered-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xae;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>(R)</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="trademark-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2122;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>(TM)</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="degree-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xb0;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>deg</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="prime-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2032;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>'</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="dblprime-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2033;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>''</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="langle-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x27e8;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>&lt;</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="rangle-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x27e9;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>&gt;</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="midpoint-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xb7;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>*</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="pilcrow-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xb6;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>[pilcrow]</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="section-mark-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xa7;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>[section]</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="minus-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2212;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>-</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="times-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xd7;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>x</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="obelus-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xf7;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>/</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="plusminus-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#xb1;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>+/-</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="permille-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2030;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>o/oo</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="solidus-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2044;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>/</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="swungdash-character">
    <xsl:choose>
        <xsl:when test="$b-text-unicode"><xsl:text>&#x2053;</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>~</xsl:text></xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- Mathematics never renders in plain text: throughout this     -->
<!-- section the output is the LaTeX an author wrote, verbatim,   -->
<!-- with no processor in prospect.                               -->

<!-- LaTeX is the lingua franca of plain-text mathematics, so     -->
<!-- authored LaTeX rides along verbatim between dollar signs.    -->
<!-- Two simple cases need no dressing at all: a single Latin     -->
<!-- letter (a variable name), and an integer.  (The same         -->
<!-- analysis the braille conversion performs.)                   -->
<xsl:template name="inline-math-wrapper">
    <xsl:param name="math"/>
    <xsl:variable name="clean" select="normalize-space($math)"/>
    <xsl:choose>
        <xsl:when test="(string-length($clean) = 1) and contains(&ALPHABET;, $clean)">
            <xsl:value-of select="$clean"/>
        </xsl:when>
        <xsl:when test="not($clean = '') and (translate($clean, &DIGIT;, '') = '')">
            <xsl:value-of select="$clean"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>$</xsl:text>
            <xsl:value-of select="$clean"/>
            <xsl:text>$</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Display mathematics: set off by blank lines, each row       -->
<!-- indented, LaTeX verbatim.  Alignment marks and such are     -->
<!-- part of the mathematics and remain.                         -->
<xsl:template match="md">
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="mrow|intertext"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="md[not(mrow)]">
    <xsl:text>&#xa;    </xsl:text>
    <xsl:value-of select="normalize-space(text())"/>
    <!-- clause-ending punctuation absorbed by the display, restored -->
    <xsl:apply-templates select="." mode="get-clause-punctuation-mark"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="mrow">
    <xsl:text>    </xsl:text>
    <xsl:value-of select="normalize-space(.)"/>
    <!-- the display's absorbed punctuation lands on the last row -->
    <xsl:if test="not(following-sibling::mrow)">
        <xsl:apply-templates select="parent::md" mode="get-clause-punctuation-mark"/>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="md/intertext">
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ################# -->
<!-- Prose Text Nodes  -->
<!-- ################# -->

<!-- Authors hard-wrap and indent their source; none of that      -->
<!-- belongs in the output.  -common's "text()" template handles  -->
<!-- punctuation migration and whitespace at the edges of nodes,  -->
<!-- and offers this hook for conversion-specific processing:     -->
<!-- every interior newline (with the indentation following it)   -->
<!-- collapses to a single space, so a paragraph becomes one long -->
<!-- line, ready for any pager to soft-wrap.  The workhorse,      -->
<!-- "flatten-line-breaks", lives with the text utilities.        -->
<xsl:template name="text-processing">
    <xsl:param name="text"/>
    <xsl:call-template name="flatten-line-breaks">
        <xsl:with-param name="text" select="$text"/>
    </xsl:call-template>
</xsl:template>

<xsl:template match="p">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- mixed-content -->
    <xsl:apply-templates/>
    <!-- end onto a newline -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Environments -->
<!-- ############ -->

<!-- A block's heading sits on its own line, set off from the   -->
<!-- content by a blank line; the markdown flavor overrides to  -->
<!-- embolden it                                                -->
<xsl:template name="block-heading-line">
    <xsl:param name="heading"/>
    <xsl:copy-of select="$heading"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- The heading line of a block: type, number when there is one, -->
<!-- a parenthesized creator for the theorem-like and axiom-like, -->
<!-- title when there is one                                      -->
<xsl:template match="*" mode="block-heading">
    <xsl:call-template name="block-heading-line">
        <xsl:with-param name="heading">
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:variable name="the-number">
                <xsl:apply-templates select="." mode="number"/>
            </xsl:variable>
            <xsl:if test="not($the-number = '')">
                <xsl:text> </xsl:text>
                <xsl:value-of select="$the-number"/>
            </xsl:if>
            <xsl:if test="creator and (&THEOREM-FILTER; or &AXIOM-FILTER;)">
                <xsl:text> (</xsl:text>
                <xsl:apply-templates select="." mode="creator-full"/>
                <xsl:text>)</xsl:text>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="title">
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="." mode="title-full"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>.</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="&REMARK-LIKE;|&DEFINITION-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|&GOAL-LIKE;|assemblage">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="block-heading"/>
    <!-- structured -->
    <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="&PROJECT-LIKE;|&OPENPROBLEM-LIKE;">
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="block-heading"/>
    <xsl:apply-templates select="introduction|statement|task|conclusion|&SOLUTION-LIKE;"/>
</xsl:template>

<xsl:template match="task">
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>.</xsl:text>
    <xsl:if test="title">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::title)]"/>
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="block-heading"/>
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="&SOLUTION-LIKE;"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*[not(self::title)]"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="&THEOREM-LIKE;">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="block-heading"/>
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="&PROOF-LIKE;"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- THEOREM-LIKE only -->
<xsl:template match="&PROOF-LIKE;">
    <!-- set off from a preceding statement -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:call-template name="block-heading-line">
        <xsl:with-param name="heading">
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text>.</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <!-- structured -->
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- ######### -->
<!-- Exercises -->
<!-- ######### -->

<!-- An inline exercise (a "Checkpoint") reads as a block, with  -->
<!-- the full heading treatment; a divisional exercise keeps its -->
<!-- run-in serial number below, reading as a numbered item      -->
<xsl:template match="exercise[&INLINE-EXERCISE-FILTER;]">
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="block-heading"/>
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="&SOLUTION-LIKE;"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*[self::hint|self::answer|self::solution]"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="exercise">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>.</xsl:text>
    <xsl:if test="title">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text> </xsl:text>
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="&SOLUTION-LIKE;"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="*[self::hint|self::answer|self::solution]"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="&SOLUTION-LIKE;">
    <!-- set off from a preceding statement -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:call-template name="block-heading-line">
        <xsl:with-param name="heading">
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:variable name="the-number">
                <xsl:apply-templates select="." mode="non-singleton-number" />
            </xsl:variable>
            <!-- An empty value means element is a singleton -->
            <!-- else the serial number comes through        -->
            <xsl:if test="not($the-number = '')">
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="." mode="serial-number" />
            </xsl:if>
            <xsl:text>.</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- ############### -->
<!-- Captioned Items -->
<!-- ############### -->

<xsl:template match="figure">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number"/>
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="caption"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="caption">
    <!-- mixed-content -->
    <xsl:apply-templates/>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<xsl:template match="ul|ol|dl">
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="li"/>
</xsl:template>

<xsl:template match="ol/li">
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>. </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul/li">
    <xsl:text>* </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="dl/li">
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
