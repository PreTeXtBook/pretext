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
    <xsl:apply-templates select="$publisher-attribute-options/common/chunking/pi:pub-attribute[@name='level']" mode="set-pubfile-variable"/>
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
    <xsl:apply-templates select="$publisher-attribute-options/common/tableofcontents/pi:pub-attribute[@name='level']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:template match="common/tableofcontents/pi:pub-attribute[@name='level']" mode="get-default-pub-variable">
    <xsl:choose>
        <!-- defaults purely by structure, not by output format -->
        <xsl:when test="$version-root/book/part/chapter/section">3</xsl:when>
        <xsl:when test="$version-root/book/part/chapter">2</xsl:when>
        <xsl:when test="$version-root/book/chapter/section">2</xsl:when>
        <xsl:when test="$version-root/book/chapter">1</xsl:when>
        <xsl:when test="$version-root/article/section/subsection">2</xsl:when>
        <xsl:when test="$version-root/article/section|$version-root/article/worksheet|$version-root/article/handout">1</xsl:when>
        <xsl:when test="$version-root/article">0</xsl:when>
        <xsl:when test="$version-root/slideshow">0</xsl:when>
        <xsl:when test="$version-root/letter">0</xsl:when>
        <xsl:when test="$version-root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Table of Contents level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:variable name="toc-level" select="number($toc-level-entered)"/>

<!-- Flag Table of Contents, or not, with boolean variable -->
<xsl:variable name="b-has-toc" select="$toc-level > 0" />

<!-- Fillin styles (underline, box, shade) -->
<xsl:variable name="fillin-text-style">
    <xsl:apply-templates select="$publisher-attribute-options/common/fillin/pi:pub-attribute[@name='textstyle']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="fillin-math-style">
    <xsl:apply-templates select="$publisher-attribute-options/common/fillin/pi:pub-attribute[@name='mathstyle']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="mermaid-theme">
    <xsl:apply-templates select="$publisher-attribute-options/common/mermaid/pi:pub-attribute[@name='theme']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- QR code image to be placed at center of QR codes -->
<xsl:variable name="qrcode-image">
    <xsl:apply-templates select="$publisher-attribute-options/common/qrcode/pi:pub-attribute[@name='image']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- Em dash Width -->

<xsl:variable name="emdash-space">
    <xsl:apply-templates select="$publisher-attribute-options/common/pi:pub-attribute[@name='emdash-space']" mode="set-pubfile-variable"/>
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

<!-- Journal name for bibliography formatting and latex style selection -->
<xsl:variable name="journal-name">
    <xsl:apply-templates select="$publisher-attribute-options/common/journal/pi:pub-attribute[@name='name']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- This is the minimum information to locate a     -->
<!-- Citation Stylesheet Language (CSL) style file   -->
<!-- in the CSL repository.  It is not expected to   -->
<!-- have the ".csl" suffix, but should have partial -->
<!-- path names, such as "dependent/".  Employers    -->
<!-- should provide ".cls" and any additional path   -->
<!-- information.                                    -->
<xsl:variable name="csl-style-file">
    <xsl:apply-templates select="$publisher-attribute-options/common/citation-stylesheet-language/pi:pub-attribute[@name='style']" mode="set-pubfile-variable"/>
</xsl:variable>
<!-- global indication of if a publisher has opted in -->
<xsl:variable name="b-using-csl-styles" select="not(normalize-space($csl-style-file) = '')"/>
<!-- if using styles we form the filename of generated references and citations -->
<xsl:variable name="csl-file">
    <xsl:choose>
        <xsl:when test="$b-using-csl-styles">
            <xsl:value-of select="$generated-directory-source"/>
            <xsl:text>references/csl-bibliography.xml</xsl:text>
        </xsl:when>
        <!-- explicitly empty/null if not using CSL styles -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- Worksheet margins.  Applies to both PDF and HTML. -->

<xsl:variable name="ws-margin">
    <xsl:apply-templates select="$publisher-attribute-options/common/worksheet/pi:pub-attribute[@name='margin']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:variable name="ws-margin-top">
    <xsl:apply-templates select="$publisher-attribute-options/common/worksheet/pi:pub-attribute[@name='top']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:variable name="ws-margin-right">
    <xsl:apply-templates select="$publisher-attribute-options/common/worksheet/pi:pub-attribute[@name='right']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:variable name="ws-margin-bottom">
    <xsl:apply-templates select="$publisher-attribute-options/common/worksheet/pi:pub-attribute[@name='bottom']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:variable name="ws-margin-left">
    <xsl:apply-templates select="$publisher-attribute-options/common/worksheet/pi:pub-attribute[@name='left']" mode="set-pubfile-variable"/>
</xsl:variable>
<!-- Set the default values of each directional margin to be the value of the ws-margin element -->
<xsl:template match="common/worksheet/pi:pub-attribute[@name='top']" mode="get-default-pub-variable">
    <xsl:value-of select="$ws-margin"/>
</xsl:template>
<xsl:template match="common/worksheet/pi:pub-attribute[@name='right']" mode="get-default-pub-variable">
    <xsl:value-of select="$ws-margin"/>
</xsl:template>
<xsl:template match="common/worksheet/pi:pub-attribute[@name='bottom']" mode="get-default-pub-variable">
    <xsl:value-of select="$ws-margin"/>
</xsl:template>
<xsl:template match="common/worksheet/pi:pub-attribute[@name='left']" mode="get-default-pub-variable">
    <xsl:value-of select="$ws-margin"/>
</xsl:template>


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
<!-- error-checking.  If not set/present, then an empty string.   -->
<!-- NB: the empty string is checked in pretext-assembly.xsl to   -->
<!-- prevent unnecessary manipulations of "exercise" and "task"   -->
<!-- when no file is indicated.                                   -->

<xsl:variable name="private-solutions-file">
    <xsl:choose>
        <xsl:when test="$publication/source/@private-solutions">
            <xsl:value-of select="str:replace($publication/source/@private-solutions, '&#x20;', '%20')"/>
        </xsl:when>
        <!-- sentinel for no private solution manipulation -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-private-solutions" select="not($private-solutions-file = '')"/>


<!-- ############### -->
<!-- WeBWorK Options -->
<!-- ############### -->

<!-- How to process PG for static output -->
<xsl:variable name="webwork-static-processing">
    <xsl:apply-templates select="$publisher-attribute-options/webwork/pi:pub-attribute[@name='static-processing']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- Location of PG library for local static processing -->
<xsl:variable name="webwork-pg-location">
    <xsl:apply-templates select="$publisher-attribute-options/webwork/pi:pub-attribute[@name='pg-location']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- WeBWorK server location and credentials for the daemon course -->
<xsl:variable name="webwork-server">
    <xsl:apply-templates select="$publisher-attribute-options/webwork/pi:pub-attribute[@name='server']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="webwork-course">
    <xsl:apply-templates select="$publisher-attribute-options/webwork/pi:pub-attribute[@name='course']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="webwork-user">
    <xsl:apply-templates select="$publisher-attribute-options/webwork/pi:pub-attribute[@name='user']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="webwork-password">
    <xsl:choose>
        <!-- For backwards compatibility -->
        <xsl:when test="$publication/webwork/@coursepassword">
            <xsl:value-of select="$publication/webwork/@coursepassword"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="$publisher-attribute-options/webwork/pi:pub-attribute[@name='password']" mode="set-pubfile-variable"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- WeBWorK tasks can be revealed incrementally or all at once -->
