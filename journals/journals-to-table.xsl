<?xml version="1.0" encoding="UTF-8"?>

<!--********************************************************************
Copyright (C) 2025-2026  Robert A. Beezer

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
*****************************************************************-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

<xsl:template match="/ptx-journals">
    <table>
        <title>Journals supported by PreTeXt</title>
        <tabular>
            <row header="yes">
                <cell>Full Journal Name</cell><cell>Code</cell><cell>Bibliography Style</cell>
            </row>
            <xsl:apply-templates select="journal"/>
        </tabular>
    </table>

</xsl:template>


<xsl:template match="journal">
    <row bottom="minor">
        <cell><xsl:value-of select="name"/></cell>
        <cell><xsl:value-of select="code"/></cell>
        <cell><xsl:apply-templates select="." mode="csl-style"/></cell>
    </row>
</xsl:template>


<!-- The CSL style a journal uses for its bibliography and citations.    -->
<!-- This repeats, for documentation only, the resolution that           -->
<!-- get_journal_info() performs at build time (see pretext.py): a "csl" -->
<!-- attribute on "method" overrides, otherwise the journal's texstyle   -->
<!-- file supplies it, or the file that one extends.  Keep the two in    -->
<!-- step; this stylesheet is run by hand, by journals/build.sh, and     -->
<!-- never during a conversion.                                          -->
<xsl:template match="journal" mode="csl-style">
    <xsl:variable name="texstyle-file">
        <xsl:text>texstyles/</xsl:text>
        <xsl:if test="method/@dependent = 'yes'">
            <xsl:text>dependents/</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="method/@texstyle">
                <xsl:value-of select="method/@texstyle"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="code"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>.xml</xsl:text>
    </xsl:variable>
    <xsl:variable name="texstyle" select="document($texstyle-file)/texstyle"/>
    <!-- Guarded by an "if": a file that extends nothing must not send -->
    <!-- document() looking for "texstyles/.xml".                      -->
    <xsl:variable name="inherited-style">
        <xsl:if test="$texstyle/metadata/extends">
            <xsl:value-of select="document(concat('texstyles/', $texstyle/metadata/extends, '.xml'))/texstyle/metadata/csl-style/@name"/>
        </xsl:if>
    </xsl:variable>
    <xsl:choose>
        <!-- a journal that names its own style -->
        <xsl:when test="method/@csl">
            <xsl:value-of select="method/@csl"/>
        </xsl:when>
        <!-- the style of its texstyle file -->
        <xsl:when test="$texstyle/metadata/csl-style/@name">
            <xsl:value-of select="$texstyle/metadata/csl-style/@name"/>
        </xsl:when>
        <!-- or of the file that one extends -->
        <xsl:when test="$inherited-style != ''">
            <xsl:value-of select="$inherited-style"/>
        </xsl:when>
        <!-- a journal with no style of its own: the publisher chooses -->
        <xsl:otherwise>
            <xsl:text>(none)</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
