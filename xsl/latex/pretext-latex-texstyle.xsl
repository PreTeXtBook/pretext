<?xml version='1.0'?>

<!--********************************************************************
Copyright 2025 Oscar Levin

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

<!-- Conveniences for classes of similar elements -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:pf="https://prefigure.org"
    extension-element-prefixes="exsl date str"
>

<!-- Build off of latex-classic, overriding as needed. -->
<xsl:import href="../pretext-latex-classic.xsl" />



<!--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%-->
<!-- Import of correct texstyle files -->
<!--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%-->


<!-- stringparam that pretext.py will override with the texstyle file name -->
<!-- (including "dependents/" if appropriate and ".xml")                   -->
<xsl:param name="journal.texstyle.file" select="''"/>

<!-- Base texstyle folder -->
<xsl:variable name="texstyle-file-path" select="'../../journals/texstyles/'"/>


<!-- Read in the original texstyle file -->
<xsl:variable name="orig-texstyle-root" select="document(concat($texstyle-file-path, $journal.texstyle.file))"/>

<!-- We create a texstyle-root element which is either the root of the     -->
<!-- original texstyle file, or is the root of a texstyle file that the    -->
<!-- original texstyle file extends.  This is done similar to how assembly -->
<!-- works.                                                                -->
<xsl:variable name="texstyle-root-rtf">
    <xsl:apply-templates select="$orig-texstyle-root" mode="include-base" />
</xsl:variable>
<xsl:variable name="texstyle-root" select="exsl:node-set($texstyle-root-rtf)"/>

<!-- Entry point to the include-base modal templates.  Looks for the /texstyle/medatadata/extends -->
<!-- element.  If it's there, gets the file it extends (assumed to be in the parent directory of  -->
<!-- the original texstyle file) and dives into that base file to copy everything there unless    -->
<!-- there is a version of that element in the extending/original texstyle file.                  -->
<xsl:template match="texstyle" mode="include-base">
    <xsl:choose>
        <xsl:when test="metadata/extends">
            <xsl:variable name="base-texstyle-file-name" select="metadata/extends"/>
            <xsl:variable name="base-texstyle-root" select="document(concat($texstyle-file-path, $base-texstyle-file-name, '.xml'))"/>
            <xsl:copy>
                <xsl:apply-templates select="$base-texstyle-root/texstyle/*" mode="include-base"/>
            </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
            <!-- If not extending, then we just take a copy of the original texstyle file -->
            <xsl:copy-of select="."/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Modal template that tests each node of base to see if it is in the  -->
<!-- original texstyle file, in which case it copies the node from the   -->
<!-- original, or else copies the node from the base texstyle file.      -->
<!-- Note that we only look at children of the texstyle element.         -->
<xsl:template match="node()|@*" mode="include-base">
    <xsl:variable name="base-node-name" select="string(name())"/>
    <xsl:variable name="orig-node-name" select="$orig-texstyle-root/texstyle/*[name()=$base-node-name]"/>
    <xsl:choose>
        <xsl:when test="$orig-node-name">
            <xsl:copy-of select="$orig-node-name"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy-of select="."/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- end of texstyle file import logic -->


<!--%%%%%%%%%%%%%%%%%%%%%%%%-->
<!-- Main "entry" templates -->
<!--%%%%%%%%%%%%%%%%%%%%%%%%-->

<!-- The main template that will be controlled by the texstyle file -->
<xsl:template match="article">
    <!-- Some boiler plate at the top of the file -->
    <xsl:call-template name="converter-blurb-latex"/>
    <xsl:call-template name="snapshot-package-info"/>
    <!-- Now hand over control of the document order to the texstyle file -->
    <xsl:apply-templates select="$texstyle-root/texstyle"/>
    <!-- Each of the elements of the texstyle file will have its own template below -->
    <!-- So that's it! -->
</xsl:template>


<!-- Catch-all for elements not yet implemented, to be overridden below -->
<xsl:template match="texstyle/*">
    <xsl:message>PTX:WARNING: Unhandled texstyle element: <xsl:value-of select="name()"/></xsl:message>
</xsl:template>


<!-- Sort of an entry template, which get's called as part of -->
<!-- the match on the pretext source's article.               -->
<xsl:template match="texstyle">
    <xsl:apply-templates select="*"/>
</xsl:template>


