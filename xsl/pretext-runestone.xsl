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
<xsl:param name="debug.rs.services.file" select="''"/>


<!-- ######################## -->
<!-- Runestone Infrastructure -->
<!-- ######################## -->

<!-- While under development, or maybe forever, do not load  -->
<!-- Runestone Javascript unless it is necessary.  Various   -->
<!-- values of @exercise-interactive are added in the        -->
<!-- pre-processing phase.  program/@interactive takes on    -->
<!-- values of 'activecode' and 'codelens'.  So a small      -->
<!-- amount of imprecision here, but should not be critical. -->
<xsl:variable name="b-needs-runestone" select="boolean($document-root//exercise[@exercise-interactive]|$document-root//program[@interactive])"/>

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
        <!-- Runestone Server build -->
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
                <xsl:text>eBookConfig.readings = </xsl:text><xsl:value-of select="$rso"/><xsl:text> readings|safe </xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
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
        <!-- Runestone for All build -->
        <!-- Hosted without a Runestone Server, just using Javascript -->
        <!-- NB: condition on problems that benefit/need this?        -->
        <xsl:when test="not($b-host-runestone) and $b-needs-runestone">
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

    <!-- If hosted on Runestone then we point to "_static" directory right -->
    <!-- on the Runestone Server.  But in the "Runestone for All" case,    -->
    <!-- any build/hosting can hit the Runestone site for the necessary    -->
    <!-- Javascript/CSS to power interactive questions in much the same    -->
    <!-- manner as at Runestone Academy.                                   -->
    <xsl:variable name="runestone-cdn">
        <xsl:choose>
            <xsl:when test="$b-host-runestone">
                <xsl:text>_static/</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- CDN URL should end in a slash, -->
                <!-- as version has no slashes      -->
                <xsl:value-of select="$runestone-services/all/cdn-url"/>
                <xsl:value-of select="$runestone-services/all/version"/>
                <xsl:text>/</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- When building for a Runestone server or when testing -->
    <!-- Runestone for All, the $runestone-cdn will point to  -->
    <!-- the right place for the necessary JS.                -->
    <!-- N.B. Enclosing "if" goes away if/when $b-needs-runestone    -->
    <!-- just becomes true all the time.  Indentation predicts this. -->
    <xsl:if test="$b-host-runestone or $b-needs-runestone">
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
    </xsl:if>
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

<!-- A convenience for attaching a Runestone id -->
<xsl:template match="exercise|program|&PROJECT-LIKE;" mode="runestone-id-attribute">
    <xsl:attribute name="id">
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:attribute>
</xsl:template>

<!-- ############### -->
<!-- Runestone Hooks -->
<!-- ############### -->

<!-- Various additions/modifications to the HTML output, but which  -->
<!-- we isolate here in this stylesheet for organizational reasons. -->

<!-- A textual and visual progress indicator of completed activities  -->
<!-- for a book hosted on a RS server, only.  At the RS "subchapter"  -->
<!-- level, which we shortcut by checking for a chapter-level parent. -->
<xsl:template match="&STRUCTURAL;" mode="runestone-progress-indicator">
    <xsl:if test="$b-host-runestone and (parent::chapter or parent::appendix)">
        <div id="scprogresscontainer">You have attempted <span id="scprogresstotal"/> of <span id="scprogressposs"/> activities on this page.<div id="subchapterprogress" aria-label="Page progress"/></div>
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
            <!-- version of Runestone Services used for this build -->
            <runestone-services>
                <xsl:attribute name="version">
                    <xsl:value-of select="$runestone-services/all/version"/>
                </xsl:attribute>
            </runestone-services>
            <!-- mine various bits and pieces of the source for RS metadata  -->
            <!-- collection, which is technically a "conf.py" file, per-book -->
            <library-metadata publisher="pretext">
                <!-- sanitizes footnotes, quotes, math for overall title-->
                <xsl:comment>Missing a blurb for library description, book back covers</xsl:comment>
                <title>
                    <xsl:apply-templates select="$document-root" mode="title-plain"/>
                </title>
                <subtitle>
                    <xsl:apply-templates select="$document-root" mode="subtitle"/>
                </subtitle>
                <!-- edition, too? -->
                <document-id>
                    <xsl:attribute name="edition">
                        <xsl:value-of select="$docinfo/document-id/@edition"/>
                    </xsl:attribute>
                    <xsl:value-of select="$docinfo/document-id"/>
                </document-id>
            </library-metadata>
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
<!--   - every True/False "exercise"                  -->
<!--   - every multiple choice "exercise"             -->
<!--   - every Parsons problem "exercise"             -->
<!--   - every matching problem "exercise"            -->
<!--   - every clickable area problem "exercise"      -->
<!--   - every "exercise" with fill-in blanks         -->
<!--   - every "exercise" with additional "program"   -->
<!--   - every "exercise" elected as "shortanswer"    -->
<!--   - every PROJECT-LIKE with additional "program" -->
<xsl:template match="exercise[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                              |project[@exercise-interactive = 'coding']
                              |activity[@exercise-interactive = 'coding']
                              |exploration[@exercise-interactive = 'coding']
                              |investigation[@exercise-interactive = 'coding']" mode="runestone-manifest">
    <question>
        <!-- label is from the "exercise" -->
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <!-- Duplicate, but still should look like original (ID, etc.),  -->
        <!-- not knowled. Solutions are available in the originals, via  -->
        <!-- an "in context" link off the Assignment page                -->
        <htmlsrc>
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="true()"/>
                <xsl:with-param name="block-type" select="'visible'"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="false()" />
                <xsl:with-param name="b-has-answer"    select="false()" />
                <xsl:with-param name="b-has-solution"  select="false()" />
            </xsl:apply-templates>
        </htmlsrc>
    </question>
