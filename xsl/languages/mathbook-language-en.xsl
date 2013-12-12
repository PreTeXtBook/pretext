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

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" 
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="date"
>

<!-- MathBook XML templates for language-specific phrases in headings, etc.      -->
<!-- Intended to be imported by mathbook-common.xsl for use in any output format -->

<!-- So output methods here are just text -->
<xsl:output method="text" />

<xsl:template name="type-name">
    <xsl:param name="generic" />
    <xsl:choose>
        <xsl:when test="$generic='theorem'">     <xsl:text>Theorem</xsl:text></xsl:when>
        <xsl:when test="$generic='corollary'">   <xsl:text>Corollary</xsl:text></xsl:when>
        <xsl:when test="$generic='lemma'">       <xsl:text>Lemma</xsl:text></xsl:when>
        <xsl:when test="$generic='proposition'"> <xsl:text>Proposition</xsl:text></xsl:when>
        <xsl:when test="$generic='claim'">       <xsl:text>Claim</xsl:text></xsl:when>
        <xsl:when test="$generic='fact'">        <xsl:text>Fact</xsl:text></xsl:when>
        <xsl:when test="$generic='conjecture'">  <xsl:text>Conjecture</xsl:text></xsl:when>
        <!-- -->
        <xsl:when test="$generic='definition'">  <xsl:text>Definition</xsl:text></xsl:when>
        <xsl:when test="$generic='section'">     <xsl:text>Section</xsl:text></xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="no">Warning: Unable to translate <xsl:value-of select="$generic" />.&#xa;</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!--
<xsl:strip-space elements="chapter appendix subsection subsubsection paragraph subparagraph" />
<xsl:strip-space elements="abstract preface" />
<xsl:strip-space elements="proof" />
<xsl:strip-space elements="axiom" />
<xsl:strip-space elements="remark example exercise hint solution" />
<xsl:strip-space elements="figure" />
<xsl:strip-space elements="table" />
-->

</xsl:stylesheet>