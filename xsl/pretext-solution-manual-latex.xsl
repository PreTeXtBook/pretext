<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2018 Robert A. Beezer

This file is part of PreTeXt.

MathBook XML is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

MathBook XML is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
>

<!-- This import will include the assembly phase, which is -->
<!-- necessary as support for a private solutions file     -->
<xsl:import href="./pretext-latex.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<!-- These variables are interpreted in pretext-common.xsl and  -->
<!-- so may be used/set in a custom XSL stylesheet for a         -->
<!-- project's solution manual.                                  -->
<!--                                                             -->
<!-- exercise.inline.statement                                   -->
<!-- exercise.inline.hint                                        -->
<!-- exercise.inline.answer                                      -->
<!-- exercise.inline.solution                                    -->
<!-- exercise.divisional.statement                               -->
<!-- exercise.divisional.hint                                    -->
<!-- exercise.divisional.answer                                  -->
<!-- exercise.divisional.solution                                -->
<!-- exercise.worksheet.statement                                -->
<!-- exercise.worksheet.hint                                     -->
<!-- exercise.worksheet.answer                                   -->
<!-- exercise.worksheet.solution                                 -->
<!-- exercise.reading.statement                                  -->
<!-- exercise.reading.hint                                       -->
<!-- exercise.reading.answer                                     -->
<!-- exercise.reading.solution                                   -->
<!-- project.statement                                           -->
<!-- project.hint                                                -->
<!-- project.answer                                              -->
<!-- project.solution                                            -->
<!--                                                             -->
<!-- The second set of variables are internal, and are derived   -->
<!-- from the above via careful routines in pretext-common.xsl. -->
<!--                                                             -->
<!-- b-has-inline-statement                                      -->
<!-- b-has-inline-hint                                           -->
<!-- b-has-inline-answer                                         -->
<!-- b-has-inline-solution                                       -->
<!-- b-has-divisional-statement                                  -->
<!-- b-has-divisional-hint                                       -->
<!-- b-has-divisional-answer                                     -->
<!-- b-has-divisional-solution                                   -->
<!-- b-has-worksheet-statement                                   -->
<!-- b-has-worksheet-hint                                        -->
<!-- b-has-worksheet-answer                                      -->
<!-- b-has-worksheet-solution                                    -->
<!-- b-has-reading-statement                                     -->
<!-- b-has-reading-hint                                          -->
<!-- b-has-reading-answer                                        -->
<!-- b-has-reading-solution                                      -->
<!-- b-has-project-statement                                     -->
<!-- b-has-project-hint                                          -->
<!-- b-has-project-answer                                        -->
<!-- b-has-project-solution                                      -->

<!-- Conceived as a "print only" PDF, this is also necessary    -->
<!-- to keep links (such as a solution number linking back to   -->
<!-- the original) from being seen/interpreted as actual links. -->
<xsl:param name="latex.print" select="'yes'"/>
<!-- There are not even labels for page numbers, beside -->
<!-- the fact that they don't make much sense           -->
<xsl:param name="latex.pageref" select="'no'"/>

<!-- We have a switch for just this situation, to force -->
<!-- (overrule) the auto-detetion of the necessity for  -->
<!-- LaTeX styles for the solutions to exercises.       -->
<!-- See  pretext-latex.xsl  for more explanation.     -->
<xsl:variable name="b-needs-solution-styles" select="true()"/>

<!-- We hardcode the numbers of 2D displays so they are correct where  -->
<!-- born, this switch could be expanded to the cross-references -->
<xsl:variable name="b-latex-hardcode-numbers" select="true()"/>

<!-- For a "book" we replace the first chapter by a call to the        -->
<!-- solutions generator.  So we burrow into parts to get at chapters. -->

<xsl:template match="part|chapter|section|backmatter/solutions" />

<xsl:template match="part[1]">
    <xsl:apply-templates select="chapter[1]" />
</xsl:template>

