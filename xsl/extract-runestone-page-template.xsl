<?xml version='1.0'?>

<!--********************************************************************
Copyright 2026 Robert A. Beezer

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

<!-- Empty shell page that Runestone can use to display content on a page -->
<!-- that looks like it belongs to the book.                              -->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- Import the HTML conversion for file wrapping and page-part templates,   -->
<!-- but override its entry point so this extraction only writes _base.html. -->
<xsl:import href="./pretext-html.xsl"/>

<!-- Override the variable open and close to use normal Jinga syntax      -->
<!-- This will be used as a template to insert other Jinga content into   -->
<!-- and that content uses normal variable delimeters.                    -->
<!-- We are not worried about LaTeX content we don't directly control.    -->
<xsl:variable name="rso" select="'{{'"/>
<xsl:variable name="rsc" select="'}}'"/>

<!-- Override latex-macros so we can escape them in bulk -->
<xsl:template match="*" mode="latex-macros">
    <xsl:text>{% raw %}&#xa;</xsl:text>
    <!-- Call the original template -->
    <xsl:apply-imports/>
    <xsl:text>{% endraw %}&#xa;</xsl:text>
</xsl:template>

<!-- Overrride navigation template to prevent next button from being enabled -->
<xsl:template match="*" mode="next-linear-url"/>

<!-- Override the HTML default so file-wrap emits Runestone template hooks -->
<xsl:template match="*" mode="file-wrap-head-pre">
    {% set using_ptx_base = "true" %}
    <base>
        <!-- avoid wonkiness with XSL {{ escaping. No spaces is important -->
        <xsl:attribute name="href">{{base_url}}</xsl:attribute>
    </base>
    <!-- Call the original template just in case something is added there -->
    <xsl:apply-imports/>
</xsl:template>

<!-- Override canonical link - don't want to generate the same value for  -->
<!-- all pages and don't need to SEO the internal student pages           -->
<xsl:template name="canonical-link"/>

<xsl:template match="*" mode="file-wrap-head-post">
    <!-- Call the original template just in case something is added there -->
    <xsl:apply-imports/>
    <link href="/staticAssets/main-ptx-based.css" rel="stylesheet" />
    <script>
        window.addEventListener("DOMContentLoaded", () => {
            const sidebar = document.getElementById("ptx-sidebar");
            if (sidebar) {
                sidebar.classList.add("hidden");
            }
        });
    </script>
    {% block css %}
    {% endblock %}
</xsl:template>

<xsl:template match="*" mode="file-wrap-body-attr-extra">
    <!-- Call the original template just in case something is added there -->
    <xsl:apply-imports/>
    <xsl:text> ptx-runestone-template</xsl:text>
</xsl:template>

<xsl:template match="*" mode="file-wrap-body-post">
    <!-- Call the original template just in case something is added there -->
    <xsl:apply-imports/>
    <!-- rs footer -->
    {% include 'footer.html' %}
    <!-- scripts -->
    <script>
        <!-- hide sidebar by default in all themes -->
        const sidebar = document.getElementById("ptx-sidebar");
        if (sidebar) {
            sidebar.classList.add("hidden");
        }
    </script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js" integrity="sha384-9/reFTGAW83EW2RDu2S0VKaIzap3H66lZH81PoYlFhbGU+6BZp6G7niu735Sk7lN" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.3/dist/js/bootstrap.min.js"></script>
    {% block js %}
    {% endblock %}
</xsl:template>


<xsl:output method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat" />

<xsl:template match="/">
    <xsl:call-template name="runestone-page-template"/>
</xsl:template>

<xsl:template name="runestone-page-template">
    <xsl:if test="$b-host-runestone and ($b-is-book or $b-is-article)">
        <xsl:apply-templates select="$document-root" mode="runestone-page-template"/>
    </xsl:if>
</xsl:template>

<xsl:template match="book|article" mode="runestone-page-template">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="filename">
            <xsl:text>_base.html</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="title">
            <xsl:text>{% block title %}</xsl:text>
            <xsl:apply-templates select="." mode="title-plain" />
            <xsl:text>{% endblock %}</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="b-include-bottom-nav" select="false()"/>
        <xsl:with-param name="content">
            {% block content %}
            {% endblock %}
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

</xsl:stylesheet>