</xsl:template>

<xsl:template match="exercise[webwork-reps]" mode="runestone-manifest">
    <question>
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <!-- N.B.  Better here to ask for "exercise-components"? -->
        <xsl:apply-templates select="introduction|webwork-reps|conclusion"/>
    </question>
</xsl:template>

<!-- PROJECT-LIKE to the Runestone manifest -->
<!--   PROJECT-LIKE with "program" *outside* of "statement" -->
<!-- TODO: where should un-supported languages get caught?  Here is pretty late. -->
<xsl:template match="project[statement/statement and statement/program]|activity[statement/statement and statement/program]|exploration[statement/statement and statement/program]|investigation[statement/statement and statement/program]" mode="runestone-manifest">
    <question>
        <!-- label is from the PROJECT-LIKE -->
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <!-- Duplicate, but still should look like original (ID, etc.),  -->
        <!-- not knowled. Solutions are available in the originals, via  -->
        <!-- an "in context" link off the Assignment page                -->
        <xsl:apply-templates select="."  mode="exercise-components">
            <xsl:with-param name="b-original" select="true()"/>
            <xsl:with-param name="block-type" select="'visible'"/>
            <xsl:with-param name="b-has-statement" select="true()" />
            <xsl:with-param name="b-has-hint"      select="false()" />
            <xsl:with-param name="b-has-answer"    select="false()" />
            <xsl:with-param name="b-has-solution"  select="false()" />
        </xsl:apply-templates>
    </question>
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

<!-- The "runestone-to-interactive" templates will combine a   -->
<!-- "regular" PreTeXt statement together with some additional -->
<!-- interactive material to make a hybrid "statement"         -->


<!-- Hacked -->

<xsl:template match="exercise[@exercise-interactive = 'htmlhack']" mode="runestone-to-interactive">
    <xsl:variable name="runestone" select="string(@runestone)"/>
    <xsl:copy-of select="document('rs-substitutes.xml', $original)/substitutes/substitute[@xml:id = $runestone]"/>
</xsl:template>

<!-- True/False -->