<xsl:variable name="webwork-task-reveal">
    <xsl:apply-templates select="$publisher-attribute-options/webwork/pi:pub-attribute[@name='task-reveal']" mode="set-pubfile-variable"/>
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

<!-- Dynamic problem substitutions are formed by Python routines    -->
<!-- in the   pretext.py  module that opens HTML representations    -->
<!-- on a local http.server process. The summary of all             -->
<!-- are recorded in the dynamic-substitutions-file.                -->
<xsl:variable name="dynamic-substitutions-file">
    <!-- Only relevant if there are dynamic exercises present.      -->
    <xsl:if test="$original//exercise//setup">
        <xsl:choose>
            <!-- Look in the publication file for the generated directory -->
            <xsl:when test="$publication/source/directories/@generated">
                <xsl:value-of select="str:replace(concat($generated-directory-source, 'dynamic_subs/dynamic_substitutions.xml'), '&#x20;', '%20')"/>
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
<!-- means it has not been set, while  @include=""  yields "||".     -->
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
            <xsl:when test="$version-root/book/part">5</xsl:when>
            <xsl:when test="$version-root/book">4</xsl:when>
            <xsl:when test="$version-root/article/section|$version-root/article/worksheet">3</xsl:when>
            <xsl:when test="$version-root/article">0</xsl:when>
            <xsl:when test="$version-root/letter">0</xsl:when>
            <xsl:when test="$version-root/slideshow">0</xsl:when>
            <xsl:when test="$version-root/memo">0</xsl:when>
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
            <xsl:when test="$version-root/book/part">3</xsl:when>
            <xsl:when test="$version-root/book">2</xsl:when>
            <xsl:when test="$version-root/article/section|$version-root/article/worksheet">1</xsl:when>
            <xsl:when test="$version-root/article">0</xsl:when>
            <xsl:when test="$version-root/slideshow">0</xsl:when>
            <xsl:when test="$version-root/letter">0</xsl:when>
            <xsl:when test="$version-root/memo">0</xsl:when>
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
            <xsl:when test="$version-root/book/part">3</xsl:when>
            <xsl:when test="$version-root/book">2</xsl:when>
            <xsl:when test="$version-root/article/section|$version-root/article/worksheet">1</xsl:when>
            <xsl:when test="$version-root/article">0</xsl:when>
            <xsl:when test="$version-root/slideshow">0</xsl:when>
            <xsl:when test="$version-root/letter">0</xsl:when>
            <xsl:when test="$version-root/memo">0</xsl:when>
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
            <xsl:when test="$version-root/book/part">3</xsl:when>
            <xsl:when test="$version-root/book">2</xsl:when>
            <xsl:when test="$version-root/article/section|$version-root/article/worksheet">1</xsl:when>
            <xsl:when test="$version-root/article">0</xsl:when>
            <xsl:when test="$version-root/slideshow">0</xsl:when>
            <xsl:when test="$version-root/letter">0</xsl:when>
            <xsl:when test="$version-root/memo">0</xsl:when>
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
            <xsl:when test="$version-root/book/part">3</xsl:when>
            <xsl:when test="$version-root/book">2</xsl:when>
            <xsl:when test="$version-root/article/section|$version-root/article/worksheet">1</xsl:when>
            <xsl:when test="$version-root/article">0</xsl:when>
            <xsl:when test="$version-root/slideshow">0</xsl:when>
            <xsl:when test="$version-root/letter">0</xsl:when>
            <xsl:when test="$version-root/memo">0</xsl:when>
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
        <xsl:when test="not($version-root/book/part)">
            <xsl:choose>
                <xsl:when test="$publication/numbering/divisions/@part-structure">
                    <xsl:message>PTX:WARNING: your document is not a book with parts, so the publisher file  numbering/divisions/@part-structure  entry is being ignored</xsl:message>
                </xsl:when>
                <xsl:when test="$version-docinfo/numbering/division/@part">
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
        <xsl:when test="$version-docinfo/numbering/division/@part">
            <xsl:choose>
                <xsl:when test="$version-docinfo/numbering/division/@part = 'structural'">
                    <xsl:text>structural</xsl:text>
                </xsl:when>
                <xsl:when test="$version-docinfo/numbering/division/@part = 'decorative'">
                    <xsl:text>decorative</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: the  docinfo/numbering/division/@part  entry should be "decorative" or "structural", not "<xsl:value-of select="$version-docinfo/numbering/division/@part"/>".  The default will be used instead.</xsl:message>
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
    <xsl:apply-templates select="$publisher-attribute-options/html/calculator/pi:pub-attribute[@name='model']" mode="set-pubfile-variable"/>
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
    <xsl:apply-templates select="$publisher-attribute-options/html/pi:pub-attribute[@name='short-answer-responses']" mode="set-pubfile-variable"/>
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

<!--                      -->
<!-- HTML Feedback Button -->
<!--                      -->

<xsl:variable name="feedback-button-href">
    <!-- internal variable, just for error-checking -->
    <xsl:variable name="attempted-href">
        <xsl:if test="$publication/html/feedback/@href">
            <xsl:value-of select="$publication/html/feedback/@href"/>
        </xsl:if>
        <!-- default to empty, as a signal of failure -->
    </xsl:variable>
    <!-- we error-check a bad @href *only* as a publisher -->
    <!-- variable, and not in the deprecated situation    -->
    <xsl:if test="$publication/html/feedback and ($attempted-href = '')">
        <xsl:message>PTX:ERROR:  an HTML "feedback" button with an empty, or missing, @href will be ineffective, or worse, non-existent</xsl:message>
    </xsl:if>
    <!-- now capture the internal variable -->
    <xsl:value-of select="$attempted-href"/>
</xsl:variable>

<!-- Pure text, no markup, no math, etc. -->
<!-- Empty is a meaningful value         -->
<xsl:variable name="feedback-button-text">
    <xsl:variable name="provided-button-text">
        <xsl:if test="$publication/html/feedback">
            <xsl:value-of select="$publication/html/feedback"/>
        </xsl:if>
    </xsl:variable>
    <!-- Clean-up *and* utilize emptieness as a signal to use -->
    <!-- default text. If empty, provide default text in      -->
    <!-- language of the page at implementation time          -->
    <xsl:value-of select="normalize-space($provided-button-text)"/>
</xsl:variable>

<!-- Since we capture alternate text easily, and   -->
<!-- we *need* an @href, we use this as the signal -->
<!-- for the election of a feedback button         -->
<xsl:variable name="b-has-feedback-button" select="not($feedback-button-href = '')"/>

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
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='theorem']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-proof">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='proof']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-definition">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='definition']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-example">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='example']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-example-solution">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='example-solution']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-project">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='project']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-task">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='task']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-list">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='list']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-remark">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='remark']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-objectives">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='objectives']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-outcomes">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='outcomes']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-figure">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='figure']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-table">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='table']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-listing">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='listing']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-exercise-inline">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='exercise-inline']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-exercise-divisional">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='exercise-divisional']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-exercise-worksheet">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='exercise-worksheet']" mode="set-pubfile-variable"/>
</xsl:variable>

<xsl:variable name="knowl-exercise-readingquestion">
    <xsl:apply-templates select="$publisher-attribute-options/html/knowl/pi:pub-attribute[@name='exercise-readingquestion']" mode="set-pubfile-variable"/>
