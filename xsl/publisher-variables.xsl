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
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
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
<!-- NB A publisher might provide a filename, which when resolved   -->
<!-- as an absolute path (think "My Documents") by some helper      -->
<!-- program or front-end, will arrive here containing a space,     -->
<!-- which will cause the  document()  function to fail silently.   -->
<!-- The location provided in the first argument of document() is   -->
<!-- a URI, so the proper escape mechanism is percent-encoding.     -->
<xsl:variable name="publication" select="document(str:replace($publisher, '&#x20;', '%20'), .)/publication"/>

<!-- The "publisher-variables.xsl" and "pretext-assembly.xsl"      -->
<!-- stylesheets are symbiotic, and should be imported             -->
<!-- simultaneously.  Assembly will change the source in various   -->
<!-- ways, while some defaults for publisher variables will depend -->
<!-- on source.  The default variables should depend on gross      -->
<!-- structure and adjustments should be to smaller portions of    -->
<!-- the source, but we don't take any chances.  So, note in       -->
<!-- "assembly" that an intermediate tree is defined as a          -->
<!-- variable, which is then used in defining some variables,      -->
<!-- based on assembled source.  Conversely, certain variables,    -->
<!-- such as locations of customizations or private solutions,     -->
<!-- are needed early in assembly, while other variables, such     -->
<!-- as options for numbering, are needed for later enhancements   -->
<!-- to the source.  If new code results in undefined, or          -->
<!-- recursively defined, variables, this discussion may be        -->
<!-- relevant.  (This is repeated verbatim in the other            -->
<!-- stylesheet).                                                  -->

<!-- ############## -->
<!-- Common Options -->
<!-- ############## -->

<!-- Override chunking publisher variable, for testing -->
<xsl:param name="debug.chunk" select="''"/>

<xsl:variable name="chunks">
    <xsl:choose>
        <!-- debugging tool overrides anything else -->
        <xsl:when test="not($debug.chunk = '')">
            <xsl:value-of select="$debug.chunk"/>
        </xsl:when>
        <!-- consult publisher file -->
        <xsl:when test="$publication/common/chunking/@level">
            <xsl:value-of select="$publication/common/chunking/@level"/>
        </xsl:when>
        <!-- respect legacy string parameter -->
        <xsl:when test="not($chunk.level = '')">
            <xsl:value-of select="$chunk.level"/>
        </xsl:when>
    </xsl:choose>
</xsl:variable>
<!-- We do not convert this to a number since various   -->
<!-- conversions will consume this and produce their    -->
<!-- own defaults, and we need to recognize "no choice" -->
<!-- as an empty string -->
<xsl:variable name="chunk-level-entered" select="string($chunks)"/>

<!-- A book must have a chapter              -->
<!-- An article need not have a section      -->
<!-- This gets replaced in -latex stylehseet -->
<xsl:variable name="toc-level-entered">
    <xsl:choose>
        <xsl:when test="$publication/common/tableofcontents/@level">
            <xsl:value-of select="$publication/common/tableofcontents/@level"/>
        </xsl:when>
        <!-- legacy, respect string parameter -->
        <xsl:when test="$toc.level != ''">
            <xsl:value-of select="$toc.level" />
        </xsl:when>
        <!-- defaults purely by structure, not by output format -->
        <xsl:when test="$assembly-root/book/part/chapter/section">3</xsl:when>
        <xsl:when test="$assembly-root/book/part/chapter">2</xsl:when>
        <xsl:when test="$assembly-root/book/chapter/section">2</xsl:when>
        <xsl:when test="$assembly-root/book/chapter">1</xsl:when>
        <xsl:when test="$assembly-root/article/section/subsection">2</xsl:when>
        <xsl:when test="$assembly-root/article/section|$assembly-root/article/worksheet">1</xsl:when>
        <xsl:when test="$assembly-root/article">0</xsl:when>
        <xsl:when test="$assembly-root/slideshow">0</xsl:when>
        <xsl:when test="$assembly-root/letter">0</xsl:when>
        <xsl:when test="$assembly-root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Table of Contents level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="toc-level" select="number($toc-level-entered)"/>

<!-- Flag Table of Contents, or not, with boolean variable -->
<xsl:variable name="b-has-toc" select="$toc-level > 0" />

<!-- ########################### -->
<!-- Exercise component switches -->
<!-- ########################### -->

<!-- We santitize exercise component switches.  These control -->
<!-- text/narrative appearances *only*, solution lists in the -->
<!-- backmatter are given in alternate ways.  However, an     -->
<!-- alternate conversion (such as an Instructor's Guide) may -->
<!-- use these as well. We only do quality control here.      -->
<!-- The first "*.text.*" forms are deprecated with warnings  -->
<!-- elsewhere, but we try to preserve their intent here.     -->
<!-- The second "exercise.{type}.{component}" also have       -->
<!-- deprecation warnings elsewhere, and are honored here.    -->
<!-- NB: "-statement" versions are necessary for the solution -->
<!-- manual stylesheet, which feeds these into the solutions  -->
<!-- generator template.                                      -->

<xsl:variable name="entered-exercise-inline-statement">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-inline/@statement">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-inline/@statement = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-inline/@statement = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-inline/@statement in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-inline/@statement"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.inline.statement = 'yes') or
                        ($exercise.inline.statement = 'no')">
            <xsl:value-of select="$exercise.inline.statement" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.statement = 'yes') or ($exercise.text.statement = 'no')">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.inline.statement = ''">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.inline.statement parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.inline.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-inline-hint">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-inline/@hint">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-inline/@hint = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-inline/@hint = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-inline/@hint in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-inline/@hint"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.inline.hint = 'yes') or
                        ($exercise.inline.hint = 'no')">
            <xsl:value-of select="$exercise.inline.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.hint = 'yes') or ($exercise.text.hint = 'no')">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.inline.hint = ''">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.inline.hint parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.inline.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-inline-answer">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-inline/@answer">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-inline/@answer = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-inline/@answer = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-inline/@answer in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-inline/@answer"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.inline.answer = 'yes') or
                        ($exercise.inline.answer = 'no')">
            <xsl:value-of select="$exercise.inline.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.answer = 'yes') or ($exercise.text.answer = 'no')">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.inline.answer = ''">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.inline.answer parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.inline.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-inline-solution">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-inline/@solution">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-inline/@solution = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-inline/@solution = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-inline/@solution in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-inline/@solution"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.inline.solution = 'yes') or
                        ($exercise.inline.solution = 'no')">
            <xsl:value-of select="$exercise.inline.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.solution = 'yes') or ($exercise.text.solution = 'no')">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.inline.solution = ''">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.inline.solution parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.inline.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-divisional-statement">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-divisional/@statement">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-divisional/@statement = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-divisional/@statement = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-divisional/@statement in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-divisional/@statement"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.divisional.statement = 'yes') or
                        ($exercise.divisional.statement = 'no')">
            <xsl:value-of select="$exercise.divisional.statement" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.statement = 'yes') or ($exercise.text.statement = 'no')">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.divisional.statement = ''">
            <xsl:value-of select="$exercise.divisional.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.divisional.statement parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.divisional.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-divisional-hint">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-divisional/@hint">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-divisional/@hint = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-divisional/@hint = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-divisional/@hint in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-divisional/@hint"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.divisional.hint = 'yes') or
                        ($exercise.divisional.hint = 'no')">
            <xsl:value-of select="$exercise.divisional.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.hint = 'yes') or ($exercise.text.hint = 'no')">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.divisional.hint = ''">
            <xsl:value-of select="$exercise.divisional.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.divisional.hint parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.divisional.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-divisional-answer">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-divisional/@answer">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-divisional/@answer = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-divisional/@answer = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-divisional/@answer in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-divisional/@answer"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.divisional.answer = 'yes') or
                        ($exercise.divisional.answer = 'no')">
            <xsl:value-of select="$exercise.divisional.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.answer = 'yes') or ($exercise.text.answer = 'no')">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.divisional.answer = ''">
            <xsl:value-of select="$exercise.divisional.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.divisional.answer parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.divisional.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-divisional-solution">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-divisional/@solution">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-divisional/@solution = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-divisional/@solution = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-divisional/@solution in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-divisional/@solution"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.divisional.solution = 'yes') or
                        ($exercise.divisional.solution = 'no')">
            <xsl:value-of select="$exercise.divisional.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.solution = 'yes') or ($exercise.text.solution = 'no')">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.divisional.solution = ''">
            <xsl:value-of select="$exercise.divisional.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.divisional.solution parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.divisional.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-worksheet-statement">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-worksheet/@statement">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-worksheet/@statement = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-worksheet/@statement = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-worksheet/@statement in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-worksheet/@statement"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.worksheet.statement = 'yes') or
                        ($exercise.worksheet.statement = 'no')">
            <xsl:value-of select="$exercise.worksheet.statement" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.statement = 'yes') or ($exercise.text.statement = 'no')">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.worksheet.statement = ''">
            <xsl:value-of select="$exercise.worksheet.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.worksheet.statement parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.worksheet.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-worksheet-hint">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-worksheet/@hint">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-worksheet/@hint = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-worksheet/@hint = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-worksheet/@hint in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-worksheet/@hint"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.worksheet.hint = 'yes') or
                        ($exercise.worksheet.hint = 'no')">
            <xsl:value-of select="$exercise.worksheet.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.hint = 'yes') or ($exercise.text.hint = 'no')">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.worksheet.hint = ''">
            <xsl:value-of select="$exercise.worksheet.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.worksheet.hint parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.worksheet.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-worksheet-answer">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-worksheet/@answer">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-worksheet/@answer = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-worksheet/@answer = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-worksheet/@answer in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-worksheet/@answer"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.worksheet.answer = 'yes') or
                        ($exercise.worksheet.answer = 'no')">
            <xsl:value-of select="$exercise.worksheet.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.answer = 'yes') or ($exercise.text.answer = 'no')">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.worksheet.answer = ''">
            <xsl:value-of select="$exercise.worksheet.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.worksheet.answer parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.worksheet.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-worksheet-solution">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-worksheet/@solution">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-worksheet/@solution = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-worksheet/@solution = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-worksheet/@solution in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-worksheet/@solution"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.worksheet.solution = 'yes') or
                        ($exercise.worksheet.solution = 'no')">
            <xsl:value-of select="$exercise.worksheet.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.solution = 'yes') or ($exercise.text.solution = 'no')">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.worksheet.solution = ''">
            <xsl:value-of select="$exercise.worksheet.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.worksheet.solution parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.worksheet.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-reading-statement">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-reading/@statement">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-reading/@statement = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-reading/@statement = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-reading/@statement in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-reading/@statement"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.reading.statement = 'yes') or
                        ($exercise.reading.statement = 'no')">
            <xsl:value-of select="$exercise.reading.statement" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.statement = 'yes') or ($exercise.text.statement = 'no')">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.reading.statement = ''">
            <xsl:value-of select="$exercise.reading.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.reading.statement parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.reading.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-reading-hint">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-reading/@hint">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-reading/@hint = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-reading/@hint = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-reading/@hint in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-reading/@hint"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.reading.hint = 'yes') or
                        ($exercise.reading.hint = 'no')">
            <xsl:value-of select="$exercise.reading.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.hint = 'yes') or ($exercise.text.hint = 'no')">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.reading.hint = ''">
            <xsl:value-of select="$exercise.reading.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.reading.hint parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.reading.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-reading-answer">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-reading/@answer">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-reading/@answer = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-reading/@answer = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-reading/@answer in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-reading/@answer"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.reading.answer = 'yes') or
                        ($exercise.reading.answer = 'no')">
            <xsl:value-of select="$exercise.reading.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.answer = 'yes') or ($exercise.text.answer = 'no')">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.reading.answer = ''">
            <xsl:value-of select="$exercise.reading.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.reading.answer parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.reading.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-reading-solution">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-reading/@solution">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-reading/@solution = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-reading/@solution = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-reading/@solution in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-reading/@solution"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($exercise.reading.solution = 'yes') or
                        ($exercise.reading.solution = 'no')">
            <xsl:value-of select="$exercise.reading.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.solution = 'yes') or ($exercise.text.solution = 'no')">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.reading.solution = ''">
            <xsl:value-of select="$exercise.reading.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: exercise.reading.solution parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.reading.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-project-statement">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-project/@statement">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-project/@statement = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-project/@statement = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-project/@statement in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-project/@statement"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($project.statement = 'yes') or
                        ($project.statement = 'no')">
            <xsl:value-of select="$project.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$project.statement = ''">
            <xsl:value-of select="$project.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: project.statement parameter should be "yes" or "no", not "<xsl:value-of select="$project.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-project-hint">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-project/@hint">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-project/@hint = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-project/@hint = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-project/@hint in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-project/@hint"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($project.hint = 'yes') or
                        ($project.hint = 'no')">
            <xsl:value-of select="$project.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($project.text.hint = 'yes') or ($project.text.hint = 'no')">
            <xsl:value-of select="$project.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$project.hint = ''">
            <xsl:value-of select="$project.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: project.hint parameter should be "yes" or "no", not "<xsl:value-of select="$project.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-project-answer">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-project/@answer">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-project/@answer = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-project/@answer = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-project/@answer in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-project/@answer"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($project.answer = 'yes') or
                        ($project.answer = 'no')">
            <xsl:value-of select="$project.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($project.text.answer = 'yes') or ($project.text.answer = 'no')">
            <xsl:value-of select="$project.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$project.answer = ''">
            <xsl:value-of select="$project.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: project.answer parameter should be "yes" or "no", not "<xsl:value-of select="$project.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-project-solution">
    <xsl:choose>
        <xsl:when test="$publication/common/exercise-project/@solution">
            <xsl:choose>
                <xsl:when test="$publication/common/exercise-project/@solution = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/common/exercise-project/@solution = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the exercise component visibility setting (common/exercise-project/@solution in the publisher file) must be "yes" or "no", not "<xsl:value-of select="$publication/common/exercise-project/@solution"/>".  Proceeding with the default, which is "yes".</xsl:message>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- deprecated, but still honored -->
        <xsl:when test="($project.solution = 'yes') or
                        ($project.solution = 'no')">
            <xsl:value-of select="$project.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($project.text.solution = 'yes') or ($project.text.solution = 'no')">
            <xsl:value-of select="$project.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$project.solution = ''">
            <xsl:value-of select="$project.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >PTX:WARNING: project.solution parameter should be "yes" or "no", not "<xsl:value-of select="$project.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- The "entered-*" versions have been sanitized      -->