<xsl:template match="exercise[@exercise-interactive = 'truefalse']" mode="runestone-to-interactive">
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:variable>
    <div class="runestone ">
        <!-- ul can have multiple answer attribute -->
        <ul data-component="multiplechoice" data-multipleanswers="false">
            <xsl:attribute name="id">
                <xsl:value-of select="$the-id"/>
            </xsl:attribute>
            <!-- Q: the statement is not a list item, but appears *inside* the list? -->
            <!-- overall statement, not per-choice -->
            <xsl:apply-templates select="statement"/>
            <!-- radio button for True -->
            <xsl:variable name="true-choice-id">
                <xsl:value-of select="$the-id"/>
                <xsl:text>_opt_t</xsl:text>
            </xsl:variable>
            <li data-component="answer">
                <xsl:attribute name="id">
                    <xsl:value-of select="$true-choice-id"/>
                </xsl:attribute>
                <!-- Correct answer if problem statement is correct/True -->
                <xsl:if test="statement/@correct = 'yes'">
                    <xsl:attribute name="data-correct"/>
                </xsl:if>
                <p>True.</p>
            </li>
            <li data-component="feedback">
                <xsl:attribute name="id">
                    <xsl:value-of select="$true-choice-id"/>
                </xsl:attribute>
                <!-- identical feedback for each reader responses -->
                <xsl:apply-templates select="feedback"/>
            </li>
            <!-- radio button for False -->
            <xsl:variable name="false-choice-id">
                <xsl:value-of select="$the-id"/>
                <xsl:text>_opt_f</xsl:text>
            </xsl:variable>
            <li data-component="answer">
                <xsl:attribute name="id">
                    <xsl:value-of select="$false-choice-id"/>
                </xsl:attribute>
                <!-- Correct answer if problem statement is incorrect/False -->
                <xsl:if test="statement/@correct = 'no'">
                    <xsl:attribute name="data-correct"/>
                </xsl:if>
                <p>False.</p>
            </li>
            <li data-component="feedback">
                <xsl:attribute name="id">
                    <xsl:value-of select="$false-choice-id"/>
                </xsl:attribute>
                <!-- identical feedback for each reader responses -->
                <xsl:apply-templates select="feedback"/>
            </li>
        </ul>
    </div>
</xsl:template>

<!-- Multiple Choice -->

<xsl:template match="exercise[@exercise-interactive = 'multiplechoice']" mode="runestone-to-interactive">
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:variable>
    <div class="runestone ">
        <!-- ul can have multiple answer attribute -->
        <ul data-component="multiplechoice">
            <xsl:attribute name="id">
                <xsl:value-of select="$the-id"/>
            </xsl:attribute>
            <xsl:variable name="ncorrect" select="count(choices/choice[@correct = 'yes'])"/>
            <xsl:attribute name="data-multipleanswers">
                <xsl:choose>
                    <xsl:when test="choices/@multiple-correct = 'yes'">
                        <xsl:text>true</xsl:text>
                    </xsl:when>
                    <xsl:when test="choices/@multiple-correct = 'no'">
                        <xsl:text>false</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ncorrect > 1">
                        <xsl:text>true</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>false</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <!-- bare attribute, iff requested -->
            <xsl:if test="choices/@randomize = 'yes'">
                <xsl:attribute name="data-random"/>
            </xsl:if>
            <!-- Q: the statement is not a list item, but appears *inside* the list? -->
            <!-- overall statement, not per-choice -->
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="choices/choice">
                <xsl:with-param name="the-id" select="$the-id"/>
            </xsl:apply-templates>
        </ul>
    </div>
</xsl:template>

<xsl:template match="choices/choice">
    <xsl:param name="the-id"/>

    <!-- id for each "choice"                  -->
    <!-- with common base, then a, b, c suffix -->
    <!-- Used *twice* on adjacent "li"?        -->
    <xsl:variable name="choice-id">
        <xsl:value-of select="$the-id"/>
        <xsl:text>_opt_</xsl:text>
        <!-- will count preceding "choice" only -->
        <xsl:number format="a"/>
    </xsl:variable>
    <li data-component="answer">
        <xsl:attribute name="id">
            <xsl:value-of select="$choice-id"/>
        </xsl:attribute>
        <!-- mark correct answers (empty attribute value) -->
        <xsl:if test="@correct = 'yes'">
            <xsl:attribute name="data-correct"/>
        </xsl:if>
        <!-- per-choice statement -->
        <xsl:apply-templates select="statement"/>
    </li>
    <li data-component="feedback">
        <xsl:attribute name="id">
            <xsl:value-of select="$choice-id"/>
        </xsl:attribute>
        <!-- per-choice explanation -->
        <xsl:apply-templates select="feedback"/>
    </li>
</xsl:template>

<!-- Parsons Problem -->

