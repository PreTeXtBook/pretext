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

<!-- This file is a library of routines to convert parts of      -->
<!-- a webwork problem into PG and PGML code/markup.  It         -->
<!-- depends on utility routines in xsl/mathbook-common.xsl,     -->
<!-- such as routines to santize blocks of code.  However        -->
<!-- the present file does not import mathbook-common.xsl,       -->
<!-- nor should it, since imports will be applied                -->
<!-- out-of-order that way.                                      -->
<!--                                                             -->
<!-- Instead, a conversion to some format, say HTML, should      -->
<!-- import xsl/mathbook-html.xsl, for general HTML conversion,  -->
<!-- but this will additionally import the common file.          -->
<!-- Then the conversion file may import the present file,       -->
<!-- mathbook-webwork-pg.xsl, for its services in creating       -->
<!-- a well-formed WeBWorK problem.                              -->
<!--                                                             -->
<!-- This should change as development stabilizes and the        -->
<!-- production of the content of a PG problem should move       -->
<!-- to the common file (perhaps).                               -->

<!-- Intend output to be a PGML problem -->
<xsl:output method="text" />


<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!--  -->
<!-- Enable answer format syntax help links                       -->
<!-- Each variable has a "category", like "integer" or "formula". -->
<!-- When an answer blank is expecting a variable, use category   -->
<!-- to provide AnswerFormatHelp link.                            -->
<xsl:param name="pg.answer.form.help" select="'yes'" />

<!-- ################# -->
<!-- File Organization -->
<!-- ################# -->

<!-- The mechanics of a WeBWorK problem come first, with        -->
<!-- specific MathBook XML markup to support problem expression -->
<!--                                                            -->
<!-- The latter half of the file is the conversion of more      -->
<!-- universal MathBook XML markup to its PGML variants         -->


<!-- ################## -->
<!-- Top-Down Structure -->
<!-- ################## -->

<!-- Basic outline of a simple problem -->
<xsl:template match="webwork[child::statement]" mode="pg">
    <xsl:call-template   name="begin-problem" />
    <xsl:call-template   name="pg-macros" />
    <xsl:call-template   name="pg-header" />
    <xsl:apply-templates select="setup" />
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="hint" />
    <xsl:apply-templates select="solution" />
    <xsl:call-template   name="end-problem" />
</xsl:template>

<!-- Basic outline of a multi-stage problem  -->
<!-- Known in WeBWorK as a"scaffold" problem -->
<!-- Indicated by <stages> as children       -->
<xsl:template match="webwork[child::stage]" mode="pg">
    <xsl:call-template   name="begin-problem" />
    <xsl:call-template   name="pg-macros" />
    <xsl:call-template   name="pg-header" />
    <xsl:apply-templates select="setup" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Scaffold</xsl:with-param>
    </xsl:call-template>
    <xsl:text>Scaffold::Begin();&#xa;</xsl:text>
    <xsl:apply-templates select="stage" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>Scaffold::End();&#xa;</xsl:text>
    <xsl:call-template   name="end-problem" />
</xsl:template>

<xsl:template match="webwork/setup">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">PG Setup</xsl:with-param>
    </xsl:call-template>
    <!-- DTD does not allow multiple "setup," is this right? -->
    <xsl:if test="not(preceding-sibling::setup) and not(contains(./pg-code,'Context('))">
        <xsl:text>Context('Numeric');&#xa;</xsl:text>
    </xsl:if>
    <!-- pg-code verbatim, but trim indentation -->
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="pg-code" />
    </xsl:call-template>
</xsl:template>

<!-- A stage is part of a multi-stage problem -->
<!-- WeBWorK calls these "scaffold" problems, -->
<!-- which have "section"s                    -->
<xsl:template match="webwork/stage">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Section</xsl:with-param>
    </xsl:call-template>
    <xsl:text>Section::Begin("</xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:text>");&#xa;</xsl:text>
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="hint" />
    <xsl:apply-templates select="solution" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>Section::End();&#xa;</xsl:text>
</xsl:template>

<!-- default template, for complete presentation -->
<xsl:template match="webwork/stage/statement|webwork/statement">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Body</xsl:with-param>
    </xsl:call-template>
    <xsl:text>BEGIN_PGML&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_PGML&#xa;</xsl:text>
</xsl:template>

<!-- default template, for solution -->
<xsl:template match="webwork/stage/solution|webwork/solution">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Solution</xsl:with-param>
    </xsl:call-template>
    <xsl:text>BEGIN_PGML_SOLUTION&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_PGML_SOLUTION&#xa;</xsl:text>
</xsl:template>

<!-- default template, for hint -->
<xsl:template match="webwork/stage/hint|webwork/hint">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Hint</xsl:with-param>
    </xsl:call-template>
    <xsl:text>#Set value of $showHint in PGcourse.pl for course-wide attempt threshhold for revealing hints&#xa;</xsl:text>
    <xsl:text>BEGIN_PGML_HINT&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_PGML_HINT&#xa;</xsl:text>
</xsl:template>

<!-- ############################## -->
<!-- Problem Header/Initializations -->
<!-- ############################## -->

