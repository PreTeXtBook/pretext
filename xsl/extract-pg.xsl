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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:str="http://exslt.org/strings"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    extension-element-prefixes="str"
    exclude-result-prefixes="pi"
>

<!-- This style sheet is intended to be used by pretext.py. It makes an    -->
<!-- ephemeral XML tree with data about each webwork exercise in the PTX   -->
<!-- project. This ephemeral tree also has some global publisher variable  -->
<!-- data for how PG should be processed. This tree will be used by        -->
<!-- pretext.py in conjuction with some form of renderer (webwork2, local  -->
<!-- PG, or the standalone renderer) to create an XML file called          -->
<!-- webwork-representations.xml with various representations of each      -->

<!-- The top of the ephemeral XML tree has some global attributes.         -->

<!-- Then for each exercise, we record:                                    -->
<!-- 1.  origin: there are two possible values                             -->
<!--        "generated" (it was authored in PTX)                           -->
<!--        "webwork2" (it is a pg file accessible from a webwork2 host    -->
<!--            course's templates folder indicated by @source on the      -->
<!--            webwork element)                                           -->
<!-- 1b. if it is copied, what is an id from which it was copied?          -->
<!-- 2.  a seed for randomization                                          -->
<!-- 3.  path: a file path to a .pg version of the problem                 -->
<!--         path-defined-by-document-structure                            -->
<!--         path-defined-by-@source                                       -->
<!-- 4.  pghuman: human readable PG (for generated exercises only)         -->
<!-- 5.  PG that is somewhat minimized (and less human-readable)           -->

<!-- The pretext/pretext script (-c webwork) uses all this to build a      -->
<!-- single XML file (called webwork-representations.xml) containing       -->
<!-- multiple representations of each webwork problem. The pretext/pretext -->
<!-- script must be re-run whenever something changes with author source   -->
<!-- within a webwork element. Or if something changes with a .pg file.    -->
<!-- Or if some configuration changes.                                     -->

<!-- Then other translation sheets' assembly phase will factor in          -->
<!-- webwork-representations.xml                                           -->

<!-- Standard conversion groundwork -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<!-- We need to alert the pretext-assembly.xsl stylesheet     -->
<!-- that it is being used in the very specific instance      -->
<!-- of extracting these objects for processing externally,   -->
<!-- with results collected in additional files, for          -->
<!-- consultation/collection in a more general use of this    -->
<!-- stylesheet for the purpose of actually building a useful -->
<!-- output format.  This variable declaration here overrides -->
<!-- the default setting of "false" in pretext-assembly.xsl.  -->
<!-- Look there for a more comprehensive discussion of the    -->
<!-- necessity of this scheme.                                -->
<xsl:variable name="b-extracting-pg" select="true()"/>

<!-- Output XML to be read in by Python -->
<xsl:output method="xml" encoding="UTF-8" />

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

<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk-level-entered != ''">
            <xsl:value-of select="$chunk-level-entered" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!--#######################################################################-->
<!-- Dictionary Architecture                                               -->
<!--#######################################################################-->

<!-- Initialize empty dictionaries, then define key-value pairs             -->
<xsl:template match="*" mode="extraction-wrapper">
    <ww-extraction>
        <xsl:attribute name="numbered-title-filesafe">
            <xsl:apply-templates select="$document-root" mode="numbered-title-filesafe"/>
        </xsl:attribute>
        <xsl:attribute name="localization">
            <xsl:value-of select="$document-language"/>
        </xsl:attribute>
        <!-- Record certain publisher variables for ease of access by pretext.py -->
        <server-params-pub>
            <xsl:attribute name="webwork2-server">
                <xsl:value-of select="$webwork-server"/>
            </xsl:attribute>
            <xsl:attribute name="course-id">
                <xsl:value-of select="$webwork-course"/>
            </xsl:attribute>
            <xsl:attribute name="user-id">
                <xsl:value-of select="$webwork-user"/>
            </xsl:attribute>
            <xsl:attribute name="password">
                <xsl:value-of select="$webwork-password"/>
            </xsl:attribute>
        </server-params-pub>
        <!-- Settings for how PG is processed -->
        <processing>
            <xsl:attribute name="static">
                <xsl:value-of select="$webwork-static-processing"/>
            </xsl:attribute>
            <xsl:attribute name="pg-location">
                <xsl:value-of select="$webwork-pg-location"/>
            </xsl:attribute>
        </processing>
        <!-- Will need to know the folder names for generated and external. -->
        <!-- These are almost certainly "generated" and "external", but     -->
        <!-- rather than hardcode them where we need them, we get them from -->
        <!-- variables defined in publisher-variables.xsl                   -->
        <directories>
            <xsl:attribute name="generated-directory">
                <xsl:value-of select="$generated-directory"/>
            </xsl:attribute>
            <xsl:attribute name="external-directory">
                <xsl:value-of select="$external-directory"/>
            </xsl:attribute>
        </directories>
        <xsl:apply-imports/>
    </ww-extraction>
</xsl:template>

<xsl:template match="webwork[@source|statement|task|text()]" mode="extraction">
    <xsl:variable name="problem">
        <xsl:value-of select="@ww-id"/>
    </xsl:variable>
    <problem>
        <xsl:attribute name="id">
            <xsl:value-of select="$problem" />
        </xsl:attribute>
        <!-- 1. a generated|webwork2 flag                                          -->
        <xsl:attribute name="origin">
            <xsl:choose>
                <xsl:when test="statement|task|text()">
                    <xsl:text>generated</xsl:text>
                </xsl:when>
                <xsl:when test="@source">
                    <xsl:text>webwork2</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:attribute>
        <!-- 1b. if this problem is a copy, record what it was copied from         -->
        <xsl:if test="@copied-from">
            <xsl:attribute name="copied-from">
                <xsl:value-of select="@copied-from"/>
            </xsl:attribute>
        </xsl:if>
        <!-- 2. a seed for randomization (with a default explicitly declared)      -->
        <xsl:attribute name="seed">
            <xsl:apply-templates select="." mode="get-seed"/>
        </xsl:attribute>
        <!-- 3. file path                                                          -->
        <xsl:attribute name="path">
            <xsl:apply-templates select="." mode="filename"/>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="statement|task">
                <!-- 4. human readable PG (for PTX-authored)                           -->
                <pghuman>
                    <xsl:variable name="pg">
                        <xsl:apply-templates select=".">
                            <xsl:with-param name="b-human-readable" select="true()"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:call-template name="consolidate-empty-lines">
                        <xsl:with-param name="text" select="$pg"/>
                    </xsl:call-template>
                </pghuman>
                <!-- 5. PG optimized (and less human-readable) for use in PTX output modes -->
                <pgdense>
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="b-human-readable" select="false()"/>
                    </xsl:apply-templates>
                </pgdense>
            </xsl:when>
            <xsl:when test="text()">
                <pghuman>
                    <xsl:value-of select="text()"/>
                </pghuman>
                <pgdense>
                    <xsl:value-of select="text()"/>
                </pgdense>
            </xsl:when>
        </xsl:choose>
    </problem>
</xsl:template>

<!-- Append a filename to the directory path              -->
<xsl:template match="webwork[@source|statement|task|text()]" mode="filename">
    <xsl:choose>
        <xsl:when test="@source">
            <xsl:value-of select="@source"/>
        </xsl:when>
        <xsl:when test="statement|task|text()">
            <xsl:apply-templates select="." mode="directory-path" />
            <xsl:if test="parent::*[&PROJECT-FILTER;]">
                <xsl:apply-templates select="parent::*" mode="type-name"/>
                <xsl:text>-</xsl:text>
            </xsl:if>
            <xsl:apply-templates select="parent::*" mode="numbered-title-filesafe" />
            <xsl:text>.pg</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Directory path, recursively climb structural nodes,  -->
<!-- record names as pass up through chunk-level barrier  -->
<!-- Includes root document node (book, article, etc)     -->
<xsl:template match="*" mode="directory-path">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural"/>
    </xsl:variable>
    <xsl:variable name="current-level">
        <xsl:choose>
            <xsl:when test="$structural = 'true'">
                <xsl:apply-templates select="." mode="level" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>undefined</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="self::mathbook|self::pretext" /> <!-- done -->
        <xsl:when test="$structural='false'">  <!-- skip up -->
            <xsl:apply-templates select="parent::*" mode="directory-path" />
        </xsl:when>
        <!-- structural is true now, compare levels -->
        <xsl:when test="$current-level > $chunk-level">  <!-- also skip up -->
            <xsl:apply-templates select="parent::*" mode="directory-path" />
        </xsl:when>
        <xsl:otherwise> <!-- append current node name -->
            <xsl:apply-templates select="parent::*" mode="directory-path" />
            <xsl:apply-templates select="." mode="numbered-title-filesafe" />
            <xsl:text>/</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- The visual text of a cross-reference is formed in the common routines -->
<!-- but in the PG source we can't really form a link to a target outside  -->
<!-- the problem.                                                          -->

<!-- This routine won't work well in -common since the human-readable      -->
<!-- parameter would need to tunnel through all the "xref" templates to    -->
<!-- arrive at the link template.  One solution is to remove the (nice)    -->
<!-- device of showing the main title in the human forms of the problem    -->

<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" />
    <xsl:param name="xref" />
    <xsl:param name="b-human-readable" />
    <xsl:copy-of select="$content" />
    <xsl:if test="/mathbook/book|/mathbook/article">
        <xsl:text> in </xsl:text>
        <xsl:apply-templates select="/mathbook/book|/mathbook/article" mode="title-full" />
    </xsl:if>
</xsl:template>

<!-- Default randomization seed based on the webwork's number()  -->
<!-- This is better than a constant default seed, which can lead -->
<!-- to adjacent problems using the same random values           -->
<xsl:template match="webwork" mode="get-seed">
    <xsl:choose>
        <xsl:when test="@seed">
            <xsl:value-of select="@seed" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:number level="any" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Inline warnings go into text, no matter what -->
<xsl:template name="inline-warning">
    <xsl:param name="warning" />
    <xsl:text>(((</xsl:text>
    <xsl:value-of select="$warning" />
    <xsl:text>)))</xsl:text>
</xsl:template>

<!-- Marginal notes are only for author's report                     -->
<xsl:template name="margin-warning">
    <xsl:param name="warning" />
    <xsl:if test="$author-tools-new = 'yes'" >
        <xsl:value-of select="$warning" />
    </xsl:if>
</xsl:template>


<!-- The mechanics of a WeBWorK problem come first, with specific PreTeXt  -->
<!-- markup to support problem expression.                                 -->
<!--                                                                       -->
<!-- The latter half of the file is the conversion of more universal       -->
<!-- PreTeXt markup to its PGML variants.                                  -->

<!-- ################## -->
<!-- Top-Down Structure -->
<!-- ################## -->

<!-- A webwork element can either:                                         -->
<!-- 1. be empty; just for printing "WeBWorK"                              -->
<!-- 2. use an existing .pg problem from the server                        -->
<!-- 3. have only one text() child, a fully intact .pg problem             -->
<!-- 4. have a single statement child                                      -->
<!-- 5. have two or more task children (known in WW as "scaffolded")       -->
<!-- What follows is not concerned with the first three. The next two top  -->
<!-- level templates follow.                                               -->


