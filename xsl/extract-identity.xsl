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

<!-- This stylesheet does nothing but traverse the tree         -->
<!-- Possible restricting to a subtree based on xml:id          -->
<!-- An importing stylesheet can concentrate on a specific task -->
<!-- It does define a "scratch" directory for placing output    -->
<!-- to presumably be process further by external program       -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- We do not specify an output method since nothing gets output from here -->

<!-- Input/Output work/scratch directory from command line (eg, remove X)  -->
<!-- -X-stringparam scratch <some directory string, no trailing backslash> -->
<!-- TODO: this parameter really does not belong here, but is convenient   -->
<xsl:param name="scratch" select="'.'"/>

<!-- The xml:id of an element to use as the root                -->
<!-- no "subtree" stringparam denotes starting at document root -->
<xsl:param name="subtree" select="''" />

<!-- Entry template, allows restriction to a -->
<!-- subtree rooted at an element identified -->
<!-- by an author-supplied xml:id            -->
<xsl:template match="/">
    <xsl:choose>
        <xsl:when test="$subtree=''">
            <xsl:apply-templates />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="subtree-root" select="id($subtree)" />
            <xsl:if test="not($subtree-root)">
                <xsl:message terminate="yes">MBX:ERROR:   xml:id provided ("<xsl:value-of select="$subtree" />") for restriction to a subtree does not exist.  Quitting...</xsl:message>
            </xsl:if>
            <xsl:apply-templates select="$subtree-root" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Traverse the tree,       -->
<!-- looking for things to do -->
<!-- http://stackoverflow.com/questions/3776333/stripping-all-elements-except-one-in-xml-using-xslt -->
<xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
</xsl:template>

</xsl:stylesheet>
