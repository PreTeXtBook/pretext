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
    xmlns:xlink="http://www.w3.org/1999/xlink"
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

<!-- Kill these in an ODT worksheet -->
<xsl:template match="idx" />
<xsl:template match="notation" />

<!-- ##################################################################### -->
<!-- "p" paragraphs styled according to where they reside in the worksheet -->
<!-- ##################################################################### -->
<xsl:template match="worksheet//p">
    <text:p>
        <xsl:attribute name="text:style-name">
            <xsl:choose>
                <xsl:when test="following-sibling::*|parent::li/following-sibling::li|ancestor::ol/following-sibling::*|ancestor::ol/parent::p/following-sibling::*|ancestor::ul/following-sibling::*|ancestor::ul/parent::p/following-sibling::*|ancestor::dl/following-sibling::*|ancestor::dl/parent::p/following-sibling::*">
                    <xsl:text>P</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>P-last</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <!-- If there is a title to a block and it belongs within this p, place it here -->
        <!-- The count construct checks that the only preceding siblings are metadata   -->
        <xsl:if test="boolean(parent::*/title or parent::statement/parent::*/title) and (count(preceding-sibling::&METADATA;) = count(preceding-sibling::*))">
            <text:span text:style-name="Runin-title">
                <xsl:choose>
                    <xsl:when test="parent::statement">
                        <xsl:apply-templates select="parent::statement/parent::*" mode="title-full"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="parent::*" mode="title-full"/>
                    </xsl:otherwise>
                </xsl:choose>
            </text:span>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates />
    </text:p>
</xsl:template>
<!-- Paragraphs, with displays within                    -->
<!-- Later, so a higher priority match                   -->
<!-- Lists are ODT blocks                                -->
<!-- and so should not be within an ODT paragraph.       -->
<!-- We bust them out.                                   -->
<xsl:template match="p[ol|ul|dl]">
    <!-- will later loop over lists within paragraph -->
    <xsl:variable name="displays" select="ol|ul|dl" />
    <!-- content prior to first display is exceptional, but if empty,   -->
    <!-- as indicated by $initial, we do not produce an empty paragraph -->
    <!-- all interesting nodes of paragraph, before first display       -->
    <xsl:variable name="initial" select="$displays[1]/preceding-sibling::*|$displays[1]/preceding-sibling::text()" />
    <xsl:variable name="initial-content">
        <xsl:apply-templates select="$initial"/>
    </xsl:variable>
    <xsl:variable name="needs-title" select="boolean(parent::*/title) and (count(preceding-sibling::&METADATA;) = count(preceding-sibling::*))"/>
    <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
    <!-- This comparison might improve with a normalize-space()      -->
    <xsl:if test="not($initial-content='') or $needs-title">
        <text:p text:style-name="P-fragment">
            <xsl:if test="$needs-title">
                <text:span text:style-name="Runin-title">
                    <xsl:apply-templates select="parent::*" mode="title-full"/>
                </text:span>
            </xsl:if>
            <xsl:if test="not($initial-content='') and $needs-title">
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:if test="not($initial-content='')">
                <xsl:copy-of select="$initial-content" />
            </xsl:if>
        </text:p>
    </xsl:if>
    <!-- for each display, output the display, plus trailing content -->
    <xsl:for-each select="$displays">
        <!-- do the display proper -->
        <xsl:apply-templates select="." />
        <!-- look through remainder, all element and text nodes, and the next display -->
        <xsl:variable name="rightward" select="following-sibling::*|following-sibling::text()" />
        <xsl:variable name="next-display" select="following-sibling::*[self::ol or self::ul or self::dl][1]" />
        <xsl:choose>
            <xsl:when test="$next-display">
                <xsl:variable name="leftward" select="$next-display/preceding-sibling::*|$next-display/preceding-sibling::text()" />
                <!-- device below forms set intersection -->
                <xsl:variable name="common" select="$rightward[count(. | $leftward) = count($leftward)]" />
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$common" />
                </xsl:variable>
                <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
                <!-- This comparison might improve with a normalize-space()      -->
                <xsl:if test="not($common-content = '')">
                    <text:p text:style-name="P-fragment">
                        <xsl:copy-of select="$common-content" />
                    </text:p>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- finish the trailing content, if nonempty -->
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$rightward" />
                </xsl:variable>
                <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
                <!-- This comparison might improve with a normalize-space()      -->
                <xsl:if test="not($common-content = '')">
                    <text:p>
                        <xsl:attribute name="text:style-name">
                            <xsl:choose>
                                <xsl:when test="parent::*/following-sibling::*">
                                    <xsl:text>P</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>P-last</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:copy-of select="$common-content" />
                    </text:p>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
