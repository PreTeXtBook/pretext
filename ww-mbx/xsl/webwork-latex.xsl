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
>

<!-- path assumes we place  webwork-latex.xsl  in mathbook "user" directory -->
<xsl:import href="../xsl/mathbook-latex.xsl" />

<!-- Intend output to be a LaTeX source -->
<xsl:output method="text" />




<!-- Unimplemented, currently killed -->
<xsl:template match="webwork/title" />


<!-- ####################### -->
<!-- Static, Named Templates -->
<!-- ####################### -->


<!-- Since we use XSLT 1.0, this is how we create -->
<!-- "width" underscores for a PGML answer blank  -->
<xsl:template name="underscore">
    <xsl:param name="width" select="5" />
    <xsl:if test="not($width = 0)">
        <xsl:text>_</xsl:text>
        <xsl:call-template name="underscore">
            <xsl:with-param name="width" select="$width - 1" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

</xsl:stylesheet>
