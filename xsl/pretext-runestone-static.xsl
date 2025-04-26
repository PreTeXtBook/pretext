<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2022 Robert A. Beezer

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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="pi exsl"
>

<!-- Conversion of author source for Runestone/interactive exercises  -->
<!-- to "standard" PreTeXt exercises, which can be used as-is in      -->
<!-- *every* conversion, except the HTML conversion, where a more     -->
<!-- capable version is designed to be powered by Runestone Services. -->

<!-- We include text utilities so we can manipulate indentation -->
<!-- in blocks of code as part of Parsons problems              -->
<xsl:include href = "./pretext-text-utilities.xsl"/>

<!-- The enclosing "exercise" and its attributes are preserved -->
<!-- before these templates are applied, so these should just  -->
<!-- produce the "body" of the exercise.                       -->

<!-- The application of the "runestone-to-static" template is     -->
<!-- controlled by a surrounding "match" that limits elements     -->
<!-- to "exercise", PROJECT-LIKE, and soon "task".  So the        -->
<!-- matches here are fine with a *[@exercise-interactive='foo'], -->
<!-- as a convenience.                                            -->

<!-- These get-programming-language templates duplicate logic from pretext-common  -->
<!-- as the contents of that file are not available yet.                           -->
<xsl:template match="program" mode="get-programming-language">
    <xsl:choose>
        <xsl:when test="@language">
            <xsl:value-of select="@language" />
        </xsl:when>
        <xsl:when test="$version-docinfo/programs/@language">
            <xsl:value-of select="$version-docinfo/programs/@language" />
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="*[@exercise-interactive = 'parson' or @exercise-interactive = 'parson-horizontal']" mode="get-programming-language">
    <xsl:choose>
        <xsl:when test="@language">
            <xsl:value-of select="@language" />
        </xsl:when>
        <xsl:when test="$version-docinfo/parsons/@language">
            <xsl:value-of select="$version-docinfo/parsons/@language" />
        </xsl:when>
        <xsl:when test="$version-docinfo/programs/@language">
            <xsl:value-of select="$version-docinfo/programs/@language" />
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- True/False -->

<xsl:template match="*[@exercise-interactive = 'truefalse']" mode="runestone-to-static">
    <!-- metadata (idx, title) -->
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <!-- prompt, followed by ordered list of choices -->
    <statement>
        <xsl:copy-of select="statement/node()"/>
        <p>True or False?</p>
    </statement>
    <!-- Hints are authored, not derived from problem formulation -->
    <xsl:copy-of select="hint"/>
    <!-- Any authored answers, not derived from problem formulation.  -->
    <!-- *Before* automatic ones, so numbering matches interactive    -->
    <!-- versions on authored ones.                                   -->
    <xsl:copy-of select="answer"/>
    <!-- the answer, simply "True" or "False" -->
    <answer>
        <xsl:choose>
            <xsl:when test="statement/@correct = 'yes'">
                <p>True.</p>
            </xsl:when>
            <xsl:when test="statement/@correct = 'no'">
                <p>False.</p>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </answer>
    <!-- Any authored solutions, not derived from problem formulation. -->
    <!-- *Before* automatic ones, so numbering matches interactive     -->
    <!-- versions on authored ones.                                    -->
    <xsl:copy-of select="solution"/>
    <!-- Answer, as above, plus explication with feedback -->
    <!-- TODO: experiment with a one-item "dl" for a slightly more       -->
    <!--       appealing presentation, rather than a one-word paragraph. -->
    <solution>
        <xsl:choose>
            <xsl:when test="statement/@correct = 'yes'">
                <p>True.</p>
            </xsl:when>
            <xsl:when test="statement/@correct = 'no'">
                <p>False.</p>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
        <xsl:copy-of select="feedback/node()"/>
    </solution>
</xsl:template>

