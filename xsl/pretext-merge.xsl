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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- The function of this file has been subsumed into the "assembly" -->
<!-- phase of processing PreTeXt source, and so its only purpose is  -->
<!-- to announce its retirement as of 2020-06-19.                    -->
<xsl:template match="/">
    <xsl:message>
        <xsl:text>************************************************************&#xa;</xsl:text>
        <xsl:text>The WeBWorK merge stylesheet is no longer necessary and no&#xa;</xsl:text>
        <xsl:text>longer has any functionality.  Any regular PreTeXt conversion&#xa;</xsl:text>
        <xsl:text>will now incorporate the WeBWorK problem representations if&#xa;</xsl:text>
        <xsl:text>the file is specified in the publisher file.  Consult the&#xa;</xsl:text>
        <xsl:text>documentation for more details.  (2020-06-19)&#xa;</xsl:text>
        <xsl:text>************************************************************&#xa;</xsl:text>
    </xsl:message>
</xsl:template>

</xsl:stylesheet>