</xsl:variable>

<!--                   -->
<!-- HTML Tabbed Tasks -->
<!--                   -->

<!-- Presentational choice for exercises and projects that are  -->
<!-- structured by task.  Value is a list of possible types,    -->
<!-- seen in creation of four boolean variables.  Never for the -->
<!-- fifth type: "exercise" inside a "worksheet".               -->

<xsl:variable name="html-tabbed-tasks" select="str:tokenize($publication/html/exercises/@tabbed-tasks, ' ,')"/>

<!-- A string is equal to a node-set (the result of tokenize()) -->
<!-- if it is equal to *one* child's text value.                -->
<xsl:variable name="b-html-tabbed-tasks-divisional" select="'divisional' = $html-tabbed-tasks"/>
<xsl:variable name="b-html-tabbed-tasks-inline" select="'inline' = $html-tabbed-tasks"/>
<xsl:variable name="b-html-tabbed-tasks-reading" select="'reading' = $html-tabbed-tasks"/>
<xsl:variable name="b-html-tabbed-tasks-project" select="'project' = $html-tabbed-tasks"/>

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
        <!-- if publisher file has a base url, use it -->
        <xsl:if test="$publication/html/baseurl/@href">
            <xsl:value-of select="$publication/html/baseurl/@href"/>
        </xsl:if>
        <!-- otherwise use the default, is empty as sentinel -->
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
<!-- For determining use in places such as static interactives -->
<xsl:variable name="b-has-baseurl" select="not($baseurl = '')"/>

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
    <xsl:apply-templates select="$publisher-attribute-options/html/navigation/pi:pub-attribute[@name='logic']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- The "up" button is optional given the contents sidebar, default is to have it -->
<!-- An up button is very desirable if you use the tree-like logic                 -->
<xsl:variable name="nav-upbutton">
    <xsl:apply-templates select="$publisher-attribute-options/html/navigation/pi:pub-attribute[@name='upbutton']" mode="set-pubfile-variable"/>
</xsl:variable>

<!--                 -->
<!-- HTML TOC        -->
<!--                 -->

<!-- Whether or not to tag TOC as focused -->
<xsl:variable name="html-toc-focused_value">
    <xsl:choose>
        <xsl:when test="$html-theme-name = 'custom' or $b-html-theme-legacy">
            <!-- legacy/custom themes can pick whether to use a focused toc or not -->
            <xsl:apply-templates select="$publisher-attribute-options/html/tableofcontents/pi:pub-attribute[@name='focused']" mode="set-pubfile-variable"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- newer ones determined by theme                                -->
            <xsl:if test="$html-theme/@focused-toc"><xsl:value-of select="$html-theme/@focused-toc"/></xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-html-toc-focused" select="$html-toc-focused_value='yes'"/>

<!-- How many levels from root to pre-expand in focused view -->
<xsl:variable name="html-toc-preexpanded-levels">
    <xsl:variable name="preexpanded-value" >
        <xsl:apply-templates select="$publisher-attribute-options/html/tableofcontents/pi:pub-attribute[@name='preexpanded-levels']" mode="set-pubfile-variable"/>
    </xsl:variable>
    <xsl:if test="not($b-html-toc-focused) and $preexpanded-value > 0">
        <xsl:message>PTX:WARNING:   the preexpanded-levels setting (html/tableofcontents/@preexpanded-levels in the publisher file) has no effect if the table of contents is not set to focused mode (/html/tableofcontents/@focused is "yes")."</xsl:message>
    </xsl:if>
    <xsl:value-of select="$preexpanded-value"/>
</xsl:variable>

<!--                 -->
<!-- HTML XREFS      -->
<!--                 -->

<!-- How to render xrefs. Default is "maximum" which renders xrefs to divisions as -->
<!-- links and other xrefs as knowls. "never" renders all xrefs as links.          -->
<!-- "cross-page" renders like "never" within a page and "maximum" otherwise.       -->
<xsl:variable name="html-xref-knowled">
    <xsl:apply-templates select="$publisher-attribute-options/html/cross-references/pi:pub-attribute[@name='knowled']" mode="set-pubfile-variable"/>
</xsl:variable>

<!--                              -->
<!-- HTML CSS Style Specification -->
<!--                              -->

<!-- A temporary variable for testing -->
<xsl:param name="debug.colors" select="''"/>
<!-- A space-separated list of CSS URLs (points to servers or local files) -->
<xsl:param name="html.css.extra"  select="''" />
<!-- A single JS file for development purposes -->
<xsl:param name="html.js.extra" select="''" />

<!-- Name of color file possibly used in legacy styling -->
<xsl:variable name="html.css.colors">
    <xsl:value-of select="$publication/html/css/@colors"/>
</xsl:variable>

<!--                              -->
<!-- HTML Theme Specification     -->
<!--                              -->

<xsl:variable name="html-theme-name">
    <xsl:variable name="warning-message">PTX:WARNING: The "FROMSTYLE" style requested in publication/html/css is deprecated. Your book will be built with theme="TOSTYLE". See the PreTeXt Guide for options for the newer HTML themes and their specification .</xsl:variable>
    <xsl:choose>
        <xsl:when test="$publication/html/css/@theme">
            <xsl:value-of select="$publication/html/css/@theme"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- legacy style detection and overriding -->
            <xsl:choose>
                <!-- crc and min are best detected via @shell -->
                <xsl:when test="contains($publication/html/css/@shell, 'crc')">
                    <xsl:message><xsl:value-of select="str:replace(str:replace($warning-message, 'FROMSTYLE', 'crc'), 'TOSTYLE', 'denver')"/></xsl:message>
                    <xsl:text>denver</xsl:text>
                </xsl:when>
                <xsl:when test="contains($publication/html/css/@shell, 'min')">
                    <xsl:message><xsl:value-of select="str:replace(str:replace($warning-message, 'FROMSTYLE', 'min'), 'TOSTYLE', 'tacoma')"/></xsl:message>
                    <xsl:text>tacoma</xsl:text>
                </xsl:when>
                <!-- others by @style                         -->
                <xsl:when test="contains($publication/html/css/@style, 'wide')">
                    <xsl:message><xsl:value-of select="str:replace(str:replace($warning-message, 'FROMSTYLE', 'wide'), 'TOSTYLE', 'salem')"/></xsl:message>
                    <xsl:text>salem</xsl:text>
                </xsl:when>
                <xsl:when test="contains($publication/html/css/@style, 'oscarlevin')">
                    <xsl:message><xsl:value-of select="str:replace(str:replace($warning-message, 'FROMSTYLE', 'oscarlevin'), 'TOSTYLE', 'denver')"/></xsl:message>
                    <xsl:text>denver</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="legacy-style">
                    <xsl:value-of select="$publication/html/css/@style"/>
                  </xsl:variable>
                  <xsl:message><xsl:value-of select="str:replace(str:replace($warning-message, 'FROMSTYLE', $legacy-style), 'TOSTYLE', 'default-modern')"/></xsl:message>
                  <xsl:text>default-modern</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="b-html-theme-legacy" select="contains($html-theme-name, '-legacy')"/>

<xsl:variable name="html-palette-name">
    <xsl:apply-templates select="$publisher-attribute-options/html/css/pi:pub-attribute[@name='palette']" mode="set-pubfile-variable"/>
