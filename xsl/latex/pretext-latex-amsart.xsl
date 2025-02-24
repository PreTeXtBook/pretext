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
<xsl:variable name="documentclass" select="'amsart'"/>
<xsl:variable name="bibliographystyle" select="'amsplain'"/>

<!-- Order of bibinfo elements before \begin{document} -->
<xsl:template name="bibinfo-pre-begin-document"/>


<!-- Order of bibinfo elements after \begin{document} -->
<xsl:template name="bibinfo-post-begin-document">
    <xsl:apply-templates select="$document-root" mode="article-title"/>
    <xsl:apply-templates select="$bibinfo/author" mode="article-frontmatter"/>
    <xsl:apply-templates select="$bibinfo/keywords[@authority='msc']" mode="article-frontmatter"/>
    <xsl:apply-templates select="$bibinfo/date" mode="article-frontmatter"/>
    <xsl:apply-templates select="$bibinfo/keywords[not(@authority='msc')]" mode="article-frontmatter"/>
    <xsl:apply-templates select="$bibinfo/support" mode="article-frontmatter"/>
    <xsl:apply-templates select="$document-root/frontmatter/abstract" mode="article-frontmatter"/>

    <xsl:text>\maketitle&#xa;</xsl:text>
</xsl:template>

<!-- Contents of bibinfo elements -->
<xsl:template match="*" mode="article-title">
    <xsl:text>%% Title page information for article&#xa;</xsl:text>
    <xsl:text>\title[</xsl:text>
    <xsl:apply-templates select="." mode="title-short"/>
    <xsl:text>]{</xsl:text>
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


<xsl:template match="bibinfo/author" mode="article-frontmatter">
    <xsl:text>\author{</xsl:text>
    <xsl:apply-templates select="personname"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="affiliation">
        <xsl:text>\address{</xsl:text>
        <xsl:apply-templates select="affiliation"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="email">
        <xsl:text>\email{</xsl:text>
        <xsl:apply-templates select="email" mode="article-info" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="support">
        <xsl:text>\thanks{</xsl:text>
        <xsl:apply-templates select="support"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>



<xsl:template match="bibinfo/keywords[@authority='msc']" mode="article-frontmatter">
    <xsl:text>\subjclass[</xsl:text>
    <xsl:value-of select="$bibinfo/keywords[@authority='msc']/@variant"/>
    <xsl:text>]{</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<xsl:template match="bibinfo/date" mode="article-frontmatter">
    <xsl:text>\date{</xsl:text>
    <xsl:apply-templates select="."/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<xsl:template match="bibinfo/keywords[not(@authority='msc')]" mode="article-frontmatter">
    <xsl:text>\keywords{</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<xsl:template match="bibinfo/support" mode="article-frontmatter">
    <xsl:text>\dedicatory{</xsl:text>
    <xsl:apply-templates select="$bibinfo/support" mode="article-info"/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>



<xsl:template match="frontmatter/abstract" mode="article-frontmatter">
    <xsl:text>\begin{abstract}&#xa;</xsl:text>
        <xsl:apply-templates select="*"/>
    <xsl:text>\end{abstract}&#xa;</xsl:text>
</xsl:template>




</xsl:stylesheet>