<!-- to be "yes", "no" or "".  We make and use boolean -->
<!-- switches. Unset, or mis-entered is the default,   -->
<!-- which is to show all components until an author   -->
<!-- decides to hide them.                             -->
<!-- These are used in the solution manual conversion  -->
<xsl:variable name="b-has-inline-statement"
              select="($entered-exercise-inline-statement = 'yes') or ($entered-exercise-inline-statement = '')" />
<xsl:variable name="b-has-inline-hint"
              select="($entered-exercise-inline-hint = 'yes') or ($entered-exercise-inline-hint = '')" />
<xsl:variable name="b-has-inline-answer"
              select="($entered-exercise-inline-answer = 'yes') or ($entered-exercise-inline-answer = '')" />
<xsl:variable name="b-has-inline-solution"
              select="($entered-exercise-inline-solution = 'yes') or ($entered-exercise-inline-solution = '')" />
<xsl:variable name="b-has-divisional-statement"
              select="($entered-exercise-divisional-statement = 'yes') or ($entered-exercise-divisional-statement = '')" />
<xsl:variable name="b-has-divisional-hint"
              select="($entered-exercise-divisional-hint = 'yes') or ($entered-exercise-divisional-hint = '')" />
<xsl:variable name="b-has-divisional-answer"
              select="($entered-exercise-divisional-answer = 'yes') or ($entered-exercise-divisional-answer = '')" />
<xsl:variable name="b-has-divisional-solution"
              select="($entered-exercise-divisional-solution = 'yes') or ($entered-exercise-divisional-solution = '')" />
<xsl:variable name="b-has-worksheet-statement"
              select="($entered-exercise-worksheet-statement = 'yes') or ($entered-exercise-worksheet-statement = '')" />
<xsl:variable name="b-has-worksheet-hint"
              select="($entered-exercise-worksheet-hint = 'yes') or ($entered-exercise-worksheet-hint = '')" />
<xsl:variable name="b-has-worksheet-answer"
              select="($entered-exercise-worksheet-answer = 'yes') or ($entered-exercise-worksheet-answer = '')" />
<xsl:variable name="b-has-worksheet-solution"
              select="($entered-exercise-worksheet-solution = 'yes') or ($entered-exercise-worksheet-solution = '')" />
<xsl:variable name="b-has-reading-statement"
              select="($entered-exercise-reading-statement = 'yes') or ($entered-exercise-reading-statement = '')" />
<xsl:variable name="b-has-reading-hint"
              select="($entered-exercise-reading-hint = 'yes') or ($entered-exercise-reading-hint = '')" />
<xsl:variable name="b-has-reading-answer"
              select="($entered-exercise-reading-answer = 'yes') or ($entered-exercise-reading-answer = '')" />
<xsl:variable name="b-has-reading-solution"
              select="($entered-exercise-reading-solution = 'yes') or ($entered-exercise-reading-solution = '')" />
<xsl:variable name="b-has-project-statement"
              select="($entered-project-statement = 'yes') or ($entered-project-statement = '')" />
<xsl:variable name="b-has-project-hint"
              select="($entered-project-hint = 'yes') or ($entered-project-hint = '')" />
<xsl:variable name="b-has-project-answer"
              select="($entered-project-answer = 'yes') or ($entered-project-answer = '')" />
<xsl:variable name="b-has-project-solution"
              select="($entered-project-solution = 'yes') or ($entered-project-solution = '')" />


<!-- ############## -->
<!-- Source Options -->
<!-- ############## -->

<!-- A directory of images that *are not* generated, or reproducible,     -->
<!-- from an author's source.  Canonical example would be a photograph.   -->
<!-- The directory specified is always a relative path rooted at the      -->
<!-- author's source file containing the "pretext" element (i.e. if       -->
<!-- source is modularized, the "master" or "top-level" file).            -->
<!-- Historically, authors were 100% responsible for this path, so the    -->
<!-- default is empty.  With this publisher file specification, a         -->
<!-- redundance in these paths (a common leading path) may be specified   -->
<!-- once, and source can assume less about the location of these images. -->
<!-- A leading slash is an error, since that'd be an absolute path,       -->
<!-- while a trailing slash will be reliably added if                     -->
<!--     (a) not present in publisher file specification                  -->
<!--     (b) the path is not empty                                        -->
<xsl:variable name="external-directory-source">
    <xsl:variable name="raw-input" select="$publication/source/directories/@external"/>
    <xsl:choose>
        <!-- leading path separator is an error -->
        <xsl:when test="substring($raw-input, 1, 1) = '/'">
            <xsl:message>PTX:ERROR:   an external-image directory (source/directories/@external in the publisher file) must be a relative path and not begin with "/" as in "<xsl:value-of select="$raw-input"/>".  Proceeding with the default, which is an empty string, and may lead to unexpected results.</xsl:message>
            <xsl:text/>
        </xsl:when>
        <!-- trailing path separator is good and -->
        <!-- we know it is not due to simply '/' -->
        <xsl:when test="substring($raw-input, string-length($raw-input), 1) = '/'">
            <xsl:value-of select="$raw-input"/>
        </xsl:when>
        <!-- if there is substance, we need to add a trailing slash -->
        <xsl:when test="string-length($raw-input) > 0">
            <xsl:value-of select="concat($raw-input, '/')"/>
        </xsl:when>
        <!-- specification must be empty, so we leave it that way -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- Historically this was given by the "images" directory as a default, -->
<!-- and it seems almost every author just ran with this.                -->
<xsl:variable name="generated-directory-source">
    <xsl:variable name="raw-input" select="$publication/source/directories/@generated"/>
    <xsl:choose>
        <xsl:when test="$b-managed-directories">
            <xsl:choose>
                <xsl:when test="substring($raw-input, 1, 1) = '/'">
                    <xsl:message>PTX:ERROR:   a generated-image directory (source/directories/@generated in the publisher file) must be a relative path and not begin with "/" as in "<xsl:value-of select="$raw-input"/>".  Proceeding with the default, which is an empty string, and may lead to unexpected results.</xsl:message>
                    <xsl:text/>
                </xsl:when>
                <!-- trailing path separator is good -->
                <xsl:when test="substring($raw-input, string-length($raw-input), 1) = '/'">
                    <xsl:value-of select="$raw-input"/>
                </xsl:when>
                <!-- if there is substance, we need to add a trailing slash -->
                <xsl:when test="string-length($raw-input) > 0">
                    <xsl:value-of select="concat($raw-input, '/')"/>
                </xsl:when>
                <!-- specification must be empty, so we leave it that way -->
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:when>
        <!-- Should issue a deprecation warning (elsewhere) for this.    -->
        <!-- directory.images *is* defined elsewhere in this stylesheet, -->
        <!-- and defaults to "images", but does not have a slash, which  -->
        <!-- is presumed for the $generated-directory variable           -->
        <xsl:otherwise>
            <xsl:value-of select="concat($directory.images, '/')"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- For backward-compatibility, we want to know if the collection of  -->