</xsl:variable>


<!-- lookup dict for known theme options -->
<xsl:variable name="html-theme-option-list">
    <theme name="default-modern" focused-toc="yes">
        <option name="provide-dark-mode" default="yes"/>
        <option name="palette" default="default"/>
        <option name="primary-color" check-contrast="#fff"/>
        <option name="secondary-color" check-contrast="#fff"/>
        <option name="primary-color-dark" check-contrast="#23241f"/>
    </theme>
    <theme name="denver" focused-toc="yes">
        <option name="provide-dark-mode" default="yes"/>
        <option name="palette" default="default"/>
        <option name="color-main" check-contrast="#fff"/>
        <option name="color-do" check-contrast="#fff"/>
        <option name="color-fact" check-contrast="#fff"/>
        <option name="color-meta" check-contrast="#fff"/>
        <option name="primary-color-dark" check-contrast="#23241f"/>
    </theme>
    <theme name="tacoma"  focused-toc="yes">
        <option name="provide-dark-mode" default="yes"/>
        <option name="primary-color" check-contrast="#fff"/>
        <option name="primary-color-dark" check-contrast="#23241f"/>
    </theme>
    <theme name="salem" focused-toc="yes">
        <option name="provide-dark-mode" default="yes"/>
        <option name="palette" default="default"/>
        <option name="color-main" check-contrast="#fff"/>
        <option name="color-do" check-contrast="#fff"/>
        <option name="color-fact" check-contrast="#fff"/>
        <option name="color-meta" check-contrast="#fff"/>
        <option name="primary-color-dark" check-contrast="#23241f"/>
    </theme>
    <theme name="greeley">
        <option name="provide-dark-mode" default="yes"/>
        <option name="primary-color" check-contrast="#fff"/>
        <option name="primary-color-dark" check-contrast="#23241f"/>
    </theme>
    <theme name="boulder">
        <option name="provide-dark-mode" default="yes"/>
        <option name="primary-color" check-contrast="#fff"/>
        <option name="primary-color-dark" check-contrast="#23241f"/>
    </theme>
    <theme name="custom">
        <option name="provide-dark-mode" default="yes"/>
        <option name="entry-point" default="custom-theme.scss"/>
    </theme>
</xsl:variable>

<!-- Setup and use key to get the active theme                          -->
<xsl:key name="html-theme-option-key" match="theme" use="@name"/>
<xsl:variable name="html-theme-rtf">
    <xsl:for-each select="exsl:node-set($html-theme-option-list)">
        <xsl:copy-of select="key('html-theme-option-key', $html-theme-name)"/>
    </xsl:for-each>
</xsl:variable>

<!-- Turn tree fragment into a node-set containing the selected theme   -->
<xsl:variable name="html-theme" select="exsl:node-set($html-theme-rtf)/theme"/>

<!-- Get an option (attr) from pub file css/theme. Available options    -->
<!-- are constrained by html-theme-option-list above.                   -->
<xsl:template name="get-theme-option">
    <xsl:param name="optname"/>
    <xsl:choose>
        <!-- Must be an option in the theme or a custom theme -->
        <xsl:when test="$html-theme/option[@name = $optname] or $html-theme[@name = 'custom']">
            <xsl:choose>
                <xsl:when test="$publication/html/css/@*[name() = $optname]">
                    <!-- Exists in pub file, use that -->
                    <xsl:value-of select="$publication/html/css/@*[name() = $optname]"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Use default from theme def -->
                    <xsl:value-of select="$html-theme/option[@name = $optname]/@default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- <xsl:otherwise>
            <xsl:message>PTX:WARNING: HTML theme "<xsl:value-of select="$html-theme-name"/>" does not support option "<xsl:value-of select="$optname"/>".</xsl:message>
        </xsl:otherwise> -->
    </xsl:choose>
</xsl:template>

<!-- Test if current theme supports dark mode                           -->
<xsl:variable name="theme-has-darkmode">
    <xsl:call-template name="get-theme-option">
        <xsl:with-param name="optname" select="'provide-dark-mode'"/>
    </xsl:call-template>
</xsl:variable>

<xsl:variable name="b-theme-has-darkmode" select="$theme-has-darkmode = 'yes'"/>

<!-- Grabs the html theme options element and returns its attr/values   -->
<!-- in JSON format for use by theme build tools.                       -->
<xsl:variable name="html-theme-options">
    <xsl:text>{</xsl:text>
        <xsl:text>&quot;options&quot;:{</xsl:text>
        <!-- if inside for-each, so can't use position to selectively add -->
        <!-- commas. So build a string with a , after each item           -->
        <xsl:variable name="options-string">
            <xsl:for-each select="$publication/html/css/@*">
                <xsl:variable name="optname" select="name(.)"/>
                <!-- only pass on values that match theme options unless custom -->
                <xsl:if test="$html-theme/option[@name = $optname] or $html-theme[@name = 'custom']">
                    <xsl:value-of select="concat('&quot;', name(.), '&quot;:')"/>
                    <xsl:value-of select="concat('&quot;', ., '&quot;')"/>
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <!-- then trim the trailing ,                                     -->
        <xsl:value-of select="substring($options-string, 1, string-length($options-string) - 1)"/>
        <xsl:text>}</xsl:text>
        <xsl:text>,&quot;contrast-checks&quot;:{</xsl:text>
        <xsl:for-each select="$html-theme/*[@check-contrast]">
            <xsl:if test="position() > 1"><xsl:text>,</xsl:text></xsl:if>
            <xsl:value-of select="concat('&quot;', @name, '&quot;:')"/>
            <xsl:value-of select="concat('&quot;', @check-contrast, '&quot;')"/>
        </xsl:for-each>
        <xsl:text>}</xsl:text>
    <xsl:text>}</xsl:text>
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
        <xsl:otherwise/>
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
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- 2019-11-28 all settings used here are deprecated -->
<xsl:variable name="google-classic-tracking">
    <xsl:choose>
        <xsl:when test="not($html.google-classic = '')">
            <xsl:value-of select="$html.google-classic"/>
        </xsl:when>
        <xsl:otherwise/>
    </xsl:choose>
</xsl:variable>

<!-- 2019-11-28 all settings used here are deprecated -->
<xsl:variable name="google-universal-tracking">
    <xsl:if test="not($html.google-universal = '')">
        <xsl:value-of select="$html.google-universal"/>
    </xsl:if>
</xsl:variable>

<!-- This is the preferred Google method as of 2019-11-28 -->
<xsl:variable name="google-gst-tracking">
    <xsl:apply-templates select="$publisher-attribute-options/html/analytics/pi:pub-attribute[@name='google-gst']" mode="set-pubfile-variable"/>
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
        <xsl:otherwise/>
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
    <xsl:apply-templates select="$publisher-attribute-options/html/video/pi:pub-attribute[@name='privacy']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:variable name="b-video-privacy" select="$embedded-video-privacy = 'yes'"/>

<!--                       -->
<!-- HTML Platform Options -->
<!--                       -->

<!-- 2019-12-17:  Under development, not documented -->

<!-- 2024-01-18: the value of this option is queried by the Python -->
<!-- routines, so keep their features and documentation in sync.   -->

<xsl:variable name="host-platform">
    <xsl:apply-templates select="$publisher-attribute-options/html/platform/pi:pub-attribute[@name='host']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- Intent is for exactly one of these boolean to be true -->
