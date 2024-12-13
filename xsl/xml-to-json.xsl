<?xml version="1.0"?>

<!--********************************************************************
Copyright 2023 Jason Siefken

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

<!--
    A basic recreation of the XSLT3.0 xml-to-json conversion.
    Valid JSON nodes are: <map>, <array>, <number>, <string>, <boolean>, <null>.
    Each node may have an optional @key (but only if the node is a child of <map>.
    Nodes must be in the namespace http://www.w3.org/2005/xpath-functions

    See https://www.w3.org/TR/xslt-30/#json-to-xml-mapping for some examples.

    In addition to the usual JSON elements, a <raw> tag has been added. Contents of the <raw> tag
    are passed directly through and printed (though leading indentation is still applied).

    Example:
    ```
    <map xmlns="http://www.w3.org/2005/xpath-functions">
        <number key="Sunday">
            1
        </number>
        <boolean key="Wednesday">
            true
        </boolean>
        <boolean key="Wednesday">
        </boolean>
        <null key="Monday" />
        <array key="content">
            <map>
                <number key="id">
                    70805774
                </number>
                <string key="value">1  0\"01"fo\o &gt;&#xa;bar</string>
                <array key="position">
                    <number>
                        1004.0
                    </number>
                    <number>
                        288.0
                    </number>
                    <number>
                        1050.0
                    </number>
                    <number>
                        324.0
                    </number>
                </array>
            </map>
        </array>
    </map>
    ```
    will produce in the document
    ```
    {
       "Sunday": 1,
       "Wednesday": true,
       "Wednesday": false,
       "Monday": null,
       "content": [
          {
             "id": 70805774,
             "value": "1  0\\\"01\"fo\\o >\nbar",
             "position": [
                1004.0,
                288.0,
                1050.0,
                324.0
             ]
          }
       ]
    }
    ```

    For debuggining, it can be helpful to have xsltproc run whenever this file changes. If you
    are on linux and have inotifywait installed, you can run
    `while inotifywait -e close_write xml-to-json.xsl; do xsltproc xml-to-json.xsl sample-data.xml;
done`
    where `sample-data.xml` is the JSON data you're converting.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:exsl="http://exslt.org/common"
>
    <xsl:output method="text" encoding="utf-8" />
    <xsl:preserve-space elements="fn:string" />


    <!-- This is the main template that should be called to output
         JSON from the structured XML content. -->
    <xsl:template name="json">
        <xsl:param name="content" />
        <xsl:param name="indentDepth" select="0" />
        <xsl:variable name="output">
            <xsl:apply-templates select="exsl:node-set($content)/*" />
        </xsl:variable>
        <xsl:variable name="indentation">
            <xsl:call-template name="indent">
                <xsl:with-param name="depth" select="$indentDepth" />
            </xsl:call-template></xsl:variable>
        <xsl:call-template name="printIndented">
            <xsl:with-param name="indent" select="$indentation" />
            <xsl:with-param name="text" select="$output" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="fn:raw">
        <xsl:apply-templates select="@key" mode="attr" />
        <xsl:value-of select="." />
    </xsl:template>

    <xsl:template match="fn:null">
        <xsl:apply-templates select="@key" mode="attr" />
        <xsl:text>null</xsl:text>
    </xsl:template>

    <xsl:template match="fn:boolean">
        <xsl:apply-templates select="@key" mode="attr" />
        <xsl:choose>
            <xsl:when test="normalize-space(text()) = 'false'">
                <xsl:text>false</xsl:text>
            </xsl:when>
            <xsl:when test="normalize-space(text()) = '0'">
                <xsl:text>false</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>true</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="fn:number">
        <xsl:apply-templates select="@key" mode="attr" />
        <xsl:value-of select="normalize-space(text())" />
    </xsl:template>

    <xsl:template match="fn:string">
        <xsl:apply-templates select="@key" mode="attr" />
        <xsl:text>"</xsl:text>
        <xsl:call-template name="escape-for-json" />
        <xsl:text>"</xsl:text>
    </xsl:template>

    <xsl:template match="fn:array">
        <xsl:variable name="depth" select="count(ancestor::*)" />
        <xsl:apply-templates
            select="@key"
            mode="attr" />
        <xsl:text>[&#xa;</xsl:text>
        <xsl:for-each select="./*">
            <xsl:call-template name="indent">
                <xsl:with-param name="depth" select="$depth+1"></xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="." />
            <xsl:if test="not(position() = last())">
                <xsl:text>,&#xa;</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="indent">
            <xsl:with-param name="depth" select="$depth"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>]</xsl:text>
    </xsl:template>

    <xsl:template match="fn:map">
        <xsl:variable name="depth" select="count(ancestor::*)" />
        <xsl:apply-templates select="@key" mode="attr" />
        <xsl:text>{&#xa;</xsl:text>
        <xsl:for-each select="./*">
            <xsl:call-template name="indent">
                <xsl:with-param name="depth" select="$depth+1"></xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="." />
            <xsl:if test="not(position() = last())">
                <xsl:text>,&#xa;</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>&#xa;</xsl:text>
        <xsl:call-template name="indent">
            <xsl:with-param name="depth" select="$depth"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>}</xsl:text>
    </xsl:template>


    <!-- Wrap any @key in quotes. No special care is taken to escape the key name,
         so make it sensible right from the get-go! -->
    <xsl:template match="@key" mode="attr">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>": </xsl:text>
    </xsl:template>

    <!-- 2 paces of indentation for each $depth -->
    <xsl:template name="indent">
        <xsl:param name="depth" select="'0'" />

        <xsl:call-template name="duplicate-string">
             <xsl:with-param name="text" select="'  '"/>
             <xsl:with-param name="count" select="$depth" />
        </xsl:call-template>
    </xsl:template>

    <!-- Escape strings for JSON. This process first escapes backslashes,
         then escapes quotes (") and finally escapes newlines. Other characters
         should be valid JSON -->
    <xsl:template name="escape-for-json">
        <xsl:param name="pText" select="." />
        <xsl:variable name="escaped1">
            <xsl:call-template name="escapeBackslash">
                <xsl:with-param name="pText" select="$pText" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="escaped2">
            <xsl:call-template name="escapeQuotes">
                <xsl:with-param name="pText" select="$escaped1" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="escaped3">
            <xsl:call-template name="escapeNewlines">
                <xsl:with-param name="pText" select="$escaped2" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="$escaped3" />
    </xsl:template>

    <xsl:template name="escapeBackslash">
        <xsl:param name="pText" select="." />
        <xsl:variable name="head" select="substring-before($pText, '\')" />
        <xsl:variable name="tail" select="substring-after($pText, '\')" />
        <xsl:choose>
            <xsl:when test="$head or $tail">
                <xsl:value-of select="$head" />
                <xsl:text>\\</xsl:text>
                <xsl:call-template name="escapeBackslash">
                    <xsl:with-param name="pText" select="$tail" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$pText" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="escapeQuotes">
        <xsl:param name="pText" select="." />
        <xsl:variable name="head" select="substring-before($pText, '&quot;')" />
        <xsl:variable name="tail" select="substring-after($pText, '&quot;')" />
        <xsl:choose>
            <xsl:when test="$head or $tail">
                <xsl:value-of select="$head" />
                <xsl:text>\"</xsl:text>
                <xsl:call-template name="escapeQuotes">
                    <xsl:with-param name="pText" select="$tail" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$pText" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="escapeNewlines">
        <xsl:param name="pText" select="." />
        <xsl:variable name="head" select="substring-before($pText, '&#xa;')" />
        <xsl:variable name="tail" select="substring-after($pText, '&#xa;')" />
        <xsl:choose>
            <xsl:when test="$head or $tail">
                <xsl:value-of select="$head" />
                <xsl:text>\n</xsl:text>
                <xsl:call-template name="escapeNewlines">
                    <xsl:with-param name="pText" select="$tail" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$pText" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- This function is from Stack Overflow
    https://stackoverflow.com/questions/24513266/indent-multi-line-blocks-of-xsltext
    CC-BY-SA license -->
    <xsl:template name="printIndented">
        <xsl:param name="text" />
        <xsl:param name="indent" />

        <xsl:if test="$text">
            <xsl:value-of select="$indent" />
            <xsl:variable name="thisLine" select="substring-before($text, '&#10;')" />
            <xsl:choose>
                <xsl:when test="$thisLine"><!-- $text contains at least one newline -->
                    <!-- print this line -->
                    <xsl:value-of select="concat($thisLine, '&#10;')" />
                    <!-- and recurse to process the rest -->
                    <xsl:call-template name="printIndented">
                        <xsl:with-param name="text" select="substring-after($text, '&#10;')" />
                        <xsl:with-param name="indent" select="$indent" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$text" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
