<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2015                                                        -->
<!-- Robert A. Beezer, Michael Gage, Geoff Goehle, Alex Jordan             -->
<!--                                                                       -->
<!-- This file is part of MathBook XML.                                    -->
<!--                                                                       -->
<!-- MathBook XML is free software: you can redistribute it and/or modify  -->
<!-- it under the terms of the GNU General Public License as published by  -->
<!-- the Free Software Foundation, either version 2 or version 3 of the    -->
<!-- License (at your option).                                             -->
<!--                                                                       -->
<!-- MathBook XML is distributed in the hope that it will be useful,       -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of        -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         -->
<!-- GNU General Public License for more details.                          -->
<!--                                                                       -->
<!-- You should have received a copy of the GNU General Public License     -->
<!-- along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>. -->
<!-- ********************************************************************* -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<xsl:import href="./mathbook-common.xsl" />
<xsl:include href="./mathbook-webwork-pg.xsl" />

<!-- Intend output to be a PG/PGML problem -->
<xsl:output method="text" />

<!-- ############## -->
<!-- Entry template -->
<!-- ############## -->

<!-- First, create the problem files in directories                           -->
<!-- Organized in directories as in the document tree, cut off at chunk level -->
<!-- Then chunk the document to write reasonable problem definition files     -->
<xsl:template match="/mathbook">
    <xsl:apply-templates mode="problems" />
    <xsl:apply-templates mode="chunk" />
</xsl:template>

<!-- Handle <webwork> element carefully -->
<!-- Recurse into other elements        -->
<xsl:template match="*" mode="problems">
    <xsl:apply-templates select="webwork" mode="problems"/>
    <xsl:apply-templates select="*[not(self::webwork)]" mode="problems" />
</xsl:template>

<!-- Kill non-element content outside of webwork -->
<xsl:template match="text()" mode="problems" />

<!-- Chunking -->

<!-- (a) Making *.def files -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <!-- no problems, no def infos, no file -->
    <xsl:if test="not($content = '')">
        <!-- filenames -->
        <xsl:variable name="def-filename">
            <xsl:text>local/</xsl:text>
            <xsl:call-template name="root-directory" />
            <xsl:text>def/</xsl:text>
            <!-- mandatory filename initial string -->
            <xsl:text>set</xsl:text>
            <xsl:apply-templates select="." mode="numbered-title-filesafe" />
            <xsl:text>.def</xsl:text>
        </xsl:variable>
        <xsl:variable name="header-filename">
            <xsl:text>local/</xsl:text>
            <xsl:call-template name="root-directory" />
            <xsl:text>header/</xsl:text>
            <xsl:apply-templates select="." mode="numbered-title-filesafe" />
            <xsl:text>.pg</xsl:text>
        </xsl:variable>
        <!-- set-definition file -->
        <exsl:document href="{$def-filename}" method="text">
            <xsl:text>openDate          = 01/01/2016 at 12:00am PST&#xa;</xsl:text>
            <xsl:text>dueDate           = 07/01/2016 at 10:00pm PDT&#xa;</xsl:text>
            <xsl:text>answerDate        = 07/01/2016 at 10:00pm PDT&#xa;</xsl:text>
            <xsl:text>paperHeaderFile   = </xsl:text>
            <xsl:value-of select="$header-filename" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>screenHeaderFile  = </xsl:text>
            <xsl:value-of select="$header-filename" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>description       = </xsl:text>
            <xsl:apply-templates select="." mode="title-simple" />
            <xsl:text>&#xa;</xsl:text>
            <!-- Version 1 problem list lead-in -->
            <!-- <xsl:text>problemList       = &#xa;</xsl:text> -->
            <!--                                                -->
            <!-- Version 2 problem list lead-in -->
            <xsl:text>problemListV2&#xa;</xsl:text>
            <xsl:copy-of select="$content" />
        </exsl:document>
        <!-- set-header file -->
        <!-- a bit of a hack to write a second file here -->
        <!-- but we avoid the entire $content used above -->
        <exsl:document href="{$header-filename}" method="text">
            <xsl:apply-templates select="." mode="header-content" />
        </exsl:document>
    </xsl:if>
</xsl:template>

<!-- (b) no content wrapping, default is pass-through -->