<!-- 'web' is the default, so we may not condition with it -->
<!-- 2019-12-19: only 'web' vs. 'runestone' implemented    -->
<xsl:variable name="b-host-web"       select="$host-platform = 'web'"/>
<xsl:variable name="b-host-runestone" select="$host-platform = 'runestone'"/>

<!-- To create a standalone html document with all css and js served by CDN -->
<!-- we can select platform/@portable to "yes"                              -->
<xsl:variable name="portable-html">
    <xsl:apply-templates select="$publisher-attribute-options/html/platform/pi:pub-attribute[@name='portable']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:variable name="b-portable-html" select="$portable-html = 'yes'"/>

<!--                            -->
<!-- HTML Favicon Specification -->
<!--                            -->

<xsl:variable name="favicon-scheme">
    <xsl:apply-templates select="$publisher-attribute-options/html/pi:pub-attribute[@name='favicon']" mode="set-pubfile-variable"/>
</xsl:variable>

<!--                            -->
<!-- HTML Embed Page button     -->
<!--                            -->

<xsl:variable name="embed-button">
    <xsl:apply-templates select="$publisher-attribute-options/html/pi:pub-attribute[@name='embed-button']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:variable name="b-has-embed-button" select="$embed-button = 'yes'"/>


<!-- ##################### -->
<!-- EPUB-Specific Options -->
<!-- ##################### -->

<!-- Cover image specification -->

<!-- Author-specified relative to source external directory -->
<xsl:variable name="epub-cover-base-filename">
    <xsl:apply-templates select="$publisher-attribute-options/epub/cover/pi:pub-attribute[@name='front']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- If the author does not say, eventually we will try to build a cover -->
<xsl:variable name="b-authored-cover" select="not(normalize-space($epub-cover-base-filename)) = ''"/>

<!-- This is where the file lives within the author's version of -->
<!-- the external files, so eventually Python will pick this up  -->
<xsl:variable name="epub-cover-source">
    <xsl:value-of select="$external-directory-source"/>
    <xsl:value-of select="$epub-cover-base-filename"/>
</xsl:variable>

<!-- This is where the image file lands in the final XHTML directory. -->
<!-- So this gets written into several constituents of the EPUB files -->
<!-- as the (special) cover image.  When an author does not provide   -->
<!-- the file, the Python makes one and it is always placed in the    -->
<!-- top-level of the EPUB package.                                   -->
<xsl:variable name="epub-cover-dest">
    <xsl:choose>
        <xsl:when test="$b-authored-cover">
            <xsl:value-of select="$external-directory"/>
            <xsl:value-of select="$epub-cover-base-filename"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>cover.png</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>


<!-- ###################### -->
<!-- LaTeX-Specific Options -->
<!-- ###################### -->

<!-- Sides are given as "one" or "two".  And we cannot think of    -->
<!-- any other options.  So we build, and use, a boolean variable.   -->
<!-- But if a third option aries, we can use it, and switch away  -->
<!-- from the boolean variable without the author knowing. -->
<xsl:variable name="latex-sides">
    <xsl:apply-templates select="$publisher-attribute-options/latex/pi:pub-attribute[@name='sides']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:template match="latex/pi:pub-attribute[@name='sides']" mode="get-default-pub-variable">
    <xsl:choose>
        <xsl:when test="$b-latex-print">
            <xsl:text>two</xsl:text>
        </xsl:when>
        <xsl:otherwise> <!-- electronic -->
            <xsl:text>one</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<!-- We have "one" or "two", or junk from the deprecated string parameter -->
<xsl:variable name="b-latex-two-sides" select="$latex-sides = 'two'"/>

<!-- Print versus electronic.  Historically "yes" versus "no" -->
<!-- and that seems stable enough, as in, we don't need to    -->
<!-- contemplate some third variant of LaTeX output.          -->
<xsl:variable name="latex-print">
    <xsl:apply-templates select="$publisher-attribute-options/latex/pi:pub-attribute[@name='print']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- We have "yes" or "no", or possibly junk from the deprecated string    -->
<!-- parameter, so we want the default (false) to be more likely than not. -->
<xsl:variable name="b-latex-print" select="not($latex-print = 'no')"/>

<!-- Always open on odd page in one-sided version, to        -->
<!-- to faciltate matching page-for-page with two-sided      -->
<!-- version.                                                -->
<!-- "add-blanks" means make a blank page on the even page   -->
<!--              preceding open odd page, when necessary    -->
<!-- "skip-pages" means skip over an even page number in the -->
<!--              pagination to open on an odd page number,  -->
<!--              when necessary                             -->
<!-- "no"         continuous pagination, parts/chapters/etc  -->
<!--              can open on either even or odd pages       -->
<xsl:variable name="latex-open-odd">
    <xsl:apply-templates select="$publisher-attribute-options/latex/pi:pub-attribute[@name='open-odd']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- Used to determine which xsl file to processess with.  Current options are based on what is present in xsl/latex.   -->
<!-- To build with `pretext-latex-styleName.xsl` variable should have valuse `stylename`. Default of empty string means -->
<!-- build with the default `pretext-latex.xsl` -->
<xsl:variable name="latex-style">
    <xsl:apply-templates select="$publisher-attribute-options/latex/pi:pub-attribute[@name='latex-style']" mode="set-pubfile-variable"/>
</xsl:variable>

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
    <xsl:apply-templates select="$publisher-attribute-options/latex/page/pi:pub-attribute[@name='bottom-alignment']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- LaTeX worksheet formatting -->
<!-- By default, worksheets in LaTeX will be formatted -->
<!-- with specified margins, pages, and workspace.     -->
<!-- Publisher switch to format continuously with      -->
<!-- other divisions here                              -->
<xsl:variable name="latex-worksheet-formatted">
    <xsl:apply-templates select="$publisher-attribute-options/latex/worksheet/pi:pub-attribute[@name='formatted']" mode="set-pubfile-variable"/>
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

<!-- For crop marks to make sense, a paper size must be known -->
<!-- There is no error-checking here, any non-empty value     -->
<!-- initiates the crop marks and becomes the paper size.     -->
<!-- Values from the  crop  package, 2023-05-19 are:          -->
<!--     a0, a1, a2, a3, a4, a5, a6,                          -->
<!--     b0, b1, b2, b3, b4, b5, b6,                          -->
<!--     letter, legal, executive                             -->
<xsl:variable name="latex-crop-papersize">
    <xsl:choose>
        <xsl:when test="$publication/latex/page/@crop-marks = 'none'"/>
        <xsl:when test="not($publication/latex/page/@crop-marks)"/>
        <xsl:otherwise>
            <xsl:value-of select="$publication/latex/page/@crop-marks"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- empty implies feature not selected -->
<xsl:variable name="b-latex-crop-marks" select="not($latex-crop-papersize = '')"/>

<!-- The default for the use of page references varies, so that  -->
<!-- particular logic is in the -latex conversion.  Here we just -->
<!-- sanitize to "yes", "no" or empty (i.e. ignored)             -->
<xsl:variable name="latex-pageref">
    <xsl:apply-templates select="$publisher-attribute-options/latex/pi:pub-attribute[@name='pageref']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- Draft Copies                                              -->
