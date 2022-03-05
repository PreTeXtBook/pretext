<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2022 Robert A. Beezer

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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- exsl: necessary to write out Runestone manifest -->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<!-- Not documented, for development use only -->
<xsl:param name="runestone.dev" select="''"/>
<xsl:variable name="runestone-dev" select="$runestone.dev = 'yes'"/>

<!-- Not documented, for development use only -->
<xsl:param name="debug.rs.services.file" select="''"/>


<!-- ######################## -->
<!-- Runestone Infrastructure -->
<!-- ######################## -->

<!-- The Runestone platform option requires output that can be used  -->
<!-- on the server with a templating language/tool.  For books       -->
<!-- originating from PreTeXt we use a non-default pair of strings.  -->
<!-- This is because the default is {{, }} and these behave poorly   -->
<!-- in  a/@href  output, since the outer pair looks like an XSL AVT -->
<!-- and then the inner pair gets escaped as a reserved character in -->
<!-- a URI.  (We can turn off URI-escaping with XSLT 2.0, but the    -->
<!-- AVT confusion may still be a problem.)                          -->

<!-- These are used two places, so defined globally, not  -->
<!-- conditionally.  Due to their ubiquity in these two   -->
<!-- concentrated locations, the variable names are       -->
<!-- intentionally cryptic, contrary to usual practice.   -->
<!-- rs = Runestone, o = open, c = close.                 -->

<xsl:variable name="rso" select="'~._'"/>
<xsl:variable name="rsc" select="'_.~'"/>

