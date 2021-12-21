<?xml version='1.0'?>

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
>

<!-- This stylesheet should behave, without any errors, without    -->
<!-- importing the "pretext-common.xsl" stylesheet.  Typically,    -->
<!-- in other uses of the two stylesheets above, we import         -->
<!-- "pretext-common.xsl" as well, which will include many         -->
<!-- "strip-space" directives, which will impact the assembled     -->
<!-- source (without any real harm, though, just different).       -->
<!-- In other words, the two (symbiotic) stylesheets used here     -->
<!-- should remain independent of the -common stylesheet.          -->
<!--                                                               -->
<!-- The "publisher-variables.xsl" and "pretext-assembly.xsl"      -->
<!-- stylesheets are symbiotic, and should be imported             -->
<!-- simultaneously.  Assembly will change the source in various   -->
<!-- ways, while some defaults for publisher variables will depend -->
<!-- on source.  The default variables should depend on gross      -->
<!-- structure and adjustments should be to smaller portions of    -->
<!-- the source, but we don't take any chances.  So, note in       -->
<!-- "assembly" that an intermediate tree is defined as a          -->
<!-- variable, which is then used in defining some variables,      -->
<!-- based on assembled source.  Conversely, certain variables,    -->
<!-- such as locations of customizations or private solutions,     -->
<!-- are needed early in assembly, while other variables, such     -->
<!-- as options for numbering, are needed for later enhancements   -->
<!-- to the source.  If new code results in undefine, or           -->
<!-- recursively defined, variables, this discussion may be        -->
<!-- relevant.  (This is repeated verbatim in the other            -->
<!-- stylesheet).                                                  -->

<xsl:import href="../publisher-variables.xsl"/>
<xsl:import href="../pretext-assembly.xsl"/>

<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- $root points to intermediate enhanced source created        -->
<!-- in the "pretext-assembly.xsl" stylesheet, so study that     -->
<!-- stylesheet to understand what it is being displayed.        -->
<!-- This stylesheet will be affected by whatever parameters     -->
<!-- and auxiliary files that the assembly stylesheet reacts to. -->

<xsl:template match="/">
    <xsl:apply-templates select="$root" mode="showme"/>
</xsl:template>

<xsl:template match="node()|@*" mode="showme">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="showme"/>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>