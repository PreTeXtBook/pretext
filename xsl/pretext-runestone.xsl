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

<!-- ######################## -->
<!-- Runestone Infrastructure -->
<!-- ######################## -->

<!-- Runestone Services -->
<!-- Runestone provides universally-applicable Javascript, and since Brad Miller -->
<!-- is "such a nice guy" he provides an XML version of the necessary files.     -->
<!-- These are obtained/created/analyzed in the Python script. The structure     -->
<!-- of this file is pretty simple, and should be apparent to the cognescenti.   -->

<!-- The content of the services file  is provided via                 -->
<!-- string parameters passed into this stylesheet. The purpose is to  -->
<!-- allow the core Python routines to query the Runestone server for  -->
<!-- the *very latest* services file available online. This is meant   -->
<!-- to be a totally automated operation, so parameter names are not   -->
<!-- always human-friendly.  Sometimes these parameters are provided   -->
<!-- from alternate sources due to some debugging mode being employed. -->
<!-- See the Python script for more detail.                            -->
<xsl:param name="rs-js" select="''"/>
<xsl:param name="rs-css" select="''"/>
<xsl:param name="rs-version" select="''"/>

<!-- The Runestone Services version actually in use is -->
<!-- needed several places, so we compute it once now. -->
<!-- Manifest, two "ebookConfig".                      -->
<xsl:variable name="runestone-version">
    <xsl:value-of select="$rs-version"/>
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

            <!-- Ethical Ads: only on Runestone server, only visible in -->
            <!-- *non-login* versions of books hosted at Runestone      -->
            <script src="https://media.ethicalads.io/media/client/ethicalads.min.js"/>

        </xsl:when>
        <!-- Runestone for All build -->
        <!-- Hosted without a Runestone Server, just using Javascript -->
        <xsl:when test="not($b-host-runestone)">
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

    <!-- The Runestone Services file typically contains multiple filenames    -->
    <!-- for Javascript and CSS (like two or three).                          -->
    <!-- We expect the two string parameters to be lists delimited by a colon -->
    <!-- (':'), so this character should not ever appear in the filenames.    -->
    <!-- Note: these variables will be vacuous when the string parameters are -->
    <!-- empty strings, and then will not ever be employed                    -->
    <xsl:variable name="rs-js-tokens" select="str:tokenize($rs-js, ':')"/>
    <xsl:variable name="rs-css-tokens" select="str:tokenize($rs-css, ':')"/>

    <!-- Javascript and CSS "master" links/pointers into _static -->
    <xsl:comment>*** Runestone Services ***</xsl:comment>
    <xsl:text>&#xa;</xsl:text>
    <xsl:for-each select="$rs-js-tokens">
        <script>
            <xsl:attribute name="src">
                <xsl:value-of select="$cdn-prefix"/>
                <xsl:text>_static/</xsl:text>
                <xsl:value-of select="."/>
            </xsl:attribute>
        </script>
    </xsl:for-each>
    <xsl:for-each select="$rs-css-tokens">
        <link rel="stylesheet" type="text/css">
            <xsl:attribute name="href">
                <xsl:value-of select="$cdn-prefix"/>
                <xsl:text>_static/</xsl:text>
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
        <button class="runestone-profile dropdown button" title="Profile">
            <xsl:call-template name="insert-symbol">
                <xsl:with-param name="name" select="'person'"/>
            </xsl:call-template>
            <span class="name"><xsl:text>Profile</xsl:text></span>
            <div class="dropdown-content">
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>{% if settings.academy_mode: %}&#xa;</xsl:text>
                <a href="/ns/course/index">Course Home</a>
                <a href="/runestone/assignments/chooseAssignment">Assignments</a>
                <a href="/runestone/assignments/practice">Practice</a>
                <hr/>
                <!-- NB: next two entries were once templated with "appname" and           -->
                <!-- the requisite spaces were percent-encoded by XSLT since it is         -->
                <!-- known to be forming a  a/@href.                                       -->
                <!-- Short-term fix: hard-code "runestone" as the appname, which should    -->
                <!-- migrate to "assignment" when peer-instruction code moves.             -->
                <!-- Long-term might suggest some XSL variables for the names of the apps. -->
                <!-- if reader is not an instructor the next link will be removed by javascript -->
                <a id="inst_peer_link" href="/runestone/peer/instructor.html">Peer Instruction (Instructor)</a>
                <a href="/runestone/peer/student.html">Peer Instruction (Student)</a>
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
        </button>
    </xsl:if>
</xsl:template>

<!-- Scratch ActiveCode window, for all builds (powered by Runestone   -->
<!-- Javascript).  But more languages available on a Runestone server. -->
<!-- Only if requested, explicitly or implicitly, via publisher file.  -->
<!-- Unicode Character 'PENCIL' (U+270F)                               -->
<xsl:template name="runestone-scratch-activecode">
    <xsl:if test="$b-has-scratch-activecode">
        <button onclick="runestoneComponents.popupScratchAC()" class="activecode-toggle button" title="Open Scratch ActiveCode">
            <xsl:call-template name="insert-symbol">
                <xsl:with-param name="name" select="'edit'"/>
            </xsl:call-template>
            <span class="name">Scratch ActiveCode</span>
        </button>
    </xsl:if>
</xsl:template>

<!-- A convenience for attaching a Runestone id -->
<!-- NB: we attempt to only use this template in this stylesheet. -->
<!-- To enforce this, we *could* make a no-op, plus warning,      -->
<!-- template in the "pretext-html" stylesheet, with this         -->
<!-- implementation doing an overide.                             -->
<xsl:template match="exercise|program|datafile|query|&PROJECT-LIKE;|task|video[@youtube]|exercises|worksheet|interactive[@platform = 'doenetml']" mode="runestone-id-attribute">
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

<!-- A timed exam requires markup that wraps an entire collection -->
<!-- of exercises, so we pass the exercises in as a parameter     -->
<xsl:template match="exercises" mode="runestone-timed-exam">
    <xsl:param name="the-exercises"/>

    <!-- Since the component wraps the exercises, we do not need any  -->
    <!-- restriction about being at teh Runestone "subchapter" level. -->
    <xsl:if test="$b-host-runestone">
        <div class="timedAssessment">
            <ul data-component="timedAssessment" data-question_label="">
                <!-- a Runestone id -->
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <!-- one mandatory attribute -->
                <xsl:attribute name="data-time">
                    <xsl:value-of select="@time-limit"/>
                </xsl:attribute>
                <!-- result, timer, feedback, pause are *on* by  -->
                <!-- default if a PreTeXt attribute is "no" then -->
                <!-- issue empty "data-no-*" Runestone attribute -->
                <xsl:if test="@results = 'no'">
                    <xsl:attribute name="data-no-result"/>
                </xsl:if>
                <xsl:if test="@timer = 'no'">
                    <xsl:attribute name="data-no-timer"/>
                </xsl:if>
                <xsl:if test="@feedback = 'no'">
                    <xsl:attribute name="data-no-feedback"/>
                </xsl:if>
                <xsl:if test="@pause = 'no'">
                    <xsl:attribute name="data-no-pause"/>
                </xsl:if>
                <!-- the actual list of exercises -->
                <xsl:copy-of select="$the-exercises"/>
                <!-- only at "section" level. only when building for a Runestone server -->
                <xsl:apply-templates select="." mode="runestone-progress-indicator"/>
            </ul>
        </div>
    </xsl:if>
