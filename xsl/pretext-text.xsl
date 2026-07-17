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
<!-- Kickstart the process, ignore "docinfo".  A positive chunk  -->
<!-- level (the common election) writes a tree of files instead  -->
<!-- of a single stream; see the Chunking section below.         -->
<xsl:template match="/">
    <xsl:choose>
        <xsl:when test="$chunk-level &gt; 0">
            <xsl:apply-templates select="$document-root" mode="chunking"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="$document-root"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- TEMPORARY: defined to stop errors, need stubs in -common -->
<xsl:template name="inline-warning"/>
<xsl:template name="margin-warning"/>

<!-- ################ -->
<!-- Producer's Notes -->
<!-- ################ -->

<!-- Content that text cannot express is announced, not dropped:  -->
<!-- a bracketed note with a localized label, a fixed convention  -->
<!-- a reader (or a consuming program) can recognize and strip.   -->
<xsl:template name="producer-note">
    <xsl:param name="message"/>
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="type-name">
        <xsl:with-param name="string-id" select="'note'"/>
    </xsl:apply-templates>
    <xsl:text>: </xsl:text>
    <xsl:copy-of select="$message"/>
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Structured lines ("department", "attribution", a "cell" of  -->
<!-- "line") break onto new lines; -common's default is a        -->
<!-- "[LINESEP]" marker demanding this implementation            -->
<xsl:template name="line-separator">
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Macro definitions preceding a page's mathematics: nothing -->
<!-- in plain text (the mathematics is authored LaTeX, macros  -->
<!-- and all), realized by the markdown flavor for renderers   -->
<xsl:template match="*" mode="latex-macros"/>

<!-- ######## -->
<!-- Verbatim -->
<!-- ######## -->

<!-- A verbatim block: contents on their own lines, every line    -->
<!-- indented four spaces (which is set-off in plain text, and    -->
<!-- happens to be a code block in markdown).  A caller may       -->
<!-- extend the indentation, say with a prompt.                   -->
<xsl:template name="verbatim-block">
    <xsl:param name="content"/>
    <xsl:param name="indent" select="'    '"/>
    <!-- the blank line preceding the block; a caller abutting -->
    <!-- two blocks (Sage input, output) empties the second's  -->
    <xsl:param name="lead" select="'&#xa;'"/>
    <xsl:variable name="sanitized">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="$content"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$lead"/>
    <xsl:call-template name="add-indentation">
        <xsl:with-param name="text" select="$sanitized"/>
        <xsl:with-param name="indent" select="$indent"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="pre">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="interior"/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="cd">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:choose>
                <xsl:when test="cline">
                    <xsl:apply-templates select="cline"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="program">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:value-of select="code"/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="console">
    <xsl:apply-templates select="input|output"/>
</xsl:template>

<xsl:template match="console/input">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:value-of select="../@prompt"/>
            <xsl:value-of select="."/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="console/output">
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content">
            <xsl:value-of select="."/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Input carries a prompt on every line, named for the cell's -->
<!-- language (Sage by default) in the manner of a session, so  -->
<!-- it reads apart from the bare output, which follows after a -->
<!-- single blank line                                          -->
<xsl:template match="sage" mode="sage-active-markup">
    <xsl:param name="in"/>
    <xsl:param name="out"/>
    <xsl:variable name="the-language">
        <xsl:choose>
            <xsl:when test="@language">
                <xsl:value-of select="@language"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>sage</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content" select="$in"/>
        <xsl:with-param name="indent" select="concat('    ', $the-language, ': ')"/>
    </xsl:call-template>
    <xsl:if test="not($out = '')">
        <xsl:call-template name="verbatim-block">
            <xsl:with-param name="content" select="$out"/>
            <xsl:with-param name="lead" select="''"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template name="sage-display-markup">
    <xsl:param name="in"/>
    <xsl:call-template name="verbatim-block">
        <xsl:with-param name="content" select="$in"/>
    </xsl:call-template>
</xsl:template>

