<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2015                                                        -->
<!-- Robert A. Beezer, Michael Gage, Geoff Goehle, Alex Jordan             -->
<!--                                                                       -->
<!-- This file is part of MathBook XML.                                    -->
<!--                                                                       -->
<!-- MathBook XML is free software: you can redistribute it and/or modify  -->
<!-- it under the terms of the GNU General Public License as published by  -->
<!-- the Free Software Foundation, either version 2 or version 3 of the    -->
<!-- License (at your option).                                             -->
<!--                                                                       -->
<!-- MathBook XML is distributed in the hope that it will be useful,       -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of        -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         -->
<!-- GNU General Public License for more details.                          -->
<!--                                                                       -->
<!-- You should have received a copy of the GNU General Public License     -->
<!-- along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>. -->
<!-- ********************************************************************* -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- For WW problems described simply as a URL for the problem -->
<!-- on a server, this transform will extract the              -->
<!--                                                           -->
<!-- (a) URL                                                   -->
<!-- (b) seed                                                  -->
<!-- (c) internal-id string                                    -->
<!--                                                           -->
<!-- in a form that the Python  mbx  script can employ it to   -->
<!-- query the server for a LaTeX version of the problem       -->

<!-- Common needed for internal ID's -->
<xsl:import href="mathbook-common.xsl" />

<!-- Enclosing structure is a Python list -->
<!-- Select WW problems with  @source     -->
<xsl:template match="/">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="//webwork[@source]" />
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Python triple: ('URL', 'seed', 'internal-id')    -->
<!-- transmit items as strings for Python's exec()    -->
<!-- trailing space in Python list is fine            -->
<!-- Only need to match "webwork" due to select above -->
<xsl:template match="webwork">
    <!-- A Python triple with information -->
    <xsl:text>(</xsl:text>
    <xsl:text>'</xsl:text>
    <xsl:value-of select="@source" />
    <xsl:text>'</xsl:text>
    <xsl:text>,</xsl:text>
    <xsl:choose>
        <xsl:when test="@seed">
            <xsl:text>'</xsl:text>
            <xsl:value-of select="@seed" />
            <xsl:text>'</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>'123567890'</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>,</xsl:text>
    <xsl:text>'</xsl:text>
    <xsl:apply-templates select="." mode="internal-id" />
    <xsl:text>'</xsl:text>
    <xsl:text>)</xsl:text>
    <xsl:text>,</xsl:text>
</xsl:template>

</xsl:stylesheet>