<!-- generated images is structured by their production method (newer) -->
<!-- or not (older, historical).  So we create a boolean based on the  -->
<!-- presence of the publisher file specification.                     -->
<xsl:variable name="managed-directories">
    <xsl:if test="$publication/source/directories/@external = ''">
        <xsl:message terminate="yes">PTX:ERROR:   the value of source/directories/@external in the publisher file must be nonempty</xsl:message>
    </xsl:if>
    <xsl:if test="$publication/source/directories/@generated = ''">
        <xsl:message terminate="yes">PTX:ERROR:   the value of source/directories/@generated in the publisher file must be nonempty</xsl:message>
    </xsl:if>
    <xsl:choose>
        <xsl:when test="$publication/source/directories/@external and $publication/source/directories/@generated">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="not($publication/source/directories/@external) and not($publication/source/directories/@generated)">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR:   the publisher file specifies one of source/directories/@external and source/directories/@generated, but not both. Proceeding as if neither was specified.</xsl:message>
            <xsl:text>no</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-managed-directories" select="$managed-directories = 'yes'"/>

<!-- Destination directory is hard-coded here and used in      -->
<!-- various conversions under the managed directories scheme. -->
<xsl:variable name="external-directory">
    <xsl:choose>
        <xsl:when test="$b-managed-directories">
            <xsl:text>external/</xsl:text>
        </xsl:when>
        <!-- backwards-compatiblity, there never was any sort of   -->
        <!-- naming/copying scheme for externally produced content -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- There was once a scheme of sorts for managing the directory -->
<!-- where generated images landed and were found.  So we need   -->
<!-- to preserve that logic for backward-compatibility.          -->
<xsl:variable name="generated-directory">
    <xsl:choose>
        <xsl:when test="$b-managed-directories">
            <xsl:value-of select="'generated/'"/>
        </xsl:when>
        <!-- Should issue a deprecation warning (elsewhere) for this.    -->
        <!-- directory.images *is* defined elsewhere in this stylesheet, -->
        <!-- and defaults to "images", but does not have a slash, which  -->
        <!-- is presumed for the $generated-directory variable           -->
        <xsl:otherwise>
            <xsl:value-of select="concat($directory.images, '/')"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>


<!-- This is a directory that may need to be copied to a      -->
<!-- scratch location in anticipation of data files necessary -->
<!-- for compilation of images, such as pie charts or plots   -->
<!-- NB: this is broken and waiting for generated and external to settle down -->
<xsl:variable name="data-directory">
    <xsl:variable name="raw-input">
        <xsl:choose>
            <xsl:when test="$publication/source/directories/@data">
                <xsl:value-of select="'data'"/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="substring($raw-input, 1, 1) = '/'">
            <xsl:message>PTX:ERROR:   a data directory (source/directories/@data in the publisher file) must be a relative path and not begin with "/" as in "<xsl:value-of select="$raw-input"/>".  Proceeding with the default, which is an empty string, and may lead to unexpected results.</xsl:message>
            <xsl:text/>
        </xsl:when>
        <!-- trailing path separator is good -->
        <xsl:when test="substring($raw-input, string-length($raw-input), 1) = '/'">
            <xsl:value-of select="$raw-input"/>
        </xsl:when>
        <!-- if there is substance, we need to add a trailing slash -->
        <xsl:when test="string-length($raw-input) > 0">
            <xsl:value-of select="concat($raw-input, '/')"/>
        </xsl:when>
        <!-- specification must be empty, so we leave it that way -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- ###################### -->
<!-- Filenames for Assembly -->
<!-- ###################### -->

<!-- These are auxiliary files provided by authors and publishers, -->
<!-- generally for derived versions of a project.  Their use can   -->
<!-- be found in the  pretext-assembly.xsl  file.                  -->
<!--                                                               -->
<!-- NB  Generally these files are given as relative paths to a    -->
<!-- project's source file and the  document()  function will      -->
<!-- locate them as such.  So absolute paths gaining "extra"       -->
<!-- directories with spaces is not as much of a concern as with   -->
<!-- the publisher file (see above).  But an author or publisher   -->
<!-- can still place these files' names into an attribute of the   -->
<!-- publisher file using a space.  This will cause the            -->
<!-- document()  function to fail silently. The location provided  -->
<!-- in the first argument of document() is a URI, so the proper   -->
<!-- escape mechanism is percent-encoding.                         -->


<!-- A file of hint|answer|solution, with @ref back to "exercise" -->
<!-- so that the solutions can see limited distribution.  No real -->
<!-- error-checking.  If not set/present, then an empty string    -->

<xsl:variable name="private-solutions-file">
    <xsl:choose>
        <xsl:when test="$publication/source/@private-solutions">
            <xsl:value-of select="str:replace($publication/source/@private-solutions, '&#x20;', '%20')"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- WeBWork problem representations are formed by the           -->
<!-- pretext/pretext script communicating with a WeBWorK server. -->
<xsl:variable name="webwork-representations-file">
    <xsl:choose>
        <!-- XSLT should skip the second condition below if the first is false (boosts efficiency). -->
        <xsl:when test="$generated-directory-source != '' and $original//webwork[*|@*]">
            <xsl:value-of select="str:replace(concat($generated-directory-source, 'webwork/webwork-representations.xml'), '&#x20;', '%20')"/>
        </xsl:when>
        <xsl:when test="$publication/source/@webwork-problems">
            <xsl:value-of select="str:replace($publication/source/@webwork-problems, '&#x20;', '%20')"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- File of  custom/@name  elements, whose content is a custom -->
<!-- replacement for a corresponding  custom/@ref  element in   -->
<!-- the source.                                                -->
<xsl:variable name="customizations-file">
    <xsl:choose>
        <xsl:when test="$publication/source/@customizations">
            <xsl:value-of select="str:replace($publication/source/@customizations, '&#x20;', '%20')"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- ################## -->
<!-- Version Components -->
<!-- ################## -->