<!-- ##### -->
<!-- Media -->
<!-- ##### -->

<!-- An image is its author-provided description; failing that, a  -->
<!-- note that an image was here                                   -->
<xsl:template match="image">
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="producer-note">
        <xsl:with-param name="message">
            <xsl:choose>
                <xsl:when test="shortdescription">
                    <xsl:apply-templates select="shortdescription"/>
                </xsl:when>
                <xsl:when test="description">
                    <xsl:apply-templates select="description"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>an image, undescribed by its author</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="shortdescription|description">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="video|audio|interactive|slate">
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="producer-note">
        <xsl:with-param name="message">
            <xsl:text>a </xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text> element is not realizable in this format</xsl:text>
            <xsl:if test="@source|@href">
                <xsl:text>; see </xsl:text>
                <xsl:value-of select="@source|@href"/>
            </xsl:if>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- A side-by-side is announced, its panels appear in sequence -->
<xsl:template match="sidebyside">
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="producer-note">
        <xsl:with-param name="message">
            <xsl:text>the following </xsl:text>
            <xsl:value-of select="count(*)"/>
            <xsl:text> elements are arranged side-by-side in other formats</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- A group announces itself, with each member's panel count -->
<xsl:template match="sbsgroup">
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="producer-note">
        <xsl:with-param name="message">
            <xsl:text>the following is a group of </xsl:text>
            <xsl:value-of select="count(sidebyside)"/>
            <xsl:text> side-by-side with </xsl:text>
            <xsl:for-each select="sidebyside">
                <xsl:value-of select="count(*)"/>
                <xsl:if test="following-sibling::sidebyside">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text> panels respectively</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="sidebyside"/>
</xsl:template>

<!-- ######### -->
<!-- Footnotes -->
<!-- ######### -->

<!-- A numbered mark in place; the text collects at the end of  -->
<!-- the division (see the division template)                   -->
<xsl:template match="fn">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>]</xsl:text>
</xsl:template>

<xsl:template match="fn" mode="collected">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>] </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ####### -->
<!-- Tabular -->
<!-- ####### -->

<!-- Modest: each row a line, cells separated by double spaces.   -->
<!-- No column alignment (yet), spanning cells simply run in.     -->
<xsl:template match="tabular">
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="row"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="row">
    <xsl:text>    </xsl:text>
    <xsl:for-each select="cell">
        <xsl:apply-templates/>
        <xsl:if test="following-sibling::cell">
            <xsl:text>  </xsl:text>
        </xsl:if>
    </xsl:for-each>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ###### -->
<!-- Poetry -->
<!-- ###### -->

<xsl:template match="poem">
    <xsl:text>&#xa;</xsl:text>
    <xsl:if test="title">
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="stanza"/>
</xsl:template>

<xsl:template match="stanza">
    <xsl:apply-templates select="line"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="stanza/line">
    <xsl:text>    </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- #### -->
<!-- URLs -->
<!-- #### -->

<!-- visible text (when there is some), address in angle brackets -->
<xsl:template match="url">
    <xsl:choose>
        <xsl:when test="node()">
            <xsl:apply-templates/>
            <xsl:text> &lt;</xsl:text>
            <xsl:value-of select="@href"/>
            <xsl:text>&gt;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="@href"/>
            <xsl:text>&gt;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ##### -->
<!-- Index -->
<!-- ##### -->

<!-- An "idx" element is invisible where it is authored; the index -->
<!-- machinery of -common mines them all to manufacture the index  -->
<!-- division, which renders through the presentation templates    -->
<!-- below (modeled on the -fo implementations).                   -->
<xsl:template match="idx"/>

