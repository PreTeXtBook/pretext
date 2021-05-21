<?xml version='1.0'?>

<!--********************************************************************
Copyright 2017 Robert A. Beezer

This file is part of MathBook XML.

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

<!-- Identify as a stylesheet -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    exclude-result-prefixes="xsl"
>

<xsl:output method="xml" encoding="UTF-8" />

<!-- ###################### -->
<!-- Deprecations and Fixes -->
<!-- ###################### -->

<!-- Deprecations that can be fixed with a transformation -->
<!-- In reverse chronological order, with dates           -->

<!-- 2020-03-13  webwork setup obsolete -->
<xsl:template match="webwork/setup">
    <xsl:apply-templates select="@* | node()" />
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2020-03-13</xsl:with-param>
        <xsl:with-param name="message">Removing &lt;setup&gt; wrapper from a &lt;webwork&gt;, preserving contents (&lt;pg-code&gt;?)</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2019-06-28  deprecate captioned lists to be titled lists -->
<xsl:template match="list[title]/caption">
    <xsl:comment>
        <xsl:text>Commented list/caption: </xsl:text>
        <xsl:apply-templates select="*|text()" />
    </xsl:comment>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-06-28</xsl:with-param>
        <xsl:with-param name="message">Converting a &lt;list&gt;/&lt;caption&gt; to a source comment</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2019-06-28  deprecate captioned lists to be titled lists -->
<xsl:template match="list[not(title)]/caption">
    <title>
        <xsl:apply-templates select="@* | node()" />
    </title>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-06-28</xsl:with-param>
        <xsl:with-param name="message">Converting a &lt;list&gt;/&lt;caption&gt; to a &lt;list&gt;/&lt;title&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2019-06-28  deprecate captioned tables to be titled tables -->
<xsl:template match="table/caption">
    <title>
        <xsl:apply-templates select="@* | node()" />
    </title>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-06-28</xsl:with-param>
        <xsl:with-param name="message">Converting a &lt;table&gt;/&lt;caption&gt; to a &lt;table&gt;/&lt;title&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2019-02-10  todo element replaced by a prefixed XML comment -->
<xsl:template match="todo">
    <xsl:comment>
        <xsl:text> </xsl:text>
        <xsl:text>ToDo: </xsl:text>
        <xsl:apply-templates/>
        <xsl:text> </xsl:text>
    </xsl:comment>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-10</xsl:with-param>
        <xsl:with-param name="message">Replacing a &lt;todo&gt; with a prefixed XML comment</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2019-02-06 Nine unnecessary elements     -->
