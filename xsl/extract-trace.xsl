<?xml version='1.0'?>

<!--********************************************************************
Copyright 2022 Robert A. Beezer

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

<!-- This stylesheet locates "program" elements to render as -->
<!-- CodeLens for interactive execution.  The code itself is -->
<!-- processed into a trace by the  pretext/pretext  script. -->
<!-- It produces text output, with one line per program:     -->
<!--                                                         -->
<!--     visible-id, language, source                        -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:str="http://exslt.org/strings"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="str"
>

<!-- Get internal ID's for filenames, etc -->
<!-- Standard conversion groundwork       -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- Needed for processing content embedded in statements/feedback -->
<!-- for checkpoint questions                                      -->
<xsl:import href="./pretext-html.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<xsl:output method="text" encoding="UTF-8"/>

<!-- The default "exercise-style" is "static". For traces,     -->
<!-- we will form a different representation, and pass through -->
<!-- the authored version for a dynamic representation.        -->
<xsl:variable name="exercise-style" select="'dynamic'"/>

<!-- Constructs a block of text for trace output                       -->
<!-- Each of the following as its own line:                            -->
<!--   visible-id                                                      -->
<!--   runestone-id                                                    -->
<!--   trace filename                                                  -->
<!--   language                                                        -->
<!--   code with newlines escaped                                      -->
<!--   starting step                                                   -->
<!-- Followed by 1 line per checkpoint question                        -->
<!-- Block ends with blank line (double newline)                       -->
<xsl:template match="program[@interactive = 'codelens']" mode="extraction">
    <xsl:apply-templates select="." mode="visible-id"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="runestone-id"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="runestone-codelens-trace-filename"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="active-language"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:variable name="code-with-newlines">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="code" />
        </xsl:call-template>
    </xsl:variable>
    <!-- Windows text files do not get normalized when xi:included -->
    <!-- with @parse="text" so a CR-LF line-ending might persist.  -->
    <!-- We do that normalization first, then convert LF to an     -->
    <!-- escape sequence that is necessary for conversion.         -->
    <xsl:variable name="removed-carriage-returns">
        <xsl:value-of select="str:replace($code-with-newlines, '&#xd;&#xa;', '&#xa;')" />
    </xsl:variable>
    <xsl:value-of select="str:replace($removed-carriage-returns, '&#xa;', '\n')"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="@starting-step != ''">
            <!-- Codelens needs to execute n-1 instructions. It has bounds checking -->
            <xsl:value-of select="number(@starting-step) - 1"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
    <xsl:for-each select="checkpoint">
        <xsl:value-of select="@line"/>
        <xsl:text>:||:</xsl:text>
        <xsl:choose>
            <xsl:when test="@answer != ''">
                <xsl:text>literal-</xsl:text><xsl:value-of select="@answer"/>
            </xsl:when>
            <xsl:when test="@answer-variable != ''">
                <xsl:text>variable-</xsl:text><xsl:value-of select="@answer-variable"/>
            </xsl:when>
        </xsl:choose>
        <xsl:text>:||:</xsl:text>
        <xsl:variable name="feedback-contents">
            <xsl:apply-templates select="feedback"/>
        </xsl:variable>
        <xsl:variable name="feedback-string">
            <xsl:apply-templates select="exsl:node-set($feedback-contents)" mode="xml-to-string"/>
        </xsl:variable>
        <xsl:value-of select="$feedback-string"/>
        <xsl:text>:||:</xsl:text>
        <xsl:variable name="prompt-contents">
            <xsl:apply-templates select="prompt"/>
        </xsl:variable>
        <xsl:variable name="prompt-string">
            <xsl:apply-templates select="exsl:node-set($prompt-contents)" mode="xml-to-string"/>
        </xsl:variable>
        <xsl:value-of select="$prompt-string"/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
    <!-- special pattern ends trace group -->
    <xsl:text>!end_codelens_trace_group!</xsl:text>
</xsl:template>

</xsl:stylesheet>
