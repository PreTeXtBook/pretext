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

<!-- path assumes we place  webwork-pg.xsl in mathbook "user" directory -->
<!-- <xsl:import href="../xsl/mathbook-common.xsl" /> -->

<!-- Intend output to be a PGML problem -->
<xsl:output method="text" />


<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!--  -->
<!-- Enable answer format syntax help links                       -->
<!-- Each variable has a "category", like "integer" or "formula". -->
<!-- When an answer blank is expecting a variable, use category   -->
<!-- to provide AnswerFormatHelp link.                            -->
<xsl:param name="pg.answer.format.help" select="'yes'" />


<!-- Removing whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->
<xsl:strip-space elements="li" />


<!-- ################## -->
<!-- Top-Down Structure -->
<!-- ################## -->

<!-- Basic outline of a simple problem -->
<xsl:template match="webwork">
    <xsl:call-template   name="begin-problem" />
    <xsl:call-template   name="macros" />
    <xsl:call-template   name="header" />
    <xsl:apply-templates select="setup" />
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="solution" />
    <xsl:call-template   name="end-problem" />
</xsl:template>

<!-- Basic outline of a "scaffold" problem -->
<xsl:template match="webwork[@type='scaffold']">
    <xsl:call-template   name="begin-problem" />
    <xsl:call-template   name="macros" />
    <xsl:call-template   name="header" />
    <xsl:apply-templates select="setup" />
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Scaffold</xsl:with-param>
    </xsl:call-template>
    <xsl:text>Scaffold::Begin();&#xa;</xsl:text>
    <xsl:apply-templates select="platform" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>Scaffold::End();&#xa;</xsl:text>
    <xsl:call-template   name="end-problem" />
</xsl:template>

<xsl:template match="setup">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">PG Setup</xsl:with-param>
    </xsl:call-template>
    <!-- TODO: ignore var for now -->
    <!-- pg-code verbatim, but trim indentation -->
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="pg-code" />
    </xsl:call-template>
</xsl:template>

