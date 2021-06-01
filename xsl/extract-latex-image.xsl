<?xml version='1.0'?>

<!--********************************************************************
Copyright 2014-2016 Robert A. Beezer

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

<!-- This stylesheet locates <latex-image> elements    -->
<!-- and wraps them for LaTeX processing               -->
<!-- This includes the LaTeX macros present in docinfo -->
<!-- and the $latex-image-preamble from common.        -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="pi exsl"
>

<!-- Get internal ID's for filenames, etc -->
<xsl:import href="./pretext-common.xsl" />

<!-- We use some common code to make the actual LaTeX code used      -->
<!-- for the image.  The extract-identity stylesheet will override   -->
<!-- the entry template, so we just access some templates as needed. -->
<xsl:import href="./pretext-latex.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<!-- Output LaTeX as text -->
<xsl:output method="text" />

<!-- Stylesheet is parametrized by format for output           -->
<!--   latex:   for PDF to be cropped, manipulated, etc        -->
<!--   tactile: placeholder rectangle for braille cells, meant -->
<!--            to survive latex -> DVI, dvisvgm -> SVG        -->
<xsl:param name="format" select="''"/>
<xsl:variable name="outformat-entered">
    <xsl:choose>
        <xsl:when test="$format = 'latex'">
            <xsl:text>latex</xsl:text>
        </xsl:when>
        <xsl:when test="$format = 'tactile'">
            <xsl:text>tactile</xsl:text>
        </xsl:when>
        <!-- nothing, silently use default -->
        <xsl:when test="$format = ''">
            <xsl:text>latex</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: the "extract-latex-image.xsl" stylesheet expects the "format" string parameter to be "latex" or "tactile", not "<xsl:value-of select="$format"/>".  The default will be used instead.</xsl:message>
            <xsl:text>tactile</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- binary right now, so we can use a boolean -->
<xsl:variable name="b-tactile" select="$outformat-entered = 'tactile'"/>


<!-- Necessary to get braille'd labels, Grade 1 + Nemeth when labels    -->
<!-- are meant to hold braille.  An empty string for the filename seems -->
<!-- to silently execute/fail so this will not hold up use for the      -->
<!-- case of LaTeX labels.  We perform a check in the entry template.   -->
<xsl:param name="labelfile" select="''"/>
<xsl:variable name="braille-labels"  select="document($labelfile)/pi:braille-labels"/>

<!-- We refine the template for the document root so we get one    -->
<!-- overall check on the necessity of a file of braille'd labels. -->
<!-- And then resume extraction through the remainder              -->
<xsl:template match="/pretext/*[not(self::docinfo)]" mode="extraction">
    <xsl:choose>
        <xsl:when test="$b-tactile">
            <xsl:if test="$labelfile = ''">
                <xsl:message terminate='yes'>PTX:ERROR:   the "extract-latex-image.xsl" stylesheet with braille labels, needs a file of the same, via the "labelfile" string parameter and it appears you have not supplied such a file.  Quitting...</xsl:message>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <xsl:if test="not($labelfile = '')">
                <xsl:message>PTX:WARNING: the "extract-latex-image.xsl" stylesheet is ignoring your file of braille labels ("<xsl:value-of select="$labelfile"/>") since you did not elect a conversion with braille labels via the "format" string parameter.</xsl:message>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="@*|node()" mode="extraction"/>
</xsl:template>

<!-- NB: Code between lines of hashes is cut/paste    -->
<!-- from the LaTeX conversion.  Until we do a better -->
<!-- job of ensuring they remain in-sync, please      -->
<!-- coordinate the two sets of templates by hand     -->

<!-- ######################################### -->
<!-- Standard fontsizes: 10pt, 11pt, or 12pt       -->
<!-- extsizes package: 8pt, 9pt, 14pt, 17pt, 20pt  -->
<xsl:param name="latex.font.size" select="'12pt'" />
<!--  -->
<!-- Geometry: page shape, margins, etc            -->
<!-- Pass a string with any of geometry's options  -->
<!-- Default is empty and thus ineffective         -->
<!-- Otherwise, happens early in preamble template -->
<xsl:param name="latex.geometry" select="''"/>

<!-- font-size also dictates document class for -->
<!-- those provided by extsizes, but we can get -->
<!-- these by just inserting the "ext" prefix   -->
<!-- We don't load the package, the classes     -->
<!-- are incorporated in the documentclass[]{}  -->
<!-- and only if we need the extreme values     -->

