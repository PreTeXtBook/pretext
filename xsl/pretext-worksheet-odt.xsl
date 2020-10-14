<?xml version='1.0'?> <!-- As XML file -->

<!--
<==================================================================>
Copyright 2020 Rob Beezer

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
<==================================================================>
-->

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
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:officeooo="http://openoffice.org/2009/office"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
>

<xsl:import href="./pretext-common.xsl" />
<!-- <xsl:import href="./pretext-assembly.xsl"/> -->

<!-- Intend output is xml for an Open Document Text package (.odt file) -->
<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />


<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the pretext element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="pretext" mode="generic-warnings" />
    <xsl:apply-templates select="pretext" mode="deprecation-warnings" />
    <xsl:apply-templates select="pretext" />
</xsl:template>

<!-- We will totally ignore docinfo       -->
<!-- For now, just making book//worksheet -->
<xsl:template match="/pretext">
    <xsl:apply-templates select="book"/>
</xsl:template>

<!-- A book -->
<!-- For now, just drilling down to a worksheet -->
<xsl:template match="book">
    <xsl:apply-templates select="chapter"/>
</xsl:template>

<xsl:template match="chapter|section|subsection|subsubsection">
    <xsl:apply-templates select="worksheet|section|subsection|subsubsection"/>
</xsl:template>

<xsl:template match="worksheet">
    <!-- A folder to hold the subfiles, to be zipped and renamed .odt externally -->
    <!-- Note that $folder will ends with a slash                                -->
    <xsl:variable name="folder">
        <xsl:apply-templates select="." mode="folder" />
    </xsl:variable>
    <!-- Now build the six files needed for a schema-compliant .odt file -->
    <!-- Style template in particular is very long,                      -->
    <!-- so find these templates pushed to the end of this stylesheet    -->
    <xsl:apply-templates select="." mode="mimetype">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="styles">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="meta">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="settings">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="manifest">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="content">
        <xsl:with-param name="folder" select="$folder" />
    </xsl:apply-templates>
</xsl:template>

<!-- ##################################################################### -->
<!-- "p" paragraphs styled according to where they reside in the worksheet -->
<!-- ##################################################################### -->
<xsl:template match="worksheet//p">
    <xsl:variable name="style">
        <xsl:choose>
            <xsl:when test="parent::introduction and count(preceding-sibling::&METADATA;) = count(preceding-sibling::*) and not(following-sibling::*)">
                <xsl:text>P-introduction-both</xsl:text>
            </xsl:when>
            <xsl:when test="parent::introduction and count(preceding-sibling::&METADATA;) = count(preceding-sibling::*)">
                <xsl:text>P-introduction-top</xsl:text>
            </xsl:when>
            <xsl:when test="parent::introduction and not(following-sibling::*)">
                <xsl:text>P-introduction-bottom</xsl:text>
            </xsl:when>
            <xsl:when test="parent::introduction">
                <xsl:text>P-introduction</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>P</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <text:p text:style-name="{$style}">
        <xsl:if test="parent::introduction/title and (count(preceding-sibling::&METADATA;) = count(preceding-sibling::*))">
            <text:span text:style-name="Runin-title">
                <xsl:apply-templates select="parent::introduction" mode="title-full"/>
            </text:span>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates />
    </text:p>
</xsl:template>

<!-- ##################################### -->
<!-- The workhseet introduction is special -->
<!-- ##################################### -->
<xsl:template match="worksheet//introduction">
    <!-- if there is a title but the first non-metadata child is not a p, give the title its own p -->
    <xsl:if test="title and boolean(*[not(&METADATA-FILTER;)][position() = 1][not(self::p)])">
        <xsl:variable name="title-style">
            <xsl:choose>
                <xsl:when test="count(*[&METADATA-FILTER;]) = count(*)">
                    <xsl:text>P-introduction-only</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>P-introduction-top</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <text:p text:style-name="{$title-style}">
            <text:span text:style-name="Runin-title">
                <xsl:apply-templates select="." mode="title-full"/>
            </text:span>
        </text:p>
    </xsl:if>
    <xsl:apply-templates select="*[not(&METADATA;)]"/>