<!-- Runestone Services (Javascript)  -->
<!-- OR, Hosting at Runestone Academy -->
<xsl:template name="runestone-header">
    <!-- Runestone templating for customizing hosted books   -->
    <!-- no Sphinx {% %} templating for build system at all, -->
    <!-- conditional on $b-host-runestone                    -->
    <!-- 'true'  - hosted on a Runestone server,             -->
    <!--           {{ }} templating replaced by $rso, $rsc   -->
    <!-- 'false' - local viewing, no server,                 -->
    <!--           just Runestone Services, so dummy values  -->
    <xsl:choose>
        <!-- Hosted on Runestone server -->
        <xsl:when test="$b-host-runestone">
            <script type="text/javascript">
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>eBookConfig = {};&#xa;</xsl:text>
                <xsl:text>eBookConfig.useRunestoneServices = true;&#xa;</xsl:text>
                <xsl:text>eBookConfig.host = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.app = eBookConfig.host + '/runestone';&#xa;</xsl:text>
                <xsl:text>eBookConfig.course = '</xsl:text><xsl:value-of select="$rso"/><xsl:text> course_name </xsl:text><xsl:value-of select="$rsc"/><xsl:text>';&#xa;</xsl:text>
                <xsl:text>eBookConfig.basecourse = '</xsl:text><xsl:value-of select="$rso"/><xsl:text> base_course </xsl:text><xsl:value-of select="$rsc"/><xsl:text>';&#xa;</xsl:text>
                <xsl:text>eBookConfig.isLoggedIn = </xsl:text><xsl:value-of select="$rso"/><xsl:text> is_logged_in </xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.email = '</xsl:text><xsl:value-of select="$rso"/><xsl:text> user_email </xsl:text><xsl:value-of select="$rsc"/><xsl:text>';&#xa;</xsl:text>
                <xsl:text>eBookConfig.isInstructor = </xsl:text><xsl:value-of select="$rso"/><xsl:text> is_instructor </xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.logLevel = 10;&#xa;</xsl:text>
                <xsl:text>eBookConfig.ajaxURL = eBookConfig.app + "/ajax/";&#xa;</xsl:text>
                <!-- no .loglevel -->
                <xsl:text>eBookConfig.username = '</xsl:text><xsl:value-of select="$rso"/><xsl:text> user_id </xsl:text><xsl:value-of select="$rsc"/><xsl:text>';&#xa;</xsl:text>
                <xsl:text>eBookConfig.readings = </xsl:text><xsl:value-of select="$rso"/><xsl:text> readings </xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.activities = </xsl:text><xsl:value-of select="$rso"/><xsl:text> activity_info|safe </xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.downloadsEnabled = </xsl:text><xsl:value-of select="$rso"/><xsl:text> downloads_enabled </xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.allow_pairs = </xsl:text><xsl:value-of select="$rso"/><xsl:text> allow_pairs </xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.enableScratchAC = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.new_server_prefix = "/ns";&#xa;</xsl:text>
                <!-- no .build_info -->
                <!-- no .python3 -->
                <!-- no .acDefaultLanguage -->
                <!-- no .runestone_version -->
                <!-- no .jobehost -->
                <!-- no .proxyuri_runs -->
                <!-- no .proxyuri_files -->
                <!-- no .enable_chatcodes -->
            </script>
            <xsl:text>&#xa;</xsl:text>

            <!-- Google Ads: only on Runestone server, only visible in -->
            <!-- *non-login* versions of books hosted at Runestone     -->
            <!--                                                       -->
            <!-- @data-ad-client attribute of upcoming script tag is   -->
            <!-- templated for Runestone serving.  We form it as a     -->
            <!-- variable, so that we can place it using an XSL AVT    -->
            <xsl:variable name="id-attr">
                <xsl:value-of select="$rso"/>
                <xsl:text> settings.adsenseid </xsl:text>
                <xsl:value-of select="$rsc"/>
            </xsl:variable>
            <!--  -->
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>{% if serve_ad and settings.adsenseid %}&#xa;</xsl:text>
            <script data-ad-client="{$id-attr}" async="" src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>{% endif %}&#xa;</xsl:text>

            <!-- When hosted, we embed YouTube videos in a slightly different -->
            <!-- manner, and with the next script it is possible to monitor   -->
            <!-- reader events associated with the use of the videos          -->
            <!-- NB: placed here just for initial testing w/ diffs, -->
            <!--     could move up above Google Ad section          -->
            <script type="text/javascript" src="https://www.youtube.com/player_api"></script>

            <!-- We only show the Runestone "bust" menu icon if we are building        -->
            <!-- for a Runestone server, so this CSS is only needed in that case.      -->
            <!-- Perhaps it should exist in Runestone's CSS or maybe in PreTeXt's CSS? -->
            <style>
                <xsl:text>.dropdown {&#xa;</xsl:text>
                <xsl:text>    position: relative;&#xa;</xsl:text>
                <xsl:text>    display: inline-block;&#xa;</xsl:text>
                <xsl:text>    height: 39px;&#xa;</xsl:text>
                <xsl:text>    width: 50px;&#xa;</xsl:text>
                <xsl:text>    margin-left: auto;&#xa;</xsl:text>
                <xsl:text>    margin-right: auto;&#xa;</xsl:text>
                <xsl:text>    padding: 7px;&#xa;</xsl:text>
                <xsl:text>    text-align: center;&#xa;</xsl:text>
                <xsl:text>    background-color: #eeeeee;&#xa;</xsl:text>
                <xsl:text>    border: 1px solid;&#xa;</xsl:text>
                <xsl:text>    border-color: #aaaaaa;&#xa;</xsl:text>
                <xsl:text> }&#xa;</xsl:text>
                <xsl:text> .dropdown-content {&#xa;</xsl:text>
                <xsl:text>    position: absolute;&#xa;</xsl:text>
                <xsl:text>    display: none;&#xa;</xsl:text>
                <xsl:text>    left: 300px;&#xa;</xsl:text>
                <xsl:text>    text-align: left;&#xa;</xsl:text>
                <xsl:text>    font-family: 'Open Sans', 'Helvetica Neue', 'Helvetica';&#xa;</xsl:text>
                <xsl:text>}&#xa;</xsl:text>
                <xsl:text>.dropdown:hover {&#xa;</xsl:text>
                <xsl:text>    background-color: #ddd;&#xa;</xsl:text>
                <xsl:text>}&#xa;</xsl:text>
                <xsl:text>.dropdown:hover .dropdown-content {&#xa;</xsl:text>
                <xsl:text>    display: block;&#xa;</xsl:text>
                <xsl:text>    position: fixed;&#xa;</xsl:text>
                <xsl:text>}&#xa;</xsl:text>
                <xsl:text>.dropdown-content {&#xa;</xsl:text>
                <xsl:text>    background-color: white;&#xa;</xsl:text>
                <xsl:text>    z-index: 1800;&#xa;</xsl:text>
                <xsl:text>    min-width: 100px;&#xa;</xsl:text>
                <xsl:text>    padding: 5px;&#xa;</xsl:text>
                <xsl:text>}&#xa;</xsl:text>
                <xsl:text>.dropdown-content a {&#xa;</xsl:text>
                <xsl:text>    display: block;&#xa;</xsl:text>
                <xsl:text>    text-decoration: none;&#xa;</xsl:text>
                <xsl:text>    color: #662211;&#xa;</xsl:text>
                <xsl:text>}&#xa;</xsl:text>
                <xsl:text>.dropdown-content a:hover {&#xa;</xsl:text>
                <xsl:text>    background-color: #671d12;&#xa;</xsl:text>
                <xsl:text>    color: #ffffff;&#xa;</xsl:text>
                <xsl:text>}&#xa;</xsl:text>
            </style>
        </xsl:when>
        <!-- Hosted without a Runestone Server, just using Javascript -->
        <!-- NB: condition on problems that benefit/need this?        -->
        <!-- 2022-01-12: not ready for prime-time, so must            -->
        <!-- flip $runestone-dev to turn this on                      -->
        <xsl:when test="not($b-host-runestone) and $runestone-dev">
            <xsl:comment>** eBookCongig is necessary to configure interactive       **</xsl:comment><xsl:text>&#xa;</xsl:text>
            <xsl:comment>** Runestone components to run locally in reader's browser **</xsl:comment><xsl:text>&#xa;</xsl:text>
            <xsl:comment>** No external communication:                              **</xsl:comment><xsl:text>&#xa;</xsl:text>
            <xsl:comment>**     log level is 0, Runestone Services are disabled     **</xsl:comment><xsl:text>&#xa;</xsl:text>
            <script type="text/javascript">
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>eBookConfig = {};&#xa;</xsl:text>
                <xsl:text>eBookConfig.useRunestoneServices = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.host = 'http://127.0.0.1:8000';&#xa;</xsl:text>
                <!-- no .app -->
                <xsl:text>eBookConfig.course = 'PTX Course: Title Here';&#xa;</xsl:text>
                <xsl:text>eBookConfig.basecourse = 'PTX Base Course';&#xa;</xsl:text>
                <xsl:text>eBookConfig.isLoggedIn = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.email = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.isInstructor = false;&#xa;</xsl:text>
                <!-- no .ajaxURL since no .app -->
                <xsl:text>eBookConfig.logLevel = 0;&#xa;</xsl:text>
                <xsl:text>eBookConfig.username = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.readings = null;&#xa;</xsl:text>
                <xsl:text>eBookConfig.activities = null;&#xa;</xsl:text>
                <xsl:text>eBookConfig.downloadsEnabled = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.allow_pairs = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.enableScratchAC = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.build_info = "";&#xa;</xsl:text>
                <xsl:text>eBookConfig.python3 = null;&#xa;</xsl:text>
                <xsl:text>eBookConfig.acDefaultLanguage = 'python';&#xa;</xsl:text>
                <xsl:text>eBookConfig.runestone_version = '5.0.1';&#xa;</xsl:text>
                <xsl:text>eBookConfig.jobehost = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.proxyuri_runs = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.proxyuri_files = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.enable_chatcodes =  false;&#xa;</xsl:text>
            </script>
            <xsl:text>&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- Runestone Services -->
    <!-- Runestone provides universally-applicable Javascript, and since Brad Miller -->
    <!-- is "such a nice guy" he provides an XML version of the necessary files,     -->
    <!-- which we store as "support/runestone-services.xml".  The structure of that  -->
    <!-- file is pretty simple, and should be apparent to the cognescenti.           -->
    <!-- NB: dev.runestoneinteractive.org  is temporary while testing -->
    <!-- NB: we may eventually condition on Runestone server/hosting  -->
    <!-- to affect the prefix network location.                       -->
    <!--  -->
    <!-- We allow for experimental services vis a "debug" parameter.  -->
    <!-- Note that any path must be relative to *this* file you are   -->
    <!-- viewing right now, i.e. relative to the "xsl" directory of   -->
    <!-- the PreteXt distribution.  An absolute path should always    -->
    <!-- be correct.                                                  -->
    <xsl:variable name="runestone-services-filename">
        <xsl:choose>
            <xsl:when test="not($debug.rs.services.file = '')">
                <xsl:value-of select="$debug.rs.services.file"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>support/runestone-services.xml</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="runestone-services" select="document($runestone-services-filename)"/>

    <!-- If hosted on Runestone then we point to "_static" directory right -->
    <!-- on the Runestone Server.  But in the "Runestone for All" case,    -->
    <!-- any build/hosting can hit the Runestone site for the necessary    -->
    <!-- Javascript/CSS to power interactive questions in much the same    -->
    <!-- manner as at Runestone Academy.                                   -->
    <xsl:variable name="runestone-cdn">
        <xsl:choose>
            <xsl:when test="$runestone-dev">
                <xsl:text>https://runestone.academy/cdn/runestone/</xsl:text>
                <xsl:value-of select="$runestone-services/all/version"/>
                <xsl:text>/</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>_static/</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:comment>*** Runestone Services ***</xsl:comment>
    <xsl:text>&#xa;</xsl:text>
    <xsl:for-each select="$runestone-services/all/js/item">
        <script type="text/javascript">
            <xsl:attribute name="src">
                <xsl:value-of select="$runestone-cdn"/>
                <xsl:value-of select="."/>
            </xsl:attribute>
        </script>
    </xsl:for-each>
    <xsl:for-each select="$runestone-services/all/css/item">
        <link rel="stylesheet" type="text/css">
            <xsl:attribute name="href">
                <xsl:value-of select="$runestone-cdn"/>
                <xsl:value-of select="."/>
            </xsl:attribute>
        </link>
    </xsl:for-each>
