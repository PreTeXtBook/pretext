<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2015                                                        -->
<!-- Robert A. Beezer, Michael Gage, Geoff Goehle, Alex Jordan             -->
<!--                                                                       -->
<!-- This file is part of MathBook XML.                                    -->
<!--                                                                       -->
<!-- MathBook XML is free software: you can redistribute it and/or modify  -->
<!-- it under the terms of the GNU General Public License as published by  -->
<!-- the Free Software Foundation, either version 2 or version 3 of the    -->
<!-- License (at your option).                                             -->
<!--                                                                       -->
<!-- MathBook XML is distributed in the hope that it will be useful,       -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of        -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         -->
<!-- GNU General Public License for more details.                          -->
<!--                                                                       -->
<!-- You should have received a copy of the GNU General Public License     -->
<!-- along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>. -->
<!-- ********************************************************************* -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<!-- paths assume we place  extract-webwork.xsl in mathbook "user" directory -->
<!-- paths assume we place  webwork-pg.xsl      in mathbook "user" directory -->
<xsl:import href="../xsl/mathbook-common.xsl" />
<xsl:import href="./webwork-pg.xsl" />

<!-- Intend output to be a PG/PGML problem -->
<xsl:output method="text" />

<!-- ############## -->
<!-- Entry template -->
<!-- ############## -->

<!-- Override chunking routine from common file as entry template -->
<!-- We are simply extracting webwork problems at any level       -->
<xsl:template match="/">
    <xsl:apply-templates select="//webwork" />
</xsl:template>

<!-- ################## -->
<!-- Extraction Wrapper -->
<!-- ################## -->

<!-- Extracted a problem into its own file                -->
<!-- This is a wrapper around the "normal" representation -->
<xsl:template match="webwork">
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="internal-id" />
        <xsl:text>.pg</xsl:text>
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <xsl:apply-imports />
    </exsl:document>
</xsl:template>

</xsl:stylesheet>