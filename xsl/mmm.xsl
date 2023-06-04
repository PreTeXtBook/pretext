<?xml version="1.0"?>

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foo="foo-namespace"
>
    <xsl:output method="text" encoding="utf-8" />

    <xsl:template name="mmm">
        MMMM
    </xsl:template>
    <xsl:template match="myelm">
        MYELM
    </xsl:template>
    <xsl:template match="foo:myfooelm">
        MYFOOELM
    </xsl:template>
    
</xsl:stylesheet>