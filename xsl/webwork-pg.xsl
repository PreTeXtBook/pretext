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
<!-- webwork-pg.xsl, for its services in creating a well-formed  -->
<!-- WeBWorK problem.                                            -->
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
    <xsl:if test="not(preceding-sibling::setup) and not(contains(./pg-code,'Context('))">
        <xsl:text>Context('Numeric');&#xa;</xsl:text>
    </xsl:if>
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

<xsl:template match="webwork//p[@halign='center']">
    <xsl:text>&gt;&gt; </xsl:text>
    <xsl:apply-templates />
    <xsl:text>&lt;&lt;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

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


<!-- Implement PGML unordered lists                 -->
<xsl:template match="webwork//ul|webwork//ol">
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul/li[ancestor::webwork]">
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

<xsl:template match="ol/li[ancestor::webwork]">
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

<!-- Tables                                            -->
<xsl:template match="webwork//table">
    <xsl:apply-templates select="*[not(self::caption)]" />
</xsl:template>

<xsl:template match="webwork//tabular">
    <!-- All cell entries must be encased in double quotes. But math and answer blanks require PGML::Format  -->
    <!-- which must be outside of quotes. So PGML::Format gets surrounding quotes. But this can lead to      -->
    <!-- "".PGML::Format(...)."" and the empty strings are not liked by PGML. So create $EmPtYsTrInG to use  -->
    <xsl:if test="descendant::m or descendant::answer">
        <xsl:text>[@$EmPtYsTrInG = '';@]&#xa;</xsl:text>
    </xsl:if>
    <!-- MBX tabular attributes top, bottom, left, right, halign are essentially passed -->
    <!-- down to cells, rather than used at the tabular level.                          -->
    <xsl:text>[@DataTable(&#xa;  [&#xa;</xsl:text>
    <xsl:apply-templates select="row"/>
    <xsl:text>  ],&#xa;</xsl:text>
    <xsl:if test="ancestor::table/caption">
        <xsl:text>  caption   => '</xsl:text>
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
    <xsl:text>  align     => '</xsl:text>
        <!-- start with left vertical border -->
        <xsl:call-template name="vrule-specification">
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
                    <xsl:call-template name="vrule-specification">
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
                        <xsl:call-template name="vrule-specification">
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
            <xsl:text>[</xsl:text>
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
                            <xsl:text>&#xa;                 </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            <xsl:text>]</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:if test="not($columns-css='')">
        <xsl:text>  columnscss => </xsl:text>
        <xsl:value-of select="$columns-css"/>
        <xsl:text>,&#xa;</xsl:text>
    </xsl:if>
    <!-- column specification done -->
    <!-- remains to apply tabular/@top and tabular/@bottom -->
    <!-- will handle these at cell level -->
    <xsl:text>);@]*&#xa;&#xa;</xsl:text>
    <xsl:if test=".//col/@top">
        <xsl:message>MBX:WARNING: column-specific top border attributes are not implemented for the hardcopy output of a WeBWorK PG table</xsl:message>
    </xsl:if>
    <xsl:if test=".//cell/@bottom">
        <xsl:message>MBX:WARNING: cell-specific bottom border attributes are not implemented for the hardcopy output of a WeBWorK PG table</xsl:message>
    </xsl:if>
    <xsl:if test=".//*[@top='medium'] or .//*[@top='major'] or .//*[@bottom='medium'] or .//*[@bottom='major'] or .//*[@left='medium'] or .//*[@left='major'] or .//*[@right='medium'] or .//*[@right='major']">
        <xsl:message>MBX:WARNING: medium and major will come out as minor in the hardcopy output of a WeBWorK PG table</xsl:message>
    </xsl:if>
</xsl:template>


<xsl:template match="webwork//tabular/row">
    <xsl:text>    [</xsl:text>
    <xsl:apply-templates />
    <xsl:text>    ],&#xa;</xsl:text>
</xsl:template>