<xsl:template match="*[@exercise-interactive = 'multiplechoice']" mode="runestone-to-static">
    <!-- metadata (idx, title) -->
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <!-- prompt, followed by ordered list of choices -->
    <statement>
        <xsl:copy-of select="statement/node()"/>
        <p><ol marker="A."> <!-- conforms to RS markers -->
            <xsl:for-each select="choices/choice">
                <li>
                    <xsl:copy-of select="statement/node()"/>
                </li>
            </xsl:for-each>
        </ol></p>
    </statement>
    <!-- Hints are authored, not derived from problem formulation -->
    <xsl:copy-of select="hint"/>
    <!-- Any authored answers, not derived from problem formulation. -->
    <!-- *Before* automatic ones, so numbering matches interactive   -->
    <!-- versions on authored ones.                                  -->
    <xsl:copy-of select="answer"/>
    <!-- the correct choices, as letters, in a sentence as a list -->
    <answer>
        <p>
            <xsl:for-each select="choices/choice">
                <xsl:if test="@correct = 'yes'">
                    <xsl:number format="A"/>
                    <xsl:if test="following-sibling::choice[@correct = 'yes']">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>.</xsl:text>
        </p>
    </answer>
    <!-- Any authored solutions, not derived from problem formulation. -->
    <!-- *Before* automatic ones, so numbering matches interactive     -->
    <!-- versions on authored ones.                                    -->
    <xsl:copy-of select="solution"/>
    <!-- feedback for each choice, in a list -->
    <solution>
        <p><ol marker="A."> <!-- conforms to RS markers -->
            <xsl:for-each select="choices/choice">
                <li>
                    <title>
                        <xsl:choose>
                            <xsl:when test="@correct = 'yes'">
                                <xsl:text>Correct</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>Incorrect</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </title>
                    <xsl:copy-of select="feedback/node()"/>
                </li>
            </xsl:for-each>
        </ol></p>
    </solution>
</xsl:template>

