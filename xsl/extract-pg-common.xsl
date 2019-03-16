<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2015-2017                                                   -->
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

<!-- IMPORTANT (2018-12-06):  this stylesheet is include'd at the end      -->
<!-- of two different stylesheets.  Each does different things with the    -->
<!-- PGML produced from PreTeXt source that describes a WeBWorK problem.   -->
<!-- A significant variance is whether or not the PGML is formatted        -->
<!-- verbosely for human viewing, or compactly for an economical base64    -->
<!-- string not exceeding capacities of web browser communications.        -->
<!--                                                                       -->
<!-- But principally, any stylesheet which uses this should operate        -->
<!-- exclusively on "webwork" elements, since these templates are only     -->
<!-- designed for producing PGML from "webwork" and there is no defense    -->
<!-- against the templates being applied elsewhere.  So a stylesheet which -->
<!-- includes this can (and typically should) import  mathbook-common.xsl  -->
<!-- for universal templates, but should not be simultaneously converting  -->
<!-- to some other output format.                                          -->
<!--                                                                       -->
<!-- The eventual goal is to produce an enhanced version of the PreTeXt    -->
<!-- source which includes identifiable representations of the WeBWorK     -->
<!-- problem described by PreTeXt source.                                  -->

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

<!-- Marginal notes that common routines may call upon not implemented     -->
<xsl:template name="margin-warning" />

<!-- extract-pg.xsl documentation -->
<!--#######################################################################-->
<!-- PG Construction. These templates are designed to create human-        -->
<!-- readable PG. This is in contrast with the templates in extract-pg-ptx -->
<!-- which are designed to create PG that behaves better for building PTX  -->
<!-- output.                                                               -->
<!--#######################################################################-->
<!-- extract-pg.xsl documentation -->

<!-- extract-pg-ptx.xsl documentation -->
<!--#######################################################################-->
<!-- PG Construction. These templates are designed to create  PG that      -->
<!-- behaves better for building PTX output. This is in contrast with the  -->
<!-- templates in extract-pg which are designed to create human-readable   -->
<!-- PG                                                                    -->
<!--#######################################################################-->
<!-- extract-pg-ptx.xsl documentation -->

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
<!-- 3. have a single statement child                                      -->
<!-- 4. have two or more stage children (known in WW as "scaffolded")      -->
<!-- This file is not concerned with the first two. The latter two top     -->
<!-- level templates follow.                                               -->


<xsl:template match="webwork[statement]">
    <xsl:param name="b-hint" select="true()" />
    <xsl:param name="b-solution" select="true()" />
    <xsl:param name="b-verbose" />
    <xsl:call-template   name="begin-problem">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:call-template   name="pg-macros">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:call-template   name="pg-header">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:apply-templates select="." mode="pg-setup">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:apply-templates select="statement">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:if test="$b-hint">
        <xsl:apply-templates select="hint">
            <xsl:with-param name="b-verbose" select="$b-verbose" />
        </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="$b-solution">
        <xsl:apply-templates select="solution">
            <xsl:with-param name="b-verbose" select="$b-verbose" />
        </xsl:apply-templates>
    </xsl:if>
    <xsl:call-template   name="end-problem">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
</xsl:template>


<xsl:template match="webwork[stage]">
    <xsl:param name="b-hint" select="true()" />
    <xsl:param name="b-solution" select="true()" />
    <xsl:param name="b-verbose" />
    <xsl:call-template   name="begin-problem" >
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:call-template   name="pg-macros">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:call-template   name="pg-header">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:if test="$b-verbose">
        <xsl:text>COMMENT('This problem is scaffolded with multiple parts');&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="pg-setup" >
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:call-template   name="begin-block">
        <xsl:with-param  name="block-title">Scaffold</xsl:with-param>
        <xsl:with-param  name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:text>Scaffold::Begin();</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="stage">
        <xsl:with-param name="b-hint" select="$b-hint" />
        <xsl:with-param name="b-solution" select="$b-solution" />
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>Scaffold::End();</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:call-template   name="end-problem">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
</xsl:template>

<!-- The setup element formerly had more internal structure. Now it only   -->
<!-- contains the pg-code element, and therefore could be eliminated.      -->
<xsl:template match="webwork" mode="pg-setup">
    <xsl:param name="b-verbose" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">PG Setup</xsl:with-param>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <!-- All our problems load MathObjects, and so should have at least    -->
    <!-- one explicit Context() load.                                      -->
    <xsl:if test="not(contains(setup/pg-code,'Context('))">
        <xsl:text>Context('Numeric');</xsl:text>
        <xsl:if test="$b-verbose">
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- pg-code verbatim, but trim indentation -->
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="setup/pg-code" />
    </xsl:call-template>
</xsl:template>


<!-- A stage is part of a multi-stage problem. WeBWorK calls these         -->
<!-- "scaffold" problems, which have "section"s                            -->
<xsl:template match="stage">
    <xsl:param name="b-hint" select="true()" />
    <xsl:param name="b-solution" select="true()" />
    <xsl:param name="b-verbose" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Section</xsl:with-param>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:text>Section::Begin("</xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:text>");</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="statement">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:if test="$b-hint">
        <xsl:apply-templates select="hint">
            <xsl:with-param name="b-verbose" select="$b-verbose" />
        </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="$b-solution">
        <xsl:apply-templates select="solution">
            <xsl:with-param name="b-verbose" select="$b-verbose" />
        </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>Section::End();</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- default template, for complete presentation -->
<xsl:template match="stage/statement|statement">
    <xsl:param name="b-verbose" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Body</xsl:with-param>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:text>&#xa;BEGIN_PGML&#xa;</xsl:text>
    <xsl:apply-templates>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:text>&#xa;END_PGML&#xa;</xsl:text>
</xsl:template>

<!-- default template, for solution -->
<xsl:template match="stage/solution|solution">
    <xsl:param name="b-verbose" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Solution</xsl:with-param>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:text>&#xa;BEGIN_PGML_SOLUTION&#xa;</xsl:text>
    <xsl:apply-templates>
        <xsl:with-param  name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:text>&#xa;END_PGML_SOLUTION&#xa;</xsl:text>
</xsl:template>

<!-- default template, for hint -->
<xsl:template match="stage/hint|hint">
    <xsl:param name="b-verbose" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Hint</xsl:with-param>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:if test="$b-verbose">
        <xsl:text>#Set value of $showHint in PGcourse.pl for course-wide attempt threshhold for revealing hints&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;BEGIN_PGML_HINT&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>&#xa;END_PGML_HINT&#xa;</xsl:text>
