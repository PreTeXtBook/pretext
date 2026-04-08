<?xml version='1.0'?>

<!--********************************************************************
Copyright 2014-2016 Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- This stylesheet extracts URL information for audio, video,  -->
<!-- and interactive elements.  For each, it writes a sidecar    -->
<!-- XML file (via exsl:document) containing a standalone URL    -->
<!-- and an in-context URL, used later for QR code generation    -->
<!-- (Python) and for links in static representations            -->
<!-- (pretext-assembly.xsl).                                     -->
<!--                                                             -->
<!-- It is hard to get a link into chunked HTML while actually   -->
<!-- building generic PreTeXt for a static representation.  The  -->
<!-- chunking level and file extension are format-specific, but  -->
<!-- assembly must remain format-neutral.  So we set HTML-        -->
<!-- specific variables ($chunk-level, $file-extension) here in  -->
<!-- the extraction stylesheet, which has the highest import     -->
<!-- precedence.  Assembly then reads the pre-computed URLs from  -->
<!-- the sidecar files rather than computing them itself.         -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    extension-element-prefixes="exsl"
>

<!-- Get internal ID's for filenames, etc -->
<!-- Standard conversion groundwork       -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<xsl:output method="text" encoding="UTF-8"/>

<!-- Avoid Catch-22: default assembly/pre-processor provides output  -->
<!-- for a conversion to a static format, but that format will       -->
<!-- *replace* "audio", "video", "interactive" by a static version   -->
<!-- (a "sidebyside") and it will not be available for extraction.    -->
<xsl:variable name="exercise-style" select="'dynamic'"/>

<!-- In "normal" circumstances, this variable is   -->
<!-- set to "false()", but when employing this     -->
<!-- specialized stylesheet, we override to "true" -->
<xsl:variable name="b-extracting-qrcode" select="true()"/>

<!-- Set HTML-specific variables so that "containing-filename" -->
<!-- (used by "context-url") produces correct HTML filenames.  -->
<!-- These override the abstract defaults in pretext-common.xsl -->
<!-- by virtue of this stylesheet's higher import precedence.   -->
<xsl:variable name="chunk-level" select="$html-chunk-level"/>
<xsl:variable name="file-extension" select="'.html'"/>

<xsl:template match="audio[@source|@href]|video[@source|@href|@youtube|@youtubeplaylist|@vimeo]|interactive" mode="extraction">
    <!-- Sidecar XML file with pre-computed URLs for use      -->
    <!-- by pretext-assembly.xsl when building static         -->
    <!-- representations, and by the Python script when       -->
    <!-- generating QR code images.                           -->
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <exsl:document href="{$the-id}-url.xml" method="xml">
        <pi:qrcode-urls>
            <pi:standalone-url>
                <xsl:apply-templates select="." mode="static-url"/>
            </pi:standalone-url>
            <pi:context-url>
                <xsl:apply-templates select="." mode="context-url"/>
            </pi:context-url>
            <pi:embed-iframe-url>
                <xsl:apply-templates select="." mode="embed-iframe-url"/>
            </pi:embed-iframe-url>
        </pi:qrcode-urls>
    </exsl:document>
</xsl:template>

</xsl:stylesheet>