<!-- the assembled index needs no wrapper -->
<xsl:template name="present-index">
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- a blank line separates letter groups -->
<xsl:template name="present-letter-group">
    <xsl:param name="the-index-list"/>
    <xsl:param name="letter-group"/>
    <xsl:param name="current-letter"/>
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- one line of the index: two spaces of indentation per level -->
<!-- of subentry, locators trailing the deepest heading         -->
<xsl:template name="present-index-heading">
    <xsl:param name="the-index-list"/>
    <xsl:param name="heading-group"/>
    <xsl:param name="b-write-locators"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="content"/>
    <xsl:value-of select="str:padding(2 * ($heading-level - 1), ' ')"/>
    <xsl:copy-of select="$content"/>
    <xsl:if test="$b-write-locators">
        <xsl:call-template name="locator-list">
            <xsl:with-param name="the-index-list" select="$the-index-list"/>
            <xsl:with-param name="heading-group" select="$heading-group"/>
            <xsl:with-param name="cross-reference-separator" select="', '"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- the pieces of a locator: processed content suffices -->
<xsl:template name="present-index-locator">
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<xsl:template name="present-index-see">
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<xsl:template name="present-index-see-also">
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- italics for a "see" word: plain text has no italics -->
<xsl:template name="present-index-italics">
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- One locator: climb from the "idx" to the nearest enclosure   -->
<!-- that is structural or a block AND has a number (the HTML     -->
<!-- conversion's approach; there are no page numbers to cite),   -->
<!-- then present it through the "index-locator" flavor template  -->
<xsl:template match="index-list" mode="index-enclosure">
    <xsl:param name="enclosure"/>
    <xsl:variable name="structural">
        <xsl:apply-templates select="$enclosure" mode="is-structural"/>
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="$enclosure" mode="is-block"/>
    </xsl:variable>
    <xsl:variable name="the-number">
        <xsl:if test="($structural = 'true') or ($block = 'true')">
            <xsl:apply-templates select="$enclosure" mode="number"/>
        </xsl:if>
    </xsl:variable>
    <xsl:choose>
        <!-- climbed past the document root (an "idx" in an unnumbered  -->
        <!-- peripheral of the root): the type of the root must suffice -->
        <xsl:when test="not($enclosure)">
            <xsl:apply-templates select="$document-root" mode="type-name"/>
        </xsl:when>
        <xsl:when test="not($the-number = '')">
            <xsl:apply-templates select="." mode="index-locator">
                <xsl:with-param name="enclosure" select="$enclosure"/>
                <xsl:with-param name="the-number" select="$the-number"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- climb; the "index-list" context rides along -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="index-enclosure">
                <xsl:with-param name="enclosure" select="$enclosure/parent::*"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- "Theorem 2.1", "Section 3": the type announces what the -->
<!-- number leads to; the markdown flavor adds the link      -->
<xsl:template match="index-list" mode="index-locator">
    <xsl:param name="enclosure"/>
    <xsl:param name="the-number"/>
    <xsl:apply-templates select="$enclosure" mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$the-number"/>
</xsl:template>

<!-- Hooks for generated lists (list of figures, etc.): the  -->
<!-- entries suffice, no surrounding apparatus               -->
<xsl:template name="list-of-begin"/>
<xsl:template name="list-of-end"/>

<!-- ############ -->
<!-- Bibliography -->
<!-- ############ -->

<!-- Font modes required by -common's bibliography machinery.    -->
<!-- Plain text has no fonts: content rides through unadorned.   -->
<!-- (The markdown conversion overrides these with emphasis.)    -->
<xsl:template match="*" mode="italic">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="*" mode="bold">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="*" mode="monospace">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template name="biblio-period">
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- Literal code phrases ("c") funnel through this wrapper;   -->
<!-- plain text passes the content through unadorned.  (The    -->
<!-- markdown conversion overrides with backtick spans.)       -->
<xsl:template name="code-wrapper">
    <xsl:param name="content"/>
    <xsl:copy-of select="$content"/>
</xsl:template>

<!-- Every bibliography flavor funnels through this wrapper in    -->
<!-- -common: a bracketed number, then the entry's content        -->
<xsl:template match="biblio" mode="bibentry-wrapper">
    <xsl:param name="content"/>
    <xsl:if test="preceding-sibling::biblio">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>] </xsl:text>
    <xsl:copy-of select="$content"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ######### -->
