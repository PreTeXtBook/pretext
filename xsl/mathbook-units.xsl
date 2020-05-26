<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    >
<!-- mathbook-*.xsl is deprecated -->
<xsl:import href="./pretext-units.xsl"/>
<xsl:template match="/">
  <xsl:message>PTX:WARNING: Use of mathbook-*.xsl stylesheets is deprecated. These will be removed in future versions.  Switch now to using the pretext-*.xsl variant instead.</xsl:message>
  <xsl:apply-imports/>
</xsl:template>
</xsl:stylesheet>