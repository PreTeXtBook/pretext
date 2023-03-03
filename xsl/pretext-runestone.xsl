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
<!-- str: necessary to tokenize alternate Runestone Services -->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str pi"
>

<!-- Not documented, for development use only -->
<xsl:param name="debug.rs.services.file" select="''"/>
<xsl:variable name="b-debugging-rs-services" select="not($debug.rs.services.file = '')"/>


<!-- ######################## -->
<!-- Runestone Infrastructure -->
<!-- ######################## -->

<!-- While under development, or maybe forever, do not load  -->
<!-- Runestone Javascript unless it is necessary.  Various   -->
<!-- values of @exercise-interactive are added in the        -->
<!-- pre-processing phase.  program/@interactive takes on    -->
<!-- values of 'activecode' and 'codelens'.                  -->
<xsl:variable name="b-needs-runestone" select="boolean($document-root//*[@exercise-interactive and not(@exercise-interactive='container') and not(@exercise-interactive='static') and not(@exercise-interactive='webwork-reps') and not(@exercise-interactive='webwork-task')]|$document-root//program[@interactive]|$document-root//datafile)"/>

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
        <xsl:when test="$b-debugging-rs-services">
            <xsl:value-of select="$debug.rs.services.file"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>support/runestone-services.xml</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="runestone-services" select="document($runestone-services-filename)"/>

