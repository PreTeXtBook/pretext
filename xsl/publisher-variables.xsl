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
    extension-element-prefixes="exsl"
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
<xsl:variable name="publication" select="document($publisher, .)/publication"/>

<!-- ############## -->
<!-- Common Options -->
<!-- ############## -->

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
        <xsl:when test="$root/book/part/chapter/section">3</xsl:when>
        <xsl:when test="$root/book/part/chapter">2</xsl:when>
        <xsl:when test="$root/book/chapter/section">2</xsl:when>
        <xsl:when test="$root/book/chapter">1</xsl:when>
        <xsl:when test="$root/article/section/subsection">2</xsl:when>
        <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: Table of Contents level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="toc-level" select="number($toc-level-entered)"/>

<!-- Flag Table of Contents, or not, with boolean variable -->
<xsl:variable name="b-has-toc" select="$toc-level > 0" />


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

<!-- A file of hint|answer|solution, with @ref back to "exercise" -->
<!-- so that the solutions can see limited distribution.  No real -->
<!-- error-checking.  If not set/present, then an empty string    -->

<xsl:variable name="private-solutions-file">
    <xsl:choose>
        <xsl:when test="$publication/source/@private-solutions">
            <xsl:value-of select="$publication/source/@private-solutions"/>
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
        <xsl:when test="$publication/source/@webwork-problems">
            <xsl:value-of select="$publication/source/@webwork-problems"/>
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
            <xsl:value-of select="$publication/source/@customizations"/>
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
            <xsl:when test="$root/book/part">5</xsl:when>
            <xsl:when test="$root/book">4</xsl:when>
            <xsl:when test="$root/article/section|$root/article/worksheet">3</xsl:when>
            <xsl:when test="$root/article">0</xsl:when>
            <xsl:when test="$root/letter">0</xsl:when>
            <xsl:when test="$root/slideshow">0</xsl:when>
            <xsl:when test="$root/memo">0</xsl:when>
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
            <xsl:when test="$root/book/part">3</xsl:when>
            <xsl:when test="$root/book">2</xsl:when>
            <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
            <xsl:when test="$root/article">0</xsl:when>
            <xsl:when test="$root/slideshow">0</xsl:when>
            <xsl:when test="$root/letter">0</xsl:when>
            <xsl:when test="$root/memo">0</xsl:when>
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
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
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
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
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
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
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
        <xsl:when test="not($document-root/part)">
            <xsl:choose>
                <xsl:when test="$publication/numbering/divisions/@part-structure">
                    <xsl:message>PTX:WARNING: your document is not a book with parts, so the publisher file  numbering/divisions/@part-structure  entry is being ignored</xsl:message>
                </xsl:when>
                <xsl:when test="$docinfo/numbering/division/@part">
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
        <xsl:when test="$docinfo/numbering/division/@part">
            <xsl:choose>
                <xsl:when test="$docinfo/numbering/division/@part = 'structural'">
                    <xsl:text>structural</xsl:text>
                </xsl:when>
                <xsl:when test="$docinfo/numbering/division/@part = 'decorative'">
                    <xsl:text>decorative</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:WARNING: the  docinfo/numbering/division/@part  entry should be "decorative" or "structural", not "<xsl:value-of select="$docinfo/numbering/division/@part"/>".  The default will be used instead.</xsl:message>
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

<!-- A generic "index.html" page will be built to redirect to an     -->
<!-- existing page from the HTML build/chunking.  The default is the -->
<!-- "frontmatter" page, if possible, otherwise the root page.       -->
<!-- The variable $html-index-page will be the full name (*.html)    -->
<!-- of a page guaranteed to be built by the chunking routines.      -->