<xsl:template match="exercise[@exercise-interactive = 'parson']" mode="runestone-to-interactive">
    <!-- determine this option before context switches -->
    <xsl:variable name="b-natural" select="not(@language) or (@language = 'natural')"/>
    <div class="runestone" style="max-width: none;">
        <div data-component="parsons" class="parsons">
            <xsl:apply-templates select="." mode="runestone-id-attribute"/>
            <div class="parsons_question parsons-text" >
                <!-- the prompt -->
                <xsl:apply-templates select="statement"/>
            </div>
            <pre class="parsonsblocks" data-question_label="" style="visibility: hidden;">
                <!-- author opts-in to adaptive problems -->
                <xsl:attribute name="data-language">
                    <xsl:choose>
                        <xsl:when test="$b-natural">
                            <xsl:text>natural</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- must now have @language -->
                            <xsl:value-of select="@language"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:variable name="numbered" select="blocks/@numbered"/>
                <xsl:choose>
                    <xsl:when test="($numbered = 'left') or ($numbered = 'right')">
                        <xsl:attribute name="data-numbered">
                            <xsl:value-of select="$numbered"/>
                        </xsl:attribute>
                    </xsl:when>
                    <!-- default is un-numbered, so no attribute at all -->
                    <xsl:when test="$numbered = 'no'"/>
                    <xsl:otherwise/>
                </xsl:choose>
                <xsl:if test="@adaptive = 'yes'">
                    <xsl:attribute name="data-adaptive">
                        <xsl:text>true</xsl:text>
                    </xsl:attribute>
                </xsl:if>
                <!-- author asks student to provide indentation via  -->
                <!-- the indentation-enabled "drop" text window      -->
                <!-- (not relevant for natural language)             -->
                <xsl:attribute name="data-noindent">
                    <xsl:choose>
                        <xsl:when test="@indentation = 'hide'">
                            <xsl:text>false</xsl:text>
                        </xsl:when>
                        <!-- default is 'show' -->
                        <xsl:otherwise>
                            <xsl:text>true</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <!-- the blocks -->
                <xsl:apply-templates select="blocks/block">
                    <xsl:with-param name="b-natural" select="$b-natural"/>
                </xsl:apply-templates>
            </pre>
        </div>
    </div>
</xsl:template>

<xsl:template match="blocks/block">
    <xsl:param name="b-natural"/>

    <xsl:choose>
        <xsl:when test="choice">
            <!-- put single correct choice first      -->
            <!-- default on "choice" is  correct="no" -->
            <xsl:apply-templates select="choice[@correct = 'yes']">
                <xsl:with-param name="b-natural" select="$b-natural"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="choice[not(@correct = 'yes')]">
                <xsl:with-param name="b-natural" select="$b-natural"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="$b-natural">
                    <xsl:apply-templates />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="cline">
                        <xsl:value-of select="."/>
                        <xsl:if test="following-sibling::cline">
                            <xsl:text>&#xa;</xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
            <!-- default on "block" is  correct="yes" -->
            <xsl:if test="@correct = 'no'">
                <xsl:text> #distractor</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="following-sibling::block">
        <xsl:text>&#xa;---&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="blocks/block/choice">
    <xsl:param name="b-natural"/>

    <!-- Exactly one choice is correct, it is placed first. -->
    <!-- Then the  n - 1  separators can be placed on all   -->
    <!-- the "wrong" choices.                               -->
    <xsl:if test="not(@correct = 'yes')">
        <xsl:text>&#xa;---&#xa;</xsl:text>
    </xsl:if>
    <xsl:choose>
        <xsl:when test="$b-natural">
            <xsl:apply-templates select="*"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select="cline">
                <xsl:value-of select="."/>
                <xsl:if test="following-sibling::cline">
                    <xsl:text>&#xa;</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="not(@correct = 'yes')">
        <xsl:text> #paired</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Matching Problem -->

<xsl:template match="exercise[@exercise-interactive = 'matching']" mode="runestone-to-interactive">
    <xsl:variable name="html-id">
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:variable>
    <div class="runestone">
        <ul data-component="dragndrop" data-question_label="" style="visibility: hidden;">
            <xsl:attribute name="id">
                <xsl:value-of select="$html-id"/>
            </xsl:attribute>
            <span data-subcomponent="question">
                <xsl:apply-templates select="statement"/>
            </span>
            <xsl:if test="feedback">
                <span data-subcomponent="feedback">
                    <xsl:apply-templates select="feedback"/>
                </span>
            </xsl:if>
            <xsl:for-each select="matches/match">
                <xsl:variable name="sub-id">
                    <xsl:value-of select="$html-id"/>
                    <xsl:text>_drag</xsl:text>
                    <xsl:number />
                </xsl:variable>
                <!-- PTX premise = RS draggable -->
                <li data-subcomponent="draggable">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$sub-id"/>
                    </xsl:attribute>
                    <xsl:apply-templates select="premise"/>
                </li>
                <!-- PTX response = RS dropzone -->
                <li data-subcomponent="dropzone">
                    <xsl:attribute name="for">
                        <xsl:value-of select="$sub-id"/>
                    </xsl:attribute>
                    <xsl:apply-templates select="response"/>
                </li>
            </xsl:for-each>
        </ul>
    </div>
