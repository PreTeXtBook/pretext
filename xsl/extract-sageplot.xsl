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
<!-- Standard conversion groundwork       -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<!-- Output Sage code as text -->
<xsl:output method="text" encoding="UTF-8"/>

<!-- This stylesheet is parameterized by a requested file format to be  -->
<!-- produced by Sage, which Sage picks up from file extensions in the  -->
<!-- filename argument in a .save() method.  We supply this from the    -->
<!-- pretext/pretext  script, so there is no error checking.  Values    -->
<!-- vary by the @variant of the "sageplot".  *.png  are low-quality    -->
<!-- (not cropped tight), so even if possible for 2D graphics, we do    -->
<!-- not build such a thing.  Otherwise the formats are exclusive to    -->
<!-- their variant (Sage capability).                                   -->
<!--                                                                    -->
<!--   2D variant: pdf (LaTeX), svg (HTML) formats                      -->
<!--   3D variant: png (LaTeX), html (HTML) formats                     -->

<xsl:param name="sageplot.fileformat" select="'pdf'"/>

<!-- Sage graphics to standalone Sage/Python file      -->
<xsl:template match="sageplot" mode="extraction">
    <!-- Construct the file for Sage to execute                    -->
    <!-- Convert final line to an assignment, so we can do save(s) -->
    <!-- First, basename for the file (Sage input, image output)   -->
    <!-- Second, the (unique) name of the graphics object in Sage  -->
    <!-- (We do this first, so we can use "$filebase" below)       -->
    <xsl:variable name="filebase">
        <xsl:apply-templates select=".." mode="visible-id" />
    </xsl:variable>
    <xsl:variable name="plot-name">
        <xsl:text>plot_</xsl:text>
        <xsl:value-of select="generate-id(.)" />
    </xsl:variable>
    <!-- Look to see if "sageplot" is building 2d or 3d -->
    <xsl:variable name="variant">
        <xsl:choose>
            <!-- default is a 2d graphic -->
            <xsl:when test="not(@variant)">
                <xsl:text>2d</xsl:text>
            </xsl:when>
            <xsl:when test="@variant = '2d'">
                <xsl:text>2d</xsl:text>
            </xsl:when>
            <xsl:when test="@variant = '3d'">
                <xsl:text>3d</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>PTX:ERROR:   a "sageplot" has a @variant attribute ("<xsl:value-of select="@variant"/>") for "<xsl:value-of select="$filebase"/>" whose value is not "2d" nor "3d".  The default ("2d") is being used, which could be incorrect</xsl:message>
                <xsl:text>2d</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
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
    <xsl:variable name="b-legal-combination" select="($variant = '2d' and $sageplot.fileformat = 'pdf')
                                                 or  ($variant = '2d' and $sageplot.fileformat = 'svg')
                                                 or  ($variant = '3d' and $sageplot.fileformat = 'png')
                                                 or  ($variant = '3d' and $sageplot.fileformat = 'html')"/>
    <!-- Only certain combinations are supported and only certain       -->
    <!-- combinations are needed in subsequent conversions.  Yes,  this -->
    <!-- setup is all inefficient to just bail out now.                 -->
    <!-- Do not use directories here, as Windows paths will get mangled -->
    <!-- Instead, set working directory before applying stylesheet      -->
    <xsl:if test="$b-legal-combination">
        <exsl:document href="{$filebase}.sage" method="text">
            <!-- Duplicate most code, massage code at last line -->
            <xsl:value-of select="$preamble" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:value-of select="$plot-name" />
            <xsl:text> = </xsl:text>
            <xsl:value-of select="$plotcmd" />
            <xsl:text>&#xa;</xsl:text>
            <!-- We could build a try/except block here, where a ValueError -->
            <!-- indicates a fileformat not supported, but we may have that -->
            <!-- covered.  Would need to get the exception out of the sage  -->
            <!-- executable invocation in the Python script to relay.       -->
            <xsl:value-of select="$plot-name" />
            <xsl:text>.save('</xsl:text>
            <xsl:value-of select="$filebase" />
            <xsl:text>.</xsl:text>
            <xsl:value-of select="$sageplot.fileformat"/>
            <xsl:text>'</xsl:text>
            <!-- Need to inform Sage display manager for 3d HTML that we -->
            <!-- are not inside a notebook or the command-line and we    -->
            <!-- want self-contained  threejs  apllications with         -->
            <!-- Javascript coming from a CDN.                           -->
            <xsl:if test="$sageplot.fileformat = 'html'">
                <xsl:text>, online=True</xsl:text>
            </xsl:if>
            <xsl:text>)&#xa;</xsl:text>
        </exsl:document>
    </xsl:if>
 </xsl:template>

</xsl:stylesheet>
