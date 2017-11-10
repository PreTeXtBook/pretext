<?xml version='1.0'?>

<!-- ********************************************************************* -->
<!-- Copyright 2017                                                        -->
<!-- Robert A. Beezer, Alex Jordan                                         -->
<!--                                                                       -->
<!-- This file is part of PreTeXt.                                         -->
<!--                                                                       -->
<!-- PreTeXt is free software: you can redistribute it and/or modify       -->
<!-- it under the terms of the GNU General Public License as published by  -->
<!-- the Free Software Foundation, either version 2 or version 3 of the    -->
<!-- License (at your option).                                             -->
<!--                                                                       -->
<!-- PreTeXt is distributed in the hope that it will be useful,            -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of        -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         -->
<!-- GNU General Public License for more details.                          -->
<!--                                                                       -->
<!-- You should have received a copy of the GNU General Public License     -->
<!-- along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.      -->
<!-- ********************************************************************* -->

<!-- Identify as a stylesheet -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    exclude-result-prefixes="xsl"
>

<!-- Occasionally there is a need to use auxiliary XML files to process    -->
<!-- PTX. This style sheet merges source with the auxiliary XML so that    -->
<!-- there can be a new single XML tree for further processing by the      -->
<!-- primary PTX style sheets.                                             -->

<!-- List of auxiliary XML this sytle sheet merges:                        -->
<!-- * WeBWorK extractions                                                 -->

<xsl:import href="./mathbook-common.xsl" />

<!-- We output a single, large .ptx file for further -->
<!-- processing by other PTX style sheets            -->
<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<!-- Location of webwork-extraction                  -->
<!-- These are collected from a webwork server       -->
<!-- by the ptx script, webwork component            -->
<xsl:param name="webwork.extraction" select="''" />
<xsl:variable name="b-webwork-extraction" select="not($webwork.extraction = '')" />

<!-- Match root, then start copying content -->
<xsl:template match="/">
    <xsl:copy>
        <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
</xsl:template>

<!-- Walk the tree, copying everything as-is, except common -->
<!-- templates applied, and webwork elements modified below -->
<xsl:template match="@* | node()">
    <xsl:copy>
        <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
</xsl:template>

<!-- Don't match on simple WeBWorK logo       -->
<!-- Seed and possibly source attributes      -->
<!-- Then authored?, pg?, and static children -->
<xsl:template match="webwork[node()|@*]">
    <xsl:if test="not($b-webwork-extraction)">
        <xsl:message terminate="yes">PTX:ERROR   You must specify the location of the webwork extraction using the "webwork.extraction" command line stringparam.  Use the mbx script and webwork component to collect these files from a WeBWorK server. Quitting...</xsl:message>
    </xsl:if>
    <xsl:variable name="ww-id">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>
    <xsl:copy-of select="document($webwork.extraction)/webwork-extraction/webwork-reps[@ww-id=$ww-id]" />
</xsl:template>

</xsl:stylesheet>
