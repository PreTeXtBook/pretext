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
<!-- dictionaries for obtaining PG designed for use in PTX output modes:   -->
<!-- 5. with hints and solutions (if present)                              -->
<!-- 6. with hints (if present) but no solutions                           -->
<!-- 7. without hints but with solutions (if present)                      -->
<!-- 8. withour hints or solutions                                         -->
<!-- For each of the above, if the problem is server-based, there are no   -->
<!-- dictionary values to define.                                          -->

<!-- The style sheet extract-pg.xsl separately builds dictionaries for:    -->
<!-- 1. a 'ptx'|'server' flag (is it authored in PTX or on the server?)    -->
<!-- 2. a seed for randomization (with a default explicitly declared)      -->
<!-- 3. source (either the source XML or a problem's file path)            -->
<!-- 4. human readable PG (or the problem's file path)                     -->

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

<!-- We are outputting Python code, and there is no reason to output       -->
<!-- anything other than "text"                                            -->
<xsl:output method="text" encoding="UTF-8" />

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

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook|pretext" mode="generic-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings" />
    <!-- Initialize empty dictionaries, then define key-value pairs -->
    <xsl:text>pgptx = {}&#xa;</xsl:text>
    <xsl:text>pgptx['hint_no_solution_no'] = {}&#xa;</xsl:text>
    <xsl:text>pgptx['hint_no_solution_yes'] = {}&#xa;</xsl:text>
    <xsl:text>pgptx['hint_yes_solution_no'] = {}&#xa;</xsl:text>
    <xsl:text>pgptx['hint_yes_solution_yes'] = {}&#xa;</xsl:text>
    <xsl:apply-templates select="//webwork[statement|stage]" mode="dictionaries"/>
</xsl:template>

<xsl:template match="webwork[statement|stage]" mode="dictionaries">
    <!-- Define values for the internal-id as key -->
    <xsl:variable name="problem">
        <xsl:apply-templates select="." mode="internal-id" />
    </xsl:variable>

    <xsl:text>pgptx['hint_no_solution_no']["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = """</xsl:text>
    <xsl:apply-templates select=".">
        <xsl:with-param name="b-hint" select="false()" />
        <xsl:with-param name="b-solution" select="false()" />
        <xsl:with-param name="b-verbose" select="false()" />
    </xsl:apply-templates>
    <xsl:text>"""&#xa;</xsl:text>

    <xsl:text>pgptx['hint_no_solution_yes']["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = """</xsl:text>
    <xsl:apply-templates select=".">
        <xsl:with-param name="b-hint" select="false()" />
        <xsl:with-param name="b-solution" select="true()" />
        <xsl:with-param name="b-verbose" select="false()" />
    </xsl:apply-templates>
    <xsl:text>"""&#xa;</xsl:text>

    <xsl:text>pgptx['hint_yes_solution_no']["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = """</xsl:text>
    <xsl:apply-templates select=".">
        <xsl:with-param name="b-hint" select="true()" />
        <xsl:with-param name="b-solution" select="false()" />
        <xsl:with-param name="b-verbose" select="false()" />
    </xsl:apply-templates>
    <xsl:text>"""&#xa;</xsl:text>

    <xsl:text>pgptx['hint_yes_solution_yes']["</xsl:text>
    <xsl:value-of select="$problem" />
    <xsl:text>"] = """</xsl:text>
    <xsl:apply-templates select=".">
        <xsl:with-param name="b-hint" select="true()" />
        <xsl:with-param name="b-solution" select="true()" />
        <xsl:with-param name="b-verbose" select="false()" />
    </xsl:apply-templates>
    <xsl:text>"""&#xa;</xsl:text>
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

<!-- TODO: since this style sheet only affects WeBWorK problems in actual  -->
<!-- PTX output (as opposed to within WeBWorK) we could do something       -->
<!-- better with links in interactive and print output, and knowls in      -->
<!-- static HTML.                                                          -->

<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" />
    <xsl:param name="xref" />
    <xsl:param name="b-verbose" />
    <xsl:copy-of select="$content" />
</xsl:template>

<!-- Include parameterized, common, templates -->
<xsl:include href="extract-pg-common.xsl" />

</xsl:stylesheet>