</xsl:template>

<!-- Clickable Area Problem -->

<xsl:template match="exercise[@exercise-interactive = 'clickablearea']" mode="runestone-to-interactive">
    <xsl:variable name="html-id">
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:variable>
    <div class="runestone">
        <div data-component="clickablearea" class="runestone" data-question_label="" style="visibility: hidden;">
            <xsl:attribute name="id">
                <xsl:value-of select="$html-id"/>
            </xsl:attribute>
            <span data-question="">
                <xsl:apply-templates select="statement"/>
            </span>
            <span data-feedback="">
                <xsl:apply-templates select="feedback"/>
            </span>
            <xsl:apply-templates select="areas" mode="clickable-html"/>
        </div>
    </div>
</xsl:template>

<!-- We use modal templates, primarily for the case of code, -->
<!-- so we do not mangle text() using routines in -common    -->
<!-- and to preserve the structure of the program.           -->

<xsl:template match="areas" mode="clickable-html">
    <xsl:choose>
        <xsl:when test="cline">
            <!-- code, so make the "pre" structure -->
            <pre>
                <xsl:apply-templates select="cline" mode="clickable-html"/>
            </pre>
        </xsl:when>
        <xsl:otherwise>
            <!-- regular text, this will match a default template later -->
            <xsl:apply-templates select="*" mode="clickable-html"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A mix of text and "area", and needs a newline -->
<xsl:template match="areas/cline" mode="clickable-html">
    <xsl:apply-templates select="text()|area" mode="clickable-html"/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Avoid falling into low-level manipulations to remain verbatim -->
<xsl:template match="areas/cline/text()" mode="clickable-html">
    <xsl:value-of select="."/>
</xsl:template>

<!-- Constructions for regular text ("p", "ul", etc) should   -->
<!-- drop out to default templates, as will an "area" element -->
<!-- (both code and regular text).                            -->
<xsl:template match="*" mode="clickable-html">
    <xsl:apply-templates select="."/>
</xsl:template>

<!-- NB: we want a generic template (not modal) for use within      -->
<!-- sentences, etc.  As such it will then be available in every    -->
<!-- derived conversion, *but* the "area" element should not        -->
<!-- survive a conversion to a static form, so will not be present. -->
<xsl:template match="area">
    <span>
        <xsl:choose>
            <xsl:when test="@correct = 'no'">
                <xsl:attribute name="data-incorrect"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="data-correct"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates/>
    </span>
</xsl:template>

<!-- Fill-in-the-Blanks problem -->

<!-- Runestone structure -->
<xsl:template match="exercise[@exercise-interactive = 'fillin-basic']" mode="runestone-to-interactive">
    <div class="runestone">
        <!-- dropped "visibility: hidden" on next div -->
        <div data-component="fillintheblank" data-question_label="">
            <xsl:apply-templates select="." mode="runestone-id-attribute"/>
            <xsl:apply-templates select="statement"/>
            <script type="application/json">
                <xsl:apply-templates select="setup" mode="json-conditions"/>
            </script>
        </div>
    </div>
</xsl:template>

<!-- simple substitution in output -->
<xsl:template match="exercise/statement//var">
    <!-- NB: this code is used in formulating static representations -->
    <!-- count location of (context) "var" in problem statement      -->
    <xsl:variable name="location">
        <xsl:number from="statement"/>
    </xsl:variable>
    <!-- locate corresponding "var" in "setup" -->
    <xsl:variable name="setup-var" select="ancestor::exercise/setup/var[position() = $location]"/>

    <!-- Know can tell what sort of data goes into the form entry -->
    <xsl:variable name="placeholder-hint">
        <xsl:choose>
            <xsl:when test="$setup-var/condition[1]/@number">
                <xsl:text>Number</xsl:text>
            </xsl:when>
            <xsl:when test="$setup-var/condition[1]/@string">
                <xsl:text>Text</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <!-- the actual form fill-in, with hint -->
    <input type="text" placeholder="{$placeholder-hint}"/>
