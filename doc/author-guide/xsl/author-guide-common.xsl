<?xml version='1.0'?>

<!-- This file is part of the documentation of MathBook XML   -->
<!--                                                          -->
<!--    MathBook XML Author's Guide                           -->
<!--                                                          -->
<!-- Copyright (C) 2013-2016  Robert A. Beezer                -->
<!-- See the file COPYING for copying conditions.             -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<!-- Copy three author-guide-*.xsl to $MATHBOOK/user -->

<!-- We run with autonaming by default -->
<xsl:param name="autoname" select="'yes'" />

<!-- XML syntax simplified -->
<!-- TODO: move into mathbook-common for long-term use -->

<xsl:template match="tag">
    <xsl:variable name="the-element">
        <c>
            <text>&lt;</text>
            <xsl:apply-templates />
            <xsl:text>&gt;</xsl:text>
        </c>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($the-element)" />
</xsl:template>

<!-- An empty tag -->
<xsl:template match="tage">
    <xsl:variable name="the-element">
        <c>
            <text>&lt;</text>
            <xsl:apply-templates />
            <xsl:text> /&gt;</xsl:text>
        </c>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($the-element)" />
</xsl:template>

<xsl:template match="attribute">
    <xsl:variable name="the-attribute">
        <c>
            <text>@</text>
            <xsl:apply-templates />
        </c>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($the-attribute)" />
</xsl:template>

</xsl:stylesheet>