</xsl:template>

<!-- User Menu (aka Bust Menu)                    -->
<!-- Conditional on a build for Runestone hosting -->

<xsl:template name="runestone-bust-menu">
    <!-- "Bust w/ Silhoutte" is U+1F464, used as menu icon -->
    <xsl:if test="$b-host-runestone">
        <div class="dropdown">
            <xsl:text>&#x1F464;</xsl:text>
            <div class="dropdown-content">
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>{% if settings.academy_mode: %}&#xa;</xsl:text>
                <a href="/runestone/assignments/chooseAssignment">Assignments</a>
                <a href="/runestone/assignments/practice">Practice</a>
                <hr/>
                <a href="/runestone/default/courses">Change Course</a>
                <hr/>
                <a id="ip_dropdown_link" href="/runestone/admin/index">Instructor's Page</a>
                <hr/>
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>{% endif %}&#xa;</xsl:text>
                <a href="/runestone/dashboard/studentreport">Progress Page</a>
                <hr/>
                <a href="/runestone/default/user/profile">Edit Profile</a>
                <a href="/runestone/default/user/change_password">Change Password</a>
                <a href="/runestone/default/user/logout">Log Out</a>
                <a href="/runestone/default/user/register">Register</a>
                <a href="/runestone/default/user/login">Login</a>
                <a href="/runestone/assignments/index">Progress Page</a>
            </div>
        </div>
    </xsl:if>
