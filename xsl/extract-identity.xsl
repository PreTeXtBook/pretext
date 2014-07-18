<?xml version='1.0'?>

<!--********************************************************************
Copyright 2014 Robert A. Beezer

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
<!-- An importing stylesheet can concentrate on a specific task -->
<!-- It does define a "scratch" directory for placing output    -->
<!-- to presumably be process further by external program       -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- ASCII output intended -->
<xsl:output method="text" />

<!-- Input/Output work/scratch directory from command line (eg, remove X)  -->
<!-- -X-stringparam scratch <some directory string, no trailing backslash> -->
<xsl:param name="scratch" select="'.'"/>

<!-- Traverse the tree,       -->
<!-- looking for things to do -->
<!-- http://stackoverflow.com/questions/3776333/stripping-all-elements-except-one-in-xml-using-xslt -->
<xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
</xsl:template>

</xsl:stylesheet>