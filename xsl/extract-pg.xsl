<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2015-7                                                      -->
<!-- Robert A. Beezer, Michael Gage, Geoff Goehle, Alex Jordan             -->
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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="str"
>

<!-- This style sheet is intended to be used by the ptx script. It makes   -->
<!-- several Python dictionaries that the ptx script will use to create a  -->
<!-- single XML file called webwork-extraction.xml with various            -->
<!-- representations of each webwork.                                      -->

<!-- Each dictionary uses the webworks' internal-ids as keys. There are    -->
<!-- dictionaries for obtaining:                                           -->
<!-- 1. a 'ptx'|'server' flag (is it authored in PTX or on the server?)    -->
<!-- 2. a seed for randomization (with a default explicitly declared)      -->
<!-- 3. source (either the source XML or a problem's file path)            -->
<!-- 4. human readable PG (or the problem's file path)                     -->

<!-- The style sheet extract-pg-ptx.xsl separately builds:                 -->
<!-- 5. PG designed for use in PTX output modes (or problem's file path)   -->

<!-- The ptx script (-c webwork) uses all this to build a single XML file  -->
<!-- (called webwork-extraction.xml) containing multiple representations   -->
<!-- of each webwork problem. The ptx script must be re-run whenever       -->
<!-- something changes with author source within a webwork element. Or if  -->
<!-- something changes with a .pg file that lives on a server. Or if the   -->
<!-- configuration of the hosting server or server/course changes.         -->

<!-- Then pretext-merge.xsl merges author's source XML and the webwork     -->
<!-- representations into a single XML file (that you name at the point of -->
<!-- running xsltproc). The standard style sheets (HMTL, LaTeX) can then   -->
<!-- be applied to this merged file. Also, most mbx applications (such as  -->
<!-- for latex-images) apply to the mered file. So you must re-apply       -->
<!-- pretext-merge.xsl  each time something changes with source XML.       -->

<xsl:import href="./mathbook-common.xsl" />

<!-- We are really outputting Python code, but setting the output method   -->
<!-- to be "xml" makes it easy to dump in the author's source.             -->
<xsl:output method="xml" omit-xml-declaration="yes" indent="yes" encoding="UTF-8" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- Enable answer format syntax help links. Each answer blank can have a  -->
<!-- "category" attribute, like "integer" or "formula". If these are       -->
<!-- present and this param is 'yes', answer blank fields in HTML are      -->
<!-- followed with a link to syntax help.                                  -->
<!-- TODO: in order to omit all answer help links globally, the ptx script -->
<!-- needs a switch so that it can pass 'no' to this param.                -->
<xsl:param name="pg.answer.form.help" select="'yes'" />

<!-- This is cribbed from the CSS "max-width".  Design width, in pixels.   -->
<!-- NB: the exact same value, for similar, but not identical, reasons is  -->
<!-- used in the formation of WeBWorK problems                             -->
<xsl:variable name="design-width-pg" select="'600'" />

<!--#######################################################################-->
<!-- Dictionary Architecture                                               -->
<!--#######################################################################-->

<!-- Initialize empty dictionaries, then define key-value pairs -->
<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook|pretext" mode="generic-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings" />
    <xsl:text>origin = {}&#xa;</xsl:text>
    <xsl:text>seed = {}&#xa;</xsl:text>
    <xsl:text>source = {}&#xa;</xsl:text>
    <xsl:text>pg = {}&#xa;</xsl:text>
    <xsl:apply-templates select="//webwork[statement|stage|@source]" mode="dictionaries"/>
</xsl:template>

<xsl:template match="webwork[statement|stage]" mode="dictionaries">
    <!-- Define values for the internal-id as key -->
    <xsl:variable name="problem">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>

    <xsl:text>origin["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = "ptx"&#xa;</xsl:text>

    <xsl:text>seed["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = "</xsl:text>
    <xsl:apply-templates select="." mode="get-seed" />
    <xsl:text>"&#xa;</xsl:text>

    <xsl:text>source["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = """</xsl:text>
    <xsl:copy-of select="." />
    <xsl:text>"""&#xa;</xsl:text>

    <xsl:text>pg["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = """</xsl:text>
    <xsl:apply-templates select=".">
        <xsl:with-param name="b-verbose" select="true()" />
    </xsl:apply-templates>
    <xsl:text>"""&#xa;</xsl:text>
</xsl:template>

<xsl:template match="webwork[@source]" mode="dictionaries">
    <!-- Define values for the internal-id as key -->
    <xsl:variable name="problem">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>

    <xsl:text>origin["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = "server"&#xa;</xsl:text>

    <xsl:text>seed["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = "</xsl:text>
    <xsl:apply-templates select="." mode="get-seed" />
    <xsl:text>"&#xa;</xsl:text>

    <xsl:text>source["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = "</xsl:text>
    <xsl:value-of select="@source" />
    <xsl:text>"&#xa;</xsl:text>

    <xsl:text>pg["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = "</xsl:text>
    <xsl:value-of select="@source" />
    <xsl:text>"&#xa;</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- The visual text of a cross-reference is formed in the common routines -->
<!-- but we in the WW source we can't really form a link to a target       -->
<!-- outside the problem.                                                  -->

<!-- This routine won't work well in -common since the verbose             -->
<!-- parameter will need to tunnel through all the "xref"                  -->
<!-- templates to arrive at the link template.  One solution               -->
<!-- is to remove the (nice) device of showing the main title              -->
<!-- in the verbose forms of the problem                                   -->

<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" />
    <xsl:param name="xref" />
    <xsl:copy-of select="$content" />
    <xsl:if test="/mathbook/book|/mathbook/article">
        <xsl:text> in </xsl:text>
        <xsl:apply-templates select="/mathbook/book|/mathbook/article" mode="title-full" />
    </xsl:if>
</xsl:template>

<!-- Include parameterized, common, templates -->
<xsl:include href="extract-pg-common.xsl" />

</xsl:stylesheet>