<!-- Various options for working copies for authors            -->
<!-- (1) LaTeX's draft mode                                    -->
<!-- (2) Crop marks on letter paper, centered                  -->
<!--     presuming geometry sets smaller page size             -->
<!--     with paperheight, paperwidth                          -->
<xsl:variable name="latex-draft-mode">
    <xsl:apply-templates select="$publisher-attribute-options/latex/pi:pub-attribute[@name='draft']" mode="set-pubfile-variable"/>
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
                <xsl:when test="not($b-has-baseurl)">
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
                <xsl:when test="not($b-has-baseurl)">
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
    <xsl:apply-templates select="$publisher-attribute-options/latex/pi:pub-attribute[@name='snapshot']" mode="set-pubfile-variable"/>
</xsl:variable>
<xsl:variable name="b-latex-snapshot" select="$latex-snapshot = 'yes'"/>

<!-- LaTeX Cover Pages -->

<!-- Front and back, a filename and a flag -->

<xsl:variable name="latex-front-cover-filename">
    <xsl:choose>
        <!-- post-managed directories, but $external-directory -->
        <!-- should preserve backward-compatibilty             -->
        <xsl:when test="$publication/latex/cover/@front">
            <xsl:value-of select="$external-directory"/>
            <xsl:value-of select="$publication/latex/cover/@front"/>
        </xsl:when>
        <otherwise/>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-has-latex-front-cover" select="not($latex-front-cover-filename = '')"/>

<xsl:variable name="latex-back-cover-filename">
    <xsl:choose>
        <!-- post-managed directories, but $external-directory -->
        <!-- should preserve backward-compatibilty             -->
        <xsl:when test="$publication/latex/cover/@back">
            <xsl:value-of select="$external-directory"/>
            <xsl:value-of select="$publication/latex/cover/@back"/>
        </xsl:when>
        <otherwise/>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-has-latex-back-cover" select="not($latex-back-cover-filename = '')"/>


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
    <xsl:apply-templates select="$publisher-attribute-options/revealjs/appearance/pi:pub-attribute[@name='theme']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- Reveal.js Controls Back Arrows -->

<xsl:variable name="reveal-control-backarrow">
    <xsl:apply-templates select="$publisher-attribute-options/revealjs/controls/pi:pub-attribute[@name='backarrows']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- Reveal.js Controls (on-screen navigation) -->

<xsl:variable name="reveal-control-display">
    <xsl:apply-templates select="$publisher-attribute-options/revealjs/controls/pi:pub-attribute[@name='display']" mode="set-pubfile-variable"/>
</xsl:variable>
<!-- Convert "yes"/"no" to a boolean variable -->
<xsl:variable name="b-reveal-control-display" select="$reveal-control-display= 'yes'"/>

<!-- Reveal.js Controls Layout -->

<xsl:variable name="reveal-control-layout">
    <xsl:apply-templates select="$publisher-attribute-options/revealjs/controls/pi:pub-attribute[@name='layout']" mode="set-pubfile-variable"/>
</xsl:variable>

<!-- Reveal.js Controls Tutorial (animated arrows) -->

<xsl:variable name="reveal-control-tutorial">
    <xsl:apply-templates select="$publisher-attribute-options/revealjs/controls/pi:pub-attribute[@name='tutorial']" mode="set-pubfile-variable"/>
</xsl:variable>
<!-- Convert "yes"/"no" to a boolean variable -->
<xsl:variable name="b-reveal-control-tutorial" select="$reveal-control-tutorial= 'yes'"/>

<!-- Reveal.js Navigation Mode -->

<xsl:variable name="reveal-navigation-mode">
    <xsl:apply-templates select="$publisher-attribute-options/revealjs/navigation/pi:pub-attribute[@name='mode']" mode="set-pubfile-variable"/>
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

<!-- The pi:publisher tree should mirror the official list of options   -->
<!-- for publisher file attributes. Each pi:pub-attribute has a name.   -->
<!-- The following attributes are optional.                             -->
<!-- default: default string to use (should not contain spaces)         -->
<!-- options: space-separated lits of options aside from the default    -->
<!-- freeform: if 'yes' then pub attributee can be anything             -->
<!-- stringparam: a stringparam that can override the pubfile entry     -->
<!-- legacy-stringparam: a deprecated stringparam, last in chain        -->
<!-- legacy-options: space separated list of retired options            -->