<!-- Alternate Runestone Services -->
<!-- We allow for an override of the content of the services file via      -->
<!-- string parameters passed into this stylesheet. The purpose is to      -->
<!-- allow the core Pythoon routines to query the Runestone server for     -->
<!-- the *very latest* services file available online.  This will be       -->
<!-- used instead of the recent (but not always latest) offline version    -->
<!-- in the repository. This is meant to be a totally automated operation, -->
<!-- so parameter names are not always human-friendly.                     -->
<!--                                                                       -->
<!-- Priority order                                                        -->
<!--   1.  Respect debugging parameter                                     -->
<!--   2.  Accept non-empty parameters (from Python online query, "altrs") -->
<!--   3.  Offline, standard, use file in repository "support" directory   -->
<xsl:param name="altrs-js" select="''"/>
<xsl:param name="altrs-css" select="''"/>
<xsl:param name="altrs-cdn-url" select="''"/>
<xsl:param name="altrs-version" select="''"/>
<!-- We arbitrarily use the version parameter as a flag for the   -->
<!-- use of alternate services and rely on code to always specify -->
<!-- all four parameters or none at all.                          -->
<xsl:variable name="b-altrs-services" select="not($altrs-version = '') and not($b-debugging-rs-services)"/>
<!-- The Runestone Services version actually in use is -->
<!-- needed several places, so we compute it once now. -->
<!-- Manifest, two "ebookConfig".                      -->
<xsl:variable name="runestone-version">
    <xsl:choose>
        <xsl:when test="$b-altrs-services">
            <xsl:value-of select="$altrs-version"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$runestone-services/all/version"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

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
                <!-- Scratch ActiveCode windows are a publisher option -->
                <xsl:text>eBookConfig.enableScratchAC = </xsl:text>
                <xsl:choose>
                    <xsl:when test="$b-has-scratch-activecode">
                        <xsl:text>true</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>false</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>;&#xa;</xsl:text>
                <!-- And set the language when scratch ActiveCode is enabled -->
                <xsl:if test="$b-has-scratch-activecode">
                    <xsl:text>eBookConfig.acDefaultLanguage = '</xsl:text>
                    <xsl:value-of select="$html-scratch-activecode-language"/>
                    <xsl:text>';&#xa;</xsl:text>
                </xsl:if>
                <!-- end Scratch ActiveCode windows -->
                <xsl:text>eBookConfig.new_server_prefix = "/ns";&#xa;</xsl:text>
                <xsl:text>eBookConfig.runestone_version = '</xsl:text>
                <xsl:value-of select="$runestone-version"/>
                <xsl:text>';&#xa;</xsl:text>
                <!-- no .build_info -->
                <!-- no .python3 -->
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
                <!-- scratch Active Code fails if these faux strings have spaces or colons -->
                <xsl:text>eBookConfig.course = 'PTX_Course_Title_Here';&#xa;</xsl:text>
                <xsl:text>eBookConfig.basecourse = 'PTX_Base_Course';&#xa;</xsl:text>
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
                <!-- Scratch ActiveCode windows are a publisher option -->
                <xsl:text>eBookConfig.enableScratchAC = </xsl:text>
                <xsl:choose>
                    <xsl:when test="$b-has-scratch-activecode">
                        <xsl:text>true</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>false</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>;&#xa;</xsl:text>
                <!-- And set the language when scratch ActiveCode is enabled -->
                <xsl:if test="$b-has-scratch-activecode">
                    <xsl:text>eBookConfig.acDefaultLanguage = '</xsl:text>
                    <xsl:value-of select="$html-scratch-activecode-language"/>
                    <xsl:text>';&#xa;</xsl:text>
                </xsl:if>
                <!-- end Scratch ActiveCode windows -->
                <xsl:text>eBookConfig.build_info = "";&#xa;</xsl:text>
                <xsl:text>eBookConfig.python3 = null;&#xa;</xsl:text>
                <xsl:text>eBookConfig.runestone_version = '</xsl:text>
                <xsl:value-of select="$runestone-version"/>
                <xsl:text>';&#xa;</xsl:text>
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
    <!-- manner as at Runestone Academy.  Additionally, overrides via      -->
    <!-- string parameters are supported.                                  -->
    <xsl:variable name="runestone-cdn">
        <xsl:choose>
            <xsl:when test="$b-host-runestone">
                <xsl:text>_static/</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- CDN URL should end in a slash, -->
                <!-- as version has no slashes      -->
                <xsl:choose>
                    <xsl:when test="$b-altrs-services">
                        <xsl:value-of select="$altrs-cdn-url"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$runestone-services/all/cdn-url"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="$runestone-version"/>
                <xsl:text>/</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- The Runestone Services file typically contains multiple filenames    -->
    <!-- for Javascript and CSS (like two or three).  In the alternate case,  -->
    <!-- we expect the two string parameters to be lists delimited by a colon -->
    <!-- (':'), so this character should not ever appear in the filenames.    -->
    <!-- Note: these variables will be vacuous when the string parameters are -->
    <!-- empty strings, and then will not ever be employed (below).           -->
    <xsl:variable name="altrs-js-tokens" select="str:tokenize($altrs-js, ':')"/>
    <xsl:variable name="altrs-css-tokens" select="str:tokenize($altrs-css, ':')"/>

    <!-- The $runestone-cdn variable will point to the right Runestone  -->
    <!-- Services file: when hosted on Runestone, inside of _static; or -->
    <!-- when building for arbitrary hosting, inside the repository.    -->
    <!-- In the case of alternate information provided via string       -->
    <!-- parameters, the tokenized node sets will be employed.  Note    -->
    <!-- how the unions of the two node-sets in the "for-each" are more -->
    <!-- like exclusive-or, as we always get exactly one of the two.    -->
    <!-- N.B. Enclosing "if" goes away if/when $b-needs-runestone    -->
    <!-- just becomes true all the time.  Indentation predicts this. -->
    <xsl:if test="$b-host-runestone or $b-needs-runestone">
    <xsl:comment>*** Runestone Services ***</xsl:comment>
    <xsl:text>&#xa;</xsl:text>
    <xsl:for-each select="$runestone-services/all/js/item[not($b-altrs-services)]|$altrs-js-tokens[$b-altrs-services]">
        <script type="text/javascript">
            <xsl:attribute name="src">
                <xsl:value-of select="$runestone-cdn"/>
                <xsl:value-of select="."/>
            </xsl:attribute>
        </script>
    </xsl:for-each>
    <xsl:for-each select="$runestone-services/all/css/item[not($b-altrs-services)]|$altrs-css-tokens[$b-altrs-services]">
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
                <!-- if reader is not an instructor the next link will be removed by javascript -->
                <a id="inst_peer_link" href='/{{appname}}/peer/instructor.html'>Peer Instruction (Instructor)</a>
                <a href='/{{appname}}/peer/student.html'>Peer Instruction (Student)</a>
                <hr/>
                <a href="/runestone/default/courses">Change Course</a>
                <hr/>
                <a id="ip_dropdown_link" href="/runestone/admin/index">Instructor's Page</a>
                <hr/>
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>{% endif %}&#xa;</xsl:text>
                <a href="/runestone/dashboard/studentreport">Progress Page</a>
                <hr/>
                <xsl:text>&#xa;{% if is_logged_in %}&#xa;</xsl:text>
                <a href="/runestone/default/user/profile">Edit Profile</a>
                <a href="/runestone/default/user/change_password">Change Password</a>
                <a href="/runestone/default/user/logout">Log Out</a>
                <xsl:text>&#xa;{% else %}&#xa;</xsl:text>
                <a href="/runestone/default/user/register">Register</a>
                <a href="/runestone/default/user/login">Login</a>
                <xsl:text>&#xa;{% endif %}&#xa;</xsl:text>
            </div>
        </div>
    </xsl:if>
