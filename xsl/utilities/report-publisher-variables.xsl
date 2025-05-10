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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<!-- We choose to not include a default namespace       -->
<!-- (in particular  http://www.w3.org/1999/xhtml),     -->
<!-- even if this complicates adding namespaces onto    -->
<!-- derivatives, such as HTML destined for EPUB output -->
<!-- xmlns="http://www.w3.org/1999/xhtml"               -->
<!--                                                    -->
<!-- NB:                                                -->
<!--   "xsl" is necessary to identify XSL functionality -->
<!--   "xml" is automatic, hence redundant              -->
<!--   "svg" is necessary to for Asymptote 3D images    -->
<!--   "pi" is meant to mark private PreTeXt markup     -->
<!--   "exsl" namespaces enable extension functions     -->
<!--                                                    -->
<!-- Excluding result prefixes keeps them from bleeding -->
<!-- into output unnecessarily -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
>

<!-- DEBUGGING -->
<!-- xsltproc -o crap.txt  -stringparam publisher ~/mathbook/mathbook/examples/sample-article/publication.xml /home/rob/mathbook/mathbook/xsl/utilities/report-publisher-variables.xsl ~/mathbook/mathbook/examples/sample-article/sample-article.xml -->

<!-- Standard conversion groundwork -->
<xsl:import href="../publisher-variables.xsl"/>
<xsl:import href="../pretext-assembly.xsl"/>

<!-- Intend output for a text file -->
<xsl:output method="text" encoding="UTF-8"/>

<!-- IMPORTANT: to report the value of a (computed) publisher variable,   -->
<!-- two related routines are involved.  For a variable not previously    -->
<!-- supported, a developer must take action to implement a report. The   -->
<!-- XSL in the "utilities/report-publisher-variable.xsl" stylesheet must -->
<!-- include the report of a value, which will be captured in a temporary -->
<!-- file to be read by the Python routine "get_publisher_variable()".    -->

<xsl:template match="/">
    <!-- 2024-06-20 Testing-->
    <xsl:text>generated-directory-source</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$generated-directory-source"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- 2024-06-20 Testing-->
    <xsl:text>external-directory-source</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$external-directory-source"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- 2024-06-26 Mermaid theme -->
    <xsl:text>mermaid-theme</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$mermaid-theme"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- 2024-07-07 QR code image -->
    <xsl:text>qrcode-image</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$qrcode-image"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- 2024-07-21 theme for html build -->
    <xsl:text>html-theme-name</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$html-theme-name"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>html-theme-options</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$html-theme-options"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- 2024-10-04 LaTeX style xsl -->
    <xsl:text>latex-style</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$latex-style"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- 2025-02-25 journal name -->
    <xsl:text>journal-name</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$journal-name"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- 2025-03-10 portable html switch -->
    <xsl:text>portable-html</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$portable-html"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- 2025-05-10 CSL style filename -->
    <xsl:text>csl-style-file</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$csl-style-file"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- -->

    <!--
    Boilerplate to support a new variable
    Please use this style, as above
    (remove "X" to format comments properly)

    <!-X- YYY-MM-DD Purpose-X->
    <xsl:text>[[var-name-here]]</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$[[var-name-here-keep-prefix-$]]"/>
    <xsl:text>&#xa;</xsl:text>
    <!-X- -X->
    -->

</xsl:template>

</xsl:stylesheet>