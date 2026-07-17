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
    xmlns:pf="https://prefigure.org"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    extension-element-prefixes="exsl str"
    exclude-result-prefixes="pf pi"
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
<!-- document title at level one, divisions one deeper.  Only   -->
<!-- the heading lines change flavor; the structure of a        -->
<!-- division (content, collected footnotes) is inherited.      -->
<xsl:template match="book|article" mode="heading-lines">
    <xsl:text># </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="heading-lines">
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
    <xsl:apply-templates select="." mode="heading-text"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
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
<!-- Images -->
<!-- ###### -->

<!-- A filename without an extension presumes a manufactured -->
<!-- SVG, exactly as the HTML conversion does                -->
<xsl:template name="presumed-svg">
    <xsl:param name="filename"/>
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename" select="$filename"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$extension = ''">
        <xsl:text>.svg</xsl:text>
    </xsl:if>
</xsl:template>

<!-- The relative path of an image's file, matching both the HTML  -->
<!-- conversion's references and the managed directories deposited -->
<!-- alongside a markdown build; empty when there is no file to    -->
<!-- point at (an interactive Asymptote diagram, say)              -->
<xsl:template match="image" mode="markdown-path">
    <xsl:choose>
        <xsl:when test="@pi:generated">
            <xsl:value-of select="$generated-directory"/>
            <xsl:value-of select="@pi:generated"/>
            <xsl:call-template name="presumed-svg">
                <xsl:with-param name="filename" select="@pi:generated"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="@source">
            <xsl:value-of select="$external-directory"/>
            <xsl:value-of select="@source"/>
            <xsl:call-template name="presumed-svg">
                <xsl:with-param name="filename" select="@source"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="latex-image">
            <xsl:value-of select="$generated-directory"/>
            <xsl:text>latex-image/</xsl:text>
            <xsl:apply-templates select="latex-image" mode="image-source-basename"/>
            <xsl:text>.svg</xsl:text>
        </xsl:when>
        <xsl:when test="sageplot[not(@variant = '3d')]">
            <xsl:value-of select="$generated-directory"/>
            <xsl:text>sageplot/</xsl:text>
            <xsl:apply-templates select="sageplot" mode="image-source-basename"/>
            <xsl:text>.svg</xsl:text>
        </xsl:when>
        <xsl:when test="pf:prefigure">
            <xsl:value-of select="$generated-directory"/>
            <xsl:text>prefigure/</xsl:text>
            <xsl:apply-templates select="pf:prefigure" mode="image-source-basename"/>
            <xsl:text>.svg</xsl:text>
        </xsl:when>
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

