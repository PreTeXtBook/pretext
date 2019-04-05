<?xml version="1.0" standalone="yes"?>
<axsl:stylesheet xmlns:axsl="http://www.w3.org/1999/XSL/Transform" xmlns:sch="http://www.ascc.net/xml/schematron" xmlns:iso="http://purl.oclc.org/dsdl/schematron" version="1.0"><!--Implementers: please note that overriding process-prolog or process-root is 
    the preferred method for meta-stylesheets to use where possible. -->
<axsl:param name="archiveDirParameter"/><axsl:param name="archiveNameParameter"/><axsl:param name="fileNameParameter"/><axsl:param name="fileDirParameter"/>

<!--PHASES-->


<!--PROLOG-->
<axsl:output method="text"/>

<!--KEYS-->


<!--DEFAULT RULES-->


<!--MODE: SCHEMATRON-SELECT-FULL-PATH-->
<!--This mode can be used to generate an ugly though full XPath for locators-->
<axsl:template match="*" mode="schematron-select-full-path"><axsl:apply-templates select="." mode="schematron-get-full-path"/></axsl:template>

<!--MODE: SCHEMATRON-FULL-PATH-->
<!--This mode can be used to generate an ugly though full XPath for locators-->
<axsl:template match="*" mode="schematron-get-full-path"><axsl:apply-templates select="parent::*" mode="schematron-get-full-path"/><axsl:text>/</axsl:text><axsl:choose><axsl:when test="namespace-uri()=''"><axsl:value-of select="name()"/><axsl:variable name="p_1" select="1+    count(preceding-sibling::*[name()=name(current())])"/><axsl:if test="$p_1&gt;1 or following-sibling::*[name()=name(current())]">[<axsl:value-of select="$p_1"/>]</axsl:if></axsl:when><axsl:otherwise><axsl:text>*[local-name()='</axsl:text><axsl:value-of select="local-name()"/><axsl:text>' and namespace-uri()='</axsl:text><axsl:value-of select="namespace-uri()"/><axsl:text>']</axsl:text><axsl:variable name="p_2" select="1+   count(preceding-sibling::*[local-name()=local-name(current())])"/><axsl:if test="$p_2&gt;1 or following-sibling::*[local-name()=local-name(current())]">[<axsl:value-of select="$p_2"/>]</axsl:if></axsl:otherwise></axsl:choose></axsl:template><axsl:template match="@*" mode="schematron-get-full-path"><axsl:text>/</axsl:text><axsl:choose><axsl:when test="namespace-uri()=''">@<axsl:value-of select="name()"/></axsl:when><axsl:otherwise><axsl:text>@*[local-name()='</axsl:text><axsl:value-of select="local-name()"/><axsl:text>' and namespace-uri()='</axsl:text><axsl:value-of select="namespace-uri()"/><axsl:text>']</axsl:text></axsl:otherwise></axsl:choose></axsl:template>

<!--MODE: SCHEMATRON-FULL-PATH-2-->
<!--This mode can be used to generate prefixed XPath for humans-->
<axsl:template match="node() | @*" mode="schematron-get-full-path-2"><axsl:for-each select="ancestor-or-self::*"><axsl:text>/</axsl:text><axsl:value-of select="name(.)"/><axsl:if test="preceding-sibling::*[name(.)=name(current())]"><axsl:text>[</axsl:text><axsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/><axsl:text>]</axsl:text></axsl:if></axsl:for-each><axsl:if test="not(self::*)"><axsl:text/>/@<axsl:value-of select="name(.)"/></axsl:if></axsl:template>