<xsl:template match="*[@exercise-interactive = 'parson']" mode="runestone-to-static">
    <!-- determine these options before context switches -->
    <xsl:variable name="language">
        <!-- we just need the "raw" programming language, not active-language translation -->
        <xsl:apply-templates select="." mode="get-programming-language"/>
    </xsl:variable>
    <xsl:variable name="b-natural" select="($language = '') or ($language = 'natural')"/>
    <xsl:attribute name="language">
        <xsl:value-of select="$language"/>
    </xsl:attribute>
    <!-- default for @indentation is "show", regards presentation -->
    <xsl:variable name="b-indent" select="@indentation = 'hide'"/>
    <!-- we use numbers in static versions, if requested, but ignore left/right distinction -->
    <!-- default for @numbered is "no" -->
    <xsl:variable name="b-numbered" select="(blocks/@numbered = 'left') or (blocks/@numbered = 'right')"/>
    <!-- metadata (idx, title) -->
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <!-- Statement -->
    <statement>
        <xsl:copy-of select="statement/node()"/>
        <xsl:variable name="list-type">
            <xsl:choose>
                <xsl:when test="$b-numbered">
                    <xsl:text>ol</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>ul</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- blocks, in author-defined order, via @order attribute -->
        <p>
            <xsl:element name="{$list-type}">
                <xsl:if test="$list-type = 'ol'">
                    <xsl:attribute name="marker">
                        <xsl:text>1.</xsl:text>
                    </xsl:attribute>
                </xsl:if>
                <xsl:for-each select="blocks/block">
                    <xsl:sort select="@order"/>
                    <li>
                        <xsl:choose>
                            <xsl:when test="choice">
                                <!-- a paired distractor in the block        -->
                                <!-- separate alternatives with "Either/Or"  -->
                                <!-- Order is as authored                    -->
                                <xsl:element name="{$list-type}">
                                    <xsl:attribute name="marker">
                                        <xsl:choose>
                                            <xsl:when test="$list-type = 'ol'">
                                                <!-- sub-number as a, b, c -->
                                                <xsl:text>(a)</xsl:text>
                                            </xsl:when>
                                            <xsl:when test="$list-type = 'ul'">
                                                <!-- no markers on "bulleted" sublists -->
                                                <xsl:text/>
                                            </xsl:when>
                                        </xsl:choose>
                                    </xsl:attribute>
                                    <xsl:for-each select="choice">
                                        <li>
                                            <xsl:if test="$list-type = 'ul'">
                                                <xsl:choose>
                                                    <xsl:when test="not(preceding-sibling::choice)">
                                                        <p>Either:</p>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <p>Or:</p>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:if>
                                            <xsl:choose>
                                                <xsl:when test="$b-natural">
                                                    <!-- replicate source of choice -->
                                                    <xsl:copy-of select="node()"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <!-- computer code, make a code display           -->
                                                    <!-- A "p" gets indentation relative to Either/Or -->
                                                    <!-- Otherwsie, we could make a sublist?          -->
                                                    <p>
                                                        <cd>
                                                            <xsl:choose>
                                                                <xsl:when test="$b-indent">
                                                                    <xsl:apply-templates select="." mode="strip-cline-indentation"/>
                                                                </xsl:when>
                                                                <xsl:otherwise>
                                                                    <xsl:copy-of select="node()"/>
                                                                </xsl:otherwise>
                                                            </xsl:choose>
                                                        </cd>
                                                    </p>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </li>
                                    </xsl:for-each>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- not a paired distractor -->
                                <xsl:choose>
                                    <xsl:when test="$b-natural">
                                        <!-- replicate source of block -->
                                        <xsl:copy-of select="node()"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- computer code, make a code display -->
                                        <cd>
                                            <xsl:choose>
                                                <xsl:when test="$b-indent">
                                                    <!-- a hard problem, reader supplies indentation -->
                                                    <xsl:apply-templates select="." mode="strip-cline-indentation"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <!-- a little help, indentation preserved and visible -->
                                                    <xsl:attribute name="showspaces">
                                                        <xsl:text>all</xsl:text>
                                                    </xsl:attribute>
                                                    <xsl:text>&#xa;</xsl:text>
                                                    <xsl:copy-of select="node()"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </cd>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </li>
                </xsl:for-each>
            </xsl:element>
        </p>
    </statement>
    <!-- Any authored answers, not derived from problem formulation. -->
    <!-- *Before* automatic ones, so numbering matches interactive   -->
    <!-- versions on authored ones.                                  -->
    <xsl:copy-of select="answer"/>
    <!-- Answer (potentially) -->
    <xsl:if test="$b-numbered">
        <!-- can make an economical answer with numbers of the -->
        <!-- (correct) blocks in the order of the solution     -->
        <answer>
            <p>
                <xsl:for-each select="blocks/block">
                    <!-- default on "block" is  correct="yes" -->
                    <xsl:if test="not(@correct = 'no')">
                        <xsl:value-of select="@order"/>
                        <xsl:if test="choice">
                            <xsl:for-each select="choice">
                                <!-- default on "choice" is  correct="no" -->
                                <xsl:if test="@correct = 'yes'">
                                    <xsl:number format="a"/>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:if>
                        <xsl:if test="following-sibling::block">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:if>
                </xsl:for-each>
            </p>
        </answer>
    </xsl:if>
    <!-- Any authored solutions, not derived from problem formulation. -->
    <!-- *Before* automatic ones, so numbering matches interactive     -->
    <!-- versions on authored ones.                                   -->
    <xsl:copy-of select="solution"/>
    <!-- Solution -->
    <solution>
        <xsl:choose>
            <xsl:when test="$b-natural">
                <!-- not a programming exercise, use unordered     -->
                <!-- or description list and copy "natural" markup -->
                <xsl:variable name="list-type">
                    <xsl:choose>
                        <xsl:when test="$b-numbered">
                            <xsl:text>dl</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>ul</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <p>
                    <xsl:element name="{$list-type}">
                        <xsl:if test="$list-type = 'dl'">
                            <xsl:attribute name="width">
                                <xsl:text>narrow</xsl:text>
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:for-each select="blocks/block">
                            <!-- default on "block" is  correct="yes" -->
                            <xsl:if test="not(@correct = 'no')">
                                <li>
                                    <xsl:if test="$list-type = 'dl'">
                                        <title>
                                            <xsl:value-of select="@order"/>
                                            <xsl:if test="choice">
                                                <xsl:for-each select="choice">
                                                    <!-- default on "choice" is  correct="no" -->
                                                    <xsl:if test="@correct = 'yes'">
                                                        <xsl:number format="a"/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:if>
                                        </title>
                                    </xsl:if>
                                    <xsl:choose>
                                        <xsl:when test="choice">
                                            <!-- just the correct one -->
                                            <xsl:for-each select="choice">
                                                <xsl:if test="@correct = 'yes'">
                                                    <xsl:copy-of select="node()"/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:copy-of select="node()"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </li>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:element>
                </p>
            </xsl:when>
            <xsl:otherwise>
                <!-- programming language specified, assume "cline" -->
                <!-- structure, reconstruct as a program/input      -->
                <program>
                    <xsl:attribute name="language">
                        <xsl:value-of select="$language"/>
                    </xsl:attribute>
                    <input>
                        <xsl:for-each select="blocks/block">
                            <xsl:if test="not(@correct = 'no')">
                                <xsl:choose>
                                    <xsl:when test="choice">
                                        <!-- just the correct choice              -->
                                        <!-- default on "choice" is  correct="no" -->
                                        <xsl:for-each select="choice">
                                            <xsl:if test="@correct = 'yes'">
                                                <xsl:for-each select="cline">
                                                    <xsl:value-of select="."/>
                                                    <xsl:text>&#xa;</xsl:text>
                                                </xsl:for-each>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:for-each select="cline">
                                            <xsl:value-of select="."/>
                                            <xsl:text>&#xa;</xsl:text>
                                        </xsl:for-each>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>
                        </xsl:for-each>
                    </input>
                </program>
            </xsl:otherwise>
        </xsl:choose>
    </solution>
</xsl:template>