</xsl:template>


<!-- ################## -->
<!-- Runestone Manifest -->
<!-- ################## -->

<!-- HTML ID and real title for each chapter and section -->
<!-- A PTX "section" is a Runestone "subchapter"         -->
<!-- Document hierarchy is preserved in XML structure    -->
<!-- TODO: add exercises as "question"                   -->

<!-- Conditional run-in -->
<xsl:template name="runestone-manifest">
    <xsl:if test="$b-host-runestone and ($b-is-book or $b-is-article)">
        <!-- $document-root *will* be a book -->
        <xsl:apply-templates select="$document-root" mode="runestone-manifest"/>
    </xsl:if>
</xsl:template>

<xsl:template match="book|article" mode="runestone-manifest">
    <exsl:document href="runestone-manifest.xml" method="xml" indent="yes" encoding="UTF-8">
        <manifest>
            <!-- LaTeX packages and macros first -->
            <latex-macros>
                <xsl:text>&#xa;</xsl:text>
                <xsl:value-of select="$latex-packages-mathjax"/>
                <xsl:value-of select="$latex-macros"/>
            </latex-macros>
            <xsl:choose>
                <xsl:when test="self::book">
                    <!-- Now recurse into chapters, appendix -->
                    <xsl:apply-templates select="*" mode="runestone-manifest"/>
                </xsl:when>
                <xsl:when test="self::article">
                    <!-- Now recurse into sections, appendix  -->
                    <!-- with a faux chapter, using "article" -->
                    <chapter>
                        <id>
                            <xsl:apply-templates select="." mode="html-id"/>
                        </id>
                        <title>
                            <xsl:apply-templates select="." mode="title-full"/>
                        </title>
                        <xsl:apply-templates select="*" mode="runestone-manifest"/>
                    </chapter>
                </xsl:when>
            </xsl:choose>
        </manifest>
    </exsl:document>
</xsl:template>

<xsl:template match="chapter" mode="runestone-manifest">
    <chapter>
        <id>
            <xsl:apply-templates select="." mode="html-id"/>
        </id>
        <title>
            <xsl:apply-templates select="." mode="title-full"/>
        </title>
    <!-- Recurse into PTX sections, or if the chapter is not structured, -->
    <!-- then pick up inline exercises directly within a chapter         -->
    <xsl:apply-templates select="*" mode="runestone-manifest"/>
    </chapter>
</xsl:template>

