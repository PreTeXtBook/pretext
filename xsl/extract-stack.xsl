<?xml version='1.0'?>

<!--********************************************************************
Copyright 2014-2016 Robert A. Beezer

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

<!-- This stylesheet locates all  exercise/stack-moodle  elements   -->
<!-- and writtes out a single file for each one (these will be sent -->
<!-- to a server for conversion to static forms)                    -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:stk="http://stack-assessment.org/2025/moodle-question"
    exclude-result-prefixes="stk"
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

<!-- Flag an extraction pass, so pretext-assembly does not get confused -->
<xsl:variable name="b-extracting-stack" select="true()"/>

<xsl:template match="exercise/stk:stack-moodle" mode="extraction">
    <xsl:variable name="filebase">
        <xsl:apply-templates select="." mode="assembly-id"/>
    </xsl:variable>

    <!-- TODO: perhaps this template could be in -common, see pretext-html.xsl -->
    <!-- TODO: make this a general purpose templare (in -common)  -->
    <!-- TODO: use an "edit" template to scrub junk from assembly -->
    <!--       Note: @xml:base might be worth keeping/adjusting   -->
    <exsl:document href="{$filebase}.xml" method="xml" encoding="UTF-8">
        <!-- don't copy the "stack" element, just children -->
        <xsl:copy-of select="node()"/>
    </exsl:document>
</xsl:template>

</xsl:stylesheet>