<!--MODE: GENERATE-ID-FROM-PATH -->
<axsl:template match="/" mode="generate-id-from-path"/><axsl:template match="text()" mode="generate-id-from-path"><axsl:apply-templates select="parent::*" mode="generate-id-from-path"/><axsl:value-of select="concat('.text-', 1+count(preceding-sibling::text()), '-')"/></axsl:template><axsl:template match="comment()" mode="generate-id-from-path"><axsl:apply-templates select="parent::*" mode="generate-id-from-path"/><axsl:value-of select="concat('.comment-', 1+count(preceding-sibling::comment()), '-')"/></axsl:template><axsl:template match="processing-instruction()" mode="generate-id-from-path"><axsl:apply-templates select="parent::*" mode="generate-id-from-path"/><axsl:value-of select="concat('.processing-instruction-', 1+count(preceding-sibling::processing-instruction()), '-')"/></axsl:template><axsl:template match="@*" mode="generate-id-from-path"><axsl:apply-templates select="parent::*" mode="generate-id-from-path"/><axsl:value-of select="concat('.@', name())"/></axsl:template><axsl:template match="*" mode="generate-id-from-path" priority="-0.5"><axsl:apply-templates select="parent::*" mode="generate-id-from-path"/><axsl:text>.</axsl:text><axsl:value-of select="concat('.',name(),'-',1+count(preceding-sibling::*[name()=name(current())]),'-')"/></axsl:template><!--MODE: SCHEMATRON-FULL-PATH-3-->
<!--This mode can be used to generate prefixed XPath for humans 
	(Top-level element has index)-->
<axsl:template match="node() | @*" mode="schematron-get-full-path-3"><axsl:for-each select="ancestor-or-self::*"><axsl:text>/</axsl:text><axsl:value-of select="name(.)"/><axsl:if test="parent::*"><axsl:text>[</axsl:text><axsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/><axsl:text>]</axsl:text></axsl:if></axsl:for-each><axsl:if test="not(self::*)"><axsl:text/>/@<axsl:value-of select="name(.)"/></axsl:if></axsl:template>

<!--MODE: GENERATE-ID-2 -->
<axsl:template match="/" mode="generate-id-2">U</axsl:template><axsl:template match="*" mode="generate-id-2" priority="2"><axsl:text>U</axsl:text><axsl:number level="multiple" count="*"/></axsl:template><axsl:template match="node()" mode="generate-id-2"><axsl:text>U.</axsl:text><axsl:number level="multiple" count="*"/><axsl:text>n</axsl:text><axsl:number count="node()"/></axsl:template><axsl:template match="@*" mode="generate-id-2"><axsl:text>U.</axsl:text><axsl:number level="multiple" count="*"/><axsl:text>_</axsl:text><axsl:value-of select="string-length(local-name(.))"/><axsl:text>_</axsl:text><axsl:value-of select="translate(name(),':','.')"/></axsl:template><!--Strip characters--><axsl:template match="text()" priority="-1"/>

<!--SCHEMA METADATA-->
<axsl:template match="/">
** Begin checking PreTeXt Schematron rules      **
<axsl:apply-templates select="/" mode="M0"/><axsl:apply-templates select="/" mode="M1"/><axsl:apply-templates select="/" mode="M2"/><axsl:apply-templates select="/" mode="M3"/><axsl:apply-templates select="/" mode="M4"/><axsl:apply-templates select="/" mode="M5"/>** Finished checking PreTeXt Schematron rules   **

</axsl:template>

<!--SCHEMATRON PATTERNS-->


<!--PATTERN -->


	<!--RULE -->
<axsl:template match="@filebase" priority="1000" mode="M0">

		<!--REPORT -->
<axsl:if test="true()">Location:         <axsl:apply-templates select="." mode="schematron-get-full-path"/>
Condition:         true()
Explanation:       the @filebase attribute is deprecated (2014-05-04) and no code remains (2018-07-21), convert to using @xml:id for this purpose <axsl:text/>
            <axsl:text/><axsl:value-of select="'&#10;Enclosing Title:    &quot;'"/><axsl:text/>
            <axsl:text/><axsl:value-of select="ancestor::*[title][1]/title"/><axsl:text/>
            <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/> <axsl:text/>
                <axsl:text/><axsl:value-of select="'&#10;Enclosing xml:id: &quot;'"/><axsl:text/>
                <axsl:text/><axsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/><axsl:text/>
                <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/>
- - - - - - - - -
</axsl:if><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M0"/></axsl:template><axsl:template match="text()" priority="-1" mode="M0"/><axsl:template match="@*|node()" priority="-2" mode="M0"><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M0"/></axsl:template>

<!--PATTERN -->


	<!--RULE -->
<axsl:template match="cite" priority="1000" mode="M1">

		<!--REPORT -->
