<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2020 Robert A. Beezer

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
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace">

<!-- Report on console, or redirect/option to a file -->
<xsl:output method="text"/>

<!-- ############## -->
<!-- Infrastructure -->
<!-- ############## -->

<!-- Entry template -->
<xsl:template match="/">
    <xsl:apply-templates/>
</xsl:template>

<!-- Traverse the tree, looking for trouble -->
<xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
</xsl:template>

<!-- ######### -->
<!-- Messaging -->
<!-- ######### -->

<xsl:template match="*" mode="messaging">
    <xsl:param name="severity"/>
    <xsl:param name="message"/>

    <xsl:text>################################################################&#xa;</xsl:text>
    <xsl:text>PTX:</xsl:text>
    <xsl:choose>
        <xsl:when test="$severity = 'error'">
            <xsl:text>ERROR</xsl:text>
        </xsl:when>
        <xsl:when test="$severity = 'warn'">
            <xsl:text>WARNING</xsl:text>
        </xsl:when>
        <xsl:when test="$severity = 'advice'">
            <xsl:text>ADVICE</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>################################################################</xsl:message>
            <xsl:message>Validation+ stylesheet is passing incorrect severity ("<xsl:value-of select="$severity"/>")</xsl:message>
            <xsl:message>################################################################</xsl:message>
            <xsl:message terminate='yes'/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="." mode="numbered-path"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="$message"/>
</xsl:template>

<xsl:template match="*" mode="numbered-path">
    <xsl:variable name="ancestors" select="ancestor-or-self::*"/>
    <xsl:for-each select="$ancestors">
        <xsl:text>/</xsl:text>
        <xsl:value-of select="local-name(.)"/>
        <xsl:text>[</xsl:text>
        <xsl:number/>
        <xsl:text>]</xsl:text>
    </xsl:for-each>
</xsl:template>

</xsl:stylesheet>