</xsl:template>

<!-- Scratch ActiveCode window, for all builds (powered by Runestone   -->
<!-- Javascript).  But more languages available on a Runestone server. -->
<!-- Only if requested, explicitly or implicitly, via publisher file.  -->
<!-- Unicode Character 'PENCIL' (U+270F)                               -->
<xsl:template name="runestone-scratch-activecode">
    <xsl:if test="$b-has-scratch-activecode">
        <a href="javascript:runestoneComponents.popupScratchAC()" class="activecode-toggle" title="Scratch ActiveCode">
            <span class="icon">&#x270F;</span>
        </a>
    </xsl:if>
</xsl:template>

<!-- A convenience for attaching a Runestone id -->
<xsl:template match="exercise|program|datafile|&PROJECT-LIKE;|task|video[@youtube]|exercises" mode="runestone-id-attribute">
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
                    <xsl:value-of select="$runestone-version"/>
                </xsl:attribute>
            </runestone-services>
            <!-- mine various bits and pieces of the source for RS metadata  -->
            <!-- collection, which is technically a "conf.py" file, per-book -->
            <library-metadata publisher="pretext">
                <!-- sanitizes footnotes, quotes, math for overall title-->
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
                <!-- duplicate blurb, blurb/@shelf for Runestone's convenience -->
                <!-- use "value-of" to enforce assumption there is no markup   -->
                <!-- NB: if absent in PTX source, these are empty in manifest  -->
                <shelf>
                    <xsl:value-of select="$docinfo/blurb/@shelf"/>
                </shelf>
                <blurb>
                    <xsl:value-of select="$docinfo/blurb"/>
                </blurb>
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
        <!-- If any of the next select are containers (full of "task") they will not  -->
        <!-- meet the dead-end monster match below, and the default template will     -->
        <!-- recurse into non-container "task" eventually, so "task" do get           -->
        <!-- processed, even if they seem to be missing from this select.             -->
        <xsl:apply-templates select=".//exercise|.//project|.//activity|.//exploration|.//investigation|.//video[@youtube]|.//program[(@interactive = 'codelens') and not(parent::exercise)]|.//program[(@interactive = 'activecode') and not(parent::exercise)]|.//datafile" mode="runestone-manifest"/>
    </subchapter>
    <!-- dead end structurally, no more recursion, even if "subsection", etc. -->
</xsl:template>

<!-- A Runestone exercise needs to identify itself when an instructor wants   -->
<!-- to select it for assignment, so we want to provide enough identification -->
<!-- in the manifest, via a "label" element full of raw text.                 -->
<xsl:template match="exercise|project|activity|exploration|investigation|task" mode="runestone-manifest-label">
    <label>
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="number"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
    </label>
</xsl:template>

<!-- Minimal label.  In database for obvious reasons, -->
<!-- this is best (only?) thing to use as a label.    -->
<xsl:template match="datafile" mode="runestone-manifest-label">
    <label>
        <xsl:value-of select="@filename"/>
    </label>
</xsl:template>

<!-- Runestone tracks engagement with YouTube videos and "stray" -->
<!-- ActiveCode and CodeLens (i.e. an "inline" "program", not as -->
<!-- a portion of an "exercise".  As these are atomic elements,  -->
<!-- there is little to grab onto for a label in a report for an -->
<!-- instructor.  So we provide examination of an enclosing      -->
<!-- figure ("video") or listing ("program").                    -->

<xsl:template match="video[@youtube]|program[((@interactive = 'codelens') or (@interactive = 'activecode')) and not(parent::exercise)]" mode="runestone-manifest-label">
    <label>
        <!-- three ways to get a type-name -->
        <xsl:choose>
            <xsl:when test="self::video[@youtube]">
                <xsl:apply-templates select="." mode="type-name"/>
            </xsl:when>
            <xsl:when test="self::program[@interactive = 'codelens']">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'program-codelens'"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="self::program[@interactive = 'activecode']">
                <xsl:apply-templates select="." mode="type-name">
                    <xsl:with-param name="string-id" select="'program-activecode'"/>
                </xsl:apply-templates>
            </xsl:when>
        </xsl:choose>
        <!-- "video" can be a "figure", and "program" can be in a -->
        <!-- "listing", but the two situations are similar enough -->
        <!-- to combine and work with a generic parent/enclosure. -->
        <!-- This could well be empty if inline objects.          -->
        <xsl:variable name="enclosure" select="parent::figure|parent::listing"/>
        <xsl:variable name="b-title" select="boolean(title)"/>
        <xsl:variable name="b-enclosure" select="boolean($enclosure)"/>
        <!-- more coming, use a separator -->
        <xsl:if test="$b-title or $b-enclosure">
            <xsl:text>: </xsl:text>
        </xsl:if>
        <!-- object's title is "closer" (or may be only  -->
        <!-- possible identification if standalone) -->
        <xsl:if test="$b-title">
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
        <!-- if an abundance, use a separator -->
        <xsl:if test="$b-title and $b-enclosure">
            <xsl:text>; </xsl:text>
        </xsl:if>
        <xsl:if test="$b-enclosure">
            <xsl:apply-templates select="$enclosure" mode="type-name"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="$enclosure" mode="number"/>
            <xsl:if test="$enclosure/title">
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="$enclosure" mode="title-full"/>
            </xsl:if>
        </xsl:if>
        <!-- last ditch effor for a YouTube video -->
        <xsl:if test="self::video[@youtube] and not($b-title) and not($b-enclosure)">
            <xsl:text>: </xsl:text>
            <!-- need to know Runestone CSS to make this code/monospace -->
            <xsl:value-of select="@youtube"/>
        </xsl:if>
    </label>