<!-- A version may be specified as a list of components.  We "fence" -->
<!-- the list so as to make matching a single component in the list  -->
<!-- more reliable (don't match substrings).  A totally empty string -->
<!-- means it has not been set.                                      -->
<!-- N.B. tokenize() and string+node-set matching might be better    -->
<xsl:variable name="components-fenced">
    <xsl:choose>
        <xsl:when test="$publication/source/version/@include">
            <xsl:value-of select="concat('|', translate(normalize-space($publication/source/version/@include), ' ', '|'), '|')"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>


<!-- ######### -->
<!-- Numbering -->
<!-- ######### -->


<!-- User-supplied Numbering for Maximum Level     -->
<!-- Respect switch, or provide sensible defaults  -->
<!-- NB: level number counts the number of         -->
<!-- separators (periods) present once qualified   -->
<!-- with a numbered item contained within         -->
<!-- NB: If we were to allow multiple (hence       -->
<!-- numbered) specialized divisions of a          -->
<!-- "subsubsection", then the non-zero maximums   -->
<!-- below would go up by 1                        -->
<!--   article/section: s.ss.sss => 3              -->
<!--   book:            c.s.ss.sss => 4            -->
<!--   book/part:       p.c.s.ss.sss => 5          -->
<xsl:variable name="numbering-maxlevel-entered">
    <!-- these are the maximum possible for a given document type -->
    <!-- the default, and also an error-check upper-limit         -->
    <xsl:variable name="max-feasible">
        <xsl:choose>
            <xsl:when test="$assembly-root/book/part">5</xsl:when>
            <xsl:when test="$assembly-root/book">4</xsl:when>
            <xsl:when test="$assembly-root/article/section|$assembly-root/article/worksheet">3</xsl:when>
            <xsl:when test="$assembly-root/article">0</xsl:when>
            <xsl:when test="$assembly-root/letter">0</xsl:when>
            <xsl:when test="$assembly-root/slideshow">0</xsl:when>
            <xsl:when test="$assembly-root/memo">0</xsl:when>
            <xsl:otherwise>
                <xsl:message>PTX:BUG: a document type needs a maximum division level defined</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="candidate-maxlevel">
        <xsl:choose>
            <!-- go with publisher file, check for numerical value -->
            <xsl:when test="$publication/numbering/divisions/@level">
                <xsl:variable name="the-number" select="$publication/numbering/divisions/@level"/>
                <xsl:choose>
                    <!-- NaN does not equal *anything*, so tests if a number -->
                    <xsl:when test="not(number($the-number) = number($the-number)) or ($the-number &lt; 0)">
                        <xsl:message>PTX:ERROR:   numbering level for divisions given in the publisher file ("<xsl:value-of select="$the-number"/>") is not a number or is negative.  The default value will be used instead</xsl:message>
                        <xsl:value-of select="$max-feasible"/>
                        </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$publication/numbering/divisions/@level"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- respect deprecated analog -->
            <xsl:when test="not($numbering.maximum.level = '')">
                <xsl:value-of select="$numbering.maximum.level" />
            </xsl:when>
            <!-- various defaults are the maximum possible -->
            <xsl:otherwise>
                <xsl:value-of select="$max-feasible"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- check $candidate against upper bound, $max-feasible -->
    <xsl:choose>
        <xsl:when test="$candidate-maxlevel > $max-feasible">
            <xsl:message>PTX:ERROR:   numbering level set for divisions ("<xsl:value-of select="$candidate-maxlevel"/>") is greater than the maximum possible ("<xsl:value-of select="$max-feasible"/>") for this document type.  The default value will be used instead</xsl:message>
            <xsl:value-of select="$max-feasible"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$candidate-maxlevel"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="numbering-maxlevel" select="number($numbering-maxlevel-entered)"/>

<!-- TODO: next five variables have wildly similar structure,  -->
<!-- and could best be created/defined with a single template, -->
<!-- parameterized by (a) publisher file entry, (b) old        -->
<!-- deprecated stringparam (or docinfo coming soon),          -->
<!-- (c) string for messages (e.g. "footnotes").               -->
<!-- EZ: make one "default" variable, since they all look identical -->

<!-- User-supplied Numbering for Theorems, etc    -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-blocks-entered">
    <xsl:variable name="default-blocks">
        <xsl:choose>
            <xsl:when test="$assembly-root/book/part">3</xsl:when>
            <xsl:when test="$assembly-root/book">2</xsl:when>
            <xsl:when test="$assembly-root/article/section|$assembly-root/article/worksheet">1</xsl:when>
            <xsl:when test="$assembly-root/article">0</xsl:when>
            <xsl:when test="$assembly-root/slideshow">0</xsl:when>
            <xsl:when test="$assembly-root/letter">0</xsl:when>
            <xsl:when test="$assembly-root/memo">0</xsl:when>
            <xsl:otherwise>
                <xsl:message>PTX:BUG: a document type needs a default block numbering level defined</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="candidate-blocks">
        <xsl:choose>
            <!-- go with publisher file, check for numerical value -->
            <xsl:when test="$publication/numbering/blocks/@level">
                <xsl:variable name="the-number" select="$publication/numbering/blocks/@level"/>
                <xsl:choose>
                    <!-- NaN does not equal *anything*, so tests if a number -->
                    <xsl:when test="not(number($the-number) = number($the-number)) or ($the-number &lt; 0)">
                        <xsl:message>PTX:ERROR:   numbering level for blocks given in the publisher file ("<xsl:value-of select="$the-number"/>") is not a number or is negative.  The default value will be used instead</xsl:message>
                        <xsl:value-of select="$default-blocks"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$publication/numbering/blocks/@level"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- respect deprecated analog -->
            <xsl:when test="$numbering.theorems.level != ''">
                <xsl:value-of select="$numbering.theorems.level" />
            </xsl:when>
            <!-- use a default -->
            <xsl:otherwise>
                <xsl:value-of select="$default-blocks"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- check $candidate-blocks against upper bound, $numbering-maxlevel -->
    <xsl:choose>
        <xsl:when test="$candidate-blocks > $numbering-maxlevel">
            <xsl:message>PTX:ERROR:   numbering level set for blocks ("<xsl:value-of select="$candidate-blocks"/>") is greater than the maximum possible levels ("<xsl:value-of select="$numbering-maxlevel"/>") configured.  The default value will be used instead</xsl:message>
            <xsl:value-of select="$default-blocks"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$candidate-blocks"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="numbering-blocks" select="number($numbering-blocks-entered)"/>

<!-- User-supplied Numbering for Projects, etc    -->
<!-- Respect switch, or provide sensible defaults -->
<!-- PROJECT-LIKE -->
<!-- NB: this should become elective, more like the -->
<!-- schemes for inline exercises and figure-like.  -->
<xsl:variable name="numbering-projects-entered">
    <xsl:variable name="default-projects">
        <xsl:choose>
            <xsl:when test="$assembly-root/book/part">3</xsl:when>
            <xsl:when test="$assembly-root/book">2</xsl:when>
            <xsl:when test="$assembly-root/article/section|$assembly-root/article/worksheet">1</xsl:when>
            <xsl:when test="$assembly-root/article">0</xsl:when>
            <xsl:when test="$assembly-root/slideshow">0</xsl:when>
            <xsl:when test="$assembly-root/letter">0</xsl:when>
            <xsl:when test="$assembly-root/memo">0</xsl:when>
            <xsl:otherwise>
                <xsl:message>PTX:BUG: a document type needs a default project level defined</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="candidate-projects">
        <xsl:choose>
            <!-- go with publisher file, check for numerical value -->
            <xsl:when test="$publication/numbering/projects/@level">
                <xsl:variable name="the-number" select="$publication/numbering/projects/@level"/>
                <xsl:choose>
                    <!-- NaN does not equal *anything*, so tests if a number -->
                    <xsl:when test="not(number($the-number) = number($the-number)) or ($the-number &lt; 0)">
                        <xsl:message>PTX:ERROR:   numbering level for projects given in the publisher file ("<xsl:value-of select="$the-number"/>") is not a number or is negative.  The default value will be used instead</xsl:message>
                        <xsl:value-of select="$default-projects"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$publication/numbering/projects/@level"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- respect deprecated analog -->
            <xsl:when test="$numbering.projects.level != ''">
                <xsl:value-of select="$numbering.projects.level" />
            </xsl:when>
            <!-- use a default -->
            <xsl:otherwise>
                <xsl:value-of select="$default-projects"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- check $candidate-projects against upper bound, $numbering-maxlevel -->
    <xsl:choose>
        <xsl:when test="$candidate-projects > $numbering-maxlevel">
            <xsl:message>PTX:ERROR:   numbering level set for projects ("<xsl:value-of select="$candidate-projects"/>") is greater than the maximum possible levels ("<xsl:value-of select="$numbering-maxlevel"/>") configured.  The default value will be used instead</xsl:message>
            <xsl:value-of select="$default-projects"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$candidate-projects"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="numbering-projects" select="number($numbering-projects-entered)"/>

<!-- User-supplied Numbering for Equations        -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-equations-entered">
    <xsl:variable name="default-equations">
        <xsl:choose>
            <xsl:when test="$assembly-root/book/part">3</xsl:when>
            <xsl:when test="$assembly-root/book">2</xsl:when>
            <xsl:when test="$assembly-root/article/section|$assembly-root/article/worksheet">1</xsl:when>
            <xsl:when test="$assembly-root/article">0</xsl:when>
            <xsl:when test="$assembly-root/slideshow">0</xsl:when>
            <xsl:when test="$assembly-root/letter">0</xsl:when>
            <xsl:when test="$assembly-root/memo">0</xsl:when>
            <xsl:otherwise>
                <xsl:message>PTX:BUG: a document type needs a default equation project level defined</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="candidate-equations">
        <xsl:choose>
            <!-- go with publisher file, check for numerical value -->
            <xsl:when test="$publication/numbering/equations/@level">
                <xsl:variable name="the-number" select="$publication/numbering/equations/@level"/>
                <xsl:choose>
                    <!-- NaN does not equal *anything*, so tests if a number -->
                    <xsl:when test="not(number($the-number) = number($the-number)) or ($the-number &lt; 0)">
                        <xsl:message>PTX:ERROR:   numbering level for equations given in the publisher file ("<xsl:value-of select="$the-number"/>") is not a number or is negative.  The default value will be used instead</xsl:message>
                        <xsl:value-of select="$default-equations"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$publication/numbering/equations/@level"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- respect deprecated analog -->
            <xsl:when test="$numbering.equations.level != ''">
                <xsl:value-of select="$numbering.equations.level" />
            </xsl:when>
            <!-- use a default -->
            <xsl:otherwise>
                <xsl:value-of select="$default-equations"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- check $candidate-equations against upper bound, $numbering-maxlevel -->
    <xsl:choose>
        <xsl:when test="$candidate-equations > $numbering-maxlevel">
            <xsl:message>PTX:ERROR:   numbering level set for equations ("<xsl:value-of select="$candidate-equations"/>") is greater than the maximum possible levels ("<xsl:value-of select="$numbering-maxlevel"/>") configured.  The default value will be used instead</xsl:message>
            <xsl:value-of select="$default-equations"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$candidate-equations"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="numbering-equations" select="number($numbering-equations-entered)"/>

<!-- User-supplied Numbering for Footnotes        -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-footnotes-entered">
    <xsl:variable name="default-footnotes">
        <xsl:choose>
            <xsl:when test="$assembly-root/book/part">3</xsl:when>
            <xsl:when test="$assembly-root/book">2</xsl:when>
            <xsl:when test="$assembly-root/article/section|$assembly-root/article/worksheet">1</xsl:when>
            <xsl:when test="$assembly-root/article">0</xsl:when>
            <xsl:when test="$assembly-root/slideshow">0</xsl:when>
            <xsl:when test="$assembly-root/letter">0</xsl:when>
            <xsl:when test="$assembly-root/memo">0</xsl:when>
            <xsl:otherwise>
                <xsl:message>PTX:BUG: a document type needs a default footnote project level defined</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="candidate-footnotes">
        <xsl:choose>
            <!-- go with publisher file, check for numerical value -->
            <xsl:when test="$publication/numbering/footnotes/@level">
                <xsl:variable name="the-number" select="$publication/numbering/footnotes/@level"/>
                <xsl:choose>
                    <!-- NaN does not equal *anything*, so tests if a number -->
                    <xsl:when test="not(number($the-number) = number($the-number)) or ($the-number &lt; 0)">
                        <xsl:message>PTX:ERROR:   numbering level for footnotes given in the publisher file ("<xsl:value-of select="$the-number"/>") is not a number or is negative.  The default value will be used instead</xsl:message>
                        <xsl:value-of select="$default-footnotes"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$publication/numbering/footnotes/@level"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- respect deprecated analog -->
            <xsl:when test="$numbering.footnotes.level != ''">
                <xsl:value-of select="$numbering.footnotes.level" />
            </xsl:when>
            <!-- use a default -->
            <xsl:otherwise>
                <xsl:value-of select="$default-footnotes"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- check $candidate-footnotes against upper bound, $numbering-maxlevel -->
    <xsl:choose>
        <xsl:when test="$candidate-footnotes > $numbering-maxlevel">
            <xsl:message>PTX:ERROR:   numbering level set for footnotes ("<xsl:value-of select="$candidate-footnotes"/>") is greater than the maximum possible levels ("<xsl:value-of select="$numbering-maxlevel"/>") configured.  The default value will be used instead</xsl:message>
            <xsl:value-of select="$default-footnotes"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$candidate-footnotes"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="numbering-footnotes" select="number($numbering-footnotes-entered)"/>

<xsl:variable name="chapter-start-entered">
    <xsl:choose>
        <xsl:when test="$publication/numbering/divisions/@chapter-start">
            <xsl:variable name="the-number" select="$publication/numbering/divisions/@chapter-start"/>
            <xsl:choose>
                <!-- NaN does not equal *anything*, so tests if a number -->
                <xsl:when test="not(number($the-number) = number($the-number)) or ($the-number &lt; 0)">
                    <xsl:message>PTX:ERROR:   starting number for chapters given in the publisher file ("<xsl:value-of select="$the-number"/>") is not a number or is negative.  The default value will be used instead</xsl:message>
                    <xsl:value-of select="1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$publication/numbering/divisions/@chapter-start"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- default if not specified -->
        <xsl:otherwise>
            <xsl:value-of select="1"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="chapter-start" select="number($chapter-start-entered)"/>

<!-- Status quo, for no-part books and articles is "absent".     -->
<!-- The "structural" option will change numbers and numbering   -->
<!-- substantially.  The "decorative" option is the default for  -->
<!-- books with parts, and it looks just like the LaTeX default. -->
<xsl:variable name="parts">
    <xsl:choose>
        <!-- no parts, just record as absent,  -->
        <!-- but warn of ill-advised attempts  -->
        <xsl:when test="not($assembly-root/book/part)">
            <xsl:choose>
                <xsl:when test="$publication/numbering/divisions/@part-structure">
                    <xsl:message>PTX:WARNING: your document is not a book with parts, so the publisher file  numbering/divisions/@part-structure  entry is being ignored</xsl:message>
                </xsl:when>
                <xsl:when test="$assembly-docinfo/numbering/division/@part">
                    <xsl:message>PTX:WARNING: your document is not a book with parts, and docinfo/numbering/division/@part is deprecated anyway and is being ignored</xsl:message>
                </xsl:when>
            </xsl:choose>
            <!-- flag this situation -->
            <xsl:text>absent</xsl:text>
        </xsl:when>
        <!-- now we have parts to deal with -->
        <!-- first via publisher file       -->
        <xsl:when test="$publication/numbering/divisions/@part-structure">
            <xsl:choose>
                <xsl:when test="$publication/numbering/divisions/@part-structure = 'structural'">
                    <xsl:text>structural</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/numbering/divisions/@part-structure = 'decorative'">
                    <xsl:text>decorative</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: the publisher file  numbering/divisions/@part-structure  entry should be "decorative" or "structural", not "<xsl:value-of select="$publication/numbering/divisions/@part-structure" />".  The default will be used instead.</xsl:message>
                    <xsl:text>decorative</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- Preserve much of old behavior, warning is elsewhere -->
        <xsl:when test="$assembly-docinfo/numbering/division/@part">
            <xsl:choose>
                <xsl:when test="$assembly-docinfo/numbering/division/@part = 'structural'">
                    <xsl:text>structural</xsl:text>
                </xsl:when>
                <xsl:when test="$assembly-docinfo/numbering/division/@part = 'decorative'">
                    <xsl:text>decorative</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: the  docinfo/numbering/division/@part  entry should be "decorative" or "structural", not "<xsl:value-of select="$assembly-docinfo/numbering/division/@part"/>".  The default will be used instead.</xsl:message>
                    <xsl:text>decorative</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- no specification, use default -->
        <xsl:otherwise>
            <xsl:text>decorative</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- ##################### -->
<!-- HTML-Specific Options -->
<!-- ##################### -->

<!-- Calculator -->
<!-- Possible values are geogebra-classic, geogebra-graphing -->
<!-- geogebra-geometry, geogebra-3d                          -->
<!-- Default is empty, meaning the calculator is not wanted. -->
<xsl:variable name="html-calculator">
    <xsl:choose>
        <xsl:when test="$publication/html/calculator/@model = 'none'">
            <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/calculator/@model = 'geogebra-classic'">
            <xsl:text>geogebra-classic</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/calculator/@model = 'geogebra-graphing'">
            <xsl:text>geogebra-graphing</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/calculator/@model = 'geogebra-geometry'">
            <xsl:text>geogebra-geometry</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/calculator/@model = 'geogebra-3d'">
            <xsl:text>geogebra-3d</xsl:text>
        </xsl:when>
        <!-- an attempt was made, but failed to be correct -->
        <xsl:when test="$publication/html/calculator/@model">
            <xsl:message>PTX:WARNING: HTML calculator/@model in publisher file should be "geogebra-classic", "geogebra-graphing", "geogebra-geometry", "geogebra-3d", or "none", not "<xsl:value-of select="$publication/html/calculator/@model"/>". Proceeding with default value: "none"</xsl:message>
            <xsl:text>none</xsl:text>
        </xsl:when>
        <!-- or maybe the deprecated string parameter was used, as evidenced -->
        <!-- by being non-empty, so we'll just run with it like in the past  -->
        <xsl:when test="not($html.calculator = '')">
            <xsl:value-of select="$html.calculator"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>none</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="b-has-calculator" select="not($html-calculator = 'none')" />


<!--                          -->
<!-- HTML Index Page Redirect -->
<!--                          -->

<!-- A generic "index.html" page will be built to redirect to an        -->
<!-- existing page from the HTML build/chunking.  Here we simply        -->
<!-- record the @xml:id present in the publication file and error-check -->
<!-- the ref.  The processing and decisions about defaults, etc. are    -->
<!-- delegated to the HTML conversion since it relies on chunk level    -->
<!-- and associated routines (which may not be available in some other  -->
<!-- conversion which imports this stylesheet).                         -->

<xsl:variable name="html-index-page-entered-ref">
    <!-- needs to be realized as a *string*, not a node -->
    <xsl:variable name="entered-ref" select="string($publication/html/index-page/@ref)"/>
    <xsl:choose>
        <!-- signal no choice with empty string-->
        <xsl:when test="$entered-ref = ''">
            <xsl:text/>
        </xsl:when>
        <!-- bad choice, set to empty string -->
        <xsl:when test="not(id($entered-ref))">
            <xsl:message>PTX:WARNING:   the requested HTML index page cannot be constructed since "<xsl:value-of select="$entered-ref"/>" is not an @xml:id anywhere in the document.  Defaults will be used instead</xsl:message>
            <xsl:text/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$entered-ref"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!--                   -->
<!-- HTML Knowlization -->
<!--                   -->

<!-- A multitude of switches to control whether various HTML "blocks"      -->
<!-- are born hidden as knowls.  Most names of resulting variables are     -->
<!-- self-explanatory, the ones for exercises come in different varities.  -->
<!-- Each template here ALWAYS produces "yes" or "no".  We do not make     -->
<!-- boolean variables, since these are consumed (exclusively) in modal    -->
<!-- "is-hidden" templates that produce string "true" or "false"           -->
<!-- (respectively).  Some HTML-based conversions cannot accomodate knowls -->
<!-- (EPUB, braille) so we turn off the "is-hidden" templates rather       -->
<!-- than override these variables.                                        -->

<xsl:variable name="knowl-theorem">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@theorem">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@theorem = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@theorem = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "theorem" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@theorem"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.theorem = '')">
            <xsl:value-of select="$html.knowl.theorem"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-proof">
    <xsl:variable name="knowl-default" select="'yes'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@proof">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@proof = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@proof = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "proof" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@proof"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.proof = '')">
            <xsl:value-of select="$html.knowl.proof"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-definition">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@definition">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@definition = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@definition = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "definition" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@definition"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.definition = '')">
            <xsl:value-of select="$html.knowl.definition"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-example">
    <xsl:variable name="knowl-default" select="'yes'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@example">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@example = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@example = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "example" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@example"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.example = '')">
            <xsl:value-of select="$html.knowl.example"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-example-solution">
    <xsl:variable name="knowl-default" select="'yes'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@example-solution">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@example-solution = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@example-solution = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "example-solution" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@example-solution"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-project">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@project">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@project = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@project = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "project" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@project"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.project = '')">
            <xsl:value-of select="$html.knowl.project"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-task">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@task">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@task = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@task = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "task" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@task"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.task = '')">
            <xsl:value-of select="$html.knowl.task"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-list">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@list">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@list = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@list = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "list" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@list"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.list = '')">
            <xsl:value-of select="$html.knowl.list"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-remark">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@remark">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@remark = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@remark = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "remark" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@remark"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.remark = '')">
            <xsl:value-of select="$html.knowl.remark"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-objectives">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@objectives">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@objectives = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@objectives = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "objectives" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@objectives"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.objectives = '')">
            <xsl:value-of select="$html.knowl.objectives"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-outcomes">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@outcomes">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@outcomes = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@outcomes = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "outcomes" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@outcomes"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.outcomes = '')">
            <xsl:value-of select="$html.knowl.outcomes"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-figure">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@figure">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@figure = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@figure = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "figure" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@figure"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.figure = '')">
            <xsl:value-of select="$html.knowl.figure"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-table">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@table">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@table = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@table = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "table" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@table"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.table = '')">
            <xsl:value-of select="$html.knowl.table"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-listing">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@listing">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@listing = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@listing = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "listing" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@listing"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.listing = '')">
            <xsl:value-of select="$html.knowl.listing"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-exercise-inline">
    <xsl:variable name="knowl-default" select="'yes'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@exercise-inline">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@exercise-inline = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@exercise-inline = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "exercise-inline" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@exercise-inline"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.exercise.inline = '')">
            <xsl:value-of select="$html.knowl.exercise.inline"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-exercise-divisional">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@exercise-divisional">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@exercise-divisional = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@exercise-divisional = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "exercise-divisional" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@exercise-divisional"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.exercise.sectional = '')">
            <xsl:value-of select="$html.knowl.exercise.sectional"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-exercise-worksheet">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@exercise-worksheet">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@exercise-worksheet = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@exercise-worksheet = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "exercise-worksheet" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@exercise-worksheet"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.exercise.worksheet = '')">
            <xsl:value-of select="$html.knowl.exercise.worksheet"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="knowl-exercise-readingquestion">
    <xsl:variable name="knowl-default" select="'no'"/>
    <xsl:choose>
        <!-- observe publisher switch first -->
        <xsl:when test="$publication/html/knowl/@exercise-readingquestion">
            <xsl:choose>
                <xsl:when test="$publication/html/knowl/@exercise-readingquestion = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/html/knowl/@exercise-readingquestion = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML knowl-ization switch for "exercise-readingquestion" in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/knowl/@exercise-readingquestion"/>". Proceeding with default value: "<xsl:value-of select="$knowl-default"/>"</xsl:message>
                    <xsl:value-of select="$knowl-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- legacy behavior with old-style string parameter, deprecation  -->
        <!-- elsewhere, accept whatever, as before, i.e. no error-checking -->
        <xsl:when test="not($html.knowl.exercise.readingquestion = '')">
            <xsl:value-of select="$html.knowl.exercise.readingquestion"/>
        </xsl:when>
        <!-- no attempt to set/manipulate, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$knowl-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>