<!-- If a sequence of "cline" are in a problem where a student does      -->
<!-- not get indentation help, then we need to strip it out for          -->
<!-- presentation in a static form.  This template forms the text block, -->
<!-- strips leading/gross indentation with a utility template, then uses -->
<!-- a recursive template to wrap back into "cline".                     -->

<xsl:template match="block|choice" mode="strip-cline-indentation">
    <xsl:variable name="text-block">
        <xsl:for-each select="cline">
            <xsl:value-of select="."/>
            <xsl:text>&#xa;</xsl:text>
        </xsl:for-each>
    </xsl:variable>
    <xsl:call-template name="restore-cline">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:value-of select="$text-block"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="restore-cline">
    <xsl:param name="text"/>

    <xsl:choose>
        <xsl:when test="$text = ''"/>
        <xsl:otherwise>
            <cline>
                <xsl:value-of select="substring-before($text, '&#xa;')"/>
            </cline>
            <xsl:call-template name="restore-cline">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Parson (Horizontal) -->

<xsl:template match="*[@exercise-interactive = 'parson-horizontal']" mode="runestone-to-static">
    <xsl:attribute name="language">
        <xsl:apply-templates select="." mode="active-language"/>
    </xsl:attribute>
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <!-- Statement -->
    <statement>
        <xsl:copy-of select="statement/node()"/>
        <!-- programming language version -->
        <p>
            <cd>
                <cline>
                    <!-- hard to tell which is last once sorted, -->
                    <!-- so we just mark front *and* end         -->
                    <xsl:text> | </xsl:text>
                    <xsl:for-each select="blocks/block[@order]">
                        <xsl:sort select="@order"/>
                        <xsl:apply-templates select="." mode="static-horizontal-block"/>
                        <xsl:text> | </xsl:text>
                    </xsl:for-each>
                </cline>
            </cd>
        </p>
    </statement>
    <!-- We provide a complete solution below, -->
    <!-- so no automatic hint or answer        -->
    <xsl:copy-of select="hint"/>
    <xsl:copy-of select="answer"/>
    <!-- Any authored solutions, not derived from problem formulation. -->
    <!-- *Before* automatic ones, so numbering matches interactive     -->
    <!-- versions on authored ones.                                   -->
    <xsl:copy-of select="solution"/>
    <solution>
        <!-- programming language version -->
        <!-- filter out distractors for the solution -->
        <xsl:variable name="the-blocks" select="blocks/block[not(@correct = 'no')]"/>
        <p>
            <cd>
                <cline>
                    <!-- authored in order, but need to follow @ref -->
                    <xsl:for-each select="$the-blocks">
                        <xsl:apply-templates select="." mode="static-horizontal-block"/>
                        <!-- context shift should handle distractors at the end -->
                        <xsl:if test="following-sibling::block">
                            <xsl:text> </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </cline>
            </cd>
        </p>
    </solution>
</xsl:template>

<xsl:template match="blocks/block" mode="static-horizontal-block">
    <xsl:choose>
        <!-- follow @ref, copy children -->
        <xsl:when test="@ref">
            <xsl:copy-of select="id(@ref)/node()"/>
        </xsl:when>
        <!-- otherwisr duplicate children -->
        <xsl:otherwise>
            <xsl:copy-of select="node()"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Matching Problems -->

<!-- Cardort variant first, then fully-general matching afterward -->

<xsl:template match="*[@exercise-interactive = 'cardsort']" mode="runestone-to-static">
    <!-- metadata (idx, title) -->
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <!-- Statement -->
    <statement>
        <xsl:copy-of select="statement/node()"/>
        <xsl:apply-templates select="cardsort" mode="cardsort-statement"/>
    </statement>
    <!-- Any authored hint, answers, solutions not derived from   -->
    <!-- problem formulation. *Before* automatic solution, so     -->
    <!-- numbering matches interactive versions on authored ones. -->
    <xsl:copy-of select="hint"/>
    <xsl:copy-of select="answer"/>
    <xsl:copy-of select="solution"/>
    <!-- Automatically generated solution -->
    <solution>
        <xsl:apply-templates select="cardsort" mode="cardsort-solution"/>
    </solution>
</xsl:template>

<!-- For a problem statement, we use a response list re-ordered    -->
<!-- according to response/@order attribute values given by author -->
<xsl:template match="cardsort" mode="cardsort-statement">

    <!-- Reorder premises -->
    <xsl:variable name="sorted-premises-rtf">
        <xsl:for-each select="match/premise">
            <xsl:sort select="@order"/>
            <xsl:copy-of select="."/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="sorted-premises" select="exsl:node-set($sorted-premises-rtf)"/>

    <!-- responses in authored order -->
    <xsl:variable name="all-responses" select="match/response"/>

    <tabular>
        <xsl:call-template name="matching-row">
            <!-- $sorted-premises gets a root element, collecting the "premise" -->
            <xsl:with-param name="premises" select="$sorted-premises/premise"/>
            <xsl:with-param name="responses" select="$all-responses"/>
        </xsl:call-template>
    </tabular>