<!-- <, >, [, ], *, /, `, braces and brackets -->
<xsl:template match="less">
    <xsl:text>&lt;</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;less/&gt; with &quot;&lt;&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="greater">
    <xsl:text>&gt;</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;greater/&gt; with &quot;&gt;&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="lbracket">
    <xsl:text>[</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;lbracket/&gt; with &quot;[&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rbracket">
    <xsl:text>]</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;rbracket/&gt; with &quot;]&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="asterisk">
    <xsl:text>*</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;asterisk/&gt; with &quot;*&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="slash">
    <xsl:text>/</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;slash/&gt; with &quot;/&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="backtick">
    <xsl:text>`</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;backtick/&gt; with &quot;`&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="braces">
    <xsl:text>{</xsl:text>
        <xsl:apply-templates select="@* | node()" />
    <xsl:text>}</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;braces&gt; by {...}</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="brackets">
    <xsl:text>[</xsl:text>
        <xsl:apply-templates select="@* | node()" />
    <xsl:text>]</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;brackets&gt; by [...]</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2019-02-06 LaTeX's 10 reserved characters: # $ % ^ & _ { } ~ \ -->
<xsl:template match="hash">
    <xsl:text>#</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;hash/&gt; with &quot;#&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="dollar">
    <xsl:text>$</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;dollar/&gt; with &quot;$&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="percent">
    <xsl:text>%</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;percent/&gt; with &quot;%&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="circumflex">
    <xsl:text>^</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;circumflex/&gt; with &quot;^&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="ampersand">
    <xsl:text>&amp;</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;ampersand/&gt; with &quot;&amp;&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="underscore">
    <xsl:text>_</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;underscore/&gt; with &quot;_&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="lbrace">
    <xsl:text>{</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;lbrace/&gt; with &quot;{&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rbrace">
    <xsl:text>}</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;rbrace/&gt; with &quot;}&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="tilde">
    <xsl:text>~</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;tilde/&gt; with &quot;~&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="backslash">
    <xsl:text>\</xsl:text>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2019-02-06</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;backslash/&gt; with &quot;\&quot;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2018-12-30  circa shortened to ca -->
<xsl:template match="circa">
    <ca/>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2018-12-30</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;circa/&gt; by &lt;ca/&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2018-05-02  sidebyside paragraphs to stack, preserve title -->
<xsl:template match="sidebyside/paragraphs">
    <stack>
        <xsl:comment> Old paragraphs title: <xsl:apply-templates select="title/node()" /> </xsl:comment>
        <xsl:apply-templates select="@*[not(self::title)] | node()" />
    </stack>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2018-05-02</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;paragraphs&gt; inside &lt;sidebyside&gt; with &lt;stack&gt;, &quot;title&quot; preserved in a comment</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2018-02-05  booktitle to simply pubtitle -->
<xsl:template match="booktitle">
    <pubtitle>
        <xsl:apply-templates select="@* | node()" />
    </pubtitle>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2018-02-05</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;booktitle&gt; by &lt;pubtitle&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2017-12-07  "c" content totally escaped for LaTeX -->
<xsl:template match="c/@latexsep|cd/@latexsep">
    <!-- do nothing, just drop it and report -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-12-07</xsl:with-param>
        <xsl:with-param name="message">Removing &lt;@latexsep&gt; from a &lt;c&gt; or &lt;cd&gt; element</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2017-08-06  wrap "program" and "console" in "sidebyside" at full width -->
<xsl:template match="program[not(parent::sidebyside or parent::listing)]">
    <sidebyside width="100%">
        <program>
            <xsl:apply-templates select="@* | node()" />
        </program>
    </sidebyside>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-08-06</xsl:with-param>
        <xsl:with-param name="message">Wrapping top-level &lt;program&gt; with full-width &lt;sidebyside&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="console[not(parent::sidebyside or parent::listing)]">
    <sidebyside width="100%">
        <console>
            <xsl:apply-templates select="@* | node()" />
        </console>
    </sidebyside>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-08-06</xsl:with-param>
        <xsl:with-param name="message">Wrapping top-level &lt;console&gt; with full-width &lt;sidebyside&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2017-08-04  top-level "task" become "exploration" -->
<xsl:template match="task[parent::chapter or parent::appendix or parent::section or parent::subsection or parent::subsubsection or parent::paragraphs or parent::introduction or parent::conclusion]">
    <exploration>
        <xsl:apply-templates select="@* | node()" />
    </exploration>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-08-04</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;task&gt; by &lt;exploration&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2017-07-25  replacement of three xref/@autoname attributes by @text -->
<xsl:template match="@autoname">
    <xsl:variable name="old-value" select="string(.)" />
    <xsl:attribute name="text">
        <xsl:choose>
            <xsl:when test="$old-value = 'no'">global</xsl:when>
            <xsl:when test="$old-value = 'yes'">type-global</xsl:when>
            <xsl:when test="$old-value = 'title'">title</xsl:when>
        </xsl:choose>
    </xsl:attribute>
</xsl:template>

<!-- 2017-07-18:  cosmetic changes to WeBWorK image attribute -->
<xsl:template match="@tex_size">
    <xsl:attribute name="tex-size">
        <xsl:value-of select="." />
    </xsl:attribute>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-07-18</xsl:with-param>
        <xsl:with-param name="message">Replacing @tex_size by @tex-size in WeBWorK &lt;image&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<!--  -->
<!-- 2017-07-14:  cosmetic changes to index specification and production -->
<xsl:template match="index-part">
    <index>
        <xsl:apply-templates select="@* | node()" />
    </index>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-07-14</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;index-part&gt; by &lt;index&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<!--  -->
<!-- try not to clobber new "index" division on subsequent run -->
<xsl:template match="index[not(index-list)]">
    <idx>
        <xsl:apply-templates select="@* | node()" />
    </idx>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-07-14</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;index&gt; by &lt;idx&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<!--  -->
<xsl:template match="index/main">
    <h>
        <xsl:apply-templates select="@* | node()" />
    </h>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-07-14</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;index&gt;/&lt;main&gt; by &lt;idx&gt;/&lt;h&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<!--  -->
<xsl:template match="index/sub">
    <h>
        <xsl:apply-templates select="@* | node()" />
    </h>
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-07-14</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;index&gt;/&lt;sub&gt; by &lt;idx&gt;/&lt;h&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2017-07-05:  wrap a captioned side-by-side as a captioned figure -->
<xsl:template match="sidebyside[caption]">
    <figure>
        <xsl:copy-of select="@xml:id" />
        <!-- <xsl:apply-templates select="@*[not(self::@xml:id)]" /> -->
        <xsl:text>&#xa;</xsl:text>
        <xsl:copy-of select="caption" />
        <xsl:text>&#xa;    </xsl:text>
        <sidebyside>
            <xsl:apply-templates select="@*[name()!='xml:id'] | node()[not(self::caption)]" />
        </sidebyside>
        <xsl:text>&#xa;</xsl:text>
    </figure>
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-07-05</xsl:with-param>
        <xsl:with-param name="message">Moving a &lt;<xsl:value-of select="local-name(.)" />&gt; with a &lt;caption&gt; into a new &lt;figure&gt; with the same &lt;caption&gt; and @xml:id</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2017-07-05:  convert top-level caption-less figure/table/listing to a side-by-side  -->
<!-- 2019-06-28:  removed fixes for tables, since they now have titles                   -->
<xsl:template match="figure[not(caption) and not(parent::sidebyside)] | listing[not(caption) and not(parent::sidebyside)]">
    <sidebyside>
        <!-- migrate an image width attribute -->
        <xsl:if test="self::figure and image[@width]">
            <xsl:copy-of select="image/@width" />
        </xsl:if>
        <xsl:apply-templates select="@* | node()" />
    </sidebyside>
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-07-05</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;<xsl:value-of select="local-name(.)" />&gt; that is a child of a division, and has no &lt;caption&gt;, by an equivalent &lt;sidebyside&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<!-- @width moves above, now trash it at origin -->
<xsl:template match="figure[not(caption) and not(parent::sidebyside)]/image">
    <image>
        <xsl:apply-templates select="@*[name()!='width'] | node()" />
    </image>
</xsl:template>

<xsl:template match="figure[not(caption) and parent::sidebyside] | listing[not(caption) and parent::sidebyside]">
    <xsl:if test="@xml:id">
        <xsl:comment>NOTE: @xml:id=<xsl:value-of select="@xml:id" /> from a &lt;<xsl:value-of select="local-name(.)" />&gt; was dropped while fixing deprecations.  The @xml:id may belong on an element just below, though it is unlikely a caption-less item was ever the target of a cross-reference.</xsl:comment>
    </xsl:if>
    <xsl:apply-templates select="node()" />
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-07-05</xsl:with-param>
        <xsl:with-param name="message">Replacing a &lt;<xsl:value-of select="local-name(.)" />&gt; that is a child of a division, and has no &lt;caption&gt;, by an equivalent &lt;sidebyside&gt;.  NOTE: attributes, such as an  @xml:id  might be lost in the process, see comment in the resulting source</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2017-02-05:  replace hyphen element by hyphen-minus element -->
<xsl:template match="hyphen">
    <hyphen-minus/>
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2017-02-05</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;hyphen/&gt; by &lt;hyphen-minus/&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2016-07-31: requiring @width attribute to be a percentage, -->
<!-- no easy way to fix this, so warnings will have to suffice  -->

<!-- 2016-07-31: withdrew @height attribute on image element -->
<xsl:template match="image/@height[not(ancestor::*[self::webwork])]">
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2016-07-31</xsl:with-param>
        <xsl:with-param name="message">Removing @height attribute of &lt;image&gt; (outside of a WeBWorK exercise)</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2016-05-23:  empty "br" elements for multiline output are banned    -->
<!-- No easy way to uniformly fix this, so warnings will have to suffice -->

<!-- 2016-05-23:  parts of a letter or memorandum suggest     -->
<!-- they *must* be structured with "line" elements           -->
<!-- Perhaps more accurate to just warn about misuse of "br", -->
<!-- as we can go with mixed-content or structured versions   -->

<!-- 2016-04-27: withdrew pluralizing prefix names in xref link text -->
<xsl:template match="xref/@autoname[. = 'plural']">
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2016-04-27</xsl:with-param>
        <xsl:with-param name="message">Removing @autoname attribute of &lt;xref&gt; set to obsolete value 'plural'</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2015-12-12: an ordered list with blank labels -->
<!-- should be an unordered list with blank labels -->
<xsl:template match="ol[@label='']">
    <ul>
        <xsl:apply-templates select="@* | node()" />
    </ul>
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2015-12-12</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;ol&gt; with empty labels by a &lt;ul&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2015-03-17: tables are very different  -->
<!-- Some automated fixing, will            -->
<!-- need attention by hand also            -->
<!--  -->
<!-- enclosing  tgroup  becomes a  tabular  -->
<xsl:template match="tgroup">
    <tabular>
        <xsl:apply-templates select="@* | node()" />
    </tabular>
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2015-03-17</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;tgroup&gt; by &lt;tabular&gt;, tables are now very different</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<!-- alignment is different, will require a hand-fix -->
<xsl:template match="tgroup/@align|tgroup/@cols">
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2015-03-17</xsl:with-param>
        <xsl:with-param name="message">Removing obsolete @align and @cols attributes, adjust alignment of contents of tabular by hand</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<!-- drop intermediate  thead  and  tbody  -->
<xsl:template match="thead|tbody">
    <xsl:apply-templates select="@* | node()" />
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2015-03-17</xsl:with-param>
        <xsl:with-param name="message">Removing intermediate &lt;thead&gt; and &lt;tbody&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<!-- maybe we'll recycle entry for something else, so protect it -->
<xsl:template match="row/entry">
    <cell>
        <xsl:apply-templates select="@* | node()" />
    </cell>
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2015-03-17</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;entry&gt; by &lt;cell&gt; in a &lt;row&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2015-03-13: the paragraph lightweight sectioning is better in plural -->
<xsl:template match="paragraph">
    <paragraphs>
        <xsl:apply-templates select="@* | node()" />
    </paragraphs>
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2015-03-13</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;paragraph&gt; by &lt;paragraphs&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2015-01-28: <circum /> is gone, <circumflex /> won -->
<xsl:template match="circum">
    <circumflex>
        <xsl:apply-templates select="@* | node()" />
    </circumflex>
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2014-06-25</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;circumflex/&gt; by &lt;circum/&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2014-06-25: <cite> gone, replace directly with <xref> -->
<xsl:template match="cite">
    <xref>
        <xsl:apply-templates select="@* | node()" />
    </xref>
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2014-06-25</xsl:with-param>
        <xsl:with-param name="message">Replacing &lt;cite&gt; by &lt;xref&gt;</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- 2014-05-04: @filebase attributes is obsolete, we drop it -->
<!-- Author's responsibility to introduce/adjust an @xml:id   -->
<xsl:template match="@filebase">
    <!--  -->
    <xsl:call-template name="deprecation-fix-report">
        <xsl:with-param name="date">2014-05-04</xsl:with-param>
        <xsl:with-param name="message">Removing obsolete @filebase attribute, introduce or adjust an @xml:id to play this role</xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- ######################### -->
<!-- Stylesheet Infrastructure -->
<!-- ######################### -->

<!-- We place these templates at the end,  -->
<!-- the deprecations above are the items of -->
<!-- interest, in reverse chronological order -->

<!-- We do a few things to get started              -->
<!-- We override matching the root element of the   -->
<!-- imported worksheet with the identity template, -->
<!-- and then resume walking the tree               -->

<!-- Switch to prevent naive use -->
<xsl:param name="fix" select="'no'" />

<xsl:template match="/">
    <xsl:choose>
        <!-- print to console and quit -->
        <xsl:when test="$fix = 'no'">
            <xsl:call-template name="instructions" />
        </xsl:when>
        <!-- modal run on root to just change source cosmetically -->
        <xsl:when test="$fix = 'normalize'">
            <xsl:apply-templates select="." mode="normalize"/>
        </xsl:when>
        <!-- default templates on children to actually change source -->
        <xsl:when test="$fix = 'all'">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" />
            </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>The parameter "fix" must be set to 'no', 'normalize', or 'all'.  Assuming 'no'.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="instructions">
    <xsl:message terminate="yes">
        <text>*                                                                        *&#xa;</text>
        <text>*  The "fix-deprecations" stylesheet will change your source files       *&#xa;</text>
        <text>*                                                                        *&#xa;</text>
        <text>*   1.  Experiment on copies and keep good backups                       *&#xa;</text>
        <text>*   2.  Send output to a file in some other directory than originals     *&#xa;</text>
        <text>*   3.  Do not enable  xinclude  processing if you want modular files    *&#xa;</text>
        <text>*   4.  Indentation and whitespace will be preserved                     *&#xa;</text>
        <text>*   5.  Attributes will likely be re-ordered, with normalized spacing    *&#xa;</text>
        <text>*   6.  Empty elements will have spaces removed from the tag             *&#xa;</text>
        <text>*   7.  Elements with no content may be written with a single empty tag  *&#xa;</text>
        <text>*   8.  CDATA sections will have some characters replaced by entities    *&#xa;</text>
        <text>*   9.  The output files will be labeled as having UTF-8 encoding        *&#xa;</text>
        <text>*  10.  It might be necessary to run this more than once                 *&#xa;</text>
        <text>*  11.  Be sure to inspect the results, perhaps using a "diff" tool      *&#xa;</text>
        <text>*  12.  It should be safe to run this repeatedly, even after updates     *&#xa;</text>
        <text>*                                                                        *&#xa;</text>
        <text>*  Quitting now.  Instructions:                                          *&#xa;</text>
        <text>*                                                                        *&#xa;</text>
        <text>*  To use, and confirm you have read this far, use a parameter on the    *&#xa;</text>
        <text>*  command line that sets the parameter "fix" to the value 'all'         *&#xa;</text>
        <text>*                                                                        *&#xa;</text>
        <text>*  Set the parameter "fix" to 'normalize' to only adjust source format   *&#xa;</text>
        <text>*  (This might be a useful first step the first time you use this)       *&#xa;</text>
        <text>*                                                                        *&#xa;</text>
    </xsl:message>
</xsl:template>

<!-- A template to report to console, so we can adjust later -->
<xsl:template name="deprecation-fix-report">
    <xsl:param name="message" select="''" />
    <xsl:param name="date" select="''" />
    <xsl:message><xsl:value-of select="$message" /> (from <xsl:value-of select="$date" />)</xsl:message>
</xsl:template>

<!-- Walk the tree, copying everything as-is -->
<!-- with templates above as exceptions      -->
<xsl:template match="@* | node()">
    <xsl:copy>
        <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
</xsl:template>

<!-- Walk the tree, copying everything *exactly* -->
<xsl:template match="@* | node()" mode="normalize">
    <xsl:copy>
        <xsl:apply-templates select="@* | node()" mode="normalize" />
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>