<!-- Default is 10pt above, this stupid template     -->
<!-- provides an error message and also sets a value -->
<!-- we can condition on for the extsizes package.   -->
<!-- In predicted order, sort of, so fall out early  -->
<xsl:variable name="font-size">
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
            <xsl:message terminate="yes">MBX:ERROR   the latex.font.size parameter must be 8pt, 9pt, 10pt, 11pt, 12pt, 14pt, 17pt, or 20pt, not "<xsl:value-of select="$latex.font.size" />"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- A convenient shortcut/hack that might need expansion later   -->
<!-- insert "ext" or nothing in front of "regular" document class -->
<xsl:variable name="document-class-prefix">
    <xsl:choose>
        <xsl:when test="$font-size='10pt'"></xsl:when>
        <xsl:when test="$font-size='12pt'"></xsl:when>
        <xsl:when test="$font-size='11pt'"></xsl:when>
        <xsl:otherwise>
            <xsl:text>ext</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!-- ######################################### -->


<!-- LaTeX graphics to a standalone file for subsequent processing.     -->
<!-- Intercept "extraction" process in extract-identity.xsl stylesheet. -->
<xsl:template match="image[latex-image]" mode="extraction">
    <xsl:variable name="filebase">
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <!-- Do not use directories here, as Windows paths will get mangled -->
    <!-- Instead, set working directory before applying stylesheet      -->
    <exsl:document href="{$filebase}.tex" method="text">
        <xsl:text>\documentclass[</xsl:text>
        <xsl:value-of select="$font-size" />
        <!-- braille version goes to  dvisvgm  next -->
        <xsl:if test="$b-tactile">
            <xsl:text>,dvisvgm</xsl:text>
        </xsl:if>
        <xsl:text>]{</xsl:text>
        <xsl:value-of select="$document-class-prefix" />
        <xsl:text>article}&#xa;</xsl:text>
        <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
        <xsl:choose>
            <!-- maybe adjust this based on discovery of environments? -->
            <xsl:when test="not($b-tactile)">
                <!-- ######################################### -->
                <!-- Determine height of text block, assumes US letterpaper (11in height) -->
                <!-- Could react to document type, paper, margin specs                    -->
                <xsl:variable name="text-height">
                    <xsl:text>9.0in</xsl:text>
                </xsl:variable>
                <!-- Bringhurst: 30x => 66 chars, so 34x => 75 chars -->
                <xsl:variable name="text-width">
                    <xsl:value-of select="34 * substring-before($font-size, 'pt')" />
                    <xsl:text>pt</xsl:text>
                </xsl:variable>
                <!-- (These are actual TeX comments in the main document's LaTeX output) -->
                <!-- Text height identically 9 inches, text width varies on point size   -->
                <!-- See Bringhurst 2.1.1 on measure for recommendations                 -->
                <!-- 75 characters per line (count spaces, punctuation) is target        -->
                <!-- which is the upper limit of Bringhurst's recommendations            -->
                <xsl:text>\geometry{letterpaper,total={</xsl:text>
                <xsl:value-of select="$text-width" />
                <xsl:text>,</xsl:text>
                <xsl:value-of select="$text-height" />
                <xsl:text>}}&#xa;</xsl:text>
                <xsl:text>%% Custom Page Layout Adjustments (use latex.geometry)&#xa;</xsl:text>
                <xsl:if test="$latex.geometry != ''">
                    <xsl:text>\geometry{</xsl:text>
                    <xsl:value-of select="$latex.geometry" />
                    <xsl:text>}&#xa;</xsl:text>
                </xsl:if>
                <!-- ######################################### -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>%% Dimensions of an embossed braille page&#xa;</xsl:text>
                <xsl:text>\newlength{\braillepagewidth}&#xa;</xsl:text>
                <xsl:text>\setlength{\braillepagewidth}{11.5in}&#xa;</xsl:text>
                <xsl:text>\newlength{\braillepageheight}&#xa;</xsl:text>
                <xsl:text>\setlength{\braillepageheight}{11in}&#xa;</xsl:text>
                <xsl:text>%% Dimensions of the area for scaled-up image&#xa;</xsl:text>
                <xsl:text>\newlength{\brailleareawidth}&#xa;</xsl:text>
                <xsl:text>\setlength{\brailleareawidth}{10in}&#xa;</xsl:text>
                <xsl:text>\newlength{\brailleareaheight}&#xa;</xsl:text>
                <xsl:text>\setlength{\brailleareaheight}{10in}&#xa;</xsl:text>
                <!-- page dimensions, no matter what for an embossed tactile image -->
                <xsl:text>%% 10in x 10in body, 1/2 inch gutter, 1/2 inch margins, some room for overfull&#xa;</xsl:text>
                <xsl:text>\geometry{paperwidth=\braillepagewidth, paperheight=\braillepageheight, </xsl:text>
                <xsl:text>left=1in, right=0.4in, top=0.5in, bottom=0.4in</xsl:text>
                <xsl:text>}&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>\usepackage{amsmath,amssymb}&#xa;</xsl:text>
        <xsl:value-of select="$latex-image-preamble"/>
        <xsl:text>\ifdefined\tikzset&#xa;</xsl:text>
        <xsl:text>\tikzset{ampersand replacement = \amp}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>
        <xsl:value-of select="$latex-macros" />
        <xsl:text>\begin{document}&#xa;</xsl:text>
        <xsl:text>\pagestyle{empty}&#xa;</xsl:text>
        <!-- The "latex-image" template is in  pretext-latex.xsl      -->
        <!-- We save off the code for discovery and possible          -->
        <!-- manipulation for scaling and spacing as tactile graphics -->
        <xsl:variable name="the-latex-image">
            <xsl:apply-templates select="latex-image"/>
        </xsl:variable>
        <!-- Analyze the type of image we have, and save markers as universal  -->
        <!-- variables.  An empty result will signal a "latex-image" we cannot -->
        <!-- yet modify predictably                                            -->
        <xsl:variable name="env-begin">
            <xsl:choose>
                <xsl:when test="contains($the-latex-image, '\begin{tikzpicture}')">
                    <xsl:text>\begin{tikzpicture}</xsl:text>
                </xsl:when>
                <xsl:when test="contains($the-latex-image, '\begin{circuittikz}')">
                    <xsl:text>\begin{circuittikz}</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="env-end">
            <xsl:choose>
                <xsl:when test="$env-begin = '\begin{tikzpicture}'">
                    <xsl:text>\end{tikzpicture}</xsl:text>
                </xsl:when>
                <xsl:when test="$env-begin = '\begin{circuittikz}'">
                    <xsl:text>\end{circuittikz}</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- If tactile versions requested, and we support the   -->
            <!-- type of latex-image, based on environment discovery -->
            <xsl:when test="$b-tactile and not($env-begin = '')">
                <!-- make a "sighted" version in a box to measure -->
                <xsl:text>%% Sighted version measured in a box&#xa;</xsl:text>
                <xsl:text>%% Scale factor lands in more global \tikzscale&#xa;</xsl:text>
                <xsl:text>\makeatletter&#xa;</xsl:text>
                <xsl:text>\newsavebox{\measure@tikzpicture}&#xa;</xsl:text>
                <xsl:text>\begin{lrbox}{\measure@tikzpicture}%&#xa;</xsl:text>
                <!-- We scale the offset of a label for a magnified version -->
                <!-- by the \tikzscale factor, so we just set it to 1 for   -->
                <!-- right now in the masurement of the original.  Inside   -->
                <!-- the lrbox environment maybe it is local as well.       -->
                <xsl:text>\def\tikzscale{1}&#xa;</xsl:text>
                <xsl:value-of select="$the-latex-image"/>
                <xsl:text>\end{lrbox}%&#xa;</xsl:text>
                <!-- https://tex.stackexchange.com/questions/18771/store-pgfmathresult-in-a-variable -->
                <!-- else: \pgfmathparse{...}, then \edef\tikzscale{\pgfmathresult} -->
                <!-- reducing scaling for page-fitting experiments works well here  -->
                <xsl:text>\pgfmathsetmacro\tikzscale{min(\brailleareawidth/\wd\measure@tikzpicture,\brailleareaheight/\ht\measure@tikzpicture)}%&#xa;</xsl:text>
                <!-- <xsl:text>\edef\tikzscale{\pgfmathresult}&#xa;</xsl:text> -->
                <xsl:text>\makeatother&#xa;</xsl:text>
                <!-- <xsl:text>FOO\quad \pgfmathresult\\% Render the picture with new scaling factor&#xa;</xsl:text> -->
                <!-- <xsl:text>BAR \verb!</xsl:text> -->
                <!-- <xsl:text>!\\</xsl:text> -->
                <!-- Decompose the code based on begin/end environment markers so -->
                <!-- adjustments can be reliably added and the code reconstructed -->
                <xsl:variable name="pre-environment" select="substring-before($the-latex-image, $env-begin)"/>
                <xsl:variable name="post-environment" select="substring-after($the-latex-image, $env-begin)"/>
                <xsl:variable name="options" select="substring-before($post-environment, '&#xa;')"/>
                <xsl:variable name="post-options" select="substring-after($post-environment, '&#xa;')"/>
                <xsl:variable name="body" select="substring-before($post-options, $env-end)"/>
                <xsl:variable name="finish" select="substring-after($post-options, $env-end)"/>
                <!-- Put the code back together with some additions  -->
                <!-- just after the start and just before the end    -->
                <!-- vertical spacing is ad-hoc, noindent seems prudent -->
                <xsl:text>%% Tactile version for production, with scaling and spacing adjustments&#xa;</xsl:text>
                <xsl:value-of select="concat($pre-environment, '\vspace*{\stretch{1}}\noindent{}', $env-begin, $options)"/>
                <xsl:text>&#xa;\tikzset{scale=\tikzscale}&#xa;</xsl:text>
                <!-- debugging, messes up some images -->
                <!-- <xsl:text>\node at (0.5,0.5) {FOO x \tikzscale x };&#xa;</xsl:text> -->
                <xsl:value-of select="$body"/>
                <!-- add calculation of bounding box additions -->
                <xsl:value-of select="$env-end"/>
                <xsl:value-of select="$finish"/>
                <xsl:text>\vspace*{\stretch{1}}</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- A latex-image we do not know how to manipulate, or  -->
                <!-- do not want to manipulate.  So leave unadulterated, -->
                <!-- anything goes, and process normally (i.e. not a     -->
                <!-- tactile version).                                   -->
                <xsl:value-of select="$the-latex-image"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>\end{document}&#xa;</xsl:text>
    </exsl:document>
</xsl:template>

<!-- We override the standard production of visual labels, but simply   -->
<!-- "apply-imports" for that case.  When a consumer of this stylesheet -->
<!-- (a script) specifies output for use with braille we will create a  -->
<!-- sequence of braille-cell sized rectangles to make space for BRF    -->
<!-- that will be printed/embossed as braille cells.                    -->
<xsl:template match="label">
    <xsl:choose>
        <xsl:when test="$b-tactile">
            <xsl:apply-templates select="." mode="braille-spacing"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-imports/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="label" mode="braille-spacing">
    <!-- All in mm -->
    <!-- experimental from 6-cell label, spec might be 6.1mm -->
    <!-- experimentally observed 6.35mm exactly equals 18pt   -->
    <xsl:variable name="cell-width" select="number(6.35)"/>
    <!-- 6.5mm bounding height, plus 0.3125mm gap * 2 -->
    <xsl:variable name="cell-height" select="number(7.125)"/>
    <xsl:variable name="id">
         <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <xsl:variable name="label" select="$braille-labels/pi:braille-label[@id = $id]"/>
    <xsl:variable name="label-count" select="string-length($label)"/>
    <xsl:variable name="label-width" select="$label-count * $cell-width"/>
    <xsl:text>\node [</xsl:text>
    <!-- convert PreTeXt compass directions to TikZ anchor -->
    <!-- shorthand (template resides in pretext-latex.xsl) -->
    <!-- along with a scaled offset from the coordinate    -->
    <xsl:apply-templates select="@direction" mode="tikz-direction"/>
    <xsl:text> = \tikzscale * </xsl:text>
    <!-- Always an offset, default is 4pt, about a "normal space" -->
    <xsl:apply-templates select="." mode="get-label-offset"/>
    <xsl:text>, inner sep=4mm, fill=white</xsl:text>
    <xsl:text>] at (</xsl:text>
    <!-- scale offsets via a macro, = 1 normally, measured otherwise -->
    <!-- .09cm = .9mm radius * 2.54 scale factor -->
    <!-- <xsl:text>=2.285mm, inner sep=4mm, fill=white] at (</xsl:text> -->
    <!-- a shift can prefix this coordinate, augmenting, -->
    <!-- or replacing, the direction/anchor option prior -->
    <xsl:value-of select="@location"/>
    <xsl:text>) {</xsl:text>
    <xsl:text>\special{dvisvgm:raw &lt;g class="PTX-rectangle"</xsl:text>
    <xsl:text> id="</xsl:text>
    <xsl:value-of select="$id"/>
    <xsl:text>"</xsl:text>
    <!-- we record direction, as data-* attribute -->
    <xsl:text> data-direction="</xsl:text>
    <xsl:value-of select="@direction"/>
    <xsl:text>"</xsl:text>
    <!-- we record label cell count, as data-* attribute -->
    <xsl:text> data-ncells="</xsl:text>
    <xsl:value-of select="$label-count"/>
    <xsl:text>"</xsl:text>
    <xsl:text>&gt;}</xsl:text>
    <xsl:text>\rule{</xsl:text>
    <xsl:value-of select="$label-width"/>
    <xsl:text>mm</xsl:text>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="$cell-height"/>
    <xsl:text>mm</xsl:text>
    <xsl:text>}</xsl:text>
    <xsl:text>\special{dvisvgm:raw &lt;/g&gt;}</xsl:text>
    <xsl:text>};&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