</xsl:template>

<!-- An "exercises" division can be a group work exercise, by virtue -->
<!-- of selection and submission features at the bottom of the page. -->
<xsl:template match="exercises|worksheet" mode="runestone-groupwork">
    <div class="runestone">
        <div data-component="groupsub">
            <!-- the Runestone id -->
            <xsl:apply-templates select="." mode="runestone-id-attribute"/>
            <xsl:attribute name="data-size_limit">
                <xsl:choose>
                    <xsl:when test="@groupsize">
                        <xsl:value-of select="@groupsize"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>3</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <!-- students select their partners in their group -->
            <div>
                <select multiple="" class="assignment_partner_select"  style="width: 100%"/>
            </div>
            <!-- and a submit button once done -->
            <div class="groupsub_button"/>
            <div class="para">The Submit Group button will submit the answer for each each question on this page for each member of your group. It also logs you as the official group submitter.</div>
        </div>
    </div>
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
            <!-- default programming language for book as specified in docinfo -->
            <!-- if not specified, assume python                               -->
            <default-language>
                <xsl:choose>
                    <xsl:when test="$default-active-programming-language != ''">
                        <xsl:value-of select="$default-active-programming-language"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>python</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </default-language>
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
                    <!-- global variables defined in -common -->
                    <xsl:attribute name="edition">
                        <xsl:value-of select="$edition"/>
                    </xsl:attribute>
                    <xsl:value-of select="$document-id"/>
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
            <!-- Report major and minor versions from WW so Runestone knows what's up.   -->
            <!-- These variables are formed in  -html  and could be empty/blank. Hoever, -->
            <!-- they should always be defined as global variables.                      -->
            <webwork-version major="{$webwork-major-version}" minor="{$webwork-minor-version}"/>
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
        <xsl:apply-templates select=".//exercise|.//project|.//activity|.//exploration|.//investigation|.//video[@youtube]|.//program[(@interactive = 'codelens') and not(parent::exercise)]|.//program[(@interactive = 'activecode') and not(parent::exercise)]|.//datafile|.//interactive[@platform = 'doenetml']" mode="runestone-manifest"/>
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

<xsl:template match="interactive[@platform = 'doenetml']" mode="runestone-manifest-label">
    <label>
        <!-- This is not very informative.  Perhaps look up     -->
        <!-- the tree to find a containing figure with a title  -->
        <!-- TODO: perhaps via a type name -->
        <xsl:text>DoenetML Interactive</xsl:text>
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
<!--   - every cardsort problem "exercise"            -->
<!--   - every matching problem "exercise"            -->
<!--   - every clickable area problem "exercise"      -->
<!--   - every "exercise" with fill-in blanks         -->
<!--   - every "exercise" with additional "program"   -->
<!--   - every "exercise" elected as "shortanswer"    -->
<!--   - every "exercise" with a WeBWorK core         -->
<!--   - every PROJECT-LIKE with additional "program" -->
<!--     NB: "task" does not have "webwork" children  -->
<xsl:template match="exercise[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'matching') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'fillin') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer') or
                               (@exercise-interactive = 'webwork-reps')]
                      |
                      project[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer') or
                               (@exercise-interactive = 'webwork-reps')]
                     |
                     activity[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer') or
                               (@exercise-interactive = 'webwork-reps')]
                     |
                  exploration[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer') or
                               (@exercise-interactive = 'webwork-reps')]
                     |
                investigation[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer') or
                               (@exercise-interactive = 'webwork-reps')]
                     |
                         task[ (@exercise-interactive = 'truefalse') or
                               (@exercise-interactive = 'multiplechoice') or
                               (@exercise-interactive = 'parson') or
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'cardsort') or
                               (@exercise-interactive = 'clickablearea') or
                               (@exercise-interactive = 'select') or
                               (@exercise-interactive = 'fillin-basic') or
                               (@exercise-interactive = 'coding') or
                               (@exercise-interactive = 'shortanswer')]" mode="runestone-manifest">
    <question>
        <!-- A divisional exercise ("exercises/../exercise") is not really   -->
        <!-- a reading activity in the Runestone model, so we flag these     -->
        <!-- exercises as such.  Also, interactive "task" come through here, -->
        <!-- so we need to look to an ancestor to see if the containing      -->
        <!-- "exercise" is divisional. The @optional attribute matches the   -->
        <!-- "optional" flag in the Runestone database.  We simply set the   -->
        <!-- value to "yes" and nevver bother to say "no".  The  only        -->
        <!-- consumer is the import into the Runestone database, so any      -->
        <!-- change needs only coordinate there.                             -->
        <xsl:if test="(@exercise-customization = 'divisional') or
                      (self::task and ancestor::exercise[@exercise-customization = 'divisional'])">
            <xsl:attribute name="optional">
                <xsl:text>yes</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <!-- label is from the "exercise" -->
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <!-- Duplicate, but still should look like original (ID, etc.),  -->
        <!-- not knowled. Solutions are available in the originals, via  -->
        <!-- an "in context" link off the Assignment page                -->
        <htmlsrc>
            <!-- next template produces nothing, unless the  -->
            <!-- "exercise" is in an "exercisegroup" ("eg")  -->
            <xsl:apply-templates select="." mode="eg-introduction"/>
            <xsl:choose>
                <!-- with "webwork" guts, the HTML is exceptional -->
                <xsl:when test="@exercise-interactive = 'webwork-reps'">
                    <xsl:apply-templates select="." mode="webwork-core">
                        <xsl:with-param name="b-original" select="true()"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="."  mode="exercise-components">
                        <xsl:with-param name="b-original" select="true()"/>
                        <xsl:with-param name="block-type" select="'visible'"/>
                        <xsl:with-param name="b-has-statement" select="true()" />
                        <xsl:with-param name="b-has-hint"      select="false()" />
                        <xsl:with-param name="b-has-answer"    select="false()" />
                        <xsl:with-param name="b-has-solution"  select="false()" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </htmlsrc>
    </question>
</xsl:template>

<!-- For an "exercise" divorced from it's "exercisegroup" "introduction", -->
<!-- we pick it up to be part of what is shown to the student on the      -->
<!-- Runestone Assignment page.                                           -->

<xsl:template match="*" mode="eg-introduction"/>