<xsl:template match="webwork//tabular/row/cell">
    <xsl:variable name="this-cells-left-column" select="count(preceding-sibling::cell) + 1 + sum(preceding-sibling::cell[@colspan]/@colspan) - count(preceding-sibling::cell[@colspan])"/>
    <xsl:variable name="this-cells-right-column" select="$this-cells-left-column + @colspan - 1"/>
    <!-- $halign below is a full LaTeX tabular argument for one cell, with perhaps more info than just alignment -->
    <xsl:variable name="halign">
        <xsl:if test="@colspan or @halign or @right or parent::row/@halign or (parent::row/@left and (count(preceding-sibling::cell)=0))">
            <xsl:if test="(count(preceding-sibling::cell) = 0) and (parent::row/@left or ancestor::tabular/@left)">
                <xsl:choose>
                    <xsl:when test="parent::row/@left">
                        <xsl:call-template name="vrule-specification">
                            <xsl:with-param name="width" select="parent::row/@left" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="ancestor::tabular/@left">
                        <xsl:call-template name="vrule-specification">
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
                    <xsl:call-template name="vrule-specification">
                        <xsl:with-param name="width" select="@right" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="ancestor::tabular/col[$this-cells-right-column]/@right">
                    <xsl:call-template name="vrule-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/col[$this-cells-right-column]/@right" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="ancestor::tabular/@right">
                    <xsl:call-template name="vrule-specification">
                        <xsl:with-param name="width" select="ancestor::tabular/@right" />
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>

    <!-- bottom borders                                                                            -->
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
        <xsl:choose>
            <xsl:when test="parent::row/@bottom">
                <xsl:text>border-bottom: </xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="parent::row/@bottom" />
                </xsl:call-template>
                <xsl:text>px solid;</xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::tabular/@bottom">
                <xsl:text>border-bottom: </xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="ancestor::tabular/@bottom" />
                </xsl:call-template>
                <xsl:text>px solid;</xsl:text>
            </xsl:when>
        </xsl:choose>
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
                <xsl:text>&#xa;                   </xsl:text>
            </xsl:if>
            <xsl:if test="not($cell-top-css='')">
                <xsl:value-of select="$cell-top-css"/>
            </xsl:if>
            <xsl:if test="not($cell-top-css='') and (not($cell-left-css='') or not($cell-right-css=''))">
                <xsl:text>&#xa;                   </xsl:text>
            </xsl:if>
            <xsl:if test="not($cell-left-css='')">
                <xsl:value-of select="$cell-left-css"/>
            </xsl:if>
            <xsl:if test="not($cell-left-css='') and not($cell-right-css='')">
                <xsl:text>&#xa;                   </xsl:text>
            </xsl:if>
            <xsl:if test="not($cell-right-css='')">
                <xsl:value-of select="$cell-right-css"/>
            </xsl:if>
        </xsl:if>
    </xsl:variable>

    <xsl:choose>
        <xsl:when test="not(preceding-sibling::cell)">
            <xsl:text> </xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>      </xsl:text>
        </xsl:otherwise>
    </xsl:choose>

    <xsl:choose>
        <xsl:when test="($halign='') and ($midrule='') and ($rowcss='') and ($cellcss='') and not(descendant::m) and not(descendant::answer) and not(@colspan)">
            <xsl:text>"</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>",&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>["</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>",</xsl:text>
            <xsl:if test="@colspan">
                <xsl:text>&#xa;           colspan => '</xsl:text>
                <xsl:value-of select="@colspan"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="not($halign='')">
                <xsl:text>&#xa;           halign  => '</xsl:text>
                <xsl:value-of select="$halign"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="$midrule='1' and not(preceding-sibling::cell)">
                <xsl:text>&#xa;           midrule => '</xsl:text>
                <xsl:value-of select="$midrule"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="not($rowcss='')">
                <xsl:text>&#xa;           rowcss  => '</xsl:text>
                <xsl:value-of select="$rowcss"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:if test="not($cellcss='')">
                <xsl:text>&#xa;           cellcss => '</xsl:text>
                <xsl:value-of select="$cellcss"/>
                <xsl:text>',</xsl:text>
            </xsl:if>
            <xsl:text>],&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate vertical rule width to a LaTeX vertical rule -->
<xsl:template name="vrule-specification">
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

