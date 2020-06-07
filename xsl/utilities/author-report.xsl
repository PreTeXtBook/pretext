<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2018 Robert A. Beezer

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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" >

<!-- NB: (2020-06-07) xref/@provisional gets replaced by placeholder -->
<!-- text in the "assembly" phase, so think carefully about whether  -->
<!-- or not this stylesheet should run against orginal source or     -->
<!-- enhanced source, they *are* different.                          -->

<!-- Uses "strip-leading-whitespace" and more -->
<xsl:import href="../pretext-common.xsl"/>

<!-- ASCII output intended, consistent with -common -->
<xsl:output method="text" />

<!-- Generally, traverse the tree,                       -->
<!-- looking for things to do                            -->
<!-- http://stackoverflow.com/questions/3776333/         -->
<!-- stripping-all-elements-except-one-in-xml-using-xslt -->
<xsl:template match="@*|node()|comment()">
    <xsl:apply-templates select="@*|node()|comment()"/>
</xsl:template>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<xsl:template match="/">
    <xsl:call-template name="converter-blurb-text"/>
    <xsl:apply-templates select="$document-root" />
</xsl:template>

<!-- Headers, per division or structure -->
<xsl:template match="&STRUCTURAL;">
    <xsl:text>&#xa;**************************************&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="long-name" />
    <xsl:text>&#xa;**************************************&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::subtitle)]|comment()"/>
</xsl:template>

<!-- Kill titles as metadata, but restore behavior on nodes to   -->
<!-- allow the "long-name" template above to perform as intended -->
<xsl:template match="title"/>
<xsl:template match="title/node()">
    <xsl:value-of select="." />
</xsl:template>

<!-- Looking for todo's and provisional citations, cross-references -->
<!-- May need to abandon counting if conditions get more complex    -->

<!-- This template comes close to doing the right thing, -->
<!-- but is off by one (or more) in strange ways, so we  -->
<!-- are not numbering the reported items                -->
<xsl:template match="xref|comment()" mode="overall-number">
    <xsl:number level="any" count="xref[@provisional]|comment()[translate(substring(normalize-space(string(.)), 1, 4), &UPPERCASE;, &LOWERCASE;) = 'todo']"/>
</xsl:template>

<xsl:template match="comment()[translate(substring(normalize-space(string(.)), 1, 4), &UPPERCASE;, &LOWERCASE;) = 'todo']">
    <!-- <xsl:apply-templates select="." mode="overall-number"/> -->
    <!-- <xsl:text>. </xsl:text> -->
    <xsl:call-template name="strip-leading-whitespace">
        <xsl:with-param name="text">
            <xsl:value-of select="."/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="xref[@provisional]">
    <!-- <xsl:apply-templates select="." mode="overall-number"/> -->
    <!-- <xsl:text>.</xsl:text> -->
    <xsl:text>xref: </xsl:text>
    <xsl:value-of select="@provisional" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>