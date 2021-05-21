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

<xsl:import href="../pretext-common.xsl"/>
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