<!-- PGML markup for Perl variable in LaTeX expression -->
<xsl:template match="statement//var|solution//var">
    <xsl:variable name="varname" select="@name" />
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:variable name="category" select="$problem/setup/var[@name=$varname]/@category" />
    <xsl:text>[</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:if test="$problem/statement//answer[@var=$varname and @format='checkboxes']">
        <xsl:text>->correct_ans()</xsl:text>
    </xsl:if>
    <xsl:text>]</xsl:text>
    <xsl:if test="not($problem/setup/var[@name=$varname]/static) and not($problem/setup/var[@name=$varname]/elements/element)">
        <xsl:message>
            <xsl:text>MBX:WARNING: A WeBWorK problem body uses a var (name="</xsl:text>
            <xsl:value-of select="$varname"/>
            <xsl:text>") for which there is no static value declared</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- PGML answer input               -->
<!-- Example: [_____]{$ans}          -->
<xsl:template match="webwork//statement//answer">
    <xsl:apply-templates select="." mode="field"/>
    <xsl:apply-templates select="." mode="format-help"/>
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:variable name="varname" select="@var" />
    <xsl:if test="not($problem/setup/var[@name=$varname]/static) and not($problem/setup/var[@name=$varname]/elements/element) and @var">
        <xsl:message>
            <xsl:text>MBX:WARNING: A WeBWorK problem body uses an answer field (var="</xsl:text>
            <xsl:value-of select="$varname"/>
            <xsl:text>") for which there is no static value declared</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- (presumed) MathObject answers -->
<xsl:template match="answer" mode="field">
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
    <xsl:text>    [</xsl:text>
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
    <xsl:text>{</xsl:text>
    <xsl:choose>
        <xsl:when test="@evaluator">
            <xsl:value-of select="@evaluator" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="@var" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <xsl:if test="$width &gt; 12">
        <xsl:text>{width => </xsl:text>
        <xsl:value-of select="$width"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- (presumed) MathObject answers inside a tabular                       -->
<!-- For answer blanks in tables (and possibly more things in the future) -->
<!-- we cannot simply insert PGML syntax. But otherwise, we do just that. -->
<xsl:template match="answer[ancestor::tabular]" mode="field">
    <xsl:text>$EmPtYsTrInG".PGML::Format('[__]{</xsl:text>
    <xsl:choose>
        <xsl:when test="@evaluator">
            <xsl:value-of select="@evaluator" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="@var" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}{width => </xsl:text>
    <xsl:choose>
        <xsl:when test="@width">
            <xsl:value-of select="@width"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>5</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}')."$EmPtYsTrInG </xsl:text>
</xsl:template>

<!-- Checkbox answers -->
<!-- TODO: not really supported yet. The checkbox handling in WeBWorK is technically broken. -->
<!-- The issue is only surfacing when trying to do a checkbox problem from an iframe. Any    -->
<!-- attempt to check multiple boxes and submit leads to only one box being seen as checked  -->
<!-- by WeBWorK 2                                                                            --> 
<xsl:template match="answer[@format='checkboxes']" mode="field">
    <xsl:text>    [@</xsl:text>
    <xsl:value-of select="@var"/>
    <xsl:text>->print_a() @]*&#xa;END_PGML&#xa;ANS(checkbox_cmp(</xsl:text>
    <xsl:value-of select="@var"/>
    <xsl:text>->correct_ans()));&#xa;BEGIN_PGML&#xa;</xsl:text>
</xsl:template>

<!-- Essay answers -->
<!-- Example: [@ ANS(essay_cmp); essay_box(6,76) @]*   -->
<!-- Requires:  PGessaymacros.pl, automatically loaded -->
<!-- http://webwork.maa.org/moodle/mod/forum/discuss.php?d=3370 -->
<xsl:template match="answer[@format='essay']" mode="field">
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

<!-- PGML inline math uses its own delimiters  -->
<!-- NB: we allow the "var" element as a child -->
<xsl:template match= "webwork//m">
    <xsl:text>[`</xsl:text>
    <xsl:call-template name="write-macros"/>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>`]</xsl:text>
</xsl:template>

<xsl:template match= "webwork//tabular//m">
    <xsl:text>$EmPtYsTrInG".PGML::Format('[`</xsl:text>
    <xsl:call-template name="write-macros"/>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>`]')."$EmPtYsTrInG </xsl:text>
</xsl:template>

<xsl:template match="webwork//me">
    <xsl:text>&#xa;&#xa;>> [``</xsl:text>
    <xsl:call-template name="write-macros"/>
    <xsl:apply-templates select="text()|var" />
    <xsl:text>``] &lt;&lt;&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="webwork//md">
    <xsl:text>&#xa;&#xa;&gt;&gt; </xsl:text>
    <xsl:choose>
        <xsl:when test="contains(., '&amp;')">
            <xsl:text>[``</xsl:text>
            <xsl:call-template name="write-macros"/>
            <xsl:text>\begin{aligned}&#xa;</xsl:text>
            <xsl:apply-templates select="mrow" />
            <xsl:text>\end{aligned}``]</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[``</xsl:text>
            <xsl:call-template name="write-macros"/>
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

<xsl:template name="write-macros">
    <xsl:param name="macros" select="/mathbook/docinfo/macros"/>
    <xsl:variable name="trimmed-start">
        <xsl:if test="contains($macros,'\newcommand{')">
            <xsl:value-of select="substring-after($macros,'\newcommand{')"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="macro-name">
        <xsl:if test="contains($trimmed-start,'}')">
            <xsl:value-of select="substring-before($trimmed-start,'}')"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="macro-command">
        <xsl:value-of select="substring-before($macros,'&#xa;')"/>
    </xsl:variable>
    <xsl:variable name="next-lines">
        <xsl:value-of select="substring-after($macros,'&#xa;')"/>
    </xsl:variable>
    <xsl:if test="contains(.,$macro-name)">
        <xsl:value-of select="normalize-space($macro-command)"/>
    </xsl:if>
    <xsl:if test="not($next-lines = '')">
        <xsl:call-template name="write-macros">
            <xsl:with-param name="macros" select="$next-lines"/>
        </xsl:call-template>
    </xsl:if>
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
    <xsl:call-template name="converter-blurb-webwork" />
    <xsl:call-template name="metadata" />
    <xsl:text>DOCUMENT();&#xa;</xsl:text>
</xsl:template>

<xsl:template name="metadata">
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
    <xsl:text>## Section1(</xsl:text>
    <xsl:text>)&#xa;</xsl:text>
    <xsl:text>## Problem1(</xsl:text>
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
    <!-- tables                                                      -->
    <xsl:if test=".//tabular">
        <xsl:text>    "niceTables.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- popup menu multiple choice answers                          -->
    <xsl:if test=".//answer[@format='popup']">
        <xsl:text>    "parserPopUp.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- radio buttons multiple choice answers                       -->
    <xsl:if test=".//answer[@format='buttons']">
        <xsl:text>    "parserRadioButtons.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- checkboxes multiple choice answers                          -->
    <xsl:if test=".//answer[@format='checkboxes']">
        <xsl:text>    "PGchoicemacros.pl",&#xa;</xsl:text>
    </xsl:if>
    <!-- essay answers, no var in setup, just answer                 -->
    <xsl:if test=".//answer[@format='essay']">
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

<xsl:template match="answer" mode="format-help">
    <xsl:variable name="varname" select="@var" />
    <xsl:variable name="problem" select="ancestor::webwork" />
    <xsl:variable name="category" select="$problem/setup/var[@name=$varname]/@category" />
    <xsl:variable name="format">
        <xsl:choose>
            <xsl:when test="@format">
                <xsl:value-of select="@format"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="category-to-format">
                    <xsl:with-param name="category" select="$category"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="($pg.answer.format.help = 'yes')">
        <xsl:choose>
            <xsl:when test="($format='none') or ($format='popup')  or ($format='buttons') or ($format='checkboxes')"/>
            <xsl:when test="$format='essay'">
                <xsl:text> [@essay_help()@]*</xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::tabular">
                <xsl:text>$EmPtYsTrInG".AnswerFormatHelp('</xsl:text>
                <xsl:value-of select="$format"/>
                <xsl:text>')."$EmPtYsTrInG </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> [@AnswerFormatHelp('</xsl:text>
                <xsl:value-of select="$format"/>
                <xsl:text>')@]*</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- Convert a var's "category" to the right term for AnswerFormatHelp -->
<xsl:template name="category-to-format">
    <xsl:param name="category" select="none"/>
    <xsl:choose>
        <xsl:when test="$category='angle'">
            <xsl:text>angles</xsl:text>
        </xsl:when>
        <xsl:when test="$category='buttons'">
            <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:when test="$category='checkboxes'">
            <xsl:text>none</xsl:text>
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
        <xsl:when test="$category='popup'">
            <xsl:text>none</xsl:text>
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

<!-- Nonbreaking space -->
<!-- contingent upon a pull request to WeBWorK -->
<xsl:template match="webwork//nbsp">
    <xsl:text>[$NBSP]*</xsl:text>
</xsl:template>

<!-- En dash           -->
<!-- contingent upon a pull request to WeBWorK -->
<xsl:template match="webwork//ndash">
    <xsl:text>[$NDASH]*</xsl:text>
</xsl:template>

<!-- Em dash           -->
<!-- contingent upon a pull request to WeBWorK -->
<xsl:template match="webwork//mdash">
    <xsl:text>[$MDASH]*</xsl:text>
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
