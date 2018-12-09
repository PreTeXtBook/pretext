<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace" >

<xsl:import href="./mathbook-common.xsl" />

<!-- ASCII output intended -->
<xsl:output method="text" />

<!-- Traverse the tree,       -->
<!-- looking for things to do -->
<!-- http://stackoverflow.com/questions/3776333/stripping-all-elements-except-one-in-xml-using-xslt -->
<xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
</xsl:template>

<!-- Headers, per sectioning -->
<xsl:template match="book|article|preface|chapter|section|subsection|subsubsection|references|exercises|frontmatter|backmatter">
    <xsl:text>&#xa;************************&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="long-name"/>
    <xsl:text>&#xa;************************&#xa;</xsl:text>
    <xsl:apply-templates select="*[not(self::title)]"/>
</xsl:template>

<!-- Looking for todo's and provisional citations, cross-references -->
<!-- Can't seem to get numbers to right-justify easily (across fixed field width) -->
<xsl:template match="todo">
    <xsl:number level="any" count="todo|xref[@provisional]|cite[@provisional]"/>
    <xsl:text>. </xsl:text>
    <xsl:value-of select="." />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="xref[@provisional]">
    <xsl:number level="any" count="todo|xref[@provisional]|cite[@provisional]"/>
    <xsl:text>. xref: </xsl:text>
    <xsl:value-of select="@provisional" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="cite[@provisional]">
    <xsl:number level="any" count="todo|xref[@provisional]|cite[@provisional]"/>
    <xsl:text>. cite: </xsl:text>
    <xsl:value-of select="@provisional" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Explicitly kill titles and do not recurse            -->
<!-- But get *value* of their nodes for long-name templates -->
<xsl:template match="title">
</xsl:template>

<xsl:template match="title/node()">
    <xsl:value-of select="." />
</xsl:template>

</xsl:stylesheet>