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
<xsl:variable name="documentclass" select="'article'"/>


<xsl:template name="journal-packages">
    <xsl:text>\usepackage[amsmath]{e-jc}&#xa;</xsl:text>
</xsl:template>


<!-- By default, no bibinfo is included before the \begin{document}.     -->
<!-- Other latex styles can override this to put some information there. -->
<xsl:template name="bibinfo-pre-begin-document">
    <!-- date -->
    <xsl:text>\dateline{</xsl:text>
    <xsl:if test="$bibinfo/date">
        <xsl:apply-templates select="$bibinfo/date"/>
    </xsl:if>
    <xsl:text>}{TBD}{TBD}&#xa;</xsl:text>
    <!-- msc -->
    <xsl:if test="$bibinfo/keywords[@authority='msc']">
        <xsl:apply-templates select="$bibinfo/keywords[@authority='msc']"/>
    </xsl:if>
    <!-- TODO: Copyright, from a list of acceptable statements.  See sample. -->
    <!-- For now, just a default -->
    <xsl:text>\Copyright{The author.}&#xa;</xsl:text>

    <!-- Title -->
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="$document-root" mode="article-title"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="$bibinfo/author">
        <xsl:text>\author{</xsl:text>
        <xsl:apply-templates select="$bibinfo/author" mode="author-names"></xsl:apply-templates>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:apply-templates select="$bibinfo/author" mode="author-info"/>
    </xsl:if>

    <xsl:if test="$bibinfo/editor">
        <xsl:message>PTX:WARNING: The journal you are building for does not provide a mechanisms for listing editors.</xsl:message>
    </xsl:if>

    <!--<xsl:if test="$bibinfo/keywords[not(@authority='msc')]">
        <xsl:text>\keywords{</xsl:text>
        <xsl:apply-templates select="$bibinfo/keywords[not(@authority='msc')]"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>-->
    <!--<xsl:if test="$bibinfo/support">
        <xsl:text>\dedicatory{</xsl:text>
        <xsl:apply-templates select="$bibinfo/support" mode="article-info"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>-->
</xsl:template>

<!-- By default, all bibinfo goes inside (after) \begin{document}.             -->
<!-- Other latex styles can override this in combination with the pre-version. -->
<xsl:template name="bibinfo-post-begin-document">
    <xsl:text>\maketitle&#xa;</xsl:text>
    <xsl:if test="$document-root/frontmatter/abstract">
        <xsl:apply-templates select="$document-root/frontmatter/abstract"/>
    </xsl:if>
</xsl:template>


<!-- Templates for bibinfo contents: -->

<xsl:template match="bibinfo/keywords[@authority='msc']">
    <xsl:text>\MSC{</xsl:text>
    <xsl:apply-templates select="keyword"/>
    <xsl:text>}%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="keyword">
    <xsl:value-of select="."/>
    <xsl:if test="following-sibling::keyword">
        <xsl:text>, </xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="*" mode="article-title">
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:if test="subtitle">
        <xsl:text>\\&#xa;</xsl:text>
        <!-- Trying to match author fontsize -->
        <xsl:text>{\small </xsl:text>
        <xsl:apply-templates select="." mode="subtitle"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>


<xsl:template match="bibinfo/author" mode="author-names">
    <xsl:apply-templates select="personname"/>
    <xsl:text>\authornote{</xsl:text>
    <xsl:number/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:if test="following-sibling::author">
        <xsl:text>\and&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="bibinfo/author" mode="author-info">
    <xsl:text>\authortext{</xsl:text>
    <xsl:number/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="affiliation"/>
    <xsl:text>(\email{</xsl:text>
    <xsl:apply-templates select="email"/>
    <xsl:text>})}%&#xa;</xsl:text>
</xsl:template>

<!-- e-jc already includes a number of theorem environments.  We remove these and only 
keep the ones e-jc.sty doesn't have. -->
<xsl:template name="latex-theorem-environments">
    <xsl:text>%% Theorem-like environments&#xa;</xsl:text>
    <xsl:text>%&#xa;% amsthm package: redundant if using amsart documentclass, but required otherwise.&#xa;</xsl:text>
    <xsl:text>\usepackage{amsthm}%&#xa;%&#xa;</xsl:text>
    <xsl:text>\theoremstyle{plain}&#xa;</xsl:text>
    <!-- Now continue with the remaining elements, checking to see if they are present -->
    <xsl:variable name="theoremstyle-plain" select="
        ($document-root//identity)[1]
        "/>
    <xsl:for-each select="$theoremstyle-plain">
        <xsl:apply-templates select="." mode="newtheorem"/>
    </xsl:for-each>
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
    <xsl:variable name="theoremstyle-definition" select="
        ($document-root//axiom)[1]|
        ($document-root//principle)[1]|
        ($document-root//heuristic)[1]|
        ($document-root//hypothesis)[1]|
        ($document-root//assumption)[1]|
        ($document-root//openproblem)[1]|
        ($document-root//openquestion)[1]|
        ($document-root//algorithm)[1]|
        ($document-root//activity)[1]|
        ($document-root//exercise)[1]|
        ($document-root//inlineexercise)[1]|
        ($document-root//investigation)[1]|
        ($document-root//exploration)[1]|
        ($document-root//project)[1]
    "/>
    <xsl:for-each select="$theoremstyle-definition">
        <xsl:apply-templates select="." mode="newtheorem"/>
    </xsl:for-each>
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>\theoremstyle{remark}&#xa;</xsl:text>
        <xsl:variable name="theoremstyle-remark" select="
        ($document-root//convention)[1]|
        ($document-root//warning)[1]|
        ($document-root//insight)[1]|
        ($document-root//computation)[1]|
        ($document-root//technology)[1]|
        ($document-root//data)[1]
    "/>
    <xsl:for-each select="$theoremstyle-remark">
        <xsl:apply-templates select="." mode="newtheorem"/>
    </xsl:for-each>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- Don't do anything special with hyperref -->
<xsl:template name="load-configure-hyperref"/>


</xsl:stylesheet>