</xsl:template>

<!-- Exercises to the Runestone manifest -->
<!--   - every True/False "exercise"                  -->
<!--   - every multiple choice "exercise"             -->
<!--   - every Parsons problem "exercise"             -->
<!--   - every horizontal Parsons problem "exercise"  -->
<!--   - every matching problem "exercise"            -->
<!--   - every clickable area problem "exercise"      -->
<!--   - every "exercise" with fill-in blanks         -->
<!--   - every "exercise" with additional "program"   -->
<!--   - every "exercise" elected as "shortanswer"    -->
<!--   - every PROJECT-LIKE with additional "program" -->
<xsl:template match="exercise[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                      |
                      project[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                     |
                     activity[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                     |
                  exploration[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                     |
                investigation[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]
                     |
                         task[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]" mode="runestone-manifest">
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

<!-- exercise and PROJECT-LIKE with WeBWorK guts -->
<xsl:template match="exercise[(@exercise-interactive = 'webwork-reps')]
                   | project[(@exercise-interactive = 'webwork-reps')]
                   | activity[(@exercise-interactive = 'webwork-reps')]
                   | exploration[(@exercise-interactive = 'webwork-reps')]
                   | investigation[(@exercise-interactive = 'webwork-reps')]" mode="runestone-manifest">
    <question>
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <htmlsrc>
            <xsl:apply-templates select="." mode="webwork-core">
                <xsl:with-param name="b-original" select="true()"/>
            </xsl:apply-templates>
        </htmlsrc>
    </question>
</xsl:template>

<!-- TODO: by renaming/refactoring the templates inside of   -->
<!-- "htmlsrc" then perhaps several of these templates with  -->
<!-- similar structure can be combined via one larger match. -->

<xsl:template match="video[@youtube]" mode="runestone-manifest">
    <question>
        <!-- label is from the "video", or enclosing "figure" -->
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <htmlsrc>
            <xsl:apply-templates select="." mode="runestone-youtube-embed"/>
        </htmlsrc>
    </question>
</xsl:template>

<xsl:template match="program[(@interactive = 'codelens') and not(parent::exercise)]" mode="runestone-manifest">
    <question>
        <!-- label is from the "program", or enclosing "listing" -->
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <htmlsrc>
            <xsl:apply-templates select="." mode="runestone-codelens"/>
        </htmlsrc>
    </question>
</xsl:template>

<xsl:template match="program[(@interactive = 'activecode') and not(parent::exercise)]" mode="runestone-manifest">
    <question>
        <!-- label is from the "program", or enclosing "listing" -->
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <htmlsrc>
            <xsl:apply-templates select="." mode="runestone-activecode"/>
        </htmlsrc>
    </question>
</xsl:template>

<!-- In database with the same structure as an exercise/question. -->
<xsl:template match="datafile" mode="runestone-manifest">
    <question>
        <!-- label is from the "program", or enclosing "listing" -->
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <htmlsrc>
            <xsl:apply-templates select="." mode="runestone-to-interactive"/>
        </htmlsrc>
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

<!-- The application of the "runestone-to-interactive" template is -->
<!-- controlled by a surrounding "match" that limits elements      -->
<!-- to "exercise", PROJECT-LIKE, and soon "task".  So the         -->
<!-- matches here are fine with a *[@exercise-interactive='foo'],  -->
<!-- as a convenience.                                             -->

<!-- Hacked -->

<xsl:template match="*[@exercise-interactive = 'htmlhack']" mode="runestone-to-interactive">
    <xsl:variable name="runestone" select="string(@runestone)"/>
    <div class="ptx-runestone-container">
        <xsl:copy-of select="document('rs-substitutes.xml', $original)/substitutes/substitute[@xml:id = $runestone]"/>
    </div>
</xsl:template>

<!-- True/False -->

<xsl:template match="*[@exercise-interactive = 'truefalse']" mode="runestone-to-interactive">
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:variable>
    <div class="ptx-runestone-container">
        <div class="runestone">
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
    </div>
</xsl:template>

<!-- Multiple Choice -->

<xsl:template match="*[@exercise-interactive = 'multiplechoice']" mode="runestone-to-interactive">
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:variable>
    <div class="ptx-runestone-container">
        <div class="runestone">
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

<xsl:template match="*[@exercise-interactive = 'parson']" mode="runestone-to-interactive">
    <!-- determine this option before context switches -->
    <xsl:variable name="b-natural" select="not(@language) or (@language = 'natural')"/>
    <div class="ptx-runestone-container">
        <div class="runestone parsons_section" style="max-width: none;">
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
                    <xsl:apply-templates select="blocks/block" mode="vertical-blocks">
                        <xsl:with-param name="b-natural" select="$b-natural"/>
                    </xsl:apply-templates>
                </pre>
            </div>
        </div>
    </div>
</xsl:template>

<xsl:template match="blocks/block" mode="vertical-blocks">
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

<!-- Parsons Problem (Horizontal)-->

<xsl:template  match="exercise[@exercise-interactive = 'parson-horizontal']" mode="runestone-to-interactive">
    <!-- determine these options before context switches -->
    <xsl:variable name="b-natural" select="not(@language) or (@language = 'natural')"/>
    <!-- randomize by default, so must explicitly turn off -->
    <xsl:variable name="b-randomize" select="not(blocks/@randomize = 'no')"/>
    <!-- A @ref is automatic indicator, else reuse has been requested on blocks -->
    <xsl:variable name="b-reuse" select="blocks/block[@ref] or (blocks/@reuse = 'yes')"/>
    <!-- We loop over blocks, as authored, so this is just a convenience -->
    <xsl:variable name="authored-blocks" select="blocks/block"/>
    <!-- A block with @ref indicates reuse of some other block, for answer         -->
    <!-- specifications we want to treat them as duplicates.  And we do not        -->
    <!-- write them into the HTML either.  So we make a subset of *unique* blocks. -->
    <xsl:variable name="unique-blocks" select="blocks/block[not(@ref)]"/>

     <div class="ptx-runestone-container">
        <div class="runestone" style="max-width: none;">
            <div data-component="hparsons" class="hparsons_section">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <div class="hp_question col-md-12">
                    <!-- the prompt -->
                    <xsl:apply-templates select="statement"/>
                </div>
                <!-- empty div seems necessary? -->
                <div class="hparsons"/>
                <textarea style="visibility: hidden">
                    <!-- A SQL database can be provided for automated  -->
                    <!-- testing of correct answers via unit tests.    -->
                    <!-- This is a location in the external directory. -->
                    <!-- NB: sample had paths with a leading backslash -->
                    <xsl:if test="@database">
                        <xsl:attribute name="data-dburl">
                            <xsl:choose>
                                <xsl:when test="$b-managed-directories">
                                    <xsl:value-of select="$external-directory"/>
                                    <xsl:value-of select="@database"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="@database"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </xsl:if>
                    <!-- for natural language, just skip attribute -->
                    <xsl:if test="not($b-natural)">
                        <xsl:attribute name="data-language">
                            <xsl:value-of select="@language"/>
                        </xsl:attribute>
                    </xsl:if>
                    <!-- default is to randomize, so only set -->
                    <!-- to "false" when explicitly requested -->
                    <xsl:attribute name="data-randomize">
                        <xsl:choose>
                            <xsl:when test="$b-randomize">
                                <xsl:text>true</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>false</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <!-- default is to not allow reuse, so only  -->
                    <!-- set to "true" when explicitly requested -->
                    <xsl:attribute name="data-reuse">
                        <xsl:choose>
                            <xsl:when test="$b-reuse">
                                <xsl:text>true</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>false</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <!-- the @blockanswer attribute is a space-separated  -->
                    <!-- list of the block numbers, *in the order listed  -->
                    <!-- in the HTML* (see below), starting at zero, that -->
                    <!-- consitutes a correct answer.  But the authored   -->
                    <!-- order is the corrrect answer, so we loop over    -->
                    <!-- those blocks as we determine positions/locations -->
                    <!-- in the HTML list.                                -->
                    <!-- NB: the "blockanswer" appears to be parsed based  -->
                    <!-- on *exactly* one space between separating indices -->
                    <xsl:variable name="blockanswer">
                        <!-- answer is list as long as authored blocks, -->
                        <!-- so loop over authored in every case        -->
                        <xsl:for-each select="$authored-blocks">
                            <!-- save off the block in question before context shifts below -->
                            <xsl:variable name="the-block" select="."/>
                            <xsl:choose>
                                <!-- Randomized or not (below), a distractor is a distractor  -->
                                <!-- and does not go in the "blockanswer" attribute. -->
                                <xsl:when test="@correct = 'no'"/>
                                <!-- For the randomized case the answer is list of       -->
                                <!-- non-negative integers in order, but interrupted     -->
                                <!-- by duplicates authored as references as references. -->
                                <xsl:when test="$b-randomize">
                                    <xsl:choose>
                                        <!-- placeholder/pointer/resuse, locate origin -->
                                        <xsl:when test="@ref">
                                            <xsl:variable name="target" select="id(@ref)"/>
                                            <!-- error-check $target here? -->
                                            <xsl:for-each select="$unique-blocks">
                                                <xsl:if test="count(.|$target) = 1">
                                                    <xsl:value-of select="position() - 1"/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <!-- "original" block, count place among originals -->
                                        <xsl:otherwise>
                                            <xsl:for-each select="$unique-blocks">
                                                <xsl:if test="count(.|$the-block) = 1">
                                                    <xsl:value-of select="position() - 1"/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <!-- For the fixed rearrangement case, the blocks are    -->
                                <!-- rearranged in the HTML, so we re-create that        -->
                                <!-- order when determining the location/number of any   -->
                                <!-- given block.  The "choose" stanza here is identical -->
                                <!-- to the above, except the unique blocks are sorted   -->
                                <!-- into their HTML order.  (Can't see how to vary an   -->
                                <!-- unsorted list versus a sorted list as a parameter   -->
                                <!-- to remove duplication.)                             -->
                                <xsl:otherwise>
                                    <xsl:choose>
                                        <!-- placeholder/pointer/resuse, locate origin -->
                                        <xsl:when test="@ref">
                                            <xsl:variable name="target" select="id(@ref)"/>
                                            <!-- error-check $target here? -->
                                            <xsl:for-each select="$unique-blocks">
                                                <xsl:sort select="@order"/>
                                                <xsl:if test="count(.|$target) = 1">
                                                    <xsl:value-of select="position() - 1"/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <!-- "original" block, count place among originals -->
                                        <xsl:otherwise>
                                            <xsl:for-each select="$unique-blocks">
                                                <xsl:sort select="@order"/>
                                                <xsl:if test="count(.|$the-block) = 1">
                                                    <xsl:value-of select="position() - 1"/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- space-separated list, per block, one extra at the very end -->
                            <!-- when a distractor is skipped, do not place a separator     -->
                            <xsl:if test="not(@correct= 'no')">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>
                    <!-- strip an extra space separator created just above -->
                    <xsl:attribute name="data-blockanswer">
                        <xsl:value-of select="substring($blockanswer, 1, string-length($blockanswer) - 1)"/>
                    </xsl:attribute>
                    <!-- blocks themselves, left justified on margin      -->
                    <!-- reused blocks are not presented, distractors are -->
                    <!-- leading newline is just cosmetic                 -->
                    <xsl:text>&#xa;--blocks--&#xa;</xsl:text>
                    <xsl:choose>
                        <!-- just go with authored order as canonical -->
                        <xsl:when test="$b-randomize">
                            <xsl:apply-templates select="$unique-blocks" mode="horizontal-blocks"/>
                        </xsl:when>
                        <!-- sort by the order provided  by author -->
                        <xsl:otherwise>
                            <xsl:for-each select="$unique-blocks">
                                <xsl:sort select="@order"/>
                                <xsl:apply-templates select="." mode="horizontal-blocks"/>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- a block of unit tests for automatic feedback (with, say, an SQL database) -->
                    <xsl:if test="tests">
                        <xsl:text>--unittest--&#xa;</xsl:text>
                        <xsl:call-template name="sanitize-text">
                            <xsl:with-param name="text" select="tests" />
                        </xsl:call-template>
                    </xsl:if>
                </textarea>
            </div>
        </div>
    </div>
</xsl:template>

<!-- Assumes a "tight" run of text, or a "c", no newlines authored. -->
<!-- Non-reused block.  Perhaps text should be massaged here?       -->
<!-- We do not ever dump duplicates into HTML or to the reader      -->
<xsl:template match="blocks/block[not(@ref)]" mode="horizontal-blocks">
    <xsl:apply-templates select="."/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Matching Problem -->

<xsl:template match="*[@exercise-interactive = 'matching']" mode="runestone-to-interactive">
    <xsl:variable name="html-id">
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:variable>
    <div class="ptx-runestone-container">
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
    </div>
</xsl:template>

<!-- Clickable Area Problem -->

<xsl:template match="*[@exercise-interactive = 'clickablearea']" mode="runestone-to-interactive">
    <xsl:variable name="html-id">
        <xsl:apply-templates select="." mode="runestone-id"/>
    </xsl:variable>
    <div class="ptx-runestone-container">
        <div class="runestone">
            <div data-component="clickablearea" data-question_label="" style="visibility: hidden;">
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
<xsl:template match="*[@exercise-interactive = 'fillin-basic']" mode="runestone-to-interactive">
    <div class="ptx-runestone-container">
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
    <!-- the actual form fill-in, with hint and width -->
    <input type="text" placeholder="{$placeholder-hint}">
        <xsl:if test="@width">
            <xsl:attribute name="size">
                <xsl:value-of select="@width"/>
            </xsl:attribute>
        </xsl:if>
    </input>
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

<xsl:template match="*[@exercise-interactive = 'coding']" mode="runestone-to-interactive">
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
<xsl:template match="*[@exercise-interactive = 'shortanswer']" mode="runestone-to-interactive">
    <xsl:choose>
        <xsl:when test="$b-host-runestone or ($short-answer-responses = 'always')">
            <!-- when "response" has attributes, perhaps they get interpreted here -->
            <div class="ptx-runestone-container">
                <div class="runestone">
                    <div data-component="shortanswer" data-question_label="" class="journal" data-mathjax="">
                        <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                        <!-- showing a box, but it can't be graded, so warn reader -->
                        <xsl:if test="not($b-host-runestone)">
                            <xsl:attribute name="data-placeholder">
                                <xsl:text>You can write here, and it will be saved on this device, but your response will not be graded.</xsl:text>
                            </xsl:attribute>
                        </xsl:if>
                        <!-- Author can indicate problem expects an  -->
                        <!-- attachment. Effectively, default is no. -->
                        <xsl:if test="(@attachment = 'yes') and $b-host-runestone">
                            <xsl:attribute name="data-attachment"/>
                        </xsl:if>
                        <xsl:apply-templates select="statement"/>
                    </div>
                </div>
            </div>
        </xsl:when>
        <xsl:otherwise>
            <!-- pointless to do fancy outside of a server/LMS situation -->
            <xsl:apply-templates select="statement"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- YouTube Video -->
<!-- When hosted on a Runestone server, we use a different embedding  -->
<!-- for a YouTube video (only), which allows using a YouTube API for -->
<!-- monitoring events from readers.  We have to pass in an actual    -->
<!-- height and width (in pixels) for semi-custom attributes here.    -->
<!-- Many PreTeXt video features (like posters) are lost.             -->
<!-- The Runestone JavaScript will automatically include the          -->
<!-- player_api JavaScript after it has set up the appropriate        -->
<!-- events such as API loaded.                                       -->

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
            <div class="ptx-runestone-container">
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
                            <!-- allow @datafile attribute on <program> -->
                            <xsl:if test="@datafile">
                                <!-- multiple files, coma- or space- separated -->
                                <xsl:variable name="tokens" select="str:tokenize(@datafile, ', ')"/>
                                <xsl:attribute name="data-datafile">
                                    <xsl:for-each select="$tokens">
                                        <xsl:value-of select="."/>
                                        <!-- n - 1 separators, required by receiving Javascript -->
                                        <!-- comma-separated this time                          -->
                                        <xsl:if test="following-sibling::token">
                                            <xsl:text>,</xsl:text>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:attribute>
                            </xsl:if>
                            <!-- allow @include attribute on <program> -->
                            <xsl:if test="@include">
                                <xsl:variable name="tokens" select="str:tokenize(@include, ', ')"/>
                                <xsl:attribute name="data-include">
                                    <xsl:for-each select="$tokens">
                                        <!-- attribute value is an xml:id, get target "program" -->
                                        <xsl:variable name="the-id">
                                            <xsl:value-of select="."/>
                                        </xsl:variable>
                                        <xsl:for-each select="$original">
                                            <xsl:variable name="target" select="id($the-id)"/>
                                            <xsl:if test="not($target)">
                                                <xsl:message>PTX:ERROR:   an included "program" with @xml:id value <xsl:value-of select="$the-id"/> was not found</xsl:message>
                                            </xsl:if>
                                            <!-- build database id of the target -->
                                            <xsl:apply-templates select="$target" mode="runestone-id"/>
                                            <!-- n - 1 separators, required by receiving Javascript -->
                                        </xsl:for-each>
                                        <!-- space-separated this time -->
                                        <xsl:if test="following-sibling::token">
                                            <xsl:text> </xsl:text>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:attribute>
                            </xsl:if>
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
    <div class="ptx-runestone-container">
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

<!-- Data Files -->
<xsl:template match="datafile" mode="runestone-to-interactive">
    <!-- Some templates and variables are defined in -common for consistency -->

    <!-- If there is a child "pre" element, then we build an un-editable  -->
    <!-- HTML "pre" in the uneditable case and an editable HTML           -->
    <!-- "textarea" in the editable case.  This discintion is mirrored in -->
    <!-- this variable and a subsequent boolean.                          -->
    <xsl:variable name="pre-element">
        <xsl:choose>
            <!-- only a clear "yes" will yield editable, -->
            <!-- default is "no" (or anything but "yes") -->
            <xsl:when test="pre and not(@editable = 'yes')">
                <xsl:text>pre</xsl:text>
            </xsl:when>
            <xsl:when test="pre and (@editable = 'yes')">
                <xsl:text>textarea</xsl:text>
            </xsl:when>
            <!-- safeguard, should not ever be queried -->
            <!-- outside of "pre" in source            -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="b-is-editable" select="$pre-element = 'textarea'"/>

    <!-- The HTML that Runestone expects -->
    <div class="runestone datafile">
        <div class="datafile_caption">
            <code class="code-inline tex2jax_ignore">
                <!-- Internationalize?  See comments in static conversion -->
                <xsl:text>Data: </xsl:text>
                <xsl:value-of select="@filename" />
            </code>
        </div>
        <xsl:choose>
            <xsl:when test="image">
                <!-- filename is relative to author's source -->
                <xsl:variable name="data-filename">
                    <xsl:apply-templates select="."  mode="datafile-filename"/>
                </xsl:variable>
                <xsl:variable name="image-b64-elt" select="document($data-filename, $original)/pi:image-b64"/>
                <img data-component="datafile" data-isimage="true">
                    <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                    <xsl:attribute name="data-filename">
                        <xsl:value-of select="@filename"/>
                    </xsl:attribute>
                    <xsl:attribute name="src">
                        <xsl:text>data:</xsl:text>
                        <xsl:value-of select="$image-b64-elt/@pi:mime-type"/>
                        <xsl:text>;base64,</xsl:text>
                        <xsl:value-of select="$image-b64-elt/@pi:base64"/>
                    </xsl:attribute>
                </img>
            </xsl:when>
            <!-- text, an authored toy example, or a serious external file -->
            <xsl:when test="pre">
                <xsl:element name="{$pre-element}">
                    <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                    <xsl:attribute name="data-component">
                        <xsl:text>datafile</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="data-filename">
                        <xsl:value-of select="@filename"/>
                    </xsl:attribute>
                    <xsl:attribute name="data-edit">
                        <!-- conveniently, value is true/false -->
                        <xsl:value-of select="$b-is-editable"/>
                    </xsl:attribute>
                    <!-- Runestone can only hide non-editable text -->
                    <xsl:if test="(not(@editable = 'yes')) and (@hide = 'yes')">
                        <xsl:attribute name="data-hidden"/>
                    </xsl:if>
                    <xsl:attribute name="data-rows">
                        <xsl:choose>
                            <xsl:when test="@rows">
                                <xsl:value-of select="@rows"/>
                            </xsl:when>
                            <!-- default is 20 rows -->
                            <xsl:otherwise>
                                <xsl:value-of select="$datafile-default-rows"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="data-cols">
                        <xsl:choose>
                            <xsl:when test="@cols">
                                <xsl:value-of select="@cols"/>
                            </xsl:when>
                            <!-- default is 40 columns -->
                            <xsl:otherwise>
                                <xsl:value-of select="$datafile-default-cols"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:apply-templates select="." mode="datafile-text-contents"/>
                </xsl:element>
            </xsl:when>
            <!-- no other source/PTX element is supported , bail out-->
            <xsl:otherwise/>
        </xsl:choose>
    </div>
</xsl:template>

</xsl:stylesheet>
