<?xml version='1.0'?>

<!--********************************************************************
Copyright 2018 Robert A. Beezer

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

<!-- This stylesheet locates video/@youtube elements and -->
<!-- prepares a Python dictionary necessary to extract a -->
<!-- thumbnail for each video from the YouTube servers   -->

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

<xsl:output method="text" encoding="UTF-8"/>

<!-- We need to alert the pretext-assembly.xsl stylesheet     -->
<!-- that it is being used in the very specific instance      -->
<!-- of extracting these objects for processing externally,   -->
<!-- with results collected in additional files, for          -->
<!-- consultation/collection in a more general use of this    -->
<!-- stylesheet for the purpose of actually building a useful -->
<!-- output format.  This variable declaration here overrides -->
<!-- the default setting of "false" in pretext-assembly.xsl.  -->
<!-- Look there for a more comprehensive discussion of the    -->
<!-- necessity of this scheme.                                -->
<xsl:variable name="b-extracting-mom" select="true()"/>

<!-- One problem id per line -->
<xsl:template match="myopenmath[@problem]" mode="extraction">
    <xsl:value-of select="@problem" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