<!--               -->
<!-- HTML Base URL -->
<!--               -->

<!-- This is used to build/reference standalone pages.    -->
<!-- Specified as a property of the HTML conversion, it   -->
<!-- actually gets used in the LaTeX conversion to form   -->
<!-- QR codes and make links to HTML versions of          -->
<!-- Asymptote figures.                                   -->
<!-- NB: We add a trailing slash, if not authored already -->
<xsl:variable name="baseurl">
    <xsl:variable name="raw-input">
        <xsl:choose>
            <!-- if publisher file has a base url, use it -->
            <xsl:when test="$publication/html/baseurl/@href">
                <xsl:value-of select="$publication/html/baseurl/@href"/>
            </xsl:when>
            <!-- reluctantly query the old docinfo version -->
            <xsl:when test="$assembly-docinfo/html/baseurl/@href">
                <xsl:value-of select="$assembly-docinfo/html/baseurl/@href"/>
            </xsl:when>
            <!-- otherwise use the default, is empty as sentinel -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$raw-input =''"/>
        <xsl:otherwise>
            <xsl:value-of select="$raw-input"/>
            <xsl:if test="not(substring($raw-input, string-length($raw-input), 1) = '/')">
                <xsl:text>/</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!--                              -->
<!-- HTML CSS Style Specification -->
<!--                              -->

