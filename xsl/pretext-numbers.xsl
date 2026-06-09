<?xml version='1.0'?>

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!--********************************************************************
Copyright 2020 Robert A. Beezer

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

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
    exclude-result-prefixes="pi"
>

<!-- Intend output as plain text (numbers) -->
<xsl:output method="text" encoding="UTF-8"/>

<!-- Read documentation in the "-assembly" stylesheet to understand -->
<!-- employment/purpose of these templates there.                   -->
<!--                                                                -->
<!-- 2021-12-22: moving the computation of serial numbers out of    -->
<!-- the "-common" stylesheet, so as to be pre-computed.            -->


<!-- ######################## -->
<!-- Block Structure Numbers  -->
<!-- ######################## -->

<!-- Given a block element, produce its structure number prefix      -->
<!-- by reading the pre-computed @block-struct from the nearest      -->
<!-- ancestor division, then truncating or padding to the configured -->
<!-- number of levels.  The @block-struct chain already excludes     -->
<!-- parts (they are squelched in assembly), so when parts are       -->
<!-- present the caller's $levels (which counts from "part" depth)   -->
<!-- must be reduced by one to match the shorter chain.              -->
<xsl:template name="block-structure-number">
    <xsl:param name="levels"/>
    <xsl:variable name="raw-struct"
        select="ancestor::*[@block-struct][1]/@block-struct"/>
    <!-- The @block-struct chain already excludes parts, so when  -->
    <!-- parts are present the $levels count (which includes the -->
    <!-- part depth) must be reduced by one.  But only for       -->
    <!-- blocks actually inside a part or backmatter — blocks    -->
    <!-- in frontmatter have no part ancestor and should use     -->
    <!-- $levels unmodified.                                     -->
    <xsl:variable name="effective-levels">
        <xsl:choose>
            <xsl:when test="not($parts = 'absent') and ancestor::*[self::part or self::backmatter]">
                <xsl:choose>
                    <xsl:when test="$levels > 0">
                        <xsl:value-of select="$levels - 1"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="0"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$levels"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="truncate-pad-struct">
        <xsl:with-param name="struct" select="$raw-struct"/>
        <xsl:with-param name="levels" select="$effective-levels"/>
    </xsl:call-template>
</xsl:template>

<!-- Truncate a dotted-number string to a given number of     -->
<!-- components, padding with ".0" if fewer components exist.  -->
<xsl:template name="truncate-pad-struct">
    <xsl:param name="struct"/>
    <xsl:param name="levels"/>
    <xsl:param name="count" select="0"/>

    <xsl:choose>
        <!-- Emitted enough levels, halt -->
        <xsl:when test="$count = $levels"/>
        <!-- Components remaining in the string -->
        <xsl:when test="$struct != ''">
            <xsl:if test="$count > 0">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="contains($struct, '.')">
                    <xsl:value-of select="substring-before($struct, '.')"/>
                    <xsl:call-template name="truncate-pad-struct">
                        <xsl:with-param name="struct"
                            select="substring-after($struct, '.')"/>
                        <xsl:with-param name="levels" select="$levels"/>
                        <xsl:with-param name="count" select="$count + 1"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$struct"/>
                    <xsl:call-template name="truncate-pad-struct">
                        <xsl:with-param name="struct" select="''"/>
                        <xsl:with-param name="levels" select="$levels"/>
                        <xsl:with-param name="count" select="$count + 1"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- Out of components, pad with zero -->
        <xsl:otherwise>
            <xsl:if test="$count > 0">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <xsl:text>0</xsl:text>
            <xsl:call-template name="truncate-pad-struct">
                <xsl:with-param name="struct" select="''"/>
                <xsl:with-param name="levels" select="$levels"/>
                <xsl:with-param name="count" select="$count + 1"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
