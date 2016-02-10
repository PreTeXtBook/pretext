<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2015                                                        -->
<!-- Robert A. Beezer, Michael Gage, Geoff Goehle, Alex Jordan             -->
<!--                                                                       -->
<!-- This file is part of MathBook XML.                                    -->
<!--                                                                       -->
<!-- MathBook XML is free software: you can redistribute it and/or modify  -->
<!-- it under the terms of the GNU General Public License as published by  -->
<!-- the Free Software Foundation, either version 2 or version 3 of the    -->
<!-- License (at your option).                                             -->
<!--                                                                       -->
<!-- MathBook XML is distributed in the hope that it will be useful,       -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of        -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         -->
<!-- GNU General Public License for more details.                          -->
<!--                                                                       -->
<!-- You should have received a copy of the GNU General Public License     -->
<!-- along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>. -->
<!-- ********************************************************************* -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- path assumes we place  webwork-latex.xsl  in mathbook "user" directory -->
<xsl:import href="../xsl/mathbook-latex.xsl" />

<!-- Intend output to be a LaTeX source -->
<xsl:output method="text" />

<!-- We have to identify snippets of LaTeX from the server,   -->
<!-- which we have stored in a directory, because XSLT 1.0    -->
<!-- is unable/unwilling to figure out where the source file  -->
<!-- lives (paths are relative to the stylesheet).  When this -->
<!-- is needed a fatal message will warn if it is not set.    -->
<!-- Path ends with a slash, anticipating appended filename   -->
<!-- This could be overridden in a compatibility layer        -->
<xsl:param name="webwork.server.latex" select="''" />


<!-- ################## -->
<!-- ################## -->




<!-- ############### -->
<!-- Server Problems -->
<!-- ############### -->

<!-- @source in an empty "webwork" element indicates     -->
<!-- the problem lives on a server.  HTML output has     -->
<!-- no problem with that.  For LaTeX, the  mbx  script  -->
<!-- fetches a LaTeX rending and associated image files. -->
<!-- Here, we just provide a light wrapper, and drop an  -->
<!-- include, since the base forthe filename has been    -->
<!-- managed to be predictable.                          -->

<xsl:template match="webwork[@source]|webwork[descendant::image[@pg-name]]">
    <!-- directory of server LaTeX must be specified -->
    <xsl:if test="$webwork.server.latex = ''">
        <xsl:message terminate="yes">MBX:ERROR   For LaTeX versions of WeBWorK problems on a server, the mbx script will collect the LaTeX source and then this conversion must specify the location through the "webwork.server.latex" command line stringparam.  Quitting...</xsl:message>
    </xsl:if>
    <xsl:variable name="xml-filename">
        <!-- assumes path has trailing slash -->
        <xsl:value-of select="$webwork.server.latex" />
        <xsl:apply-templates select="." mode="internal-id" />
        <xsl:text>.xml</xsl:text>
    </xsl:variable>
    <xsl:variable name="server-tex" select="document($xml-filename)/webwork-tex" />
    <!-- An enclosing exercise may introduce/connect the server-version problem. -->
    <!-- Then formatting is OK.  Otherwise we need a faux sentence instead.      -->
    <xsl:text>\mbox{}\\ % hack to move box after heading&#xa;</xsl:text>
    <xsl:apply-templates select="introduction" /> <!-- before boxed problem -->
    <xsl:text>\begin{mdframed}&#xa;</xsl:text>
    <xsl:text>{</xsl:text> <!-- prophylactic wrapper -->
    <xsl:value-of select="$server-tex/preamble" />
    <!-- process in the order server produces them, may be several -->
    <xsl:apply-templates select="$server-tex/statement|$server-tex/solution|$server-tex/hint" />
    <xsl:text>}</xsl:text>
    <xsl:text>\par\vspace*{2ex}%&#xa;</xsl:text>
    <xsl:text>{\tiny\ttfamily\noindent&#xa;</xsl:text>
    <xsl:value-of select="@source" />
    <xsl:text>\\</xsl:text>
    <!-- seed will round-trip through mbx script, default -->
    <!-- is hard-coded there.  It comes back as an        -->
    <!-- attribute of the overall "webwork-tex" element   -->
    <xsl:text>Seed: </xsl:text>
    <xsl:value-of select="$server-tex/@seed" />
    <xsl:text>\hfill</xsl:text>
    <xsl:text>}</xsl:text>  <!-- end: \tiny\ttfamily -->
    <xsl:text>\end{mdframed}&#xa;</xsl:text>
    <xsl:apply-templates select="conclusion" /> <!-- after boxed problem -->
</xsl:template>

<!-- We respect switches by implementing templates     -->
<!-- for each part of the problem that use the switch. -->
<!-- This allows processing above in document order    -->
<xsl:template match="webwork-tex/statement">
    <xsl:if test="$exercise.text.statement = 'yes'">
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>
<xsl:template match="webwork-tex/solution">
    <xsl:if test="$exercise.text.solution = 'yes'">
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>
<xsl:template match="webwork-tex/hint">
    <xsl:if test="$exercise.text.hint = 'yes'">
        <xsl:apply-templates />
    </xsl:if>
</xsl:template>


<!-- Unimplemented, currently killed -->
<xsl:template match="webwork/title" />


<!-- ####################### -->
<!-- Static, Named Templates -->
<!-- ####################### -->


<!-- Since we use XSLT 1.0, this is how we create -->
<!-- "width" underscores for a PGML answer blank  -->
<xsl:template name="underscore">
    <xsl:param name="width" select="5" />
    <xsl:if test="not($width = 0)">
        <xsl:text>_</xsl:text>
        <xsl:call-template name="underscore">
            <xsl:with-param name="width" select="$width - 1" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

</xsl:stylesheet>