<xsl:template match="exercisegroup/exercise" mode="eg-introduction">
    <xsl:apply-templates select="parent::exercisegroup/introduction"/>
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
    <xsl:attribute name="optional">
        <xsl:text>yes</xsl:text>
    </xsl:attribute>
        <!-- label is from the "program", or enclosing "listing" -->
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <htmlsrc>
            <xsl:apply-templates select="." mode="runestone-to-interactive"/>
        </htmlsrc>
    </question>
</xsl:template>

<xsl:template match="interactive[@platform = 'doenetml']" mode="runestone-manifest">
    <question>
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <htmlsrc>
            <xsl:apply-templates select="." mode="interactive-core"/>
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
    <div class="ptx-runestone-container">
        <div class="runestone multiplechoice_section">
            <!-- ul can have multiple answer attribute -->
            <ul data-component="multiplechoice" data-multipleanswers="false">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <!-- Q: the statement is not a list item, but appears *inside* the list? -->
                <!-- overall statement, not per-choice -->
                <xsl:apply-templates select="statement"/>
                <!-- radio button for True -->
                <li data-component="answer">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="runestone-id"/>
                        <xsl:text>_opt_t</xsl:text>
                    </xsl:attribute>
                    <!-- Correct answer if problem statement is correct/True -->
                    <xsl:if test="statement/@correct = 'yes'">
                        <xsl:attribute name="data-correct"/>
                    </xsl:if>
                    <p>True.</p>
                </li>
                <li data-component="feedback">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="runestone-id"/>
                        <xsl:text>_opt_t</xsl:text>
                    </xsl:attribute>
                    <!-- identical feedback for each reader responses -->
                    <xsl:apply-templates select="feedback"/>
                </li>
                <!-- radio button for False -->
                <li data-component="answer">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="runestone-id"/>
                        <xsl:text>_opt_f</xsl:text>
                    </xsl:attribute>
                    <!-- Correct answer if problem statement is incorrect/False -->
                    <xsl:if test="statement/@correct = 'no'">
                        <xsl:attribute name="data-correct"/>
                    </xsl:if>
                    <p>False.</p>
                </li>
                <li data-component="feedback">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="runestone-id"/>
                        <xsl:text>_opt_f</xsl:text>
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
    <div class="ptx-runestone-container">
        <div class="runestone multiplechoice_section">
            <!-- ul can have multiple answer attribute -->
            <ul data-component="multiplechoice">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
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
                    <xsl:with-param name="the-id">
                        <xsl:apply-templates select="." mode="runestone-id"/>
                    </xsl:with-param>
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
    <!-- active-language only used if runnable but needed multiple places -->
    <xsl:variable name="active-language">
        <xsl:apply-templates select="." mode="active-language"/>
    </xsl:variable>
    <!-- determine this option before context switches -->
    <xsl:variable name="b-natural" select="($active-language = '') or ($active-language = 'natural')"/>
    <div class="ptx-runestone-container">
        <div class="runestone parsons_section" style="max-width: none;">
            <div data-component="parsons" class="parsons">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <div class="parsons_question parsons-text" >
                    <!-- the prompt -->
                    <xsl:apply-templates select="statement"/>
                </div>
                <pre class="parsonsblocks" data-question_label="" style="visibility: hidden;">
                    <!-- presence of a program implies runnable when completed -->
                    <xsl:if test="program">
                        <xsl:choose>
                            <xsl:when test="$active-language != ''">
                                <xsl:attribute name="data-runnable">
                                    <xsl:text>true</xsl:text>
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="id">
                                    <xsl:apply-templates select="." mode="unique-id"/>
                                </xsl:variable>
                                <xsl:message>PTX:WARNING:  Parsons problems need a @langauge that is a valid activecode language to be runnable</xsl:message>
                                <xsl:message>              id: <xsl:value-of select="$id"></xsl:value-of></xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    <!-- author opts-in to adaptive problems -->
                    <xsl:attribute name="data-language">
                        <xsl:choose>
                            <xsl:when test="$b-natural">
                                <xsl:text>natural</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- must now have a language -->
                                <xsl:value-of select="$active-language"/>
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
                    <xsl:if test="blocks/block/@depends">
                        <xsl:attribute name="data-grader">
                            <xsl:text>dag</xsl:text>
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
            <xsl:if test="program">
                <!-- Parsons is executable when finished -->
                <div style="display: none">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="runestone-id"/>
                        <xsl:text>-runnable</xsl:text>
                    </xsl:attribute>
                    <div data-component="parsons-runnable">
                    <textarea data-lang="{$active-language}" data-audio="" data-coach="true" style="visibility: hidden;">
                        <xsl:variable name="hosting">
                            <xsl:apply-templates select="." mode="activecode-host"/>
                        </xsl:variable>
                        <!-- loop just to set context. program should be single -->
                        <xsl:for-each select="program">
                            <xsl:call-template name="runestone-activecode-editor-attributes">
                                <xsl:with-param name="active-language" select="$active-language"/>
                                <xsl:with-param name="hosting" select="$hosting"/>
                            </xsl:call-template>
                        </xsl:for-each>
                        <!-- the content -->
                        <xsl:text>&#xa;</xsl:text>
                        <xsl:call-template name="add-indentation">
                            <xsl:with-param name="text">
                                <xsl:call-template name="sanitize-text">
                                    <xsl:with-param name="text" select="program-preamble"/>
                                    <xsl:with-param name="preserve-end" select="true()"/>
                                </xsl:call-template>
                            </xsl:with-param>
                            <xsl:with-param name="indent"><xsl:value-of select="program-preamble/@indent"/></xsl:with-param>
                        </xsl:call-template>
                        <!-- placeholder for user code -->
                        <xsl:text>==PARSONSCODE==&#xa;</xsl:text>
                        <xsl:call-template name="add-indentation">
                            <xsl:with-param name="text">
                                <xsl:call-template name="sanitize-text">
                                    <xsl:with-param name="text" select="program-postamble"/>
                                    <xsl:with-param name="preserve-start" select="true()"/>
                                </xsl:call-template>
                            </xsl:with-param>
                            <xsl:with-param name="indent"><xsl:value-of select="program-postamble/@indent"/></xsl:with-param>
                        </xsl:call-template>
                    </textarea>
                </div></div>
            </xsl:if>

        </div>
    </div>
</xsl:template>

<xsl:template match="blocks/block" mode="vertical-blocks">
    <xsl:param name="b-natural"/>
    <xsl:variable name="name">
        <xsl:choose>
            <xsl:when test="@name|@depends">
                <xsl:text> #tag:</xsl:text>
                <xsl:value-of select="@name"/>
                <xsl:text>; depends:</xsl:text>
                <xsl:value-of select="str:replace(@depends, ' ', ',')"/>
                <xsl:text>;</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>

    <xsl:choose>
        <xsl:when test="choice">
            <!-- put single correct choice first      -->
            <!-- default on "choice" is  correct="no" -->
            <xsl:apply-templates select="choice[@correct = 'yes']">
                <xsl:with-param name="b-natural" select="$b-natural"/>
                <xsl:with-param name="name" select="$name"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="choice[not(@correct = 'yes')]">
                <xsl:with-param name="b-natural" select="$b-natural"/>
                <xsl:with-param name="name"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="$b-natural">
                    <xsl:apply-templates/>
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
            <xsl:value-of select="$name"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="following-sibling::block">
        <xsl:text>&#xa;---&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="blocks/block/choice">
    <xsl:param name="b-natural"/>
    <xsl:param name="name"/>

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
    <xsl:value-of select="$name"/>