<!-- provoke the "solutions-generator" at the first sign of main matter content -->
<xsl:template match="chapter[1]|article/section[1]">
    <xsl:apply-templates select="$document-root" mode="solutions-generator">
        <xsl:with-param name="purpose" select="'solutionmanual'" />
        <xsl:with-param name="admit" select="'all'" />
        <xsl:with-param name="b-inline-statement"     select="$b-has-inline-statement" />
        <xsl:with-param name="b-inline-hint"          select="$b-has-inline-hint"  />
        <xsl:with-param name="b-inline-answer"        select="$b-has-inline-answer"  />
        <xsl:with-param name="b-inline-solution"      select="$b-has-inline-solution"  />
        <xsl:with-param name="b-divisional-statement" select="$b-has-divisional-statement" />
        <xsl:with-param name="b-divisional-hint"      select="$b-has-divisional-hint"  />
        <xsl:with-param name="b-divisional-answer"    select="$b-has-divisional-answer"  />
        <xsl:with-param name="b-divisional-solution"  select="$b-has-divisional-solution"  />
        <xsl:with-param name="b-worksheet-statement"  select="$b-has-worksheet-statement" />
        <xsl:with-param name="b-worksheet-hint"       select="$b-has-worksheet-hint"  />
        <xsl:with-param name="b-worksheet-answer"     select="$b-has-worksheet-answer"  />
        <xsl:with-param name="b-worksheet-solution"   select="$b-has-worksheet-solution"  />
        <xsl:with-param name="b-reading-statement"    select="$b-has-reading-statement" />
        <xsl:with-param name="b-reading-hint"         select="$b-has-reading-hint"  />
        <xsl:with-param name="b-reading-answer"       select="$b-has-reading-answer"  />
        <xsl:with-param name="b-reading-solution"     select="$b-has-reading-solution"  />
        <xsl:with-param name="b-project-statement"    select="$b-has-project-statement" />
        <xsl:with-param name="b-project-hint"         select="$b-has-project-hint"  />
        <xsl:with-param name="b-project-answer"       select="$b-has-project-answer"  />
        <xsl:with-param name="b-project-solution"     select="$b-has-project-solution"  />
    </xsl:apply-templates>
</xsl:template>

<!-- Hard-code numbers into titles -->
<xsl:template match="part|chapter|section|subsection|subsubsection|exercises" mode="division-in-solutions">
    <xsl:param name="scope" />
    <xsl:param name="content" />

    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:variable name="original-title">
        <!-- no trailing space if no number -->
        <xsl:if test="not($the-number = '')">
            <xsl:value-of select="$the-number" />
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:variable>
    <xsl:variable name="moving-title">
        <!-- no trailing space if no number -->
        <xsl:if test="not($the-number = '')">
            <xsl:value-of select="$the-number" />
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="title-simple" />
    </xsl:variable>

    <!-- LaTeX heading with hard-coded number -->
    <xsl:text>\</xsl:text>
    <xsl:apply-templates select="." mode="division-name" />
    <xsl:text>*{</xsl:text>
    <xsl:value-of select="$original-title"/>
    <xsl:text>}&#xa;</xsl:text>
    <!-- An entry for the ToC, since we hard-code numbers -->
    <!-- These mainmatter divisions should always have a number -->
    <xsl:text>\addcontentsline{toc}{</xsl:text>
    <xsl:apply-templates select="." mode="division-name" />
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="$moving-title"/>
    <xsl:text>}&#xa;</xsl:text>
    <!-- Explicit marks, since divisions are the starred form -->
    <xsl:choose>
        <xsl:when test="self::chapter">
            <xsl:text>\chaptermark{</xsl:text>
            <xsl:value-of select="$moving-title"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <!-- "section", "exercises", "worksheet", at section-level, etc. -->
        <xsl:when test="parent::chapter">
            <xsl:text>\sectionmark{</xsl:text>
            <xsl:value-of select="$moving-title"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>

    <xsl:copy-of select="$content" />
</xsl:template>

<!-- Page headers + Chapter/Section XYZ Title      -->
<!-- \sethead[even-left][even-center][even-right]  -->
<!--         {odd-left}{odd-center}{odd-right}     -->
<xsl:template match="book" mode="titleps-headings">
    <xsl:text>{&#xa;</xsl:text>
    <xsl:text>\sethead[\thepage][][\textsl{\chaptertitle}]&#xa;</xsl:text>
    <xsl:text>{\textsl{\sectiontitle}}{}{\thepage}&#xa;</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Hard-Coded Numbers -->
<!-- As a subset of full content, we can't          -->
<!-- point to much of the content with hyperlinks   -->
<!-- But we do have the full context as we process, -->
<!-- so we can get numbers for cross-references     -->
<!-- and *hard-code* them into the LaTeX            -->

<!-- We don't dither about possibly using a \ref{} and  -->
<!-- just produce numbers.  These might lack the "part" -->
<xsl:template match="*" mode="xref-number">
  <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- The actual link is not a \hyperlink nor a    -->
<!-- hyperref, but instead is just plain 'ol text -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" select="'MISSING LINK CONTENT'"/>
    <xsl:value-of select="$content" />
</xsl:template>

<!-- Exercise numbers are always hard-coded at birth, given -->
<!-- complications of numbering, placement, duplication     -->

<!-- Since divisions have hard-coded numbers, a \label{}   -->
<!-- on an equation will be inaccurate.  These are reduced -->
<!-- versions of the templates for hard-coded equation     -->
<!-- numbers in the HTML conversion.                       -->

<xsl:template match="men|mrow" mode="tag">
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="mrow[@tag]" mode="tag">
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
    <xsl:text>}</xsl:text>
</xsl:template>

</xsl:stylesheet>