</xsl:template>

<!-- JSON list-of-list structure -->
<xsl:template match="exercise/setup"  mode="json-conditions">
    <!-- outermost list begin -->
    <xsl:text>[</xsl:text>
    <xsl:for-each select="var">
        <!-- per-var list begin -->
        <xsl:text>[</xsl:text>
        <xsl:for-each select="condition">
            <!-- where the real content originates -->
            <xsl:apply-templates select="." mode="condition-to-json"/>
            <!-- separate dictionaries for conditions -->
            <xsl:if test="following-sibling::condition">
                <xsl:text>, </xsl:text>
            </xsl:if>
        </xsl:for-each>
        <!-- per-var list end -->
        <xsl:text>]</xsl:text>
        <!-- separate vars -->
        <xsl:if test="following-sibling::var">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:for-each>
    <!-- outermost list end -->
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- JSON dictionary for numerical condition -->
<xsl:template match="setup/var/condition[@number]" mode="condition-to-json">
    <!-- per-condition dictionary begin -->
    <xsl:text>{</xsl:text>
    <xsl:text>"number": [</xsl:text>
    <xsl:choose>
        <xsl:when test="@tolerance">
            <xsl:value-of select="@number - @tolerance"/>
            <xsl:text>,</xsl:text>
            <xsl:value-of select="@number + @tolerance"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="@number"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="@number"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>]</xsl:text>
    <xsl:if test="feedback">
        <xsl:text>, "feedback": "</xsl:text>
        <xsl:apply-templates select="feedback" mode="serialize-feedback"/>
        <xsl:text>"</xsl:text>
    </xsl:if>
    <!-- per-condition dictionary end -->
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- JSON dictionary for string condition -->
<xsl:template match="setup/var/condition[@string]" mode="condition-to-json">
    <!-- per-condition dictionary begin -->
    <xsl:text>{</xsl:text>
    <!-- regex string match, drop    -->
    <!-- leading/trailing whitespace -->
    <xsl:text>"regex": "</xsl:text>
    <!-- JSON escapes necessary for regular expression -->
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:text>^\s*</xsl:text>
            <xsl:value-of select="@string"/>
            <xsl:text>\s*$</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
    <!-- flag for case-sensitive match -->
    <!-- default:  'sensitive'         -->
    <xsl:text>, "regexFlags": "</xsl:text>
    <xsl:if test="parent::var/@case = 'insensitive'">
        <xsl:text>i</xsl:text>
    </xsl:if>
    <xsl:text>"</xsl:text>
    <!-- optional feedback -->
    <xsl:if test="feedback">
        <xsl:text>, "feedback": "</xsl:text>
        <xsl:apply-templates select="feedback" mode="serialize-feedback"/>
        <xsl:text>"</xsl:text>
    </xsl:if>
    <!-- per-condition dictionary end -->
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="setup/var/condition/feedback" mode="serialize-feedback">
    <xsl:variable name="feedback-rtf">
        <xsl:apply-templates select="."/>
    </xsl:variable>
    <!-- serialize HTML as text, then escape as JSON -->
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:apply-templates select="exsl:node-set($feedback-rtf)" mode="serialize"/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>


<!-- Coding exercise -->

<xsl:template match="exercise[@exercise-interactive = 'coding']|project[@exercise-interactive = 'coding']|activity[@exercise-interactive = 'coding']|exploration[@exercise-interactive = 'coding']|investigation[@exercise-interactive = 'coding']" mode="runestone-to-interactive">
    <!-- We don't have a 'coding' attribute value  -->
    <!-- unless one of the two tests below is true -->
    <xsl:choose>
        <xsl:when test="program/@interactive = 'codelens'">
            <xsl:apply-templates select="statement"/>
            <xsl:apply-templates select="program" mode="runestone-codelens"/>
        </xsl:when>
        <xsl:when test="program/@interactive = 'activecode'">
            <xsl:apply-templates select="program" mode="runestone-activecode">
                <xsl:with-param name="exercise-statement" select="statement"/>
            </xsl:apply-templates>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- Short Answer problem -->

<!-- Traditional form, but not converted like other interactive exercises -->
<!-- Won't match indiscriminately, there is some control over when to be  -->
<!-- interactive, see "static" v. "dynamic" publisher variables.          -->
<!-- NB - not currently applying to short-form with no "statement" -->
<!-- NB: match is recycled in manifest formation                   -->
<xsl:template match="exercise[@exercise-interactive = 'shortanswer']" mode="runestone-to-interactive">
    <div class="runestone">
        <div data-component="shortanswer" data-question_label="" class="journal" data-mathjax="">
            <xsl:apply-templates select="." mode="runestone-id-attribute"/>
            <xsl:apply-templates select="statement"/>
        </div>
    </div>
</xsl:template>

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
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:variable>

    <div id="{$hid}" data-component="youtube" class="align-left youtube-video"
         data-video-height="{$height}" data-video-width="{$width}"
         data-video-videoid="{@youtube}" data-video-divid="{$hid}"
         data-video-start="0" data-video-end="-1"/>
</xsl:template>

<!-- ########### -->
<!-- Active Code -->
<!-- ########### -->

<!-- Runestone has support for various languages.  Some    -->
<!-- are "in-browser" while others are backed by "real"    -->
<!-- compilers as part of a Runestone server.  For an      -->
<!-- exercise, we pass in some lead-in text, which is      -->
<!-- the directions for using the ActiveCode component.    -->
<!-- This template does the best job possible:             -->
<!--   1.  Unsupported language, static rendering.         -->
<!--   2.  Supported in-browser, always interactive.       -->
<!--   3.  On a Runestone server, always interactive.      -->
<!--                                                       -->
<!-- When a "program" is part of an exercise/project-like, -->
<!-- then we need to get the problem "statement" absorbed  -->
<!-- into the ActiveCode.  This is an authored "statement" -->
<!-- passed in via the $exercise-statement parameter.      -->
<!-- Other times a "program" is an atomic item             -->
<!-- and surrounding text explains its purpose, hence      -->
<!-- "exercise-statment" appropriately defaults to an      -->
<!-- empty node-set.                                       -->
<xsl:template match="program" mode="runestone-activecode">
    <xsl:param name="exercise-statement" select="/.."/>

    <xsl:variable name="active-language">
        <xsl:apply-templates select="." mode="active-language"/>
    </xsl:variable>
    <xsl:variable name="hosting">
        <xsl:apply-templates select="." mode="activecode-host"/>
    </xsl:variable>
    <!-- Use an id from the "program" element, unless employed -->
    <!-- inside an exercise/project-like, which is up a level  -->
    <!-- (and could be many different types of project-like).  -->
    <xsl:variable name="hid">
        <xsl:choose>
            <xsl:when test="$exercise-statement">
                <xsl:apply-templates select="parent::*" mode="runestone-id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="runestone-id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- unsupported on Runestone, period -->
        <xsl:when test="$active-language = ''">
            <xsl:apply-templates select="$exercise-statement"/>
            <xsl:apply-templates select="." mode="code-inclusion"/>
        </xsl:when>
        <!-- needs server, and we aren't there -->
        <xsl:when test="($hosting = 'jobeserver') and not($b-host-runestone)">
            <xsl:apply-templates select="$exercise-statement"/>
            <xsl:apply-templates select="." mode="code-inclusion"/>
        </xsl:when>
        <!-- this is the logical negation of the previous, so could be "otherwise" -->
        <xsl:when test="($hosting = 'browser') or $b-host-runestone">
            <div class="runestone explainer ac_section ">
                <div data-component="activecode">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$hid"/>
                    </xsl:attribute>
                    <!-- add some lead-in text to the window -->
                    <xsl:if test="$exercise-statement">
                        <div class="ac_question col-md-12">
                            <xsl:attribute name="id">
                                <xsl:value-of select="concat($hid, '_question')"/>
                            </xsl:attribute>
                            <xsl:apply-templates select="$exercise-statement"/>
                        </div>
                    </xsl:if>
                    <textarea data-lang="{$active-language}" data-timelimit="25000" data-audio="" data-coach="true" style="visibility: hidden;">
                        <xsl:attribute name="id">
                            <xsl:value-of select="concat($hid, '_editor')"/>
                        </xsl:attribute>
                        <xsl:attribute name="data-question_label"/>
                        <!-- Code Lens only for certain languages -->
                        <xsl:attribute name="data-codelens">
                            <xsl:choose>
                                <xsl:when test="($active-language = 'python') or ($active-language = 'python2') or ($active-language = 'python3')">
                                    <xsl:text>true</xsl:text>
                                </xsl:when>
                                <xsl:when test="($active-language = 'c') or ($active-language = 'cpp') or ($active-language = 'java')">
                                    <xsl:text>true</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>false</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <!-- SQL (only) needs an attribute so it can find some code -->
                        <xsl:if test="$active-language = 'sql'">
                            <xsl:attribute name="data-wasm">
                                <xsl:text>/_static</xsl:text>
                            </xsl:attribute>
                        </xsl:if>
                        <!-- the code itself as text -->
                        <xsl:call-template name="sanitize-text">
                            <xsl:with-param name="text" select="input" />
                        </xsl:call-template>
                        <!-- optional unit testing, with RS markup to keep it hidden -->
                        <xsl:if test="tests">
                            <xsl:text>====&#xa;</xsl:text>
                            <xsl:call-template name="sanitize-text">
                                <xsl:with-param name="text" select="tests" />
                            </xsl:call-template>
                        </xsl:if>
                    </textarea>
                </div>
            </div>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- ######## -->
<!-- CodeLens -->
<!-- ######## -->

<xsl:template match="program[@interactive = 'codelens']" mode="runestone-codelens">
    <!-- as a variable so it does not look like an AVT -->
    <xsl:variable name="parameter-dictionary">
        <xsl:text>{</xsl:text>
        <xsl:text>"embeddedMode": true, </xsl:text>
        <xsl:text>"lang": "</xsl:text>
        <xsl:value-of select="@language"/>
        <xsl:text>", </xsl:text>
        <xsl:text>"jumpToEnd": false</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:variable>
    <!-- locate trace data via a *.js file, managed or not -->
    <xsl:variable name="trace-file">
        <xsl:value-of select="$generated-directory"/>
        <xsl:if test="$b-managed-directories">
            <xsl:text>trace/</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="visible-id"/>
        <xsl:text>.js</xsl:text>
    </xsl:variable>
    <!-- the Runestone HTML -->
    <div class="runestone codelens">
        <div class="cd_section" data-component="codelens" data-question_label="">
            <div class="pytutorVisualizer">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <xsl:attribute name="data-params">
                    <xsl:value-of select="$parameter-dictionary"/>
                </xsl:attribute>
            </div>
            <!-- no caption, should go inside a listing? -->
        </div>
        <!-- access simple script with variable set to -->
        <!-- the trace data via the @src attribute     -->
        <script>
            <xsl:attribute name="src">
                <xsl:value-of select="$trace-file"/>
            </xsl:attribute>
        </script>
    </div>
</xsl:template>

<!-- Some Runestone languages are supported within a browser,      -->
<!-- so can be used as part of Runestone for All, while others     -->
<!-- require a JOBE server on the Runestone server.  This template -->
<!-- simply returns the necessary hosting capability.              -->
<xsl:template match="program" mode="activecode-host">
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="active-language"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$language = 'python'">      <xsl:text>browser</xsl:text></xsl:when>
        <xsl:when test="$language = 'javascript'">  <xsl:text>browser</xsl:text></xsl:when>
        <xsl:when test="$language = 'html'">        <xsl:text>browser</xsl:text></xsl:when>
        <xsl:when test="$language = 'sql'">         <xsl:text>browser</xsl:text></xsl:when>
        <xsl:when test="$language = 'c'">           <xsl:text>jobeserver</xsl:text></xsl:when>
        <xsl:when test="$language = 'cpp'">         <xsl:text>jobeserver</xsl:text></xsl:when>
        <xsl:when test="$language = 'java'">        <xsl:text>jobeserver</xsl:text></xsl:when>
        <xsl:when test="$language = 'python2'">     <xsl:text>jobeserver</xsl:text></xsl:when>
        <xsl:when test="$language = 'python3'">     <xsl:text>jobeserver</xsl:text></xsl:when>
        <xsl:when test="$language = 'octave'">      <xsl:text>jobeserver</xsl:text></xsl:when>
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>