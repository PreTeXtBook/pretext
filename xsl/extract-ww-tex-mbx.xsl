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
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64"
>

<!-- For WW problems described as MathBook XML source, but with    -->
<!-- images authored in PG format, this transform will extract the -->
<!--                                                               -->
<!-- (a) base64 version of the problem                             -->
<!-- (b) seed                                                      -->
<!-- (c) internal-id string                                        -->
<!--                                                               -->
<!-- in a form that the Python  mbx  script can employ it to       -->
<!-- query the server for a version of the problem with the images -->

<xsl:import href="./mathbook-common.xsl" />

<!-- Base 64 Library, MIT License -->
<!-- Used to encode WeBWork problems           -->
<!-- Will also read  base64_binarydatamap.xml  -->
<xsl:include href="./xslt_base64/base64.xsl"/>

<!-- Routines specific to converting a "webwork"  -->
<!-- element into a problem in the PGML language -->
<xsl:include href="./mathbook-webwork-pg.xsl" />

<!-- Enclosing structure is a Python list -->
<!-- Select WW problems with PG images    -->
<xsl:template match="/">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="//webwork[descendant::image[@pg-name]]" />
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Python triple: ('base64-version', 'seed', 'internal-id') -->
<!-- transmit items as strings for Python's exec()            -->
<!-- trailing space in Python list is fine                    -->
<!-- We *do not* URL-encode the base64 string since the       -->
<!-- Python  mbx  script uses the "requests" library which    -->
<!-- seems to do the encoding automatically                   -->
<xsl:template match="webwork[descendant::image[@pg-name]]">
    <!-- A Python triple with information -->
    <xsl:text>(</xsl:text>
    <xsl:text>'</xsl:text>
    <!-- formulate PG version with included routine  -->
    <!-- form base64 version for URL transmission    -->
    <!-- NB: not URL-safe, Python library handles it -->
    <xsl:variable name="pg-ascii">
        <xsl:apply-templates select="." mode="pg" />
    </xsl:variable>
    <xsl:call-template name="b64:encode">
        <xsl:with-param name="urlsafe" select="false()" />
        <xsl:with-param name="asciiString">
            <xsl:value-of select="$pg-ascii" />
        </xsl:with-param>
    </xsl:call-template>
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