<!-- Every division at PTX "section" level, -->
<!-- potentially containing an "exercise",  -->
<!-- e.g. "worksheet" but not "references", -->
<!-- is a RS "subchapter"                   -->
<xsl:template match="section|chapter/exercises|chapter/worksheet|chapter/reading-questions" mode="runestone-manifest">
    <subchapter>
        <id>
            <xsl:apply-templates select="." mode="html-id"/>
        </id>
        <title>
            <xsl:apply-templates select="." mode="title-full"/>
        </title>
        <!-- nearly a dead end, recurse into "exercise" and PROJECT-LIKE at *any* PTX -->
        <!-- depth, for example within a "subsection" (which Runestone does not have) -->
        <xsl:apply-templates select=".//exercise|.//project|.//activity|.//exploration|.//investigation"  mode="runestone-manifest"/>
    </subchapter>
    <!-- dead end structurally, no more recursion, even if "subsection", etc. -->
</xsl:template>

<!-- A Runestone exercise needs to identify itself when an instructor wants   -->
<!-- to select it for assignment, so we want to provide enough identification -->
<!-- in the manifest, via a "label" element full of raw text.                 -->
<xsl:template match="exercise|project|activity|exploration|investigation" mode="runestone-manifest-label">
    <label>
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="number"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
    </label>
</xsl:template>

<!-- Exercises to the Runestone manifest -->
<!--   - every "exercise" in a "reading-questions" division -->
<!--   - every multiple choice "exercise"                   -->
<!--   - every "exercise" with an interactive "program"     -->
<!-- Note, 2020-05-29: multiple choice not yet merged, markup is speculative -->
<xsl:template match="exercise[parent::reading-questions]|exercise[choices]" mode="runestone-manifest">
    <question>
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <xsl:apply-templates select="." mode="exercise-components"/>
    </question>
</xsl:template>

<xsl:template match="exercise[webwork-reps]" mode="runestone-manifest">
    <question>
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <!-- N.B.  Better here to ask for "exercise-components"? -->
        <xsl:apply-templates select="introduction|webwork-reps|conclusion"/>
    </question>
</xsl:template>

<!-- Coding Exercise to the Runestone manifest -->
<!--   "exercise" with "program" *outside* of "statement" -->
<!--   &PROJECT-LIKE; only at top-level                   -->
<xsl:template match="exercise[program]|project[program]|activity[program]|exploration[program]|investigation[program]" mode="runestone-manifest">
    <xsl:variable name="active-language">
        <xsl:apply-templates select="program" mode="active-language"/>
    </xsl:variable>
    <!-- if elected as interactive AND @language is supported -->
    <xsl:if test="not($active-language = '')">
        <question>
            <!-- label is from the "exercise" -->
            <xsl:apply-templates select="." mode="runestone-manifest-label"/>
            <!-- need to set controls on what gets produced by "exercise-components"     -->
            <!-- TODO: this is a band-aid, why isn't it necessary for reading questions? -->
            <xsl:apply-templates select="." mode="exercise-components">
                <xsl:with-param name="b-has-statement" select="true()"/>
            </xsl:apply-templates>
        </question>
    </xsl:if>
</xsl:template>

<!-- Appendix is explicitly no-op, so we do not recurse into "section"  -->
<xsl:template match="appendix" mode="runestone-manifest"/>

<!-- Traverse the tree,looking for things to do          -->
<!-- http://stackoverflow.com/questions/3776333/         -->
<!-- stripping-all-elements-except-one-in-xml-using-xslt -->
<xsl:template match="*" mode="runestone-manifest">
    <xsl:apply-templates select="*" mode="runestone-manifest"/>
</xsl:template>

<!-- ########## -->
<!-- Components -->
<!-- ########## -->

<!-- YouTube Video -->
<!-- When hosted on a Runestone server, we use a different embedding  -->
<!-- for a YouTube video (only), which allows using a YouTube API for -->
<!-- monitoring events from readers.  We have to pass in an actual    -->
<!-- height and width (in pixels) for semi-custom attributes here.    -->
<!-- Many PreTeXt video features (like posters) are lost.             -->
<!-- TODO: are start/end attributes useful?      -->
<xsl:template match="video[@youtube]" mode="runestone-youtube-embed">
    <xsl:param name="width"/>
    <xsl:param name="height"/>

    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:variable>

    <div id="{$hid}" data-component="youtube" class="align-left youtube-video"
         data-video-height="{$height}" data-video-width="{$width}"
         data-video-videoid="{@youtube}" data-video-divid="{$hid}"
         data-video-start="0" data-video-end="-1"/>
</xsl:template>

</xsl:stylesheet>