</xsl:template>

<!-- ##################################### -->
<!-- The workhseet introduction is special -->
<!-- ##################################### -->
<xsl:template match="worksheet//introduction">
    <!-- if there is a title but the first non-metadata child is not a p, give the title its own p -->
    <xsl:if test="title and boolean(*[not(&METADATA-FILTER;)][position() = 1][not(self::p)])">
        <text:p text:style-name="P">
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
    <text:list-item>
        <xsl:apply-templates/>
    </text:list-item>
</xsl:template>

<xsl:template match="worksheet//statement">
    <!-- if there is a title but the first non-metadata child is not a p, give the title its own p -->
    <xsl:if test="parent::*/title and boolean(*[not(&METADATA-FILTER;)][position() = 1][not(self::p)])">
        <text:p text:style-name="P">
            <text:span text:style-name="Runin-title">
                <xsl:apply-templates select="." mode="title-full"/>
            </text:span>
        </text:p>
    </xsl:if>
    <xsl:apply-templates/>
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

<!-- ###### -->
<!-- Fillin -->
<!-- ###### -->
<xsl:template match="fillin">
    <!-- TODO: using a string of nbsp with styled underlining does not make an accessible fillin -->
    <text:span text:style-name="Fillin">
        <xsl:call-template name="duplicate-string">
            <xsl:with-param name="text">
                <xsl:call-template name="nbsp-character"/>
            </xsl:with-param>
            <xsl:with-param name="count" select="@characters" />
        </xsl:call-template>
    </text:span>
</xsl:template>

<!-- ######## -->
<!-- Footnote -->
<!-- ######## -->
<xsl:template match="fn">
    <xsl:variable name="id">
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <xsl:variable name="citation">
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:variable>
    <text:note text:id="{$id}" text:note-class="footnote">
        <text:note-citation>
            <xsl:value-of select="$citation" />
        </text:note-citation>
        <text:note-body>
            <text:p text:style-name="Footnote">
                <xsl:apply-templates />
            </text:p>
        </text:note-body>
    </text:note>
</xsl:template>

<!-- ######## -->
<!-- SI Units -->
<!-- ######## -->
<xsl:template match="quantity">
    <!-- TODO: We would like this span to prevent line breaks within the quantity -->
    <text:span text:style-name="Quantity">
        <xsl:apply-templates select="mag"/>
        <!-- if not solo, add separation -->
        <xsl:if test="mag and (unit or per)">
            <xsl:call-template name="nbsp-character" />
        </xsl:if>
        <xsl:choose>
            <xsl:when test="per">
                <xsl:if test="not(unit)">
                    <xsl:text>1</xsl:text>
                </xsl:if>
                <xsl:apply-templates select="unit" />
                <xsl:call-template name="solidus-character" />
                <xsl:apply-templates select="per" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="unit"/>
            </xsl:otherwise>
        </xsl:choose>
    </text:span>
</xsl:template>
<xsl:template match="mag">
    <xsl:variable name="mag">
        <xsl:value-of select="."/>
    </xsl:variable>
    <xsl:value-of select="str:replace($mag,'\pi','&#x1D70B;')"/>