<xsl:variable name="html-index-page">
    <!-- needs to be realized as a *string*, not a node -->
    <xsl:variable name="entered-ref" select="string($publication/html/index-page/@ref)"/>
    <xsl:variable name="entered-id">
        <xsl:call-template name="id-lookup-by-name">
            <xsl:with-param name="name" select="$entered-ref"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="sanitized-ref">
        <xsl:choose>
            <!-- signal no choice with empty string-->
            <xsl:when test="$entered-ref = ''">
                <xsl:text/>
            </xsl:when>
            <!-- bad choice, set to empty string -->
            <xsl:when test="not(id($entered-id))">
                <xsl:message>PTX:WARNING:   the requested HTML index page cannot be constructed since "<xsl:value-of select="$entered-ref"/>" is not an @xml:id anywhere in the document.  Defaults will be used instead</xsl:message>
                <xsl:text/>
            </xsl:when>
            <!-- now we have a node, is it the top of a page? -->
            <xsl:otherwise>
                <!-- true/false values if node creates a web page -->
                <xsl:variable name="is-intermediate">
                    <xsl:apply-templates select="id($entered-id)" mode="is-intermediate"/>
                </xsl:variable>
                <xsl:variable name="is-chunk">
                    <xsl:apply-templates select="id($entered-id)" mode="is-chunk"/>
                </xsl:variable>
                <xsl:choose>
                    <!-- really is a web-page -->
                    <xsl:when test="($is-intermediate = 'true') or ($is-chunk = 'true')">
                        <xsl:value-of select="$entered-ref"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>PTX:WARNING:   the requested HTML index page cannot be constructed since "<xsl:value-of select="$entered-ref"/>" is not a complete web page at the current chunking level (level <xsl:value-of select="$chunk-level"/>).  Defaults will be used instead</xsl:message>
                        <xsl:text/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- now have a good @xml:id for an extant webpage, or        -->
    <!-- empty string signals we need to choose sensible defaults -->
    <xsl:choose>
        <!-- publisher's choice survives -->
        <xsl:when test="not($sanitized-ref = '')">
            <xsl:apply-templates select="id($sanitized-ref)" mode="containing-filename"/>
        </xsl:when>
        <!-- now need to create defaults                        -->
        <!-- the level of the frontmatter is a bit conflicted   -->
        <!-- but it is a chunk iff there is any chunking at all -->
        <xsl:when test="$document-root/frontmatter and ($chunk-level &gt; 0)">
            <xsl:apply-templates select="$document-root/frontmatter" mode="containing-filename"/>
        </xsl:when>
        <!-- absolute last option is $document-root, *always* a webpage -->
        <xsl:otherwise>
            <xsl:apply-templates select="$document-root" mode="containing-filename"/>
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
            <xsl:when test="$docinfo/html/baseurl/@href">
                <xsl:value-of select="$docinfo/html/baseurl/@href"/>
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
        <xsl:when test="$docinfo/analytics/statcounter/project">
            <xsl:value-of select="$docinfo/analytics/statcounter/project"/>
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
        <xsl:when test="$docinfo/analytics/statcounter/security">
            <xsl:value-of select="$docinfo/analytics/statcounter/security"/>
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
        <xsl:when test="$docinfo/analytics/google">
            <xsl:value-of select="$docinfo/analytics/google/tracking"/>
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
        <xsl:when test="$docinfo/analytics/google-universal">
            <xsl:value-of select="$docinfo/analytics/google-universal/@tracking"/>
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
        <xsl:when test="$docinfo/search/google/cx">
            <xsl:value-of select="$docinfo/search/google/cx"/>
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
        <xsl:text>https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0</xsl:text>
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

<!-- Reveal.js Minified CSS/JS -->
<!-- Resources from a CDN come in a minified version typically.    -->
<!-- But a local version does not have these files available.      -->
<!-- So we provide sensible defaults and let a publisher override. -->

<xsl:variable name="minified">
    <xsl:choose>
        <!-- explict is recognized first, only "yes" activates minified -->
        <xsl:when test="$publication/revealjs/resources/@minified">
            <xsl:choose>
                <xsl:when test="$publication/revealjs/resources/@minified = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>no</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- for PTX-supplied CDN, assume minified is best -->
        <xsl:when test="$publication/revealjs/resources/@host = 'cdn'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <!-- and for a local copy, assume no minified copy exists -->
        <xsl:when test="$publication/revealjs/resources/@host = 'local'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- else some host, but we don't have any idea -->
        <!-- so don't get fancy, and go without minified -->
        <xsl:when test="$publication/revealjs/resources/@host">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- no @minified, and no @host, so we have     -->
        <!-- defaulted to CDN and minified is suggested -->
        <xsl:otherwise>
            <xsl:text>yes</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- Convert "yes"/"no" to a boolean variable -->
<xsl:variable name="b-reveal-minified" select="$minified = 'yes'"/>


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
