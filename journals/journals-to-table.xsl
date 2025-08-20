<?xml version="1.0" encoding="UTF-8"?>

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