</xsl:template>
<!-- unit and per children of a quantity element    -->
<!-- have a mandatory base attribute                -->
<!-- may have prefix and exp attributes             -->
<!-- base and prefix are not abbreviations          -->
<xsl:key name="prefix-key" match="prefix" use="concat(../@name, @full)"/>
<xsl:key name="base-key" match="base" use="concat(../@name, @full)"/>
<xsl:template match="unit|per">
    <!-- add dot within a product of units -->
    <xsl:if test="(self::unit and preceding-sibling::unit) or (self::per and preceding-sibling::per)">
        <xsl:call-template name="midpoint-character" />
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:variable name="prefix">
            <xsl:value-of select="@prefix" />
        </xsl:variable>
        <xsl:variable name="short">
            <xsl:for-each select="document('pretext-units.xsl')">
                <xsl:value-of select="key('prefix-key',concat('prefixes',$prefix))/@short"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$short" />
    </xsl:if>
    <!-- base unit is required -->
    <xsl:variable name="base">
        <xsl:value-of select="@base" />
    </xsl:variable>
    <xsl:variable name="short">
        <xsl:for-each select="document('pretext-units.xsl')">
            <xsl:value-of select="key('base-key',concat('bases',$base))/@short"/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="$short" />
     <!-- exponent is optional -->
    <xsl:if test="@exp">
        <text:span text:style-name="Exponent">
            <xsl:value-of select="@exp"/>
        </text:span>
    </xsl:if>
</xsl:template>

<!-- ############# -->
<!-- Verbatim Text -->
<!-- ############# -->
<!-- .odt will (1) ignore leading and trailing whitespace -->
<!-- (2) collapse adjacent whitespace into a single space -->
<!-- (3) treat a line break character as a space          -->
<!-- So the explicit-space template replaces space with   -->
<!-- <text:s/> and replaces \n with <text:line-break/>    -->
<!-- With pre, we still past conteent to sanitize-text    -->
<!-- template for consistency with other output formats   -->

<!-- TODO: code spans will line break in the natural way, and I'm unsure if it's possible to prevent that.        -->
<!-- With line breaking possible, an outline makes less sense; can't seem to get an outline even if I wanted one. -->
<xsl:template match="c">
    <text:span text:style-name="C">
        <xsl:call-template name="explicit-space">
            <xsl:with-param name="string" select="."/>
        </xsl:call-template>
    </text:span>
</xsl:template>

<xsl:template match="cd">
    <xsl:if test="boolean(preceding-sibling::*) or boolean(preceding-sibling::text()[normalize-space() != ''])">
        <text:line-break/>
    </xsl:if>
    <text:span text:style-name="C">
        <xsl:choose>
            <xsl:when test="cline">
                <xsl:apply-templates select="cline" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="explicit-space">
                    <xsl:with-param name="string" select="."/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </text:span>
    <xsl:if test="boolean(following-sibling::*) or boolean(following-sibling::text()[normalize-space() != ''])">
        <text:line-break/>
    </xsl:if>
</xsl:template>

<xsl:template match="cline">
    <xsl:call-template name="explicit-space">
        <xsl:with-param name="string" select="."/>
    </xsl:call-template>
    <xsl:if test="following-sibling::cline">
        <text:line-break/>
    </xsl:if>
</xsl:template>

<xsl:template match="pre">
    <text:p text:style-name="Pre">
        <xsl:choose>
            <xsl:when test="cline">
                <xsl:apply-templates select="cline" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="explicit-space">
                    <xsl:with-param name="string">
                        <xsl:call-template name="sanitize-text">
                            <xsl:with-param name="text" select="." />
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </text:p>
</xsl:template>