<!-- Divisions -->
<!-- ######### -->

<!-- A heading is the division's usual "Type Number Title" line,     -->
<!-- underlined in the manner of typewritten manuscripts (and,       -->
<!-- happily, of markdown's setext headings for the top two          -->
<!-- levels): one underline character per depth.                     -->
<xsl:variable name="heading-underline-characters" select="'=-~^&quot;'"/>

<!-- The text of a heading: "Type Number Title".                -->
<!-- Unnumbered peripheral divisions (preface, colophon, ...)   -->
<!-- take just their title: the default title IS the type-name, -->
<!-- and "Preface Preface" serves nobody.                       -->
<xsl:template match="*" mode="heading-text">
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$the-number"/>
        <xsl:text> </xsl:text>
    </xsl:if>
    <!-- Title is required (or default is supplied) -->
    <xsl:apply-templates select="." mode="title-full"/>
</xsl:template>

<!-- The heading and its underline, assembled once so the -->
<!-- heading can be measured                               -->
<xsl:template match="*" mode="heading-lines">
    <xsl:variable name="heading">
        <xsl:apply-templates select="." mode="heading-text"/>
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
</xsl:template>

<!-- Footnotes belonging to a division (and not to a deeper -->
<!-- one) collect at its end                                -->
<xsl:template match="*" mode="division-footnotes">
    <xsl:variable name="the-notes" select=".//fn[count(ancestor::*[&STRUCTURAL-FILTER;][1]|current()) = 1]"/>
    <xsl:if test="$the-notes">
        <xsl:text>&#xa;</xsl:text>
        <xsl:apply-templates select="$the-notes" mode="collected"/>
    </xsl:if>
</xsl:template>

<xsl:template match="part|chapter|appendix|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|exercises|reading-questions|worksheet|handout|glossary|references|solutions|index">
    <xsl:apply-templates select="." mode="heading-lines"/>
    <!-- metadata-ish, eg "title", should be killed by default -->
    <xsl:apply-templates select="*"/>
    <xsl:apply-templates select="." mode="division-footnotes"/>
</xsl:template>

<!-- The document itself: its title as the topmost heading, then  -->
<!-- the content.  ("docinfo" is ignored by the entry template.)  -->
<xsl:template match="book|article" mode="heading-lines">
    <xsl:variable name="heading">
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:variable>
    <xsl:value-of select="$heading"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="str:padding(string-length($heading), '*')"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="book|article">
    <xsl:apply-templates select="." mode="heading-lines"/>
    <xsl:apply-templates select="." mode="latex-macros"/>
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- Whole-document containers with no heading of their own -->
<xsl:template match="frontmatter|backmatter|mainmatter">
    <xsl:apply-templates select="*"/>
</xsl:template>

<!-- ######## -->
<!-- Chunking -->
<!-- ######## -->

<!-- The common election (common/chunking/@level in the publication -->
<!-- file): a positive level writes each division at that depth as  -->
<!-- its own file, driven by the generic chunking machinery of      -->
<!-- -common.  No election produces the document as a single file.  -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk-level-entered != ''">
            <xsl:value-of select="$chunk-level-entered"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Every chunk of a chunked build, in reading order, each known -->
<!-- by its (unique) filename: the basis of each file's           -->
<!-- navigation line                                              -->
<xsl:variable name="chunk-list-rtf">
    <xsl:if test="$chunk-level &gt; 0">
        <xsl:for-each select="($document-root|$document-root//*)[&STRUCTURAL-FILTER;]">
            <xsl:variable name="is-chunk">
                <xsl:apply-templates select="." mode="is-chunk"/>
            </xsl:variable>
            <xsl:if test="$is-chunk = 'true'">
                <chunk>
                    <xsl:attribute name="filename">
                        <xsl:apply-templates select="." mode="containing-filename"/>
                    </xsl:attribute>
                </chunk>
            </xsl:if>
        </xsl:for-each>
    </xsl:if>