<axsl:if test="true()">Location:         <axsl:apply-templates select="." mode="schematron-get-full-path"/>
Condition:         true()
Explanation:       the &lt;cite&gt; element is deprecated (2014-06-25) and no code remains (2018-07-21), convert to an &lt;xref&gt; <axsl:text/>
            <axsl:text/><axsl:value-of select="'&#10;Enclosing Title:    &quot;'"/><axsl:text/>
            <axsl:text/><axsl:value-of select="ancestor::*[title][1]/title"/><axsl:text/>
            <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/> <axsl:text/>
                <axsl:text/><axsl:value-of select="'&#10;Enclosing xml:id: &quot;'"/><axsl:text/>
                <axsl:text/><axsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/><axsl:text/>
                <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/>
- - - - - - - - -
</axsl:if><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M1"/></axsl:template><axsl:template match="text()" priority="-1" mode="M1"/><axsl:template match="@*|node()" priority="-2" mode="M1"><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M1"/></axsl:template>

<!--PATTERN -->


	<!--RULE -->
<axsl:template match="circum" priority="1000" mode="M2">

		<!--REPORT -->
<axsl:if test="true()">Location:         <axsl:apply-templates select="." mode="schematron-get-full-path"/>
Condition:         true()
Explanation:       the &lt;circum&gt; element is deprecated (2015-01-28) and no code remains (2018-07-22), convert to a &lt;circumflex&gt; <axsl:text/>
            <axsl:text/><axsl:value-of select="'&#10;Enclosing Title:    &quot;'"/><axsl:text/>
            <axsl:text/><axsl:value-of select="ancestor::*[title][1]/title"/><axsl:text/>
            <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/> <axsl:text/>
                <axsl:text/><axsl:value-of select="'&#10;Enclosing xml:id: &quot;'"/><axsl:text/>
                <axsl:text/><axsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/><axsl:text/>
                <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/>
- - - - - - - - -
</axsl:if><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M2"/></axsl:template><axsl:template match="text()" priority="-1" mode="M2"/><axsl:template match="@*|node()" priority="-2" mode="M2"><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M2"/></axsl:template>

<!--PATTERN -->


	<!--RULE -->
<axsl:template match="var" priority="1000" mode="M3">

		<!--ASSERT -->
<axsl:choose><axsl:when test="ancestor::webwork"/><axsl:otherwise>Location:         <axsl:apply-templates select="." mode="schematron-get-full-path"/>
Requirement:      ancestor::webwork
Explanation:       the &lt;var&gt; element is exclusive to a WeBWorK problem, and so must only appear within a &lt;webwork&gt; element <axsl:text/>
            <axsl:text/><axsl:value-of select="'&#10;Enclosing Title:    &quot;'"/><axsl:text/>
            <axsl:text/><axsl:value-of select="ancestor::*[title][1]/title"/><axsl:text/>
            <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/> <axsl:text/>
                <axsl:text/><axsl:value-of select="'&#10;Enclosing xml:id: &quot;'"/><axsl:text/>
                <axsl:text/><axsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/><axsl:text/>
                <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/>
- - - - - - - - -
</axsl:otherwise></axsl:choose><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M3"/></axsl:template><axsl:template match="text()" priority="-1" mode="M3"/><axsl:template match="@*|node()" priority="-2" mode="M3"><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M3"/></axsl:template>

<!--PATTERN -->


	<!--RULE -->
<axsl:template match="author/xref" priority="1000" mode="M4">

		<!--ASSERT -->
<axsl:choose><axsl:when test="id(@ref)/self::contributor"/><axsl:otherwise>Location:         <axsl:apply-templates select="." mode="schematron-get-full-path"/>
Requirement:      id(@ref)/self::contributor
Explanation:       an &lt;xref&gt; within an &lt;author&gt; must point to a &lt;contributor&gt; <axsl:text/>
            <axsl:text/><axsl:value-of select="'&#10;Enclosing Title:    &quot;'"/><axsl:text/>
            <axsl:text/><axsl:value-of select="ancestor::*[title][1]/title"/><axsl:text/>
            <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/> <axsl:text/>
                <axsl:text/><axsl:value-of select="'&#10;Enclosing xml:id: &quot;'"/><axsl:text/>
                <axsl:text/><axsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/><axsl:text/>
                <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/>