<xsl:template name="explicit-space">
    <xsl:param name="string" select="''"/>
    <xsl:choose>
        <xsl:when test="string-length($string) = 0"/>
        <xsl:when test="substring($string,1,1) = ' '">
            <text:s/>
            <xsl:call-template name="explicit-space">
                <xsl:with-param name="string" select="substring($string,2)"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="substring($string,1,1) = '&#xa;'">
            <text:line-break/>
            <xsl:call-template name="explicit-space">
                <xsl:with-param name="string" select="substring($string,2)"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="substring($string,1,1)" />
            <xsl:call-template name="explicit-space">
                <xsl:with-param name="string" select="substring($string,2)"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ### -->
<!-- URL -->
<!-- ### -->
<xsl:template match="url">
    <!-- visible portion of HTML is the URL itself,   -->
    <!-- formatted as code, or content of PTX element -->
    <xsl:variable name="visible-text">
        <xsl:choose>
            <xsl:when test="not(*) and not(normalize-space())">
                <xsl:variable name="the-element">
                    <c>
                        <xsl:value-of select="@href" />
                    </c>
                </xsl:variable>
                <xsl:apply-templates select="exsl:node-set($the-element)/*" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Normally in an active link, except inactive in titles -->
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::shorttitle|ancestor::subtitle">
            <xsl:copy-of select="$visible-text" />
        </xsl:when>
        <xsl:otherwise>
            <!-- class name identifies an external link -->
            <text:a xlink:type="simple" xlink:href="{@href}">
                <xsl:copy-of select="$visible-text" />
            </text:a>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################ -->
<!-- Cross-references -->
<!-- ################ -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="content" />
    <xsl:param name="xref" />
    <xsl:param name="b-human-readable" />
    <xsl:copy-of select="$content" />
</xsl:template>

<xsl:template match="*" mode="xref-number">
    <xsl:param name="xref" select="/.." />
    <xsl:variable name="needs-part-prefix">
        <xsl:apply-templates select="." mode="crosses-part-boundary">
            <xsl:with-param name="xref" select="$xref" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$needs-part-prefix = 'true'">
        <xsl:apply-templates select="ancestor::part" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<xsl:template match="mrow[@tag]" mode="xref-number">
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->
<xsl:template match="ol">
    <text:list>
        <xsl:attribute name="text:style-name">
            <xsl:choose>
                <xsl:when test="@label">
                    <xsl:apply-templates select="." mode="get-label"/>
                </xsl:when>
                <xsl:when test="ancestor::exercise">
                    <xsl:text>Exercises</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>List</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates />
    </text:list>
</xsl:template>

<xsl:template match="ol" mode="get-label">
    <xsl:choose>
        <xsl:when test="contains(@label,'0')">
            <xsl:message>PTX:ERROR: .odt output format does not permit list numbering to begin with 0</xsl:message>
        </xsl:when>
        <xsl:when test="contains(@label,'1')">Arabic-1</xsl:when>
        <xsl:when test="contains(@label,'a')">Lowercase</xsl:when>
        <xsl:when test="contains(@label,'A')">Uppercase</xsl:when>
        <xsl:when test="contains(@label,'i')">Lowercase-roman</xsl:when>
        <xsl:when test="contains(@label,'I')">Uppercase-roman</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: ordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>-</xsl:text>
    <xsl:apply-templates select="." mode="list-level"/>
</xsl:template>

<xsl:template match="ul">
    <text:list>
        <xsl:attribute name="text:style-name">
            <xsl:choose>
                <xsl:when test="@label">
                    <xsl:apply-templates select="." mode="get-label"/>
                </xsl:when>
                <xsl:when test="ancestor::exercise">
                    <xsl:text>Exercises-unordered</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Unordered</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates />
    </text:list>
</xsl:template>

<xsl:template match="ul" mode="get-label">
    <xsl:choose>
        <xsl:when test="@label='disc'">Disc</xsl:when>
        <xsl:when test="@label='circle'">Circle</xsl:when>
        <xsl:when test="@label='square'">Square</xsl:when>
        <xsl:when test="@label=''">None</xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:ERROR: unordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>-</xsl:text>
    <xsl:apply-templates select="." mode="list-level"/>
</xsl:template>