</xsl:variable>
<xsl:variable name="chunk-list" select="exsl:node-set($chunk-list-rtf)/chunk"/>

<!-- The file every navigation line points back to: the -->
<!-- summary page of the document root (or the root as  -->
<!-- one big chunk, for a shallow document)             -->
<xsl:variable name="contents-filename">
    <xsl:if test="$chunk-level &gt; 0">
        <xsl:apply-templates select="$document-root" mode="containing-filename"/>
    </xsl:if>
</xsl:variable>

<!-- Realize one file: macro support for its mathematics -->
<!-- (nothing in plain text), the content, then a        -->
<!-- navigation line                                     -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content"/>
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="containing-filename"/>
    </xsl:variable>
    <exsl:document href="{$filename}" method="text" encoding="UTF-8">
        <xsl:apply-templates select="." mode="latex-macros"/>
        <xsl:copy-of select="$content"/>
        <xsl:apply-templates select="." mode="navigation-line"/>
    </exsl:document>
</xsl:template>

<!-- A division above the chunk frontier becomes a summary page:  -->
<!-- its heading, its unstructured content, and one line naming   -->
<!-- the file of each structural child                            -->
<xsl:template match="&STRUCTURAL;" mode="intermediate">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="heading-lines"/>
            <xsl:apply-templates select="introduction"/>
            <xsl:text>&#xa;</xsl:text>
            <xsl:for-each select="*[&STRUCTURAL-FILTER;]">
                <xsl:apply-templates select="." mode="summary-entry"/>
            </xsl:for-each>
            <xsl:apply-templates select="conclusion"/>
            <xsl:apply-templates select="." mode="division-footnotes"/>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- One line of a summary page, naming a subsidiary file; the -->
<!-- markdown flavor overrides with a genuine link             -->
<xsl:template match="*" mode="summary-entry">
    <xsl:text>- </xsl:text>
    <xsl:apply-templates select="." mode="heading-text"/>
    <xsl:text> (</xsl:text>
    <xsl:apply-templates select="." mode="containing-filename"/>
    <xsl:text>)&#xa;</xsl:text>
</xsl:template>

<!-- The file of the division containing a chunk, when that is  -->
<!-- neither the chunk itself nor the contents page: worthwhile -->
<!-- in a deeply chunked document.  The document root has no    -->
<!-- containing division, so nothing at all.                    -->
<xsl:template match="*" mode="up-filename">
    <xsl:if test="parent::*[&STRUCTURAL-FILTER;]">
        <xsl:variable name="parent-filename">
            <xsl:apply-templates select=".." mode="containing-filename"/>
        </xsl:variable>
        <xsl:if test="not($parent-filename = $contents-filename)">
            <xsl:value-of select="$parent-filename"/>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- The trailing navigation line of a file that has a neighbor;   -->
<!-- labels localize, and the markdown flavor overrides with links -->
<xsl:template match="*" mode="navigation-line">
    <xsl:variable name="the-filename">
        <xsl:apply-templates select="." mode="containing-filename"/>
    </xsl:variable>
    <xsl:variable name="entry" select="$chunk-list[@filename = $the-filename]"/>
    <xsl:variable name="previous" select="$entry/preceding-sibling::chunk[1]"/>
    <xsl:variable name="next" select="$entry/following-sibling::chunk[1]"/>
    <xsl:variable name="up">
        <xsl:apply-templates select="." mode="up-filename"/>
    </xsl:variable>
    <xsl:if test="$previous or $next">
        <xsl:text>&#xa;[</xsl:text>
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'toc'"/>
        </xsl:apply-templates>
        <xsl:text>: </xsl:text>
        <xsl:value-of select="$contents-filename"/>
        <xsl:if test="$previous">
            <xsl:text> | </xsl:text>
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'previous'"/>
            </xsl:apply-templates>
            <xsl:text>: </xsl:text>
            <xsl:value-of select="$previous/@filename"/>
        </xsl:if>
        <xsl:if test="not($up = '')">
            <xsl:text> | </xsl:text>
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'up'"/>
            </xsl:apply-templates>
            <xsl:text>: </xsl:text>
            <xsl:value-of select="$up"/>
        </xsl:if>
        <xsl:if test="$next">
            <xsl:text> | </xsl:text>
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'next'"/>
            </xsl:apply-templates>
            <xsl:text>: </xsl:text>
            <xsl:value-of select="$next/@filename"/>
        </xsl:if>
        <xsl:text>]&#xa;</xsl:text>
    </xsl:if>
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
    <!-- within a list item or task, a paragraph indents to the -->
    <!-- item's content, except the one leading a list item,    -->
    <!-- which runs in right after the marker                   -->
    <xsl:if test="(ancestor::li or ancestor::task) and not(parent::li and not(preceding-sibling::*[not(self::title)]))">
        <xsl:apply-templates select="." mode="item-indent"/>
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