<!-- (c) Override intermediate node processing, snag any problems that exist -->
<xsl:template match="*" mode="structure-node-intermediate">
    <xsl:for-each select="*"> <!-- loop over children -->
        <xsl:variable name="structural"> <!-- identify structural -->
            <xsl:apply-templates select="." mode="is-structural" />
        </xsl:variable>
        <xsl:choose>
            <!-- do nothing for structural children                   -->
            <!-- so no need to implement "intermediate-child-summary" -->
            <xsl:when test="$structural = 'true'" />
           <xsl:otherwise>
                <!-- Process non-structural components -->
                <!-- (eg, introduction, conclusion)    -->
                <!-- Write out specific problem info   -->
                <xsl:apply-templates select=".//webwork[@*|node()]" mode="def-info-v2" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
</xsl:template>

<!-- (d) For each child we want webwork info only  -->
<!-- This presumes webwork is in an exercise       -->
<xsl:template match="*" mode="structure-node-child">
    <xsl:apply-templates select=".//webwork[@*|node()]" mode="def-info-v2" />
</xsl:template>


<!-- ################## -->
<!-- Extraction Wrapper -->
<!-- ################## -->

<!-- String for document root, but not docinfo -->
<xsl:template name="root-directory">
    <xsl:for-each select="/mathbook/*">
        <xsl:if test="not(self::docinfo)">
            <xsl:apply-templates select="." mode="numbered-title-filesafe" />
            <xsl:text>/</xsl:text>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<!-- Directory path, recursively climb structural nodes, -->
<!-- record names as pass up throughchunk-level barrier  -->
<!-- Includes root document node (book, article, etc)    -->
<xsl:template match="*" mode="directory-path">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural"/>
    </xsl:variable>
    <xsl:variable name="current-level">
        <xsl:choose>
            <xsl:when test="$structural = 'true'">
                <xsl:apply-templates select="." mode="level" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>undefined</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="self::mathbook" /> <!-- done -->
        <xsl:when test="$structural='false'">  <!-- skip up -->
            <xsl:apply-templates select="parent::*" mode="directory-path" />
        </xsl:when>
        <!-- structural is true now, compare levels -->
        <xsl:when test="$current-level > $chunk-level">  <!-- also skip up -->
            <xsl:apply-templates select="parent::*" mode="directory-path" />
        </xsl:when>
        <xsl:otherwise> <!-- append current node name -->
            <xsl:apply-templates select="parent::*" mode="directory-path" />
            <xsl:apply-templates select="." mode="numbered-title-filesafe" />
            <xsl:text>/</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Append a filename to the directory path              -->
<!-- Include a "local/" prefix for WW directory structure -->
<xsl:template match="webwork" mode="filename">
    <xsl:text>local/</xsl:text>
    <xsl:apply-templates select="." mode="directory-path" />
    <xsl:apply-templates select="parent::exercise" mode="numbered-title-filesafe" />
    <xsl:text>.pg</xsl:text>
</xsl:template>

<!-- For problems from the OPL, just report the @source -->
<xsl:template match="webwork[@source]" mode="filename">
    <xsl:value-of select="@source" />
</xsl:template>

<!-- Extract an authored problem into its own file        -->
<!-- This is a wrapper around the "normal" representation -->
<xsl:template match="webwork" mode="problems">
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <xsl:apply-templates select="." mode="pg" />
    </exsl:document>
</xsl:template>

<!-- OPL problems just get killed, they live on the server already -->
<xsl:template match="webwork[@source]" mode="problems" />

<!-- Version 1 problem info -->
<!-- Each problem gets its own line in the problem set   -->
<!-- definition file. Be careful to create no content if -->
<!-- there are no problems in a subdivision as we employ -->
<!-- non-emptieness up the wrapping chain to ensure      -->
<!--  no trivial problem definition files are created.   -->
<!-- http://webwork.maa.org/wiki/Set_Definition_Files#Version_1 -->
<xsl:template match="webwork[@*|node()]" mode="def-info-v1">
    <xsl:apply-templates select="." mode="filename" />
    <xsl:text>, </xsl:text>
    <xsl:text>1</xsl:text> <!-- default weight -->
    <xsl:text>, </xsl:text>
    <xsl:text>-1</xsl:text> <!-- default max attempts is unlimited -->
    <xsl:text>, </xsl:text>
    <xsl:text></xsl:text> <!-- default SMA is blank -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Version 2 problem info -->
