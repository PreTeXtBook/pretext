<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2022 Robert A. Beezer

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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<xsl:import href="./pretext-html.xsl"/>

<!-- We create HTML5 output.  The @doctype-system attribute will    -->
<!-- create a header in the old style that browsers will recognize  -->
<!-- as signaling HTML5.  However  xsltproc  does one better and    -->
<!-- writes the super-simple <!DOCTYPE html> header.  See all of    -->
<!-- https://stackoverflow.com/questions/3387127/                   -->
<!-- (set-html5-doctype-with-xslt)                                  -->
<!--                                                                -->
<!-- Since we write output into a single file, likely this          -->
<!-- declaration is never active, but it serves as a model here for -->
<!-- subsequent exsl:document elements.                             -->

<xsl:output method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat" />

<!-- It will be a problem if an author decides to name an interactive -->
<!-- identically but we will consider this highly unlikely.           -->
<xsl:variable name="main-file" select="'dynamics-needing-static-parsing.html'"/>
<xsl:variable name="b-dynamics-static-seed" select="true()"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Build a single page.  Actual use will require copying/placing      -->
<!-- necessary "external" support files (JS, CSS, iframe HTML content). -->
<xsl:template match="/">
    <xsl:apply-templates select="$document-root//exercise[//setup]" mode="standalone-page"/>
</xsl:template>

</xsl:stylesheet>
