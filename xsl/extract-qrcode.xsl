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

<!-- interactive-urls is normally generated from the document this stylesheet    -->
<!-- produces. Override with empty value while extracting to avoid chicken/egg   -->
<xsl:variable name="interactive-urls">
    <interactive-urls/>
</xsl:variable>

<!-- Override extraction-wrapper so we can do two passes over the document             -->
<!-- First pass generates a text file for the Python QR code generator                 -->
<!-- Second pass generates an XML file with the URLs that is part of the final product -->
<xsl:template match="*" mode="extraction-wrapper">
    <xsl:choose>
        <xsl:when test="$b-has-baseurl">
            <xsl:message>Writing qrcode-urls.txt</xsl:message>
            <xsl:apply-templates select="." mode="extraction"/>
            <xsl:message>Writing interactive-urls.xml</xsl:message>
            <exsl:document href="{$generated-directory-source}qrcode/interactive-urls.xml" method="xml" indent="yes" encoding="UTF-8">
                <interactive-urls xmlns:str="http://exslt.org/strings">
                    <xsl:attribute name="localized-link-description">
                        <xsl:apply-templates select="." mode="type-name">
                            <xsl:with-param name="string-id" select="'program-interactive-available'"/>
                        </xsl:apply-templates>
                    </xsl:attribute>
                    <xsl:apply-templates select="." mode="url-extraction"/>
                </interactive-urls>
            </exsl:document>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR:   Base URL must be specified to generate QR codes</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Standard traversal generates temp text file for python qrcode generation   -->
<!-- Are filters here irrelevant?  Just for the implementation of "static-url"? -->
<xsl:template match="&QRCODE-INTERACTIVES;" mode="extraction">
    <xsl:apply-templates select="." mode="static-url"/>
    <!-- Do not use a comma, since a YouTube playlist has      -->
    <!-- commas as separators, and they show up in the URL.    -->
    <!-- So a space instead.  See comments in Python consumer. -->
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="assembly-id" />
    <xsl:text>&#xa;</xsl:text>
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