<!-- Each problem gets its own line in the problem set   -->
<!-- definition file. Be careful to create no content if -->
<!-- there are no problems in a subdivision as we employ -->
<!-- non-emptieness up the wrapping chain to ensure      -->
<!--  no trivial problem definition files are created.   -->
<!-- http://webwork.maa.org/wiki/Set_Definition_Files#Version_2 -->
<xsl:template match="webwork[@*|node()]" mode="def-info-v2">
    <xsl:text>problem_start&#xa;</xsl:text>
    <xsl:text>source_file = </xsl:text> <!-- PG file -->
    <xsl:apply-templates select="." mode="filename" />
    <xsl:text>&#xa;</xsl:text>
    <!--Much of the following commented out until we decide we shoudl inclide them.   -->
    <!--WeBWorK provides good default values, customizable by sysadmin or instructor. -->
    <!--<xsl:text>value = 1&#xa;</xsl:text>--> <!-- default problem weight -->
    <!--<xsl:text>max_attempts = -1&#xa;</xsl:text>--> <!-- default max attempts is unlimited -->
    <!--<xsl:text>showMeAnother = -1&#xa;</xsl:text>--> <!-- default SMA is off -->
    <!--<xsl:text>problem_id = </xsl:text>-->
    <!--<xsl:apply-templates select="ancestor::exercise" mode="number" />-->
    <!--<xsl:text>&#xa;</xsl:text>-->
    <!--<xsl:text>counts_parent_grade = 0&#xa;</xsl:text>--> <!-- for JIT sets only -->
    <!--<xsl:text>att_to_open_children = 0&#xa;</xsl:text>--> <!-- for JIT sets only -->
    <xsl:text>problem_end&#xa;</xsl:text>
</xsl:template>

<!-- Header file content -->
<!-- Gives some information about where in the MBX project the set came from -->
<!-- Some info changes with WW variables, such as due date -->
<xsl:template match="*" mode="header-content">
    <!-- Inneficient: indented text in variable, then strip indentation -->
    <!-- Alternative: wrap each line in "text" with linefeeds           -->
    <xsl:variable name="header-text">
        <xsl:text>
        # Header file for problem set </xsl:text><xsl:apply-templates select="." mode="numbered-title-filesafe" />
        <xsl:text>
        # This header file can be used for both the screen and hardcopy output

        DOCUMENT();

        loadMacros(
            "PG.pl",
            "PGbasicmacros.pl",
            "PGML.pl",
            "PGcourse.pl",
        );

        TEXT($BEGIN_ONE_COLUMN);

        $texTopLine = "\noindent {\large \bf $studentName}\hfill{\large \bf {".protect_underbar($courseName)."}}";
        if (defined($sectionName) and ($sectionName ne '')) {$texTopLine .= "  {\large \bf { Section: ".protect_underbar($sectionName)." } }"}; 
        $texTopLine .= "\par";

        ####################################################
        #
        # MODES provides for distinct output for TeX and HTML
        #
        ####################################################

        TEXT(MODES(
            TeX =&gt;"$texTopLine",
            HTML=&gt;"",
        ));

        TEXT(MODES(
            TeX =>"\noindent{\large \sc {Assignment ".protect_underbar($setNumber)." due $formatedDueDate}}\par".
                  "\noindent \bigskip",
            HTML=>"&lt;span style='font-variant: small-caps; font-size:large;'&gt;WeBWorK Assignment ".protect_underbar($setNumber)." is due: $formattedDueDate. &lt;/span&gt;$PAR",
        ));

        TEXT("This assignment contains exercises from</xsl:text><xsl:text>.");

        TEXT(MODES(
            TeX =>"",
            HTML=>"Here's the list of ".htmlLink(qq!http://webwork.maa.org/wiki/Available_Functions!,"functions and symbols")." which WeBWorK understands.",
        ));

        TEXT($END_ONE_COLUMN);

        ENDDOCUMENT();
        </xsl:text>
    </xsl:variable>
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="$header-text" />
    </xsl:call-template>
</xsl:template>

</xsl:stylesheet>