</xsl:template>

<!-- ############################## -->
<!-- Problem Header/Initializations -->
<!-- ############################## -->

<!-- Includes file header blurb promoting PTX -->
<xsl:template name="begin-problem">
    <xsl:param name="b-verbose" />
    <xsl:if test="$b-verbose">
        <xsl:call-template name="converter-blurb-webwork" />
        <xsl:call-template name="webwork-metadata" />
    </xsl:if>
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
</xsl:template>

<!-- Mine various parts of the surrounding text -->
<!-- Only ever called in verbose mode           -->
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
            <xsl:if test="not(position()=last())">
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
    <!-- WW problem is always enclosed directly by an PTX exercise -->
    <xsl:text>## Problem1(</xsl:text>
        <xsl:apply-templates select="parent::exercise" mode="number" />
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## Author(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## Institution(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## Language(</xsl:text>
        <xsl:value-of select="$document-language"/>
    <xsl:text>)&#xa;&#xa;</xsl:text>
</xsl:template>


<xsl:template name="pg-header">
    <xsl:param name="b-verbose" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Header</xsl:with-param>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:if test="$b-verbose">
        <xsl:text>COMMENT('</xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'authored'" />
        </xsl:call-template>
        <xsl:text> PreTeXt');&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>TEXT(beginproblem());</xsl:text>
    <xsl:if test="not($b-verbose)">
        <!-- see select-latex-macros template -->
        <xsl:variable name="macros">
            <xsl:call-template name="select-latex-macros"/>
        </xsl:variable>
        <xsl:if test="$macros != ''">
            <xsl:text>loadMacros("PCCmacros.pl");&#xa;</xsl:text>
            <!-- @ character is unlikely to appear in latex macro definitions, -->
            <!-- so it makes a good delimiter, better than single quote.       -->
            <xsl:text>TEXT(MODES(PTX=>'',HTML=>q@&lt;div style="display:none;">\(</xsl:text>
            <xsl:value-of select="$macros" />
            <xsl:text>\)&lt;/div>@));&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- ############## -->
<!-- Problem Ending -->
<!-- ############## -->

<xsl:template name="end-problem">
    <xsl:param name="b-verbose" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">End Problem</xsl:with-param>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>
    <xsl:text>&#xa;ENDDOCUMENT();</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ############## -->
<!-- Load PG Macros -->
<!-- ############## -->

<!-- call exactly once,        -->
<!-- context is "webwork" root -->
<xsl:template name="pg-macros">
    <xsl:param name="b-verbose" />

    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Load Macros</xsl:with-param>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:call-template>

    <!-- three standard macros always, order and placement is critical -->
    <xsl:variable name="standard-macros">
        <xsl:choose>
            <xsl:when test="$b-verbose">
                <xsl:text>  "PGstandard.pl",&#xa;</xsl:text>
                <xsl:text>  "MathObjects.pl",&#xa;</xsl:text>
                <xsl:text>  "PGML.pl",&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>"PGstandard.pl",</xsl:text>
                <xsl:text>"MathObjects.pl",</xsl:text>
                <xsl:text>"PGML.pl",</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- accumulate macros evidenced by some aspect of problem design      -->
    <!-- for details on what each macro file provides, see their source at -->
    <!-- https://github.com/openwebwork/pg/tree/master/macros              -->
    <!-- or                                                                -->
    <!-- https://github.com/openwebwork/webwork-open-problem-library/tree/master/OpenProblemLibrary/macros -->
    <xsl:variable name="implied-macros">
        <!-- tables -->
        <xsl:if test=".//tabular">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "niceTables.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"niceTables.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- bizarro arithmetic technique for assesing answer form -->
        <xsl:if test="contains(./setup/pg-code,'bizarro')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "bizarroArithmetic.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"bizarroArithmetic.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- multistage problems ("scaffolded") -->
        <xsl:if test=".//stage">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "scaffold.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"scaffold.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- links to syntax help following answer blanks -->
        <xsl:if test="$pg.answer.form.help = 'yes'">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "AnswerFormatHelp.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"AnswerFormatHelp.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- targeted feedback messages for specific wrong answers -->
        <xsl:if test="contains(./setup/pg-code,'AnswerHints')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "answerHints.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"answerHints.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- checkboxes multiple choice answers or the very useful NchooseK function-->
        <xsl:if test=".//var[@form='checkboxes'] or contains(./setup/pg-code,'NchooseK')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "PGchoicemacros.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"PGchoicemacros.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- essay answers -->
        <xsl:if test=".//var[@form='essay']">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "PGessaymacros.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"PGessaymacros.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- when there is a PGgraphmacros graph -->
        <xsl:if test=".//image[@pg-name]">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "PGgraphmacros.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"PGgraphmacros.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- instructions for entering answers into HTML forms -->
        <!-- utility for randomly generating variable letters -->
        <xsl:if test=".//instruction or contains(./setup/pg-code,'RandomVariableName')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "PCCmacros.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"PCCmacros.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- ################### -->
        <!-- Parser Enhancements -->
        <!-- ################### -->
        <!-- popup menu multiple choice answers -->
        <xsl:if test=".//var[@form='popup']">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserPopUp.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserPopUp.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- radio buttons multiple choice answers -->
        <xsl:if test=".//var[@form='buttons']">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserRadioButtons.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserRadioButtons.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- "assignment" answers, like "y=x+1", "f(x)=x+1" -->
        <xsl:if test="contains(./setup/pg-code,'parser::Assignment')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserAssignment.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserAssignment.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- allow "f(x)" as part of answers -->
        <xsl:if test="contains(./setup/pg-code,'parserFunction')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserFunction.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserFunction.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- numbers with units -->
        <xsl:if test="contains(./setup/pg-code,'NumberWithUnits')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserNumberWithUnits.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserNumberWithUnits.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- formulas with units -->
        <xsl:if test="contains(./setup/pg-code,'FormulaWithUnits')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserFormulaWithUnits.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserFormulaWithUnits.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- implicit planes, e.g. x+2y=3z+1 -->
        <xsl:if test="contains(./setup/pg-code,'ImplicitPlane')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserImplicitPlane.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserImplicitPlane.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- implicit equations, e.g. x^2+sin(x+y)=5 -->
        <xsl:if test="contains(./setup/pg-code,'ImplicitEquation')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserImplicitEquation.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserImplicitEquation.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- for questions where multiple answer blanks work in conjunction  -->
        <xsl:if test="contains(./setup/pg-code,'MultiAnswer')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserMultiAnswer.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserMultiAnswer.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- for questions where any one of a finite list of answers is allowable  -->
        <xsl:if test="contains(./setup/pg-code,'OneOf')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "parserOneOf.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"parserOneOf.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- #################### -->
        <!-- Math Object contexts -->
        <!-- #################### -->
        <xsl:if test="contains(./setup/pg-code,'Fraction')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "contextFraction.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"contextFraction.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'PiecewiseFunction')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "contextPiecewiseFunction.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"contextPiecewiseFunction.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'Ordering')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "contextOrdering.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"contextOrdering.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'InequalitySetBuilder')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "contextInequalitySetBuilder.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"contextInequalitySetBuilder.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'Inequalities')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "contextInequalities.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"contextInequalities.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'LimitedRadical')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "contextLimitedRadical.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"contextLimitedRadical.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'FiniteSolutionSets')">
            <xsl:choose>
                <xsl:when test="$b-verbose">
                    <xsl:text>  "contextFiniteSolutionSets.pl",&#xa;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"contextFiniteSolutionSets.pl",</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <!-- capture problem root to use inside upcoming for-each -->
    <xsl:variable name="problem-root" select="." />
    <!-- accumulate new macros supplied by problem author, warn if not new -->
    <xsl:variable name="user-macros">
        <xsl:for-each select=".//pg-macros/macro-file">
            <!-- wrap in quotes to protect accidental matches -->
            <xsl:variable name="fenced-macro">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="." />
                <xsl:text>"</xsl:text>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="contains($standard-macros, $fenced-macro)">
                    <xsl:message>PTX:WARNING: the WeBWorK PG macro <xsl:value-of select="."/> is always included for every problem</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:when test="contains($implied-macros, $fenced-macro)">
                    <xsl:message>PTX:WARNING: the WeBWorK PG macro <xsl:value-of select="."/> is implied by the problem construction and already included</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="$b-verbose">
                        <xsl:text>  </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="$fenced-macro" />
                    <xsl:text>,</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text>&#xa;</xsl:text>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:variable>
    <!-- always finish with PG course macro -->
    <xsl:variable name="course-macro">
        <xsl:variable name="fenced-macro">
            <xsl:text>"PGcourse.pl"</xsl:text>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="contains($standard-macros, $fenced-macro)">
                <xsl:message>PTX:WARNING: the WeBWorK PG macro PGcourse.pl is always included for every problem</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$b-verbose">
                    <xsl:text>  </xsl:text>
                </xsl:if>
                <xsl:value-of select="$fenced-macro" />
                <xsl:text>,</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text>&#xa;</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- put them together with a wrapper -->
    <xsl:variable name="load-macros">
        <xsl:text>loadMacros(</xsl:text>
        <xsl:if test="$b-verbose">
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
        <xsl:value-of select="$standard-macros" />
        <xsl:value-of select="$implied-macros" />
        <xsl:value-of select="$user-macros" />
        <xsl:value-of select="$course-macro" />
        <xsl:text>);</xsl:text>
        <xsl:if test="$b-verbose">
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$load-macros" />
    <!-- if images are used, explicitly refresh or stale images will be used in HTML -->
    <xsl:if test=".//image[@pg-name]">
        <xsl:text>$refreshCachedImages= 1;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ############## -->
<!-- PERL Variables -->
<!-- ############## -->

<!-- PGML markup for Perl variable in LaTeX expression -->
<xsl:template match="statement//var|hint//var|solution//var">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:if test="@form='checkboxes'">
        <xsl:text>->correct_ans()</xsl:text>
    </xsl:if>
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- An image description may depend on the value of a simple scalar var   -->
<!-- Perhaps this should warn if @name is not in Perl scalar syntax        -->
<xsl:template match="description//var">
    <xsl:value-of select="@name"/>
</xsl:template>


<!-- ############ -->
<!-- PGML answers -->
<!-- ############ -->

<!-- PGML answer input               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="statement//var[@width|@form]">
    <xsl:param name="b-verbose" />
    <xsl:apply-templates select="." mode="field">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="form-help"/>
</xsl:template>

<!-- MathObject answers -->
<!-- with variant for MathObjects like Matrix, Vector, ColumnVector      -->
<!-- where the shape of the MathObject guides the array of answer blanks -->
<xsl:template match="var[@width|@form]" mode="field">
    <xsl:param name="b-verbose" />
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
    <!-- when an answer blank is the first thing on a line, indent -->
    <!-- this is a styling preference that can't be customized     -->
    <xsl:if test="(count(preceding-sibling::*)+count(preceding-sibling::text()))=0 and parent::p/parent::statement">
        <xsl:text>    </xsl:text>
    </xsl:if>
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

<!-- Checkbox answers -->
<!-- TODO: not really supported yet. The checkbox handling in WeBWorK is  -->
<!-- technically broken. The issue is only surfacing when trying to do a  -->
<!-- checkbox problem from an iframe. Any attempt to check multiple boxes -->
<!-- and submit leads to only one box being seen as checked by WeBWorK.   -->
<xsl:template match="var[@form='checkboxes']" mode="field">
    <xsl:text>    [@</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>->print_a() @]*&#xa;</xsl:text>
    <xsl:text>&#xa;END_PGML&#xa;</xsl:text>
    <xsl:text>ANS(checkbox_cmp(</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>->correct_ans()));&#xa;</xsl:text>
    <xsl:text>&#xa;BEGIN_PGML&#xa;</xsl:text>
</xsl:template>

<!-- Essay answers -->
<!-- Example: [@ ANS(essay_cmp); essay_box(6,76) @]*   -->
<!-- Requires:  PGessaymacros.pl, automatically loaded -->
<!-- http://webwork.maa.org/moodle/mod/forum/discuss.php?d=3370 -->
<xsl:template match="var[@form='essay']" mode="field">
    <xsl:param name="b-verbose" />
    <xsl:text>[@ANS(essay_cmp);</xsl:text>
    <!-- NECESSARY? -->
    <xsl:if test="$b-verbose">
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

<xsl:template match="image[@pg-name]">
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:text>[@image(insertGraph(</xsl:text>
    <xsl:value-of select="@pg-name"/>
    <xsl:text>), width=&gt;</xsl:text>
    <xsl:value-of select="substring-before($width, '%') div 100 * $design-width-pg"/>
    <xsl:if test="description">
        <xsl:text>, extra_html_tags=&gt;qq!alt="</xsl:text>
        <xsl:apply-templates select="description" mode="pg" />
        <xsl:text>"!</xsl:text>
    </xsl:if>
    <xsl:text>)@]* </xsl:text>
</xsl:template>

<!-- A description here should only have text nodes and var children.      -->
<!-- Puts the description into an "alt" tag.                               -->
<xsl:template match="image[@pg-name]/description">
    <xsl:apply-templates select="text()|var"/>
</xsl:template>

<!-- An "instruction" is a peer of p, only within a webwork. The purpose   -->
<!-- is to give the reader something like keyboard syntax instructions     -->
<!-- but withhold these in print output.                                   -->
<xsl:template match="instruction">
    <xsl:if test="preceding-sibling::p|preceding-sibling::sidebyside and not(child::*[1][self::ol] or child::*[1][self::ul])">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>[@KeyboardInstructions(q?</xsl:text>
    <xsl:apply-templates />
    <xsl:text>?)@]**</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Documentation for extract-pg.xsl -->
<!-- Inside math we need to print definitions for PTX author-defined      -->
<!-- LaTeX macros. This template assumes each LaTeX macro is entirely on  -->
<!-- its own line and assumes they are defined with a \newcommand         -->
<!-- (not \renewcommand). It only outputs LaTeX macro definitions that    -->
<!-- are explicitly used, so if they are nested, then "inner" macros will -->
<!-- be missed. So authors should not use nested macro definitions.       -->
<!-- Macros are jammed together, but maybe need protection, like {}. The  -->
<!-- $latex-macros sanitized list assumes  mathbook-common.xsl is used.   -->
<!-- TODO: This named template examines the current context (see '.' in   -->
<!-- contains() below), so should be a match template. But its recursive  -->
<!-- implementation makes it a named template for now.                    -->

<!-- Documentation for extract-pg-ptx.xsl -->
<!-- Handling of PTX author-defined LaTeX macros is very different here   -->
<!-- than in pretex-pg.xsl. Here, we gather all macros used anywhere in   -->
<!-- the problem in one place, and define them once. As a temporary hack, -->
<!-- we print them inside math delimiters inside a KeyboardInstructions.  -->
<!-- The intended outcome is that in HTML static and print output these   -->
<!-- macro definitions will be ignored, while in HTML interactive output  -->
<!-- they will be loaded just once for the problem.                       -->
<!-- Note: an embedded interactive WeBWorK cell is using the WeBWorK      -->
<!-- server's MathJax, not the ambient PTX-loaded MathJax. So defining    -->
<!-- these macros in the problem is necessary.                            -->

<!-- This template assumes each LaTeX macro is entirely on                -->
<!-- its own line and assumes they are defined with a \newcommand         -->
<!-- (not \renewcommand). It only outputs LaTeX macro definitions that    -->
<!-- are explicitly used, so if they are nested, then "inner" macros will -->
<!-- be missed. So authors should not use nested macro definitions.       -->
<!-- Macros are jammed together, but maybe need protection, like {}. The  -->
<!-- $latex-macros sanitized list assumes  mathbook-common.xsl is used.   -->
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
    <xsl:param name="b-verbose" />
    <xsl:if test="preceding-sibling::p|preceding-sibling::sidebyside and not(child::*[1][self::ol] or child::*[1][self::ul])">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:apply-templates>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
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

<!-- Sidebyside in a WeBWorK expects only one child: image or tabular.    -->
<!-- Just applies templates to its child                                  -->
<!-- NB: this may need improvements, such as positioning                  -->
<!-- NB: a Schematron rule should enforce the single child                -->
<xsl:template match="sidebyside">
    <xsl:param name="b-verbose" />
    <xsl:if test="preceding-sibling::p|preceding-sibling::sidebyside">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:if test="not(ancestor::li)">
        <xsl:text>&gt;&gt; </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="image|tabular">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
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
<!-- mathbook-common.xsl, hence we implement it here           -->
<!-- This is identical to mathbook-html.xsl                    -->

<xsl:template match="*" mode="xref-number">
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- In common template, but have to point -->
<!-- to it since it is a modal template    -->
<xsl:template match="exercisegroup" mode="xref-number">
    <xsl:apply-imports />
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
<!-- Note: the default template for "text()" in xsl/mathbook-common.xsl    -->
<!-- will drop "clause-ending" punctuation that immediately follows a bit  -->
<!-- of math, and possibly remove some resulting leading whitespace. For   -->
<!-- inline math "m" this behavior is under the control of the global      -->
<!-- $latex-processing variable, which is only overridden for LaTeX        -->
<!-- processing itself. Then the math templates need to look forward and   -->
<!-- recover this punctuation with a \text{} wrapper.                      -->

<xsl:template match="m">
    <xsl:param name="b-verbose" />
    <xsl:text>[`</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:call-template name="select-latex-macros"/>
    </xsl:if>
    <xsl:apply-templates select="text()|var" />
    <!-- look ahead to absorb immediate clause-ending punctuation -->
    <xsl:apply-templates select="." mode="get-clause-punctuation" />
    <xsl:text>`]</xsl:text>
</xsl:template>

<!-- PGML [```...```] creates display math -->
<xsl:template match="me">
    <xsl:param name="b-verbose" />
    <xsl:text>&#xa;&#xa;</xsl:text>
    <xsl:if test="ancestor::ul|ancestor::ol">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>[```</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:call-template name="select-latex-macros"/>
    </xsl:if>
    <xsl:apply-templates select="text()|var" />
    <!-- look ahead to absorb immediate clause-ending punctuation -->
    <xsl:apply-templates select="." mode="get-clause-punctuation" />
    <xsl:text>```]&#xa;&#xa;</xsl:text>
    <xsl:if test="following-sibling::text()[normalize-space()] or following-sibling::*">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
</xsl:template>

<xsl:template match="md">
    <xsl:param name="b-verbose" />
    <xsl:text>&#xa;&#xa;</xsl:text>
        <xsl:if test="ancestor::ul|ancestor::ol">
            <xsl:call-template name="potential-list-indent" />
        </xsl:if>
    <xsl:choose>
        <xsl:when test="contains(., '&amp;') or contains(., '\amp')">
            <xsl:text>[```</xsl:text>
            <xsl:if test="$b-verbose">
                <xsl:call-template name="select-latex-macros"/>
            </xsl:if>
            <xsl:text>\begin{aligned}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow" />
            <xsl:text>\end{aligned}```]</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[```</xsl:text>
            <xsl:if test="$b-verbose">
                <xsl:call-template name="select-latex-macros"/>
            </xsl:if>
            <xsl:text>\begin{gathered}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow" />
            <xsl:text>\end{gathered}```]</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;&#xa;</xsl:text>
    <xsl:if test="following-sibling::text()[normalize-space()] or following-sibling::*">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
</xsl:template>

<xsl:template match="md/mrow">
    <xsl:if test="ancestor::ul|ancestor::ol">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:apply-templates select="text()|var|xref" />
    <xsl:if test="not(following-sibling::*[self::mrow or self::intertext])">
        <!-- look ahead to absorb immediate clause-ending punctuation -->
        <!-- pass the enclosing environment (md) as the context       -->
        <xsl:apply-templates select="parent::md" mode="get-clause-punctuation" />
    </xsl:if>
    <xsl:if test="following-sibling::mrow">
       <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
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
        <xsl:message terminate="no">
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
        <xsl:apply-templates />
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
            <xsl:for-each select="document('mathbook-units.xsl')">
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
                <xsl:for-each select="document('mathbook-units.xsl')">
                    <xsl:value-of select="key('base-key',concat('bases',$base))/@short"/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="$short" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="no">
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
            <xsl:apply-templates />
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
    <xsl:apply-templates />
    <xsl:text>  &#xa;</xsl:text>
</xsl:template>

<!-- Emphasis: underscores produce italic -->
<!-- Foreign:  for phrases                -->
<xsl:template match="em|foreign">
    <xsl:text>_</xsl:text>
    <xsl:apply-templates />
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Booktitle: slanted normally, we italic here-->
<xsl:template match="booktitle">
    <xsl:text>_</xsl:text>
    <xsl:apply-templates />
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Alert: asterik-underscore produces bold-italic -->
<xsl:template match="alert">
    <xsl:text>*</xsl:text>
    <xsl:apply-templates />
    <xsl:text>*</xsl:text>
</xsl:template>

<!-- TeX logo  -->
<xsl:template match="tex">
    <xsl:param name="b-verbose" />
    <xsl:choose>
        <xsl:when test="$b-verbose">
            <xsl:text>[@MODES(HTML =&gt; '\(\mathrm\TeX\)', TeX =&gt; '\TeX', PTX =&gt; '&lt;tex/&gt;')@]*</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[@MODES(HTML=&gt;'\(\mathrm\TeX\)',TeX=&gt;'\TeX', PTX=&gt;'&lt;tex/&gt;')@]*</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- LaTeX logo  -->
<xsl:template match="latex">
    <xsl:param name="b-verbose" />
    <xsl:choose>
        <xsl:when test="$b-verbose">
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

<xsl:template name="lbracket-character">
    <xsl:text>\[</xsl:text>
</xsl:template>

<xsl:template name="rbracket-character">
    <xsl:text>\]</xsl:text>
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
<!-- implemented throughout MBX.  But for math *only*         -->
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
<!-- * &, %, $, ^, ~  No need to escape in PGML                      -->
<!--                                                                 -->
<!-- * _  If there are two of these in a line, the parts in          -->
<!--      between are italicized.                                    -->
<!--                                                                 -->
<!-- * [, ] should always be escaped if you want the characters      -->
<!--        printed. Except if they don't pair up, you don't need to -->
<!--        escape them.                                             -->
<!--                                                                 -->
<!-- * #  If n of these are at the start of a line, that makes       -->
<!--      the line a header level n. Whitespace before the # may or  -->
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


<!-- Ampersand -->
<!-- Not for controlling mathematics -->
<!-- or table formatting             -->
<xsl:template name="ampersand-character">
    <xsl:text>&amp;</xsl:text>
</xsl:template>

<!-- Less Than -->
<xsl:template name="less-character">
    <xsl:text>&lt;</xsl:text>
</xsl:template>

<!-- Greater Than -->
<xsl:template name="greater-character">
    <xsl:text>&gt;</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template name="percent-character">
    <xsl:text>%</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<xsl:template name="dollar-character">
    <xsl:text>$</xsl:text>
</xsl:template>

<!-- Circumflex  -->
<xsl:template name="circumflex-character">
    <xsl:text>^</xsl:text>
</xsl:template>

<!-- Text underscore -->
<xsl:template name="underscore-character">
    <xsl:text>\_</xsl:text>
</xsl:template>

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template name="hash-character">
    <xsl:text>\#</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template name="tilde-character">
    <xsl:text>~</xsl:text>
</xsl:template>

<!-- Asterisk -->
<!-- Centered as a character, not an exponent -->
<xsl:template name="asterisk-character">
    <xsl:text>\*</xsl:text>
</xsl:template>

<!-- Ellipsis -->
<!-- Just three periods -->
<xsl:template name="ellipsis-character">
    <xsl:text>...</xsl:text>
</xsl:template>


<!-- Braces -->
<!-- Individually, or matched            -->
<!-- All escaped to avoid conflicts with -->
<!-- use after answer blanks, etc.       -->
<xsl:template name="lbrace-character">
    <xsl:text>\{</xsl:text>
</xsl:template>
<xsl:template name="rbrace-character">
    <xsl:text>\}</xsl:text>
</xsl:template>

<!-- Backslash -->
<xsl:template name="backslash-character">
    <xsl:text>\\</xsl:text>
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
    <xsl:variable name="asterisk-fixed"  select="str:replace($backslash-fixed, '*', '\*')"/>
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
<xsl:template match="c">
    <xsl:choose>
        <xsl:when test="contains(.,'[|') or contains(.,'|]')">
            <xsl:message>PTX:ERROR:   the strings '[|' and '|]' are not supported within verbatim text in WeBWorK problems</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[|</xsl:text>
            <xsl:value-of select="."/>
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
    <xsl:param name="b-verbose" />
    <!-- Lists are always inside a p.                                         -->
    <!-- If some text content or other elements precede the list within the p -->
    <!-- then line break to get a clean start. Otherwise do nothing; assume   -->
    <!-- whatever preceded the list gave adequate line breaks.                -->
    <xsl:if test="preceding-sibling::text()[normalize-space()] or preceding-sibling::*">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <!-- When a list ends, there may be more content before the p ends. This  -->
    <!-- content needs to be indented the proper amount when the list was a   -->
    <!-- nested list.                                                         -->
    <xsl:if test="following-sibling::text()[normalize-space()] or following-sibling::*">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
</xsl:template>

<xsl:template match="li">
    <xsl:param name="b-verbose" />
    <!-- Indent according to list depth; note this differs from potential-list-indent template. -->
    <xsl:call-template name="duplicate-string">
        <xsl:with-param name="count" select="4 * (count(ancestor::ul) + count(ancestor::ol) - 1)" />
        <xsl:with-param name="text"  select="' '" />
    </xsl:call-template>
    <xsl:choose>
        <xsl:when test="parent::ul">
            <xsl:choose>
                <xsl:when test="parent::*/@label='disc'">*</xsl:when>
                <xsl:when test="parent::*/@label='circle'">o</xsl:when>
                <xsl:when test="parent::*/@label='square'">+</xsl:when>
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
                <xsl:when test="contains(parent::*/@label,'1')">1</xsl:when>
                <xsl:when test="contains(parent::*/@label,'a')">a</xsl:when>
                <xsl:when test="contains(parent::*/@label,'A')">A</xsl:when>
                <xsl:when test="contains(parent::*/@label,'i')">i</xsl:when>
                <xsl:when test="contains(parent::*/@label,'I')">I</xsl:when>
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
                    (child::p[1]/child::*|child::p[1]/child::text())[normalize-space()][1][self::md]
                  )">
        <xsl:text>[$NBSP]*&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
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
    <xsl:param name="b-verbose" />
    <xsl:apply-templates select="*[not(self::caption)]">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="tabular">
    <!-- PTX tabular attributes top, bottom, left, right, halign are essentially passed -->
    <!-- down to cells, rather than used at the tabular level.                          -->
    <xsl:param name="b-verbose" />

    <xsl:text>[@DataTable(</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>  </xsl:text>
    </xsl:if>
    <xsl:text>[</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="row">
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:if test="$b-verbose">
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>  </xsl:text>
    </xsl:if>
    <xsl:text>],</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:variable name="table-left">
        <xsl:choose>
            <xsl:when test="@left">
                <xsl:value-of select="@left" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-right">
        <xsl:choose>
            <xsl:when test="@right">
                <xsl:value-of select="@right" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-halign">
        <xsl:choose>
            <xsl:when test="@halign">
                <xsl:value-of select="@halign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>left</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Build latex column specification                         -->
    <!--   vertical borders (left side, right side, three widths) -->
    <!--   horizontal alignment (left, center, right)             -->
    <xsl:choose>
        <xsl:when test="$b-verbose">
            <xsl:call-template name="potential-list-indent" />
            <xsl:text>  align => '</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>align=>'</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
        <!-- start with left vertical border -->
        <xsl:call-template name="pg-vrule-specification">
            <xsl:with-param name="width" select="$table-left" />
        </xsl:call-template>
        <xsl:choose>
            <!-- Potential for individual column overrides    -->
            <!--   Deduce number of columns from col elements -->
            <!--   Employ individual column overrides,        -->
            <!--   or use global table-wide values            -->
            <!--   write alignment (mandatory)                -->
            <!--   follow with right border (optional)        -->
            <xsl:when test="col">
                <xsl:for-each select="col">
                    <xsl:call-template name="halign-specification">
                        <xsl:with-param name="align">
                            <xsl:choose>
                                <xsl:when test="@halign">
                                    <xsl:value-of select="@halign" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$table-halign" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                    </xsl:call-template>
                    <xsl:call-template name="pg-vrule-specification">
                        <xsl:with-param name="width">
                            <xsl:choose>
                                <xsl:when test="@right">
                                    <xsl:value-of select="@right" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$table-right" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- No col specification                                  -->
            <!--   so default identically to global, table-wide values -->
            <!--   first row determines the  number of columns         -->
            <!--   write the alignment (mandatory)                     -->
            <!--   follow with right border (optional)                 -->
            <!-- TODO: error check each row for correct number of columns -->
            <xsl:otherwise>
                <xsl:variable name="ncols" select="count(row[1]/cell) + sum(row[1]/cell[@colspan]/@colspan) - count(row[1]/cell[@colspan])" />
                <xsl:call-template name="duplicate-string">
                    <xsl:with-param name="count" select="$ncols" />
                    <xsl:with-param name="text">
                        <xsl:call-template name="halign-specification">
                            <xsl:with-param name="align" select="$table-halign" />
                        </xsl:call-template>
                        <xsl:call-template name="pg-vrule-specification">
                            <xsl:with-param name="width" select="$table-right" />
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    <xsl:text>',</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- kill all of niceTable's column left/right border thickness in colgroup/col css; just let cellcss control border thickness -->
    <xsl:variable name="columns-css">
        <xsl:if test="col[@right] or @left">
            <xsl:if test="$b-verbose">
                <xsl:call-template name="potential-list-indent" />
                <xsl:text>    </xsl:text>
            </xsl:if>
            <xsl:text>[</xsl:text>
                <xsl:for-each select="col">
                    <xsl:text>'</xsl:text>
                    <xsl:if test="not($table-left='none') and (count(preceding-sibling::col)=0)">
                        <xsl:choose>
                            <xsl:when test="$b-verbose">
                                <xsl:text>border-left: </xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>border-left:</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:call-template name="thickness-specification">
                            <xsl:with-param name="width" select="'none'" />
                        </xsl:call-template>
                        <xsl:text>px solid;</xsl:text>
                    </xsl:if>
                    <xsl:if test="@right">
                        <xsl:choose>
                            <xsl:when test="$b-verbose">
                                <xsl:text>border-right: </xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>border-right:</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:call-template name="thickness-specification">
                            <xsl:with-param name="width" select="'none'" />
                        </xsl:call-template>
                        <xsl:text>px solid;</xsl:text>
                    </xsl:if>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:text>',</xsl:text>
                    <xsl:choose>
                        <xsl:when test="following-sibling::col">
                            <xsl:if test="$b-verbose">
                                <xsl:text>&#xa;     </xsl:text>
                                <xsl:call-template name="potential-list-indent" />
                            </xsl:if>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            <xsl:text>]</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:if test="not($columns-css='')">
        <xsl:choose>
            <xsl:when test="$b-verbose">
                <xsl:call-template name="potential-list-indent" />
                <xsl:text>  columnscss =>&#xa;</xsl:text>
                <xsl:call-template name="potential-list-indent" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>columnscss=></xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$columns-css"/>
        <xsl:text>,</xsl:text>
        <xsl:if test="$b-verbose">
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- column specification done -->
    <xsl:if test="not(parent::table)">
        <xsl:choose>
            <xsl:when test="$b-verbose">
                <xsl:call-template name="potential-list-indent" />
                <xsl:text>  center => 0,&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>center=>0,</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- remains to apply tabular/@top and tabular/@bottom -->
    <!-- will handle these at cell level -->
    <xsl:if test="$b-verbose">
        <xsl:call-template name="potential-list-indent" />
    </xsl:if>
    <xsl:text>);@]*</xsl:text>
</xsl:template>


<xsl:template match="tabular/row">
    <xsl:param name="b-verbose" />
    <xsl:if test="$b-verbose">
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>    </xsl:text>
    </xsl:if>
    <xsl:text>[</xsl:text>
    <xsl:apply-templates>
        <xsl:with-param name="b-verbose" select="$b-verbose" />
    </xsl:apply-templates>
    <xsl:if test="$b-verbose">
        <xsl:call-template name="potential-list-indent" />
        <xsl:text>    </xsl:text>
    </xsl:if>
    <xsl:text>],</xsl:text>
    <xsl:if test="$b-verbose">
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<xsl:template match="tabular/row/cell">
    <xsl:param name="b-verbose" />
    <xsl:variable name="this-cells-left-column" select="count(preceding-sibling::cell) + 1 + sum(preceding-sibling::cell[@colspan]/@colspan) - count(preceding-sibling::cell[@colspan])"/>
    <xsl:variable name="this-cells-right-column" select="$this-cells-left-column + sum(self::cell[@colspan]/@colspan) - count(self::cell[@colspan]/@colspan)"/>

    <!-- $halign below is a full LaTeX tabular argument for one cell, with perhaps more info than just alignment -->
    <xsl:variable name="halign">
        <xsl:if test="@colspan or @halign or @right or parent::row/@halign or (parent::row/@left and (count(preceding-sibling::cell)=0))">
            <xsl:if test="(count(preceding-sibling::cell) = 0) and (parent::row/@left or ancestor::tabular/@left)">
                <xsl:choose>
                    <xsl:when test="parent::row/@left">
                        <xsl:call-template name="pg-vrule-specification">
                            <xsl:with-param name="width" select="parent::row/@left" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="ancestor::tabular/@left">
                        <xsl:call-template name="pg-vrule-specification">
                            <xsl:with-param name="width" select="ancestor::tabular/@left" />
                        </xsl:call-template>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
            <xsl:call-template name="halign-specification">
                <xsl:with-param name="align" >
                    <xsl:choose>
                        <xsl:when test="@halign">
                            <xsl:value-of select="@halign" />
                        </xsl:when>
                        <!-- look to the row -->
                        <xsl:when test="parent::row/@halign">
                            <xsl:value-of select="parent::row/@halign" />
                        </xsl:when>
                        <!-- look to the col -->
                        <xsl:when test="ancestor::tabular/col[$this-cells-left-column]/@halign">
                            <xsl:value-of select="ancestor::tabular/col[$this-cells-left-column]/@halign" />
                        </xsl:when>
                        <!-- look to the tabular -->
                        <xsl:when test="ancestor::tabular/@halign">
                            <xsl:value-of select="ancestor::tabular/@halign" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'left'" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test="@right">
                    <xsl:call-template name="pg-vrule-specification">
                        <xsl:with-param name="width" select="@right" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="ancestor::tabular/col[$this-cells-right-column]/@right">
                    <xsl:call-template name="pg-vrule-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/col[$this-cells-right-column]/@right" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@right">
                    <xsl:call-template name="pg-vrule-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/@right" />
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>

    <!-- bottom borders -->
    <!-- if there is a bottom border due to tabular or row, put midrule => 1 in first cell of row  -->
    <!-- to get these horizontal rules in WeBWorK tex output; always omit last row for such output -->
    <!-- additionally put rowcss with more specific thickness into first cell                      -->
    <!-- if there is a bottom border due to cell, store some css to go into cellcss later          -->
    <!-- but need to understand that cell-specific bottom borders are not implemented in TeX       -->
    <!-- output from WeBWorK itself processing the PG                                              -->
    <xsl:variable name="midrule">
        <xsl:variable name="table-bottom-width">
            <xsl:if test="ancestor::tabular/@bottom">
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="ancestor::tabular/@bottom" />
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="row-bottom-width">
            <xsl:if test="parent::row/@bottom">
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="parent::row/@bottom" />
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="parent::row/@bottom and parent::row/following-sibling::row">
                <xsl:choose>
                    <xsl:when test="$row-bottom-width &gt; 0">
                        <xsl:text>1</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>0</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="ancestor::tabular/@bottom and parent::row/following-sibling::row">
                <xsl:choose>
                    <xsl:when test="$table-bottom-width &gt; 0">
                        <xsl:text>1</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>0</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="rowcss">
        <xsl:if test="position()=1">
            <xsl:choose>
                <xsl:when test="parent::row/@bottom">
                    <xsl:text>border-bottom:</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="parent::row/@bottom" />
                    </xsl:call-template>
                    <xsl:text>px solid;</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@bottom">
                    <xsl:text>border-bottom:</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/@bottom" />
                    </xsl:call-template>
                    <xsl:text>px solid;</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="parent::row/@valign">
                    <xsl:text>vertical-align:</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="parent::row/@valign" />
                    <xsl:text>;</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@valign">
                    <xsl:text>vertical-align:</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="ancestor::tabular/@valign" />
                    <xsl:text>;</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="cell-bottom-css">
        <xsl:if test="@bottom">
            <xsl:text>border-bottom:</xsl:text>
            <xsl:if test="$b-verbose">
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:call-template name="thickness-specification">
                <xsl:with-param name="width" select="@bottom" />
            </xsl:call-template>
            <xsl:text>px solid;</xsl:text>
            <xsl:if test="$b-verbose">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:variable>

    <!-- top from tabular or col: implement in HMTL side only with string for cellcss -->
    <xsl:variable name="cell-top-css">
        <xsl:if test="count(parent::row/preceding-sibling::row) = 0">
            <xsl:choose>
                <xsl:when test="ancestor::tabular/col[$this-cells-left-column]/@top">
                    <xsl:text>border-top:</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/col[$this-cells-left-column]/@top" />
                    </xsl:call-template>
                    <xsl:text>px solid;</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@top">
                    <xsl:text>border-top:</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/@top" />
                    </xsl:call-template>
                    <xsl:text>px solid;</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>

    <!-- left from tabular or row: implement thickness in HMTL side with string for cellcss -->
    <xsl:variable name="cell-left-css">
        <xsl:if test="count(preceding-sibling::cell) = 0">
            <xsl:choose>
                <xsl:when test="parent::row/@left">
                    <xsl:text>border-left:</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="parent::row/@left" />
                    </xsl:call-template>
                    <xsl:text>px solid;</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@left">
                    <xsl:text>border-left:</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/@left" />
                    </xsl:call-template>
                    <xsl:text>px solid;</xsl:text>
                    <xsl:if test="$b-verbose">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>

    <!-- right from tabular, col, or row: implement thickness in HMTL side with string for cellcss -->
    <xsl:variable name="cell-right-css">
        <xsl:choose>
            <xsl:when test="@right">
                <xsl:text>border-right:</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="@right" />
                </xsl:call-template>
                <xsl:text>px solid;</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:when>
            <xsl:when test="ancestor::tabular/col[$this-cells-right-column]/@right">
                <xsl:text>border-right:</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="ancestor::tabular/col[$this-cells-right-column]/@right" />
                </xsl:call-template>
                <xsl:text>px solid;</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:when>
            <xsl:when test="ancestor::tabular/@right">
                <xsl:text>border-right:</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="ancestor::tabular/@right" />
                </xsl:call-template>
                <xsl:text>px solid;</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="cellcss">
        <xsl:if test="not($cell-bottom-css='') or not($cell-top-css='') or not($cell-left-css='') or not($cell-right-css='')">
            <xsl:if test="not($cell-bottom-css='')">
                <xsl:value-of select="$cell-bottom-css"/>
            </xsl:if>
            <xsl:if test="$b-verbose">
                <xsl:if test="not($cell-bottom-css='') and (not($cell-top-css='') or not($cell-left-css='') or not($cell-right-css=''))">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="potential-list-indent" />
                    <xsl:text>                  </xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:if test="not($cell-top-css='')">
                <xsl:value-of select="$cell-top-css"/>
            </xsl:if>
            <xsl:if test="$b-verbose">
                <xsl:if test="not($cell-top-css='') and (not($cell-left-css='') or not($cell-right-css=''))">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="potential-list-indent" />
                    <xsl:text>                  </xsl:text>
                </xsl:if>
            </xsl:if>

            <xsl:if test="not($cell-left-css='')">
                <xsl:value-of select="$cell-left-css"/>
            </xsl:if>
            <xsl:if test="$b-verbose">
                <xsl:if test="not($cell-left-css='') and not($cell-right-css='')">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="potential-list-indent" />
                    <xsl:text>                  </xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:if test="not($cell-right-css='')">
                <xsl:value-of select="$cell-right-css"/>
            </xsl:if>
        </xsl:if>
    </xsl:variable>

    <xsl:if test="$b-verbose">
        <xsl:choose>
            <xsl:when test="not(preceding-sibling::cell)">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="potential-list-indent" />
                <xsl:text>     </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>

    <xsl:choose>
        <xsl:when test="($halign='') and ($midrule='') and ($rowcss='') and ($cellcss='') and not(descendant::m) and not(descendant::var[@width|@form]) and not(@colspan)">
            <xsl:text>PGML('</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>'),</xsl:text>
            <xsl:if test="$b-verbose">
                <xsl:text>&#xa;</xsl:text>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[PGML('</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>'),</xsl:text>
            <xsl:if test="@colspan">
                <xsl:if test="$b-verbose">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="potential-list-indent" />
                    <xsl:text>      </xsl:text>
                </xsl:if>
                <xsl:text>colspan</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:text>=></xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:text>'</xsl:text>
                <xsl:value-of select="@colspan"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="not($halign='')">
                <xsl:if test="$b-verbose">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="potential-list-indent" />
                    <xsl:text>      </xsl:text>
                </xsl:if>
                <xsl:text>halign</xsl:text>
                <xsl:if test="$b-verbose">
                    <!-- two spaces is legacy -->
                    <xsl:text>  </xsl:text>
                </xsl:if>
                <xsl:text>=></xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:text>'</xsl:text>
                <xsl:value-of select="$halign"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="$midrule='1' and not(preceding-sibling::cell)">
                <xsl:if test="$b-verbose">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="potential-list-indent" />
                    <xsl:text>      </xsl:text>
                </xsl:if>
                <xsl:text>midrule</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:text>=></xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:text>'</xsl:text>
                <xsl:value-of select="$midrule"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="not($rowcss='')">
                <xsl:if test="$b-verbose">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="potential-list-indent" />
                    <xsl:text>      </xsl:text>
                </xsl:if>
                <xsl:text>rowcss</xsl:text>
                <xsl:if test="$b-verbose">
                    <!-- two spaces is legacy -->
                    <xsl:text>  </xsl:text>
                </xsl:if>
                <xsl:text>=></xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:text>'</xsl:text>
                <xsl:value-of select="$rowcss"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="not($cellcss='')">
                <xsl:if test="$b-verbose">
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="potential-list-indent" />
                    <xsl:text>      </xsl:text>
                </xsl:if>
                <xsl:text>cellcss</xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:text>=></xsl:text>
                <xsl:if test="$b-verbose">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:text>'</xsl:text>
                <xsl:value-of select="$cellcss"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:text>],</xsl:text>
            <xsl:if test="$b-verbose">
                <xsl:text>&#xa;</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate vertical rule width to a LaTeX vertical rule -->
<xsl:template name="pg-vrule-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>|</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>|</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>|</xsl:text>
        </xsl:when>
        <xsl:when test="$width=''"/>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: tabular left or right attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################# -->
<!-- Utility Templates -->
<!-- ################# -->

<!-- Very good for readability, very bad for base64 length -->
<xsl:template name="begin-block">
    <xsl:param name="block-title"/>
    <xsl:param name="b-verbose" />
    <xsl:if test="$b-verbose">
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