<!-- Remain for testing purposes -->
<xsl:param name="html.css.colorfile" select="''" />
<xsl:param name="html.css.stylefile" select="''" />
<!-- A temporary variable for testing -->
<xsl:param name="debug.colors" select="''"/>
<!-- A space-separated list of CSS URLs (points to servers or local files) -->
<xsl:param name="html.css.extra"  select="''" />
<!-- A single JS file for development purposes -->
<xsl:param name="html.js.extra" select="''" />

<xsl:variable name="html-css-colorfile">
    <xsl:choose>
        <!-- 2019-05-29: override with new files, no error-checking    -->
        <!-- if not used, then previous scheme is employed identically -->
        <!-- 2019-08-12: this is current scheme, so used first. -->
        <!-- To be replaced with publisher file option.         -->
        <xsl:when test="not($debug.colors = '')">
            <xsl:text>colors_</xsl:text>
            <xsl:value-of select="$debug.colors"/>
            <xsl:text>.css</xsl:text>
        </xsl:when>
        <!-- 2019-12-5: use stringparam specified colorfile is present -->
        <xsl:when test="not($html.css.colorfile = '')">
            <xsl:value-of select="$html.css.colorfile"/>
        </xsl:when>
        <!-- 2019-12-5: if publisher.xml file has colors value, use it -->
        <xsl:when test="$publication/html/css/@colors">
            <xsl:text>colors_</xsl:text>
            <xsl:value-of select="$publication/html/css/@colors"/>
            <xsl:text>.css</xsl:text>
        </xsl:when>
        <!-- Otherwise use the new default.  -->
        <xsl:otherwise>
            <xsl:text>colors_default.css</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- 2019-11-24: this selects the style_default            -->
<!-- unless there is a style specified in a publisher.xml  -->
<!-- file or as a string-param. (OL)                       -->
<xsl:variable name="html-css-stylefile">
    <xsl:choose>
        <!-- if string-param is set, use it (highest priority) -->
        <xsl:when test="not($html.css.stylefile = '')">
            <xsl:value-of select="$html.css.stylefile"/>
        </xsl:when>
        <!-- if publisher.xml file has style value, use it -->
        <xsl:when test="$publication/html/css/@style">
            <xsl:text>style_</xsl:text>
            <xsl:value-of select="$publication/html/css/@style"/>
            <xsl:text>.css</xsl:text>
        </xsl:when>
        <!-- otherwise use the dafault -->
        <xsl:otherwise>
            <xsl:text>style_default.css</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- 2019-12-5: Select pub-file specified css for knowls, -->
<!-- TOC, and banner, or defaults                         -->

<xsl:variable name="html-css-knowlfile">
    <xsl:choose>
        <!-- if publisher.xml file has style value, use it -->
        <xsl:when test="$publication/html/css/@knowls">
            <xsl:text>knowls_</xsl:text>
            <xsl:value-of select="$publication/html/css/@knowls"/>
            <xsl:text>.css</xsl:text>
        </xsl:when>
        <!-- otherwise use the dafault -->
        <xsl:otherwise>
            <xsl:text>knowls_default.css</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="html-css-tocfile">
    <xsl:choose>
        <!-- if publisher.xml file has style value, use it -->
        <xsl:when test="$publication/html/css/@toc">
            <xsl:text>toc_</xsl:text>
            <xsl:value-of select="$publication/html/css/@toc"/>
            <xsl:text>.css</xsl:text>
        </xsl:when>
        <!-- otherwise use the dafault -->
        <xsl:otherwise>
            <xsl:text>toc_default.css</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="html-css-bannerfile">
    <xsl:choose>
        <!-- if publisher.xml file has style value, use it -->
        <xsl:when test="$publication/html/css/@banner">
            <xsl:text>banner_</xsl:text>
            <xsl:value-of select="$publication/html/css/@banner"/>
            <xsl:text>.css</xsl:text>
        </xsl:when>
        <!-- otherwise use the dafault -->
        <xsl:otherwise>
            <xsl:text>banner_default.css</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!--                              -->
<!-- HTML Analytics Configuration -->
<!--                              -->

<!-- String parameters are deprecated, so in -common -->
<!-- file, and are only consulted secondarily here   -->

<xsl:variable name="statcounter-project">
    <xsl:choose>
        <xsl:when test="$publication/html/analytics/@statcounter-project">
            <xsl:value-of select="$publication/html/analytics/@statcounter-project"/>
        </xsl:when>
        <!-- obsolete, to deprecate -->
        <xsl:when test="not($html.statcounter.project = '')">
            <xsl:value-of select="$html.statcounter.project"/>
        </xsl:when>
        <!-- deprecated -->
        <xsl:when test="$assembly-docinfo/analytics/statcounter/project">
            <xsl:value-of select="$assembly-docinfo/analytics/statcounter/project"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="statcounter-security">
    <xsl:choose>
        <xsl:when test="$publication/html/analytics/@statcounter-security">
            <xsl:value-of select="$publication/html/analytics/@statcounter-security"/>
        </xsl:when>
        <!-- obsolete, to deprecate -->
        <xsl:when test="not($html.statcounter.security = '')">
            <xsl:value-of select="$html.statcounter.security"/>
        </xsl:when>
        <!-- deprecated -->
        <xsl:when test="$assembly-docinfo/analytics/statcounter/security">
            <xsl:value-of select="$assembly-docinfo/analytics/statcounter/security"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- 2019-11-28 all settings used here are deprecated -->
<xsl:variable name="google-classic-tracking">
    <xsl:choose>
        <xsl:when test="not($html.google-classic = '')">
            <xsl:value-of select="$html.google-classic"/>
        </xsl:when>
        <xsl:when test="$assembly-docinfo/analytics/google">
            <xsl:value-of select="$assembly-docinfo/analytics/google/tracking"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- 2019-11-28 all settings used here are deprecated -->
<xsl:variable name="google-universal-tracking">
    <xsl:choose>
        <xsl:when test="not($html.google-universal = '')">
            <xsl:value-of select="$html.google-universal"/>
        </xsl:when>
        <xsl:when test="$assembly-docinfo/analytics/google-universal">
            <xsl:value-of select="$assembly-docinfo/analytics/google-universal/@tracking"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- This is the preferred Google method as of 2019-11-28 -->
<xsl:variable name="google-gst-tracking">
    <xsl:choose>
        <xsl:when test="$publication/html/analytics/@google-gst">
            <xsl:value-of select="$publication/html/analytics/@google-gst"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- And boolean variables for the presence of these services -->
<!-- 2019-11-28 Two old Google services are deprecated        -->
<xsl:variable name="b-statcounter" select="not($statcounter-project = '') and not($statcounter-security = '')" />
<xsl:variable name="b-google-classic" select="not($google-classic-tracking = '')" />
<xsl:variable name="b-google-universal" select="not($google-universal-tracking = '')" />
<xsl:variable name="b-google-gst" select="not($google-gst-tracking = '')" />

<!--                           -->
<!-- HTML Search Configuration -->
<!--                           -->

<!-- Deprecated "docinfo" options are respected for now. -->
<!-- String parameters are deprecated, so in -common     -->
<!-- file, and are only consulted secondarily here       -->
<xsl:variable name="google-search-cx">
    <xsl:choose>
        <xsl:when test="$publication/html/search/@google-cx">
            <xsl:value-of select="$publication/html/search/@google-cx"/>
        </xsl:when>
        <xsl:when test="not($html.google-search = '')">
            <xsl:value-of select="$html.google-search"/>
        </xsl:when>
        <xsl:when test="$assembly-docinfo/search/google/cx">
            <xsl:value-of select="$assembly-docinfo/search/google/cx"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- And a boolean variable for the presence of this service -->
<xsl:variable name="b-google-cse" select="not($google-search-cx = '')" />

<!-- Add a boolean variable to toggle "enhanced privacy mode" -->
<!-- This is an option for embedded YouTube videos            -->
<!-- and possibly other platforms at a later date.            -->
<!-- The default is for privacy (fewer tracking cookies)      -->
<xsl:variable name="embedded-video-privacy">
    <xsl:choose>
        <xsl:when test="$publication/html/video/@privacy = 'yes'">
            <xsl:value-of select="$publication/html/video/@privacy"/>
        </xsl:when>
        <xsl:when test="$publication/html/video/@privacy = 'no'">
            <xsl:value-of select="$publication/html/video/@privacy"/>
        </xsl:when>
        <!-- set, but not correct, so inform and use default -->
        <xsl:when test="$publication/html/video/@privacy">
            <xsl:value-of select="$publication/html/video/@privacy"/>
            <xsl:message>PTX WARNING:   HTML video/@privacy in publisher file should be "yes" (fewer cookies) or "no" (all cookies), not "<xsl:value-of select="$publication/html/video/@privacy"/>". Proceeding with default value: "yes" (disable cookies, if possible)</xsl:message>
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <!-- unset, so use default -->
        <xsl:otherwise>
            <xsl:text>yes</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="b-video-privacy" select="$embedded-video-privacy = 'yes'"/>

<!--                       -->
<!-- HTML Platform Options -->
<!--                       -->

<!-- 2019-12-17:  Under development, not documented -->

