<?xml version='1.0'?>

<!--********************************************************************
Copyright 2026 Robert A. Beezer

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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
>

<!-- The markdown conversion IS the text conversion, plus the     -->
<!-- conventions markdown makes machine-recognizable: ATX         -->
<!-- headings, emphasis, code spans, links, and an escaping       -->
<!-- layer so authored punctuation is never mistaken for markup.  -->
<!-- The target is valid CommonMark.  The library lives here so   -->
<!-- other conversions producing markdown (Jupyter notebook       -->
<!-- cells) can import it and share single definitions.           -->
<xsl:import href="./pretext-text.xsl"/>

<xsl:output method="text"/>

<!-- if chunking, this is the extension of the files produced -->
<xsl:variable name="file-extension" select="'.md'"/>

<!-- ######## -->
<!-- Escaping -->
<!-- ######## -->

<!-- Prose flows through -common's "text()" machinery to the      -->
<!-- "text-processing" hook: flatten authored line breaks (as the -->
<!-- text conversion does), then backslash-escape every character -->
<!-- that could be mistaken for markdown or HTML markup.  (Math   -->
<!-- and verbatim content never reach this hook.)  CommonMark     -->
<!-- honors a backslash before any ASCII punctuation, so          -->
<!-- over-escaping is always safe, if unlovely; the set below is  -->
<!-- the characters that can OPEN a construction mid-prose, plus  -->
<!-- the dollar sign, which mathematics has claimed.              -->
<xsl:variable name="markdown-escapes" select="'\`*_[]&lt;&amp;$'"/>

<xsl:template name="text-processing">
    <xsl:param name="text"/>
    <xsl:variable name="flattened">
        <xsl:call-template name="flatten-line-breaks">
            <xsl:with-param name="text" select="$text"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="escape-markdown">
        <xsl:with-param name="text" select="$flattened"/>
    </xsl:call-template>
</xsl:template>

<!-- one pass per character of the escape set -->
<xsl:template name="escape-markdown">
    <xsl:param name="text"/>
    <xsl:param name="position" select="1"/>
    <xsl:choose>
        <xsl:when test="$position &gt; string-length($markdown-escapes)">
            <xsl:value-of select="$text"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="escaped">
                <xsl:call-template name="escape-one-character">
                    <xsl:with-param name="text" select="$text"/>
                    <xsl:with-param name="character" select="substring($markdown-escapes, $position, 1)"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="escape-markdown">
                <xsl:with-param name="text" select="$escaped"/>
                <xsl:with-param name="position" select="$position + 1"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="escape-one-character">
    <xsl:param name="text"/>
    <xsl:param name="character"/>
    <xsl:choose>
        <xsl:when test="contains($text, $character)">
            <xsl:value-of select="substring-before($text, $character)"/>
            <xsl:text>\</xsl:text>
            <xsl:value-of select="$character"/>
            <xsl:call-template name="escape-one-character">
                <xsl:with-param name="text" select="substring-after($text, $character)"/>
                <xsl:with-param name="character" select="$character"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ######## -->
<!-- Headings -->
<!-- ######## -->

<!-- ATX headings: honest levels, one octothorpe per depth, the -->
<!-- document title at level one, divisions one deeper          -->
<xsl:template match="book|article">
    <xsl:text># </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="part|chapter|appendix|preface|acknowledgement|biography|foreword|dedication|colophon|section|subsection|subsubsection|exercises|reading-questions|worksheet|handout|glossary|references|solutions">
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
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="substring('######', 1, $level + 1)"/>
    <xsl:text> </xsl:text>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$the-number"/>
        <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:variable name="the-notes" select=".//fn[generate-id(ancestor::*[&STRUCTURAL-FILTER;][1]) = generate-id(current())]"/>
    <xsl:if test="$the-notes">
        <xsl:text>&#xa;</xsl:text>
        <xsl:apply-templates select="$the-notes" mode="collected"/>
    </xsl:if>
</xsl:template>

<!-- ######## -->
<!-- Emphasis -->
<!-- ######## -->

<xsl:template match="em|foreign|articletitle|pubtitle">
    <xsl:text>*</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>*</xsl:text>
</xsl:template>

<xsl:template match="term|alert">
    <xsl:text>**</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>**</xsl:text>
</xsl:template>