<!-- An image is always a raw-HTML "img" (legal CommonMark, and    -->
<!-- markdown's own syntax has no size or placement), so an        -->
<!-- authored @width in percent is honored (100% is the default).  -->
<!-- Centered by default, via an "align" wrapper that forge        -->
<!-- sanitizers keep (they strip "style").  An *authored* margin   -->
<!-- of 10% or less pins the image to that edge instead.  Without  -->
<!-- a file to reference, the producer's note of the text          -->
<!-- conversion stands.                                            -->
<xsl:template match="image">
    <xsl:variable name="path">
        <xsl:apply-templates select="." mode="markdown-path"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="not($path = '')">
            <xsl:variable name="rtf-layout">
                <xsl:apply-templates select="." mode="layout-parameters"/>
            </xsl:variable>
            <xsl:variable name="layout" select="exsl:node-set($rtf-layout)"/>
            <!-- A panel of a "sidebyside" is not aligned (it sits on -->
            <!-- the left edge, as any panel does); otherwise the     -->
            <!-- layout reports margins as bare numbers, anything     -->
            <!-- unresolvable is NaN, both comparisons fail, and      -->
            <!-- centering wins                                       -->
            <xsl:variable name="alignment">
                <xsl:choose>
                    <xsl:when test="ancestor::sidebyside"/>
                    <xsl:when test="@margins and (number($layout/left-margin) &lt;= 10)">
                        <xsl:text>left</xsl:text>
                    </xsl:when>
                    <xsl:when test="@margins and (number($layout/right-margin) &lt;= 10)">
                        <xsl:text>right</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>center</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- The layouts report bare numbers; the "img" attribute -->
            <!-- carries a percentage (a bare number would be pixels).-->
            <!-- A panel image takes its width from the enclosing     -->
            <!-- "sidebyside" layout, locating its panel as -common   -->
            <!-- does (a "figure" or "stack" wrapper is the panel)    -->
            <xsl:variable name="width">
                <xsl:choose>
                    <xsl:when test="ancestor::sidebyside">
                        <xsl:variable name="rtf-sbs-layout">
                            <xsl:apply-templates select="ancestor::sidebyside" mode="layout-parameters"/>
                        </xsl:variable>
                        <xsl:variable name="sbs-layout" select="exsl:node-set($rtf-sbs-layout)"/>
                        <xsl:variable name="panel-number">
                            <xsl:choose>
                                <xsl:when test="parent::figure or parent::stack">
                                    <xsl:value-of select="count(parent::*/preceding-sibling::*) + 1"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <!-- this layout's widths carry their percent signs -->
                        <xsl:value-of select="translate($sbs-layout/width[number($panel-number)], '%', '')"/>
                        <xsl:text>%</xsl:text>
                    </xsl:when>
                    <xsl:when test="not($layout/width = '')">
                        <xsl:value-of select="$layout/width"/>
                        <xsl:text>%</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>100%</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="alternative-text">
                <xsl:choose>
                    <xsl:when test="shortdescription">
                        <xsl:apply-templates select="shortdescription"/>
                    </xsl:when>
                    <xsl:when test="description">
                        <xsl:value-of select="normalize-space(description)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>image</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:text>&#xa;&lt;p</xsl:text>
            <xsl:if test="not($alignment = '')">
                <xsl:text> align="</xsl:text>
                <xsl:value-of select="$alignment"/>
                <xsl:text>"</xsl:text>
            </xsl:if>
            <xsl:text>&gt;&lt;img src="</xsl:text>
            <xsl:value-of select="$path"/>
            <xsl:text>" alt="</xsl:text>
            <!-- a double quote in a description would end the attribute -->
            <xsl:value-of select="translate($alternative-text, '&quot;', &quot;'&quot;)"/>
            <xsl:text>" width="</xsl:text>
            <xsl:value-of select="$width"/>
            <xsl:text>"&gt;&lt;/p&gt;&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-imports/>
        </xsl:otherwise>
    </xsl:choose>
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
<!-- Index -->
<!-- ##### -->

<!-- Each entry is a list item, nested two spaces per subentry     -->
<!-- level, so entries do not run together as a single paragraph   -->
<xsl:template name="present-index-heading">
    <xsl:param name="the-index-list"/>
    <xsl:param name="heading-group"/>
    <xsl:param name="b-write-locators"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="content"/>
    <xsl:value-of select="substring('    ', 1, 2 * ($heading-level - 1))"/>
    <xsl:text>- </xsl:text>
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

<!-- the "see"/"see also" words italicize -->
<xsl:template name="present-index-italics">
    <xsl:param name="content"/>
    <xsl:text>*</xsl:text>
    <xsl:copy-of select="$content"/>
    <xsl:text>*</xsl:text>
</xsl:template>

<!-- a chunked build links each locator to the file of its enclosure -->
<xsl:template match="index-list" mode="index-locator">
    <xsl:param name="enclosure"/>
    <xsl:param name="the-number"/>
    <xsl:choose>
        <xsl:when test="$chunk-level &gt; 0">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="$enclosure" mode="type-name"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
            <xsl:text>](</xsl:text>
            <xsl:apply-templates select="$enclosure" mode="containing-filename"/>
            <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="$enclosure" mode="type-name"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$the-number"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ######## -->
<!-- Chunking -->
<!-- ######## -->

<!-- A summary page's line for a subsidiary file is a genuine link -->
<xsl:template match="*" mode="summary-entry">
    <xsl:text>- [</xsl:text>
    <xsl:apply-templates select="." mode="heading-text"/>
    <xsl:text>](</xsl:text>
    <xsl:apply-templates select="." mode="containing-filename"/>
    <xsl:text>)&#xa;</xsl:text>
</xsl:template>

<!-- The navigation line links its labels; a lone paragraph, -->
<!-- pipe-separated like the plain-text form                 -->
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
        <xsl:text>](</xsl:text>
        <xsl:value-of select="$contents-filename"/>
        <xsl:text>)</xsl:text>
        <xsl:if test="$previous">
            <xsl:text> | [</xsl:text>
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'previous'"/>
            </xsl:apply-templates>
            <xsl:text>](</xsl:text>
            <xsl:value-of select="$previous/@filename"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:if test="not($up = '')">
            <xsl:text> | [</xsl:text>
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'up'"/>
            </xsl:apply-templates>
            <xsl:text>](</xsl:text>
            <xsl:value-of select="$up"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:if test="$next">
            <xsl:text> | [</xsl:text>
            <xsl:apply-templates select="." mode="type-name">
                <xsl:with-param name="string-id" select="'next'"/>
            </xsl:apply-templates>
            <xsl:text>](</xsl:text>
            <xsl:value-of select="$next/@filename"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