</xsl:template>

<!-- ####################### -->
<!-- The workhseet exercises -->
<!-- ####################### -->
<!-- TODO: extend so that an exercise need not have a statement -->
<xsl:template match="worksheet//exercise">
    <text:list-item><xsl:apply-templates select="statement"/></text:list-item>
</xsl:template>

<xsl:template match="worksheet//statement">
    <!-- TODO: For now, only supporting p children -->
    <xsl:apply-templates select="p"/>
</xsl:template>


<!-- ######### -->
<!-- Groupings -->
<!-- ######### -->
<xsl:template match="abbr">
    <text:span text:style-name="Abbr">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="acro">
    <text:span text:style-name="Acro">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="init">
    <text:span text:style-name="Init">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="em">
    <text:span text:style-name="Emphasis">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="term">
    <text:span text:style-name="Term">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="alert">
    <text:span text:style-name="Alert">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="pubtitle">
    <text:span text:style-name="Pubtitle">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="articletitle">
    <text:span text:style-name="Articletitle">
        <xsl:call-template name="lq-character"/>
        <xsl:apply-templates/>
        <xsl:call-template name="rq-character"/>
    </text:span>
</xsl:template>
<xsl:template match="foreign">
    <text:span text:style-name="Foreign">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="delete">
    <text:span text:style-name="Delete">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="insert">
    <text:span text:style-name="Insert">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="stale">
    <text:span text:style-name="Stale">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="taxon[not(genus) and not(species)]">
    <text:span text:style-name="Taxon">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>
<xsl:template match="taxon[genus or species]">
    <text:span text:style-name="Taxon">
        <xsl:if test="genus">
            <text:span text:style-name="Genus">
                <xsl:apply-templates select="genus"/>
            </text:span>
        </xsl:if>
        <xsl:if test="genus and species">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:if test="species">
            <text:span text:style-name="Species">
                <xsl:apply-templates select="species"/>
            </text:span>
        </xsl:if>
    </text:span>
</xsl:template>
<xsl:template match="email">
    <text:span text:style-name="Email">
        <xsl:apply-templates/>
    </text:span>
</xsl:template>

<!-- ########## -->
<!-- Characters -->
<!-- ########## -->
<xsl:template name="lsq-character">
    <xsl:text>&#x2018;</xsl:text>
</xsl:template>
<xsl:template name="rsq-character">
    <xsl:text>&#x2019;</xsl:text>
</xsl:template>
<xsl:template name="lq-character">
    <xsl:text>&#x201c;</xsl:text>
</xsl:template>
<xsl:template name="rq-character">
    <xsl:text>&#x201d;</xsl:text>
</xsl:template>
<xsl:template name="ldblbracket-character">
    <xsl:text>&#x27e6;</xsl:text>
</xsl:template>
<xsl:template name="rdblbracket-character">
    <xsl:text>&#x27e7;</xsl:text>
</xsl:template>
<xsl:template name="langle-character">
    <xsl:text>&#x3008;</xsl:text>
</xsl:template>
<xsl:template name="rangle-character">
    <xsl:text>&#x3009;</xsl:text>
</xsl:template>
<xsl:template name="nbsp-character">
    <xsl:text>&#xa0;</xsl:text>
</xsl:template>
<xsl:template name="ndash-character">
    <xsl:text>&#8211;</xsl:text>
</xsl:template>
<xsl:template name="mdash-character">
    <xsl:text>&#8212;</xsl:text>
</xsl:template>
<xsl:template name="ellipsis-character">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>
<xsl:template name="midpoint-character">
    <xsl:text>&#xb7;</xsl:text>