- - - - - - - - -
</axsl:otherwise></axsl:choose><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M4"/></axsl:template><axsl:template match="text()" priority="-1" mode="M4"/><axsl:template match="@*|node()" priority="-2" mode="M4"><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M4"/></axsl:template>

<!--PATTERN -->


	<!--RULE -->
<axsl:template match="webwork//tabular" priority="1000" mode="M5">

		<!--REPORT -->
<axsl:if test="col/@top">Location:         <axsl:apply-templates select="." mode="schematron-get-full-path"/>
Condition:         col/@top
Explanation:       column-specific top border attributes are not implemented for the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine <axsl:text/>
            <axsl:text/><axsl:value-of select="'&#10;Enclosing Title:    &quot;'"/><axsl:text/>
            <axsl:text/><axsl:value-of select="ancestor::*[title][1]/title"/><axsl:text/>
            <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/> <axsl:text/>
                <axsl:text/><axsl:value-of select="'&#10;Enclosing xml:id: &quot;'"/><axsl:text/>
                <axsl:text/><axsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/><axsl:text/>
                <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/>
- - - - - - - - -
</axsl:if>

		<!--REPORT -->
<axsl:if test="cell/@bottom">Location:         <axsl:apply-templates select="." mode="schematron-get-full-path"/>
Condition:         cell/@bottom
Explanation:       cell-specific bottom border attributes are not implemented for the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine <axsl:text/>
            <axsl:text/><axsl:value-of select="'&#10;Enclosing Title:    &quot;'"/><axsl:text/>
            <axsl:text/><axsl:value-of select="ancestor::*[title][1]/title"/><axsl:text/>
            <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/> <axsl:text/>
                <axsl:text/><axsl:value-of select="'&#10;Enclosing xml:id: &quot;'"/><axsl:text/>
                <axsl:text/><axsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/><axsl:text/>
                <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/>
- - - - - - - - -
</axsl:if>

		<!--REPORT -->
<axsl:if test="//*[@top='major' or @bottom='major' or @left='major' or @right='major']">Location:         <axsl:apply-templates select="." mode="schematron-get-full-path"/>
Condition:         //*[@top='major' or @bottom='major' or @left='major' or @right='major']
Explanation:       'major' table rule attributes will be handled as 'minor' in the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine <axsl:text/>
            <axsl:text/><axsl:value-of select="'&#10;Enclosing Title:    &quot;'"/><axsl:text/>
            <axsl:text/><axsl:value-of select="ancestor::*[title][1]/title"/><axsl:text/>
            <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/> <axsl:text/>
                <axsl:text/><axsl:value-of select="'&#10;Enclosing xml:id: &quot;'"/><axsl:text/>
                <axsl:text/><axsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/><axsl:text/>
                <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/>
- - - - - - - - -
</axsl:if>

		<!--REPORT -->
<axsl:if test="//*[@top='medium' or @bottom='medium' or @left='medium' or @right='medium']">Location:         <axsl:apply-templates select="." mode="schematron-get-full-path"/>
Condition:         //*[@top='medium' or @bottom='medium' or @left='medium' or @right='medium']
Explanation:       'medium' table rule attributes will be handled as 'minor' in the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine <axsl:text/>
            <axsl:text/><axsl:value-of select="'&#10;Enclosing Title:    &quot;'"/><axsl:text/>
            <axsl:text/><axsl:value-of select="ancestor::*[title][1]/title"/><axsl:text/>
            <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/> <axsl:text/>
                <axsl:text/><axsl:value-of select="'&#10;Enclosing xml:id: &quot;'"/><axsl:text/>
                <axsl:text/><axsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/><axsl:text/>
                <axsl:text/><axsl:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/><axsl:text/>
        <axsl:text/>
- - - - - - - - -
</axsl:if><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M5"/></axsl:template><axsl:template match="text()" priority="-1" mode="M5"/><axsl:template match="@*|node()" priority="-2" mode="M5"><axsl:apply-templates select="@*|*|comment()|processing-instruction()" mode="M5"/></axsl:template></axsl:stylesheet>
