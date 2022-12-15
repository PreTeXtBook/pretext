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
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:dyn="http://exslt.org/dynamic"
    extension-element-prefixes="exsl str dyn"
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
<!--                                                               -->
<!-- Also, in this stylesheet, we should not be letting "docinfo"  -->
<!-- directly set variables, as "docinfo" contains                 -->
<!-- settings/characteristics that are part of the author's source -->
<!-- and are not changed/influenced by a publisher.  Some uses are -->
<!-- historical when we we were not so aware of the distinction,   -->
<!-- and some uses are tangential (such as the type of "part" the  -->
<!-- author has chosen).                                           -->

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

<!-- Fillin styles (underline, box, shade) -->
<xsl:variable name="fillin-text-style">
    <xsl:choose>
        <xsl:when test="$publication/common/fillin/@textstyle = 'box'">
            <xsl:text>box</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/common/fillin/@textstyle = 'shade'">
            <xsl:text>shade</xsl:text>
        </xsl:when>
        <!-- default -->
        <xsl:otherwise>
            <xsl:text>underline</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="fillin-math-style">
    <xsl:choose>
        <xsl:when test="$publication/common/fillin/@mathstyle = 'underline'">
            <xsl:text>underline</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/common/fillin/@mathstyle = 'box'">
            <xsl:text>box</xsl:text>
        </xsl:when>
        <!-- default -->
        <xsl:otherwise>
            <xsl:text>shade</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Em dash Width -->

<xsl:variable name="emdash-space">
    <xsl:variable name="default-width" select="'none'"/>
    <xsl:choose>
        <xsl:when test="$publication/common/@emdash-space = 'none'">
            <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/common/@emdash-space = 'thin'">
            <xsl:text>thin</xsl:text>
        </xsl:when>
        <!-- attempted to set, but wrong -->
        <xsl:when test="$publication/common/@emdash-space">
            <xsl:message>PTX:WARNING: em-dash width setting in publisher file should be "none" or "thin", not "<xsl:value-of select="$publication/common/@emdash-space"/>". Proceeding with default value: "<xsl:value-of select="$default-width"/>"</xsl:message>
            <xsl:value-of select="$default-width"/>
        </xsl:when>
        <!-- backwards-compatability -->
        <xsl:when test="$emdash.space = 'thin'">
            <xsl:text>thin</xsl:text>
        </xsl:when>
        <xsl:when test="$emdash.space = 'none'">
            <xsl:text>none</xsl:text>
        </xsl:when>
        <!-- no attempt to set -->
        <xsl:otherwise>
            <xsl:value-of select="$default-width"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Watermarking -->
<!-- Variables for watermark text (simple!), and a scale factor. -->
<!-- Boolean variables for existence (one is deprecated LaTeX).  -->

<xsl:variable name="watermark-text">
    <xsl:choose>
        <!-- via publication file -->
        <xsl:when test="$publication/common/watermark">
            <xsl:value-of select="$publication/common/watermark"/>
        </xsl:when>
        <!-- string parameter, general -->
        <xsl:when test="($watermark.text != '')">
            <xsl:value-of select="$watermark.text"/>
        </xsl:when>
        <!-- old LaTeX-specific string parameter -->
        <xsl:when test="($latex.watermark != '')">
            <xsl:value-of select="$latex.watermark"/>
        </xsl:when>
        <!-- won't get employed if we get here, but... -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- Unedited comment, copied from old code:                            -->
<!-- watermark uses a 5cm font, which can be scaled                     -->
<!-- and scaling by 0.5 makes "CONFIDENTIAL" fit well in 600 pixel HTML -->
<!-- and in the default body width for LaTeX                            -->

<xsl:variable name="watermark-scale">
    <xsl:choose>
        <!-- via publication file -->
        <xsl:when test="$publication/common/watermark and $publication/common/watermark/@scale">
            <xsl:value-of select="$publication/common/watermark/@scale"/>
        </xsl:when>
        <!-- string parameter, general -->
        <xsl:when test="($watermark.text != '') and ($watermark.scale != '')">
            <xsl:value-of select="$watermark.scale"/>
        </xsl:when>
        <!-- old LaTeX-specific string parameter -->
        <xsl:when test="($latex.watermark != '') and ($latex.watermark.scale != '')">
            <xsl:value-of select="$latex.watermark.scale"/>
        </xsl:when>
        <!-- employ (historical) defaults to accompany provided text-->
        <xsl:otherwise>
            <xsl:choose>
                <!-- via publication file -->
                <xsl:when test="$publication/common/watermark">
                    <xsl:text>0.5</xsl:text>
                </xsl:when>
                <!-- string parameter, general -->
                <xsl:when test="($watermark.text != '')">
                    <xsl:text>0.5</xsl:text>
                </xsl:when>
                <!-- old LaTeX-specific string parameter -->
                <xsl:when test="($latex.watermark != '')">
                    <xsl:text>2.0</xsl:text>
                </xsl:when>
                <!-- won't get employed if we get here, but... -->
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- General watermarking, publication file or deprecated stringparam.  Plus  .-->
<!-- the option of double-deprecated string parameter (indicating LaTeX only). -->
<xsl:variable name="b-watermark" select="$publication/common/watermark or ($watermark.text != '')"/>
<xsl:variable name="b-latex-watermark" select="$b-watermark or ($latex.watermark != '')"/>

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

<!-- WeBWorK server location and credentials for the daemon course -->
<xsl:variable name="webwork-server">
    <xsl:choose>
        <xsl:when test="$publication/webwork/@server">
            <xsl:value-of select="$publication/webwork/@server"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>https://webwork-ptx.aimath.org</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="webwork-course">
    <xsl:choose>
        <xsl:when test="$publication/webwork/@course">
            <xsl:value-of select="$publication/webwork/@course"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>anonymous</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="webwork-coursepassword">
    <xsl:choose>
        <xsl:when test="$publication/webwork/@coursepassword">
            <xsl:value-of select="$publication/webwork/@coursepassword"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>anonymous</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="webwork-user">
    <xsl:choose>
        <xsl:when test="$publication/webwork/@user">
            <xsl:value-of select="$publication/webwork/@user"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>anonymous</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="webwork-userpassword">
    <xsl:choose>
        <xsl:when test="$publication/webwork/@userpassword">
            <xsl:value-of select="$publication/webwork/@userpassword"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>anonymous</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- WeBWorK tasks can be revealed incrementally or all at once -->
<xsl:variable name="webwork-task-reveal">
    <xsl:apply-templates mode="set-pubfile-attribute-variable" select="$publisher-attribute-options/webwork/@task-reveal"/>
</xsl:variable>


<!-- WeBWork problem representations are formed by Python routines  -->
<!-- in the   pretext.py  module that communicates with a WeBWorK   -->
<!-- server.  So this filename is only relevant for *consumption"   -->
<!-- of WW representations into final output.   But we need to make -->
<!-- sure these filenames stay in sync, creation v. consumption.    -->
<!-- Keep this template silent, since this variable may not be      -->
<!-- necessary, and it is only needed during consumption.           -->
<xsl:variable name="webwork-representations-file">
    <!-- Only relevant if there are WW problems present. A version     -->
    <!-- might remove all WW problems but there is no harm in this     -->
    <!-- template since the variable created will not be used, and     -->
    <!-- the template is silent, but for a useful deprecation warning. -->
    <xsl:if test="$original//webwork[* or @copy or @source]">
        <xsl:choose>
            <!-- Note: $generated-directory-source is never empty?    -->
            <!-- Defaults to the very old "directory.images"?         -->
            <!-- So testing for the publication file entry is better. -->
            <xsl:when test="$publication/source/directories/@generated">
                <xsl:value-of select="str:replace(concat($generated-directory-source, 'webwork/webwork-representations.xml'), '&#x20;', '%20')"/>
            </xsl:when>
            <xsl:when test="$publication/source/@webwork-problems">
                <xsl:value-of select="str:replace($publication/source/@webwork-problems, '&#x20;', '%20')"/>
                <xsl:message>PTX:WARNING: the publication file entry  source/@webwork-problems  is</xsl:message>
                <xsl:message>             deprecated, please move to using managed directories</xsl:message>
            </xsl:when>
            <!-- no specification, so empty string for filename -->
            <!-- this will be noted where it is employed        -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:if>
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