<!-- Includes file header blurb promoting MBX -->
<xsl:template name="begin-problem">
    <xsl:call-template name="converter-blurb-webwork" />
    <xsl:call-template name="webwork-metadata" />
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
</xsl:template>

<!-- Mine various parts of the surrounding text -->
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
        <xsl:choose>
            <xsl:when test="/mathbook/book">
                <xsl:apply-templates select="/mathbook/book" mode="title-full" />
            </xsl:when>
            <xsl:when test="/mathbook/article">
                <xsl:apply-templates select="/mathbook/article" mode="title-full" />
            </xsl:when>
        </xsl:choose>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## EditionText1(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## AuthorText1(</xsl:text>
        <xsl:choose>
            <xsl:when test="/mathbook/book">
                <xsl:for-each select="/mathbook/book/frontmatter/titlepage/author">
                    <xsl:value-of select="personname"/>
                    <xsl:if test="not(position()=last())">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="/mathbook/article">
                <xsl:for-each select="/mathbook/article/frontmatter/titlepage/author">
                    <xsl:value-of select="personname"/>
                    <xsl:if test="not(position()=last())">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
        </xsl:choose>
    <xsl:text>)&#xa;</xsl:text>
    <!-- needs structural enclosure inline v. sectional          -->
    <!-- do not use structure number, makes overrides impossible -->
    <xsl:text>## Section1(not reported</xsl:text>
        <!-- <xsl:apply-templates select="ancestor::exercise" mode="structure-number" /> -->
    <xsl:text>)&#xa;</xsl:text>
    <!-- WW problem is always enclosed directly by an MBX exercise -->
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

<!-- Includes (localized) PG "COMMENT" promoting MBX -->
<xsl:template name="pg-header">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Header</xsl:with-param>
    </xsl:call-template>
    <xsl:text>COMMENT('</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'authored'" />
    </xsl:call-template>
    <xsl:text> MathBook XML');&#xa;</xsl:text>
    <xsl:text>TEXT(beginproblem());&#xa;</xsl:text>
</xsl:template>

<!-- ############## -->
<!-- Problem Ending -->
<!-- ############## -->

<xsl:template name="end-problem">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">End Problem</xsl:with-param>
    </xsl:call-template>
    <xsl:text>ENDDOCUMENT();&#xa;</xsl:text>
</xsl:template>

<!-- ############## -->
<!-- Load PG Macros -->
<!-- ############## -->

<!-- call exactly once,        -->
<!-- context is "webwork" root -->
<xsl:template name="pg-macros">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="block-title">Load Macros</xsl:with-param>
    </xsl:call-template>
    <!-- three standard macros always, order and placement is critical -->
    <xsl:variable name="standard-macros">
        <xsl:text>  "PGstandard.pl",&#xa;</xsl:text>
        <xsl:text>  "MathObjects.pl",&#xa;</xsl:text>
        <xsl:text>  "PGML.pl",&#xa;</xsl:text>
    </xsl:variable>
    <!-- accumulate macros evidenced by some aspect of problem design      -->
    <!-- for details on what each macro file provides, see their source at -->
    <!-- https://github.com/openwebwork/pg/tree/master/macros              -->
    <!-- or                                                                -->
    <!-- https://github.com/openwebwork/webwork-open-problem-library/tree/master/OpenProblemLibrary/macros -->
    <xsl:variable name="implied-macros">
        <!-- tables -->
        <xsl:if test=".//tabular">
            <xsl:text>  "niceTables.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- bizarro arithmetic technique for assesing answer form -->
        <xsl:if test="contains(./setup/pg-code,'bizarro')">
            <xsl:text>  "bizarroArithmetic.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- multistage problems ("scaffolded") -->
        <xsl:if test=".//stage">
            <xsl:text>  "scaffold.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- links to syntax help following answer blanks -->
        <xsl:if test="$pg.answer.form.help = 'yes'">
            <xsl:text>  "AnswerFormatHelp.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- targeted feedback messages for specific wrong answers -->
        <xsl:if test="contains(./setup/pg-code,'AnswerHints')">
            <xsl:text>  "answerHints.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- checkboxes multiple choice answers or the very useful NchooseK function-->
        <xsl:if test=".//var[@form='checkboxes'] or contains(./setup/pg-code,'NchooseK')">
            <xsl:text>  "PGchoicemacros.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- essay answers -->
        <xsl:if test=".//var[@form='essay']">
            <xsl:text>  "PGessaymacros.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- when there is a PGgraphmacros graph -->
        <xsl:if test=".//image[@pg-name]">
            <xsl:text>  "PGgraphmacros.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- ################### -->
        <!-- Parser Enhancements -->
        <!-- ################### -->
        <!-- popup menu multiple choice answers -->
        <xsl:if test=".//var[@form='popup']">
            <xsl:text>  "parserPopUp.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- radio buttons multiple choice answers -->
        <xsl:if test=".//var[@form='buttons']">
            <xsl:text>  "parserRadioButtons.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- "assignment" answers, like "y=x+1", "f(x)=x+1" -->
        <xsl:if test="contains(./setup/pg-code,'parser::Assignment')">
            <xsl:text>  "parserAssignment.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- allow "f(x)" as part of answers -->
        <xsl:if test="contains(./setup/pg-code,'parserFunction')">
            <xsl:text>  "parserFunction.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- numbers with units -->
        <xsl:if test="contains(./setup/pg-code,'NumberWithUnits')">
            <xsl:text>  "parserNumberWithUnits.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- formulas with units -->
        <xsl:if test="contains(./setup/pg-code,'FormulaWithUnits')">
            <xsl:text>  "parserFormulaWithUnits.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- implicit planes, e.g. x+2y=3z+1 -->
        <xsl:if test="contains(./setup/pg-code,'ImplicitPlane')">
            <xsl:text>  "parserImplicitPlane.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- implicit equations, e.g. x^2+sin(x+y)=5 -->
        <xsl:if test="contains(./setup/pg-code,'ImplicitEquation')">
            <xsl:text>  "parserImplicitEquation.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- for questions where multiple answer blanks work in conjunction  -->
        <xsl:if test="contains(./setup/pg-code,'MultiAnswer')">
            <xsl:text>  "parserMultiAnswer.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- for questions where any one of a finite list of answers is allowable  -->
        <xsl:if test="contains(./setup/pg-code,'OneOf')">
            <xsl:text>  "parserOneOf.pl",&#xa;</xsl:text>
        </xsl:if>
        <!-- #################### -->
        <!-- Math Object contexts -->
        <!-- #################### -->
        <xsl:if test="contains(./setup/pg-code,'Fraction')">
            <xsl:text>  "contextFraction.pl",&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'PiecewiseFunction')">
            <xsl:text>  "contextPiecewiseFunction.pl",&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'Ordering')">
            <xsl:text>  "contextOrdering.pl",&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'InequalitySetBuilder')">
            <xsl:text>  "contextInequalitySetBuilder.pl",&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'Inequalities')">
            <xsl:text>  "contextInequalities.pl",&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="contains(./setup/pg-code,'LimitedRadical')">
            <xsl:text>  "contextLimitedRadical.pl",&#xa;</xsl:text>
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
                    <xsl:message>MBX:WARNING: the WeBWorK PG macro <xsl:value-of select="."/> is always included for every problem</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:when test="contains($implied-macros, $fenced-macro)">
                    <xsl:message>MBX:WARNING: the WeBWorK PG macro <xsl:value-of select="."/> is implied by the problem construction and already included</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>  </xsl:text>
                    <xsl:value-of select="$fenced-macro" />
                    <xsl:text>,&#xa;</xsl:text>
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
                <xsl:message>MBX:WARNING: the WeBWorK PG macro PGcourse.pl is always included for every problem</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>  </xsl:text>
                <xsl:value-of select="$fenced-macro" />
                <xsl:text>,&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- put them together with a wrapper -->
    <xsl:text>loadMacros(&#xa;</xsl:text>
    <xsl:value-of select="$standard-macros" />
    <xsl:value-of select="$implied-macros" />
    <xsl:value-of select="$user-macros" />
    <xsl:value-of select="$course-macro" />
    <xsl:text>);&#xa;</xsl:text>
    <!-- if images are used, explicitly refresh or stale images will be used in HTML -->
    <xsl:if test=".//image[@pg-name]">
        <xsl:text>$refreshCachedImages= 1;</xsl:text>
    </xsl:if>
    <!-- shorten name of PGML::Format to save characters for base64 url -->
    <!-- only used within table cells                                  -->
    <xsl:if test=".//tabular">
        <xsl:text>sub PF {PGML::Format(@_)};&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- ############## -->