</xsl:template>

<!-- Parsons Problem (Horizontal)-->

<xsl:template  match="*[@exercise-interactive = 'parson-horizontal']" mode="runestone-to-interactive">
    <!-- determine these options before context switches -->
    <xsl:variable name="active-language">
      <xsl:apply-templates select="." mode="active-language"/>
    </xsl:variable>
    <xsl:variable name="b-natural" select="($active-language = '') or ($active-language = 'natural')"/>
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
        <div class="runestone hparsons_section">
            <div data-component="hparsons" class="hparsons_section">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <div class="hp_question">
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
                            <xsl:value-of select="$active-language"/>
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
                            <xsl:apply-templates select="$unique-blocks" mode="horizontal-blocks">
                                <xsl:with-param name="b-natural" select="$b-natural"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <!-- sort by the order provided  by author -->
                        <xsl:otherwise>
                            <xsl:for-each select="$unique-blocks">
                                <xsl:sort select="@order"/>
                                <xsl:apply-templates select="." mode="horizontal-blocks">
                                    <xsl:with-param name="b-natural" select="$b-natural"/>
                                </xsl:apply-templates>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- a block of unit tests for automatic feedback (with, say, an SQL database) -->
                    <!-- NB: could mimic "program/tests" to avoid empty "tests" elements           -->
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
    <xsl:param name="b-natural"/>

    <xsl:choose>
        <xsl:when test="$b-natural">
            <xsl:apply-templates select="."/>
        </xsl:when>
        <!-- Now this a problem with code, requiring a "c" wrapper -->
        <!-- 2023-03-07: can move to warnings or validation-plus, semi-deprecated -->
        <xsl:when test="not(c)">
            <xsl:message>PTX:WARNING:  a block of a horizontal Parson problem with</xsl:message>
            <xsl:message>              code needs to be enclosed in a "c" element</xsl:message>
            <xsl:apply-templates select="."/>
            <xsl:text> (NEEDS "c" ELEMENT)</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="c"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Carsort Problem -->

<xsl:template match="*[@exercise-interactive = 'cardsort']" mode="runestone-to-interactive">
    <div class="ptx-runestone-container">
        <div class="runestone cardsort_section">
            <ul data-component="dragndrop" data-question_label="" style="visibility: hidden;">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <span data-subcomponent="question">
                    <xsl:apply-templates select="statement"/>
                </span>
                <xsl:if test="feedback">
                    <span data-subcomponent="feedback">
                        <xsl:apply-templates select="feedback"/>
                    </span>
                </xsl:if>
                <!-- NB: need to compute Runestone ID in current context -->
                <!-- and save off before changing context with for-each  -->
                <xsl:variable name="rsid">
                    <xsl:apply-templates select="." mode="runestone-id"/>
                </xsl:variable>
                <xsl:for-each select="cardsort/match">

                    <!-- PTX premise = RS draggable -->
                    <!-- may be multiple premise or none -->
                    <xsl:for-each select="premise">
                        <li data-subcomponent="draggable">
                            <xsl:attribute name="id">
                                <xsl:value-of select="$rsid"/>
                                <xsl:text>_drag</xsl:text>
                                <xsl:number count="premise" from="cardsort" level="any"/>
                            </xsl:attribute>
                            <xsl:apply-templates select="parent::match" mode="category-attribute"/>
                            <xsl:apply-templates select="."/>
                        </li>
                    </xsl:for-each>
                    <!-- PTX response = RS dropzone -->
                    <!-- one response, or none -->
                    <xsl:for-each select="response">
                        <li data-subcomponent="dropzone">
                            <xsl:attribute name="for">
                                <xsl:value-of select="$rsid"/>
                                <xsl:text>_drag</xsl:text>
                                <xsl:number count="response" from="cardsort" level="any"/>
                            </xsl:attribute>
                            <xsl:apply-templates select="parent::match" mode="category-attribute"/>
                            <xsl:apply-templates select="."/>
                        </li>
                    </xsl:for-each>
                </xsl:for-each>
            </ul>
        </div>
    </div>
</xsl:template>

<!-- A "category" is simply the sequence number of an     -->
<!-- enclosing "match" element, which serves to group     -->
<!-- any number of "premise" with zero or one "response", -->
<!-- indicating they have a relationship (they match!).   -->
<xsl:template match="match" mode="category-attribute">
    <xsl:attribute name="data-category">
        <!-- no @count, then implies count="match" (peers),   -->
        <!-- from="cardsort", while @level="single" is default -->
        <xsl:number/>
    </xsl:attribute>
</xsl:template>

<!-- Matching Problem -->

<xsl:template match="*[@exercise-interactive = 'matching']" mode="runestone-to-interactive">
    <div class="ptx-runestone-container">
        <div data-component="matching" class="runestone">
            <xsl:apply-templates select="." mode="runestone-id-attribute"/>
            <script type="text/xml">
                <!-- one-off XML for Runestone JS to consume -->
                <matching>
                    <!-- provide the authored statement of the exercise -->
                    <statement>
                        <xsl:apply-templates select="statement"/>
                    </statement>
                    <!-- "feedback" is for the interactive interface -->
                    <!-- to show to the reader at the right time     -->
                    <feedback>
                        <xsl:apply-templates select="feedback"/>
                    </feedback>
                    <!-- sequence of "premise" -->
                    <xsl:apply-templates select="matching/premise" mode="node-info"/>
                    <!-- sequence of "response" -->
                    <xsl:apply-templates select="matching/response" mode="node-info"/>
                    <!-- sequence of "edge" -->
                    <xsl:apply-templates select="matching" mode="matching-adjacencies"/>
                </matching>
            </script>
        </div>
    </div>
</xsl:template>

<!-- utility template to create unique ID for each premise and       -->
<!-- response for use in the user interface, invisible to the reader -->
<xsl:template match="matching/premise|matching/response" mode="matching-identification">
    <xsl:value-of select="parent::matching/parent::*/@label"/>
    <xsl:text>-</xsl:text>
    <xsl:choose>
        <xsl:when test="self::premise">
            <xsl:text>p</xsl:text>
        </xsl:when>
        <xsl:when test="self::response">
            <xsl:text>r</xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- counts among elements of current type -->
    <xsl:number/>
</xsl:template>

