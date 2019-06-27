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

<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="$root" mode="generic-warnings" />
    <xsl:apply-templates select="$root" mode="deprecation-warnings" />
    <xsl:apply-templates select="$root" />
</xsl:template>

<!-- Locate roots by the filename attribute -->
<xsl:template match="mathbook|pretext">
    <xsl:apply-templates select="//fragment[@filename]" />
</xsl:template>

<!-- Use filename as a root indicator, -->
<!-- allowing multiple files as output -->
<!-- Otherwise process as a fragment   -->
<xsl:template match="fragment[@filename]">
    <xsl:variable name="filename">
        <xsl:value-of select="@filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <xsl:apply-templates />
    </exsl:document>
</xsl:template>

<!-- Process a fragment, a mix of code and pointers -->
<!-- incorporate the referenced material            -->
 <xsl:template match="fragment[@ref]">
    <xsl:apply-templates select="id(@ref)" />
</xsl:template>

<!-- Duplicate text, rather than default sanitization -->
<xsl:template match="fragment/text()">
    <xsl:value-of select="." />
</xsl:template>

</xsl:stylesheet>