<xsl:template match="dl">
    <text:list>
        <xsl:attribute name="text:style-name">
            <xsl:apply-templates select="." mode="get-label"/>
        </xsl:attribute>
        <xsl:apply-templates />
    </text:list>
</xsl:template>

<xsl:template match="dl" mode="get-label">
    <xsl:text>Description-</xsl:text>
    <xsl:apply-templates select="." mode="list-level"/>
</xsl:template>

<xsl:template match="li">
    <text:list-item>
        <!-- if there is a title but the first non-metadata child is not a p, give the title its own p -->
        <xsl:if test="title and boolean(*[not(&METADATA-FILTER;)][position() = 1][not(self::p)])">
            <text:p text:style-name="P">
                <text:span text:style-name="Runin-title">
                    <xsl:apply-templates select="." mode="title-full"/>
                </text:span>
            </text:p>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="p|blockquote|pre|figure|table|listing|list|aside|biographical|historical|sidebyside|sbsgroup|sage">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <text:p>
                    <xsl:attribute name="text:style-name">
                        <xsl:choose>
                            <xsl:when test="following-sibling::*|parent::li/following-sibling::li|ancestor::ol/following-sibling::*|ancestor::ol/parent::p/following-sibling::*|ancestor::ul/following-sibling::*|ancestor::ul/parent::p/following-sibling::*|ancestor::dl/following-sibling::*|ancestor::dl/parent::p/following-sibling::*">
                                <xsl:text>P</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>P-last</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </text:p>
            </xsl:otherwise>
        </xsl:choose>
    </text:list-item>
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
                    style:font-family-generic="decorative"
                    style:font-pitch="variable"
                />
                <style:font-face
                    style:name="Code"
                    svg:font-family="&apos;Courier New&apos;"
                    style:font-family-generic="modern"
                    style:font-pitch="fixed"
                />
            </office:font-face-decls>
            <office:styles>
                <style:default-style style:family="paragraph">
                    <!-- We are unable to use paragraphindentation in a consistent way throughout a worksheet, -->
                    <!-- including within exercises. So we use no indenation anywhere and end a paragraph with -->
                    <!-- 0.08304in (6pt) of vertical skip as a way to indicate new paragraphs.                 -->
                    <style:paragraph-properties
                        fo:orphans="2"
                        fo:widows="2"
                        style:auto-text-indent="false"
                        style:punctuation-wrap="hanging"
                    />
                    <style:text-properties
                        style:font-name="Main"
                        fo:font-size="12pt"
                        style:letter-kerning="true"
                    />
                </style:default-style>
                <!-- A typical paragraph -->
                <style:style
                    style:name="P"
                    style:family="paragraph"
                    >
                    <style:paragraph-properties
                        fo:margin-bottom="0.08304in"
                        fo:text-indent="0in"
                    />
                </style:style>
                <!-- This style is for when a PTX p is broken up into -->
                <!-- several ODT p because of a list or display       -->
                <style:style
                    style:name="P-fragment"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:margin-bottom="0in"
                    />
                </style:style>
                <!-- The last paragraph in a block can have a bit more vertical skip at the end -->
                <style:style
                    style:name="P-last"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:margin-bottom="0.16608in"
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
                <!-- Fillin -->
                <style:style
                    style:name="Fillin"
                    style:family="text"
                    >
                    <style:text-properties
                        style:text-underline-style="solid"
                        style:text-underline-width="auto"
                        style:text-underline-color="font-color"
                    />
                </style:style>
                <!-- Quantity -->
                <style:style
                    style:name="Quantity"
                    style:family="text"
                />
                <style:style
                    style:name="Super"
                    style:family="text"
                    >
                    <style:text-properties
                        style:text-position="super"
                    />
                </style:style>
                <!-- Verbatim -->
                <style:style
                    style:name="C"
                    style:family="text"
                    >
                    <style:text-properties
                        style:font-name="Code"
                        fo:background-color="#eeeeee"
                    />
                </style:style>
                <style:style
                    style:name="Cd"
                    style:display-name="Code Display"
                    style:family="paragraph"
                    >
                    <style:text-properties
                        style:font-name="Code"
                        fo:background-color="#eeeeee"
                    />
                </style:style>
                <style:style
                    style:name="Pre"
                    style:display-name="Preformatted"
                    style:family="paragraph"
                    >
                    <style:text-properties
                        style:font-name="Code"
                    />
                </style:style>
                <!-- Footnote -->
                <style:style
                    style:name="Footnote"
                    style:family="paragraph"
                    style:parent-style-name="P"
                    >
                    <style:paragraph-properties
                        fo:margin-left="0.2354in"
                        fo:margin-right="0in"
                        fo:text-indent="-0.2354in"
                        style:auto-text-indent="false"
                        text:number-lines="false"
                        text:line-number="0"
                    />
                    <style:text-properties
                        fo:font-size="10pt"
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
                <style:style
                    style:name="List_Numbering"
                    style:display-name="List Numbering"
                    style:family="text"
                />
                <style:style
                    style:name="Description_Numbering"
                    style:display-name="Description Numbering"
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
                    <text:list-level-style-number
                        text:level="2"
                        text:style-name="List_Numbering"
                        style:num-prefix="("
                        style:num-suffix=")"
                        style:num-format="a"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="0.6949in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="0.6949in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-number>
                    <text:list-level-style-number
                        text:level="3"
                        text:style-name="List_Numbering"
                        style:num-suffix="."
                        style:num-format="i"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="1.04235in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.04235in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-number>
                    <text:list-level-style-number
                        text:level="4"
                        text:style-name="List_Numbering"
                        style:num-suffix="."
                        style:num-format="A"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="1.3898in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.3898in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-number>
                </text:list-style>
                <text:list-style
                    style:name="List"
                    >
                    <text:list-level-style-number
                        text:level="1"
                        text:style-name="List_Numbering"
                        style:num-prefix="("
                        style:num-suffix=")"
                        style:num-format="a"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="0.34745in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="0.6949in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-number>
                    <text:list-level-style-number
                        text:level="2"
                        text:style-name="List_Numbering"
                        style:num-suffix="."
                        style:num-format="i"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="0.6949in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.04235in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-number>
                    <text:list-level-style-number
                        text:level="3"
                        text:style-name="List_Numbering"
                        style:num-suffix="."
                        style:num-format="A"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="1.04235in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.3898in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-number>
                </text:list-style>
                <text:list-style
                    style:name="Unordered"
                    >
                    <text:list-level-style-bullet
                        text:level="1"
                        text:style-name="List_Numbering"
                        text:bullet-char="•"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="0.6949in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="0.6949in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-bullet>
                    <text:list-level-style-bullet
                        text:level="2"
                        text:style-name="List_Numbering"
                        text:bullet-char="◦"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="1.04235in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.04235in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-bullet>
                    <text:list-level-style-bullet
                        text:level="3"
                        text:style-name="List_Numbering"
                        text:bullet-char="■"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="1.3898in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.3898in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-bullet>
                    <text:list-level-style-bullet
                        text:level="4"
                        text:style-name="List_Numbering"
                        text:bullet-char="•"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="1.73725in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.73725in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-bullet>
                </text:list-style>
                <text:list-style
                    style:name="Exercises-unordered"
                    >
                    <text:list-level-style-bullet
                        text:level="2"
                        text:style-name="List_Numbering"
                        text:bullet-char="•"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="0.6949in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="0.6949in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-bullet>
                    <text:list-level-style-bullet
                        text:level="3"
                        text:style-name="List_Numbering"
                        text:bullet-char="◦"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="1.04235in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.04235in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-bullet>
                    <text:list-level-style-bullet
                        text:level="4"
                        text:style-name="List_Numbering"
                        text:bullet-char="■"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="1.3898in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.3898in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-bullet>
                    <text:list-level-style-bullet
                        text:level="5"
                        text:style-name="List_Numbering"
                        text:bullet-char="•"
                        >
                        <style:list-level-properties
                            text:list-level-position-and-space-mode="label-alignment"
                            >
                            <style:list-level-label-alignment
                                text:label-followed-by="listtab"
                                text:list-tab-stop-position="1.73725in"
                                fo:text-indent="-0.34745in"
                                fo:margin-left="1.73725in"
                            />
                        </style:list-level-properties>
                    </text:list-level-style-bullet>
                </text:list-style>
                <xsl:if test="$document-root//ol[@label]">
                    <xsl:variable name="ol-with-label" select="$document-root//ol[@label]"/>
                    <xsl:for-each select="$ol-with-label">
                        <xsl:variable name="level">
                            <xsl:apply-templates select="." mode="list-level"/>
                        </xsl:variable>
                        <text:list-style>
                            <xsl:attribute name="style:name">
                                <xsl:apply-templates select="." mode="get-label"/>
                            </xsl:attribute>
                            <text:list-level-style-number
                                text:style-name="List_Numbering"
                                >
                                <xsl:attribute name="text:level">
                                    <xsl:value-of select="$level + 1"/>
                                </xsl:attribute>
                                <xsl:attribute name="style:num-prefix">
                                    <xsl:if test="contains(@label,'a')">
                                        <xsl:text>(</xsl:text>
                                    </xsl:if>
                                </xsl:attribute>
                                <xsl:attribute name="style:num-suffix">
                                    <xsl:choose>
                                        <xsl:when test="contains(@label,'a')">
                                            <xsl:text>)</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>.</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="style:num-format">
                                    <xsl:choose>
                                        <xsl:when test="contains(@label,'0')">
                                            <xsl:message>PTX:ERROR: .odt output format does not permit list numbering to begin with 0</xsl:message>
                                        </xsl:when>
                                        <xsl:when test="contains(@label,'1')">1</xsl:when>
                                        <xsl:when test="contains(@label,'a')">a</xsl:when>
                                        <xsl:when test="contains(@label,'A')">A</xsl:when>
                                        <xsl:when test="contains(@label,'i')">i</xsl:when>
                                        <xsl:when test="contains(@label,'I')">I</xsl:when>
                                        <xsl:otherwise>
                                            <xsl:message>PTX:ERROR: ordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <style:list-level-properties
                                    text:list-level-position-and-space-mode="label-alignment"
                                    >
                                    <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                                    <style:list-level-label-alignment
                                        text:label-followed-by="listtab"
                                        fo:text-indent="-0.34745in"
                                        >
                                        <xsl:attribute name="text:list-tab-stop-position">
                                            <xsl:value-of select="0.34745 * ($level + 1)"/>
                                            <xsl:text>in</xsl:text>
                                        </xsl:attribute>
                                        <xsl:attribute name="fo:margin-left">
                                            <xsl:value-of select="0.34745 * ($level + 2)"/>
                                            <xsl:text>in</xsl:text>
                                        </xsl:attribute>
                                    </style:list-level-label-alignment>
                                </style:list-level-properties>
                            </text:list-level-style-number>
                        </text:list-style>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="$document-root//ul[@label]">
                    <xsl:variable name="ul-with-label" select="$document-root//ul[@label]"/>
                    <xsl:for-each select="$ul-with-label">
                        <xsl:variable name="level">
                            <xsl:apply-templates select="." mode="list-level"/>
                        </xsl:variable>
                        <text:list-style>
                            <xsl:attribute name="style:name">
                                <xsl:apply-templates select="." mode="get-label"/>
                            </xsl:attribute>
                            <text:list-level-style-bullet
                                text:style-name="List_Numbering"
                                >
                                <xsl:attribute name="text:level">
                                    <xsl:choose>
                                        <xsl:when test="ancestor::exercise">
                                            <xsl:value-of select="$level + 1"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$level"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="text:bullet-char">
                                    <xsl:choose>
                                        <xsl:when test="@label='disc'">•</xsl:when>
                                        <xsl:when test="@label='circle'">◦</xsl:when>
                                        <xsl:when test="@label='square'">■</xsl:when>
                                        <xsl:when test="@label=''"><xsl:call-template name="nbsp-character"/></xsl:when>
                                        <xsl:otherwise>
                                            <xsl:message>PTX:ERROR: unordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <style:list-level-properties
                                    text:list-level-position-and-space-mode="label-alignment"
                                    >
                                    <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                                    <style:list-level-label-alignment
                                        text:label-followed-by="listtab"
                                        fo:text-indent="-0.34745in"
                                        >
                                        <xsl:attribute name="text:list-tab-stop-position">
                                            <xsl:value-of select="0.34745 * ($level)"/>
                                            <xsl:text>in</xsl:text>
                                        </xsl:attribute>
                                        <xsl:attribute name="fo:margin-left">
                                            <xsl:value-of select="0.34745 * ($level + 1)"/>
                                            <xsl:text>in</xsl:text>
                                        </xsl:attribute>
                                    </style:list-level-label-alignment>
                                </style:list-level-properties>
                            </text:list-level-style-bullet>
                        </text:list-style>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="$document-root//dl">
                    <xsl:variable name="dl" select="$document-root//dl"/>
                    <xsl:for-each select="$dl">
                        <xsl:variable name="level">
                            <xsl:apply-templates select="." mode="list-level"/>
                        </xsl:variable>
                        <text:list-style>
                            <xsl:attribute name="style:name">
                                <xsl:apply-templates select="." mode="get-label"/>
                            </xsl:attribute>
                            <text:list-level-style-bullet
                                text:style-name="Description_Numbering"
                                >
                                <xsl:attribute name="text:level">
                                    <xsl:choose>
                                        <xsl:when test="ancestor::exercise">
                                            <xsl:value-of select="$level + 1"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$level"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="text:bullet-char">
                                    <xsl:call-template name="nbsp-character"/>
                                </xsl:attribute>
                                <style:list-level-properties
                                    text:list-level-position-and-space-mode="label-alignment"
                                    >
                                    <!-- 0.34745in is 5ex in 12pt Latin Modern Roman -->
                                    <style:list-level-label-alignment
                                        text:label-followed-by="listtab"
                                        fo:text-indent="-0.34745in"
                                        >
                                        <xsl:attribute name="text:list-tab-stop-position">
                                            <xsl:value-of select="0.34745 * ($level - 0.5)"/>
                                            <xsl:text>in</xsl:text>
                                        </xsl:attribute>
                                        <xsl:attribute name="fo:margin-left">
                                            <xsl:value-of select="0.34745 * ($level)"/>
                                            <xsl:text>in</xsl:text>
                                        </xsl:attribute>
                                    </style:list-level-label-alignment>
                                </style:list-level-properties>
                            </text:list-level-style-bullet>
                        </text:list-style>
                    </xsl:for-each>
                </xsl:if>
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
            <!-- Print header on first page, but move to a header-free page -->
            <office:master-styles>
                <style:master-page
                    style:name="Standard"
                    style:page-layout-name="Page"
                    style:next-style-name="Latter-page"
                    >
                    <style:header>
                        <text:p text:style-name="Header-first-page">
                            <xsl:apply-templates select="$document-root" mode="title-full" />
                            <text:tab/>
                            <xsl:apply-templates select="." mode="type-name" />
                            <xsl:text> </xsl:text>
                            <xsl:apply-templates select="." mode="number" />
                            <text:tab/>
                            <xsl:apply-templates select="$document-root/frontmatter/titlepage/author" mode="name-list"/>
                        </text:p>
                    </style:header>
                </style:master-page>
                <style:master-page
                    style:name="Latter-page"
                    style:page-layout-name="Page"
                    style:next-style-name="Latter-page"
                />
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