<pi:publisher>
    <common>
        <pi:pub-attribute name="emdash-space" default="none" options="thin" legacy-stringparam="emdash.space"/>
        <chunking>
            <pi:pub-attribute name="level" default="" options="0 1 2 3 4 5 6" stringparam="debug.chunk" legacy-stringparam="chunk.level"/>
        </chunking>
        <tableofcontents>
            <pi:pub-attribute name="level" options="0 1 2 3 4 5 6" legacy-stringparam="toc.level"/>
        </tableofcontents>
        <fillin>
            <pi:pub-attribute name="textstyle" default="underline" options="box shade"/>
            <pi:pub-attribute name="mathstyle" default="shade" options="underline box"/>
        </fillin>
        <qrcode>
            <pi:pub-attribute name="image" default="" freeform="yes"/>
        </qrcode>
        <mermaid>
            <pi:pub-attribute name="theme" default="default" options="dark forest light"/>
        </mermaid>
        <journal>
            <pi:pub-attribute name="name" default="" freeform="yes"/>
        </journal>
        <!-- The default CSL style file is empty so that this  -->
        <!-- feature can be "opt in", initially, and perhaps   -->
        <!-- forever.  A good first choice for a CSL style is  -->
        <!-- the "harvard1" style since it is copied into the  -->
        <!-- right place in the citeproc-py distribution and   -->
        <!-- should be present out-of-the-box.                 -->
        <citation-stylesheet-language>
            <pi:pub-attribute name="style" default="" freeform="yes"/>
        </citation-stylesheet-language>
        <worksheet>
            <pi:pub-attribute name="margin" default="0.75in" freeform="yes"/>
            <pi:pub-attribute name="top" freeform="yes"/>
            <pi:pub-attribute name="right" freeform="yes"/>
            <pi:pub-attribute name="bottom" freeform="yes"/>
            <pi:pub-attribute name="left" freeform="yes"/>
        </worksheet>
    </common>
    <html>
        <pi:pub-attribute name="short-answer-responses" default="graded" options="always"/>
        <pi:pub-attribute name="favicon" default="none" options="simple"/>
        <pi:pub-attribute name="embed-button" default="no" options="yes"/>
        <calculator>
            <pi:pub-attribute name="model" default="none" options="geogebra-classic geogebra-graphing geogebra-geometry geogebra-3d" legacy-stringparam="html.calculator"/>
        </calculator>
        <css>
            <pi:pub-attribute name="palette" freeform="yes"/>
        </css>
        <knowl>
            <pi:pub-attribute name="theorem" default="no" options="yes" legacy-stringparam="html.knowl.theorem"/>
            <pi:pub-attribute name="proof" default="yes" options="no" legacy-stringparam="html.knowl.proof"/>
            <pi:pub-attribute name="definition" default="no" options="yes" legacy-stringparam="html.knowl.definition"/>
            <pi:pub-attribute name="example" default="yes" options="no" legacy-stringparam="html.knowl.example"/>
            <pi:pub-attribute name="example-solution" default="yes" options="no"/>
            <pi:pub-attribute name="project" default="no" options="yes" legacy-stringparam="html.knowl.project"/>
            <pi:pub-attribute name="task" default="no" options="yes" legacy-stringparam="html.knowl.task"/>
            <pi:pub-attribute name="list" default="no" options="yes" legacy-stringparam="html.knowl.list"/>
            <pi:pub-attribute name="remark" default="no" options="yes" legacy-stringparam="html.knowl.remark"/>
            <pi:pub-attribute name="objectives" default="no" options="yes" legacy-stringparam="html.knowl.objectives"/>
            <pi:pub-attribute name="outcomes" default="no" options="yes" legacy-stringparam="html.knowl.outcomes"/>
            <pi:pub-attribute name="figure" default="no" options="yes" legacy-stringparam="html.knowl.figure"/>
            <pi:pub-attribute name="table" default="no" options="yes" legacy-stringparam="html.knowl.table"/>
            <pi:pub-attribute name="listing" default="no" options="yes" legacy-stringparam="html.knowl.listing"/>
            <pi:pub-attribute name="exercise-inline" default="yes" options="no" legacy-stringparam="html.knowl.exercise.inline"/>
            <pi:pub-attribute name="exercise-divisional" default="no" options="yes" legacy-stringparam="html.knowl.exercise.sectional"/>
            <pi:pub-attribute name="exercise-worksheet" default="no" options="yes" legacy-stringparam="html.knowl.exercise.worksheet"/>
            <pi:pub-attribute name="exercise-readingquestion" default="no" options="yes" legacy-stringparam="html.knowl.exercise.readingquestion"/>
        </knowl>
        <cross-references>
            <pi:pub-attribute name="knowled" default="maximum" options="never cross-page"/>
        </cross-references>
        <navigation>
            <pi:pub-attribute name="logic" default="linear" options="tree" legacy-stringparam="html.navigation.logic"/>
            <pi:pub-attribute name="upbutton" default="yes" options="no" legacy-stringparam="html.navigation.logic"/>
        </navigation>
        <tableofcontents>
            <pi:pub-attribute name="focused" default="no" options="yes"/>
            <pi:pub-attribute name="preexpanded-levels" default="0" options="1 2 3 4 5 6"/>
        </tableofcontents>
        <analytics>
            <pi:pub-attribute name="google-gst" freeform="yes"/>
        </analytics>
        <video>
            <pi:pub-attribute name="privacy" default="yes" options="no"/>
        </video>
        <platform>
            <pi:pub-attribute name="host" default="web" options="runestone" legacy-options="aim"/>
            <pi:pub-attribute name="portable" default="no" options="yes"/>
        </platform>
    </html>
    <epub>
        <cover>
            <pi:pub-attribute name="front" freeform="yes"/>
        </cover>
    </epub>
    <latex>
        <pi:pub-attribute name="sides" options="one two" legacy-stringparam="latex.sides"/>
        <pi:pub-attribute name="print" default="no" options="yes" legacy-stringparam="latex.print"/>
        <pi:pub-attribute name="snapshot" default="no" options="yes"/>
        <pi:pub-attribute name="pageref" options="yes no" legacy-stringparam="latex.pageref"/>
        <pi:pub-attribute name="draft" default="no" options="yes" legacy-stringparam="latex.draft"/>
        <pi:pub-attribute name="open-odd" default="no" options="add-blanks skip-pages"/>
        <pi:pub-attribute name="latex-style" default="" options="AIM chaos CLP dyslexic-font guide texstyle"/>
        <page>
            <pi:pub-attribute name="bottom-alignment" default="ragged" options="flush"/>
        </page>
        <worksheet>
            <pi:pub-attribute name="formatted" default="yes" options="no"/>
        </worksheet>
    </latex>
    <webwork>
        <pi:pub-attribute name="static-processing" default="webwork2" options="local"/>
        <pi:pub-attribute name="pg-location" default="/opt/webwork/pg" freeform="yes"/>
        <pi:pub-attribute name="server" default="https://webwork-ptx.aimath.org" freeform="yes"/>
        <pi:pub-attribute name="course" default="anonymous" freeform="yes"/>
        <pi:pub-attribute name="user" default="anonymous" freeform="yes"/>
        <pi:pub-attribute name="password" default="anonymous" freeform="yes"/>
        <pi:pub-attribute name="task-reveal" default="all" options="preceding-correct"/>
    </webwork>
    <revealjs>
        <appearance>
            <pi:pub-attribute name="theme" default="simple" freeform="yes"/>
        </appearance>
        <controls>
            <pi:pub-attribute name="backarrows" default="faded" options="hidden visible"/>
            <pi:pub-attribute name="display" default="yes" options="no"/>
            <pi:pub-attribute name="layout" default="bottom-right" options="edges"/>
            <pi:pub-attribute name="tutorial" default="yes" options="no"/>
        </controls>
        <navigation>
            <pi:pub-attribute name="mode" default="default" options="linear grid"/>
        </navigation>
    </revealjs>
</pi:publisher>

<!-- global variable for pi:publisher tree above -->
<xsl:variable name="publisher-attribute-options" select="document('')/xsl:stylesheet/pi:publisher"/>