<!-- A platform is part of a scaffold -->
<xsl:template match="platform">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Section</xsl:with-param>
    </xsl:call-template>
    <xsl:text>Section::Begin("</xsl:text>
    <xsl:apply-templates select="title" />
    <xsl:text>");&#xa;</xsl:text>
    <xsl:apply-templates select="statement" />
    <xsl:apply-templates select="solution" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>Section::End();&#xa;</xsl:text>
</xsl:template>


<!-- default template, for complete presentation -->
<!-- TODO: fix match pattern to cover scaffolded problems once name firms up -->
<xsl:template match="webwork//statement">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Body</xsl:with-param>
    </xsl:call-template>
    <xsl:text>BEGIN_PGML&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_PGML&#xa;</xsl:text>
</xsl:template>

<!-- default template, for solution -->
<!-- TODO: fix match pattern to cover scaffolded problems once name firms up -->
<xsl:template match="webwork//solution">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Solution</xsl:with-param>
    </xsl:call-template>
    <xsl:text>BEGIN_PGML_SOLUTION&#xa;</xsl:text>
    <xsl:apply-templates />
    <!-- unless we guarantee line feed, a break is needed -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>END_PGML_SOLUTION&#xa;</xsl:text>
</xsl:template>

<!-- In PGML, paragraph breaks are just blank lines -->
<!-- End as normal with a line feed, then           -->
<!-- issue a blank line to signify the break        -->
<!-- If p is inside a list, special handling        -->
<xsl:template match="webwork//p">
    <xsl:if test="preceding-sibling::p">
        <xsl:call-template name="space">
            <xsl:with-param name="blocksize" select="4"/>
            <xsl:with-param name="repetitions" select="count(ancestor::ul) + count(ancestor::ol)"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates />
    <xsl:if test="parent::li and not(../following-sibling::li) and not(../following::*[1][self::li])">
        <xsl:call-template name="space">
            <xsl:with-param name="blocksize" select="3"/>
            <xsl:with-param name="repetitions" select="1"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Implement PGML unordered lists                 -->
<xsl:template match="webwork//ul|webwork//ol">
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul/li[ancestor::webwork]">
    <xsl:call-template name="space">
        <xsl:with-param name="blocksize" select="4"/>
        <xsl:with-param name="repetitions" select="count(ancestor::ul) + count(ancestor::ol) - 1"/>
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
        <xsl:call-template name="space">
            <xsl:with-param name="blocksize" select="3"/>
            <xsl:with-param name="repetitions" select="1"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ol/li[ancestor::webwork]">
    <xsl:call-template name="space">
        <xsl:with-param name="blocksize" select="4"/>
        <xsl:with-param name="repetitions" select="count(ancestor::ul) + count(ancestor::ol) - 1"/>
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
        <xsl:call-template name="space">
            <xsl:with-param name="blocksize" select="3"/>
            <xsl:with-param name="repetitions" select="1"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- PGML markup for Perl variable in LaTeX expression -->
<xsl:template match="statement//var|solution//var">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- PGML answer blank               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="statement//answer">
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
    <xsl:text>[</xsl:text>
    <xsl:call-template name="underscore">
        <xsl:with-param name="width">
            <xsl:value-of select="$width"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>]{</xsl:text>
        <xsl:choose>
            <xsl:when test="@evaluator">
                <xsl:value-of select="@evaluator" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@var" />
            </xsl:otherwise>
        </xsl:choose>
    <xsl:text>}</xsl:text>
    <xsl:if test="$pg.answer.format.help = 'yes'">
        <xsl:variable name="category">
            <xsl:choose>
                <xsl:when test="@category">
                    <xsl:value-of select="@category"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="varname" select="@var" />
                    <xsl:variable name="problem" select="ancestor::webwork" />
                    <xsl:value-of select="$problem/setup/var[@name=$varname]/@category" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="format">
            <xsl:call-template name="category-to-format">
                <xsl:with-param name="category" select="$category"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="not($format='none')">
            <xsl:text> [@ AnswerFormatHelp("</xsl:text>
                <xsl:value-of select="$format"/>
            <xsl:text>") @]*</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- Essay answers -->
<!-- Example: [@ ANS(essay_cmp); essay_box(6,76) @]*   -->
<!-- Requires:  PGessaymacros.pl, automatically loaded -->
<!-- http://webwork.maa.org/moodle/mod/forum/discuss.php?d=3370 -->
<xsl:template match="answer[@format = 'essay']">
    <xsl:text>[@ ANS(essay_cmp); essay_box(</xsl:text>
    <xsl:choose>
        <xsl:when test="@height">
            <xsl:value-of select="@height" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>6</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>,</xsl:text>
    <xsl:choose>
        <xsl:when test="@width">
            <xsl:value-of select="@width" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>76</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>) @]*</xsl:text>
</xsl:template>

<!-- PGML inline math uses its own delimiters  -->
<!-- NB: we allow the "var" element as a child -->
<xsl:template match= "webwork//m">
    <xsl:text>[`</xsl:text>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>`]</xsl:text>
</xsl:template>

<xsl:template match="webwork//me">
    <xsl:text>&#xa;&#xa;&gt;&gt; [``</xsl:text>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>``] &lt;&lt;&#xa;&#xa;</xsl:text>
</xsl:template>


<!-- re-activate, since MBX kills all titles -->
<xsl:template match="webwork//title">
    <xsl:apply-templates />
</xsl:template>


<!-- Unimplemented, currently killed -->
<xsl:template match="webwork//hint" />


<!-- ####################### -->
<!-- Static, Named Templates -->
<!-- ####################### -->

<!-- Includes file header blurb promoting MBX -->
<xsl:template name="begin-problem">
    <xsl:call-template name="converter-blurb-perl" />
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
</xsl:template>

<!-- Includes (localized) PG "COMMENT" promoting MBX -->
<xsl:template name="header">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Header</xsl:with-param>
    </xsl:call-template>
    <xsl:text>COMMENT('</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'authored'" />
    </xsl:call-template>
    <xsl:text> MathBook XML');&#xa;</xsl:text>
    <xsl:text>TEXT(beginproblem());&#xa;</xsl:text>
</xsl:template>

<!-- We kill default processing of "macros" and use       -->
<!-- a named template.  This allows for there to be no    -->
<!-- "macros" element if no additional macros are needed. -->
<!-- Calling context is "webwork" problem-root            -->
<!-- Call from "webwork" context                          -->
<!-- http://stackoverflow.com/questions/9936762/xslt-pass-current-context-in-call-template -->
<xsl:template match="macros" />

<xsl:template name="macros">
    <!-- three standard macro files, order and placement is critical -->
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">Load Macros</xsl:with-param>
    </xsl:call-template>
    <xsl:text>loadMacros(&#xa;</xsl:text>
    <xsl:text>    "PGstandard.pl",&#xa;</xsl:text>
    <xsl:text>    "MathObjects.pl",&#xa;</xsl:text>
    <xsl:text>    "PGML.pl",&#xa;</xsl:text>
    <!-- look for other macros to use automatically                  -->
    <!-- popup menu multiple choice answers                          -->
    <xsl:if test="./setup/var[@category='popup']">
        <xsl:text>    "parserPopUp.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- radio buttons multiple choice answers                       -->
    <xsl:if test="./setup/var[@category='buttons']">
        <xsl:text>    "parserRadioButtons.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- essay answers, no var in setup, just answer                 -->
    <xsl:if test="./statement//answer[@format='essay']">
        <xsl:text>    "PGessaymacros.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- scaffolded problems -->
    <xsl:if test="@type='scaffold'">
        <xsl:text>    "scaffold.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- links to syntax help following answer blanks                -->
    <xsl:if test="($pg.answer.format.help = 'yes')">
        <xsl:text>    "AnswerFormatHelp.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- targeted feedback messages for specific wrong answers       -->
    <xsl:if test="contains(./setup/pg-code,'AnswerHints')">
        <xsl:text>    "answerHints.pl",&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="macros/macro" />
    <xsl:text>    "PGcourse.pl",&#xa;</xsl:text>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- NB: final trailing comma controlled by "PGcourse.pl" -->
<xsl:template match="macro">
    <xsl:text>    "</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>",&#xa;</xsl:text>
</xsl:template>

<xsl:template name="end-problem">
    <xsl:call-template name="begin-block">
        <xsl:with-param name="title">End Problem</xsl:with-param>
    </xsl:call-template>
    <xsl:text>ENDDOCUMENT();&#xa;</xsl:text>
</xsl:template>

<xsl:template name="begin-block">
    <xsl:param name="title"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>############################################################&#xa;</xsl:text>
    <xsl:text># </xsl:text>
    <xsl:value-of select="$title"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>############################################################&#xa;</xsl:text>
</xsl:template>

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

<!-- PGML relies on sequences of space characters for markup -->
<xsl:template name="space">
    <xsl:param name="blocksize" select="4" />
    <xsl:param name="repetitions" select="1" />
    <xsl:param name="width" select="$blocksize * $repetitions" />
    <xsl:if test="not($width = 0)">
        <xsl:text> </xsl:text>
        <xsl:call-template name="space">
            <xsl:with-param name="width" select="$width - 1" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>



<!-- Convert a var's "category" to the right term for AnswerFormatHelp -->
<xsl:template name="category-to-format">
    <xsl:param name="category"/>
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


<!-- ###### -->
<!-- Markup -->
<!-- ###### -->

<!-- Convenience: kern, etc. into LaTeX, HTML versions -->
<xsl:template match="wbwk">
    <xsl:text>WeBWorK</xsl:text>
</xsl:template>

<!-- Convenience: understood by MathJax and LaTeX -->
<xsl:template match="webwork//latex">
    <xsl:text>[`\LaTeX`]</xsl:text>
</xsl:template>

<!-- http://webwork.maa.org/wiki/Introduction_to_PGML#Basic_Formatting -->

<!-- two spaces at line-end is a newline -->
<xsl:template match="webwork//br">
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
<!-- "sanitize-text-output" analyzes *all* lines for left margin -->
<!-- "prepend-string" adds colon and three spaces to each line   -->
<xsl:template match="webwork//pre">
    <xsl:call-template name="prepend-string">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-text-output">
                <xsl:with-param name="text" select="." />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Recursively prepend to multiple lines -->
<!-- Presumes pre-processing with line-feed at very end                      -->
<!-- Borrowed from more complicated routine in xsl/mathbook-sage-doctest.xsl -->
<!-- Generalize: pass pre-pending string at invocation and each iteration    -->
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


<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

</xsl:stylesheet>