<xsl:template match="premise|response" mode="node-info">
    <xsl:variable name="element-name" select="local-name(.)"/>
    <xsl:element name="{$element-name}">
        <id>
            <xsl:apply-templates select="." mode="matching-identification"/>
        </id>
        <label>
            <xsl:apply-templates select="."/>
        </label>
    </xsl:element>
</xsl:template>


<xsl:template match="matching" mode="matching-adjacencies">
    <!-- Run over all response, to see if their single @xml:id -->
    <!-- is present in the premise's multi-valued @ref         -->
    <!-- array of pairs -->
    <xsl:for-each select="premise">
        <!-- save off some "premise" info before context change -->
        <xsl:variable name="the-ref-fenced" select="concat('|', translate(@ref, ' ', '|'), '|')"/>
        <xsl:variable name="the-premise-identification">
            <xsl:apply-templates select="." mode="matching-identification"/>
        </xsl:variable>
        <!-- note context is no longer "matching", so step up -->
        <xsl:for-each select="../response">
            <xsl:variable name="response-xmlid-fenced" select="concat('|', @xml:id, '|')"/>
            <!-- finally, the test for adjacency -->
            <xsl:if test="contains($the-ref-fenced, $response-xmlid-fenced)">
                <!-- a pair, connecting "premise" to "response"-->
                <edge>
                    <label>
                        <!-- "matching-identification", saved off above -->
                        <xsl:value-of select="$the-premise-identification"/>
                    </label>
                    <label>
                        <xsl:apply-templates select="." mode="matching-identification"/>
                    </label>
                </edge>
            </xsl:if>
        </xsl:for-each>
    </xsl:for-each>
</xsl:template>


<!-- Clickable Area Problem -->

<xsl:template match="*[@exercise-interactive = 'clickablearea']" mode="runestone-to-interactive">
    <div class="ptx-runestone-container">
        <div class="runestone clickablearea_section">
            <div data-component="clickablearea" data-question_label="" style="visibility: hidden;">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
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

<!-- Select Questions -->

<!-- "Select" questions come in three types                            -->
<!--   * Question List - several equivalent problems,                  -->
<!--     reader is assigned just one (good for exams)                  -->
<!--   * A/B Experiment - two choices, experiment managed by Runestone -->
<xsl:template match="*[@exercise-interactive = 'select']" mode="runestone-to-interactive">
    <div class="runestone sqcontainer selectquestion_section">
        <div data-component="selectquestion" data-points="1" data-limit-basecourse="false">
            <xsl:apply-templates select="." mode="runestone-id-attribute"/>
            <!-- condition on an attribute of the "select" element -->
            <xsl:choose>
                <xsl:when test="select/@questions">
                    <xsl:attribute name="data-questionlist">
                        <xsl:call-template name="runestone-targets">
                            <xsl:with-param name="id-list" select="select/@questions"/>
                            <xsl:with-param name="separator" select="', '"/>
                        </xsl:call-template>
                    </xsl:attribute>
                    <p>Loading a dynamic question-list question...</p>
                </xsl:when>
                <xsl:when test="select/@ab-experiment">
                    <xsl:attribute name="data-ab">
                        <xsl:value-of select="select/@experiment-name"/>
                    </xsl:attribute>
                    <xsl:attribute name="data-questionlist">
                        <xsl:call-template name="runestone-targets">
                          <xsl:with-param name="id-list" select="select/@ab-experiment"/>
                          <xsl:with-param name="separator" select="', '"/>
                        </xsl:call-template>
                    </xsl:attribute>
                    <p>Loading a dynamic A/B question...</p>
                </xsl:when>
            </xsl:choose>
        </div>
    </div>
</xsl:template>


<!-- Fill-in-the-Blanks problem -->