</xsl:template>
<xsl:template name="swungdash-character">
    <xsl:text>&#x2053;</xsl:text>
</xsl:template>
<xsl:template name="permille-character">
    <xsl:text>&#x2030;</xsl:text>
</xsl:template>
<xsl:template name="pilcrow-character">
    <xsl:text>&#xb6;</xsl:text>
</xsl:template>
<xsl:template name="section-mark-character">
    <xsl:text>&#xa7;</xsl:text>
</xsl:template>
<xsl:template name="minus-character">
    <xsl:text>&#x2212;</xsl:text>
</xsl:template>
<xsl:template name="times-character">
    <xsl:text>&#xd7;</xsl:text>
</xsl:template>
<xsl:template name="solidus-character">
    <xsl:text>&#x2044;</xsl:text>
</xsl:template>
<xsl:template name="obelus-character">
    <xsl:text>&#xf7;</xsl:text>
</xsl:template>
<xsl:template name="plusminus-character">
    <xsl:text>&#xb1;</xsl:text>
</xsl:template>
<xsl:template name="copyright-character">
    <xsl:text>&#xa9;</xsl:text>
</xsl:template>
<!-- Registered symbol -->
<!-- Bringhurst: should be superscript                    -->
<!-- We consider it a font mistake if not superscripted,  -->
<!-- since if we use a "sup" tag then a correct font will -->
<!-- get way too small                                    -->
<xsl:template name="registered-character">
    <xsl:text>&#xae;</xsl:text>
</xsl:template>
<xsl:template name="trademark-character">
    <xsl:text>&#x2122;</xsl:text>
</xsl:template>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->
<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>
    <!-- for-each is just one node, but sets context for key() -->
    <xsl:variable name="unicode">
        <xsl:for-each select="$icon-table">
            <xsl:value-of select="key('icon-key', $icon-name)/@unicode"/>
        </xsl:for-each>
    </xsl:variable>
    <text:span text:style-name="Icon">
        <xsl:value-of select="$unicode"/>
    </text:span>
</xsl:template>

<!-- ########## -->
<!-- Generators -->
<!-- ########## -->
<xsl:template match="tex">
    <text:span text:style-name="TeX">T<text:span text:style-name="E">E</text:span>X</text:span>
</xsl:template>
<xsl:template match="latex">
    <text:span text:style-name="TeX">L<text:span text:style-name="A">A</text:span>T<text:span text:style-name="E">E</text:span>X</text:span>
</xsl:template>


<!-- ############# -->
<!-- File building -->
<!-- ############# -->

<!-- Append a filename to the directory path              -->
<xsl:template match="worksheet" mode="folder">
    <xsl:text>worksheets/</xsl:text>
    <xsl:apply-templates select="." mode="numbered-title-filesafe" />
    <xsl:text>/</xsl:text>
</xsl:template>

<!-- mimetype -->
<!-- Considered using a named template, but maybe something -->
<!-- else in the future will need a different mimetype      -->
<xsl:template match="worksheet" mode="mimetype">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'mimetype')" />
    <exsl:document href="{$filepathname}" method="text">
        <xsl:text>application/vnd.oasis.opendocument.text</xsl:text>
    </exsl:document>
</xsl:template>

