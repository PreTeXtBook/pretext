<?xml version="1.0" standalone="yes"?>

<!--********************************************************************
Copyright 2018 Robert A. Beezer

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

<!-- This is a set of Schematron rules, to complement the RELAX-NG schema   -->
<!-- for PreTeXt.  It is the source file for an XSL transform which uses a  -->
<!-- stylesheet like Schematron's "iso_schematron_skeleton_for_xslt1.xsl",  -->
<!-- or an extension, to produce a new stylesheet that can be applied to    -->
<!-- PreTeXt source and emit messages.                                      -->
<!--                                                                        -->
<!-- This set of rules was originally generated in July 2018 from RNG       -->
<!-- annotations which were extracted with Schematron's                     -->
<!-- "ExtractSchFromRNG.xsl" utility.  It has been hand-edited from there.  -->
<!-- Notes indicate extensive namespace declarations which seem unnecessary -->
<!-- now, have been removed.  We have been unsuccessful in removing the     -->
<!-- Schematron namespace declaration, but we were able to edit the prefix  -->
<!-- from "sch:" to "s:'.                                                   -->
<!--                                                                        -->
<!-- This file is the input to a process which creates the                  -->
<!-- "pretext-schematron.xsl" file, which is updated regularly on every     -->
<!-- change to that pipeline.  So an author should never need to use this   -->
<!-- file directly, but it is included for use by developers.               -->


<!-- Removed from schema:                            -->
<!-- xmlns:rng="http://relaxng.org/ns/structure/1.0" -->
<!-- Removed from each "pattern":                                  -->
<!-- xmlns:xsl="http://www.w3.org/1999/XSL/Transform"              -->
<!-- xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" -->
<!-- xmlns="http://relaxng.org/ns/structure/1.0"                   -->
<!-- Removed from each diagnostic:                                 -->
<!-- xmlns:xsl="http://www.w3.org/1999/XSL/Transform"              -->
<!-- xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" -->
<!-- xmlns="http://relaxng.org/ns/structure/1.0"                   -->

<s:schema xmlns:s="http://purl.oclc.org/dsdl/schematron">

    <!-- Begin: Deprecations -->
    <!-- Comments are copied from original warnings in -common templates -->

    <!-- 2014-05-04  @filebase has been replaced in function by @xml:id -->
    <!-- 2018-07-21  remove all relevant code                           -->
    <s:pattern>
        <s:rule context="@filebase">
            <s:report test="true()" diagnostics="enclosing-title enclosing-id">the @filebase attribute is deprecated (2014-05-04) and no code remains (2018-07-21), convert to using @xml:id for this purpose</s:report>
        </s:rule>
    </s:pattern>

    <!-- 2014-06-25  xref once had cite as a variant -->
    <!-- 2018-07-21  remove all relevant code        -->
    <s:pattern>
        <s:rule context="cite">
            <s:report test="true()" diagnostics="enclosing-title enclosing-id">the &lt;cite&gt; element is deprecated (2014-06-25) and no code remains (2018-07-21), convert to an &lt;xref&gt;</s:report>
        </s:rule>
    </s:pattern>

    <!-- 2015-01-28  once both circum and circumflex existed, circumflex won -->
    <!-- 2018-07-21  remove all relevant code                                -->
    <s:pattern>
        <s:rule context="circum">
            <s:report test="true()" diagnostics="enclosing-title enclosing-id">the &lt;circum&gt; element is deprecated (2015-01-28) and no code remains (2018-07-22), convert to a &lt;circumflex&gt;</s:report>
        </s:rule>
    </s:pattern>

    <!-- End: Deprecations -->

    <s:pattern>
        <s:rule context="var">
            <s:assert test="ancestor::webwork" diagnostics="enclosing-title enclosing-id">the &lt;var&gt; element is exclusive to a WeBWorK problem, and so must only appear within a &lt;webwork&gt; element</s:assert>
        </s:rule>
    </s:pattern>

    <s:pattern>
        <s:rule context="author/xref">
            <s:assert test="id(@ref)/self::contributor" diagnostics="enclosing-title enclosing-id">an &lt;xref&gt; within an &lt;author&gt; must point to a &lt;contributor&gt;</s:assert>
        </s:rule>
    </s:pattern>

    <!-- WeBWorK cannot handle all the flexibility of a PreTeXt tabular -->
    <s:pattern>
        <s:rule context="webwork//tabular">
            <s:report test="col/@top" diagnostics="enclosing-title enclosing-id">column-specific top border attributes are not implemented for the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</s:report>
            <s:report test="cell/@bottom" diagnostics="enclosing-title enclosing-id">cell-specific bottom border attributes are not implemented for the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</s:report>
            <s:report test="//*[@top='major' or @bottom='major' or @left='major' or @right='major']" diagnostics="enclosing-title enclosing-id">'major' table rule attributes will be handled as 'minor' in the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</s:report>
            <s:report test="//*[@top='medium' or @bottom='medium' or @left='medium' or @right='medium']" diagnostics="enclosing-title enclosing-id">'medium' table rule attributes will be handled as 'minor' in the output of a WeBWorK PG table produced by WeBWorK's hardcopy production engine</s:report>
        </s:rule>
    </s:pattern>


    <s:diagnostics>
        <s:diagnostic id="enclosing-title" xml:space="default">
            <s:value-of select="'&#xa;Enclosing Title:    &quot;'"/>
            <s:value-of select="ancestor::*[title][1]/title"/>
            <s:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[title][1]), '&gt;)')"/>
        </s:diagnostic>

        <s:diagnostic id="enclosing-id" xml:space="default">
                <s:value-of select="'&#xa;Enclosing xml:id: &quot;'"/>
                <s:value-of select="ancestor::*[@xml:id][1]/@xml:id"/>
                <s:value-of select="concat('&quot; (on a &lt;', local-name(ancestor::*[@xml:id][1]), '&gt;)')"/>
        </s:diagnostic>
    </s:diagnostics>
</s:schema>