<!--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%-->
<!-- texstyle templates               -->
<!--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%-->

<!-- Include comments describing the texstyle file used -->
<xsl:template match="texstyle/metadata">
    <xsl:text>% This document was created with the texstyle file "</xsl:text>
    <xsl:apply-templates select="code"/>
    <xsl:text>.xml" to satisfy the requirements of the journal "</xsl:text>
    <xsl:apply-templates select="name"/>
    <xsl:text>."&#xa;%&#xa;%&#xa;</xsl:text>
</xsl:template>


<!-- - - - - - - - - -->
<!-- Preamble stuff  -->
<!-- - - - - - - - - -->

<!-- For the document class -->
<!-- TODO: respond to options with correct options -->
<xsl:template match="texstyle/documentclass">
    <xsl:text>\documentclass{</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>}&#xa;%&#xa;</xsl:text>
</xsl:template>

<!-- Sometimes journals require specific packages -->
<xsl:template match="texstyle/packages">
<xsl:text>% Required packages:&#xa;</xsl:text>
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
</xsl:template>


<!-- Here we build the "standard" (classic) latex preamble,       -->
<!-- with some minor modifications suggested by the texstyle file -->
<xsl:template match="texstyle/ptx-preamble">
    <xsl:call-template name="frontmatter-helpers"/>
    <xsl:call-template name="preamble-early"/>
    <xsl:call-template name="cleardoublepage"/>
    <xsl:call-template name="standard-packages"/>
    <xsl:choose>
        <xsl:when test="theoremstyle">
            <xsl:apply-templates select="theoremstyle"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- The latex-theorem-environments template from -classic:  -->
            <xsl:call-template name="latex-theorem-environments"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:call-template name="tcolorbox-init"/>
    <xsl:call-template name="numberless-environments"/>
    <xsl:call-template name="page-setup"/>
    <xsl:call-template name="latex-engine-support"/>
    <xsl:call-template name="font-support"/>
    <xsl:call-template name="math-packages"/>
    <xsl:call-template name="pdfpages-package"/>
    <xsl:call-template name="semantic-macros"/>
    <xsl:call-template name="exercises-and-solutions"/>
    <xsl:call-template name="chapter-start-number"/>
    <xsl:call-template name="equation-numbering"/>
    <xsl:call-template name="image-tcolorbox"/>
    <xsl:call-template name="tables"/>
    <xsl:call-template name="font-awesome"/>
    <xsl:call-template name="poetry-support"/>
    <xsl:call-template name="music-support"/>
    <xsl:call-template name="code-support"/>
    <xsl:call-template name="list-layout"/>
    <xsl:call-template name="load-configure-hyperref"/>
    <xsl:call-template name="create-numbered-tcolorbox"/>
    <xsl:call-template name="watermark"/>
    <xsl:call-template name="showkeys"/>
    <xsl:call-template name="latex-image-support"/>
    <xsl:call-template name="sidebyside-environment"/>
    <xsl:call-template name="kbd-keys"/>
    <xsl:call-template name="late-preamble-adjustments"/>
</xsl:template>