<xsl:template match="webwork[statement]">
    <xsl:param name="b-human-readable" />
    <xsl:if test="$b-human-readable">
        <xsl:call-template name="converter-blurb-webwork" />
        <xsl:call-template name="webwork-metadata" />
    </xsl:if>
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pg-macros">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:if test="$b-human-readable">
        <xsl:text>COMMENT('</xsl:text>
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'authored'"/>
        </xsl:apply-templates>
        <xsl:text>');&#xa;</xsl:text>
        <xsl:apply-templates select="description"/>
    </xsl:if>
    <xsl:call-template name="pg-header">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:apply-templates select="." mode="pg-code">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:apply-templates select="statement">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:apply-templates select="hint">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:apply-templates select="solution">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:call-template name="end-problem">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
</xsl:template>

<xsl:template match="webwork[task]">
    <xsl:param name="b-human-readable" />
    <xsl:if test="$b-human-readable">
        <xsl:call-template name="converter-blurb-webwork" />
        <xsl:call-template name="webwork-metadata" />
    </xsl:if>
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pg-macros">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:if test="$b-human-readable">
        <xsl:text>COMMENT('</xsl:text>
        <xsl:apply-templates select="." mode="type-name">
            <xsl:with-param name="string-id" select="'authored'"/>
        </xsl:apply-templates>
        <xsl:text>');&#xa;</xsl:text>
        <xsl:text>COMMENT('This problem is scaffolded with multiple parts');&#xa;</xsl:text>
        <xsl:apply-templates select="description"/>
    </xsl:if>
    <xsl:call-template name="pg-header">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:apply-templates select="." mode="pg-code">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Body</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:if test="ancestor::exercisegroup/introduction|introduction">
        <xsl:text>&#xa;BEGIN_PGML&#xa;</xsl:text>
        <xsl:if test="$b-human-readable">
            <xsl:apply-templates select="ancestor::exercisegroup/introduction">
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:apply-templates>
        </xsl:if>
        <xsl:apply-templates select="introduction">
            <xsl:with-param name="b-human-readable" select="$b-human-readable" />
        </xsl:apply-templates>
        <xsl:text>&#xa;END_PGML&#xa;</xsl:text>
    </xsl:if>
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Scaffold</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:text>Scaffold::Begin(</xsl:text>
    <xsl:text>numbered =&gt; 1,</xsl:text>
    <xsl:text>is_open =&gt; "correct_or_first_incorrect",</xsl:text>
    <xsl:text>can_open =&gt; </xsl:text>
    <xsl:choose>
        <xsl:when test="$webwork-task-reveal = 'all'">
            <xsl:text>always,</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>when_previous_correct,</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>);</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="task">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>Scaffold::End();</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="conclusion">
        <xsl:text>&#xa;BEGIN_PGML&#xa;</xsl:text>
        <xsl:apply-templates select="conclusion">
            <xsl:with-param name="b-human-readable" select="$b-human-readable" />
        </xsl:apply-templates>
        <xsl:text>&#xa;END_PGML&#xa;</xsl:text>
    </xsl:if>
    <xsl:call-template name="end-problem">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
</xsl:template>

<xsl:template match="task[statement]">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Section</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:text>Section::Begin("</xsl:text>
    <xsl:if test="title">
        <xsl:apply-templates select="." mode="title-xref"/>
    </xsl:if>
    <xsl:text>");</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="statement">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:apply-templates select="hint">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:apply-templates select="solution">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>Section::End();</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="task[task]">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Section</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:text>Section::Begin("</xsl:text>
    <xsl:if test="title">
        <xsl:apply-templates select="." mode="title-xref"/>
    </xsl:if>
    <xsl:text>");</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="introduction">
        <xsl:text>&#xa;BEGIN_PGML&#xa;</xsl:text>
        <xsl:apply-templates select="introduction">
            <xsl:with-param name="b-human-readable" select="$b-human-readable" />
        </xsl:apply-templates>
        <xsl:text>&#xa;END_PGML&#xa;</xsl:text>
    </xsl:if>
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Scaffold</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:text>Scaffold::Begin(numbered=&gt;1);</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="task">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>Scaffold::End();</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="conclusion">
        <xsl:text>&#xa;BEGIN_PGML&#xa;</xsl:text>
        <xsl:apply-templates select="conclusion">
            <xsl:with-param name="b-human-readable" select="$b-human-readable" />
        </xsl:apply-templates>
        <xsl:text>&#xa;END_PGML&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>Section::End();</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="webwork" mode="pg-code">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">PG Setup Code</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <!-- All our problems load MathObjects, and so should have at least    -->
    <!-- one explicit Context() load.                                      -->
    <xsl:if test="not(contains(.//pg-code,'Context('))">
        <xsl:text>Context('Numeric');</xsl:text>
        <xsl:if test="$b-human-readable">
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- pg-code verbatim, but trim indentation -->
    <xsl:if test=".//pg-code">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select=".//pg-code" />
        </xsl:call-template>
    </xsl:if>
    <!-- if there are latex-image in the problem, put their code here -->
    <!-- introduction images are not needed except for human readable code -->
    <xsl:if test="$b-human-readable">
        <xsl:apply-templates select="ancestor::exercisegroup/introduction//image[latex-image]" mode="latex-image-code"/>
    </xsl:if>
    <xsl:apply-templates select=".//image[latex-image]" mode="latex-image-code"/>
</xsl:template>

<!-- default template, for complete presentation -->
<xsl:template match="statement">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Body</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:text>&#xa;BEGIN_PGML&#xa;</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:apply-templates select="ancestor::exercisegroup/introduction">
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
    </xsl:if>
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:text>&#xa;END_PGML&#xa;</xsl:text>
</xsl:template>

<xsl:template match="task/statement">
    <xsl:param name="b-human-readable" />
    <xsl:text>&#xa;BEGIN_PGML&#xa;</xsl:text>
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:text>&#xa;END_PGML&#xa;</xsl:text>
</xsl:template>

<!-- default template, for solution -->
<xsl:template match="solution">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Solution</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:text>&#xa;BEGIN_PGML_SOLUTION&#xa;</xsl:text>
    <xsl:apply-templates select="*">
        <xsl:with-param  name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:text>&#xa;END_PGML_SOLUTION&#xa;</xsl:text>
</xsl:template>

<!-- default template, for hint -->
<xsl:template match="hint">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Hint</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:if test="$b-human-readable">
        <xsl:text>#Set value of $showHint in PGcourse.pl for course-wide attempt threshhold for revealing hints&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;BEGIN_PGML_HINT&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>&#xa;END_PGML_HINT&#xa;</xsl:text>
</xsl:template>

<xsl:template match="introduction|conclusion">
    <xsl:param name="b-human-readable" />
    <xsl:apply-templates select="*">
        <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
    </xsl:apply-templates>
    <xsl:if test="parent::exercisegroup">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="webwork/description">
    <xsl:text>COMMENT(</xsl:text>
    <xsl:choose>
        <xsl:when test="line">
            <xsl:for-each select="line">
                <xsl:apply-templates select="." mode="delimit"/>
                <xsl:if test="following-sibling::line">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="delimit"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*" mode="delimit">
    <xsl:variable name="delimiter">
        <xsl:call-template name="find-unused-character">
            <xsl:with-param name="string" select="."/>
            <!-- https://stackoverflow.com/questions/43617820/what-are-the-legal-delimiters-for-perl-5s-pick-your-own-quotes-operators    -->
            <!-- NB: don't use (), <>, [], {}, because as perl delimiters, closer must be the right version; too complicated to check for -->
            <!-- Don't use backslash. All other keyboard characters are present below                                                     -->
            <xsl:with-param name="charset" select="concat($apos, '&quot;:;,./?|`~!@#$%^&amp;*-_=+', &SIMPLECHAR;)"/>
        </xsl:call-template>
    </xsl:variable>
    <!-- If the delimiter is not a single quote, use q operator -->
    <xsl:if test="$delimiter != $apos">
        <xsl:text>q</xsl:text>
    </xsl:if>
    <!-- If the delimiter is alphanumeric (or underscore), it must be preceded by a space -->
    <xsl:if test="contains(concat('_',&SIMPLECHAR;), $delimiter)">
        <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:value-of select="$delimiter"/>
    <xsl:apply-templates/>
    <xsl:value-of select="$delimiter"/>
</xsl:template>


<!-- ############################## -->
<!-- Problem Header/Initializations -->
<!-- ############################## -->

<!-- Mine various parts of the surrounding text -->
<!-- Only ever called in human-readable mode    -->
<xsl:template name="webwork-metadata">
    <xsl:text>## DBsubject(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## DBchapter(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## DBsection(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## Level(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## KEYWORDS(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## TitleText1(</xsl:text>
    <xsl:if test="/mathbook/book|/mathbook/article">
        <xsl:apply-templates select="/mathbook/book|/mathbook/article" mode="title-full" />
    </xsl:if>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## EditionText1(</xsl:text>
    <xsl:if test="/mathbook/book/frontmatter/colophon/edition">
        <xsl:apply-templates select="/mathbook/book/frontmatter/colophon/edition" />
    </xsl:if>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## AuthorText1(</xsl:text>
    <xsl:if test="/mathbook/book|/mathbook/article">
        <xsl:for-each select="/mathbook/book/frontmatter/titlepage/author|/mathbook/article/frontmatter/titlepage/author">
            <xsl:value-of select="personname"/>
            <xsl:if test="following-sibling::author">
                <xsl:text>, </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:if>
    <xsl:text>)&#xa;</xsl:text>
    <!-- needs structural enclosure inline v. divisional         -->
    <!-- do not use structure number, makes overrides impossible -->
    <xsl:text>## Section1(not reported</xsl:text>
        <!-- <xsl:apply-templates select="ancestor::exercise" mode="structure-number" /> -->
    <xsl:text>)&#xa;</xsl:text>
    <!-- WW problem is always enclosed directly by a PTX exercise or PROJECT-LIKE -->
    <xsl:if test="parent::exercise">
        <xsl:text>## Problem1(</xsl:text>
            <xsl:apply-templates select="parent::exercise" mode="number" />
        <xsl:text>)&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>## Author(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## Institution(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## Language(</xsl:text>
        <xsl:value-of select="$document-language"/>
    <xsl:text>)&#xa;&#xa;</xsl:text>
</xsl:template>


<xsl:template name="pg-header">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Header</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:text>TEXT(beginproblem());&#xa;</xsl:text>
    <xsl:if test="not($b-human-readable)">
        <!-- see select-latex-macros template -->
        <xsl:variable name="macros">
            <xsl:call-template name="select-latex-macros"/>
        </xsl:variable>
        <xsl:if test="$macros != ''">
            <xsl:variable name="wrapped-macros">
                <xsl:text>&lt;div style="display:none;">\(</xsl:text>
                <xsl:value-of select="$macros" />
                <xsl:text>\)&lt;/div></xsl:text>
            </xsl:variable>
            <xsl:variable name="delimiter">
                <xsl:call-template name="find-unused-character">
                    <xsl:with-param name="string" select="$wrapped-macros"/>
                    <!-- https://stackoverflow.com/questions/43617820/what-are-the-legal-delimiters-for-perl-5s-pick-your-own-quotes-operators    -->
                    <!-- NB: don't use (), <>, [], {}, because as perl delimiters, closer must be the right version; too complicated to check for -->
                    <xsl:with-param name="charset" select="concat($apos,'|/?.,+-_~`!@$%^&amp;*')"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:text>TEXT(MODES(PTX=&gt;'',HTML=&gt;</xsl:text>
            <xsl:if test="$delimiter != $apos">
                <xsl:text>q</xsl:text>
            </xsl:if>
            <xsl:value-of select="$delimiter"/>
            <xsl:value-of select="$wrapped-macros"/>
            <xsl:value-of select="$delimiter"/>
            <xsl:text>));&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- ############## -->
<!-- Problem Ending -->
<!-- ############## -->

<xsl:template name="end-problem">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">End Problem</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>
    <xsl:text>&#xa;ENDDOCUMENT();</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ############## -->
<!-- Load PG Macros -->
<!-- ############## -->