<!-- A task is an item of a list, in the manner of "ol/li": its   -->
<!-- serial marker indented to its depth, its content indented    -->
<!-- one level deeper (the item-indent and paragraph machinery of -->
<!-- the Lists section counts "task" ancestors too).  Markdown    -->
<!-- prefixes a genuine list marker so renderers nest properly.   -->
<xsl:template match="task" mode="item-marker">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>)</xsl:text>
</xsl:template>

<xsl:template match="task">
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="item-indent"/>
    <xsl:apply-templates select="." mode="item-marker"/>
    <xsl:if test="title">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
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

<!-- A figure — or a table, listing, or named list — presents its -->
<!-- content, and then a caption line: type, number, and the      -->
<!-- caption (or the title, for the types that have titles)       -->
<xsl:template match="&FIGURE-LIKE;">
    <!-- space with a blank line if not -->
    <!-- first in a structured element  -->
    <!-- barring metadata-ish           -->
    <xsl:if test="preceding-sibling::*[not(self::title)]">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="*[not(self::caption or self::title)]"/>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number"/>
    <xsl:text>: </xsl:text>
    <xsl:choose>
        <xsl:when test="caption">
            <xsl:apply-templates select="caption"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="caption">
    <!-- mixed-content -->
    <xsl:apply-templates/>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- The indentation of an item at its depth: four spaces per   -->
<!-- level of containing item, list or task alike, which is the -->
<!-- nesting convention markdown recognizes                     -->
<xsl:template match="*" mode="item-indent">
    <xsl:value-of select="str:padding(4 * (count(ancestor::li) + count(ancestor::task)), ' ')"/>
</xsl:template>

<xsl:template match="ul|ol|dl">
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="li"/>
</xsl:template>

<!-- A structured item's blocks (paragraphs, nested lists) supply -->
<!-- their own trailing newlines; an unstructured item needs one  -->
<xsl:template match="li" mode="finish-item">
    <xsl:if test="not(p or ol or ul or dl)">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- The marker of an ordered list item is its own number in the -->
<!-- authored format ("item-number"), not the dotted hierarchy   -->
<!-- ("serial-number", which cross-references still use); the    -->
<!-- nesting shows in the indentation                            -->
<xsl:template match="ol/li" mode="item-marker">
    <xsl:apply-templates select="." mode="item-number"/>
    <xsl:text>. </xsl:text>
</xsl:template>

<xsl:template match="ol/li">
    <xsl:apply-templates select="." mode="item-indent"/>
    <xsl:apply-templates select="." mode="item-marker"/>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="finish-item"/>
</xsl:template>

<xsl:template match="ul/li">
    <xsl:apply-templates select="." mode="item-indent"/>
    <xsl:text>* </xsl:text>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="finish-item"/>
</xsl:template>

<xsl:template match="dl/li">
    <xsl:apply-templates select="." mode="item-indent"/>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="finish-item"/>
</xsl:template>

</xsl:stylesheet>
