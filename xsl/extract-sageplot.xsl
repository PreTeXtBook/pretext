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

<!-- This stylesheet locates <sageplot> elements     -->
<!-- and bundles them into a Sage/Python program     -->
<!-- The program accepts one command-line parameter: -->
<!-- the file extension of the desired format        -->
<!-- (i.e. svg, eps, pdf, png, etc)                  -->
<!-- N.B. 3D plots always render as PNG              -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" 
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<!-- Get internal ID's for filenames, etc -->
<xsl:import href="./pretext-common.xsl" />

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<!-- Output Sage code as text -->
<xsl:output method="text" />

<!-- Sage graphics to standalone Sage/Python file      -->
<xsl:template match="sageplot" mode="extraction">
    <!-- has one trailing newline, which we ignore later (?) -->
    <xsl:variable name="plot-code-sanitary">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    </xsl:variable>
    <!-- remove the trailing newline provided by sanitization -->
    <xsl:variable name="plot-code-trimmed" select="substring($plot-code-sanitary,1,string-length($plot-code-sanitary)-1)"/>
    <!-- conditionally provide a breakpoint for single-line source -->
    <xsl:variable name="plot-code">
        <xsl:if test="not(contains($plot-code-trimmed, '&#xa;'))">
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
        <xsl:value-of select="$plot-code-trimmed"/>
    </xsl:variable>
    <!-- split on last newline, which is first character for single-line source -->
    <xsl:variable name="preamble">
        <xsl:call-template name="substring-before-last">
            <xsl:with-param name="input" select="$plot-code"/>
            <xsl:with-param name="substr" select="'&#xa;'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="plotcmd">
        <xsl:call-template name="substring-after-last">
            <xsl:with-param name="input" select="$plot-code"/>
            <xsl:with-param name="substr" select="'&#xa;'" />
        </xsl:call-template>
    </xsl:variable>
    <!-- Construct the file for Sage to execute                    -->
    <!-- Convert final line to an assignment, so we can do save(s) -->
    <!-- First, basename for the file (Sage input, image output)   -->
    <!-- Second, the (unique) name of the graphics object in Sage  -->
    <xsl:variable name="filebase">
        <xsl:apply-templates select=".." mode="visible-id" />
    </xsl:variable>
    <xsl:variable name="plot-name">
        <xsl:text>plot_</xsl:text>
        <xsl:value-of select="generate-id(.)" />
    </xsl:variable>
    <!-- Do not use directories here, as Windows paths will get mangled -->
    <!-- Instead, set working directory before applying stylesheet      -->
    <exsl:document href="{$filebase}.sage" method="text">
        <!-- Module so we can pass file extension parameter on command line -->
        <xsl:text>import sys&#xa;</xsl:text>
        <xsl:text>suffix = sys.argv[1]&#xa;</xsl:text>
        <!-- Duplicate most code, massge code at last line -->
        <xsl:value-of select="$preamble" />
        <xsl:text>&#xa;</xsl:text>
        <xsl:value-of select="$plot-name" />
        <xsl:text> = </xsl:text>
        <xsl:value-of select="$plotcmd" />
        <xsl:text>&#xa;</xsl:text>
        <!-- Sage 2D plots can be made into SVGs  -->
        <!-- or many other formats routinely, -->
        <!-- but for 3D plots only PNG is possible -->
        <!-- So we try the former and default to the latter -->
        <xsl:text>try:&#xa;</xsl:text>
        <xsl:text>    </xsl:text>
        <xsl:value-of select="$plot-name" />
        <xsl:text>.save("</xsl:text>
        <xsl:value-of select="$filebase" />
        <xsl:text>.{}".format(suffix))&#xa;</xsl:text>
        <xsl:text>except ValueError:&#xa;</xsl:text>
        <xsl:text>    </xsl:text>
        <xsl:value-of select="$plot-name" />
        <xsl:text>.save("</xsl:text>
        <xsl:value-of select="$filebase" />
        <xsl:text>.png")&#xa;</xsl:text>
    </exsl:document>
 </xsl:template>

</xsl:stylesheet>