<xsl:variable name="host-platform">
    <xsl:choose>
        <xsl:when test="$publication/html/platform/@host = 'web'">
            <xsl:text>web</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/platform/@host = 'runestone'">
            <xsl:text>runestone</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/platform/@host = 'aim'">
            <xsl:text>aim</xsl:text>
        </xsl:when>
        <!-- not recognized, so warn and default -->
        <xsl:when test="$publication/html/platform/@host">
            <xsl:message >PTX:WARNING: HTML platform/@host in publisher file should be "web", "runestone", or "aim", not "<xsl:value-of select="$publication/html/platform/@host"/>".  Proceeding with default value: "web"</xsl:message>
            <xsl:text>web</xsl:text>
        </xsl:when>
        <!-- the default is the "open web" -->
        <xsl:otherwise>
            <xsl:text>web</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Intent is for exactly one of these boolean to be true -->
<!-- 'web' is the default, so we may not condition with it -->
<!-- 2019-12-19: only 'web' vs. 'runestone' implemented    -->
<xsl:variable name="b-host-web"       select="$host-platform = 'web'"/>
<xsl:variable name="b-host-runestone" select="$host-platform = 'runestone'"/>
<xsl:variable name="b-host-aim"       select="$host-platform = 'aim'"/>

<!-- ###################### -->
<!-- LaTeX-Specific Options -->
<!-- ###################### -->

<!-- Sides are given as "one" or "two".  And we cannot think of    -->
<!-- any other options.  So we build, and use, a boolean variable.   -->
<!-- But if a third option aries, we can use it, and switch away  -->
<!-- from the boolean variable without the author knowing. -->
<xsl:variable name="latex-sides">
    <!-- default depends on character of output -->
    <xsl:variable name="default-sides">
        <xsl:choose>
            <xsl:when test="$b-latex-print">
                <xsl:text>two</xsl:text>
            </xsl:when>
            <xsl:otherwise> <!-- electronic -->
                <xsl:text>one</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$publication/latex/@sides = 'two'">
            <xsl:text>two</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/@sides = 'one'">
            <xsl:text>one</xsl:text>
        </xsl:when>
        <!-- not recognized, so warn and default -->
        <xsl:when test="$publication/latex/@sides">
            <xsl:message>PTX:WARNING: LaTeX @sides in publisher file should be "one" or "two", not "<xsl:value-of select="$publication/latex/@sides"/>".  Proceeding with default value, which depends on if you are making electronic ("one") or print ("two") output</xsl:message>
            <xsl:value-of select="$default-sides"/>
        </xsl:when>
        <!-- inspect deprecated string parameter  -->
        <!-- no error-checking, shouldn't be used -->
        <xsl:when test="not($latex.sides = '')">
            <xsl:value-of select="$latex.sides"/>
        </xsl:when>
        <!-- default depends -->
        <xsl:otherwise>
            <xsl:value-of select="$default-sides"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- We have "one" or "two", or junk from the deprecated string parameter -->
<xsl:variable name="b-latex-two-sides" select="$latex-sides = 'two'"/>

<!-- Print versus electronic.  Historically "yes" versus "no" -->
<!-- and that seems stable enough, as in, we don't need to    -->
<!-- contemplate some third variant of LaTeX output.          -->
<xsl:variable name="latex-print">
    <xsl:choose>
        <xsl:when test="$publication/latex/@print = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/@print = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- not recognized, so warn and default -->
        <xsl:when test="$publication/latex/@print">
            <xsl:message>PTX:WARNING: LaTeX @print in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/latex/@print"/>".  Proceeding with default value: "no"</xsl:message>
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- inspect deprecated string parameter  -->
        <!-- no error-checking, shouldn't be used -->
        <xsl:when test="not($latex.print = '')">
            <xsl:value-of select="$latex.print"/>
        </xsl:when>
        <!-- default is "no" -->
        <xsl:otherwise>
            <xsl:text>no</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- We have "yes" or "no", or possibly junk from the deprecated string    -->
<!-- parameter, so we want the default (false) to be more likely than not. -->
<xsl:variable name="b-latex-print" select="not($latex-print = 'no')"/>

<!-- LaTeX/Page -->

<!-- Right Alignment -->
<!-- guaranteed to be 'flush' or 'ragged'   -->
<!-- N.B. let HTML be different/independent -->
<xsl:variable name="latex-right-alignment">
    <xsl:choose>
        <xsl:when test="$publication/latex/page/@right-alignment = 'flush'">
            <xsl:text>flush</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/page/@right-alignment = 'ragged'">
            <xsl:text>ragged</xsl:text>
        </xsl:when>
        <!-- or respect deprecated stringparam in use, text.alignment -->
        <xsl:when test="$text.alignment = 'justify'">
            <xsl:text>flush</xsl:text>
        </xsl:when>
        <xsl:when test="$text.alignment = 'raggedright'">
            <xsl:text>ragged</xsl:text>
        </xsl:when>
        <!-- default -->
        <xsl:otherwise>
            <xsl:text>flush</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Bottom Alignment -->
<!-- guaranteed to be 'flush' or 'ragged'            -->
<!-- LaTeX varies this according to oneside, twoside -->
<!-- https://www.sascha-frank.com/page-break.html    -->
<!-- N.B. makes no sense for HTML                    -->
<xsl:variable name="latex-bottom-alignment">
    <xsl:choose>
        <xsl:when test="$publication/latex/page/@bottom-alignmant = 'flush'">
            <xsl:text>flush</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/page/@bottom-alignment = 'ragged'">
            <xsl:text>ragged</xsl:text>
        </xsl:when>
        <!-- default -->
        <xsl:otherwise>
            <xsl:text>ragged</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- LaTeX worksheet formatting -->
<!-- By default, worksheets in LaTeX will be formatted -->
<!-- with specified margins, pages, and workspace.     -->
<!-- Publisher switch to format continuously with      -->
<!-- other divisions here                              -->
<xsl:variable name="latex-worksheet-formatted">
    <xsl:choose>
        <xsl:when test="$publication/latex/worksheet/@formatted = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/worksheet/@formatted = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/worksheet/@formatted">
            <xsl:message>PTX WARNING: LaTeX worksheet formatting in the publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/latex/worksheet/@formatted"/>". Proceeding with default value: "yes"</xsl:message>
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <!-- default -->
        <xsl:otherwise>
            <xsl:text>yes</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-latex-worksheet-formatted" select="$latex-worksheet-formatted = 'yes'"/>

<!-- LaTeX/Asymptote -->

<!-- Add a boolean variable to toggle links for Asymptote images in PDF.    -->
<!-- If a baseurl is set, and an HTML version is available with interactive -->
<!-- WebGL images the publisher may want static images in the PDF to link   -->
<!-- to the interactive images online.                                      -->
<xsl:variable name="asymptote-links">
    <xsl:choose>
        <!-- fail automatically and silently for print -->
        <xsl:when test="$b-latex-print">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- proceed when requested, so long as there is a base URL -->
        <xsl:when test="$publication/latex/asymptote/@links = 'yes'">
            <xsl:choose>
                <!-- fail when no base URL is given -->
                <xsl:when test="$baseurl = ''">
                    <xsl:message>PTX WARNING: baseurl must be set in publisher file to enable links from Asymptote images</xsl:message>
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="$publication/latex/asymptote/@links = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- set, but not correct, so inform and use default -->
        <xsl:when test="$publication/latex/asymptote/@links">
            <xsl:message>PTX WARNING: LaTeX links to Asymptote publisher file should be "yes" (links to HTML) or "no" (no links), not "<xsl:value-of select="$publication/latex/asymptote/@links"/>". Proceeding with default value: "no" (no links)</xsl:message>
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- unset, use the default, which is "no" since -->
        <!-- it also needs action to set base URL        -->
        <xsl:otherwise>
            <xsl:text>no</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-asymptote-links" select="$asymptote-links = 'yes'"/>

<!-- Add another boolean to turn on links in html -->
<!-- so reader can click to open a larger version -->

<xsl:variable name="asymptote-html-links">
    <xsl:choose>
        <!-- proceed when requested, so long as there is a base URL -->
        <xsl:when test="$publication/html/asymptote/@links = 'yes'">
            <xsl:choose>
                <!-- fail when no base URL is given -->
                <xsl:when test="$baseurl = ''">
                    <xsl:message>PTX WARNING: baseurl must be set in publisher file to enable links from Asymptote images</xsl:message>
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>yes</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="$publication/html/asymptote/@links = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- set, but not correct, so inform and use default -->
        <xsl:when test="$publication/html/asymptote/@links">
            <xsl:message>PTX WARNING: HTML links to Asymptote publisher file should be "yes" (adds link below image) or "no" (no links), not "<xsl:value-of select="$publication/latex/asymptote/@links"/>". Proceeding with default value: "no" (no links)</xsl:message>
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- unset, use the default, which is "no" since -->
        <!-- it also needs action to set base URL        -->
        <xsl:otherwise>
            <xsl:text>no</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-asymptote-html-links" select="$asymptote-html-links = 'yes'"/>

<!-- ########################### -->
<!-- Reveal.js Slideshow Options -->
<!-- ########################### -->

<!-- Reveal.js Theme -->

<xsl:variable name="reveal-theme">
    <xsl:choose>
        <!-- if theme is specified, use it -->
        <xsl:when test="$publication/revealjs/appearance/@theme">
            <xsl:value-of select="$publication/revealjs/appearance/@theme"/>
        </xsl:when>
        <!-- otherwise use "simple" as the default -->
        <xsl:otherwise>
            <xsl:text>simple</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Reveal.js Controls Back Arrows -->

<xsl:variable name="reveal-control-backarrow">
    <xsl:choose>
        <!-- if publisher.xml file has laout specified, use it -->
        <xsl:when test="($publication/revealjs/controls/@backarrows = 'faded') or ($publication/revealjs/controls/@backarrows = 'hidden') or ($publication/revealjs/controls/@backarrows = 'visible')">
            <xsl:value-of select="$publication/revealjs/controls/@backarrows"/>
        </xsl:when>
        <xsl:when test="$publication/revealjs/controls/@backarrows">
            <xsl:message>PTX:WARNING: the value of the publisher file attribute "revealjs/controls/@backarrows" should be "faded", "hidden", or "visible" not "<xsl:value-of select="$publication/revealjs/controls/@backarrows"/>".  Default value will be used instead.</xsl:message>
            <xsl:text>faded</xsl:text>
        </xsl:when>
        <!-- otherwise use "faded" as the default -->
        <xsl:otherwise>
            <xsl:text>faded</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Reveal.js Controls (on-screen navigation) -->