<!-- Runestone structure -->
<xsl:template match="*[@exercise-interactive = 'fillin-basic']" mode="runestone-to-interactive">
    <div class="ptx-runestone-container">
        <div class="runestone fillintheblank_section">
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
                <div class="runestone shortanswer_section">
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

    <div class="ptx-runestone-container">
        <div class="runestone yt_section">
            <div id="{$hid}" data-component="youtube" class="align-left youtube-video"
                 data-video-height="{$height}" data-video-width="{$width}"
                 data-video-videoid="{@youtube}" data-video-divid="{$hid}"
                 data-video-start="0" data-video-end="-1"/>
        </div>
    </div>
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
    <xsl:variable name="rsid">
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
                            <xsl:value-of select="$rsid"/>
                        </xsl:attribute>
                        <!-- filename used for this data if another program makes use of it -->
                        <!-- via add-files                                                  -->
                        <xsl:if test="@filename">
                            <xsl:attribute name="data-filename">
                                <xsl:value-of select="@filename"/>
                            </xsl:attribute>
                        </xsl:if>
                        <!-- add some lead-in text to the window -->
                        <xsl:if test="$exercise-statement">
                            <div class="ac_question">
                                <xsl:attribute name="id">
                                    <xsl:value-of select="$rsid"/>
                                    <xsl:text>_question</xsl:text>
                                </xsl:attribute>
                                <xsl:apply-templates select="$exercise-statement"/>
                            </div>
                        </xsl:if>
                        <textarea data-lang="{$active-language}" data-audio="" data-coach="true" style="visibility: hidden;">
                            <xsl:if test="stdin">
                                <xsl:attribute name="data-stdin">
                                    <xsl:call-template name="sanitize-text">
                                        <xsl:with-param name="text" select="stdin" />
                                    </xsl:call-template>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:attribute name="id">
                                <xsl:value-of select="$rsid"/>
                                <xsl:text>_editor</xsl:text>
                            </xsl:attribute>
                            <!-- conditional attributes shared with parsons activecodes -->
                            <xsl:call-template name="runestone-activecode-editor-attributes">
                                <xsl:with-param name="active-language" select="$active-language"/>
                                <xsl:with-param name="hosting" select="$hosting"/>
                            </xsl:call-template>
                            <!-- this is a bit awful, but we need to figure out how much margin -->
                            <!-- to add to runestone dividers. So preassemble program for       -->
                            <!-- computation and then discard                                   -->
                            <xsl:variable name="program-left-margin">
                                <xsl:variable name="raw-program-text">
                                    <xsl:value-of select="preamble"/>
                                    <xsl:value-of select="code"/>
                                    <xsl:value-of select="postamble"/>
                                </xsl:variable>
                                <xsl:variable name="trimmed-program-text">
                                    <xsl:call-template name="trim-start-lines">
                                        <xsl:with-param name="text">
                                            <xsl:call-template name="trim-end">
                                                <xsl:with-param name="text" select="$raw-program-text" />
                                            </xsl:call-template>
                                        </xsl:with-param>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:call-template name="left-margin">
                                  <xsl:with-param name="text" select="$trimmed-program-text" />
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:variable name="left-margin-string">
                                <xsl:value-of select="str:padding($program-left-margin, ' ')" />
                            </xsl:variable>
                            <xsl:variable name="program-text">
                                <xsl:for-each select="preamble">
                                    <!-- only expect one, for-each just for binding -->
                                    <xsl:call-template name="substring-before-last">
                                        <xsl:with-param name="input" select="." />
                                        <xsl:with-param name="substr" select="'&#xA;'" />
                                    </xsl:call-template>
                                    <xsl:text>&#xa;</xsl:text>
                                    <xsl:value-of select="$left-margin-string"/>
                                    <xsl:choose>
                                        <xsl:when test='@visible = "no"'>
                                            <xsl:text>^^^^</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>^^^!</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                                <xsl:call-template name="substring-before-last">
                                    <xsl:with-param name="input" select="code" />
                                    <xsl:with-param name="substr" select="'&#xA;'" />
                                </xsl:call-template>
                                <xsl:text>&#xA;</xsl:text>
                                <xsl:for-each select="postamble">
                                    <!-- only expect one, for-each just for binding -->
                                    <xsl:value-of select="$left-margin-string"/>
                                    <xsl:choose>
                                        <xsl:when test='@visible = "no"'>
                                            <xsl:text>====&#xa;</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>===!&#xa;</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:value-of select="substring-after(.,'&#xA;')" />
                                </xsl:for-each>
                            </xsl:variable>
                            <!-- assembled code as text -->
                            <xsl:call-template name="sanitize-text">
                                <xsl:with-param name="text" select="$program-text" />
                            </xsl:call-template>
                            <!-- optional unit testing -->
                            <xsl:if test="tests">
                                <!-- Be wary of empty "test" elements which lead to -->
                                <!-- empty files, which are possibly not legal      -->
                                <!-- programs for their target languages, and hence -->
                                <!-- raise errors due to  the Runestone back-end    -->
                                <!-- trying to process them.                        -->
                                <!-- NB: static versions never show "tests" anyway  -->
                                <xsl:variable name="tests-content">
                                    <xsl:call-template name="sanitize-text">
                                        <xsl:with-param name="text" select="tests/text()" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <!-- Even if there is no content, the sanitization -->
                                <!-- template adds a concluding newline            -->
                                <xsl:if test="not(normalize-space($tests-content) = '')">
                                    <xsl:choose>
                                        <xsl:when test="tests[@visible = 'yes']">
                                            <xsl:choose>
                                                <xsl:when test="postamble[@visible = 'no']">
                                                    <xsl:message>PTX:WARNING: There is no support for visible tests after an invisible postamble. (Issue in <xsl:value-of select="$rsid"/>).</xsl:message>
                                                </xsl:when>
                                                <xsl:when test="not(postamble)">
                                                    <!-- need to add header -->
                                                    <xsl:text>===!&#xa;</xsl:text>
                                                </xsl:when>
                                                <!-- otherwise header created by postamble -->
                                            </xsl:choose>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <!-- invisible tests, need header if not after invisible postamble -->
                                            <xsl:if test="not(postamble[@visible = 'no'])">
                                                <xsl:text>====&#xa;</xsl:text>
                                            </xsl:if>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <!-- historical behavior is to use sanitized version -->
                                    <xsl:value-of select="$tests-content"/>
                                </xsl:if>
                                <xsl:if test="tests/iotest">
                                    <xsl:choose>
                                        <xsl:when test="not(normalize-space($tests-content) = '')">
                                            <xsl:message>WARNING: You can either write text based tests or use iotests, but not both. iotests ignored in <xsl:value-of select="$rsid"/>.</xsl:message>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>===iotests===&#x0a;</xsl:text>
                                            <xsl:text>[</xsl:text>
                                            <xsl:for-each select="tests/iotest">
                                                <xsl:text>{"input":"</xsl:text>
                                                <xsl:call-template name="escape-json-string">
                                                    <xsl:with-param name="text">
                                                        <xsl:call-template name="sanitize-text">
                                                            <xsl:with-param name="text">
                                                                <xsl:value-of select="input"/>
                                                            </xsl:with-param>
                                                        </xsl:call-template>
                                                    </xsl:with-param>
                                                </xsl:call-template>
                                                <xsl:text>","out":"</xsl:text>
                                                <xsl:call-template name="escape-json-string">
                                                    <xsl:with-param name="text">
                                                        <xsl:call-template name="sanitize-text">
                                                            <xsl:with-param name="text">
                                                                <xsl:value-of select="output"/>
                                                            </xsl:with-param>
                                                        </xsl:call-template>
                                                    </xsl:with-param>
                                                </xsl:call-template>
                                                <xsl:text>"}</xsl:text>
                                                <xsl:if test="position() != last()">
                                                    <xsl:text>,</xsl:text>
                                                </xsl:if>
                                            </xsl:for-each>
                                            <xsl:text>]&#x0a;</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:if>
                            </xsl:if>
                        </textarea>
                    </div>
                </div>
            </div>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template name="runestone-activecode-editor-attributes">
    <xsl:param name="active-language"/>
    <xsl:param name="hosting"/>
    <xsl:attribute name="data-question_label"/>
    <!-- Code Lens only for certain languages -->
    <xsl:attribute name="data-codelens">
        <xsl:choose>
            <xsl:when test="@codelens = 'no'">
                <xsl:text>false</xsl:text>
            </xsl:when>
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

    <!-- Merge add-files and compile-also, get unique items               -->
    <!-- This will be the list that we use as add-files for the manifest  -->
    <xsl:variable name="all-extra-files">
        <xsl:variable name="id-list">
            <xsl:value-of select="@add-files"/>
            <xsl:if test="@add-files and @compile-also">
                <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:value-of select="@compile-also"/>
        </xsl:variable>
        <xsl:variable name="unique-tokens">
            <xsl:call-template name="unique-token-set">
                <xsl:with-param name="s" select="$id-list"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:for-each select="exsl:node-set($unique-tokens)/token">
            <xsl:value-of select="."/>
            <xsl:if test="following-sibling::token">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>

    <!-- allow @add-files attribute on <program> -->
    <xsl:if test="$all-extra-files != ''">
        <xsl:attribute name="data-add-files">
            <xsl:call-template name="runestone-targets">
                <xsl:with-param name="id-list" select="$all-extra-files"/>
                <xsl:with-param name="separator" select="','"/>
            </xsl:call-template>
        </xsl:attribute>
    </xsl:if>
    <!-- allow @compile-with attribute on <program> -->
    <xsl:if test="@compile-also">
        <xsl:attribute name="data-compile-also">
            <xsl:call-template name="runestone-targets">
                <xsl:with-param name="id-list" select="@compile-also"/>
                <xsl:with-param name="separator" select="','"/>
                <xsl:with-param name="output-field" select="'filename'"/>
            </xsl:call-template>
        </xsl:attribute>
    </xsl:if>
    <!-- allow @include attribute on <program> -->
    <xsl:if test="@include">
        <!-- space-separated this time -->
        <xsl:attribute name="data-include">
            <xsl:call-template name="runestone-targets">
                <xsl:with-param name="id-list" select="@include"/>
                <xsl:with-param name="separator" select="' '"/>
            </xsl:call-template>
        </xsl:attribute>
    </xsl:if>
    <!-- SQL (only) needs an attribute so it can find some code -->
    <xsl:if test="$active-language = 'sql'">
        <xsl:attribute name="data-wasm">
            <xsl:text>/_static</xsl:text>
        </xsl:attribute>
        <!-- A SQL database can be provided for automated  -->
        <!-- testing of correct answers via unit tests.    -->
        <!-- This is a location in the external directory. -->
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
    </xsl:if>
    <!-- interpreter arguments for hosted languages -->
    <xsl:variable name="interpreter-args">
        <xsl:call-template name="get-program-attr-or-default">
            <xsl:with-param name="attr" select="'interpreter-args'"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$interpreter-args != '' and ($hosting = 'jobeserver')">
        <xsl:attribute name="data-interpreterargs">
            <xsl:call-template name="comma-list-to-json-array">
                <xsl:with-param name="list" select="$interpreter-args"/>
            </xsl:call-template>
        </xsl:attribute>
    </xsl:if>
    <!-- compiler arguments for hosted languages -->
    <xsl:variable name="compiler-args">
        <xsl:call-template name="get-program-attr-or-default">
            <xsl:with-param name="attr" select="'compiler-args'"/>
        </xsl:call-template>
    </xsl:variable>
    <!-- extra compiler args, appended to compiler args -->
    <xsl:variable name="extra-compiler-args" select="@extra-compiler-args"/>
    <xsl:if test="($compiler-args != '' or $extra-compiler-args != '') and ($hosting = 'jobeserver')">
        <xsl:variable name="compiler-args-full">
            <xsl:value-of select="$compiler-args"/>
            <xsl:if test="$compiler-args != '' and $extra-compiler-args != ''">
                <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:value-of select="$extra-compiler-args"/>
        </xsl:variable>
        <xsl:attribute name="data-compileargs">
            <xsl:call-template name="comma-list-to-json-array">
                <xsl:with-param name="list" select="$compiler-args-full"/>
            </xsl:call-template>
        </xsl:attribute>
    </xsl:if>
    <!-- linker arguments for hosted languages -->
    <xsl:variable name="linker-args">
        <xsl:call-template name="get-program-attr-or-default">
            <xsl:with-param name="attr" select="'linker-args'"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$linker-args != '' and ($hosting = 'jobeserver')">
        <xsl:attribute name="data-linkargs">
            <xsl:call-template name="comma-list-to-json-array">
                <xsl:with-param name="list" select="$linker-args"/>
            </xsl:call-template>
        </xsl:attribute>
    </xsl:if>
    <!-- timelimit -->
    <xsl:variable name="timelimit">
        <xsl:call-template name="get-program-attr-or-default">
            <xsl:with-param name="attr" select="'timelimit'"/>
            <xsl:with-param name="default" select="'25000'"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$timelimit != ''">
        <xsl:attribute name="data-timelimit">
            <xsl:value-of select="$timelimit"/>
        </xsl:attribute>
    </xsl:if>
    <!-- assorted boolean flags -->
    <xsl:variable name="download">
      <xsl:call-template name="get-program-attr-or-default">
          <xsl:with-param name="attr" select="'download'"/>
          <xsl:with-param name="default" select="''"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$download = 'yes'">
        <xsl:attribute name="data-enabledownload">
            <xsl:text>yes</xsl:text>
        </xsl:attribute>
    </xsl:if>
    <xsl:if test="@autorun = 'yes'">
        <xsl:attribute name="data-autorun">
            <xsl:text>yes</xsl:text>
        </xsl:attribute>
    </xsl:if>
    <xsl:if test="@hidecode = 'yes'">
        <xsl:attribute name="data-hidecode">
            <xsl:text>yes</xsl:text>
        </xsl:attribute>
    </xsl:if>
    <xsl:if test="@chatcodes = 'yes'">
        <xsl:attribute name="data-chatcodes">
            <xsl:text>yes</xsl:text>
        </xsl:attribute>
    </xsl:if>
    <!-- Pass on highlighted line numbering -->
    <xsl:if test="@highlight-lines != ''">
        <xsl:attribute name="data-highlight-lines">
            <!-- force comma-, or space-separated, list to commas -->
            <xsl:value-of select="translate(normalize-space(translate(@highlight-lines, ',', ' ')), ' ', ',')"/>
        </xsl:attribute>
    </xsl:if>
</xsl:template>


<!-- ######## -->
<!-- CodeLens -->
<!-- ######## -->

<xsl:template match="program[@interactive = 'codelens']" mode="runestone-codelens">
    <xsl:variable name="active-language">
      <xsl:apply-templates select="." mode="active-language"/>
    </xsl:variable>
    <!-- as a variable so it does not look like an AVT -->
    <xsl:variable name="parameter-dictionary">
        <xsl:text>{</xsl:text>
        <xsl:text>"embeddedMode": true, </xsl:text>
        <xsl:text>"lang": "</xsl:text>
        <xsl:value-of select="$active-language"/>
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
<!-- N.B. This match could be simply on "program", but a runnable  -->
<!-- Parsons problem may have a @language on it as part of being   -->
<!-- runnable, thus a more liberal match (which could be           -->
<!-- tightened, most likely).                                      -->
<xsl:template match="*" mode="activecode-host">
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
    <!-- Possibly annotate with the source                     -->
    <xsl:apply-templates select="." mode="view-source-widget"/>
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

<!-- ############# -->
<!-- Tabbed Viewer -->
<!-- ############# -->

<!-- Strictly a presentational device, but useful in certain situations  -->
<!-- as a pedogogical device.  But we start with presentation.  An       -->
<!-- "exercise" or PROJECT-LIKE, structured by "task" can have each      -->
<!-- top-level task go into a tab, along with tabs for "introduction"    -->
<!-- and "conclusion".  We *never* do this for worksheets, to avoid      -->
<!-- gumming up printing and spacing.  And WeBWorK problems manage       -->
<!-- their own tasks.  The "match" here is pretty selective for          -->
<!-- "exercise", should perhaps be tighter for PROJECT-LIKE.  Of course, -->
<!-- Runestone Components play nicely with this device, along with more  -->
<!-- boring exercises.                                                   -->

<xsl:template match="exercise[task and not(@exercise-customization = 'worksheet')]|&PROJECT-LIKE;" mode="tabbed-tasks">
    <div class="ptx-runestone-container">
        <div>
            <xsl:attribute name="class">
                <xsl:text>runestone tabbed_section</xsl:text>
                <!-- need to know if it contains an element that wants to be wide in wide layout -->
                <xsl:if test=".//program[@interactive = 'activecode'] or .//program[@interactive = 'codelens'] or .//exercise/blocks">
                    <xsl:text> contains-wide</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <!-- @data-component="tab" do not need an HTML @id for any -->
            <!-- purpose in Runestone (such as, say, tracking activity -->
            <!-- as a reader clicks from tab to tab)                   -->
            <div data-component="tabbedStuff">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <xsl:if test="introduction">
                    <xsl:variable name="the-intro">
                        <xsl:apply-templates select="." mode="type-name">
                            <xsl:with-param name="string-id" select="'introduction'"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <div data-component="tab" data-tabname="{$the-intro}">
                        <xsl:apply-templates select="introduction"/>
                    </div>
                </xsl:if>
                <!--  -->
                <xsl:for-each select="task">
                    <xsl:variable name="the-task-number">
                        <xsl:text>(</xsl:text>
                        <xsl:apply-templates select="." mode="serial-number"/>
                        <xsl:text>)</xsl:text>
                    </xsl:variable>
                    <div data-component="tab" data-tabname="{$the-task-number}">
                        <xsl:apply-templates select="."/>
                    </div>
                </xsl:for-each>
                <!--  -->
                <xsl:if test="conclusion">
                    <xsl:variable name="the-outro">
                        <xsl:apply-templates select="." mode="type-name">
                            <xsl:with-param name="string-id" select="'conclusion'"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <div data-component="tab" data-tabname="{$the-outro}">
                        <xsl:apply-templates select="conclusion"/>
                    </div>
                </xsl:if>
            </div>
        </div>
    </div>
</xsl:template>

<!-- ####### -->
<!-- Queries -->
<!-- ####### -->

<xsl:template match="query" mode="runestone-to-interactive">
    <!-- <xsl:text>FOO</xsl:text> -->
    <xsl:variable name="the-choices" select="choices/choice"/>
    <div class="ptx-runestone-container">
        <div class="runestone">
            <ul data-component="poll">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <xsl:attribute name="data-results">
                    <xsl:choose>
                        <xsl:when test="(@visibility = 'instructor') or (@visibility = 'all')">
                            <xsl:value-of select="@visibility"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>instructor</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:apply-templates select="statement"/>
                <!-- infrastructure to here is common to a query with -->
                <!-- explicit distinct choices, versus a query with a -->
                <!-- simple scale for responses                       -->
                <!-- NB: could define a variable early on indicating  -->
                <!-- the nature of the poll, should there need to be  -->
                <!-- more differentiation                             -->
                <xsl:choose>
                    <xsl:when test="choices">
                        <xsl:apply-templates select="choices/choice"/>
                    </xsl:when>
                    <xsl:when test="foome">
                        <!-- context switch will allow "position()" to behave -->
                        <xsl:for-each select="$the-choices">
                            <li>
                                <span class="poll-choice">
                                    <xsl:value-of select="position()"/>
                                </span>
                                <xsl:apply-templates/>
                            </li>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:when test="@scale">
                        <!-- generate list items with numbers recursively -->
                        <xsl:call-template name="numbered-list-items">
                            <xsl:with-param name="max" select="@scale"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- could add error warning here?  Or rely on schema? -->
                    <xsl:otherwise/>
                </xsl:choose>
            </ul>
        </div>
    </div>
</xsl:template>

<xsl:template match="query/choices/choice">
    <li>
        <!-- <span class="poll-choice">
            <xsl:number/>
        </span> -->
        <xsl:number/>
        <xsl:text>. </xsl:text>
        <xsl:apply-templates/>
    </li>
</xsl:template>

<xsl:template name="numbered-list-items">
    <!-- always initialize with 1 to start -->
    <xsl:param name="current" select="'1'"/>
    <xsl:param name="max"/>

    <xsl:choose>
        <!-- $current is too big, done with recursion -->
        <xsl:when test="$current > $max"/>
        <xsl:otherwise>
            <!-- make numbered list-item -->
            <li>
                <xsl:value-of select="$current"/>
            </li>
            <!-- recurse with next integer -->
            <xsl:call-template name="numbered-list-items">
                <xsl:with-param name="current" select="$current + 1"/>
                <xsl:with-param name="max" select="$max"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

<!-- Interpreter/compiler/linker args all start as comma separated lists "-Wall, -std=c++17" -->
<!-- and need to end up a JSON array of strings: "['-Wall', '-std=c++17']"                   -->
<xsl:template name="comma-list-to-json-array">
    <xsl:param name="list"/>
    <!-- comma separated in PreTeXt source -->
    <xsl:variable name="tokens" select="str:tokenize($list, ',')"/>
    <xsl:text>[</xsl:text>
    <xsl:for-each select="$tokens">
        <xsl:text>'</xsl:text>
        <!-- prune leading/trailing spaces but leave ones in middle -->
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:text>'</xsl:text>
        <xsl:if test="following-sibling::token">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:for-each>
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Runestone components, such as data files and select questions,  -->
<!-- frequently point to other Runestone components in the database. -->
<!--   * Authors point in their source with @xml:id                  -->
<!--     values in a space- or comma- separated list                 -->
<!--   * We locate the targets in the orginal source                 -->
<!--   * Compute the Runestone database id                           -->
<!--   * Return a list (varying separator) to use in Runestone HTML. -->
<xsl:template name="runestone-targets">
    <xsl:param name="id-list"/>
    <xsl:param name="separator" select="'MISSING SEPARATOR'"/>
    <xsl:param name="output-field" select="'runestone-id'"/>

    <!-- comma or space separated in PreTeXt source -->
    <xsl:variable name="tokens" select="str:tokenize($id-list, ', ')"/>
    <xsl:for-each select="$tokens">
        <!-- attribute value is an xml:id, get target interactive -->
        <xsl:variable name="the-id">
            <xsl:value-of select="."/>
        </xsl:variable>
        <!-- context shift so  id()  functions properly -->
        <xsl:for-each select="$original">
            <xsl:variable name="target" select="id($the-id)"/>
            <xsl:if test="not($target)">
                <xsl:message>PTX:ERROR:   an @xml:id value "<xsl:value-of select="$the-id"/>" was used to specify a runestone component but no item with that id exists.</xsl:message>
            </xsl:if>
            <!-- build Runestone database id of the target -->
            <xsl:choose>
                <xsl:when test="$output-field = 'runestone-id'">
                    <xsl:apply-templates select="$target" mode="runestone-id"/>
                </xsl:when>
                <xsl:when test="$output-field = 'filename'">
                    <xsl:value-of select="$target/@filename"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="runestone-id"/>
                    <xsl:message>PTX:ERROR:   runestone-targets template was called with an invalid @output-field value "<xsl:value-of select="$output-field"/>"</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            <!-- n - 1 separators, required by receiving Javascript -->
        </xsl:for-each>
        <xsl:if test="following-sibling::token">
            <xsl:value-of select="$separator"/>
        </xsl:if>
    </xsl:for-each>
</xsl:template>


</xsl:stylesheet>