<!-- styles.xml -->
<!-- Defines styles quasi-analogously to a .css file for HTML -->
<xsl:template match="worksheet" mode="styles">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'styles.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <office:document-styles
            office:version="1.3"
            xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
            xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
            xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
            xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
            xmlns:loext="urn:org:documentfoundation:names:experimental:office:xmlns:loext:1.0"
            xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
            >
            <office:font-face-decls>
                <style:font-face
                    style:name="Main"
                    svg:font-family="&apos;Latin Modern Roman&apos;"
                    style:font-family-generic="roman"
                    style:font-pitch="variable"
                />
                <style:font-face
                    style:name="TeX"
                    svg:font-family="&apos;Latin Modern Roman&apos;"
                    style:font-family-generic="roman"
                />
                <style:font-face
                    style:name="Icon"
                    svg:font-family="&apos;Arial Unicode MS&apos;"
                    style:font-family-generic="system"
                    style:font-pitch="variable"
                />
            </office:font-face-decls>
            <office:styles>
                <style:default-style style:family="paragraph">
                    <!-- 0.08304in is 6pt -->
                    <style:paragraph-properties
                        fo:orphans="2"
                        fo:widows="2"
                        fo:margin-bottom="0.08304in"
                        fo:text-indent="0in"
                        style:auto-text-indent="false"
                        style:punctuation-wrap="hanging"
                    />
                    <style:text-properties
                        style:font-name="Main"
                        fo:font-size="12pt"
                        style:letter-kerning="true"
                    />
                </style:default-style>

                <!-- A typical paragraph just falls to the default "paragraph" family of styling -->
                <style:style
                    style:name="P"
                    style:family="paragraph"
                />

                <!-- The overall worksheet introduction is the only place we can implement indentation.  -->
                <!-- All content within the actual exercises is in an ordered list, where the list level -->
                <!-- indentation overrides individual paragraph indentation. So we have some specific    -->
                <!-- styling for the overall introduction.                                               -->

                <!-- A paragraph at the very top of an introduction -->
                <!-- No preceding image or anything like that       -->
                <!-- Gets no indentation, no parskip                -->
                <style:style
                    style:name="P-introduction-top"
                    style:family="paragraph"
                    style:parent-style-name="P-introduction"
                    >
                    <style:paragraph-properties
                        fo:text-indent="0in"
                    />
                </style:style>
                <!-- A general paragraph somewhere in the middle                   -->
                <!-- Indent by 0.24387in, which is 1.5em (in 12pt) to match LaTeX  -->
                <style:style
                    style:name="P-introduction"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:text-indent="0.24387in"
                        fo:margin-bottom="0in"
                    />
                </style:style>
                <!-- A paragraph at the very end of an introduction         -->
                <!-- No following image or anything like that               -->
                <!-- Indent and skip 0.08304in, which is 6pt to match LaTeX -->
                <style:style
                    style:name="P-introduction-bottom"
                    style:family="paragraph"
                    style:parent-style-name="P-introduction"
                    >
                    <style:paragraph-properties
                        fo:margin-bottom="0.08304in"
                    />
                </style:style>
                <!-- When the introduction only has one content child and it's a p -->
                <!-- No indent like "top", but after-skip like "bottom"            -->
                <style:style
                    style:name="P-introduction-only"
                    style:family="paragraph"
                    style:parent-style-name="P-top"
                    >
                    <style:paragraph-properties
                        fo:margin-bottom="0.08304in"
                    />
                </style:style>
                <style:style
                    style:name="Runin-title"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-weight="bold"
                    />
                </style:style>
                <!-- Groupings -->
                <style:style
                    style:name="Abbr"
                    style:family="text"
                />
                <style:style
                    style:name="Acro"
                    style:family="text"
                />
                <style:style
                    style:name="Init"
                    style:family="text"
                />
                <style:style
                    style:name="Emphasis"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-style="italic"
                    />
                </style:style>
                <style:style
                    style:name="Term"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-weight="bold"
                    />
                </style:style>
                <style:style
                    style:name="Alert"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-style="italic"
                        fo:font-weight="bold"
                    />
                </style:style>
                <style:style
                    style:name="Pubtitle"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-style="oblique"
                    />
                </style:style>
                <style:style
                    style:name="Articletitle"
                    style:family="text"
                    >
                </style:style>
                <style:style
                    style:name="Foreign"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-style="italic"
                    />
                </style:style>
                <style:style
                    style:name="Delete"
                    style:family="text"
                    >
                    <style:text-properties
                        style:text-line-through-style="solid"
                    />
                </style:style>
                <style:style
                    style:name="Insert"
                    style:family="text"
                    >
                    <style:text-properties
                        style:text-underline-style="solid"
                    />
                </style:style>
                <style:style
                    style:name="Stale"
                    style:family="text"
                    >
                    <style:text-properties
                        style:text-line-through-style="solid"
                    />
                </style:style>
                <style:style
                    style:name="Taxon"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-style="italic"
                    />
                </style:style>
                <style:style
                    style:name="Genus"
                    style:family="text"
                    >
                    <style:text-properties
                    />
                </style:style>
                <style:style
                    style:name="Species"
                    style:family="text"
                    >
                    <style:text-properties
                    />
                </style:style>
                <style:style
                    style:name="Email"
                    style:family="text"
                />
                <!-- Icons -->
                <style:style
                    style:name="Icon"
                    style:family="text"
                    >
                    <style:text-properties
                        style:font-name="Icon"
                    />
                </style:style>
                <!-- Generators -->
                <style:style
                    style:name="TeX"
                    style:family="text"
                    >
                    <style:text-properties
                        style:font-name="TeX"
                        fo:letter-spacing="-0.01951in"
                    />
                </style:style>
                <style:style
                    style:name="E"
                    style:family="text"
                    style:parent-style-name="TeX"
                    >
                    <style:text-properties
                        style:text-position="-21.5% 100%"
                    />
                </style:style>
                <style:style
                    style:name="A"
                    style:family="text"
                    style:parent-style-name="TeX"
                    >
                    <style:text-properties
                        style:text-position="21.5% 75%"
                    />
                </style:style>
                <!-- Headings -->
                <!-- First, very generic heading styling -->
                <style:style
                    style:name="Heading"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:margin-top="0.1665in"
                        fo:margin-bottom="0.0835in"
                    />
                    <style:text-properties
                        style:font-name="Main"
                        style:font-family-generic="roman"
                        style:font-pitch="variable"
                        fo:font-size="14pt"
                    />
                </style:style>
                <!-- Title of the worksheet -->
                <style:style
                    style:name="Title"
                    style:family="paragraph"
                    style:parent-style-name="Heading"
                    >
                    <style:paragraph-properties
                        fo:text-align="left"
                    />
                    <!-- 17pt is \large for base 12pt, matching LaTeX -->
                    <style:text-properties
                        fo:font-size="17pt"
                        fo:font-weight="bold"
                    />
                </style:style>
                <!-- Header and Footer -->
                <!-- First, generic styling -->
                <style:style
                    style:name="Header_and_Footer" 
                    style:display-name="Header and Footer"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties>
                        <!-- these tab stops allow for left|center|right header/footer -->
                        <style:tab-stops>
                            <style:tab-stop
                                style:position="3.4626in"
                                style:type="center"
                            />
                            <style:tab-stop
                                style:position="6.9252in"
                                style:type="right"
                            />
                        </style:tab-stops>
                    </style:paragraph-properties>
                </style:style>
                <!-- Headers in general -->
                <style:style
                    style:name="Header"
                    style:family="paragraph"
                    style:parent-style-name="Header_and_Footer"
                />
                <!-- Headers for page 1 -->
                <style:style
                    style:name="Header-first-page"
                    style:display-name="Header first page"
                    style:family="paragraph"
                    style:parent-style-name="Header"
                    >
                    <style:text-properties
                        fo:font-variant="small-caps"
                        fo:font-style="oblique"
                        fo:font-weight="normal" 
                    />
                </style:style>
                <!-- Numbering -->
                <style:style
                    style:name="Exercise_Numbering"
                    style:display-name="Exercise Numbering"
                    style:family="text"
                    >
                    <style:text-properties
                        fo:font-weight="bold"
                    />
                </style:style>
                <!-- Styling the primary exercise numbering in a worksheet -->
                <text:list-style
                    style:name="Exercises"
                    >
                    <text:list-level-style-number
                        text:level="1"
                        text:style-name="Exercise_Numbering"
                        style:num-suffix="."
                        style:num-format="1"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="0.34745in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="0.34745in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-number>
                </text:list-style>
            </office:styles>
            <office:automatic-styles>
                <style:page-layout style:name="Page">
                    <style:page-layout-properties
                        fo:page-width="8.5in"
                        fo:page-height="11in"
                        style:num-format="1"
                        style:print-orientation="portrait"
                        fo:margin-top="0.7874in"
                        fo:margin-bottom="0.7874in"
                        fo:margin-left="0.7874in"
                        fo:margin-right="0.7874in"
                        style:writing-mode="lr-tb"
                        >
                    </style:page-layout-properties>
                    <style:header-style>
                        <style:header-footer-properties
                            fo:min-height="0in"
                            fo:margin-left="0in"
                            fo:margin-right="0in"
                            fo:margin-bottom="0.1965in"
                        />
                    </style:header-style>
                    <style:footer-style/>
                </style:page-layout>
            </office:automatic-styles>
            <office:master-styles>
                <style:master-page
                    style:name="Standard"
                    style:page-layout-name="Page"
                    >
                    <style:header />
                    <style:header-first>
                        <text:p text:style-name="Header-first-page">
                            <xsl:apply-templates select="$document-root" mode="title-full" />
                            <text:tab/>
                            <xsl:apply-templates select="." mode="type-name" />
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="." mode="number" />
                            <text:tab/>
                            <xsl:apply-templates select="$document-root/frontmatter/titlepage/author" mode="name-list"/>
                        </text:p>
                    </style:header-first>
                </style:master-page>
            </office:master-styles>
        </office:document-styles>
    </exsl:document>