<!-- A list of all the elements that could need \newtheorem environments -->
<xsl:variable name="numbered-theorem-envs" select="
        ($document-root//lemma)[1]|
        ($document-root//proposition)[1]|
        ($document-root//corollary)[1]|
        ($document-root//claim)[1]|
        ($document-root//fact)[1]|
        ($document-root//identity)[1]|
        ($document-root//conjecture)[1]|
        ($document-root//definition)[1]|
        ($document-root//axiom)[1]|
        ($document-root//principle)[1]|
        ($document-root//heuristic)[1]|
        ($document-root//hypothesis)[1]|
        ($document-root//assumption)[1]|
        ($document-root//openproblem)[1]|
        ($document-root//openquestion)[1]|
        ($document-root//algorithm)[1]|
        ($document-root//question)[1]|
        ($document-root//activity)[1]|
        ($document-root//exercise)[1]|
        ($document-root//inlineexercise)[1]|
        ($document-root//investigation)[1]|
        ($document-root//exploration)[1]|
        ($document-root//problem)[1]|
        ($document-root//example)[1]|
        ($document-root//project)[1]|
        ($document-root//convention)[1]|
        ($document-root//warning)[1]|
        ($document-root//remark)[1]|
        ($document-root//insight)[1]|
        ($document-root//note)[1]|
        ($document-root//observation)[1]|
        ($document-root//computation)[1]|
        ($document-root//technology)[1]|
        ($document-root//data)[1]
"/>

<!-- Determine which \newtheorem environments to create based on what is in the texstyle file -->
<xsl:template match="theoremstyle">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\theoremstyle{</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>}%&#xa;</xsl:text>
    <!-- In just the first theoremstyle, we use "theorem" as the     -->
    <!-- default theorem for purposes of defining a counter.         -->
    <!-- Note that "theorem" is not among the $numbered-theorem-envs -->
    <xsl:if test="not(preceding-sibling::theoremstyle)">
        <xsl:text>\newtheorem{theorem}{</xsl:text>
        <xsl:apply-templates select="($document-root//theorem)[1]" mode="type-name"/>
        <xsl:text>}[section]&#xa;</xsl:text>
    </xsl:if>
    <!-- Read in all the names of theorems in the @environments attribute -->
    <xsl:variable name="thm-envs" select="str:tokenize(@environments, ', ')"/>
    <!-- Apply the modal newtheorem template to each environment if it belongs in this group -->
    <xsl:for-each select="$thm-envs">
        <xsl:variable name="env">
            <xsl:value-of select="."/>
        </xsl:variable>
        <xsl:for-each select="$numbered-theorem-envs">
            <xsl:if test="name() = $env">
                <xsl:apply-templates select="." mode="newtheorem"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:for-each>
</xsl:template>

<!-- End preamble stuff -->



<!-- - - - - - - - - - - - - - - - -->
<!-- Frontmatter and bibinfo stuff -->
<!-- - - - - - - - - - - - - - - - -->

<!-- Note: for the rest of the template commands, we will use a couple      -->
<!-- utility templates, located at the end of this file, to consistently    -->
<!-- wrap the pretext content in environments, command options and          -->
<!-- arguments, or below headings. Each of the following templates will     -->
<!-- pass the appropriate pretext node as needed to these utility templates.-->

<!-- Some journals wrap some of the bibinfo in a `frontmatter` environment -->
<!-- NB only environment supported as of 2025-03-23 -->
<xsl:template match="texstyle/frontmatter">
    <xsl:apply-templates select="." mode="env-cmd-header-wrap"/>
</xsl:template>

<!-- A title texstyle element.  Currently assumes @cmd structured with opt and arg -->
<xsl:template match="texstyle//title">
    <xsl:apply-templates select="." mode="env-cmd-header-wrap">
        <xsl:with-param name="ptx-node" select="$document-root"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="texstyle//title//ptx-short-title">
    <xsl:apply-templates select="$document-root" mode="title-short"/>
</xsl:template>

<xsl:template match="texstyle//title//ptx-title">
    <xsl:apply-templates select="$document-root" mode="title-full"/>
    <xsl:if test="$document-root/subtitle">
        <xsl:text>\\&#xa;</xsl:text>
        <!-- Trying to match author fontsize -->
        <xsl:text>{\small </xsl:text>
        <xsl:apply-templates select="$document-root" mode="subtitle"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Article-level support statement.  Assumes @cmd as of 2025-03-23 -->
<!-- NB careful that this does not conflict with author-level support. -->
<!-- That is, don't allow <support> in author, use <ptx-support> always. -->
<xsl:template match="texstyle//support">
    <xsl:if test="$bibinfo/support">
        <xsl:apply-templates select="." mode="env-cmd-header-wrap">
            <xsl:with-param name="ptx-node" select="$bibinfo"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<xsl:template match="ptx-bibinfo-support">
    <xsl:apply-templates select="$bibinfo/support"/>
</xsl:template>

<xsl:template match="texstyle//date">
    <xsl:if test="$bibinfo/date">
        <xsl:apply-templates select="." mode="env-cmd-header-wrap">
            <xsl:with-param name="ptx-node" select="$bibinfo"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>


<!-- Author listings -->

<!-- We provide two basic frameworks for listing authors.                                   -->
<!-- 1. Each author is listed with its own command, possibly tied to an affiliation with    -->
<!--    some sort of reference or number.  The texstyle file wraps all author information   -->
<!--    in an <author-list> environment.                                                    -->
<!-- 2. All authors are listed inside a single command, separated by \and or similar.       -->
<!--    In the texstyle, this is indicated by having a top-level <author> element which     -->
<!--    encloses an <author-list>.                                                          -->


<!-- An author-list means we should cycle through the list of authors. -->
<!-- So we apply templates for $bibinfo/author, but pass the context -->
<!-- of the texstyle node, so we can keep looking around there. -->
<!-- NB this works for either framework, either as a direct child of texstyle -->
<!-- or as a child of author -->
<xsl:template match="texstyle//author-list">
    <xsl:apply-templates select="$bibinfo/author" mode="author-list">
        <xsl:with-param name="ts-node" select="."/>
    </xsl:apply-templates>
</xsl:template>

<!-- Here our context is on the author node of the ptx source, but we want to -->
<!-- now apply each template of the texstyle author-list node in the order of -->
<!-- the textstyle file.  So we apply templates, and pass the context of the  -->
<!-- author node from pretext source.                                         -->
<xsl:template match="*" mode="author-list">
    <xsl:param name="ts-node"/>
    <xsl:apply-templates select="$ts-node/*">
        <xsl:with-param name="ptx-node" select="."/>
    </xsl:apply-templates>
    <!-- If we are separating authors, add the separator between each group of texstyle nodes -->
    <xsl:if test="following-sibling::author and $ts-node/@sep">
        <xsl:value-of select="$ts-node/@sep"/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Context: texstyle nodes, Param: ptx-source node (for the author)-->
<xsl:template match="texstyle//author-list/author">
    <xsl:param name="ptx-node"/>
    <xsl:apply-templates select="." mode="env-cmd-header-wrap">
        <xsl:with-param name="ptx-node" select="$ptx-node"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="texstyle//author-list/affiliation">
    <xsl:param name="ptx-node"/>
    <xsl:if test="$ptx-node/affiliation">
        <xsl:apply-templates select="." mode="env-cmd-header-wrap">
            <xsl:with-param name="ptx-node" select="$ptx-node"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>


<xsl:template match="texstyle//author-list/support">
    <xsl:param name="ptx-node"/>
    <xsl:if test="$ptx-node/support">
        <xsl:apply-templates select="." mode="env-cmd-header-wrap">
            <xsl:with-param name="ptx-node" select="$ptx-node"/>
            <xsl:with-param name="after" select="@after"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<xsl:template match="texstyle//author-list/email">
    <xsl:param name="ptx-node"/>
    <xsl:if test="$ptx-node/email">
        <xsl:apply-templates select="." mode="env-cmd-header-wrap">
            <xsl:with-param name="ptx-node" select="$ptx-node"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- We do the same thing for affiliation-list -->
<xsl:template match="texstyle//affiliation-list">
    <xsl:apply-templates select="$bibinfo/author" mode="affiliation-list">
        <xsl:with-param name="ts-node" select="."/>
    </xsl:apply-templates>
</xsl:template>

<!-- Context: ptx-source (likely an author element) -->
<!-- NB this is currently assuming only one structure of the ts-node.            -->
<!-- In particular, we do not pass back to the ts-node as we did for author-list -->
<!-- TODO: should this just be author-list in the ts file? -->
<xsl:template match="*" mode="affiliation-list">
    <xsl:param name="ts-node"/>
    <xsl:if test="$ts-node/affiliation">
        <xsl:text>\</xsl:text>
        <xsl:value-of select="$ts-node/affiliation/@cmd"/>
        <xsl:if test="$ts-node/affiliation/opt">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="$ts-node/affiliation/opt/*">
                <xsl:with-param name="ptx-node" select="."/>
            </xsl:apply-templates>
            <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:text>{</xsl:text>
        <!-- This could be the contents of the <arg> element, but hardcoded for now. -->
        <xsl:apply-templates select="affiliation"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- The next two templates are a little strange: it gives a way to -->
<!-- get the number of "ptx-source node", when called from a different  -->
<!-- node.  NB we use mode="texstyle-number" to avoid a conflict    -->
<!-- with the default number modal template.                        -->
<xsl:template match="affiliation-ordinal">
    <xsl:param name="ptx-node"/>
    <xsl:apply-templates select="$ptx-node" mode="texstyle-number"/>
</xsl:template>

<xsl:template match="*" mode="texstyle-number">
    <xsl:number/>
</xsl:template>

<!-- Some journals put footnote commands with their contents elsewhere, linked by an id -->
<xsl:template match="fnmark">
    <xsl:param name="ptx-node"/>
    <xsl:text>\</xsl:text>
    <xsl:value-of select="@cmd"/>
    <xsl:text>{</xsl:text>
    <xsl:choose>
        <xsl:when test="@arg = 'unique-id'">
            <xsl:value-of select="$ptx-node/@unique-id"/>
        </xsl:when>
        <xsl:when test="@arg = 'ordinal'">
            <xsl:apply-templates select="$ptx-node" mode="texstyle-number"/>
        </xsl:when>
        <!-- Todo: add other options here -->
    </xsl:choose>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="fntext">
    <xsl:param name="ptx-node"/>
    <xsl:text>\</xsl:text>
    <xsl:value-of select="@cmd"/>
    <xsl:if test="@opt">
        <xsl:text>[</xsl:text>
        <xsl:choose>
            <xsl:when test="@opt = 'unique-id'">
                <xsl:value-of select="$ptx-node/@unique-id"/>
            </xsl:when>
            <xsl:when test="@arg = 'ordinal'">
                <xsl:apply-templates select="$ptx-node" mode="texstyle-number"/>
            </xsl:when>
        </xsl:choose>
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:if test="@arg">
        <xsl:text>{</xsl:text>
        <xsl:choose>
            <xsl:when test="@arg = 'unique-id'">
                <xsl:value-of select="$ptx-node/@unique-id"/>
            </xsl:when>
            <xsl:when test="@arg = 'ordinal'">
                <xsl:apply-templates select="$ptx-node" mode="texstyle-number"/>
            </xsl:when>
        </xsl:choose>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="*">
        <xsl:with-param name="ptx-node" select="$ptx-node"/>
    </xsl:apply-templates>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Now for the second option for listing authors.        -->
<!-- We only need the top level template here; everything  -->
<!-- else will be handled by the general author-list above -->
<!-- NB we can't use texstyle//author because that conflicts with texstyle//authorlist/author -->
<xsl:template match="texstyle/author|/texstyle/frontmatter/author">
    <xsl:apply-templates select="." mode="env-cmd-header-wrap">
        <xsl:with-param name="ptx-node" select="$bibinfo"/>
    </xsl:apply-templates>
</xsl:template>


<xsl:template match="ptx-support">
    <xsl:param name="ptx-node"/>
    <xsl:apply-templates select="$ptx-node/support"/>
</xsl:template>

<xsl:template match="ptx-personname">
    <xsl:param name="ptx-node"/>
    <xsl:apply-templates select="$ptx-node/personname"/>
</xsl:template>

<xsl:template match="ptx-affiliation">
    <xsl:param name="ptx-node"/>
    <!-- Variable for sep param; use value of attribute or '\\&#xa;' for default. -->
    <xsl:variable name="sep">
        <xsl:choose>
            <xsl:when test="@sep">
                <xsl:value-of select="@sep"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="$ptx-node/affiliation">
        <xsl:with-param name="sep" select="$sep"/>
        <xsl:with-param name="after" select="@after"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="ptx-email">
    <xsl:param name="ptx-node"/>
    <xsl:apply-templates select="$ptx-node/email" mode="article-info"/>
</xsl:template>

<xsl:template match="ptx-date">
    <xsl:param name="ptx-node"/>
    <xsl:apply-templates select="$ptx-node/date"/>
</xsl:template>

<!-- End of author information -->



<!-- Abstract, keywords, etc. -->

<xsl:template match="texstyle//abstract">
    <xsl:if test="$document-root/frontmatter/abstract">
        <xsl:apply-templates select="." mode="env-cmd-header-wrap" />
    </xsl:if>
</xsl:template>


<xsl:template match="texstyle//keywords[keywords]">
    <xsl:apply-templates select="." mode="env-cmd-header-wrap"/>
</xsl:template>


<!-- First we select which source keyword element to use for a particular texstyle -->
<!-- keyword element by matching up their "authority" (with authority="author" the -->
<!-- default for source). In either case, we jump to a modal template with context -->
<!-- on the source node, passing the texstyle node as a param.                     -->
<!-- NB we can group keywords inside a parent keywords element, but that's not what we want here. -->
<xsl:template match="texstyle//keywords[not(keywords)]">
    <xsl:choose>
        <xsl:when test="@authority = 'author'">
            <xsl:apply-templates select="$bibinfo/keywords[@authority='author' or not(@authority)]" mode="keywords">
                <xsl:with-param name="ts-node" select="."/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="@authority = 'msc'">
            <xsl:apply-templates select="$bibinfo/keywords[@authority='msc']" mode="keywords">
                <xsl:with-param name="ts-node" select="."/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: The @authority attribute on a keyword element (in a texstyle file) is required and must be "author" or "msc".  Found "@authority="<xsl:value-of select="@authority"/>". </xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Here we insert the correct text for a keywords element based on the ts-node param -->
<xsl:template match="*" mode="keywords">
    <xsl:param name="ts-node"/>
    <xsl:choose>
        <!-- Case when keywords are in the argument of a command: -->
        <xsl:when test="$ts-node/@cmd">
            <xsl:text>\</xsl:text>
            <xsl:value-of select="$ts-node/@cmd"/>
            <xsl:if test="$ts-node/@variant-style='opt'">
                <xsl:text>[</xsl:text>
                <xsl:apply-templates select="@variant"/>
                <xsl:text>]</xsl:text>
            </xsl:if>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="keyword">
                <xsl:with-param name="sep" select="$ts-node/@sep"/>
            </xsl:apply-templates>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <!-- Case when keywords have a boldface heading -->
        <xsl:when test="$ts-node/@style='bf-heading'">
            <xsl:if test="$ts-node/@before">
                <xsl:value-of select="$ts-node/@before"/>
                <xsl:text>&#xa;</xsl:text>
            </xsl:if>
            <xsl:text>\noindent\textbf{</xsl:text>
            <xsl:choose>
                <xsl:when test="$ts-node/@authority='author'">
                    <xsl:text>Keywords</xsl:text>
                </xsl:when>
                <xsl:when test="$ts-node/@authority='msc'">
                    <xsl:if test="$ts-node/@variant-style='before'">
                        <xsl:value-of select="@variant"/>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:text>Math Subject Classification</xsl:text>
                </xsl:when>
            </xsl:choose>
            <xsl:text>}. </xsl:text>
            <xsl:apply-templates select="keyword">
                <xsl:with-param name="sep" select="$ts-node/@sep"/>
            </xsl:apply-templates>
            <xsl:text>&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="keyword">
                <xsl:with-param name="sep" select="$ts-node/@sep"/>
            </xsl:apply-templates>
            <xsl:text>&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template match="ptx-abstract">
    <xsl:apply-templates select="$document-root/frontmatter/abstract/*"/>
</xsl:template>

<xsl:template match="texstyle/maketitle">
    <xsl:text>\maketitle&#xa;</xsl:text>
</xsl:template>
<!-- End frontmatter stuff -->



<!-- Mainmatter -->
<xsl:template match="texstyle/mainmatter">
    <xsl:apply-templates select="$document-root/*[not(self::backmatter|self::references)]"/>
</xsl:template>


<!-- Backmatter -->
<xsl:template match="texstyle/backmatter">
    <xsl:apply-templates select="." mode="env-cmd-header-wrap" />
</xsl:template>

<!-- Todo: fix these -->
<xsl:template match="texstyle/supplement">
    <xsl:message>PTX:WARNING: Supplements are not yet available in PreTeXt so this feature is not available currently.</xsl:message>
    <xsl:if test="$document-root//supplement">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>% Supplement sections&#xa;</xsl:text>
        <xsl:value-of select="@heading"/>
        <xsl:text>%&#xa;%&#xa;</xsl:text>
        <xsl:apply-templates select="$document-root//supplement"/>
    </xsl:if>
</xsl:template>
<xsl:template match="texstyle/acknowledgments">
    <xsl:if test="$document-root//acknowledgement">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>% acknowledgement section&#xa;</xsl:text>
        <xsl:value-of select="@heading"/>
        <xsl:text>%&#xa;%&#xa;</xsl:text>
        <xsl:apply-templates select="$document-root//acknowledgement"/>
    </xsl:if>
</xsl:template>
<xsl:template match="texstyle/declarations">
    <xsl:message>PTX:WARNING: Declarations are not yet available in PreTeXt so this feature is not available currently.</xsl:message>
    <xsl:if test="$document-root//declaration">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>% Declarations sections&#xa;</xsl:text>
        <xsl:value-of select="@heading"/>
        <xsl:text>%&#xa;%&#xa;</xsl:text>
        <xsl:apply-templates select="$document-root//declaration"/>
    </xsl:if>
</xsl:template>


<xsl:template match="texstyle/appendices">
    <xsl:if test="$document-root//appendix">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>% Appendices&#xa;</xsl:text>
        <xsl:if test="@env">
            <xsl:text>\begin{</xsl:text>
            <xsl:value-of select="@env"/>
            <xsl:text>}</xsl:text>
            <xsl:text>%&#xa;%&#xa;</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="$document-root//appendix"/>
        <xsl:if test="@env">
            <xsl:text>\end{</xsl:text>
            <xsl:value-of select="@env"/>
            <xsl:text>}%&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>


<xsl:template match="texstyle/bibliography">
    <xsl:message>PTX:WARNING: Bibliographies are not implemented correctly yet.</xsl:message>
    <xsl:apply-templates select="$document-root/references"/>
</xsl:template>


<!-- Begin/End document -->
<xsl:template match="texstyle/begin-document">
    <xsl:text>%&#xa;%&#xa;</xsl:text>
    <xsl:text>%*********************************%&#xa;</xsl:text>
    <xsl:text>%*      Begin Main Document      *%&#xa;</xsl:text>
    <xsl:text>%*********************************%&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="texstyle/end-document">
    <xsl:text>%&#xa;\end{document}&#xa;</xsl:text>
</xsl:template>


<!-- LaTeX spacing commands -->

<xsl:template match="medskip">
    <xsl:text>\par\medskip&#xa;</xsl:text>
</xsl:template>

<!-- For cases when the texstyle file should include raw text -->
<xsl:template match="text">
    <xsl:value-of select="."/>
</xsl:template>


<!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  -->
<!-- Utility templates for wrapping pretext content in environments, -->
<!-- command options and arguments, or below headings.               -->
<!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  -->


<!-- First we have a template that will put in the \begin{env}...\end{env}, -->
<!-- or \cmd or heading depending on what the current ts-node has as an     -->
<!-- attribute.  We might pass a ptx-node depending on the originating      -->
<!-- template as well.                                                      -->
<!-- The `after` param is for templates that need to put a linebreak or     -->
<!-- or similar text after the end of the command.                          -->
<xsl:template match="*" mode="env-cmd-header-wrap">
    <xsl:param name="ptx-node"/>
    <xsl:param name="after"/>
    <xsl:choose>
        <xsl:when test="@env">
            <xsl:text>\begin{</xsl:text>
            <xsl:value-of select="@env"/>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:apply-templates select="*">
                <xsl:with-param name="ptx-node" select="$ptx-node"/>
            </xsl:apply-templates>
            <xsl:text>\end{</xsl:text>
            <xsl:value-of select="@env"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@cmd">
            <xsl:text>\</xsl:text>
            <xsl:value-of select="@cmd"/>
            <xsl:apply-templates select="*">
                <xsl:with-param name="ptx-node" select="$ptx-node"/>
            </xsl:apply-templates>
            <xsl:value-of select="$after"/>
            <xsl:text>&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@heading">
            <xsl:value-of select="@heading"/>
            <xsl:apply-templates select="*">
                <xsl:with-param name="ptx-node" select="$ptx-node"/>
            </xsl:apply-templates>
            <xsl:text>&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Wrappers for opts and args -->
<!-- These are applied inside commands.  Context is a ts-node -->
<!-- we always pass the ptx-node parent of any element we will apply using a ptx-element -->
<xsl:template match="opt">
    <xsl:param name="ptx-node"/>
    <xsl:text>[</xsl:text>
        <xsl:apply-templates select="*">
            <xsl:with-param name="ptx-node" select="$ptx-node"/>
        </xsl:apply-templates>
    <xsl:text>]</xsl:text>
</xsl:template>

<xsl:template match="arg">
    <xsl:param name="ptx-node"/>
    <xsl:text>{</xsl:text>
        <xsl:apply-templates select="*">
            <xsl:with-param name="ptx-node" select="$ptx-node"/>
        </xsl:apply-templates>
    <xsl:text>}</xsl:text>
</xsl:template>


</xsl:stylesheet>