</xsl:template>

<!-- Make one row of a tabular, recursively.  We do not know which list  -->
<!-- is longer (or they are the same length).  So we "zip" them together -->
<!-- by making a row and then effectively discarding the contents of the -->
<!-- row in the recursive call.  (We could pass/increment a row number   -->
<!-- and not keep updating the node-set.)                                -->

<xsl:template name="matching-row">
    <xsl:param name="premises"/>
    <xsl:param name="responses"/>

    <xsl:choose>
        <xsl:when test="not($premises) and not($responses)"/>
        <xsl:otherwise>
            <row>
                <cell>
                    <xsl:if test="count($premises) > 1">
                        <xsl:attribute name="bottom">
                            <xsl:text>minor</xsl:text>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:copy-of select="$premises[1]/node()"/>
                </cell>
                <!-- An empty (two-character wide) column is a bit of a hack to get -->
                <!-- a visual separation.  Could we do better with paragraph cells? -->
                <cell bottom="none"><nbsp/><nbsp/></cell>
                <cell>
                    <xsl:if test="count($responses) > 1">
                        <xsl:attribute name="bottom">
                            <xsl:text>minor</xsl:text>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:copy-of select="$responses[1]/node()"/>
                </cell>
            </row>
            <xsl:call-template name="matching-row">
                <xsl:with-param name="premises" select="$premises[position() > 1]"/>
                <xsl:with-param name="responses" select="$responses[position() > 1]"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- For a solution, we make an unordered list of the responses     -->
