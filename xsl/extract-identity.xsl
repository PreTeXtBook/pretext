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
<!-- Possibly restricting to a subtree based on xml:id          -->
<!-- An importing stylesheet can concentrate on a specific task -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:import href="./publisher-variables.xsl" />
<xsl:import href="./pretext-assembly.xsl" />

<!-- We do not specify an output method since nothing gets output from here -->

<!-- This template serves two purposes.                                   -->
<!--                                                                      -->
<!-- 1.  It provides an entry template.                                   -->
<!--                                                                      -->
<!-- At the document root (after assembly) or at the root of some subtree -->
<!-- passed in and indicated by an xml:id for that root.  So a stylesheet -->
<!-- that uses this stylesheet must import this utility stylesheet *last* -->
<!-- so that any entry template of some conversion is overridden.         -->
<!--                                                                      -->
<!--                                                                      -->
<!-- 2.  It establishes a tree walker with mode "extraction".             -->
<!--                                                                      -->
<!-- The modal template here walks the tree and does *nothing* at each    -->
<!-- node, but descend into children and attributes.  So a consuming      -->
<!-- stylesheet can provide its own "extraction" templates to interrupt   -->
<!-- this giant no-op and do something interesting.  Note that this modal -->
<!-- template allows plain/generic templates from established conversions -->
<!-- to be employed, and conceivably overridden, without disturbing the   -->
<!-- tree walk.                                                           -->

<!-- 2020-05-19: This general-purpose template formerly obtained a      -->
<!-- "scratch directory" where intermediate results might be processed. -->
<!-- But if a pathname, in Windows syntax, was passed in, then the      -->
<!-- slashes all got butchered.  Better to set a working directory      -->
<!-- and have "extracttion" worksheets write files, sans paths, into    -->
<!-- that directory.  We leave a warning behind if there is an attempt  -->
<!-- to set this, which will likely be something overlooked in a        -->
<!-- calling script. -->
<xsl:param name="scratch" select="''"/>

<!-- The xml:id of an element to use as the root                -->
<!-- no "subtree" stringparam denotes starting at document root -->
<xsl:param name="subtree" select="''" />

<!-- Entry template, allows restriction to a -->
<!-- subtree rooted at an element identified -->
<!-- by an author-supplied xml:id            -->
<xsl:template match="/">
    <!-- Fail if a scratch directory is set -->
    <xsl:if test="not($scratch = '')">
        <xsl:message terminate="yes">PTX:BUG:     scratch directory provided ("<xsl:value-of select="$scratch" />") which is not supported.  Please report the circumstances revealing this mistake.  Quitting...</xsl:message>
    </xsl:if>
    <xsl:choose>
        <xsl:when test="$subtree=''">
            <xsl:apply-templates select="$root" mode="extraction"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- Context is root of *original* source as we are in the entry template. -->
            <!-- The "for-each" allows a switch to the duplicate (assembled) source,   -->
            <!-- so the id() function scans the enhanced tree.                         -->
            <xsl:for-each select="$root">
                <xsl:variable name="subtree-root" select="id($subtree)"/>
                <xsl:if test="not($subtree-root)">
                    <xsl:message terminate="yes">MBX:FATAL:   xml:id provided ("<xsl:value-of select="$subtree"/>") for restriction to a subtree does not exist.  Quitting...</xsl:message>
                </xsl:if>
                <xsl:apply-templates select="$subtree-root" mode="extraction"/>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Traverse the tree,       -->
<!-- looking for things to do -->
<!-- http://stackoverflow.com/questions/3776333/stripping-all-elements-except-one-in-xml-using-xslt -->
<xsl:template match="@*|node()" mode="extraction">
    <xsl:apply-templates select="@*|node()" mode="extraction"/>
</xsl:template>

</xsl:stylesheet>