<!-- fonts demanded by -common machinery (bibliographies) -->
<xsl:template match="*" mode="italic">
    <xsl:text>*</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>*</xsl:text>
</xsl:template>

<xsl:template match="*" mode="bold">
    <xsl:text>**</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>**</xsl:text>
</xsl:template>

<xsl:template match="*" mode="monospace">
    <xsl:text>`</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>`</xsl:text>
</xsl:template>

<!-- #### -->
<!-- Code -->
<!-- #### -->

<!-- backtick spans; content with a backtick gets double-backtick -->
<!-- delimiters and interior space, per CommonMark                -->
<xsl:template name="code-wrapper">
    <xsl:param name="content"/>
    <xsl:choose>
        <xsl:when test="contains($content, '`')">
            <xsl:text>`` </xsl:text>
            <xsl:copy-of select="$content"/>
            <xsl:text> ``</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>`</xsl:text>
            <xsl:copy-of select="$content"/>
            <xsl:text>`</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- #### -->
<!-- URLs -->
<!-- #### -->

<!-- a labeled link; a bare address is already an autolink in -->
<!-- the inherited angle-bracket form                         -->
<xsl:template match="url[node()]">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>](</xsl:text>
    <xsl:value-of select="@href"/>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- Display mathematics in dollar-fenced blocks, which GitHub    -->
<!-- and Jupyter renderers typeset; four-space indentation would  -->
<!-- read as a code block, so rows sit flush left                 -->
<xsl:template match="md">
    <xsl:text>&#xa;$$&#xa;</xsl:text>
    <xsl:apply-templates select="mrow|intertext"/>
    <xsl:text>$$&#xa;</xsl:text>
</xsl:template>

<xsl:template match="md[not(mrow)]">
    <xsl:text>&#xa;$$&#xa;</xsl:text>
    <xsl:value-of select="normalize-space(text())"/>
    <xsl:apply-templates select="." mode="get-clause-punctuation-mark"/>
    <xsl:text>&#xa;$$&#xa;</xsl:text>
</xsl:template>

<xsl:template match="mrow">
    <xsl:value-of select="normalize-space(.)"/>
    <xsl:if test="not(following-sibling::mrow)">
        <xsl:apply-templates select="parent::md" mode="get-clause-punctuation-mark"/>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- A structured line breaks with a raw HTML break: legal      -->
<!-- CommonMark, and it keeps a multi-line cell on the one      -->
<!-- physical line a pipe table demands                         -->
<xsl:template name="line-separator">
    <xsl:text>&lt;br&gt;</xsl:text>
</xsl:template>

<!-- ###### -->
<!-- Blocks -->
<!-- ###### -->

<!-- A block's heading line, emboldened -->
<xsl:template name="block-heading-line">
    <xsl:param name="heading"/>
    <xsl:text>**</xsl:text>
    <xsl:copy-of select="$heading"/>
    <xsl:text>**&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- CommonMark ordered-list markers are digits only, so the     -->
<!-- authored label (letters, Roman numerals, ...) rides inside  -->
<!-- a bullet item instead, in the manner of a task: hard-coded, -->
<!-- and every renderer shows exactly the label PreTeXt chose.   -->
<!-- The label's dot is backslash-escaped: a digit label with a  -->
<!-- bare dot would re-parse as an ordered list nested inside    -->
<!-- the bullet, and renderers would renumber it.                -->
<xsl:template match="ol/li" mode="item-marker">
    <xsl:text>- </xsl:text>
    <xsl:apply-templates select="." mode="item-number"/>
    <xsl:text>\. </xsl:text>
</xsl:template>

<!-- A description-list item is a bullet with its emboldened     -->
<!-- term; consecutive bare lines would otherwise merge into one -->
<!-- paragraph when rendered                                     -->
<xsl:template match="dl/li">
    <xsl:apply-templates select="." mode="item-indent"/>
    <xsl:text>- **</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>** </xsl:text>
    <xsl:apply-templates/>
    <xsl:apply-templates select="." mode="finish-item"/>
</xsl:template>

<!-- a task's serial marker rides inside a genuine list item, -->
<!-- so renderers indent nested tasks properly                -->
<xsl:template match="task" mode="item-marker">
    <xsl:text>- (</xsl:text>
    <xsl:apply-templates select="." mode="serial-number"/>
    <xsl:text>)</xsl:text>
</xsl:template>

</xsl:stylesheet>