<!-- PERL Variables -->
<!-- ############## -->

<!-- PGML markup for Perl variable in LaTeX expression -->
<xsl:template match="webwork//statement//var|webwork//hint//var|webwork//solution//var">
    <xsl:apply-templates select="." mode="static-warning" />
    <xsl:variable name="varname" select="@name" />
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:text>[</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:if test="$problem/statement//var[@name=$varname and @form='checkboxes']">
        <xsl:text>->correct_ans()</xsl:text>
    </xsl:if>
    <xsl:text>]</xsl:text>
</xsl:template>

<xsl:template match="webwork//description//var">
    <xsl:apply-templates select="." mode="static-warning" />
    <xsl:value-of select="@name"/>
</xsl:template>

<xsl:template match="webwork//var" mode="static-warning">
    <xsl:variable name="varname" select="@name" />
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:if test="substring($varname,1,1)='$' and not($problem/setup/var[@name=$varname]/static) and not($problem/setup/var[@name=$varname]/set/member) and not(@form='essay')">
        <xsl:message>
            <xsl:text>MBX:WARNING: A WeBWorK exercise uses a var (name="</xsl:text>
            <xsl:value-of select="$varname"/>
            <xsl:text>") for which there is no static value or set declared</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>


<!-- ############ -->
<!-- PGML answers -->
<!-- ############ -->

<!-- PGML answer input               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="webwork//statement//var[@width|@form]">
    <xsl:apply-templates select="." mode="static-warning" />
    <xsl:apply-templates select="." mode="field"/>
    <xsl:apply-templates select="." mode="form-help"/>
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:variable name="varname" select="@name" />
</xsl:template>

<!-- MathObject answers -->
<!-- with variant for MathObjects like Matrix, Vector, ColumnVector      -->
<!-- where the shape of the MathObject guides the array of answer blanks -->
<xsl:template match="webwork//var[@width|@form]" mode="field">
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
    <xsl:if test="(count(preceding-sibling::*)+count(preceding-sibling::text()))=0 and parent::p/parent::statement">
        <xsl:text>    </xsl:text>
    </xsl:if>
    <xsl:text>[</xsl:text>
    <!-- for small width, print underscores; otherwise, specify by number -->
    <xsl:choose>
        <xsl:when test="$width &lt; 13">
            <xsl:call-template name="duplicate-string">
                <xsl:with-param name="count" select="$width" />
                <xsl:with-param name="text"  select="'_'" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>__</xsl:text> <!-- width specified after evaluator -->
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>]</xsl:text>
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
    <xsl:if test="$width &gt; 12">
        <xsl:text>{width => </xsl:text>
        <xsl:value-of select="$width"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Checkbox answers -->
<!-- TODO: not really supported yet. The checkbox handling in WeBWorK is technically broken. -->
<!-- The issue is only surfacing when trying to do a checkbox problem from an iframe. Any    -->
<!-- attempt to check multiple boxes and submit leads to only one box being seen as checked  -->
<!-- by WeBWorK 2                                                                            --> 
<xsl:template match="webwork//var[@form='checkboxes']" mode="field">
    <xsl:text>    [@</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>->print_a() @]*&#xa;END_PGML&#xa;ANS(checkbox_cmp(</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>->correct_ans()));&#xa;BEGIN_PGML&#xa;</xsl:text>
</xsl:template>

<!-- Essay answers -->
<!-- Example: [@ ANS(essay_cmp); essay_box(6,76) @]*   -->
<!-- Requires:  PGessaymacros.pl, automatically loaded -->
<!-- http://webwork.maa.org/moodle/mod/forum/discuss.php?d=3370 -->
<xsl:template match="webwork//var[@form='essay']" mode="field">
    <xsl:text>[@ ANS(essay_cmp); essay_box(</xsl:text>
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
    <xsl:text>) @]*</xsl:text>
</xsl:template>

<xsl:template match="webwork//var[@width]|var[@form]" mode="form-help">
    <xsl:variable name="varname" select="@name" />
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:variable name="category" select="$problem/setup/var[@name=$varname]/@category" />
    <xsl:variable name="form">
        <xsl:choose>
            <xsl:when test="@form">
                <xsl:value-of select="@form"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="category-to-form">
                    <xsl:with-param name="category" select="$category"/>
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
        <xsl:when test="$category='interval'">
            <xsl:text>intervals</xsl:text>
        </xsl:when>
        <xsl:when test="$category='logarithm'">
            <xsl:text>logarithms</xsl:text>
        </xsl:when>
        <xsl:when test="$category='limit'">
            <xsl:text>limits</xsl:text>
        </xsl:when>
        <xsl:when test="$category='number' or $category='integer'">
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

<xsl:template match="webwork//image[@pg-name]">
    <xsl:text>[@ image(insertGraph(</xsl:text>
    <xsl:value-of select="@pg-name"/>
    <xsl:text>), width=&gt;</xsl:text>
    <xsl:choose>
        <xsl:when test="@width">
            <xsl:value-of select="@width"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>400</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, height=&gt;</xsl:text>
    <xsl:choose>
        <xsl:when test="@height">
            <xsl:value-of select="@height"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>400</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, tex_size=&gt;</xsl:text>
    <xsl:choose>
        <xsl:when test="@tex_size">
            <xsl:value-of select="@tex_size"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>800</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="description">
        <xsl:text>, extra_html_tags=&gt;qq!alt="</xsl:text>
        <xsl:apply-templates select="description" mode="pg" />
        <xsl:text>"!</xsl:text>
    </xsl:if>
    <xsl:text>)@]* </xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- We need to override the HTML template that  -->
<!-- puts the description into an "alt" tag -->
<xsl:template match="webwork//description" mode="pg">
    <xsl:apply-templates />
</xsl:template>



<!-- ############################# -->
<!-- ############################# -->
<!-- MathBook XML Markup into PGML -->
<!-- ############################# -->
<!-- ############################# -->


<!-- ########## -->
<!-- Paragraphs -->
<!-- ########## -->

<!-- In PGML, paragraph breaks are just blank lines -->
<!-- End as normal with a line feed, then           -->
<!-- issue a blank line to signify the break        -->
<!-- If p is inside a list, special handling        -->
<xsl:template match="webwork//p">
    <xsl:if test="preceding-sibling::p">
        <xsl:call-template name="duplicate-string">
            <xsl:with-param name="count" select="4 * (count(ancestor::ul) + count(ancestor::ol))" />
            <xsl:with-param name="text"  select="' '" />
        </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates />
    <xsl:if test="parent::li and not(../following-sibling::li) and not(../following::*[1][self::li])">
        <xsl:text>   </xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- This construction in not valid MBX, can we do better? -->
<!-- TODO: add an error message?, terminate?               -->
<xsl:template match="webwork//p[@halign='center']">
    <xsl:text>&gt;&gt; </xsl:text>
    <xsl:apply-templates />
    <xsl:text>&lt;&lt;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ######### -->
<!-- Numbering -->
<!-- ######### -->

<!-- The cross-reference numbering scheme uses \ref, \hyperref -->
<!-- for LaTeX and numbers elsewhere, so it is unimplmented in -->
<!-- mathbook-common.xsl, hence we implement it here           -->

<xsl:template match="webwork//*" mode="xref-number">
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- In common template, but have to point -->
<!-- to it since it is a modal template    -->
<xsl:template match="webwork//exercisegroup" mode="xref-number">
    <xsl:apply-imports />
</xsl:template>

<!-- ######### -->
<!-- PGML Math -->
<!-- ######### -->

<!-- PGML inline math uses its own delimiters  -->
<!-- NB: we allow the "var" element as a child -->
<xsl:template match= "webwork//m">
    <xsl:text>[`</xsl:text>
    <xsl:call-template name="select-latex-macros"/>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>`]</xsl:text>
</xsl:template>

<xsl:template match="webwork//me">
    <xsl:text>&#xa;&#xa;>> [``</xsl:text>
    <xsl:call-template name="select-latex-macros"/>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>``] &lt;&lt;&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="webwork//md">
    <xsl:text>&#xa;&#xa;&gt;&gt; </xsl:text>
    <xsl:choose>
        <xsl:when test="contains(., '&amp;') or contains(., '\amp')">
            <xsl:text>[``</xsl:text>
            <xsl:call-template name="select-latex-macros"/>
            <xsl:text>\begin{aligned}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow" />
            <xsl:text>\end{aligned}``]</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[``</xsl:text>
            <xsl:call-template name="select-latex-macros"/>
            <xsl:text>\begin{gathered}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow" />
            <xsl:text>\end{gathered}``]</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text> &lt;&lt;&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="webwork//md/mrow">
    <xsl:apply-templates select="text()|var" />
    <xsl:if test="position()!=last()">
       <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- This template assumes each LaTeX macro is entirely on its own line  -->
<!-- And assumes they are defined with a \newcommand (not \renewcommand) -->
<!-- It only outputs LaTeX macro definitions that are explicitly used,   -->
<!-- so if they are chained, then precursors will be missed              -->
<!-- Macros are jammed together, but maybe needs protection, like {}     -->
<!-- The $latex-macros sanitized list assumes  mathbook-common.xsl  used -->
<!-- TODO: This named template examines the current context              -->
<!-- (see . in contains() below), so should be a match template          -->
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

<!-- ############## -->
<!-- Various Markup -->
<!-- ############## -->

<xsl:template match="webwork//url">
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
<xsl:template match="webwork//cell/line">
    <xsl:apply-templates />
    <xsl:text>  &#xa;</xsl:text>
</xsl:template>

<!-- Emphasis: underscores produce italic -->
<!-- Foreign:  for phrases                -->
<xsl:template match="webwork//em|webwork//foreign">
    <xsl:text>_</xsl:text>
    <xsl:apply-templates />
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Booktitle: slanted normally, we italic here-->
<xsl:template match="webwork//booktitle">
    <xsl:text>_</xsl:text>
    <xsl:apply-templates />
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Alert: asterik-underscore produces bold-italic -->
<xsl:template match="webwork//alert">
    <xsl:text>*_</xsl:text>
    <xsl:apply-templates />
    <xsl:text>_*</xsl:text>
</xsl:template>

<!-- LaTeX logo  -->
<xsl:template match="webwork//latex">
    <xsl:text>[@MODES(HTML =&gt; '\(\mathrm\LaTeX\)', TeX =&gt; '\LaTeX')@]*</xsl:text>
</xsl:template>

<!-- Quotes, double or single -->
<!-- PGML will do the right thing with "dumb" quotes          -->
<!-- in the source, so we implement these to allow for        -->
<!-- direct/easy cut/paste to/from other MathBook XML sources -->
<xsl:template match="webwork//q">
    <xsl:text>"</xsl:text>
    <xsl:apply-templates />
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template match="webwork//sq">
    <xsl:text>'</xsl:text>
    <xsl:apply-templates />
    <xsl:text>'</xsl:text>
</xsl:template>

<!-- Sometimes you need an "unbalanced" quotation make,    -->
<!-- maybe because you are crossing some other XML element -->
<!-- So here are left and right, single and double         -->
<xsl:template match="webwork//lsq">
    <xsl:text>'</xsl:text>
</xsl:template>

<xsl:template match="webwork//rsq">
    <xsl:text>'</xsl:text>
</xsl:template>

<xsl:template match="webwork//lq">
    <xsl:text>"</xsl:text>
</xsl:template>

<xsl:template match="webwork//rq">
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
<!-- implemented throughout MBX.  But for math *only*         -->
<!-- (ie LaTeX) the macros \lt, \gt are supported universally -->

<!-- Ampersand -->
<!-- Not for controlling mathematics -->
<!-- or table formatting             -->
<xsl:template match="webwork//ampersand">
    <xsl:text>\&amp;</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template match="webwork//percent">
    <xsl:text>\%</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<xsl:template match="webwork//dollar">
    <xsl:text>\$</xsl:text>
</xsl:template>

<!-- Circumflex  -->
<!-- 2015/01/28: there was a mismatch between HTML and LaTeX names -->
<xsl:template match="webwork//circum">
    <xsl:text>\^</xsl:text>
    <xsl:message>MBX:WARNING: the "circum" element is deprecated (2015/01/28), use "circumflex"</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>

<xsl:template match="webwork//circumflex">
    <xsl:text>\^</xsl:text>
</xsl:template>

<!-- Text underscore -->
<xsl:template match="webwork//underscore">
    <xsl:text>\_</xsl:text>
</xsl:template>

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template match="webwork//hash">
    <xsl:text>\#</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template match="webwork//tilde">
    <xsl:text>\~</xsl:text>
</xsl:template>

<!-- Asterisk -->
<!-- Centered as a character, not an exponent -->
<xsl:template match="webwork//asterisk">
    <xsl:text>\*</xsl:text>
</xsl:template>

<!-- Braces -->
<!-- Individually, or matched            -->
<!-- All escaped to avoid conflicts with -->
<!-- use after answer blanks, etc.       -->
<xsl:template match="webwork//lbrace">
    <xsl:text>\{</xsl:text>
</xsl:template>
<xsl:template match="webwork//rbrace">
    <xsl:text>\}</xsl:text>
</xsl:template>
<xsl:template match="webwork//braces">
    <xsl:text>\{</xsl:text>
    <xsl:apply-templates />>
    <xsl:text>\}</xsl:text>
</xsl:template>

<!-- Backslash -->
<xsl:template match="webwork//backslash">
    <xsl:text>\\</xsl:text>
</xsl:template>

<!-- Verbatim Snippets, Code -->
<xsl:template match="webwork//c">
    <xsl:choose>
        <xsl:when test="contains(.,'[|') or contains(.,'|]')">
            <xsl:message>MBX:ERROR:   the strings '[|' and '|]' are not supported within verbatim text in WeBWorK problems</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[|</xsl:text>
            <xsl:apply-templates />
            <xsl:text>|]</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Preformatted Text -->
<!-- Sanitization analyzes *all* lines for left margin         -->
<!-- "prepend-string" adds colon and three spaces to each line -->
<xsl:template match="webwork//pre">
    <xsl:call-template name="prepend-string">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="." />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- The next three are macros that will format  -->
<!-- properly for PGML realized as HTML or LaTeX -->

<!-- Nonbreaking space -->
<xsl:template match="webwork//nbsp">
    <xsl:text>[$NBSP]*</xsl:text>
</xsl:template>

<!-- En dash           -->
<xsl:template match="webwork//ndash">
    <xsl:text>[$NDASH]*</xsl:text>
</xsl:template>

<!-- Em dash           -->
<xsl:template match="webwork//mdash">
    <xsl:text>[$MDASH]*</xsl:text>
</xsl:template>

<!-- These same three characters have modal    -->
<!-- templates in  xsl/mathbook-common.xsl     -->
<!-- to allow for some generic routines        -->
<!-- (eg, xref with autoname) that only depend -->
<!-- on variants of these.  Here we recognize  -->
<!-- that we are in PG mode and supply the     -->
<!-- right representations.                    -->

<xsl:template match="webwork//*" mode="nbsp">
    <xsl:text>[$NBSP]*</xsl:text>
</xsl:template>

<xsl:template match="webwork//*" mode="ndash">
    <xsl:text>[$NDASH]*</xsl:text>
</xsl:template>

<xsl:template match="webwork//*" mode="mdash">
    <xsl:text>[$MDASH]*</xsl:text>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Implement PGML unordered lists -->
<xsl:template match="webwork//ul|webwork//ol">
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="webwork//ul/li">
    <xsl:call-template name="duplicate-string">
        <xsl:with-param name="count" select="4 * (count(ancestor::ul) + count(ancestor::ol) - 1)" />
        <xsl:with-param name="text"  select="' '" />
    </xsl:call-template>
    <xsl:choose>
        <xsl:when test="../@label='disc'">*</xsl:when>
        <xsl:when test="../@label='circle'">o</xsl:when>
        <xsl:when test="../@label='square'">+</xsl:when>
        <xsl:otherwise>-</xsl:otherwise>
    </xsl:choose>
    <xsl:text> </xsl:text>
    <xsl:apply-templates />
    <xsl:if test="not(child::p) and not(following-sibling::li) and not(following::*[1][self::li])">
        <xsl:text>   </xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="webwork//ol/li">
    <xsl:call-template name="duplicate-string">
        <xsl:with-param name="count" select="4 * (count(ancestor::ul) + count(ancestor::ol) - 1)" />
        <xsl:with-param name="text"  select="' '" />
    </xsl:call-template>
    <xsl:choose>
        <xsl:when test="contains(../@label,'1')">1</xsl:when>
        <xsl:when test="contains(../@label,'a')">a</xsl:when>
        <xsl:when test="contains(../@label,'A')">A</xsl:when>
        <xsl:when test="contains(../@label,'i')">i</xsl:when>
        <xsl:when test="contains(../@label,'I')">I</xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
    <xsl:text>.  </xsl:text>
    <xsl:apply-templates />
    <xsl:if test="not(child::p) and not(following-sibling::li) and not(following::*[1][self::li])">
        <xsl:text>   </xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ###### -->
<!-- Tables -->
<!-- ###### -->

<xsl:template match="webwork//table">
    <xsl:apply-templates select="*[not(self::caption)]" />
</xsl:template>

<xsl:template match="webwork//tabular">
    <!-- MBX tabular attributes top, bottom, left, right, halign are essentially passed -->
    <!-- down to cells, rather than used at the tabular level.                          -->
    <xsl:text>[@DataTable(&#xa;  [&#xa;</xsl:text>
    <xsl:apply-templates select="row"/>
    <xsl:text>  ],&#xa;</xsl:text>
    <xsl:if test="ancestor::table/caption">
        <xsl:text>  caption => '</xsl:text>
            <xsl:apply-templates select="parent::*" mode="type-name"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="parent::*" mode="number"/>
            <xsl:text>: </xsl:text>
            <xsl:value-of select="ancestor::table/caption"/>
        <xsl:text>',&#xa;</xsl:text>
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
    <xsl:text>  align => '</xsl:text>
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
    <xsl:text>',&#xa;</xsl:text>
    <!-- kill all of niceTable's column left/right border thickness in colgroup/col css; just let cellcss control border thickness -->
    <xsl:variable name="columns-css">
        <xsl:if test="col[@right] or @left">
            <xsl:text>    [</xsl:text>
                <xsl:for-each select="col">
                    <xsl:text>'</xsl:text>
                    <xsl:if test="not($table-left='none') and (count(preceding-sibling::col)=0)">
                        <xsl:text>border-left: </xsl:text>
                        <xsl:call-template name="thickness-specification">
                            <xsl:with-param name="width" select="'none'" />
                        </xsl:call-template>
                        <xsl:text>px solid;</xsl:text>
                    </xsl:if>
                    <xsl:if test="@right">
                        <xsl:text>border-right: </xsl:text>
                        <xsl:call-template name="thickness-specification">
                            <xsl:with-param name="width" select="'none'" />
                        </xsl:call-template>
                        <xsl:text>px solid;</xsl:text>
                    </xsl:if>
                    <xsl:text> ',</xsl:text>
                    <xsl:choose>
                        <xsl:when test="following-sibling::col">
                            <xsl:text>&#xa;     </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            <xsl:text>]</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:if test="not($columns-css='')">
        <xsl:text>  columnscss =>&#xa;</xsl:text>
        <xsl:value-of select="$columns-css"/>
        <xsl:text>,&#xa;</xsl:text>
    </xsl:if>
    <!-- column specification done -->
    <!-- remains to apply tabular/@top and tabular/@bottom -->
    <!-- will handle these at cell level -->
    <xsl:text>);@]*&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="webwork//tabular/row">
    <xsl:text>    [</xsl:text>
    <xsl:apply-templates />
    <xsl:text>    ],&#xa;</xsl:text>
</xsl:template>

<xsl:template match="webwork//tabular/row/cell">
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
                    <xsl:text>border-bottom: </xsl:text>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="parent::row/@bottom" />
                    </xsl:call-template>
                    <xsl:text>px solid; </xsl:text>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@bottom">
                    <xsl:text>border-bottom: </xsl:text>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/@bottom" />
                    </xsl:call-template>
                    <xsl:text>px solid; </xsl:text>
                </xsl:when>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="parent::row/@valign">
                    <xsl:text>vertical-align: </xsl:text>
                    <xsl:value-of select="parent::row/@valign" />
                    <xsl:text>; </xsl:text>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@valign">
                    <xsl:text>vertical-align: </xsl:text>
                    <xsl:value-of select="ancestor::tabular/@valign" />
                    <xsl:text>; </xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="cell-bottom-css">
        <xsl:if test="@bottom">
            <xsl:text>border-bottom: </xsl:text>
            <xsl:call-template name="thickness-specification">
                <xsl:with-param name="width" select="@bottom" />
            </xsl:call-template>
            <xsl:text>px solid; </xsl:text>
        </xsl:if>
    </xsl:variable>

    <!-- top from tabular or col: implement in HMTL side only with string for cellcss -->
    <xsl:variable name="cell-top-css">
        <xsl:if test="count(parent::row/preceding-sibling::row) = 0">
            <xsl:choose>
                <xsl:when test="ancestor::tabular/col[$this-cells-left-column]/@top">
                    <xsl:text>border-top: </xsl:text>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/col[$this-cells-left-column]/@top" />
                    </xsl:call-template>
                    <xsl:text>px solid; </xsl:text>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@top">
                    <xsl:text>border-top: </xsl:text>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/@top" />
                    </xsl:call-template>
                    <xsl:text>px solid; </xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>

    <!-- left from tabular or row: implement thickness in HMTL side with string for cellcss -->
    <xsl:variable name="cell-left-css">
        <xsl:if test="count(preceding-sibling::cell) = 0">
            <xsl:choose>
                <xsl:when test="parent::row/@left">
                    <xsl:text>border-left: </xsl:text>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="parent::row/@left" />
                    </xsl:call-template>
                    <xsl:text>px solid; </xsl:text>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@left">
                    <xsl:text>border-left: </xsl:text>
                    <xsl:call-template name="thickness-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/@left" />
                    </xsl:call-template>
                    <xsl:text>px solid; </xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>

    <!-- right from tabular, col, or row: implement thickness in HMTL side with string for cellcss -->
    <xsl:variable name="cell-right-css">
        <xsl:choose>
            <xsl:when test="@right">
                <xsl:text>border-right: </xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="@right" />
                </xsl:call-template>
                <xsl:text>px solid; </xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::tabular/col[$this-cells-right-column]/@right">
                <xsl:text>border-right: </xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="ancestor::tabular/col[$this-cells-right-column]/@right" />
                </xsl:call-template>
                <xsl:text>px solid; </xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::tabular/@right">
                <xsl:text>border-right: </xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="ancestor::tabular/@right" />
                </xsl:call-template>
                <xsl:text>px solid; </xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="cellcss">
        <xsl:if test="not($cell-bottom-css='') or not($cell-top-css='') or not($cell-left-css='') or not($cell-right-css='')">
            <xsl:if test="not($cell-bottom-css='')">
                <xsl:value-of select="$cell-bottom-css"/>
            </xsl:if>
            <xsl:if test="not($cell-bottom-css='') and (not($cell-top-css='') or not($cell-left-css='') or not($cell-right-css=''))">
                <xsl:text>&#xa;                  </xsl:text>
            </xsl:if>
            <xsl:if test="not($cell-top-css='')">
                <xsl:value-of select="$cell-top-css"/>
            </xsl:if>
            <xsl:if test="not($cell-top-css='') and (not($cell-left-css='') or not($cell-right-css=''))">
                <xsl:text>&#xa;                  </xsl:text>
            </xsl:if>
            <xsl:if test="not($cell-left-css='')">
                <xsl:value-of select="$cell-left-css"/>
            </xsl:if>
            <xsl:if test="not($cell-left-css='') and not($cell-right-css='')">
                <xsl:text>&#xa;                  </xsl:text>
            </xsl:if>
            <xsl:if test="not($cell-right-css='')">
                <xsl:value-of select="$cell-right-css"/>
            </xsl:if>
        </xsl:if>
    </xsl:variable>

    <xsl:choose>
        <xsl:when test="not(preceding-sibling::cell)">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>     </xsl:text>
        </xsl:otherwise>
    </xsl:choose>

    <xsl:choose>
        <xsl:when test="($halign='') and ($midrule='') and ($rowcss='') and ($cellcss='') and not(descendant::m) and not(descendant::var[@width|@form]) and not(@colspan)">
            <xsl:text>PF('</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>'),&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[PF('</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>'),</xsl:text>
            <xsl:if test="@colspan">
                <xsl:text>&#xa;      colspan => '</xsl:text>
                <xsl:value-of select="@colspan"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="not($halign='')">
                <xsl:text>&#xa;      halign  => '</xsl:text>
                <xsl:value-of select="$halign"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="$midrule='1' and not(preceding-sibling::cell)">
                <xsl:text>&#xa;      midrule => '</xsl:text>
                <xsl:value-of select="$midrule"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="not($rowcss='')">
                <xsl:text>&#xa;      rowcss  => '</xsl:text>
                <xsl:value-of select="$rowcss"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="not($cellcss='')">
                <xsl:text>&#xa;      cellcss => '</xsl:text>
                <xsl:value-of select="$cellcss"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:text>],&#xa;</xsl:text>
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
            <xsl:message>MBX:WARNING: tabular left or right attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################# -->
<!-- Utility Templates -->
<!-- ################# -->

<xsl:template name="begin-block">
    <xsl:param name="block-title"/>
    <xsl:text>&#xa;</xsl:text>
    <!-- short string of octothorpes to save on base64 url characters -->
    <xsl:text>####################&#xa;</xsl:text>
    <xsl:text># </xsl:text>
    <xsl:value-of select="$block-title"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>####################&#xa;</xsl:text>
</xsl:template>

<!-- Recursively prepend to multiple lines -->
<!-- Presumes pre-processing with line-feed at very end                      -->
<!-- Borrowed from more complicated routine in xsl/mathbook-sage-doctest.xsl -->
<!-- Generalize: pass pre-pending string at invocation and each iteration    -->
<!-- TODO: perhaps consolidate with similar routine for Sage doctesting      -->
<xsl:template name="prepend-string">
    <xsl:param name="text" />
    <!-- Quit when string becomes empty -->
    <xsl:if test="string-length($text)">
        <xsl:variable name="first-line" select="substring-before($text, '&#xA;')" />
        <xsl:text>:   </xsl:text> <!-- the string, yields PG pre-formatted -->
        <xsl:value-of select="$first-line"/>
        <xsl:text>&#xA;</xsl:text>
        <!-- recursive call on remainder of string -->
        <xsl:call-template name="prepend-string">
            <xsl:with-param name="text" select="substring-after($text, '&#xA;')"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
