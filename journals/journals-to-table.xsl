<?xml version="1.0" encoding="UTF-8"?>

<!--********************************************************************
Copyright (C) 2025-2026  Robert A. Beezer

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
*****************************************************************-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

<xsl:template match="/ptx-journals">
    <table>
        <title>Journals supported by PreTeXt</title>
        <tabular>
            <row header="yes">
                <cell>Full Journal Name</cell><cell>Code</cell>
            </row>
            <xsl:apply-templates select="journal"/>
        </tabular>
    </table>

</xsl:template>


<xsl:template match="journal">
    <row bottom="minor">
        <cell><xsl:value-of select="name"/></cell>
        <cell><xsl:value-of select="code"/></cell>
    </row>
</xsl:template>

</xsl:stylesheet>