</xsl:template>

<!-- settings.xml -->
<!-- User settings for word processor application -->
<xsl:template match="worksheet" mode="settings">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'settings.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <office:document-settings office:version="1.3" />
    </exsl:document>
</xsl:template>

<!-- meta.xml -->
<!-- Metadata about this .odt file -->
<xsl:template match="worksheet" mode="meta">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'meta.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <office:document-meta office:version="1.3" />
    </exsl:document>
</xsl:template>

<!-- manifest.xml -->
<!-- A map to the component files -->
<xsl:template match="worksheet" mode="manifest">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'META-INF/manifest.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.3">
            <manifest:file-entry manifest:full-path="/" manifest:version="1.3" manifest:media-type="application/vnd.oasis.opendocument.text"/>
            <manifest:file-entry manifest:full-path="meta.xml" manifest:media-type="text/xml"/>
            <manifest:file-entry manifest:full-path="settings.xml" manifest:media-type="text/xml"/>
            <manifest:file-entry manifest:full-path="styles.xml" manifest:media-type="text/xml"/>
            <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>
        </manifest:manifest>
    </exsl:document>
</xsl:template>

<!-- content.xml -->
<!-- The actual content of the document -->
<xsl:template match="worksheet" mode="content">
    <xsl:param name="folder" />
    <xsl:variable name="filepathname" select="concat($folder,'content.xml')" />
    <exsl:document href="{$filepathname}" method="xml" version="1.0">
        <office:document-content
            office:version="1.3"
            xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
            xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
            xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
            xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
            xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"            
            >
            <office:body>
                <office:text>
                    <xsl:if test="title">
                        <text:h text:style-name="Title" text:outline-level="1">
                            <xsl:apply-templates select="." mode="title-full" />
                        </text:h>
                    </xsl:if>
                    <xsl:apply-templates select="introduction" />
                    <text:list text:style-name="Exercises">
                        <xsl:apply-templates select="exercise" />
                    </text:list>
                </office:text>
            </office:body>
        </office:document-content>
    </exsl:document>
</xsl:template>


</xsl:stylesheet>
