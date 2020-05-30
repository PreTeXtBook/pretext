<?xml version='1.0'?>

<!--********************************************************************
Copyright 2020 Robert A. Beezer

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

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<!-- ######################### -->
<!-- Publisher Options Support -->
<!-- ######################### -->

<!-- Elements and attributes of a publisher file are meant to          -->
<!-- influence decisions taken *after* an author is completed writing. -->
<!-- In limited cases a command-line string parameter may be used to   -->
<!-- override the settings (especially for testing purposes).          -->
<!-- In other cases, deprecated string parameters may be consulted     -->
<!-- secondarily, for a limited time.                                  -->

<!-- A single command-line string parameter points to an XML file that      -->
<!-- is structured to carry various options that a *publisher* might set.   -->
<!-- Generally, these affect the *look* of the output, rather than the      -->
<!-- actual *content* that appears on the page, i.e. the actual characters. -->
<!-- We initialize with an empty node-set, then if not used, there is no    -->
<!-- loading of the entire source all over again (which seems to be the     -->
<!-- case with an empty string).  When set on the command-line, a string    -->
<!-- value will be interpreted correctly. -->
<xsl:param name="publisher" select="/.."/>

<!-- NB: the second argument is simply a node, it causes $publisher -->
<!-- to be interpreted relative to the location of the *current XML -->
<!-- file* rather than the location of the *stylesheet*. The actual -->
<!-- node does not seem so critical.                                -->
<xsl:variable name="publication" select="document($publisher, .)/publication"/>


<!-- ######################### -->
<!-- String Parameter Bad Bank -->
<!-- ######################### -->

<!-- Conversion specific parameters that die will   -->
<!-- live on in warnings, which are isolated in the -->
<!-- pretext-common stylesheet.  So we need to      -->
<!-- declare them here for use in the warnings      -->

<!-- DO NOT USE -->
<!-- HTML-specific deprecated 2015-06, but still functional -->
<xsl:param name="html.chunk.level" select="''" />
<!-- html.knowl.sidebyside is deprecated 2017-07  -->
<!-- null value necessary for deprecation message -->
<xsl:param name="html.knowl.sidebyside" select="''" />
<!-- Analytics deprecated 2019-11-28               -->
<!-- null values necessary for deprecation message -->
<xsl:param name="html.statcounter.project" select="''"/>
<xsl:param name="html.statcounter.security" select="''"/>
<xsl:param name="html.google-classic" select="''"/>
<xsl:param name="html.google-universal" select="''"/>
<!-- Google search via string parameter deprecated 2019-11-29 -->
<xsl:param name="html.google-search" select="''"/>
<!-- DO NOT USE -->

<!-- The dashed version is deprecated 2019-02-10,      -->
<!-- but we still recognize it.  Move to variable bad  -->
<!-- bank once killed.                                 -->
<xsl:param name="author-tools" select="''" />
<!-- The autoname parameter is deprecated (2017-07-25) -->
<!-- Replace with docinfo/cross-references/@text       -->
<xsl:param name="autoname" select="''" />

<!-- ################# -->
<!-- Variable Bad Bank -->
<!-- ################# -->

<!-- DO NOT USE THESE; THEY ARE TOTALLY DEPRECATED -->

<!-- Some string parameters have been deprecated without any      -->
<!-- sort of replacement, fallback, or upgrade.  But for a        -->
<!-- deprecation message to be effective, they need to exist.     -->
<!-- If you add something here, make a note by the deprecation    -->
<!-- message.  These definitions expain why it is *always* best   -->
<!-- to define a user variable as empty, and then supply defaults -->
<!-- to an internal variable.                                     -->

<xsl:variable name="html.css.file" select="''"/>
<xsl:variable name="html.permalink" select="''"/>

<!-- The old (incomplete) methods for duplicating components of -->
<!-- exercises have been deprecated as of 2018-11-07.  We keep  -->
<!-- these here as we have tried to preserve their intent, and  -->
<!-- we are generating warnings if they are ever set.           -->
<xsl:param name="exercise.text.statement" select="''" />
<xsl:param name="exercise.text.hint" select="''" />
<xsl:param name="exercise.text.answer" select="''" />
<xsl:param name="exercise.text.solution" select="''" />
<xsl:param name="exercise.backmatter.statement" select="''" />
<xsl:param name="exercise.backmatter.hint" select="''" />
<xsl:param name="exercise.backmatter.answer" select="''" />
<xsl:param name="exercise.backmatter.solution" select="''" />
<xsl:param name="project.text.hint" select="''" />
<xsl:param name="project.text.answer" select="''" />
<xsl:param name="project.text.solution" select="''" />
<xsl:param name="task.text.hint" select="''" />
<xsl:param name="task.text.answer" select="''" />
<xsl:param name="task.text.solution" select="''" />

<!-- These are deprecated in favor of watermark.text and watermark.scale -->
<!-- which are now managed in common. These still "work" for now.        -->
<!-- The default scaling factor of 2.0 is historical.                    -->
<xsl:param name="latex.watermark" select="''"/>
<xsl:variable name="b-latex-watermark" select="not($latex.watermark = '')" />
<xsl:param name="latex.watermark.scale" select="''"/>
<xsl:variable name="latex-watermark-scale">
    <xsl:choose>
        <xsl:when test="not($latex.watermark.scale = '')">
            <xsl:value-of select="$latex.watermark.scale"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>2.0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- DO NOT USE THESE; THEY ARE TOTALLY DEPRECATED -->

<!-- DEPRECATED: 2017-12-18, do not use, any value -->
<!-- besides an empty string will raise a warning  -->
<xsl:param name="latex.console.macro-char" select="''" />
<xsl:param name="latex.console.begin-char" select="''" />
<xsl:param name="latex.console.end-char" select="''" />


</xsl:stylesheet>