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
<xsl:variable name="main-file" select="'interactives-needing-snapshotting.html'"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Build a single page.  Actual use will require copying/placing      -->
<!-- necessary "external" support files (JS, CSS, iframe HTML content). -->
<!-- NB: the -html template for the root will process it's one lone     -->
<!-- child, "pretext", and that is where language support begins        -->
<!-- (ends?), which is necessary for Sage cell construction (in the     -->
<!-- head) to pick up the text of the "Evaluate" button.                -->
<!-- Also, that template begins at $root, etc.                          -->

<!-- But we set $has-native-search to false to squelch generation  of   -->
<!-- search docvuments, which are not needed.                           -->

<xsl:variable name="has-native-search" select="false()"/>

<!-- Only without an author-supplied preview -->
<xsl:template match="/pretext">
    <xsl:apply-templates select=".//interactive[not(@preview)]"/>
</xsl:template>

<!-- Make the iframe for each interactive, these are  -->
<!-- two of the three steps in the non-modal template -->
<!-- for "interactive" in pretext-html.xsl            -->
<xsl:template match="interactive">
    <!-- (2) Identical content, but now isolated on a reader-friendly page -->
    <xsl:apply-templates select="." mode="standalone-page" >
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="interactive-core" />
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- (3) A simple page that can be used in an iframe construction -->
    <xsl:apply-templates select="." mode="create-iframe-page" />
</xsl:template>

</xsl:stylesheet>
