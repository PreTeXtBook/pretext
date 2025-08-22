<?xml version='1.0'?>

<!--********************************************************************
Copyright 2014-2016 Robert A. Beezer

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

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- This stylesheet locates video/@youtube elements and -->
<!-- prepares a Python dictionary necessary to extract a -->
<!-- thumbnail for each video from the YouTube servers   -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl"
>

<!-- Get internal ID's for filenames, etc -->
<!-- Standard conversion groundwork       -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- Need pretext-html to set up chunking for containing-filename -->
<xsl:import href="./pretext-html.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<xsl:output method="text" encoding="UTF-8"/>

<!-- Avoid Catch-22: default assembly/pre-processor providews output     -->
<!-- for a conversion to a static format, but that format will *replace* -->
<!-- "audio", "video", "interactive"  by a static version (a             -->
<!-- "sidebyside") and it will not be available for extraction.           -->
<xsl:variable name="exercise-style" select="'dynamic'"/>

<!-- Make sure url's are generated with .html extension -->
<xsl:variable name="file-extension" select="'.html'"/>

<!-- Override extraction-wrapper so we can provide single error and not attempt -->
<!-- to write files if no base URL is defined.                                  -->
<xsl:template match="*" mode="extraction-wrapper">
    <xsl:choose>
        <xsl:when test="$b-has-baseurl">
            <xsl:message>PTX:INFO:   Writing qrcode-urls.txt</xsl:message>
            <xsl:apply-templates select="." mode="extraction"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR:   Base URL must be specified to generate QR codes</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Standard traversal generates temp text file for python qrcode generation   -->
<xsl:template match="&QRCODE-INTERACTIVES;" mode="extraction">
    <!-- Each line of the text file is a URL, space, assembly-id -->
    <xsl:apply-templates select="." mode="static-url"/>
    <!-- Do not use a comma, since a YouTube playlist has      -->
    <!-- commas as separators, and they show up in the URL.    -->
    <!-- So a space instead.  See comments in Python consumer. -->
    <xsl:text> </xsl:text>
    <xsl:variable name="assembly-id">
        <xsl:apply-templates select="." mode="assembly-id"/>
    </xsl:variable>
    <xsl:value-of select="$assembly-id"/>
    <xsl:text>&#xa;</xsl:text>

    <!-- Also generate a sidecar XML file with name based on assembly-id    -->
    <!-- File will contain the URL for this interactive.                    -->
    <!-- For URLs within the book, static outputs will not be able to use   -->
    <!-- mode="static-url" directly, as it depends on the chunking set by   -->
    <!-- the HTML conversion.  So generate now and save to file.            -->
    <exsl:document href="{$generated-directory-source}qrcode/{$assembly-id}-url.xml" method="xml" indent="yes" encoding="UTF-8">
        <interactive-url>
            <xsl:attribute name="url">
                <xsl:apply-templates select="." mode="static-url"/>
            </xsl:attribute>
        </interactive-url>
    </exsl:document>
</xsl:template>

<!-- Second traversal to generate XML file with URLS that is part of final product -->
<xsl:template match="@*|node()" mode="url-extraction">
    <xsl:apply-templates select="@*|node()" mode="url-extraction"/>
</xsl:template>

<xsl:template match="&QRCODE-INTERACTIVES;" mode="url-extraction">
    <interactive-url>
      <xsl:attribute name="url">
        <xsl:apply-templates select="." mode="static-url"/>
      </xsl:attribute>
      <!-- need to use assembly-id as the value will be read during representations -->
      <!-- pass of assembly before visible-id is available                          -->
      <xsl:attribute name="id">
        <xsl:apply-templates select="." mode="assembly-id" />
      </xsl:attribute>
    </interactive-url>
</xsl:template>

</xsl:stylesheet>
