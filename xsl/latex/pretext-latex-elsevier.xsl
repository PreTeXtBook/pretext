<?xml version='1.0'?>

<!--********************************************************************
Copyright 2025 Oscar Levin

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

<!-- Conveniences for classes of similar elements -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- Override specific tenplates of the standard conversion -->
<xsl:import href="../pretext-latex-classic.xsl" />

<!-- Provide the name of the document class -->
<!-- TODO: when @journal is specified in publisher file, we will use   -->
<!-- that to change the documentclass using some sort of lookup table. -->
<xsl:variable name="documentclass" select="'elsarticle'"/>


<xsl:template name="bibinfo-pre-begin-document"/>

<xsl:template name="bibinfo-post-begin-document">
    <xsl:text>\begin{frontmatter}&#xa;</xsl:text>
    <xsl:apply-templates select="$document-root" mode="article-title"/>
    <xsl:if test="$bibinfo/author or $bibinfo/editor">
        <xsl:apply-templates select="$bibinfo/author" mode="article-info"/>
        <xsl:apply-templates select="$bibinfo/editor" mode="article-info"/>
    </xsl:if>
    <xsl:if test="$document-root/frontmatter/abstract">
        <xsl:apply-templates select="$document-root/frontmatter/abstract" mode="article-frontmatter"/>
    </xsl:if>
    <xsl:if test="$bibinfo/keywords">
        <xsl:text>\begin{keyword}&#xa;</xsl:text>
        <xsl:apply-templates select="$bibinfo/keywords"/>
        <xsl:text>\end{keyword}&#xa;</xsl:text>
    </xsl:if>
    <!--<xsl:if test="$bibinfo/support">
        <xsl:text>\dedicatory{</xsl:text>
        <xsl:apply-templates select="$bibinfo/support" mode="article-info"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>-->

    <xsl:text>\end{frontmatter}&#xa;</xsl:text>
</xsl:template>


<xsl:template match="*" mode="article-title">
    <xsl:text>%% Title page information for article&#xa;</xsl:text>
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:if test="subtitle">
        <xsl:text>\\&#xa;</xsl:text>
        <!-- Trying to match author fontsize -->
        <xsl:text>{\small </xsl:text>
        <xsl:apply-templates select="." mode="subtitle"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="bibinfo/author" mode="article-info">
    <xsl:text>\author{</xsl:text>
    <xsl:apply-templates select="personname"/>
    <xsl:if test="support">
        <xsl:text>\fnref{</xsl:text>
        <xsl:apply-templates select="." mode="unique-id"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="support">
        <xsl:text>\fntext[</xsl:text>
        <xsl:apply-templates select="." mode="unique-id"/>
        <xsl:text>]{</xsl:text>
        <xsl:apply-templates select="support"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="affiliation">
        <xsl:text>\affiliation{</xsl:text>
        <xsl:apply-templates select="affiliation"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="email">
        <xsl:text>\ead{</xsl:text>
        <xsl:apply-templates select="email" mode="article-info" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>



<xsl:template match="affiliation">
    <xsl:if test="department">
        <xsl:apply-templates select="department" />
        <xsl:if test="department/following-sibling::*">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="institution">
        <xsl:apply-templates select="institution" />
        <xsl:if test="institution/following-sibling::*">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="location">
        <xsl:apply-templates select="location" />
    </xsl:if>
    <xsl:text>.</xsl:text>
</xsl:template>

<xsl:template name="line-separator">
    <xsl:text>, </xsl:text>
</xsl:template>


<xsl:template match="frontmatter/abstract" mode="article-frontmatter">
    <xsl:text>\begin{abstract}&#xa;</xsl:text>
        <xsl:apply-templates select="*"/>
    <xsl:text>\end{abstract}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="bibinfo/keywords">
    <xsl:if test="not(@authority='msc')">
        <xsl:apply-templates select="*"/>
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="@authority='msc'">
        <xsl:text>\MSC[</xsl:text>
        <xsl:value-of select="@variant"/>
        <xsl:text>] </xsl:text>
        <xsl:apply-templates select="*"/>
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
