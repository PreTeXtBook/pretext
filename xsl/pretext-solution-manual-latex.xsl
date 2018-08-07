<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2018 Robert A. Beezer

This file is part of PreTeXt.

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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
>

<xsl:import href="./mathbook-latex.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<!-- For a "book" we replace the first chapter by a call to the        -->
<!-- solutions generator.  So we burrow into parts to get at chapters. -->

<xsl:template match="part|chapter|backmatter/solutions" />

<xsl:template match="part[1]">
    <xsl:apply-templates select="chapter[1]" />
</xsl:template>

<xsl:template match="chapter[1]">
    <xsl:apply-templates select="$document-root" mode="solutions-generator">
        <xsl:with-param name="b-inline-statement"     select="false()" />
        <xsl:with-param name="b-inline-hint"          select="true()"  />
        <xsl:with-param name="b-inline-answer"        select="true()"  />
        <xsl:with-param name="b-inline-solution"      select="true()"  />
        <xsl:with-param name="b-divisional-statement" select="false()" />
        <xsl:with-param name="b-divisional-hint"      select="true()"  />
        <xsl:with-param name="b-divisional-answer"    select="true()"  />
        <xsl:with-param name="b-divisional-solution"  select="true()"  />
        <xsl:with-param name="b-project-statement"    select="false()" />
        <xsl:with-param name="b-project-hint"         select="true()"  />
        <xsl:with-param name="b-project-answer"       select="true()"  />
        <xsl:with-param name="b-project-solution"     select="true()"  />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="part|chapter|section|subsection|subsubsection|exercises" mode="division-in-solutions">
    <xsl:param name="scope" />
    <xsl:param name="content" />

    <!-- LaTeX heading with hard-coded number -->
    <xsl:text>\</xsl:text>
    <xsl:apply-templates select="." mode="division-name" />
    <xsl:text>*{</xsl:text>
    <!-- control the numbering, i.e. hard-coded -->
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <!-- no trailing space if no number -->
    <xsl:if test="not($the-number = '')">
        <xsl:value-of select="$the-number" />
        <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}&#xa;</xsl:text>
    <!-- An entry for the ToC, since we hard-code numbers -->
    <!-- These mainmatter divisions should always have a number -->
    <xsl:text>\addcontentsline{toc}{</xsl:text>
    <xsl:apply-templates select="." mode="division-name" />
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="$the-number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-simple" />
    <xsl:text>}&#xa;</xsl:text>

    <xsl:copy-of select="$content" />
</xsl:template>

</xsl:stylesheet>