<!-- context for a match below will be an attribute from the pi:publisher tree -->
<xsl:template match="pi:pub-attribute" mode="set-pubfile-variable">
    <xsl:variable name="all-options" select="str:tokenize(concat(@default, ' ', @options), ' ')"/>
    <xsl:variable name="legacy-options" select="str:tokenize(@legacy-options, ' ')"/>
    <!-- get the path to this attribute in the actual publisher file-->
    <xsl:variable name="path">
        <xsl:apply-templates select="." mode="pub-entry-path"/>
    </xsl:variable>
    <!-- get the corresponding attribute from the publisher file -->
    <!-- which may not exist                                     -->
    <xsl:variable name="full-path" select="concat('$publication/', $path)"/>
    <xsl:variable name="pubfile-attribute" select="dyn:evaluate($full-path)"/>
    <!-- The default value, which may be specified or may vary conditionally -->
    <!-- (via a custom template) appears frequently as the provided value    -->
    <!-- when there is an error condition of some type, and is also echo'ed  -->
    <!-- back to the publisher in those cases.  So we grab it once..         -->
    <xsl:variable name="the-default">
        <xsl:apply-templates select="." mode="get-default-pub-variable"/>
    </xsl:variable>
    <xsl:choose>
        <!-- if we respect a stringparam override and it is provided, use it -->
        <xsl:when test="@stringparam and dyn:evaluate(concat('$', @stringparam)) != ''">
            <xsl:value-of select="dyn:evaluate(concat('$', @stringparam))"/>
        </xsl:when>
        <!-- if nothing is declared in the publisher file, not even as null  -->
        <!-- and if there is an old stringparam that we still honor, and if  -->
        <!-- it is among the legal options, use it and issue warning         -->
        <xsl:when test="not($pubfile-attribute) and @legacy-stringparam and (@freeform = 'yes' or dyn:evaluate(concat('$', @legacy-stringparam)) = $all-options)">
            <xsl:value-of select="dyn:evaluate(concat('$', @legacy-stringparam))"/>
            <xsl:message>PTX:WARNING: the stringparam "<xsl:value-of select="@legacy-stringparam"/>" is deprecated. Your value, "<xsl:value-of select="dyn:evaluate(concat('$', @legacy-stringparam))"/>" will be used. However you should move to using a publisher file entry for  <xsl:value-of select="$full-path"/>  instead.</xsl:message>
        </xsl:when>
        <!-- if nothing is declared in the publisher file, not even as null  -->
        <!-- and if there is an old stringparam that we still honor, and if  -->
        <!-- it is among the legacy options, use default and issue warning   -->
        <xsl:when test="not($pubfile-attribute) and @legacy-stringparam and dyn:evaluate(concat('$', @legacy-stringparam)) = $legacy-options">
            <xsl:value-of select="$the-default"/>
            <xsl:message>PTX:WARNING: the stringparam "<xsl:value-of select="@legacy-stringparam"/>" is deprecated. Also your value, "<xsl:value-of select="dyn:evaluate(concat('$', @legacy-stringparam))"/>" has been retired. You should move to using a publisher file entry  <xsl:value-of select="$full-path"/>  with possible values: <xsl:apply-templates select="$all-options" mode="quoted-list"/>.  The default, "<xsl:value-of select="$the-default"/>", will be used instead.</xsl:message>
        </xsl:when>
        <!-- if nothing is declared in the publisher file, not even as null  -->
        <!-- and if there is an old stringparam that we still honor, but its -->
        <!-- value isn't legal, legacy, or the default strinigparam '',      -->
        <!-- then use default and issue warning                              -->
        <xsl:when test="not($pubfile-attribute) and @legacy-stringparam and dyn:evaluate(concat('$', @legacy-stringparam)) != ''">
            <xsl:value-of select="$the-default"/>
            <xsl:message>PTX:WARNING: the stringparam "<xsl:value-of select="@legacy-stringparam"/>" is deprecated. Also your value, "<xsl:value-of select="dyn:evaluate(concat('$', @legacy-stringparam))"/>" is not a legal option. You should move to using a publisher file entry  <xsl:value-of select="$full-path"/>  with possible values: <xsl:apply-templates select="$all-options" mode="quoted-list"/>.  The default, "<xsl:value-of select="$the-default"/>", will be used instead.</xsl:message>
        </xsl:when>
        <!-- if nothing is declared in the publisher file or it is declared  -->
        <!-- as null, use the default, which might be null                   -->
        <xsl:when test="string($pubfile-attribute) = ''">
            <xsl:value-of select="$the-default"/>
        </xsl:when>
        <!-- if a non-empty string declared in the pubfile and if freeform   -->
        <!-- is permitted, use whatever the pubfile entry was                -->
        <xsl:when test="@freeform = 'yes'">
            <xsl:value-of select="$pubfile-attribute"/>
        </xsl:when>
        <!-- now freeform not permittted; check if entry is among the legal  -->
        <!-- options and if so, use it                                       -->
        <xsl:when test="$pubfile-attribute = $all-options">
            <xsl:value-of select="$pubfile-attribute"/>
        </xsl:when>
        <!-- if it's among the legacy options, use default and issue warning  -->
        <xsl:when test="$pubfile-attribute = $legacy-options">
            <xsl:value-of select="$the-default"/>
            <xsl:message>PTX:WARNING: your value "<xsl:value-of select="$pubfile-attribute"/>"  for the publisher file entry  <xsl:value-of select="$path"/>  has been retired; possible values are <xsl:apply-templates select="$all-options" mode="quoted-list"/>. The default, "<xsl:value-of select="$the-default"/>", will be used instead.</xsl:message>
        </xsl:when>
        <!-- pubfile has some string that is not among legal options, and    -->
        <!-- freeform is disallowed, so give a warning and use default       -->
        <xsl:otherwise>
            <xsl:value-of select="$the-default"/>
            <xsl:message>PTX:WARNING: the publisher file  <xsl:value-of select="$path"/>  entry should not have value "<xsl:value-of select="$pubfile-attribute"/>".  Possible values are: <xsl:apply-templates select="$all-options" mode="quoted-list"/>.  The default, "<xsl:value-of select="$the-default"/>", will be used instead.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- can be overrided when the default is dynamic -->
<xsl:template match="pi:pub-attribute" mode="get-default-pub-variable">
    <xsl:value-of select="@default"/>
</xsl:template>

<!-- Recurse back up the tree to get the path to an attribute -->
<xsl:template match="pi:pub-attribute" mode="pub-entry-path">
    <xsl:apply-templates select=".." mode="pub-entry-path"/>
    <xsl:value-of select="concat('@', @name)"/>
</xsl:template>

<xsl:template match="*" mode="pub-entry-path">
    <xsl:apply-templates select=".." mode="pub-entry-path"/>
    <xsl:value-of select="concat(local-name(), '/')"/>
</xsl:template>

<xsl:template match="pi:publisher" mode="pub-entry-path"/>

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

<!-- "commentary" element relegated to version support, so string    -->
<!-- parameter is deprecated and ineffective, deprecated 2024-02-16. -->
<xsl:param name="commentary" select="''" />

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

<!-- 2023-01-11: These warnings are originally about string parameters -->
<!-- moving to the publisher file.  But they seem to work just as well -->
<!-- when an option in the publisher file changes.  So "parameter" is  -->
<!-- the nomenclature, but usage is a bit more broad.                  -->

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
    <!-- 2023-01-11  EPUB cover image publication file entry totally reworked -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2023-01-11'" />
        <xsl:with-param name="message" select="'the  epub/@cover  publication file entry has been replaced, and likely you will only get a simple generic cover image.  Please read the documentation for how to transition to the new specification'" />
            <xsl:with-param name="incorrect-use" select="($publication/epub/@cover != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2023-05-05  HTML navigation buttons' style publication file entry removed -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2023-05-05'" />
        <xsl:with-param name="message" select="'the  html/navigation/@style  publication file entry has been removed, since the &quot;compact&quot; option is no longer implemented, and the only option left is &quot;full&quot;.  Remove your publication file entry to stop this message re-appearing'" />
            <xsl:with-param name="incorrect-use" select="($publication/html/navigation/@style != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2024-02-16  "commentary" string parameter deprecated with changes in "commentary" element -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2024-02-16'" />
        <xsl:with-param name="message" select="'the  commentary  string parameter has been deprecated, is no longer functional, and has no replacement.  Instead control the visibility of a &quot;commentary&quot; element by placing it into a component and using version support.  You likely also have related deprecation messages about that situation which are more informative.'" />
            <xsl:with-param name="incorrect-use" select="($commentary != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2024-07-12'" />
        <xsl:with-param name="message" select="'the html/css/@style publication file entry has been deprecated for replacement by @theme. See the Guide for theme options.'" />
        <xsl:with-param name="incorrect-use" select="($publication/html/css/@style != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2024-07-12'" />
        <xsl:with-param name="message" select="'the html/css/@toc, @navbar, @shell, @knowls, and @banner publication entries have been deprecated. Use @theme to control html appearance. See the Guide for theme options.'" />
        <xsl:with-param name="incorrect-use" select="($publication/html/css/@toc != '' or $publication/html/css/@navbar != '' or $publication/html/css/@shell != '' or $publication/html/css/@knowls != '' or $publication/html/css/@banner != '')" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2025-05-09'" />
        <xsl:with-param name="message" select="'the webwork/@coursepassword and @userpassword publication entries have been deprecated. Use @password instead.'" />
        <xsl:with-param name="incorrect-use" select="($publication/webwork/@coursepassword != '' or $publication/webwork/@userpassword != '')" />
    </xsl:call-template>
    <!--  -->
</xsl:template>

</xsl:stylesheet>