<!-- call exactly once,        -->
<!-- context is "webwork" root -->
<xsl:template match="webwork" mode="pg-macros">
    <xsl:param name="b-human-readable" />

    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Load Macros</xsl:with-param>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:call-template>

    <!-- three standard macros always, order and placement is critical -->
    <xsl:variable name="standard-macros">
        <xsl:call-template name="macro-padding">
            <xsl:with-param name="string" select="'PGstandard.pl'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:call-template>
        <xsl:call-template name="macro-padding">
            <xsl:with-param name="string" select="'PGML.pl'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:call-template>
    </xsl:variable>

    <!-- accumulate macros evidenced by some aspect of problem design      -->
    <!-- for details on what each macro file provides, see their source at -->
    <!-- https://github.com/openwebwork/pg/tree/master/macros              -->
    <!-- or                                                                -->
    <!-- https://github.com/openwebwork/webwork-open-problem-library/tree/master/OpenProblemLibrary/macros -->
    <xsl:variable name="implied-macros">
        <!-- tables -->
        <xsl:if test=".//tabular">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'niceTables.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- bizarro arithmetic technique for assesing answer form -->
        <xsl:if test="contains(.//pg-code,'bizarro')">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'bizarroArithmetic.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- multistage problems ("scaffolded") -->
        <xsl:if test="task">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'scaffold.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- links to syntax help following answer blanks -->
        <xsl:if test="$pg.answer.form.help = 'yes'">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'AnswerFormatHelp.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- targeted feedback messages for specific wrong answers -->
        <xsl:if test="contains(.//pg-code,'AnswerHints')">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'answerHints.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- the very useful NchooseK function-->
        <xsl:if test="contains(.//pg-code,'NchooseK')">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'PGchoicemacros.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- essay answers -->
        <xsl:if test=".//var[@form='essay'] or contains(.//pg-code,'explanation_box')">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'PGessaymacros.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- when there is a PGgraphmacros graph -->
        <xsl:if test=".//image[@pg-name]">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'PGgraphmacros.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- when there is a latex-image graph -->
        <xsl:if test=".//latex-image or ($b-human-readable and ancestor::exercisegroup/introduction//latex-image)">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'PGlateximage.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- instructions for entering answers into HTML forms -->
        <!-- utility for randomly generating variable letters -->
        <xsl:if test=".//instruction or contains(.//pg-code,'RandomVariableName') or contains(.//pg-code,'RandomName') or contains(.//pg-code,'numberWord')">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'PCCmacros.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- ################### -->
        <!-- Parser Enhancements -->
        <!-- ################### -->
        <!-- https://github.com/openwebwork/pg/tree/master/macros -->
        <!-- "assignment" answers, like "y=x+1", "f(x)=x+1" -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'Assignment'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- force String() to accept any string (and add it to the context if not already there) -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'AutoStrings'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- special type of Formula for simplified difference quotients -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'DifferenceQuotient'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- special type of Formula with only one variable and student can use any variable -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'FormulaAnyVar'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- special type of Formula with a "+C" at the end -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'FormulaUpToConstant'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- formulas with units -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'FormulaWithUnits'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- allow "f(x)" as part of answers -->
        <!-- note unusual usage precludes using parser modal template here -->
        <xsl:if test="contains(.//pg-code,'parserFunction')">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'parserFunction.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- allow "f'(x)" as part of answers -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'FunctionPrime'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- implicit equations, e.g. x^2+sin(x+y)=5 -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'ImplicitEquation'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- implicit planes, e.g. x+2y=3z+1 -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'ImplicitPlane'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- linear inequalities, e.g. 4x1 -3x2 <= 5 -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'LinearInequality'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- for questions where multiple answer blanks work in conjunction  -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'MultiAnswer'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- numbers with units -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'NumberWithUnits'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- for questions where any one of a finite list of answers is allowable  -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'OneOf'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- parametric lines, specified in a variety of ways  -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'ParametricLine'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- parametric planes, specified in a variety of ways  -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'ParametricPlane'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- popup menu multiple choice answers -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'PopUp'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- checkboxes multiple choice answers -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'CheckboxList'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- allow "'" as part of answers, as an effective derivative operator -->
        <!-- note unusual usage precludes using parser modal template here -->
        <xsl:if test="contains(.//pg-code,'parser::Prime')">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'parserPrime.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- parserQuotedString.pl is part of pg distribution, but not documented what it does -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'QuotedString'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- radio buttons multiple choice answers -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'RadioButtons'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- allow a root(n,x) function -->
        <!-- note unusual usage precludes using parser modal template here -->
        <xsl:if test="contains(.//pg-code,'parser::Root')">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'parserRoot.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- check if a number/point satisfies an implicit equation -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'SolutionFor'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Some utility routines that are useful in vector problems -->
        <!-- note unusual usage precludes using parser modal template here -->
        <xsl:if test="contains(.//pg-code,'Overline') or contains(.//pg-code,'BoldMath' or contains(.//pg-code,'non_zero_point') or contains(.//pg-code,'non_zero_vector'))">
            <xsl:call-template name="macro-padding">
                <xsl:with-param name="string" select="'parserVectorUtils.pl'"/>
                <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            </xsl:call-template>
        </xsl:if>
        <!-- Provides free response, fill in the blank questions with interactive help -->
        <xsl:apply-templates select="." mode="parser">
            <xsl:with-param name="parser" select="'WordCompletion'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- #################### -->
        <!-- Math Object contexts -->
        <!-- #################### -->
        <!-- https://github.com/openwebwork/pg/tree/master/macros -->
        <!-- string-valued answers especially for matching problems -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'ABCD'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Provides a context that allows the entry of decimal numbers using a comma -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'AlternateDecimal'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Allows the entry of intervals using reversed bracket notation for open endpoints -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'AlternateIntervals'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Allow arbitrary string answers where you code the checker -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'ArbitraryString'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- ComplexExtras context loads tools with no good way to auto detect. Must be added by user. -->
        <!-- https://github.com/openwebwork/pg/blob/master/macros/contextComplexExtras.pl -->
        <!-- ComplexJ context lets j^2 = -1 with no good way to auto detect. Must be added by user. -->
        <!-- https://github.com/openwebwork/pg/blob/master/macros/contextComplexJ.pl -->
        <!-- Provides contexts that allow the entry of congruence solutions -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Congruence'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Answers with currency symbols -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Currency'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Form -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Form'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Fractions -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Fraction'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Inequalities -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Inequalities'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Inequalitis in SEt-Builder notation -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'InequalitySetBuilder'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Integer objects, with integer functions -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Integers'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Integer functions -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'IntegerFunctions'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Require a leading zero on decimal numbers -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'LeadingZero'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Allow complex numbers but not complex operations -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'LimitedComplex'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Check that the students answer agrees in form with a factored polynomial -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'LimitedFactor'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Allow point entry but no point operations -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'LimitedPoint'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Allow only entry of polynomials -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'LimitedPolynomial'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Restrict the base or power allowed in exponentials -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'LimitedPowers'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Allows for specification of forms of radical answers -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'LimitedRadical'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Allow vector entry but no vector operations -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'LimitedVector'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- MatrixExtras adds features to Matrix context  with no good way to auto detect. Must be added by user. -->
        <!-- https://github.com/openwebwork/pg/blob/master/macros/contextMatrixExtras.pl -->
        <!-- Orderings, like A > B > C -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Ordering'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Partition of an integer as a sum -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Partition'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Percent answers -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Percent'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Allow the entry of cycles and permutations -->
        <!-- User must choose between Permutation and PermutationUBC -->
        <!-- https://github.com/openwebwork/pg/blob/master/macros/contextPermutation.pl -->
        <!-- https://github.com/openwebwork/pg/blob/master/macros/contextPermutationUBC.pl -->
        <!-- Piecewise functions -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'PiecewiseFunction'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Allow only entry of polynomials, and their products and powers -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'PolynomialFactors'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Only allow rational functions (and their products and powers) -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'RationalFunction'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Chemical reactions -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'Reaction'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Scientific notation -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'ScientificNotation'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- String-centric context. User must add -->
        <!-- https://github.com/openwebwork/pg/blob/master/macros/contextString.pl -->
        <!-- Context for True/False answers. User must add -->
        <!-- https://github.com/openwebwork/pg/blob/master/macros/contextTF.pl -->
        <!-- Make ttrig functions behave wrt degrees -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'TrigDegrees'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Below are context files from the OPL macros folder, not the pg distribution -->
        <!-- Answers like {1,2,3} that can be entered in many other ways, like "x=1,2,or 3" -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'FiniteSolutionSets'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
        <!-- Answers that are functions paired with domains, like x^2, x != 2 -->
        <xsl:apply-templates select="." mode="context">
            <xsl:with-param name="context" select="'RestrictedDomains'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:apply-templates>
    </xsl:variable>
    <!-- capture problem root to use inside upcoming for-each -->
    <xsl:variable name="problem-root" select="." />
    <!-- accumulate new macros supplied by problem author, warn if not new -->
    <xsl:variable name="user-macros">
        <xsl:for-each select=".//pg-macros/macro-file">
            <xsl:variable name="trimmed-macro">
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:variable>
            <!-- wrap in quotes to protect accidental matches -->
            <xsl:variable name="fenced-macro">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="$trimmed-macro" />
                <xsl:text>"</xsl:text>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="contains($standard-macros, $fenced-macro) or ($fenced-macro = '&quot;PGcourse.pl&quot;')">
                    <xsl:message>PTX:WARNING: the WeBWorK PG macro <xsl:value-of select="$trimmed-macro"/> is always included for every problem</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:when test="$trimmed-macro = 'PG.pl' or $trimmed-macro = 'PGbasicmacros.pl' or $trimmed-macro = 'PGanswermacros.pl' or $trimmed-macro = 'PGauxiliaryFunctions.pl' or $trimmed-macro = 'customizeLaTeX.pl'">
                    <xsl:message>PTX:WARNING: the WeBWorK PG macro <xsl:value-of select="$trimmed-macro"/> is always included for every problem as a dependency of PGstandard.pl</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:when test="$trimmed-macro = 'Parser.pl' or $trimmed-macro = 'MathObjects.pl' or $trimmed-macro = 'contextTypeset.pl'">
                    <xsl:message>PTX:WARNING: the WeBWorK PG macro <xsl:value-of select="$trimmed-macro"/> is always included for every problem as a dependency of PGML.pl</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:when test="contains($implied-macros, $fenced-macro)">
                    <xsl:message>PTX:WARNING: the WeBWorK PG macro <xsl:value-of select="$trimmed-macro"/> is implied by the problem construction and already included</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="macro-padding">
                        <xsl:with-param name="string" select="."/>
                        <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:variable>
    <!-- PTX-built macros file -->
    <xsl:variable name="ptx-pg-macros">
        <xsl:variable name="ptx-pg-macros-filename">
            <xsl:choose>
                <xsl:when test="$docinfo/initialism">
                    <xsl:value-of select="$docinfo/initialism"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$document-root" mode="title-filesafe"/>
                </xsl:otherwise>
            </xsl:choose>
            <text>.pl</text>
        </xsl:variable>
        <xsl:call-template name="macro-padding">
            <xsl:with-param name="string" select="$ptx-pg-macros-filename"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:call-template>
    </xsl:variable>
    <!-- always finish with PG course macro -->
    <xsl:variable name="course-macros">
        <xsl:call-template name="macro-padding">
            <xsl:with-param name="string" select="'PGcourse.pl'"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:call-template>
    </xsl:variable>
    <!-- put them together with a wrapper -->
    <xsl:variable name="load-macros">
        <xsl:text>loadMacros(</xsl:text>
        <xsl:if test="$b-human-readable">
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
        <xsl:value-of select="$standard-macros" />
        <xsl:value-of select="$implied-macros" />
        <xsl:value-of select="$user-macros" />
        <xsl:if test=".//latex-image or ancestor::exercisegroup/introduction//latex-image">
            <xsl:value-of select="$ptx-pg-macros" />
        </xsl:if>
        <xsl:value-of select="$course-macros" />
        <xsl:text>);</xsl:text>
        <xsl:if test="$b-human-readable">
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$load-macros" />
    <!-- if images are used, explicitly refresh or stale images will be used in HTML -->
    <xsl:if test="(.//image[@pg-name] or .//image[latex-image]) and not($b-human-readable)">
        <xsl:text>$refreshCachedImages=1;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="webwork" mode="context">
    <xsl:param name="context"/>
    <xsl:param name="b-human-readable"/>
    <xsl:if test="contains(.//pg-code,$context)">
        <xsl:call-template name="macro-padding">
            <xsl:with-param name="string" select="concat('context',$context,'.pl')"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template match="webwork" mode="parser">
    <xsl:param name="parser"/>
    <xsl:param name="b-human-readable"/>
    <xsl:if test="contains(.//pg-code,$parser)">
        <xsl:call-template name="macro-padding">
            <xsl:with-param name="string" select="concat('parser',$parser,'.pl')"/>
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template name="macro-padding">
    <xsl:param name="string"/>
    <xsl:param name="b-human-readable"/>
    <xsl:if test="$b-human-readable">
        <xsl:text>  </xsl:text>
    </xsl:if>
    <xsl:text>"</xsl:text>
    <xsl:value-of select="$string"/>
    <xsl:text>",</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ############## -->
