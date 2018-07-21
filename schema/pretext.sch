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
<s:schema xmlns:s="http://purl.oclc.org/dsdl/schematron">

    <!-- Removed from each "pattern":                                  -->
    <!-- xmlns:xsl="http://www.w3.org/1999/XSL/Transform"              -->
    <!-- xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" -->
    <!-- xmlns="http://relaxng.org/ns/structure/1.0"                   -->
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

    <!-- Removed from each diagnostic:                                 -->
    <!-- xmlns:xsl="http://www.w3.org/1999/XSL/Transform"              -->
    <!-- xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" -->
    <!-- xmlns="http://relaxng.org/ns/structure/1.0"                   -->
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