<xsl:variable name="control-display">
    <xsl:choose>
        <!-- if publisher.xml file has theme specified, use it -->
        <xsl:when test="($publication/revealjs/controls/@display = 'yes') or ($publication/revealjs/controls/@display = 'no')">
            <xsl:value-of select="$publication/revealjs/controls/@display"/>
        </xsl:when>
        <xsl:when test="$publication/revealjs/controls/@display">
            <xsl:message>PTX:WARNING: the value of the publisher file attribute "revealjs/controls/@display" should be "yes" or "no" not "<xsl:value-of select="$publication/revealjs/controls/@display"/>".  Default value will be used instead.</xsl:message>
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <!-- otherwise use "yes" as the default -->
        <xsl:otherwise>
            <xsl:text>yes</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- Convert "yes"/"no" to a boolean variable -->
<xsl:variable name="b-reveal-control-display" select="$control-display= 'yes'"/>

<!-- Reveal.js Controls Layout -->

<xsl:variable name="reveal-control-layout">
    <xsl:choose>
        <!-- if publisher.xml file has laout specified, use it -->
        <xsl:when test="($publication/revealjs/controls/@layout = 'edges') or ($publication/revealjs/controls/@layout = 'bottom-right')">
            <xsl:value-of select="$publication/revealjs/controls/@layout"/>
        </xsl:when>
        <xsl:when test="$publication/revealjs/controls/@layout">
            <xsl:message>PTX:WARNING: the value of the publisher file attribute "revealjs/controls/@layout" should be "edges" or "bottom-right" not "<xsl:value-of select="$publication/revealjs/controls/@layout"/>".  Default value will be used instead.</xsl:message>
            <xsl:text>bottom-right</xsl:text>
        </xsl:when>
        <!-- otherwise use "bottom-right" as the default -->
        <xsl:otherwise>
            <xsl:text>bottom-right</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Reveal.js Controls Tutorial (animated arrows) -->

<xsl:variable name="control-tutorial">
    <xsl:choose>
        <!-- if publisher.xml file has theme specified, use it -->
        <xsl:when test="($publication/revealjs/controls/@tutorial = 'yes') or ($publication/revealjs/controls/@tutorial = 'no')">
            <xsl:value-of select="$publication/revealjs/controls/@tutorial"/>
        </xsl:when>
        <xsl:when test="$publication/revealjs/controls/@tutorial">
            <xsl:message>PTX:WARNING: the value of the publisher file attribute "revealjs/controls/@tutorial" should be "yes" or "no" not "<xsl:value-of select="$publication/revealjs/controls/@tutorial"/>".  Default value will be used instead.</xsl:message>
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <!-- otherwise use "yes" as the default -->
        <xsl:otherwise>
            <xsl:text>yes</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- Convert "yes"/"no" to a boolean variable -->
<xsl:variable name="b-reveal-control-tutorial" select="$control-tutorial= 'yes'"/>

<!-- Reveal.js Navigation Mode -->

<xsl:variable name="reveal-navigation-mode">
    <xsl:choose>
        <!-- if publisher.xml file has laout specified, use it -->
        <xsl:when test="($publication/revealjs/navigation/@mode = 'default') or ($publication/revealjs/navigation/@mode = 'linear') or ($publication/revealjs/navigation/@mode = 'grid')">
            <xsl:value-of select="$publication/revealjs/navigation/@mode"/>
        </xsl:when>
        <xsl:when test="$publication/revealjs/navigation/@mode">
            <xsl:message>PTX:WARNING: the value of the publisher file attribute "revealjs/navigation/@mode" should be "default", "linear", or "grid" not "<xsl:value-of select="$publication/revealjs/navigation/@mode"/>".  Default value will be used instead.</xsl:message>
            <xsl:text>default</xsl:text>
        </xsl:when>
        <!-- otherwise use "default" as the default -->
        <xsl:otherwise>
            <xsl:text>default</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Reveal.js Resources file location -->

<!-- String to prefix  reveal.js  resources -->
<xsl:variable name="reveal-root">
    <!-- CDN is used twice, so just edit here -->
    <!-- NB: deprecation is frozen -->
    <xsl:variable name="cdn-url">
        <xsl:text>https://cdnjs.cloudflare.com/ajax/libs/reveal.js/4.1.2</xsl:text>
    </xsl:variable>

    <xsl:choose>
        <!-- if publisher.xml file has CDN option specified, use it       -->
        <!-- keep this URL updated, but not for the deprecation situation -->
        <xsl:when test="$publication/revealjs/resources/@host = 'cdn'">
            <xsl:value-of select="$cdn-url"/>
        </xsl:when>
        <!-- if publisher.xml file has the local option specified, use it -->
        <xsl:when test="$publication/revealjs/resources/@host = 'local'">
            <xsl:text>.</xsl:text>
        </xsl:when>
        <!-- Experimental - just some file path/url -->
        <xsl:when test="$publication/revealjs/resources/@host">
            <xsl:value-of select="$publication/revealjs/resources/@host"/>
        </xsl:when>
        <!-- default to the CDN if no specification -->
        <xsl:otherwise>
            <xsl:value-of select="$cdn-url"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>


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
<!-- 2020-11-22: latex.print to publisher file -->
<xsl:param name="latex.print" select="''"/>
<!-- 2020-11-22 sidedness to publisher file -->
<xsl:param name="latex.sides" select="''"/>


<!-- Deprecated 2020-11-23 in favor of publisher file -->
<!-- specification, but will still be respected       -->
<xsl:param name="directory.images" select="'images'" />

<!-- 2021-01-03 chunk.level to publisher file -->
<xsl:param name="chunk.level" select="''" />
<!-- 2021-01-03 toc.level to publisher file -->
<xsl:param name="toc.level" select="''" />


<!-- Deprecated 2021-01-23, but still respected -->
<xsl:param name="html.knowl.theorem" select="''" />
<xsl:param name="html.knowl.proof" select="''" />
<xsl:param name="html.knowl.definition" select="''" />
<xsl:param name="html.knowl.example" select="''" />
<xsl:param name="html.knowl.project" select="''" />
<xsl:param name="html.knowl.task" select="''" />
<xsl:param name="html.knowl.list" select="''" />
<xsl:param name="html.knowl.remark" select="''" />
<xsl:param name="html.knowl.objectives" select="''" />
<xsl:param name="html.knowl.outcomes" select="''" />
<xsl:param name="html.knowl.figure" select="''" />
<xsl:param name="html.knowl.table" select="''" />
<xsl:param name="html.knowl.listing" select="''" />
<xsl:param name="html.knowl.exercise.inline" select="''" />
<xsl:param name="html.knowl.exercise.sectional" select="''" />
<xsl:param name="html.knowl.exercise.worksheet" select="''" />
<xsl:param name="html.knowl.exercise.readingquestion" select="''" />

<!-- Deprecated 2021-02-14 but still respected -->
<!-- maxlevel -> divisions.level, theorems.level -> blocks.level -->
<xsl:param name="numbering.theorems.level" select="''" />
<xsl:param name="numbering.projects.level" select="''" />
<xsl:param name="numbering.equations.level" select="''" />
<xsl:param name="numbering.footnotes.level" select="''" />
<xsl:param name="numbering.maximum.level" select="''" />

<!-- Deprecated 2021-02-14, now ignored, but warning exists -->
<xsl:param name="debug.chapter.start" select="''" />

<!-- Deprecated 2021-11-04, but respected by LaTeX publisher -->
<!-- switch for right alignment of page's text               -->
<xsl:param name="text.alignment" select="''" />

<!-- String parameters were the *second* wave of these        -->
<!-- switches, see variables below.  Deprecated on 2022-01-31 -->
<!-- when they migrated to the publication file.              -->

<xsl:param name="exercise.inline.statement" select="''" />
<xsl:param name="exercise.inline.hint" select="''" />
<xsl:param name="exercise.inline.answer" select="''" />
<xsl:param name="exercise.inline.solution" select="''" />
<xsl:param name="exercise.divisional.statement" select="''" />
<xsl:param name="exercise.divisional.hint" select="''" />
<xsl:param name="exercise.divisional.answer" select="''" />
<xsl:param name="exercise.divisional.solution" select="''" />
<xsl:param name="exercise.worksheet.statement" select="''" />
<xsl:param name="exercise.worksheet.hint" select="''" />
<xsl:param name="exercise.worksheet.answer" select="''" />
<xsl:param name="exercise.worksheet.solution" select="''" />
<xsl:param name="exercise.reading.statement" select="''" />
<xsl:param name="exercise.reading.hint" select="''" />
<xsl:param name="exercise.reading.answer" select="''" />
<xsl:param name="exercise.reading.solution" select="''" />
<xsl:param name="project.statement" select="''" />
<xsl:param name="project.hint" select="''" />
<xsl:param name="project.answer" select="''" />
<xsl:param name="project.solution" select="''" />

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
<!-- 2020-08-31 exercise.backmatter.* only remain for warnings  -->
<xsl:param name="exercise.text.statement" select="''" />
<xsl:param name="exercise.text.hint" select="''" />
<xsl:param name="exercise.text.answer" select="''" />
<xsl:param name="exercise.text.solution" select="''" />
<xsl:param name="project.text.hint" select="''" />
<xsl:param name="project.text.answer" select="''" />
<xsl:param name="project.text.solution" select="''" />
<xsl:param name="task.text.hint" select="''" />
<xsl:param name="task.text.answer" select="''" />
<xsl:param name="task.text.solution" select="''" />
<xsl:param name="exercise.backmatter.statement" select="''" />
<xsl:param name="exercise.backmatter.hint" select="''" />
<xsl:param name="exercise.backmatter.answer" select="''" />
<xsl:param name="exercise.backmatter.solution" select="''" />

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

<!-- DEPRECATED: 2020-05-29  In favor of       -->
<!-- html/calculator/@model  in publisher file -->
<xsl:param name="html.calculator" select="''" />

<!-- RETIRED: 2020-11-22 Not a deprecation, this is a string parameter that             -->
<!-- was never used at all.  Probably no real harm in parking it here for now.          -->
<!-- N.B. This has no effect, and may never.  xelatex and lualatex support is automatic -->
<xsl:param name="latex.engine" select="'pdflatex'" />

<!-- RETIRED: 2020-11-23 this parameter was never used, now    -->
<!-- silently moved here, which should make no real difference -->
<xsl:param name="directory.media"  select="''" />

<!-- RETIRED: 2020-11-23 this parameter was never used, now    -->
<!-- silently moved here, which should make no real difference -->
<xsl:param name="directory.knowls"  select="''" />

</xsl:stylesheet>
