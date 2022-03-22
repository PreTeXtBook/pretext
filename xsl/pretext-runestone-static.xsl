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
>

<!-- Conversion of author source for Runestone/interactive exercises  -->
<!-- to "standard" PreTeXt exercises, which can be used as-is in      -->
<!-- *every* conversion, except the HTML conversion, where a more     -->
<!-- capable version is designed to be powered by Runestone Services. -->

<xsl:template match="exercise[choices]" mode="runestone-to-static">
    <!-- prompt, followed by ordered list of choices -->
    <xsl:text>&#xa;</xsl:text>
    <statement>
        <xsl:copy-of select="statement/node()"/>
        <p><ol label="A."> <!-- conforms to RS markers -->
            <xsl:for-each select="choices/choice">
                <li>
                    <xsl:copy-of select="statement/node()"/>
                </li>
            </xsl:for-each>
        </ol></p>
    </statement>
    <!-- Hints are authored, not derived from problem formulation -->
    <xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="hint"/>
    <!-- the correct choices, as letters, in a sentence as a list -->
    <xsl:text>&#xa;</xsl:text>
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
    <!-- feedback for each choice, in a list -->
    <xsl:text>&#xa;</xsl:text>
    <solution>
        <p><ol label="A."> <!-- conforms to RS markers -->
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

<xsl:template match="exercise[blocks]" mode="runestone-to-static">
    <statement>
        <xsl:copy-of select="statement/node()"/>
        <!-- blocks, in author-defined order, via @order attribute -->
        <p><ul>
            <xsl:for-each select="blocks/block">
                <xsl:sort select="@order"/>
                <li>
                    <xsl:choose>
                        <xsl:when test="choice">
                            <!-- seperate alternatives with "Or" -->
                            <xsl:for-each select="choice">
                                <xsl:copy-of select="node()"/>
                                <xsl:if test="following-sibling::choice">
                                    <p>Or,</p>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="node()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
            </xsl:for-each>
        </ul></p>
    </statement>
    <solution>
        <p><ul>
            <xsl:for-each select="blocks/block">
                <xsl:if test="not(@correct = 'no')">
                    <li>
                        <xsl:choose>
                            <xsl:when test="choice">
                                <!-- seperate alternatives with "Or" -->
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
        </ul></p>
    </solution>
</xsl:template>

<!-- Active Code -->

<xsl:template match="exercise[statement and program]|project[statement and program]|activity[statement and program]|exploration[statement and program]|investigation[statement and program]" mode="runestone-to-static">
    <statement>
        <!-- duplicate the authored prompt/statement -->
        <xsl:copy-of select="statement/node()"/>
        <!-- bring up the program as part of the problem statement -->
        <xsl:copy-of select="program"/>
    </statement>
    <xsl:copy-of select="hint|answer|solution"/>
</xsl:template>

</xsl:stylesheet>