<!-- (the "buckets" in true cardsort terminology) and for each      -->
<!-- we make a sub-list wioth the premises that match (the "cards"  -->
<!-- in true cardsort terminology.  Note that potential distractors -->
<!-- are a premise with no response (empty sub-list) and a response -->
<!-- with no premise (a premise that is null-ish).                  -->

<xsl:template match="cardsort" mode="cardsort-solution">
    <p><ul>
        <xsl:for-each select="match">
            <li>
                <p>
                    <xsl:choose>
                        <xsl:when test="response">
                            <xsl:copy-of select="response"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>(uncategorized)</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="premise">
                        <ul>
                            <xsl:for-each select="premise">
                                <li>
                                    <xsl:copy-of select="."/>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </xsl:if>
                </p>
            </li>
        </xsl:for-each>
    </ul></p>
</xsl:template>

<!-- General matching: temporary - stub out static -->

<xsl:template match="*[@exercise-interactive = 'matching']" mode="runestone-to-static">
    <statement>
        <p>2025-04-25: stub while static versions of general matching questions are under development.</p>
        <xsl:copy-of select="statement/node()"/>
    </statement>
</xsl:template>


<!-- Clickable Area -->

<xsl:template match="*[@exercise-interactive = 'clickablearea']" mode="runestone-to-static">
    <!-- metadata (idx, title) -->
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <!-- Statement -->
    <statement>
        <xsl:copy-of select="statement/node()"/>
        <xsl:apply-templates select="areas" mode="static-areas"/>
    </statement>
    <xsl:copy-of select="hint"/>
    <!-- Any authored answers, not derived from problem formulation. -->
    <!-- *Before* automatic ones, so numbering matches interactive   -->
    <!-- versions on authored ones.                                  -->
    <xsl:copy-of select="answer"/>
    <answer>
        <p>
            <xsl:text>Correct: </xsl:text>
            <xsl:for-each select="areas//area[not(@correct = 'no')]">
                <xsl:apply-templates select="." mode="answer-areas"/>
                <xsl:if test="not(position() = last())">
                    <xsl:text>; </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>.</xsl:text>
            <xsl:text> </xsl:text>
            <xsl:text>Incorrect: </xsl:text>
            <xsl:for-each select="areas//area[@correct = 'no']">
                <xsl:apply-templates select="." mode="answer-areas"/>
                <xsl:if test="not(position() = last())">
                    <xsl:text>; </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>.</xsl:text>
        </p>
        <xsl:copy-of select="feedback/node()"/>
    </answer>
    <!-- Any authored solutions, not derived from problem formulation. -->
    <!-- *Before* automatic ones, so numbering matches interactive     -->
    <!-- versions on authored ones.                                    -->
    <xsl:copy-of select="solution"/>
    <!-- A text version can get markup of correct and incorrect areas    -->
    <!-- (italics, strikethrough) but no good way to markup code easily. -->
    <!-- So no "solution" for code versions.                             -->
    <xsl:if test="not(areas/cline)">
        <solution>
            <xsl:apply-templates select="areas/node()" mode="solution-areas"/>
        </solution>
    </xsl:if>
</xsl:template>

<!-- We do a xerox'ing pass to construct the problem. -->
<!--   (1) "area" gets dropped (invisible in static)  -->
<!--       [could italicize correct and incorrect?]   -->
<!--   (2) "cline" get reconstructed as a "program"   -->

<xsl:template match="node()|@*" mode="static-areas">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="static-areas"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="areas" mode="static-areas">
    <xsl:choose>
        <xsl:when test="cline">
            <!-- code, so make a "program" structure -->
            <program>
                <xsl:attribute name="language">
                    <xsl:apply-templates select="." mode="get-programming-language"/>
                </xsl:attribute>
                <input>
                    <xsl:apply-templates select="cline" mode="static-areas"/>
                </input>
            </program>
        </xsl:when>
        <xsl:otherwise>
            <!-- regular text, this will match a default template later -->
            <xsl:apply-templates select="*" mode="static-areas"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="areas/cline" mode="static-areas">
    <xsl:apply-templates select="text()|area" mode="static-areas"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="cline/text()" mode="static-areas">
    <xsl:value-of select="."/>
</xsl:template>

<!-- NB: don't apply to attributes of an "area" (just @correct) -->
<xsl:template match="area" mode="static-areas">
    <xsl:apply-templates select="node()" mode="static-areas"/>
</xsl:template>

<!-- Modal templates reproduce answers, which could have some  -->
<!-- markup in them?  We enter here at each "area" to form the -->
<!-- lists of correct and incorrect areas.                     -->

<xsl:template match="node()|@*" mode="answer-areas">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="answer-areas"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="area[parent::cline]" mode="answer-areas">
    <c>
        <!-- NB: don't xerox attributes of an "area" (just @correct) -->
        <xsl:apply-templates select="node()" mode="answer-areas"/>
    </c>
</xsl:template>

<xsl:template match="area[not(parent::cline) and not(@correct = 'no')]" mode="answer-areas">
    <em>
        <!-- NB: don't xerox attributes of an "area" (just @correct) -->
        <xsl:apply-templates select="node()" mode="answer-areas"/>
    </em>
</xsl:template>

<xsl:template match="area[not(parent::cline) and (@correct = 'no')]" mode="answer-areas">
    <delete>
        <!-- NB: don't xerox attributes of an "area" (just @correct) -->
        <xsl:apply-templates select="node()" mode="answer-areas"/>
    </delete>
</xsl:template>

<!-- protect from low-level routines in -common -->
<xsl:template match="cline/area/text()" mode="answer-areas">
    <xsl:value-of select="."/>
</xsl:template>

<!-- For a text version (only, not a code version) we xerox -->
<!-- the contents of "areas" and slide-in some highlighting -->
<!-- of the correct and incorrect "area".                   -->

<xsl:template match="node()|@*" mode="solution-areas">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="solution-areas"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="area[not(@correct = 'no')]" mode="solution-areas">
    <em>
        <!-- NB: don't xerox attributes of an "area" (just @correct) -->
        <xsl:apply-templates select="node()" mode="solution-areas"/>
    </em>
</xsl:template>

<xsl:template match="area[@correct = 'no']" mode="solution-areas">
    <delete>
        <!-- NB: don't xerox attributes of an "area" (just @correct) -->
        <xsl:apply-templates select="node()" mode="solution-areas"/>
    </delete>
</xsl:template>

<!-- Fill-In the Blanks (Basic) -->

<xsl:template match="*[@exercise-interactive = 'fillin-basic']" mode="runestone-to-static">
    <!-- metadata (idx, title) -->
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <!-- reproduce statement identically, but replace var w/ fillin -->
    <xsl:apply-templates select="statement" mode="fillin-statement"/>
    <!-- Any authored hints, answers, solutions, not derived from   -->
    <!-- problem formulation. *Before* automatic ones, so numbering -->
    <!-- matches interactive versions on authored ones.             -->
    <xsl:copy-of select="hint"/>
    <xsl:copy-of select="answer"/>
    <xsl:copy-of select="solution"/>
    <xsl:apply-templates select="statement" mode="fillin-solution"/>
</xsl:template>

<!-- Fillin Statement -->
<xsl:template match="node()|@*" mode="fillin-statement">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="fillin-statement"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="var" mode="fillin-statement">
    <fillin>
        <xsl:attribute name="characters">
            <xsl:choose>
                <xsl:when test="@width">
                    <xsl:value-of select="@width"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- arbitrary default width -->
                    <xsl:text>5</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </fillin>
</xsl:template>

<!-- Fillin complete solution -->

<xsl:template match="node()|@*" mode="fillin-solution">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="fillin-solution"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="statement" mode="fillin-solution">
    <xsl:variable name="exercise" select=".."/>
    <solution>
        <xsl:apply-templates select="node()|@*" mode="fillin-solution"/>
        <!-- xerox feedback for correct response on each var -->
        <xsl:for-each select="../setup/var/condition[1]/feedback">
            <xsl:apply-templates select="node()" mode="fillin-solution"/>
        </xsl:for-each>
        <xsl:for-each select=".//fillin[@answer]">
            <xsl:variable name="fillin-name" select="@name"/>
            <xsl:variable name="fillin-pos" select="position()"/>
            <xsl:choose>
                <!-- If #evaluate matches by name, find feedback on a correct result -->
                <xsl:when test="$exercise/evaluation/evaluate[@name='$fillin-name']/test[@correct='yes']">
                    <xsl:apply-templates select="$exercise/evaluation/evaluate[@name='$fillin-name']/test[@correct='yes']/feedback/node()" mode="fillin-solution"/>
                </xsl:when>
                <!-- Otherwise #evaluate matches by order, find feedback on a correct result -->
                <xsl:when test="$exercise/evaluation/evaluate[$fillin-pos]/test[@correct='yes']">
                    <xsl:apply-templates select="$exercise/evaluation/evaluate[$fillin-pos]/test[@correct='yes']/feedback/node()" mode="fillin-solution"/>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
        <xsl:if test="../evaluation[@answers-coupled='yes']">
            <xsl:apply-templates select="$exercise/evaluation/evaluate[@all='yes']/test[@correct='yes']/feedback/node()" mode="fillin-solution"/>
        </xsl:if>
    </solution>
</xsl:template>

<xsl:template match="var" mode="fillin-solution">
    <!-- NB: this code is used in formulating HTML representations -->
    <!-- count location of (context) "var" in problem statement    -->
    <xsl:variable name="location">
        <xsl:number from="statement"/>
    </xsl:variable>
    <!-- locate corresponding "var" in "setup" -->
    <xsl:variable name="setup-var" select="ancestor::exercise/setup/var[position() = $location]"/>

    <!-- Know can tell what the correct answer is, from first "condition"-->
    <fillin characters="1"/>
    <xsl:choose>
        <xsl:when test="$setup-var/condition[1]/@number">
            <m>
                <xsl:value-of select="$setup-var/condition[1]/@number"/>
            </m>
        </xsl:when>
        <xsl:when test="$setup-var/condition[1]/@string">
            <xsl:value-of select="$setup-var/condition[1]/@string"/>
        </xsl:when>
    </xsl:choose>
    <fillin characters="1"/>
</xsl:template>

<!-- Fill-In the Blanks (Complete) -->

<xsl:template match="*[@exercise-interactive = 'fillin']" mode="runestone-to-static">
    <!-- metadata (idx, title) -->
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <!-- reproduce statement identically, but replace var w/ fillin -->
    <xsl:apply-templates select="statement" mode="fillin-statement"/>
    <!-- Any authored hints, answers, solutions, not derived from   -->
    <!-- problem formulation. *Before* automatic ones, so numbering -->
    <!-- matches interactive versions on authored ones.             -->
    <xsl:copy-of select="hint"/>
    <xsl:copy-of select="answer"/>
    <xsl:choose>
        <xsl:when test="solution[@include-automatic='no']">
            <xsl:copy-of select="solution"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="statement" mode="fillin-solution"/>
            <xsl:copy-of select="solution"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Fillin Statement -->
<xsl:template match="fillin" mode="fillin-statement">
    <fillin>
        <xsl:attribute name="characters">
            <xsl:choose>
                <xsl:when test="@width">
                    <xsl:value-of select="@width"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- arbitrary default width -->
                    <xsl:text>5</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </fillin>
</xsl:template>

<!-- Fillin complete solution -->
<xsl:template match="fillin" mode="fillin-solution">
    <!-- Correct answer is in @answer. -->
    <fillin characters="1"/>
    <xsl:choose>
        <xsl:when test="@mode='math' or @mode='number'">
            <m><xsl:value-of select="@answer"/></m>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="@answer"/>
        </xsl:otherwise>
    </xsl:choose>
    <fillin characters="1"/>
</xsl:template>

<!-- Short Answer -->

<!-- Authored with a "response" element, we effectively drop it here -->
<xsl:template match="*[@exercise-interactive = 'shortanswer']" mode="runestone-to-static">
    <!-- metadata (idx, title) -->
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <!-- reproduce usual components -->
    <xsl:copy-of select="statement"/>
    <!-- skip over response until it carries something relevant -->
    <xsl:copy-of select="hint"/>
    <xsl:copy-of select="answer"/>
    <xsl:copy-of select="solution"/>
</xsl:template>

<!-- Queries -->

<xsl:template match="query" mode="runestone-to-static">
    <paragraphs>
        <!-- no period, it is supplied by conversions -->
        <!-- TODO: internationalize the term -->
        <title>Query</title>
        <!-- reproduce structured statement's pieces -->
        <xsl:copy-of select="statement/*"/>
        <xsl:choose>
            <xsl:when test="choices">
                <p><ol format="1.">
                    <xsl:for-each select="choices/choice">
                        <li>
                            <xsl:copy-of select="."/>
                        </li>
                    </xsl:for-each>
                </ol></p>
            </xsl:when>
            <xsl:when test="@scale">
                <!-- A pre-formatted "display" of the integer choices, -->
                <!-- which could be printed and circled by the reader. -->
                <pre>
                    <xsl:apply-templates select="." mode="scale-choices"/>
                </pre>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </paragraphs>
</xsl:template>

<!-- Recursively count-up and layout choices with rows of -->
<!-- 10 choices each, with blank lines between the rows.  -->
<xsl:template match="query" mode="scale-choices">
    <xsl:param name="the-choice" select="'1'"/>

    <xsl:choose>
        <!-- Done.  Emit and that's it -->
        <xsl:when test="$the-choice = ./@scale">
            <xsl:value-of select="$the-choice"/>
        </xsl:when>
        <!-- Done with a row, but not done.  Newline, and blankline. -->
        <xsl:when test="$the-choice mod 10 = 0">
            <xsl:value-of select="$the-choice"/>
            <xsl:text>&#xa;&#xa;</xsl:text>
            <xsl:apply-templates select="." mode="scale-choices">
                <xsl:with-param name="the-choice" select="$the-choice + 1"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- Mid-row, use two spaces to separate. -->
        <xsl:otherwise>
            <xsl:value-of select="$the-choice"/>
            <xsl:text>&#x20;&#x20;</xsl:text>
            <xsl:apply-templates select="." mode="scale-choices">
                <xsl:with-param name="the-choice" select="$the-choice + 1"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Active Code -->

<xsl:template match="*[@exercise-interactive = 'coding']" mode="runestone-to-static">
    <!-- metadata (idx, title) -->
    <xsl:copy-of select="statement/preceding-sibling::*"/>
    <statement>
        <!-- duplicate the authored prompt/statement -->
        <xsl:copy-of select="statement/node()"/>
        <!-- bring up the program as part of the problem statement -->
        <xsl:copy-of select="program"/>
    </statement>
    <xsl:copy-of select="hint"/>
    <xsl:copy-of select="answer"/>
    <xsl:copy-of select="solution"/>
</xsl:template>


<xsl:template match="datafile" mode="runestone-to-static">
    <!-- Some templates and variables are defined in -common for consistency -->

    <!-- A faux automatic title of sorts, careful about whitespace for mixed content -->
    <!-- TODO: localize "Data" (or "Data file"?), but too early in pre-processor,  -->
    <!-- there is no $docinfo to consult for renames, etc. -->
    <pre>Data: <xsl:value-of select="@filename"/></pre>

    <xsl:choose>
        <xsl:when test="image">
            <xsl:copy-of select="image"/>
        </xsl:when>
        <xsl:when test="pre">
            <!-- provide default rows and cols, sync with dynamic version -->
            <xsl:variable name="desired-rows">
                <xsl:choose>
                    <xsl:when test="@rows">
                        <xsl:value-of select="@rows"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$datafile-default-rows"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="desired-cols">
                <xsl:choose>
                    <xsl:when test="@cols">
                        <xsl:value-of select="@cols"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$datafile-default-cols"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <pre>
                <!-- form an "upper-left-corner" view -->
                <xsl:call-template name="text-viewport">
                    <xsl:with-param name="nrows" select="$desired-rows"/>
                    <xsl:with-param name="ncols" select="$desired-cols"/>
                    <xsl:with-param name="text">
                        <!-- defined in -common -->
                        <xsl:apply-templates select="." mode="datafile-text-contents"/>
                    </xsl:with-param>
                </xsl:call-template>
            </pre>
        </xsl:when>
        <!-- no other source/PTX element is supported , bail out-->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