<!-- NB: the "$assembly-*" trees are a bit dangerous, being formed  -->
<!-- partway through the pre-processing phase.  Their purpose, when -->
<!-- used to query the structure of the document was to be certain  -->
<!-- that the pre-processing was done building versions, and/or     -->
<!-- done adding/deleting material.  We want to build numbers as    -->
<!-- part of pre-processing, and various defaults are a function    -->
<!-- of structure, hence the intermediate trees. (We are being very -->
<!-- cautious here, likely the $original trees would suffice for    -->
<!-- determining gross sructure.                                    -->

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

<!-- Scratch ActiveCode Window -->
<!-- Pop-up a window for testing program code.  So "calculator-like" but we      -->
<!-- reserve the word "calculator" for the hand-held type (even if more modern). -->
<xsl:variable name="html-scratch-activecode-language">
    <!-- Builds for a Runestone server default to having this   -->
    <!-- available via a button, and a "generic" build defaults -->
    <!-- to not having a button (or teh feature in any event).  -->
    <xsl:variable name="activecode-default">
        <xsl:choose>
            <xsl:when test="$b-host-runestone">
                <xsl:text>python</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="entered-lang" select="$publication/html/calculator/@activecode"/>
    <xsl:choose>
        <!-- languages *always* supported, including "none" -->
        <xsl:when test="($entered-lang = 'none') or
                        ($entered-lang = 'python') or
                        ($entered-lang = 'javascript') or
                        ($entered-lang = 'html') or
                        ($entered-lang = 'sql')">
            <!-- HTML has odd identifier, due to CodeMirror API, we  -->
            <!-- use a simple one for our authors and translate here -->
            <xsl:choose>
                <xsl:when test="$entered-lang = 'html'">
                    <xsl:text>htmlmixed</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$entered-lang"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- languages only available on a Runestone server -->
        <xsl:when test="($entered-lang = 'c') or
                        ($entered-lang = 'cpp') or
                        ($entered-lang = 'java') or
                        ($entered-lang = 'python3') or
                        ($entered-lang = 'octave')">
            <xsl:choose>
                <!-- good when hosting on a server -->
                <xsl:when test="$b-host-runestone">
                    <xsl:value-of select="$entered-lang"/>
                </xsl:when>
                <!-- sounds good, but no, not the right build -->
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: HTML calculator/@activecode in publisher file requests "<xsl:value-of select="$entered-lang"/>", but this language is not supported unless the publisher file also indicates the build is meant to be hosted on a Runestone server. Proceeding with the default value for current build: "<xsl:value-of select="$activecode-default"/>"</xsl:message>
                    <xsl:value-of select="$activecode-default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- an attempt was made, but failed to be any sort of language -->
        <xsl:when test="$publication/html/calculator/@activecode">
            <xsl:message>PTX:WARNING: HTML calculator/@activecode in publisher file should be a programming language or "none", not "<xsl:value-of select="$publication/html/calculator/@activecode"/>". Proceeding with the default value for current build: "<xsl:value-of select="$activecode-default"/>"</xsl:message>
            <xsl:value-of select="$activecode-default"/>
        </xsl:when>
        <!-- no attempt to specify build-dependent default value -->
        <xsl:otherwise>
            <xsl:value-of select="$activecode-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="b-has-scratch-activecode" select="not($html-scratch-activecode-language = 'none')"/>

<!--                                      -->
<!-- HTML Reading Question Response Boxes -->
<!--                                      -->

<xsl:variable name="short-answer-responses">
    <xsl:variable name="default-responses" select="'graded'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/@short-answer-responses = 'graded'">
            <xsl:text>graded</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/@short-answer-responses = 'always'">
            <xsl:text>always</xsl:text>
        </xsl:when>
        <!-- set, but not correct, so inform and use default -->
        <xsl:when test="$publication/html/@short-answer-responses">
            <xsl:message>PTX:WARNING: HTML @short-answer-responses in publisher file should be "graded" or "always", not "<xsl:value-of select="$publication/html/@short-answer-responses"/>". Proceeding with default value: "<xsl:value-of select="$default-responses"/>"</xsl:message>
            <xsl:value-of select="$default-responses"/>
        </xsl:when>
        <!-- unset, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$default-responses"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

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

<!--                       -->
<!-- HTML WeBWorK Dynamism -->
<!--                       -->

<!-- In HTML output a WeBWorK problem may be static or dynamic.  This  -->
<!-- is a dichotomy, so we make (historical) boolean variables, where  -->
<!-- static = True, which get used in the HTML conversion.  But as a   -->
<!-- publisher setting, we have allowed for possibilities beyond just  -->
<!-- two.  Inline and project-like default to "dynamic" since they may -->
<!-- be formative, while the others are "static" since they may be     -->
<!-- summative.                                                        -->

<xsl:variable name="webwork-inline-capability">
    <xsl:variable name="ww-default" select="'dynamic'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/webwork/@inline = 'dynamic'">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/webwork/@inline = 'static'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <!-- attempted to set, but wrong -->
        <xsl:when test="$publication/html/webwork/@inline">
            <xsl:message>PTX:WARNING: HTML WeBWorK @inline setting in publisher file should be "static" or "dynamic", not "<xsl:value-of select="$publication/html/webwork/@inline"/>". Proceeding with default value: "<xsl:value-of select="$ww-default"/>"</xsl:message>
            <xsl:value-of select="$ww-default"/>
        </xsl:when>
        <!-- backwards compatibility: 'yes' indicated static,     -->
        <!-- anything else would be interpreted as if it was 'no' -->
        <xsl:when test="$webwork.inline.static = 'yes'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <xsl:when test="$webwork.inline.static != ''">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <!-- no effort to set this switch, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$ww-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- the variable is now either 'static' or 'dynamic' -->
<xsl:variable name="b-webwork-inline-static" select="$webwork-inline-capability = 'static'" />

<xsl:variable name="webwork-divisional-capability">
    <xsl:variable name="ww-default" select="'static'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/webwork/@divisional = 'dynamic'">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/webwork/@divisional = 'static'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <!-- attempted to set, but wrong -->
        <xsl:when test="$publication/html/webwork/@divisional">
            <xsl:message>PTX:WARNING: HTML WeBWorK @divisional setting in publisher file should be "static" or "dynamic", not "<xsl:value-of select="$publication/html/webwork/@divisional"/>". Proceeding with default value: "<xsl:value-of select="$ww-default"/>"</xsl:message>
            <xsl:value-of select="$ww-default"/>
        </xsl:when>
        <!-- backwards compatibility: 'yes' indicated static,     -->
        <!-- anything else would be interpreted as if it was 'no' -->
        <xsl:when test="$webwork.divisional.static = 'yes'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <xsl:when test="$webwork.divisional.static != ''">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <!-- no effort to set this switch, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$ww-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- the variable is now either 'static' or 'dynamic' -->
<xsl:variable name="b-webwork-divisional-static" select="$webwork-divisional-capability = 'static'" />

<xsl:variable name="webwork-reading-capability">
    <xsl:variable name="ww-default" select="'static'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/webwork/@reading = 'dynamic'">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/webwork/@reading = 'static'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <!-- attempted to set, but wrong -->
        <xsl:when test="$publication/html/webwork/@reading">
            <xsl:message>PTX:WARNING: HTML WeBWorK @reading setting in publisher file should be "static" or "dynamic", not "<xsl:value-of select="$publication/html/webwork/@reading"/>". Proceeding with default value: "<xsl:value-of select="$ww-default"/>"</xsl:message>
            <xsl:value-of select="$ww-default"/>
        </xsl:when>
        <!-- backwards compatibility: 'yes' indicated static,     -->
        <!-- anything else would be interpreted as if it was 'no' -->
        <xsl:when test="$webwork.reading.static = 'yes'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <xsl:when test="$webwork.reading.static != ''">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <!-- no effort to set this switch, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$ww-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- the variable is now either 'static' or 'dynamic' -->
<xsl:variable name="b-webwork-reading-static" select="$webwork-reading-capability = 'static'" />

<xsl:variable name="webwork-worksheet-capability">
    <xsl:variable name="ww-default" select="'static'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/webwork/@worksheet = 'dynamic'">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/webwork/@worksheet = 'static'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <!-- attempted to set, but wrong -->
        <xsl:when test="$publication/html/webwork/@worksheet">
            <xsl:message>PTX:WARNING: HTML WeBWorK @worksheet setting in publisher file should be "static" or "dynamic", not "<xsl:value-of select="$publication/html/webwork/@worksheet"/>". Proceeding with default value: "<xsl:value-of select="$ww-default"/>"</xsl:message>
            <xsl:value-of select="$ww-default"/>
        </xsl:when>
        <!-- backwards compatibility: 'yes' indicated static,     -->
        <!-- anything else would be interpreted as if it was 'no' -->
        <xsl:when test="$webwork.worksheet.static = 'yes'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <xsl:when test="$webwork.worksheet.static != ''">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <!-- no effort to set this switch, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$ww-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- the variable is now either 'static' or 'dynamic' -->
<xsl:variable name="b-webwork-worksheet-static" select="$webwork-worksheet-capability = 'static'" />

<xsl:variable name="webwork-project-capability">
    <xsl:variable name="ww-default" select="'dynamic'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/webwork/@project = 'dynamic'">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/webwork/@project = 'static'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <!-- attempted to set, but wrong -->
        <xsl:when test="$publication/html/webwork/@project">
            <xsl:message>PTX:WARNING: HTML WeBWorK @project setting in publisher file should be "static" or "dynamic", not "<xsl:value-of select="$publication/html/webwork/@project"/>". Proceeding with default value: "<xsl:value-of select="$ww-default"/>"</xsl:message>
            <xsl:value-of select="$ww-default"/>
        </xsl:when>
        <!-- backwards compatibility: 'yes' indicated static,     -->
        <!-- anything else would be interpreted as if it was 'no' -->
        <xsl:when test="$webwork.project.static = 'yes'">
            <xsl:text>static</xsl:text>
        </xsl:when>
        <xsl:when test="$webwork.project.static != ''">
            <xsl:text>dynamic</xsl:text>
        </xsl:when>
        <!-- no effort to set this switch, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$ww-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- the variable is now either 'static' or 'dynamic' -->
<xsl:variable name="b-webwork-project-static" select="$webwork-project-capability = 'static'" />


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
            <!-- reluctantly query the old docinfo version  -->
            <!-- If the "version" feature controls multiple -->
            <!-- "docinfo" then this might query the wrong  -->
            <!-- one (using $assembly-docinfo here led to a -->
            <!-- circular variable definition).             -->
            <xsl:when test="$original/docinfo/html/baseurl/@href">
                <xsl:value-of select="$original/docinfo/html/baseurl/@href"/>
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

<!--                 -->
<!-- HTML Navigation -->
<!--                 -->

<!-- Navigation may follow two different logical models:                     -->
<!--   (a) Linear, Prev/Next - depth-first search, linear layout like a book -->
<!--       Previous and Next take you to the adjacent "page"                 -->
<!--   (b) Tree, Prev/Up/Next - explicitly traverse the document tree        -->
<!--       Prev and Next remain at same depth/level in tree                  -->
<!--       Must follow a summary link to descend to finer subdivisions       -->
<!--   'linear' is the default, 'tree' is an option                          -->
<xsl:variable name="nav-logic">
    <xsl:variable name="logic-default" select="'linear'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/navigation/@logic = 'linear'">
            <xsl:text>linear</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/navigation/@logic = 'tree'">
            <xsl:text>tree</xsl:text>
        </xsl:when>
        <!-- an attempt to set, but wrong -->
        <xsl:when test="$publication/html/navigation/@logic">
            <xsl:message>PTX:WARNING: HTML navigation logic setting in publisher file should be "linear" or "tree", not "<xsl:value-of select="$publication/html/navigation/@logic"/>". Proceeding with default value: "<xsl:value-of select="$logic-default"/>"</xsl:message>
            <xsl:value-of select="$logic-default"/>
        </xsl:when>
        <!-- backwards compatibility, no error-checking -->
        <xsl:when test="$html.navigation.logic='linear'">
            <xsl:text>linear</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.logic='tree'">
            <xsl:text>tree</xsl:text>
        </xsl:when>
        <!-- no effort to set this switch, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$logic-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- The "up" button is optional given the contents sidebar, default is to have it -->
<!-- An up button is very desirable if you use the tree-like logic                 -->
<xsl:variable name="nav-upbutton">
    <xsl:variable name="upbutton-default" select="'yes'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/navigation/@upbutton = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/navigation/@upbutton = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- an attempt to set, but wrong -->
        <xsl:when test="$publication/html/navigation/@upbutton">
            <xsl:message>PTX:WARNING: HTML navigation up-button setting in publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/html/navigation/@upbutton"/>". Proceeding with default value: "<xsl:value-of select="$upbutton-default"/>"</xsl:message>
            <xsl:value-of select="$upbutton-default"/>
        </xsl:when>
        <!-- backwards compatibility, no error-checking -->
        <xsl:when test="$html.navigation.upbutton='yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.upbutton='no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- no effort to set this switch, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$upbutton-default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- There are also "compact" versions of the navigation buttons in the top right -->
<xsl:variable name="nav-style">
    <xsl:variable name="style-default" select="'full'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/navigation/@style = 'full'">
            <xsl:text>full</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/navigation/@style = 'compact'">
            <xsl:text>compact</xsl:text>
        </xsl:when>
        <!-- an attempt to set, but wrong -->
        <xsl:when test="$publication/html/navigation/@style">
            <xsl:message>PTX:WARNING: HTML navigation style setting in publisher file should be "full" or "compact", not "<xsl:value-of select="$publication/html/navigation/@style"/>". Proceeding with default value: "<xsl:value-of select="$style-default"/>"</xsl:message>
            <xsl:value-of select="$style-default"/>
        </xsl:when>
        <!-- backwards compatibility, no error-checking -->
        <xsl:when test="$html.navigation.style='full'">
            <xsl:text>full</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.style='compact'">
            <xsl:text>compact</xsl:text>
        </xsl:when>
        <!-- no effort to set this switch, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$style-default"/>
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

<xsl:variable name="html-css-navbarfile">
    <xsl:choose>
        <!-- if publisher.xml file has style value, use it -->
        <xsl:when test="$publication/html/css/@navbar">
            <xsl:text>navbar_</xsl:text>
            <xsl:value-of select="$publication/html/css/@navbar"/>
            <xsl:text>.css</xsl:text>
        </xsl:when>
        <!-- otherwise use the dafault -->
        <xsl:otherwise>
            <xsl:text>navbar_default.css</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="html-css-shellfile">
    <xsl:choose>
        <!-- if publisher.xml file has style value, use it -->
        <xsl:when test="$publication/html/css/@shell">
            <xsl:text>shell_</xsl:text>
            <xsl:value-of select="$publication/html/css/@shell"/>
            <xsl:text>.css</xsl:text>
        </xsl:when>
        <!-- otherwise use the dafault -->
        <xsl:otherwise>
            <xsl:text>shell_default.css</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!--                              -->
<!-- HTML Analytics Configuration -->
<!--                              -->

<!-- String parameters are deprecated, so in -common -->
<!-- file, and are only consulted secondarily here   -->

<!-- NB: the "$assembly-*" trees are a bit dangerous, being formed  -->
<!-- partway through the pre-processing phase.  Their previous      -->
<!-- purpose, when used to query the "docinfo" was to be certain    -->
<!-- that the pre-processing was done building versions, and/or     -->
<!-- done adding/deleting material.  They could probably be         -->
<!-- changed to "$original/docinfo".  The risk is that a project    -->
<!-- might have multiple "docinfo" for multiple versions (the       -->
<!-- supported scheme for this) and would be relying on only one    -->
<!-- "docinfo" surviving.  However, uses below are for deprecated   -->
<!-- situations, so we can warn about multiple "docinfo" in the     -->
<!-- deprecation messages (as has been done for html/baseurl/@href. -->

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

<!-- Possible values for search/@variant are:                      -->
<!--                                                               -->
<!--   "none" - self-explanatory, no computation, no interface     -->
<!--   "textbook" - pages, divisions on pages, blocks, p[term],    -->
<!--                chronological and indented presentation        -->
<!--   "reference" - pages, divisions, all children of a division  -->
<!--                 (blocks, first-class "p")                     -->
<!--   "default" - historical, equal to "textbook"                 -->
<!--                                                               -->
<!-- Resulting variable values are "none", "textbook", "reference" -->
<!-- and *not* "default", it was an historical fudge.              -->
<!-- Note the boolean variable for the no-search case              -->
<xsl:variable name="native-search-variant">
    <xsl:variable name="default-native-search" select="'textbook'"/>
    <xsl:choose>
        <xsl:when test="$publication/html/search/@variant = 'none'">
            <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/search/@variant = 'textbook'">
            <xsl:text>textbook</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/search/@variant = 'reference'">
            <xsl:text>reference</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/html/search/@variant = 'default'">
            <!-- change to default variable once this becomes opt-out -->
            <xsl:text>textbook</xsl:text>
        </xsl:when>
        <!-- set, but not correct, so inform and use default -->
        <xsl:when test="$publication/html/search/@variant">
            <xsl:message>PTX:WARNING: HTML search/@variant in publisher file should be "none", "textbook", "reference" or "default", not "<xsl:value-of select="$publication/html/search/@variant"/>". Proceeding with default value: "<xsl:value-of select="$default-native-search"/>"</xsl:message>
            <xsl:value-of select="$default-native-search"/>
        </xsl:when>
        <!-- unset, so use default -->
        <xsl:otherwise>
            <xsl:value-of select="$default-native-search"/>
        </xsl:otherwise>
    </xsl:choose>
    <!-- warn if Google search is also set               -->
    <!-- TODO: implementation might prefer native search -->
    <xsl:if test="$b-google-cse and $publication/html/search/@variant and not($publication/html/search/@variant = 'none')">
        <xsl:message>PTX:WARNING: specifying HTML search/@variant AND search/@google-cx in publisher file is not possible and will lead to unpredictable results</xsl:message>
    </xsl:if>
</xsl:variable>

<xsl:variable name="has-native-search" select="not($native-search-variant = 'none')"/>

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
    <xsl:variable name="default-align" select="'flush'"/>
    <xsl:choose>
        <xsl:when test="$publication/latex/page/@right-alignment = 'flush'">
            <xsl:text>flush</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/page/@right-alignment = 'ragged'">
            <xsl:text>ragged</xsl:text>
        </xsl:when>
        <!-- attempted to set, but wrong -->
        <xsl:when test="$publication/latex/page/@right-alignment">
            <xsl:message>PTX:WARNING: LaTeX right-alignment setting in publisher file should be "flush" or "ragged", not "<xsl:value-of select="$publication/latex/page/@right-alignment"/>". Proceeding with default value: "<xsl:value-of select="$default-align"/>"</xsl:message>
            <xsl:value-of select="$default-align"/>
        </xsl:when>
        <!-- or respect deprecated stringparam in use, text.alignment -->
        <xsl:when test="$text.alignment = 'justify'">
            <xsl:text>flush</xsl:text>
        </xsl:when>
        <xsl:when test="$text.alignment = 'raggedright'">
            <xsl:text>ragged</xsl:text>
        </xsl:when>
        <!-- no attempt at all, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$default-align"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Bottom Alignment -->
<!-- guaranteed to be 'flush' or 'ragged'            -->
<!-- LaTeX varies this according to oneside, twoside -->
<!-- https://www.sascha-frank.com/page-break.html    -->
<!-- N.B. makes no sense for HTML                    -->
<xsl:variable name="latex-bottom-alignment">
    <xsl:variable name="default-align" select="'ragged'"/>
    <xsl:choose>
        <xsl:when test="$publication/latex/page/@bottom-alignment = 'flush'">
            <xsl:text>flush</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/page/@bottom-alignment = 'ragged'">
            <xsl:text>ragged</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/page/@bottom-alignment">
            <xsl:message>PTX:WARNING: LaTeX bottom-alignment setting in publisher file should be "flush" or "ragged", not "<xsl:value-of select="$publication/latex/page/@bottom-alignment"/>". Proceeding with default value: "<xsl:value-of select="$default-align"/>"</xsl:message>
            <xsl:value-of select="$default-align"/>
        </xsl:when>
        <!-- no attempt at all, so default -->
        <xsl:otherwise>
            <xsl:value-of select="$default-align"/>
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

<!-- For historical reasons, this variable has "pt" as part -->
<!-- of its value.  A change would need to be coordinated   -->
<!-- with every application in the -latex conversion.       -->
<xsl:variable name="font-size">
    <xsl:choose>
        <!-- via publication file -->
        <xsl:when test="$publication/latex/@font-size">
            <!-- provisional, convenience -->
            <xsl:variable name="fs" select="$publication/latex/@font-size"/>
            <xsl:choose>
                <xsl:when test="($fs =  '8') or
                                ($fs =  '9') or
                                ($fs = '10') or
                                ($fs = '11') or
                                ($fs = '12') or
                                ($fs = '14') or
                                ($fs = '17') or
                                ($fs = '20')">
                    <xsl:value-of select="$fs"/>
                    <xsl:text>pt</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: LaTeX @font-size in publication file should be 8, 9, 10, 11, 12, 14, 17 or 20 points, not "<xsl:value-of select="$publication/latex/@font-size"/>".  Proceeding with default value: "10"</xsl:message>
                    <xsl:text>10pt</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- via deprecated stringparam: assumes "pt" as the unit of measure   -->
        <!-- (this is recycled code, so no real attempt to do better)          -->
        <xsl:when test="not($latex.font.size = '')">
            <xsl:choose>
                <xsl:when test="$latex.font.size='10pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
                <xsl:when test="$latex.font.size='12pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
                <xsl:when test="$latex.font.size='11pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
                <xsl:when test="$latex.font.size='8pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
                <xsl:when test="$latex.font.size='9pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
                <xsl:when test="$latex.font.size='14pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
                <xsl:when test="$latex.font.size='17pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
                <xsl:when test="$latex.font.size='20pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
                <xsl:otherwise>
                    <xsl:text>10pt</xsl:text>
                    <xsl:message>PTX:ERROR   the *deprecated* latex.font.size parameter must be 8pt, 9pt, 10pt, 11pt, 12pt, 14pt, 17pt, or 20pt, not "<xsl:value-of select="$latex.font.size" />".  Using the default ("10pt")</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- no publication file entry, no deprecated  -->
        <!-- string parameter, so use the default value -->
        <xsl:otherwise>
            <xsl:text>10pt</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Simple - just feeds into a LaTeX \geometry{} -->
<xsl:variable name="latex-page-geometry">
    <xsl:choose>
        <!-- prefer publication file entry -->
        <xsl:when test="$publication/latex/page/geometry">
            <xsl:value-of select="$publication/latex/page/geometry"/>
        </xsl:when>
        <!-- deprecated string parameter in use-->
        <xsl:when test="($latex.geometry != '')">
            <xsl:value-of select="$latex.geometry"/>
        </xsl:when>
        <!-- empty is the signal to not use -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- The default for the use of page references varies, so that  -->
<!-- particular logic is in the -latex conversion.  Here we just -->
<!-- sanitize to "yes", "no" or empty (i.e. ignored)             -->
<xsl:variable name="latex-pageref">
    <xsl:choose>
        <!-- given in publication file -->
        <xsl:when test="$publication/latex/@pageref">
            <xsl:choose>
                <xsl:when test="$publication/latex/@pageref = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/latex/@pageref = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <!-- ignored = empty (as if not attempted -->
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: the value of the publisher file entry  latex/@pageref  should be "yes" or "no" not "<xsl:value-of select="$publication/latex/@pageref"/>".  The value is being ignored.</xsl:message>
                    <xsl:text/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- given by deprecated string parameter -->
        <xsl:when test="($latex.pageref != '')">
            <xsl:choose>
                <xsl:when test="$latex.pageref = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$latex.pageref = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <!-- ignored = empty (as if not attempted -->
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: the value of the *deprecated* string parameter  latex.pageref  should be "yes" or "no" not "<xsl:value-of select="$latex.pageref"/>".  The value is being ignored.</xsl:message>
                    <xsl:text/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- empty if no attempt to influence -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- Draft Copies                                              -->
<!-- Various options for working copies for authors            -->
<!-- (1) LaTeX's draft mode                                    -->
<!-- (2) Crop marks on letter paper, centered                  -->
<!--     presuming geometry sets smaller page size             -->
<!--     with paperheight, paperwidth                          -->
<xsl:variable name="latex-draft-mode">
    <xsl:choose>
        <xsl:when test="$publication/latex/@draft">
            <xsl:choose>
                <xsl:when test="$publication/latex/@draft = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/latex/@draft = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$publication/latex/@draft">
                    <xsl:message>PTX WARNING: LaTeX draft mode in the publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/latex/@draft"/>". Proceeding with default value: "no"</xsl:message>
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <!-- default -->
                <xsl:otherwise>
                    <xsl:text>no</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="($latex.draft != '')">
            <xsl:choose>
                <xsl:when test="$latex.draft = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="$latex.draft = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <!-- ignored = empty (as if not attempted -->
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: the value of the *deprecated* string parameter  latex.draft  should be "yes" or "no" not "<xsl:value-of select="$latex.draft"/>".  The default value of "no" is being used.</xsl:message>
                    <xsl:text/>
                </xsl:otherwise>
            </xsl:choose>
       </xsl:when>
        <!-- ho effort to specify, default to "no" -->
        <xsl:otherwise>
            <xsl:text>no</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-latex-draft-mode" select="$latex-draft-mode = 'yes'"/>

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

<xsl:variable name="latex-snapshot">
    <xsl:variable name="default-snapshot" select="'no'"/>
    <xsl:choose>
        <xsl:when test="$publication/latex/@snapshot = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:when test="$publication/latex/@snapshot = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <!-- attempt to set, but wrong -->
        <xsl:when test="$publication/latex/@snapshot">
            <xsl:message>PTX WARNING: LaTeX snapshot record in the publisher file should be "yes" or "no", not "<xsl:value-of select="$publication/latex/@snapshot"/>". Proceeding with default value: "<xsl:value-of select="$default-snapshot"/>"</xsl:message>
            <xsl:value-of select="$default-snapshot"/>
        </xsl:when>
        <!-- no attempt to set, thus default -->
        <xsl:otherwise>
            <xsl:value-of select="$default-snapshot"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-latex-snapshot" select="$latex-snapshot = 'yes'"/>


<!-- ########### -->
<!-- LaTeX Fonts -->
<!-- ########### -->

<!-- 2022-11-03: experimental, subject to change -->

<xsl:variable name="latex-font-main-regular">
    <xsl:choose>
        <!-- having a main font specification *rerquires* a @regular -->
        <!-- TODO: put in a test here to generate a warning if no @regular -->
        <xsl:when test="$publication/latex/fonts/main">
            <xsl:value-of select="$publication/latex/fonts/main/@regular"/>
        </xsl:when>
        <!-- empty is signal there is no main font overrride -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>


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


<!-- ########################################### -->
<!-- Set Values/Defaults for Publisher Variables -->
<!-- ########################################### -->

<!-- This tree should mirror the official list of options for publisher file -->
<!-- attributes for each attribute that has a finite list of options.        -->

<pi:publisher>
    <webwork task-reveal="preceding-correct all"/>
</pi:publisher>

<!-- global variable for pi:publisher tree above -->
<xsl:variable name="publisher-attribute-options" select="document('')/xsl:stylesheet/pi:publisher"/>

<!-- context for a match below will be an attribute from the pi:publisher tree -->
<xsl:template match="@*" mode="set-pubfile-attribute-variable">
    <!-- get the options that are in pi:publisher -->
    <xsl:variable name="options" select="str:tokenize(., ' ')"/>
    <!-- the first option is the default -->
    <xsl:variable name="default" select="$options[1]"/>
    <!-- get the path to this attribute -->
    <xsl:variable name="path">
        <xsl:apply-templates select="." mode="path"/>
    </xsl:variable>
    <!-- get the corresponding attribute from the publisher file -->
    <!-- which may not exist                                     -->
    <xsl:variable name="full-path" select="concat('$publication/', $path)"/>
    <xsl:variable name="pubfile-attribute" select="dyn:evaluate($full-path)"/>
    <xsl:choose>
        <!-- test catches when attribute is omitted from pubfile, -->
        <!-- as well as present but null or only whitepsace       -->
        <xsl:when test="string($pubfile-attribute) = ''">
            <xsl:value-of select="$default"/>
        </xsl:when>
        <!-- a non-empty, non-whitespace string was used in the pubfile -->
        <!-- next test checks if it is among the legal options          -->
        <xsl:when test="$pubfile-attribute = $options">
            <xsl:value-of select="$pubfile-attribute"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: the publisher file  <xsl:value-of select="$path"/>  entry should be <xsl:apply-templates select="$options" mode="quoted-list"/>, not "<xsl:value-of select="$pubfile-attribute"/>".  The default "<xsl:value-of select="$default"/>" will be used instead.</xsl:message>
            <xsl:value-of select="$default"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Recurse back up the tree to get the path to an attribute -->
<xsl:template match="@*" mode="path">
    <xsl:apply-templates select=".." mode="path"/>
    <xsl:value-of select="concat('@', local-name())"/>
</xsl:template>

<xsl:template match="*" mode="path">
    <xsl:apply-templates select=".." mode="path"/>
    <xsl:value-of select="concat(local-name(), '/')"/>
</xsl:template>

<xsl:template match="pi:publisher" mode="path"/>

<!-- Expects a node set from tokenize()                       -->
<!-- Produces a string where each token is wrapped in quotes  -->
<!-- When there are multiple options, separates with a comma  -->
<!-- Last options preceded by "or" with Oxford comma if 3+    -->
<xsl:template match="token" mode="quoted-list">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
    <xsl:choose>
        <!-- if there are at least two more coming -->
        <xsl:when test="count(following-sibling::token) &gt;= 2">
            <xsl:text>, </xsl:text>
        </xsl:when>
        <!-- if there is exactly one more coming and we have a list of at least three -->
        <xsl:when test="preceding-sibling::token and following-sibling::token">
            <xsl:text>, or </xsl:text>
        </xsl:when>
        <!-- if there is exactly one more coming and we have a list of two -->
        <xsl:when test="following-sibling::token">
            <xsl:text> or </xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- ######################### -->
<!-- String Parameter Bad Bank -->
<!-- ######################### -->

<!-- 2022-12-26: this list of deprecated, retired, obsolete (string)  -->
<!-- parameters has evolved over time and the comments are a bit      -->
<!-- haphazard.  The primary motivation for keeping (most of) these   -->
<!-- is to allow deprecation warnings to flag (and often react        -->
<!-- favorably) to attempted uses. Dated, and in chronological        -->
<!-- order.  Grep, or the git pickaxe (log -S) using the date strings -->
 <!-- is often effective in locating all the pieces of a deprecation. -->

<!-- Conversion specific parameters that die will   -->
<!-- live on in warnings, which are isolated in the -->
<!-- pretext-common stylesheet.  So we need to      -->
<!-- declare them here for use in the warnings      -->

<!-- Some string parameters have been deprecated without any      -->
<!-- sort of replacement, fallback, or upgrade.  But for a        -->
<!-- deprecation message to be effective, they need to exist.     -->
<!-- If you add something here, make a note by the deprecation    -->
<!-- message.  These definitions expain why it is *always* best   -->
<!-- to define a user variable as empty, and then supply defaults -->
<!-- to an internal variable.                                     -->

<!-- HTML-specific deprecated 2015-06, but still functional -->
<xsl:param name="html.chunk.level" select="''" />

<!-- DEPRECATED: 2017-12-18, do not use, any value -->
<!-- besides an empty string will raise a warning  -->
<xsl:param name="latex.console.macro-char" select="''" />
<xsl:param name="latex.console.begin-char" select="''" />
<xsl:param name="latex.console.end-char" select="''" />

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

<!-- DEPRECATED: 2020-05-29  In favor of       -->
<!-- html/calculator/@model  in publisher file -->
<xsl:param name="html.calculator" select="''" />

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

<!-- Replaced by more specific versions, 2019-02-10     -->
<!-- These are variables, but still react when supplied -->
<!-- to xsltproc/lxml as command-line arguments         -->
<xsl:variable name="html.css.file" select="''"/>
<xsl:variable name="html.permalink" select="''"/>

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

<!-- On 2021-03-03 abandoned a "fast-id" scheme that was never -->
<!-- really used since it was in-effect a developer testing    -->
<!-- option. Then on 2022-05-23 removed code, strengthened     -->
<!-- deprecation message, and moved parameter here.            -->
<xsl:param name="oldids" select="''"/>

<!-- Deprecated on 2022-10-24.  Definition has changed from  -->
<!-- a default value of "10pt" to an empty string, so we can -->
<!-- detect use for a deprecation warning.  Default value is -->
<!-- preserved in other ways as part of the deprecation.     -->
<xsl:param name="latex.font.size" select="''" />

<!-- Geometry: page shape, margins, etc. Deprecated    -->
<!--2022-10-24, non-empty triggers deprecation warning -->
<xsl:param name="latex.geometry" select="''"/>

<!-- Page Numbers in cross-references, deprecated 2022-10-24 -->
<xsl:param name="latex.pageref" select="''"/>

<!-- Electing LaTeX draft mode, deprecated 2022-10-24 -->
<xsl:param name="latex.draft" select="''"/>

<!-- These first two are deprecated in favor of watermark.text  -->
<!-- and watermark.scale, which in turn are deprecated in favor -->
<!-- of publication file entry.  Double deprecation, second one -->
<!-- on 2022-10-24.                                             -->
<xsl:param name="latex.watermark" select="''"/>
<xsl:param name="latex.watermark.scale" select="''"/>
<xsl:param name="watermark.text" select="''" />
<xsl:param name="watermark.scale" select="''" />

<!-- These were yes/no string parameters.  We converted to values -->
<!-- of "static" or "dynamic" as publisher entries on 2022-11-19. -->
<xsl:param name="webwork.inline.static" select="''" />
<xsl:param name="webwork.divisional.static" select="''" />
<xsl:param name="webwork.reading.static" select="''" />
<xsl:param name="webwork.worksheet.static" select="''" />
<xsl:param name="webwork.project.static" select="''" />

<!-- Navigation options move to the publisher file on 2022-11-20. -->
<xsl:param name="html.navigation.logic"  select="''"/>
<xsl:param name="html.navigation.upbutton"  select="''"/>
<xsl:param name="html.navigation.style"  select="''"/>

<!-- Publisher option to surround emdash, deprecated 2022-11-20 -->
<xsl:param name="emdash.space" select="''" />

<!-- ###################################### -->
<!-- Parameter Deprecation Warning Messages -->
<!-- ###################################### -->

<!-- Pass in a condition, true is a problem.       -->
<!-- A message string like "'foo'" cannot contain  -->
<!-- a single quote, even if entered as &apos;.    -->
<!-- If despearate, concatentate with $apos.       -->
<!-- A &#xa; can be used if necessary, but only    -->
<!-- rarely do we bother.                          -->
<xsl:template name="parameter-deprecation-message">
    <xsl:param name="incorrect-use" select="false()" />
    <xsl:param name="date-string" />
    <xsl:param name="message" />
    <xsl:if test="$incorrect-use">
        <xsl:message>
            <xsl:text>PTX:DEPRECATE: (</xsl:text>
            <xsl:value-of select="$date-string" />
            <xsl:text>) </xsl:text>
            <xsl:value-of select="$message" />
            <!-- once verbosity is implemented -->
            <!-- <xsl:text>, set log.level to see more details</xsl:text> -->
        </xsl:message>
        <xsl:message>
            <xsl:text>--------------</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<xsl:template match="mathbook|pretext" mode="parameter-deprecation-warnings">
    <!-- These apparent re-definitions are local to this template -->
    <!-- Reasons are historical, so to be a convenience           -->
    <xsl:variable name="docinfo" select="./docinfo"/>
    <xsl:variable name="document-root" select="./*[not(self::docinfo)]"/>


    <!-- 2017-07-05  sidebyside cannot be cross-referenced anymore, so not knowlizable -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2017-07-05'" />
        <xsl:with-param name="message" select="'the  html.knowl.sidebyside  parameter is now obsolete and will be ignored'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.sidebyside != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-06-26  chunking became a general thing -->
    <!-- 2021-01-03  rendered ineffective            -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2015-06-26'" />
        <xsl:with-param name="message" select="'the  html.chunk.level  parameter has been replaced by the common/chunking/@level  entry in the publisher file.  It will be ignored.  Please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.chunk.level != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-25  deprecate intentional autoname without new setting -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the  autoname  parameter is deprecated, but is still effective since  &quot;docinfo/cross-references/@text&quot;  has not been set.  The following parameter values equate to the attribute values: &quot;no&quot; is &quot;global&quot;, &quot;yes&quot; is &quot;type-global&quot;, &quot;title&quot; is &quot;title&quot;'" />
        <xsl:with-param name="incorrect-use" select="not($autoname = '') and not(//docinfo/cross-references)" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-25  deprecate intentional autoname also with new setting -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the  autoname  parameter is deprecated, and is being overidden by a  &quot;docinfo/cross-references/@text&quot;  and so is totally ineffective and can be removed'" />
            <xsl:with-param name="incorrect-use" select="not($autoname = '') and //docinfo/cross-references" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-12-18  deprecate three console macro characters -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2017-12-18'" />
        <xsl:with-param name="message" select="'the  latex.console.macro-char  parameter is deprecated, and there is no longer a need to be careful about the backslash (\) character in a console'" />
            <xsl:with-param name="incorrect-use" select="not($latex.console.macro-char = '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2017-12-18'" />
        <xsl:with-param name="message" select="'the  latex.console.begin-char  parameter is deprecated, and there is no longer a need to be careful about the begin group ({) character in a console'" />
            <xsl:with-param name="incorrect-use" select="not($latex.console.begin-char = '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2017-12-18'" />
        <xsl:with-param name="message" select="'the  latex.console.end-char  parameter is deprecated, and there is no longer a need to be careful about the end group (}) character in a console'" />
            <xsl:with-param name="incorrect-use" select="not($latex.console.end-char = '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-11-07  obsolete exercise component switches          -->
    <!-- Still exists in "String Parameter Bad Bank" for use here  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2018-11-07'" />
        <xsl:with-param name="message" select="'the  *.text.*  parameters that control the visibility of components of exercises and projects have been removed and replaced by a greater variety of  exercise.*.*  and  project.*  parameters'" />
            <xsl:with-param name="incorrect-use" select="not(($exercise.text.statement = '') and ($exercise.text.hint = '') and ($exercise.text.answer = '') and ($exercise.text.solution = '') and ($project.text.hint = '') and ($project.text.answer = '') and ($project.text.solution = '') and ($task.text.hint = '') and ($task.text.answer = '') and ($task.text.solution = ''))"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2018-11-07  obsolete backmatter exercise component switches -->
    <!-- Still exists in "String Parameter Bad Bank" for use here    -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2018-11-07'" />
        <xsl:with-param name="message" select="'the  exercise.backmatter.*  parameters that control the visibility of components of exercises and projects in the back matter have been removed and replaced by the &quot;solutions&quot; element, which is much more versatile'"/>
            <xsl:with-param name="incorrect-use" select="not(($exercise.backmatter.statement = '') and ($exercise.backmatter.hint = '') and ($exercise.backmatter.answer = '') and ($exercise.backmatter.solution = ''))" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-10  obsolete  html.css.file  removed             -->
    <!-- Still exists in "String Parameter Bad Bank" for use here -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-02-10'" />
        <xsl:with-param name="message" select="'the obsolete  html.css.file  parameter has been removed, please use html.css.colorfile to choose a color scheme'" />
            <xsl:with-param name="incorrect-use" select="($html.css.file != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-20  replace author-tools with author.tools                       -->
    <!-- Still exists and is respected, move to "String Parameter Bad Bank" later -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-02-20'" />
        <xsl:with-param name="message" select="'the  author-tools  parameter has been replaced by the functionally equivalent  author.tools'" />
            <xsl:with-param name="incorrect-use" select="not($author-tools = '')"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-03-07  replace latex.watermark with watermark.text                  -->
    <!-- 2022-10-24  update - to publication file                                 -->
    <!-- Still exists and is respected, move to "String Parameter Bad Bank" later -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-03-07'" />
        <xsl:with-param name="message" select="'the  latex.watermark  string parameter has been replaced by a publication file entry which is effective in HTML as well as LaTeX'" />
            <xsl:with-param name="incorrect-use" select="($latex.watermark != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-03-07  replace latex.watermark.scale with watermark.scale           -->
    <!-- 2022-10-24  update - to publication file                                 -->
    <!-- Still exists and is respected, move to "String Parameter Bad Bank" later -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-03-07'" />
        <xsl:with-param name="message" select="'the  latex.watermark.scale  string parameter has been replaced by a publication file entry which is effective in HTML as well as LaTeX'" />
            <xsl:with-param name="incorrect-use" select="($latex.watermark.scale != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- And switches for analytics  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-11-28'" />
        <xsl:with-param name="message" select="'use of string parameters for analytics configuration has been deprecated.  Existing switches are being respected, but please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.&#xa;  * For StatCounter this is a cosmetic change.&#xa;  * Google Classic has been deprecated by Google and will not be supported.&#xa;  * Google Universal has been replaced, your ID may continue to work.&#xa;  * Google Global Site Tag is fully supported, try your Universal ID.&#xa;'" />
            <xsl:with-param name="incorrect-use" select="($html.statcounter.project != '') or ($html.statcounter.security != '') or ($html.google-classic != '') or ($html.google-universal != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-11-29  deprecated Google search via string parameter -->
    <!-- see 2019-04-14 for docinfo deprecation                    -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-11-29'" />
        <xsl:with-param name="message" select="'Google search is no longer specified with a string parameter.  Please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
            <xsl:with-param name="incorrect-use" select="$html.google-search != ''" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-05-10  permalinks (their style actually) are now controlled by Javascript -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-05-10'" />
        <xsl:with-param name="message" select="'the  html.permalink  parameter is now obsolete and will be ignored as this is now controlled by Javascript'" />
        <xsl:with-param name="incorrect-use" select="($html.permalink != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-05-29  HTML calculator model controlled by publisher file -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-05-29'" />
        <xsl:with-param name="message" select="'the  html.calculator  parameter has been replaced by the  html/calculator/@model  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.calculator != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-11-22  LaTeX print option controlled by publisher file -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-11-22'" />
        <xsl:with-param name="message" select="'the  latex.print  parameter has been replaced by the  latex/@print  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($latex.print != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-11-22  LaTeX sideness option controlled by publisher file -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-11-22'" />
        <xsl:with-param name="message" select="'the  latex.sides  parameter has been replaced by the  latex/@sides  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($latex.sides != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2021-01-03  chunk.level now in publisher file -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-03'" />
        <xsl:with-param name="message" select="'the  chunk.level  parameter has been replaced by the  common/chunking/@level  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($chunk.level != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2021-01-03  toc.level now in publisher file -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-03'"/>
        <xsl:with-param name="message" select="'the  toc.level  parameter has been replaced by the  common/tableofcontents/@level  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($toc.level != '')" />
    </xsl:call-template>
    <!-- 2020-11-23  directory.images replaced by publisher file specification -->
    <!-- Reverse this soon, hot fix -->
    <!--
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-11-23'" />
        <xsl:with-param name="message" select="'the  directory.images  parameter has been replaced by specification of two directories in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($directory.images != '')" />
    </xsl:call-template>
 -->
    <!--  -->
    <!--                                                  -->
    <!-- 2021-01-23  Seventeen old knowl-ization switches -->
    <!--                                                  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.theorem  parameter has been replaced by the  html/knowl/@theorem  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.theorem != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.proof  parameter has been replaced by the  html/knowl/@proof  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.proof != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.definition  parameter has been replaced by the  html/knowl/@definition  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.definition != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.example  parameter has been replaced by the  html/knowl/@example  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.example != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.project  parameter has been replaced by the  html/knowl/@project  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.project != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.task  parameter has been replaced by the  html/knowl/@task  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.task != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.list  parameter has been replaced by the  html/knowl/@list  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.list != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.remark  parameter has been replaced by the  html/knowl/@remark  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.remark != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.objectives  parameter has been replaced by the  html/knowl/@objectives  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.objectives != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.outcomes  parameter has been replaced by the  html/knowl/@outcomes  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.outcomes != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.figure  parameter has been replaced by the  html/knowl/@figure  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.figure != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.table  parameter has been replaced by the  html/knowl/@table  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.table != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.listing  parameter has been replaced by the  html/knowl/@listing  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.listing != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.exercise.inline  parameter has been replaced by the  html/knowl/@exercise-inline  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.exercise.inline != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.exercise.sectional  parameter has been replaced by the  html/knowl/@exercise-divisional  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.exercise.sectional != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.exercise.worksheet  parameter has been replaced by the  html/knowl/@exercise-worksheet  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.exercise.worksheet != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-01-23'" />
        <xsl:with-param name="message" select="'the  html.knowl.exercise.readingquestion  parameter has been replaced by the  html/knowl/@exercise-readingquestion  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.exercise.readingquestion != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2014-02-14 Five parameters for numbering level to publisher file -->
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-02-14'" />
        <xsl:with-param name="message" select="'the  numbering.maximum.level  parameter has been replaced by the  numbering/divisions/@level  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($numbering.maximum.level != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-02-14'" />
        <xsl:with-param name="message" select="'the  numbering.theorems.level  parameter has been replaced by the  numbering/blocks/@level  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($numbering.theorems.level != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-02-14'" />
        <xsl:with-param name="message" select="'the  numbering.projects.level  parameter has been replaced by the  numbering/projects/@level  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($numbering.projects.level != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-02-14'" />
        <xsl:with-param name="message" select="'the  numbering.equations.level  parameter has been replaced by the  numbering/equations/@level  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($numbering.equations.level != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-02-14'" />
        <xsl:with-param name="message" select="'the  numbering.footnotes.level  parameter has been replaced by the  numbering/footnotes/@level  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($numbering.footnotes.level != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-02-14'" />
        <xsl:with-param name="message" select="'the  debug.chapter.start  parameter has been removed entirely and so will be ignored.  Please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($debug.chapter.start != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2021-11-04'" />
        <xsl:with-param name="message" select="'the  text.alignment  parameter has been deprecated, but we will attempt to honor your intent.  Please switch to using the Publishers File for configuration of LaTeX page shape, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($text.alignment != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 1/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.inline.statement  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.inline.statement != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 2/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.inline.hint  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.inline.hint != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 3/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.inline.answer  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.inline.answer != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 4/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.inline.solution  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.inline.solution != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 5/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.divisional.statement  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.divisional.statement != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 6/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.divisional.hint  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.divisional.hint != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 7/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.divisional.answer  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.divisional.answer != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 8/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.divisional.solution  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.divisional.solution != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 9/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.worksheet.statement  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.worksheet.statement != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 10/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.worksheet.hint  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.worksheet.hint != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 11/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.worksheet.answer  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.worksheet.answer != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 12/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.worksheet.solution  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.worksheet.solution != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 13/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.reading.statement  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.reading.statement != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 14/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.reading.hint  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.reading.hint != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 15/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.reading.answer  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.reading.answer != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 16/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  exercise.reading.solution  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($exercise.reading.solution != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 17/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  project.statement  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($project.statement != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 18/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  project.hint  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($project.hint != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 19/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  project.answer  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($project.answer != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-01-31  exercise component visibility setting 20/20 -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-01-31'" />
        <xsl:with-param name="message" select="'the  project.solution  string parameter is now deprecated, but we will attempt to honor your intent.  Please switch to using the Publication File, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($project.solution != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-05-23  experimental scheme for "fast-id" abandonend -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-05-23'" />
        <xsl:with-param name="message" select="'the  oldids  string parameter was used for testing, was deprecated on 2021-03-03, is now obsolete, there is no replacement, relevant code has been removed, and the parameter is being ignored'" />
        <xsl:with-param name="incorrect-use" select="($oldids != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-05-28  "latex.fillin.style" is deprecated for publisher variables -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-05-28'" />
        <xsl:with-param name="message" select="'the  latex.fillin.style  parameter has been replaced by the  common/fillin/@textstyle  and  common/fillin/mathstyle  entries in the publication file. The default style for a text fillin is now  underline  and the default style for a math fillin is now  shade .  To use  box  style for either, set values in the publication file.'" />
        <xsl:with-param name="incorrect-use" select="($numbering.maximum.level != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-10-24  "latex.font.size" is deprecated for publisher variables -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-10-24'" />
        <xsl:with-param name="message" select="'the  latex.font.size  parameter has been replaced by the  latex/@font-size  entry in the publication file.   We will attempt to honor your intent.  Note that possible values are the same, but you no longer provide &quot;pt&quot; as the unit of measure.'" />
        <xsl:with-param name="incorrect-use" select="($latex.font.size != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-10-24  "latex.geometry" is deprecated for publisher variables -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-10-24'" />
        <xsl:with-param name="message" select="'the  latex.geometry  parameter has been replaced by the  latex/page/geometry  entry in the publication file.  We will attempt to honor your intent.'" />
        <xsl:with-param name="incorrect-use" select="($latex.geometry != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-10-24  "latex.pageref" is deprecated for publisher variables -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-10-24'" />
        <xsl:with-param name="message" select="'the  latex.pageref string parameter has been replaced by the  latex/@pageref  entry in the publication file.  We will attempt to honor your intent.'" />
        <xsl:with-param name="incorrect-use" select="($latex.pageref != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-10-24  "latex.draft" is deprecated for publisher variables -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-10-24'" />
        <xsl:with-param name="message" select="'the  latex.draft string parameter has been replaced by the  latex/@draft  entry in the publication file.  We will attempt to honor your intent.'" />
        <xsl:with-param name="incorrect-use" select="($latex.draft != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-10-24  watermark.text  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-10-24'" />
        <xsl:with-param name="message" select="'the  watermark.text  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($watermark.text != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-10-24  watermark.scale  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-10-24'" />
        <xsl:with-param name="message" select="'the  watermark.scale  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($watermark.scale != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-11-19  webwork.inline.static  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-11-19'" />
        <xsl:with-param name="message" select="'the  webwork.inline.static  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($webwork.inline.static != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-11-19  webwork.divisional.static  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-11-19'" />
        <xsl:with-param name="message" select="'the  webwork.divisional.static  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($webwork.divisional.static != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-11-19  webwork.reading.static  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-11-19'" />
        <xsl:with-param name="message" select="'the  webwork.reading.static  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($webwork.reading.static != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-11-19  webwork.worksheet.static  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-11-19'" />
        <xsl:with-param name="message" select="'the  webwork.worksheet.static  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($webwork.worksheet.static != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-11-19  webwork.project.static  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-11-19'" />
        <xsl:with-param name="message" select="'the  webwork.project.static  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($webwork.project.static != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-11-20  html.navigation.logic  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-11-20'" />
        <xsl:with-param name="message" select="'the  html.navigation.logic  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($html.navigation.logic != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-11-20  html.navigation.upbutton  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-11-20'" />
        <xsl:with-param name="message" select="'the  html.navigation.upbutton  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($html.navigation.upbutton != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-11-20  html.navigation.style  deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-11-20'" />
        <xsl:with-param name="message" select="'the  html.navigation.style  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($html.navigation.style != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2022-11-20  emdash.space deprecated in favor of publication file entry-->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2022-11-20'" />
        <xsl:with-param name="message" select="'the  emdash.space  string parameter has been replaced by a publication file entry.  We will try to honor your intent.'" />
            <xsl:with-param name="incorrect-use" select="($emdash.space != '')" />
    </xsl:call-template>
    <!--  -->
</xsl:template>

</xsl:stylesheet>