<!-- PERL Variables -->
<!-- ############## -->

<!-- PGML markup for Perl variable in LaTeX expression -->
<xsl:template match="var">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>]</xsl:text>
    <!-- if the variable is a string of PGML syntax to be processed -->
    <xsl:if test="@data='pgml'">
        <xsl:text>**</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="latex-image/var" mode="latex-image">
    <xsl:value-of select="@name" />
</xsl:template>

<!-- ############ -->
<!-- PGML answers -->
<!-- ############ -->

<!-- PGML answer input               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="statement//var[@width|@form]">
    <xsl:param name="b-human-readable" />
    <xsl:apply-templates select="." mode="field">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="form-help"/>
</xsl:template>

<!-- MathObject answers -->
<!-- with variant for MathObjects like Matrix, Vector, ColumnVector      -->
<!-- where the shape of the MathObject guides the array of answer blanks -->
<xsl:template match="var[@width|@form]" mode="field">
    <xsl:param name="b-human-readable" />
    <xsl:variable name="width">
        <xsl:choose>
            <xsl:when test="@width">
                <xsl:value-of select="@width"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>5</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Answer inputs all on their own p get indented         -->
    <!-- This is a styling preference that can't be customized -->
    <xsl:choose>
        <!-- We don't indent for radio buttons or checkboxes input -->
        <!-- which ought to be in their own p in the first place   -->
        <xsl:when test="@form = 'buttons' or @form = 'checkboxes'"/>
        <!-- We don't indent for answer input that is within certain structures -->
        <xsl:when test="ancestor::li or ancestor::tabular"/>
        <!-- We don't indent when the input field is inline with a p -->
        <xsl:when test="count(parent::p/*) + string-length(normalize-space(parent::p/text())) = 0">
            <xsl:text>    </xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>[_]</xsl:text>
    <!-- multiplier for MathObjects like Matrix, Vector, ColumnVector -->
    <xsl:if test="@form='array'">
        <xsl:text>*</xsl:text>
    </xsl:if>
    <xsl:text>{</xsl:text>
    <xsl:choose>
        <xsl:when test="@evaluator">
            <xsl:value-of select="@evaluator" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="@name" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$width"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Essay answers -->
<!-- Example: [@ ANS(essay_cmp); essay_box(6,76) @]*   -->
<!-- Requires:  PGessaymacros.pl, automatically loaded -->
<!-- http://webwork.maa.org/moodle/mod/forum/discuss.php?d=3370 -->
<xsl:template match="var[@form='essay']" mode="field">
    <xsl:param name="b-human-readable" />
    <xsl:text>[@ANS(essay_cmp());</xsl:text>
    <!-- NECESSARY? -->
    <xsl:if test="$b-human-readable">
        <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:text>essay_box(</xsl:text>
    <xsl:choose>
        <xsl:when test="@height">
            <xsl:value-of select="@height"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>6</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>,</xsl:text>
    <xsl:choose>
        <xsl:when test="@width">
            <xsl:value-of select="@width"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>76</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>)@]*</xsl:text>
</xsl:template>

<xsl:template match="var[@width]|var[@form]" mode="form-help">
    <xsl:variable name="form">
        <xsl:choose>
            <xsl:when test="@form">
                <xsl:value-of select="@form"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="category-to-form">
                    <xsl:with-param name="category" select="@category"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="($pg.answer.form.help = 'yes')">
        <xsl:choose>
            <!-- first, formats we can't help with -->
            <xsl:when test="($form='none') or ($form='popup')  or ($form='buttons') or ($form='checkboxes') or ($form='array')"/>
            <xsl:when test="$form='essay'">
                <xsl:text> [@essay_help()@]*</xsl:text>
            </xsl:when>
            <!-- inside a table, do not encase in [@...@]* and do concatenate-->
            <xsl:when test="ancestor::tabular">
                <xsl:text>".AnswerFormatHelp('</xsl:text>
                <xsl:value-of select="$form"/>
                <xsl:text>')."</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> [@AnswerFormatHelp('</xsl:text>
                <xsl:value-of select="$form"/>
                <xsl:text>')@]*</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- Convert a var's "category" to the right term for AnswerFormatHelp -->
<!-- Keep ordered alphabetically, and one value per @test, so          -->
<!-- that it is easier to maintain a list in the schema                -->
<xsl:template name="category-to-form">
    <xsl:param name="category" select="none"/>
    <xsl:choose>
        <xsl:when test="$category='angle'">
            <xsl:text>angles</xsl:text>
        </xsl:when>
        <xsl:when test="$category='decimal'">
            <xsl:text>decimals</xsl:text>
        </xsl:when>
        <xsl:when test="$category='exponent'">
            <xsl:text>exponents</xsl:text>
        </xsl:when>
        <xsl:when test="$category='formula'">
            <xsl:text>formulas</xsl:text>
        </xsl:when>
        <xsl:when test="$category='fraction'">
            <xsl:text>fractions</xsl:text>
        </xsl:when>
        <xsl:when test="$category='inequality'">
            <xsl:text>inequalities</xsl:text>
        </xsl:when>
        <xsl:when test="$category='integer'">
            <xsl:text>numbers</xsl:text>
        </xsl:when>
        <xsl:when test="$category='interval'">
            <xsl:text>intervals</xsl:text>
        </xsl:when>
        <xsl:when test="$category='logarithm'">
            <xsl:text>logarithms</xsl:text>
        </xsl:when>
        <xsl:when test="$category='limit'">
            <xsl:text>limits</xsl:text>
        </xsl:when>
        <xsl:when test="$category='number'">
            <xsl:text>numbers</xsl:text>
        </xsl:when>
        <xsl:when test="$category='point'">
            <xsl:text>points</xsl:text>
        </xsl:when>
        <xsl:when test="$category='syntax'">
            <xsl:text>syntax</xsl:text>
        </xsl:when>
        <xsl:when test="$category='quantity'">
            <xsl:text>units</xsl:text>
        </xsl:when>
        <xsl:when test="$category='vector'">
            <xsl:text>vectors</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>none</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ####################### -->
<!-- PGML Image Construction -->
<!-- ####################### -->

<xsl:template match="image[@pg-name|latex-image]" mode="components">
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:text>[@image(insertGraph(</xsl:text>
    <xsl:apply-templates select="." mode="pg-name"/>
    <xsl:text>), width=&gt;</xsl:text>
    <xsl:value-of select="substring-before($width, '%') div 100 * $design-width-pg"/>
    <xsl:apply-templates select="." mode="shortdescription"/>
    <xsl:text>)@]* </xsl:text>
</xsl:template>

<!-- Puts the description into an "alt" tag.                               -->
<xsl:template match="image" mode="shortdescription">
    <xsl:choose>
        <xsl:when test="@decorative = 'yes'">
            <xsl:text>, alt=&gt;""</xsl:text>
        </xsl:when>
        <xsl:when test="not(string(shortdescription) = '')">
            <xsl:variable name="description-text">
                <xsl:apply-templates select="shortdescription"/>
            </xsl:variable>
            <xsl:variable name="delimiter">
                <xsl:call-template name="find-unused-character">
                    <xsl:with-param name="string" select="$description-text"/>
                    <xsl:with-param name="charset" select="concat('&quot;|/\?:;.,=+-_~`!^&amp;*',&SIMPLECHAR;)"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:text>, alt=&gt;qq</xsl:text>
            <xsl:value-of select="concat($delimiter, $description-text, $delimiter)"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- A description here should only have text nodes and var children.      -->
<xsl:template match="image/shortdescription">
    <xsl:apply-templates select="text()|var"/>
</xsl:template>

<!-- An image description may depend on the value of a simple scalar var   -->
<!-- Perhaps this should warn if @name is not in Perl scalar syntax        -->
<xsl:template match="shortdescription/var">
    <xsl:value-of select="@name"/>
</xsl:template>

<xsl:template match="image[latex-image]" mode="latex-image-code">
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pg-name"/>
    <xsl:text> = createLaTeXImage();&#xa;</xsl:text>
    <xsl:if test="$docinfo/latex-image-preamble">
        <xsl:apply-templates select="." mode="pg-name"/>
        <xsl:text>->addToPreamble(latexImagePreamble());&#xa;</xsl:text>
    </xsl:if>
    <xsl:variable name="pg-latex-image-code">
        <xsl:apply-templates select="latex-image/text()|latex-image/var" mode="latex-image"/>
    </xsl:variable>
    <xsl:apply-templates select="." mode="pg-name"/>
    <xsl:text>->BEGIN_LATEX_IMAGE&#xa;</xsl:text>
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="$pg-latex-image-code"/>
    </xsl:call-template>
    <xsl:text>&#xa;END_LATEX_IMAGE&#xa;</xsl:text>
</xsl:template>

<xsl:template match="image" mode="pg-name">
    <xsl:choose>
        <xsl:when test="@pg-name">
            <xsl:value-of select="@pg-name"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>$image_</xsl:text>
            <xsl:number count="image" from="webwork" level="any" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="exercisegroup/introduction//image[latex-image]" mode="pg-name">
    <xsl:text>$introduction_image_</xsl:text>
    <xsl:number count="image" from="exercisegroup" level="any" />
</xsl:template>

<xsl:template match="text()" mode="latex-image">
    <xsl:variable name="dollar-fixed"  select="str:replace(.,             '\$', '\~~$')"/>
    <xsl:variable name="percent-fixed" select="str:replace($dollar-fixed, '\%', '\~~%')"/>
    <xsl:variable name="at-fixed"      select="str:replace($percent-fixed, '@',  '~~@')"/>
    <xsl:value-of select="$at-fixed"/>
</xsl:template>

<!-- An "instruction" is a peer of p, only within a webwork. The purpose   -->
<!-- is to give the reader something like keyboard syntax instructions     -->
<!-- but withhold these in print output.                                   -->
<xsl:template match="instruction">
    <xsl:if test="preceding-sibling::p and not(child::*[1][self::ol] or child::*[1][self::ul])">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>[@KeyboardInstructions(</xsl:text>
    <xsl:apply-templates select="." mode="delimit"/>
    <xsl:text>)@]**</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Inside math we need to print definitions for PTX author-defined      -->
<!-- LaTeX macros to support WeBWorK's images display mode.               -->

<!-- TODO: This named template examines the current context (see '.' in   -->
<!-- contains() below), so should be a match template. But its recursive  -->
<!-- implementation makes it a named template for now.                    -->
<xsl:template name="select-latex-macros">
    <xsl:param name="macros" select="$latex-macros" />
    <xsl:variable name="trimmed-start">
        <xsl:if test="contains($macros, '\newcommand{')">
            <xsl:value-of select="substring-after($macros, '\newcommand{')"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="macro-name">
        <xsl:if test="contains($trimmed-start, '}')">
            <xsl:value-of select="substring-before($trimmed-start, '}')"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="macro-command">
        <xsl:value-of select="substring-before($macros, '&#xa;')"/>
    </xsl:variable>
    <xsl:variable name="next-lines">
        <xsl:value-of select="substring-after($macros, '&#xa;')"/>
    </xsl:variable>
    <xsl:if test="contains(., $macro-name)">
        <xsl:value-of select="normalize-space($macro-command)"/>
    </xsl:if>
    <xsl:if test="not($next-lines = '')">
        <xsl:call-template name="select-latex-macros">
            <xsl:with-param name="macros" select="$next-lines"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- ##################################################################### -->
<!-- ##################################################################### -->
<!-- Above: templates for elements that only ever apply within a webwork   -->
<!-- Below: templates for elements that also exist outside webwork         -->
<!-- ##################################################################### -->
<!-- ##################################################################### -->

<!-- ########## -->
<!-- Paragraphs -->
<!-- ########## -->

<!-- In PGML, paragraph breaks are just blank lines. End as normal with a -->
<!-- line feed, then issue a blank line to signify the break. If p is     -->
<!-- inside a list, special handling                                      -->
<xsl:template match="p">
    <xsl:param name="b-human-readable" />
    <xsl:if test="preceding-sibling::p and not(child::*[1][self::ol] or child::*[1][self::ul])">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:apply-templates>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <!-- If p is last thing in entire (maybe nested) list, explicitly terminate list with three spaces at end of line. -->
    <xsl:if test="parent::li and not(following-sibling::*) and not(following::li)">
        <xsl:text>   </xsl:text>
    </xsl:if>
    <!-- Blank line required or PGML will treat two adjacent p as one -->
    <xsl:if test="not(parent::li) or following-sibling::* or parent::li/following-sibling::*">
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Some common wrappers for image and tabular   -->
<!-- Formerly this template was for sidebyside    -->
<!-- And we leave it to also work on a sidebyside -->
<!-- for backwards compatibility. However, such   -->
<!-- use will be caught by a deprectation warning -->
<!-- as well as fail a schema validation.         -->
<xsl:template match="image|tabular|sidebyside">
    <xsl:param name="b-human-readable" />
    <xsl:if test="preceding-sibling::p">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:if test="not(ancestor::li)">
        <xsl:text>&gt;&gt; </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="self::image|self::tabular|self::sidebyside/image|self::sidebyside/tabular" mode="components">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:if test="not(ancestor::li)">
        <xsl:text> &lt;&lt;</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ######### -->
<!-- Numbering -->
<!-- ######### -->

<!-- The cross-reference numbering scheme uses \ref, \hyperref -->
<!-- for LaTeX and numbers elsewhere, so it is unimplmented in -->
<!-- pretext-common.xsl, hence we implement it here           -->
<!-- This is identical to pretext-html.xsl                    -->

<xsl:template match="*" mode="xref-number">
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- ######### -->
<!-- PGML Math -->
<!-- ######### -->

<!-- extract-pg.xsl documentation -->
<!-- PGML inline math uses its own delimiters: [`...`] and [```...```]     -->
<!-- NB: we allow the "var" element as a child                             -->
<!-- To support a PTX author's custom LaTeX macros when the problem is     -->
<!-- used within WeBWorK, we must define each macro as it is used within   -->
<!-- each math environment. This is the only way to simultaneiously        -->
<!-- support HTML_mathjax, HTML_dpng, and TeX display modes.               -->

<!-- extract-pg-ptx.xsl documentation -->
<!-- PGML inline math uses its own delimiters: [`...`] and [```...```]     -->
<!-- NB: we allow the "var" element as a child                             -->

<!-- Common documentation -->
<!-- See the -common stylesheet for manipulations of math elements     -->
<!-- and subsequent text nodes that lead with punctuation.  Basically, -->
<!-- punctuation can migrate from the start of the text node and into  -->
<!-- the math, wrapped in a \text{}.  We do this to display math as a  -->
<!-- service to authors.  But LaTeX handles this situation carefully   -->
<!-- for inline math, so we do the same here.                          -->
<xsl:variable name="math.punctuation.include" select="'all'"/>

<xsl:template match="m">
    <xsl:param name="b-human-readable" />
    <xsl:text>[`</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:call-template name="select-latex-macros"/>
    </xsl:if>
    <xsl:apply-templates select="text()|var" />
    <!-- look ahead to absorb immediate clause-ending punctuation -->
    <xsl:apply-templates select="." mode="get-clause-punctuation" />
    <xsl:text>`]</xsl:text>
</xsl:template>

<!-- PGML [```...```] creates display math -->
<xsl:template match="md[@pi:authored-one-line]">
    <xsl:param name="b-human-readable" />
    <xsl:text>&#xa;&#xa;</xsl:text>
    <xsl:if test="ancestor::ul|ancestor::ol">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>[```</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:call-template name="select-latex-macros"/>
    </xsl:if>
    <!-- only a single mrow as a child (transition from old "me") -->
    <xsl:apply-templates select="mrow/text()|mrow/var" />
    <!-- look ahead to absorb immediate clause-ending punctuation -->
    <xsl:apply-templates select="." mode="get-clause-punctuation" />
    <xsl:text>```]&#xa;&#xa;</xsl:text>
    <xsl:if test="following-sibling::text()[normalize-space()] or following-sibling::*">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
</xsl:template>

<xsl:template match="md[not(@pi:authored-one-line)]">
    <xsl:param name="b-human-readable" />
    <xsl:apply-templates select="." mode="body">
        <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="md[not(@pi:authored-one-line)]" mode="body">
    <xsl:param name="b-human-readable"/>
    <xsl:variable name="complete-latex">
        <xsl:if test="$b-human-readable">
            <xsl:text>&#xa;</xsl:text>
            <xsl:if test="ancestor::ul|ancestor::ol">
                <xsl:call-template name="potential-list-indent" />
            </xsl:if>
        </xsl:if>
        <xsl:text>\begin{</xsl:text>
        <xsl:apply-templates select="." mode="displaymath-alignment"/>
        <xsl:text>}</xsl:text>
        <xsl:apply-templates select="." mode="alignat-columns" />
        <xsl:text>&#xa;</xsl:text>
        <!-- Indentation of mrow/intertext is in each one's template   -->
        <xsl:apply-templates select="mrow|intertext"/>
        <xsl:if test="ancestor::ul|ancestor::ol">
            <xsl:call-template name="potential-list-indent" />
        </xsl:if>
        <xsl:text>\end{</xsl:text>
        <xsl:apply-templates select="." mode="displaymath-alignment"/>
        <xsl:text>}</xsl:text>
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>
    <xsl:apply-templates select="." mode="display-math-wrapper">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
        <xsl:with-param name="content" select="$complete-latex" />
    </xsl:apply-templates>
</xsl:template>

<!-- Within a WeBWorK, md and rows are never numbered -->
<xsl:template match="md[not(@pi:authored-one-line)]" mode="displaymath-alignment">
    <xsl:choose>
        <!-- look for @alignment override, possibly bad -->
        <xsl:when test="@alignment='gather'">
            <xsl:text>gathered</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment='alignat'">
            <xsl:text>alignedat</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment='align'">
            <xsl:text>aligned</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment">
            <xsl:message>PTX:ERROR:   display math @alignment attribute "<xsl:value-of select="@alignment" />" is not recognized (should be "aligned", "gathered", "alignedat")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <!-- sniff for alignment specifications    -->
        <!-- this can be easily fooled, eg matrices-->
        <xsl:when test="contains(., '&amp;') or contains(., '\amp')">
            <xsl:text>aligned</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>gathered</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="md[mrow]" mode="display-math-wrapper">
    <xsl:param name="b-human-readable" />
    <xsl:param name="content" />
    <xsl:text>&#xa;&#xa;</xsl:text>
    <xsl:if test="ancestor::ul|ancestor::ol">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>[```</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:call-template name="select-latex-macros"/>
    </xsl:if>
    <xsl:value-of select="$content" />
    <xsl:if test="ancestor::ul|ancestor::ol">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>```]</xsl:text>
    <xsl:text>&#xa;&#xa;</xsl:text>
    <xsl:if test="following-sibling::text()[normalize-space()] or following-sibling::*">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
</xsl:template>

<xsl:template match="mrow">
    <xsl:if test="ancestor::ul|ancestor::ol">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:apply-templates select="text()|var|xref" />
    <xsl:if test="not(following-sibling::*[self::mrow or self::intertext])">
        <!-- look ahead to absorb immediate clause-ending punctuation -->
        <!-- pass the enclosing environment (md) as the context       -->
        <xsl:apply-templates select="parent::md[mrow]" mode="get-clause-punctuation" />
    </xsl:if>
    <!-- PG cannot actually mirror LaTeX intertext functionality. As  -->
    <!-- a consequence, we should not line break an mrow that         -->
    <!-- immediately preceds an intertext.                            -->
    <xsl:if test="following-sibling::mrow and not(following-sibling::*[1][self::intertext])">
       <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="intertext">
    <xsl:if test="ancestor::ul|ancestor::ol">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="parent::*" mode="displaymath-alignment"/>
    <xsl:text>}```]&#xa;</xsl:text>
    <xsl:if test="ancestor::ul|ancestor::ol">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:if test="ancestor::ul|ancestor::ol">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>[```\begin{</xsl:text>
    <xsl:apply-templates select="parent::*" mode="displaymath-alignment"/>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="parent::*" mode="alignat-columns"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ######### -->
<!-- Groupings -->
<!-- ######### -->

<!-- We cannot rely on the -common templates for these,   -->
<!-- because if they contain math, we need to respect the -->
<!-- human readable parameter.                            -->

<xsl:template match="q">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="lq-character"/>
    <xsl:apply-templates>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:call-template name="rq-character"/>
</xsl:template>

<xsl:template match="sq">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="lsq-character"/>
    <xsl:apply-templates>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:call-template name="rsq-character"/>
</xsl:template>

<xsl:template match="dblbrackets">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="ldblbracket-character"/>
    <xsl:apply-templates>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:call-template name="rdblbracket-character"/>
</xsl:template>

<xsl:template match="angles">
    <xsl:param name="b-human-readable" />
    <xsl:call-template name="langle-character"/>
    <xsl:apply-templates>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:call-template name="rangle-character"/>
</xsl:template>


<!-- ########################## -->
<!-- Numbers, units, quantities -->
<!-- ########################## -->

<!-- Implemented similarly as in pretext-html.xsl, but we avoid the       -->
<!-- unicode thinspace. And avoid the unicode fraction slash with sub and -->
<!-- sup elements for a fractional unit. And implement exponent with a    -->
<!-- literal ^ instead of superscript. Perhaps once unicode is supported  -->
<!-- in WeBWorK, revisit some of these differences.                       -->
<xsl:template match="quantity">
    <!-- warning if there is no content -->
    <xsl:if test="not(descendant::unit) and not(descendant::per) and not(descendant::mag)">
        <xsl:message>
        <xsl:text>PTX:WARNING: magnitude or units needed</xsl:text>
        </xsl:message>
    </xsl:if>
    <!-- print magnitude if there is one -->
    <xsl:if test="descendant::mag">
        <xsl:apply-templates select="mag"/>
        <!-- if the units that follow are fractional, space -->
        <xsl:if test="descendant::per">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- if there are non-fracitonal units, print them -->
    <xsl:if test="descendant::unit and not(descendant::per)">
        <xsl:apply-templates select="unit" />
    </xsl:if>
    <!-- if there are fracitonal units with a numerator part, print them -->
    <xsl:if test="descendant::unit and descendant::per">
        <xsl:apply-templates select="unit" />
        <xsl:text>/</xsl:text>
        <xsl:apply-templates select="per" />
    </xsl:if>
    <!-- if there are fracitonal units without a numerator part, print them -->
    <xsl:if test="not(descendant::unit) and descendant::per">
        <xsl:text>1</xsl:text>
        <xsl:text>/</xsl:text>
        <xsl:apply-templates select="per" />
    </xsl:if>
</xsl:template>

<!-- Magnitude                                      -->
<xsl:template match="mag">
    <xsl:variable name="mag">
        <xsl:apply-templates/>
    </xsl:variable>
    <xsl:value-of select="str:replace($mag,'\pi','[`\pi`]')"/>
</xsl:template>

<!-- unit and per children of a quantity element    -->
<!-- have a mandatory base attribute                -->
<!-- may have prefix and exp attributes             -->
<!-- base and prefix are not abbreviations          -->

<xsl:key name="prefix-key" match="prefix" use="concat(../@name, @full)"/>
<xsl:key name="prefix-key" match="prefix" use="concat(../@name, @full)"/>
<xsl:key name="base-key" match="base" use="concat(../@name, @full)"/>

<xsl:template match="unit|per">
    <xsl:if test="not(parent::quantity)">
        <xsl:message>PTX:WARNING: unit or per element should have parent quantity element</xsl:message>
    </xsl:if>
    <!-- if the unit is 1st and no mag, no need for thinspace. Otherwise, give space -->
    <xsl:if test="position() != 1 or (local-name(.)='unit' and (preceding-sibling::mag or following-sibling::mag) and not(preceding-sibling::per or following-sibling::per))">
        <xsl:text> </xsl:text>
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:variable name="prefix">
            <xsl:value-of select="@prefix" />
        </xsl:variable>
        <xsl:variable name="short">
            <xsl:for-each select="document('pretext-units.xsl')">
                <xsl:value-of select="key('prefix-key',concat('prefixes',$prefix))/@short"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$short" />
    </xsl:if>
    <!-- base unit is *mandatory* so check to see if it has been provided -->
    <xsl:choose>
        <xsl:when test="@base">
            <xsl:variable name="base">
                <xsl:value-of select="@base" />
            </xsl:variable>
            <xsl:variable name="short">
                <xsl:for-each select="document('pretext-units.xsl')">
                    <xsl:value-of select="key('base-key',concat('bases',$base))/@short"/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="$short" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>
                <xsl:text>PTX:WARNING: base unit needed</xsl:text>
            </xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- exponent is optional -->
    <xsl:if test="@exp">
        <xsl:text>^</xsl:text>
        <xsl:value-of select="@exp"/>
    </xsl:if>
</xsl:template>


<!-- ############## -->
<!-- Various Markup -->
<!-- ############## -->

<xsl:template match="url">
    <xsl:text>[@htmlLink("</xsl:text>
    <xsl:value-of select="@href" />
    <xsl:text>","</xsl:text>
    <xsl:choose>
        <xsl:when test="not(*) and not(normalize-space())">
            <xsl:value-of select="@href" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>","TARGET='_blank'")@]*</xsl:text>
</xsl:template>

<!-- http://webwork.maa.org/wiki/Introduction_to_PGML#Basic_Formatting -->

<!-- two spaces at line-end makes a newline in PGML-->
<xsl:template match="cell/line">
    <!-- This leads to lines of PG code that would ideally be indented     -->
    <!-- for human readability, but it cannot be avoided because the       -->
    <!-- cell is fed to PGML::Format(), and would act on the indentation.  -->
    <xsl:apply-templates/>
    <xsl:text>  &#xa;</xsl:text>
</xsl:template>

<!-- Emphasis: underscores produce italic -->
<!-- Foreign:  for phrases                -->
<xsl:template match="em|foreign">
    <xsl:text>_</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Booktitle: slanted normally, we italic here-->
<xsl:template match="booktitle">
    <xsl:text>_</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Alert: asterik-underscore produces bold-italic -->
<xsl:template match="alert">
    <xsl:text>*</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>*</xsl:text>
</xsl:template>

<!-- TeX logo  -->
<xsl:template match="tex">
    <xsl:param name="b-human-readable" />
    <xsl:choose>
        <xsl:when test="$b-human-readable">
            <xsl:text>[@MODES(HTML =&gt; '\(\mathrm\TeX\)', TeX =&gt; '\TeX', PTX =&gt; '&lt;tex/&gt;')@]*</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[@MODES(HTML=&gt;'\(\mathrm\TeX\)',TeX=&gt;'\TeX', PTX=&gt;'&lt;tex/&gt;')@]*</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- LaTeX logo  -->
<xsl:template match="latex">
    <xsl:param name="b-human-readable" />
    <xsl:choose>
        <xsl:when test="$b-human-readable">
            <xsl:text>[$LATEX]*</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[$TEX]*</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- PGML is content with "dumb" quotes and will do    -->
<!-- the right thing in a conversion to "smart" quotes -->
<!-- in various WW output formats                      -->

<xsl:template name="lsq-character">
    <xsl:text>'</xsl:text>
</xsl:template>

<xsl:template name="rsq-character">
    <xsl:text>'</xsl:text>
</xsl:template>

<xsl:template name="lq-character">
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template name="rq-character">
    <xsl:text>"</xsl:text>
</xsl:template>

<!-- http://webwork.maa.org/wiki/Special_Characters_-_PGML -->
<!-- suggests PGML understands the TeX special characters. -->
<!-- There seems enough exceptions that we will routinely  -->
<!-- escape them. We definitely need to author ampersands  -->
<!-- and angle brackets with XML elements to avoid source  -->
<!-- conflicts, the others are conveniences. \ is PGML's   -->
<!-- escape character, thus is itself escaped              -->
<!--   <, >, &, %, $, ^, _, #, ~, {, }                     -->

<!-- NB: angle brackets as characters are not                 -->
<!-- implemented throughout PTX.  But for math *only*         -->
<!-- (ie LaTeX) the macros \lt, \gt are supported universally -->

<!--       Alex Jordan, 2018-12-07, pretext-dev list                 -->
<!--                                                                 -->
<!-- * >  if there are two of these and then a space at the          -->
<!--      start of a line, right justify the line.                   -->
<!--                                                                 -->
<!-- * <  if the above is in effect, and the line ends with          -->
<!--      a space and two of these, center the line.                 -->
<!--                                                                 -->
<!-- * Some combinations of whitespace before the &lt;&lt; and       -->
<!--   after the &gt;&gt; will prevent any action and print the      -->
<!--   characters, and other combinations allow the action. I        -->
<!--   think this is a bug and white space should not prevent        -->
<!--   the action.                                                   -->
<!--                                                                 -->
<!-- * &, %, ^, ~  No need to escape in PGML                         -->
<!--                                                                 -->
<!-- * $  No need to escape dollar in PGML, however this needs to be -->
<!--      escaped when in image descriptions. And harmless to escape -->
<!--      in PGML.                                                   -->
<!--                                                                 -->
<!-- * _  If there are two of these in a line, the parts in          -->
<!--      between are italicized.                                    -->
<!--                                                                 -->
<!-- * [, ] should always be escaped if you want the characters      -->
<!--        printed. Except if they don't pair up, you don't need to -->
<!--        escape them.                                             -->
<!--                                                                 -->
<!-- * #  If n of these are at the start of a line, that makes       -->
<!--      the line a heading level n. Whitespace before the # may or -->
<!--      may not break that, but I think it is a bug and whitespace -->
<!--      shouldn't break that. Otherwise # doesn't need escaping.   -->
<!--                                                                 -->
<!-- * {  I think only needs to be escaped when immediately          -->
<!--      follow a [ ] pair.                                         -->
<!--                                                                 -->
<!-- * }  Not sure about this one if it ever would need escaping.    -->
<!--                                                                 -->
<!-- * - - -, ===  Three or more of these in a row make a horizontal -->
<!--             rule when they start a line, even if other          -->
<!--             characters come after on that line. (They get       -->
<!--             printed on the next line.) Leading white space      -->
<!--             seems to prevent this but I don't think it should.  -->
<!--                                                                 -->
<!-- * *  Always escape this if you want the character.              -->
<!--                                                                 -->
<!--                                                                 -->
<!-- * -, + Escape these if they are the first non-white space       -->
<!--       character on a line or they will start an unordered list. -->
<!--                                                                 -->
<!-- * ```  three backticks start and end "code" which is more like  -->
<!--        PTX pre                                                  -->
<!--                                                                 -->
<!-- * :  A line opening with a colon and two (three) spaces makes   -->
<!--      preformatted text. (not really a verbatim block)           -->
<!--                                                                 -->
<!-- * ', " If you want "dumb" quotes, escape them.                  -->
<!--                                                                 -->
<!-- * \    Always escape backslash.                                 -->
<!-- #################################################### -->

<!-- Ellipsis -->
<!-- Just three periods -->
<xsl:template name="ellipsis-character">
    <xsl:text>...</xsl:text>
</xsl:template>

<!-- ############### -->
<!-- Text Processing -->
<!-- ############### -->

<!-- The general template for matching "text()" nodes will     -->
<!-- apply this template (there is a hook there).  Verbatim    -->
<!-- text should be manipulated in templates with              -->
<!-- "xsl:value-of" and so not come through here.  Conversely, -->
<!-- when "xsl:apply-templates" is applied, the template will  -->
<!-- have effect.                                              -->
<!--                                                           -->
<!-- These are characters which PGML gives special meaning,    -->
<!-- and should be escaped to prevent accidents.               -->

<!-- Necessary to prevent XML quote confusion -->
<xsl:variable name="apostrophe">
    <xsl:text>'</xsl:text>
</xsl:variable>

<xsl:template name="text-processing">
    <xsl:param name="text"/>

    <!-- NB: many of these symbols only need to be disrupted in certain    -->
    <!-- locations or in certain combinations.  With regular expressions   -->
    <!-- in XSLT 3 we could do better, especially in cases where the       -->
    <!-- effect only happens at the start of a line.  So, as is, we overdo -->
    <!-- it, without making too big of an unnecessary mess elsewhere.      -->
    <!--                                                                   -->
    <!-- Precise regular expressions for various conditions are at         -->
    <!-- https://github.com/openwebwork/pg/blob/master/macros/PGML.pl      -->
    <!-- (as of 2018-12-09)                                                -->

    <!-- Backslash first, since more will be introduced in other replacements -->
    <xsl:variable name="backslash-fixed" select="str:replace($text,            '\', '\\')"/>
    <xsl:variable name="dollar-fixed"    select="str:replace($backslash-fixed, '$', '\$')"/>
    <xsl:variable name="asterisk-fixed"  select="str:replace($dollar-fixed,    '*', '\*')"/>
    <xsl:variable name="hash-fixed"      select="str:replace($asterisk-fixed,  '#', '\#')"/>
    <xsl:variable name="lbrace-fixed"    select="str:replace($hash-fixed,      '{', '\{')"/>
    <xsl:variable name="rbrace-fixed"    select="str:replace($lbrace-fixed,    '}', '\}')"/>
    <xsl:variable name="lbracket-fixed"  select="str:replace($rbrace-fixed,    '[', '\[')"/>
    <xsl:variable name="rbracket-fixed"  select="str:replace($lbracket-fixed,  ']', '\]')"/>

    <!-- We translate textual apostrophes to the escape sequence [$APOS] -->
    <!-- <xsl:variable name="apostrophe-fixed"  select="str:replace($rbracket-fixed, $apostrophe, '[$APOS]')"/> -->

    <!-- Break up right justify AND center line -->
    <xsl:variable name="centerline-fixed" select="str:replace($rbracket-fixed, '&gt;&gt; ', '\&gt;\&gt;')"/>

    <!-- Break up any possibility of paired underscores for italics (overkill) -->
    <xsl:variable name="italicization-fixed" select="str:replace($centerline-fixed, '_', '\_')"/>

    <!-- Break up horizontal rule from three equals or three hyphens -->
    <!-- We escape the *middle* symbol, as a minimal disruption      -->
    <xsl:variable name="equalrule-fixed"  select="str:replace($italicization-fixed, '===', '=\==')"/>
    <xsl:variable name="hyphenrule-fixed" select="str:replace($equalrule-fixed,     '---', '-\--')"/>

    <!-- A line-leading hyphen is a list item, but we don't want *every* hyphen escaped  -->
    <!-- So we trap a hyphen with a space after it, as a compromise                      -->
    <!-- A regular expression with a match on "line beginning" will work better          -->
    <!-- A plus sign is similar, but outside mathematics, not so pervasive               -->
    <!-- NB: the hyphen substitution should not introduce consecutive backslashes when   -->
    <!-- triple-hyphen above is disrupted                                                -->
    <xsl:variable name="unordered-hyphen-fixed" select="str:replace($hyphenrule-fixed,       '- ', '\- ')"/>
    <xsl:variable name="unordered-plus-fixed"   select="str:replace($unordered-hyphen-fixed, '+',  '\+')"/>

    <!-- Triple backticks indicate code?  Not implemented. -->

    <xsl:value-of select="$unordered-plus-fixed"/>
</xsl:template>

<!-- Verbatim Snippets, Code -->
<!-- *Must* be "value-of" to avoid low-level text-processing template -->
<xsl:template name="code-wrapper">
    <xsl:param name="content"/>

    <xsl:choose>
        <xsl:when test="contains($content,'[|') or contains($content,'|]')">
            <xsl:message>PTX:ERROR:   the strings '[|' and '|]' are not supported within verbatim text ("<xsl:value-of select="$content"/>") in WeBWorK problems</xsl:message>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[|</xsl:text>
            <xsl:value-of select="$content"/>
            <xsl:text>|]*</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Lines of Code -->
<!-- Note this contruct uses PGML ```,                   -->
<!-- so it will return with the encompassing p closed,   -->
<!-- and inside a pre. WeBWorK doesn't really know where -->
<!-- p's open and close, so we can't hop to return cd.   -->
<xsl:template match="cd">
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="potential-list-indent" />
    <xsl:text>```&#xa;</xsl:text>
    <!-- Subsequent lines of PGML should not be indented -->
    <xsl:choose>
        <xsl:when test="cline">
            <xsl:apply-templates select="cline" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="." />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>```&#xa;</xsl:text>
</xsl:template>

<xsl:template match="cline">
    <xsl:variable name="trimmed-text">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    </xsl:variable>
    <!-- Remove carriage return, then append three spaces and carriage return for PGML line break -->
    <xsl:value-of select="concat(substring($trimmed-text, 1, string-length($trimmed-text) - 1),'   &#xa;')"/>
</xsl:template>


<!-- Preformatted Text -->
<!-- Sanitization analyzes *all* lines for left margin. -->
<xsl:template match="pre">
    <xsl:text>```&#xa;</xsl:text>
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
    <xsl:text>```&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- The next three are WW macros that PGML will format  -->
<!-- properly for WW HTML or LaTeX output, and so we use -->
<!-- them as the desired characters                      -->

<!-- Nonbreaking space -->
<xsl:template name="nbsp-character">
    <xsl:text>[$NBSP]*</xsl:text>
</xsl:template>

<!-- En dash           -->
<xsl:template name="ndash-character">
    <xsl:text>[$NDASH]*</xsl:text>
</xsl:template>

<!-- Em dash           -->
<xsl:template name="mdash-character">
    <xsl:text>[$MDASH]*</xsl:text>
</xsl:template>

<!-- The abstract template for "mdash" consults a publisher option -->
<!-- for thin space, or no space, surrounding an em-dash.  So the  -->
<!-- "thin-space-character" is needed for that purpose, and does   -->
<!-- not have an associated empty PTX element.                     -->
<!-- Cannot find such a thing documented for PGML, so just normal  -->

<xsl:template name="thin-space-character">
    <xsl:text> </xsl:text>
</xsl:template>


<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Implement PGML unordered lists -->
<xsl:template match="ul|ol">
    <xsl:param name="b-human-readable" />
    <!-- Lists are always inside a p.                                         -->
    <!-- If some text content or other elements precede the list within the p -->
    <!-- then line break to get a clean start. Otherwise do nothing; assume   -->
    <!-- whatever preceded the list gave adequate line breaks.                -->
    <xsl:if test="preceding-sibling::text()[normalize-space()] or preceding-sibling::*">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="li">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:text>&#xa;</xsl:text>
    <!-- When a list ends, there may be more content before the p ends. This  -->
    <!-- content needs to be indented the proper amount when the list was a   -->
    <!-- nested list.                                                         -->
    <xsl:if test="following-sibling::text()[normalize-space()] or following-sibling::*">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
</xsl:template>

<xsl:template match="li">
    <xsl:param name="b-human-readable" />
    <!-- Indent according to list depth; note this differs from potential-list-indent template. -->
    <xsl:call-template name="duplicate-string">
        <xsl:with-param name="count" select="4 * (count(ancestor::ul) + count(ancestor::ol) - 1)" />
        <xsl:with-param name="text"  select="' '" />
    </xsl:call-template>
    <xsl:choose>
        <xsl:when test="parent::ul">
            <xsl:choose>
                <xsl:when test="parent::*/@marker='disc'">*</xsl:when>
                <xsl:when test="parent::*/@marker='circle'">o</xsl:when>
                <xsl:when test="parent::*/@marker='square'">+</xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="count(ancestor::ul) mod 3 = 1">*</xsl:when>
                        <xsl:when test="count(ancestor::ul) mod 3 = 2">o</xsl:when>
                        <xsl:when test="count(ancestor::ul) mod 3 = 0">+</xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text> </xsl:text>
        </xsl:when>
        <xsl:when test="parent::ol">
            <xsl:choose>
                <xsl:when test="contains(parent::*/@marker,'1')">1</xsl:when>
                <xsl:when test="contains(parent::*/@marker,'a')">a</xsl:when>
                <xsl:when test="contains(parent::*/@marker,'A')">A</xsl:when>
                <xsl:when test="contains(parent::*/@marker,'i')">i</xsl:when>
                <xsl:when test="contains(parent::*/@marker,'I')">I</xsl:when>
                <xsl:otherwise>
                    <!-- the exercise will be numbered with Arabic numerals, -->
                    <!-- so we start the default cycle with lower-case Latin -->
                    <xsl:choose>
                        <xsl:when test="count(ancestor::ol) mod 4 = 1">a</xsl:when>
                        <xsl:when test="count(ancestor::ol) mod 4 = 2">i</xsl:when>
                        <xsl:when test="count(ancestor::ol) mod 4 = 3">A</xsl:when>
                        <xsl:when test="count(ancestor::ol) mod 4 = 0">1</xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>.  </xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- If the very first thing inside the li is a list or display math, we must line break before it -->
    <!-- starts. However the line with the li needs *some* non-space characater or it will be ignored  -->
    <!-- so we give it a NBSP.                                                                         -->
    <xsl:if test="(child::*|child::text())[normalize-space()][1][self::p] and
                  (
                    (child::p[1]/child::*|child::p[1]/child::text())[normalize-space()][1][self::ol] or
                    (child::p[1]/child::*|child::p[1]/child::text())[normalize-space()][1][self::ul] or
                    (child::p[1]/child::*|child::p[1]/child::text())[normalize-space()][1][self::me] or
                    (child::p[1]/child::*|child::p[1]/child::text())[normalize-space()][1][self::md[not(mrow)]] or
                    (child::p[1]/child::*|child::p[1]/child::text())[normalize-space()][1][self::md[mrow]]
                  )">
        <xsl:text>[$NBSP]*&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates>
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <!-- Explicitly end lists with three trailing spaces when at the absolute end of all nested list -->
    <!-- in document order. For structured list items with p, image, tabular children, this trailing -->
    <!-- whitespace must be added in respective templates prior to their trailing line breaks.       -->
    <xsl:if test="(child::*|child::text())[normalize-space()][position()=last()][self::text()] and not(following::*[1][self::li])">
        <xsl:text>   </xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- ###### -->
<!-- Tables -->
<!-- ###### -->

<xsl:template match="table">
    <xsl:param name="b-human-readable" />
    <xsl:apply-templates select="*[not(self::caption)]">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="tabular" mode="components">
    <xsl:param name="b-human-readable" />

    <xsl:text>[@DataTable(</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>  </xsl:text>
    </xsl:if>
    <xsl:text>[</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="row">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:if test="$b-human-readable">
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>  </xsl:text>
    </xsl:if>
    <xsl:text>],</xsl:text>
    <xsl:call-template name="key-value">
        <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
        <xsl:with-param name="key" select="'align'"/>
        <xsl:with-param name="value">
            <xsl:apply-templates select="." mode="texalignment"/>
        </xsl:with-param>
    </xsl:call-template>
    <!-- niceTables default for valign is top -->
    <xsl:if test="@valign = str:tokenize('bottom middle') or not(@valign) or @valign = ''">
        <xsl:call-template name="key-value">
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            <xsl:with-param name="key" select="'valign'"/>
            <xsl:with-param name="value">
                <xsl:choose>
                    <xsl:when test="@valign = 'bottom'">
                        <xsl:text>bottom</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>middle</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!-- is there a top border? -->
    <xsl:if test="@top = str:tokenize('minor medium major', ' ')">
        <xsl:call-template name="key-value">
            <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
            <xsl:with-param name="key" select="'top'"/>
            <xsl:with-param name="value">
                <xsl:call-template name="pg-hrule-specification">
                    <xsl:with-param name="width" select="@top"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <xsl:if test="$b-human-readable">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>);@]*</xsl:text>
</xsl:template>


<xsl:template match="tabular" mode="texalignment">
    <!-- left border -->
    <xsl:if test="@left">
        <xsl:call-template name="pg-vrule-specification">
            <xsl:with-param name="width" select="@left" />
        </xsl:call-template>
    </xsl:if>
    <xsl:choose>
        <!-- go through cols if we have them -->
        <xsl:when test="col">
            <xsl:apply-templates select="col" mode="texalignment"/>
        </xsl:when>
        <!-- there are no cols, so tabular attributes and defaults are in control -->
        <!-- but we guess how many columns there are using the first row          -->
        <xsl:otherwise>
            <xsl:text>*{</xsl:text>
            <xsl:value-of select="count(row[1]/cell) + sum(row[1]/cell[@colspan]/@colspan) - count(row[1]/cell[@colspan])"/>
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates select="." mode="per-column-specification"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="tabular" mode="per-column-specification">
    <!-- halign is an l, c, or r -->
    <xsl:call-template name="halign-specification">
        <xsl:with-param name="align">
            <xsl:choose>
                <!-- if the tabular has a specification -->
                <xsl:when test="@halign">
                    <xsl:value-of select="@halign" />
                </xsl:when>
                <!-- else the PTX default -->
                <xsl:otherwise>
                    <xsl:text>left</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
    <!-- now the right border, if any -->
    <xsl:call-template name="pg-vrule-specification">
        <xsl:with-param name="width" select="@right" />
    </xsl:call-template>
 </xsl:template>

<xsl:template match="col" mode="texalignment">
    <xsl:choose>
        <!-- if the column has a width we use that in a p{}-->
        <xsl:when test="@width != ''">
            <xsl:text>p{</xsl:text>
            <xsl:apply-templates select="." mode="absolute-width-inches"/>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- otherwise use an l, c, or r -->
        <xsl:otherwise>
            <xsl:call-template name="halign-specification">
                <xsl:with-param name="align">
                    <xsl:choose>
                        <!-- if the column has a specification -->
                        <xsl:when test="@halign">
                            <xsl:value-of select="@halign" />
                        </xsl:when>
                        <!-- else if the tabular has a specification -->
                        <xsl:when test="../@halign">
                            <xsl:value-of select="../@halign" />
                        </xsl:when>
                        <!-- else the PTX default -->
                        <xsl:otherwise>
                            <xsl:text>left</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <!-- now the right border, if any -->
    <xsl:call-template name="pg-vrule-specification">
        <xsl:with-param name="width">
            <xsl:choose>
                <xsl:when test="@right">
                    <xsl:value-of select="@right"/>
                </xsl:when>
                <xsl:when test="../@right">
                    <xsl:value-of select="../@right"/>
                </xsl:when>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="*" mode="absolute-width-inches">
    <xsl:variable name="percent-width">
        <xsl:call-template name="normalize-percentage">
            <xsl:with-param name="percentage" select="@width"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="concat(number(substring-before($percent-width,'%')) div 100 * 6.25, 'in')"/>
</xsl:template>


<xsl:template match="tabular/row">
    <xsl:param name="b-human-readable" />
    <xsl:if test="$b-human-readable">
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>    </xsl:text>
    </xsl:if>
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="cell">
        <xsl:with-param name="b-human-readable" select="$b-human-readable" />
    </xsl:apply-templates>
    <xsl:if test="$b-human-readable">
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>    </xsl:text>
    </xsl:if>
    <xsl:text>],</xsl:text>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<xsl:template match="cell">
    <xsl:param name="b-human-readable" />
    <xsl:if test="$b-human-readable and preceding-sibling::cell">
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>     </xsl:text>
    </xsl:if>

    <!-- A goal is to minimize length of code, so we work hard here to ascertain -->
    <!-- when a given cell specification like valign can be omitted, because the -->
    <!-- inherited or default value does the same thing.                         -->

    <!-- work out which col's left edge and which col's right edge align with this cell -->
    <xsl:variable name="left-col" select="count(preceding-sibling::cell) + sum(preceding-sibling::cell[@colspan]/@colspan) - count(preceding-sibling::cell[@colspan]) + 1"/>
    <xsl:variable name="right-col" select="$left-col + sum(self::cell[@colspan]/@colspan) - count(self::cell[@colspan])"/>

    <!-- work out if the cell needs to declare bottom -->
    <xsl:variable name="tabular-bottom">
        <xsl:choose>
            <xsl:when test="ancestor::tabular[1]/@bottom = str:tokenize('minor medium major', ' ')">
                <xsl:value-of select="ancestor::tabular[1]/@bottom"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="row-bottom">
        <xsl:choose>
            <xsl:when test="parent::row/@bottom = str:tokenize('minor medium major none', ' ')">
                <xsl:value-of select="parent::row/@bottom"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$tabular-bottom"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="cell-bottom">
        <xsl:choose>
            <xsl:when test="@bottom = str:tokenize('minor medium major none', ' ')">
                <xsl:value-of select="@bottom"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$row-bottom"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- work out if the cell needs to declare valign -->
    <xsl:variable name="tabular-valign">
        <xsl:choose>
            <xsl:when test="ancestor::tabular[1]/@valign = str:tokenize('top bottom', ' ')">
                <xsl:value-of select="ancestor::tabular[1]/@valign"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>middle</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="row-valign">
        <xsl:choose>
            <xsl:when test="parent::row/@valign = str:tokenize('top middle bottom', ' ')">
                <xsl:value-of select="parent::row/@valign"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$tabular-valign"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- work out if the cell needs to declare halign -->
    <xsl:variable name="tabular-halign">
        <xsl:choose>
            <xsl:when test="ancestor::tabular[1]/@halign = str:tokenize('center right', ' ')">
                <xsl:value-of select="ancestor::tabular[1]/@halign"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>left</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="col-halign">
        <xsl:choose>
            <xsl:when test="ancestor::tabular[1]/col[$left-col]/@halign = str:tokenize('center right left', ' ') and ancestor::tabular[1]/col[$left-col]/@halign != $tabular-halign">
                <xsl:value-of select="ancestor::tabular[1]/col[$left-col]/@halign"/>
            </xsl:when>
            <xsl:when test="ancestor::tabular[1]/col[$left-col]/@halign = 'justify' and 'left' != $tabular-halign">
                <xsl:text>left</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$tabular-halign"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="row-halign">
        <xsl:choose>
            <xsl:when test="parent::row/@halign = str:tokenize('center right left', ' ') and parent::row/@halign != $col-halign">
                <xsl:value-of select="parent::row/@halign"/>
            </xsl:when>
            <xsl:when test="parent::row/@halign = 'justify' and 'left' != $col-halign">
                <xsl:text>left</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$col-halign"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="cell-halign">
        <xsl:choose>
            <xsl:when test="@halign = str:tokenize('center right left', ' ') and @halign != $row-halign">
                <xsl:value-of select="@halign"/>
            </xsl:when>
            <xsl:when test="@halign = 'justify' and 'left' != $row-halign">
                <xsl:text>left</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$row-halign"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- work out if the cell needs to declare left -->
    <xsl:variable name="tabular-left">
        <xsl:choose>
            <xsl:when test="ancestor::tabular[1]/@left = str:tokenize('minor medium major', ' ')">
                <xsl:value-of select="ancestor::tabular[1]/@left"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="row-left">
        <xsl:choose>
            <xsl:when test="parent::row/@left = str:tokenize('minor medium major none', ' ')">
                <xsl:value-of select="parent::row/@left"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$tabular-left"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- work out if the cell needs to declare right -->
    <xsl:variable name="tabular-right">
        <xsl:choose>
            <xsl:when test="ancestor::tabular[1]/@right = str:tokenize('minor medium major', ' ')">
                <xsl:value-of select="ancestor::tabular[1]/@right"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="col-right">
        <xsl:choose>
            <xsl:when test="ancestor::tabular[1]/col[$right-col]/@right = str:tokenize('minor medium major none', ' ')">
                <xsl:value-of select="ancestor::tabular[1]/col[$right-col]/@right"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$tabular-right"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="cell-right">
        <xsl:choose>
            <xsl:when test="@right = str:tokenize('minor medium major none', ' ') and @right != $col-right">
                <xsl:value-of select="@right"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$col-right"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="cell-has-traits" select="
            boolean(@colspan)
            or
            $cell-halign != $col-halign
            or
            ($row-bottom != 'none' and not(preceding-sibling::cell))
            or
            $cell-bottom != $row-bottom
            or
            ($row-valign != $tabular-valign and not(preceding-sibling::cell))
            or
            ($row-left != $tabular-left and not(preceding-sibling::cell))
            or
            $cell-right != $col-right
    "/>

    <xsl:choose>
        <!-- if the cell only has data and no traits to declare, simplify the  -->
        <!-- output by leaving off the array reference delimiters (brackets)   -->
        <xsl:when test="not($cell-has-traits)">
            <xsl:text>PGML(</xsl:text>
            <xsl:apply-templates select="." mode="delimit"/>
            <xsl:text>),</xsl:text>
            <xsl:if test="$b-human-readable">
                <xsl:text>&#xa;</xsl:text>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[PGML(</xsl:text>
            <xsl:apply-templates select="." mode="delimit"/>
            <xsl:text>),</xsl:text>
            <!-- declare rowbottom if needed -->
            <xsl:if test="$row-bottom != 'none' and not(preceding-sibling::cell)">
                <xsl:call-template name="key-value">
                    <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
                    <xsl:with-param name="key" select="'rowbottom'"/>
                    <xsl:with-param name="value">
                        <xsl:call-template name="pg-hrule-specification">
                            <xsl:with-param name="width" select="$row-bottom"/>
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
                <!-- this is redundant, but it here for backward compatibility -->
                <xsl:call-template name="key-value">
                    <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
                    <xsl:with-param name="key" select="'midrule'"/>
                    <xsl:with-param name="value" select="1"/>
                </xsl:call-template>
            </xsl:if>
             <!-- declare bottom if needed -->
             <xsl:if test="$cell-bottom != $row-bottom">
                <xsl:call-template name="key-value">
                    <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
                    <xsl:with-param name="key" select="'bottom'"/>
                    <xsl:with-param name="value">
                        <xsl:call-template name="pg-hrule-specification">
                            <xsl:with-param name="width" select="$cell-bottom"/>
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:if>
            <!-- declare valign if needed -->
            <xsl:if test="$row-valign != $tabular-valign and not(preceding-sibling::cell)">
                <xsl:call-template name="key-value">
                    <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
                    <xsl:with-param name="key" select="'valign'"/>
                    <xsl:with-param name="value" select="$row-valign"/>
                </xsl:call-template>
            </xsl:if>
            <!-- declare halign if needed -->
            <xsl:if test="$cell-halign != $col-halign and not(ancestor::tabular[1]/col[$left-col]/@width) or ($row-left != $tabular-left and not(preceding-sibling::cell)) or ($cell-right != $col-right)">
                <xsl:call-template name="key-value">
                    <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
                    <xsl:with-param name="key" select="'halign'"/>
                    <xsl:with-param name="value">
                        <xsl:if test="$row-left != $tabular-left and not(preceding-sibling::cell)">
                            <xsl:call-template name="pg-vrule-specification">
                                <xsl:with-param name="width" select="$row-left"/>
                            </xsl:call-template>
                        </xsl:if>
                        <xsl:call-template name="halign-specification">
                            <xsl:with-param name="align" select="$cell-halign"/>
                        </xsl:call-template>
                        <xsl:if test="$cell-right != $col-right">
                            <xsl:call-template name="pg-vrule-specification">
                                <xsl:with-param name="width" select="$cell-right"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:if>
            <!-- declare colspan if present-->
            <xsl:if test="@colspan">
                <xsl:call-template name="key-value">
                    <xsl:with-param name="b-human-readable" select="$b-human-readable"/>
                    <xsl:with-param name="key" select="'colspan'"/>
                    <xsl:with-param name="value" select="@colspan"/>
                </xsl:call-template>
            </xsl:if>
            <!-- close cell's array reference bracket -->
            <xsl:text>],</xsl:text>
            <xsl:if test="$b-human-readable">
                <xsl:text>&#xa;</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate vertical rule width to a LaTeX vertical rule -->
<xsl:template name="pg-vrule-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width = 'none' or $width = '' or not($width)"/>
        <xsl:when test="$width = 'minor'">
            <xsl:text>|</xsl:text>
        </xsl:when>
        <xsl:when test="$width = 'medium'">
            <xsl:text>!{\vrule width 0.07em}</xsl:text>
        </xsl:when>
        <xsl:when test="$width = 'major'">
            <xsl:text>!{\vrule width 0.11em}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING:  left or right attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Translate vertical rule width to a LaTeX vertical rule -->
<xsl:template name="pg-hrule-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width = 'none' or $width = '' or not($width)">
            <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:when test="$width = 'minor'">
            <xsl:text>1</xsl:text>
        </xsl:when>
        <xsl:when test="$width = 'medium'">
            <xsl:text>2</xsl:text>
        </xsl:when>
        <xsl:when test="$width = 'major'">
            <xsl:text>3</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING:  top or bottom attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template name="key-value">
    <xsl:param name="b-human-readable"/>
    <xsl:param name="key"/>
    <xsl:param name="value"/>
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>      </xsl:text>
    </xsl:if>
    <xsl:value-of select="$key"/>
    <xsl:choose>
        <xsl:when test="$b-human-readable">
            <xsl:text> =&gt; </xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>=&gt;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>'</xsl:text>
    <xsl:value-of select="$value"/>
    <xsl:text>',</xsl:text>
</xsl:template>


<!-- ################# -->
<!-- Utility Templates -->
<!-- ################# -->

<!-- Very good for readability, very bad for base64 length -->
<xsl:template name="begin-block">
    <xsl:param name="block-title"/>
    <xsl:param name="b-human-readable" />
    <xsl:if test="$b-human-readable">
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>############################################################&#xa;</xsl:text>
        <xsl:text># </xsl:text>
        <xsl:value-of select="$block-title"/>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>############################################################&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Base indentation for lines of code in the middle of a list -->
<xsl:template name="potential-list-indent">
    <xsl:call-template name="duplicate-string">
        <xsl:with-param name="count" select="4 * (count(ancestor::ul) + count(ancestor::ol))" />
        <xsl:with-param name="text"  select="' '" />
    </xsl:call-template>
</xsl:template>

</xsl:stylesheet>
