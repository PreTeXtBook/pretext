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
 
<!-- Presents a WeBWork problem within a knowl  -->
<!-- Problem may be given as authored source in -->
<!-- XML or as a URL for an OPL problem         -->
<!-- Must be enclosed in an MBX "exercise"      -->

<!-- paths assumes we place this file (webwork-html.xsl) in mathbook "user" directory -->
<xsl:import href="../xsl/mathbook-html.xsl" />
<xsl:import href="./webwork-pg.xsl" />

<!-- Base 64 Library, MIT License -->
<!-- For encoding a problem string, copy/place    -->
<!-- base64.xsl *and* base64_binarydatamap.xml    -->
<!-- into mathbook "user" directory,              -->
<!-- and use the "b64" name space                 -->
<!-- https://github.com/ilyakharlamov/xslt_base64 -->
<!-- Again, into mathbook "user" directory        -->
<!-- Also copy   base64_binarydatamap.xml         -->
<xsl:include href="./base64.xsl"/>

<!-- Convert webwork problem content -->
<!-- Apply imports to make content, then encode to base64               -->
<!-- Base64 resurces for debugging                                      -->
<!-- ASCII Table:  http://www.rapidtables.com/code/text/ascii-table.htm -->
<!-- Online Converter: http://www.freeformatter.com/base64-encoder.html -->
<xsl:template match="webwork">
    <xsl:variable name="pg-ascii">
        <xsl:apply-imports />
    </xsl:variable>
    <xsl:call-template name="b64:encode">
        <xsl:with-param name="urlsafe" select="true()" />
        <xsl:with-param name="asciiString">
            <xsl:value-of select="$pg-ascii" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- The request for a "knowlized" webwork problem -->
<!-- comes from deep within the environment/knowl  -->
<!-- scheme in MBX's mathbook-html.xsl conversion  -->
<xsl:template match="webwork" mode="knowlized">
    <!-- Clickable, cribbed from "environment-hidden-factory" template -->
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>hidden-knowl-wrapper</xsl:text>
        </xsl:attribute>
        <xsl:element name="a">
           <!-- empty, indicates knowl content *not* in a file -->
            <xsl:attribute name="knowl"></xsl:attribute>
            <!-- class indicates content is in div referenced by id -->
            <xsl:attribute name="class">
                <xsl:text>id-ref</xsl:text>
            </xsl:attribute>
            <!-- and the id via a template for consistency -->
            <xsl:attribute name="refid">
                <xsl:apply-templates select="." mode="hidden-knowl-id" />
            </xsl:attribute>
            <!-- make the anchor a target, eg of an in-context link -->
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
            <!-- generally the "hidden-knowl-text", but generic here -->
            <xsl:text>WeBWorK Exercise</xsl:text>
        </xsl:element> 
    </xsl:element> <!-- end knowl clickable -->
    <!-- div containing hidden problem, with appropriate id -->
    <xsl:element name="div">
        <!-- different id, for use by the knowl mechanism -->
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="hidden-knowl-id" />
        </xsl:attribute>
        <!-- not "visibility," display:none takes no space -->
        <xsl:attribute name="style">
            <xsl:text>display: none;</xsl:text>
        </xsl:attribute>
        <!-- Do not process the contents on page load, wait until it is exposed -->
        <xsl:attribute name="class">
            <xsl:text>tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <!-- Actual content of knowl -->
        <xsl:comment>use 'format=debug' on 'webwork' tag to debug problem</xsl:comment>
        <xsl:element name="iframe">
            <xsl:attribute name="width">540</xsl:attribute> <!-- MBX specific -->
            <xsl:attribute name="height"><xsl:value-of select="@height" /></xsl:attribute>
            <xsl:attribute name="src">
                <xsl:text>https://hosted2.webwork.rochester.edu/webwork2/html2xml?</xsl:text>
                <xsl:text>&amp;answersSubmitted=0</xsl:text>
                <xsl:choose>
                    <xsl:when test="@source">
                        <xsl:text>&amp;sourceFilePath=</xsl:text>
                        <xsl:value-of select="@source" />
                    </xsl:when>
                    <xsl:when test="not(. = '')">
                        <xsl:text>&amp;problemSource=</xsl:text>
                        <xsl:apply-templates select="." />
                    </xsl:when>
                    <!-- no problem given in any form -->
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:text>MBX:WARNING: A webwork problem needs to specify the problem</xsl:text>
                            <xsl:apply-templates select="." mode="location-report" />
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>&amp;problemSeed=123567890</xsl:text>
                <xsl:text>&amp;displayMode=MathJax</xsl:text>
                <xsl:text>&amp;courseID=</xsl:text>
                <xsl:choose>
                    <xsl:when test="@course"><xsl:value-of select="@course" /></xsl:when>
                    <xsl:otherwise><xsl:text>daemon_course</xsl:text></xsl:otherwise>
                </xsl:choose>
                <xsl:text>&amp;userID=daemon</xsl:text>
                <xsl:text>&amp;password=daemon</xsl:text>
                <xsl:text>&amp;outputformat=</xsl:text>
                <xsl:choose>
                    <xsl:when test="@format"><xsl:value-of select="@format" /></xsl:when>
                    <xsl:otherwise><xsl:text>simple</xsl:text></xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <!-- unclear what this does, mimicing Mike's blog post -->
            <xsl:if test="not(. = '')">
                <xsl:attribute name="base64"><xsl:text>1</xsl:text></xsl:attribute>
                <xsl:attribute name="uri"><xsl:text>1</xsl:text></xsl:attribute>
            </xsl:if>
        </xsl:element> <!-- end iframe -->
    </xsl:element> <!-- end hidden div -->

</xsl:template>


<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

<!-- WeBWorK header -->
<!-- Maybe we use stock MBX knowl styling, or not -->
<!-- MathView likely necessary for WW widgets     -->
<!-- Incorporated into MBX HTML pages only if     -->
<!-- "webwork" element is present                 -->
<!-- Requires MBX to incorporate in page headers  -->
<xsl:template name="webwork">
    <!-- <link href="https://hosted2.webwork.rochester.edu/webwork2_files/css/knowlstyle.css" rel="stylesheet" type="text/css" /> -->
    <link href="https://hosted2.webwork.rochester.edu/webwork2_files/js/apps/MathView/mathview.css" rel="stylesheet" />
</xsl:template>

</xsl:stylesheet>
