<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2015-18                                                     -->
<!-- Robert A. Beezer, Michael Gage, Geoff Goehle, Alex Jordan             -->
<!--                                                                       -->
<!-- This file is part of PreTeXt.                                         -->
<!--                                                                       -->
<!-- PreTeXt is free software: you can redistribute it and/or modify       -->
<!-- it under the terms of the GNU General Public License as published by  -->
<!-- the Free Software Foundation, either version 2 or version 3 of the    -->
<!-- License (at your option).                                             -->
<!--                                                                       -->
<!-- PreTeXt is distributed in the hope that it will be useful,            -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of        -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         -->
<!-- GNU General Public License for more details.                          -->
<!--                                                                       -->
<!-- You should have received a copy of the GNU General Public License     -->
<!-- along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.      -->
<!-- ********************************************************************* -->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<!-- Apply this style sheet to merged XML (see pretext-merge.xsl and       -->
<!-- webwork-extraction.xsl) to produce a folder tree of .pg problem files -->
<!-- with set defintion and set header files. Compress into a .tgz and     -->
<!-- upload into a WeBWorK course (perhaps in the templates/local folder); -->
<!-- or into a server's libraries folder and set up site-wide access.      -->

<xsl:import href="./pretext-common.xsl" />
<xsl:import href="./pretext-assembly.xsl" />

<!-- Intend output to be a PG/PGML problem or a "def" file -->
<xsl:output method="text" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- We default to one massive def file -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk-level-entered != ''">
            <xsl:value-of select="$chunk-level-entered" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- ############## -->
<!-- Entry template -->
<!-- ############## -->

<!-- First, create the problem files in directories                           -->
<!-- Organized in directories as in the document tree, cut off at chunk level -->
<!-- Then chunk the document to write reasonable problem definition files     -->
<xsl:template match="/">
    <xsl:apply-templates select="$original" mode="generic-warnings"/>
    <!-- Handle <webwork-reps> element carefully -->
    <xsl:apply-templates select="$document-root//exercise/webwork-reps" />
    <xsl:apply-templates select="$document-root" mode="chunking"/>
</xsl:template>

<!-- ################## -->
<!-- Filename Utilities -->
<!-- ################## -->

<!-- Overall document title, for root directory name -->
<xsl:template name="root-directory">
    <xsl:apply-templates select="$document-root" mode="numbered-title-filesafe" />
    <xsl:text>/</xsl:text>
</xsl:template>

<!-- Directory path, recursively climb structural nodes,  -->
<!-- record names as pass up through chunk-level barrier  -->
<!-- Includes root document node (book, article, etc)     -->
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
        <xsl:when test="self::mathbook|self::pretext" /> <!-- done -->
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
<xsl:template match="webwork-reps" mode="filename">
    <xsl:apply-templates select="." mode="directory-path" />
    <xsl:apply-templates select="parent::exercise" mode="numbered-title-filesafe" />
    <xsl:text>.pg</xsl:text>
</xsl:template>

<!-- For problems from the OPL, just report the @source -->
<xsl:template match="webwork-reps[pg/@source]" mode="filename">
    <xsl:value-of select="pg/@source" />
</xsl:template>

<!-- For copied problems move to the problem that was copied -->
<xsl:template match="webwork-reps[pg/@copied-from]" mode="filename">
    <xsl:variable name="copied-from" select="pg/@copied-from"/>
    <xsl:apply-templates select="$document-root//webwork-reps[@ww-id=$copied-from]" mode="filename"/>
</xsl:template>


<!-- ################## -->
<!-- Problem Extraction -->
<!-- ################## -->

<!-- Extract an authored problem into its own file, flush left -->
<xsl:template match="webwork-reps[pg]" >
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="pg" />
        </xsl:call-template>
    </exsl:document>
</xsl:template>

<!-- OPL problems don't produce PG source files, -->
<!-- as they live on the server already          -->
<xsl:template match="webwork-reps[pg/@source]" />

<!-- Don't make PG file for copies -->
<xsl:template match="webwork-reps[pg/@copied-from]" />


<!-- ################## -->
<!-- Chunking Def Files-->
<!-- ################## -->

<!-- A complete file for a structural subdivision -->
<xsl:template match="&STRUCTURAL;" mode="chunk">
    <!-- Separate webwork within any exercises into their own set. -->
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select=".//webwork-reps[not(ancestor::exercises)]" mode="def-info-v2" />
        </xsl:with-param>
    </xsl:apply-templates>
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="exercises" select="true()" />
        <xsl:with-param name="content">
            <xsl:apply-templates select=".//webwork-reps[ancestor::exercises]" mode="def-info-v2" />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- A summary file for a structural subdivision                -->
<!-- Any webwork not in a subdivision (say, in an introduction) -->
<!-- The // is OK here (rather than descendant-or-self) since   -->
<!-- there will at least be an intervening "exercise" wrapper   -->
<xsl:template match="&STRUCTURAL;" mode="intermediate">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="content">
            <xsl:apply-templates select="*[not(&STRUCTURAL-FILTER;)]//webwork-reps" mode="def-info-v2" />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- ##################### -->
<!-- Def File Construction -->
<!-- ##################### -->

<!-- A *.def file for a structural subdivision -->
<xsl:template match="&STRUCTURAL;" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:param name="exercises" select="false()" />
    <!-- no problems, no def infos, then no file -->
    <xsl:if test="not($content = '')">
        <!-- filenames -->
        <xsl:variable name="def-filename">
            <xsl:call-template name="root-directory" />
            <xsl:text>def/</xsl:text>
            <!-- mandatory filename initial string -->
            <xsl:text>set</xsl:text>
            <xsl:apply-templates select="." mode="numbered-title-filesafe" />
            <xsl:if test="$exercises">
                <xsl:text>_Exercises</xsl:text>
            </xsl:if>
            <xsl:text>.def</xsl:text>
        </xsl:variable>
        <xsl:variable name="header-filename">
            <xsl:call-template name="root-directory" />
            <xsl:text>header/</xsl:text>
            <xsl:apply-templates select="." mode="numbered-title-filesafe" />
            <xsl:if test="$exercises">
                <xsl:text>_Exercises</xsl:text>
            </xsl:if>
            <xsl:text>.pg</xsl:text>
        </xsl:variable>
        <!-- set-definition file -->
        <exsl:document href="{$def-filename}" method="text">
            <xsl:variable name="open" select="substring(date:date-time(),1,10)" />
            <xsl:variable name="due" select="date:add($open,'P6M')" />
            <xsl:variable name="answer" select="$due" />
            <xsl:text>openDate          = </xsl:text>
            <xsl:value-of select="substring($open, 6, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($open, 9, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($open, 1, 4)" />
            <xsl:text> at 12:00am&#xa;</xsl:text>
            <xsl:text>dueDate           = </xsl:text>
            <xsl:value-of select="substring($due, 6, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($due, 9, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($due, 1, 4)" />
            <xsl:text> at 10:00pm&#xa;</xsl:text>
            <xsl:text>answerDate        = </xsl:text>
            <xsl:value-of select="substring($due, 6, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($due, 9, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($due, 1, 4)" />
            <xsl:text> at 10:00pm&#xa;</xsl:text>
            <xsl:text>paperHeaderFile   = </xsl:text>
            <xsl:value-of select="$header-filename" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>screenHeaderFile  = </xsl:text>
            <xsl:value-of select="$header-filename" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>description       = </xsl:text>
            <xsl:apply-templates select="." mode="title-simple" />
            <xsl:text>&#xa;</xsl:text>
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

<!-- Version 2 problem info -->
<!-- Each problem gets its own line in the problem set   -->
<!-- definition file. Be careful to create no content if -->
<!-- there are no problems in a subdivision as we employ -->
<!-- non-emptieness up the wrapping chain to ensure      -->
<!--  no trivial problem definition files are created.   -->
<!-- http://webwork.maa.org/wiki/Set_Definition_Files#Version_2 -->
<xsl:template match="webwork-reps" mode="def-info-v2">
    <xsl:text>problem_start&#xa;</xsl:text>
    <xsl:text>source_file = </xsl:text> <!-- PG file -->
    <xsl:apply-templates select="." mode="filename" />
    <xsl:text>&#xa;</xsl:text>
    <!--Much of the following commented out until we decide we should include them.   -->
    <!--WeBWorK provides good default values, customizable by sysadmin or instructor. -->
    <!--<xsl:text>value = 1&#xa;</xsl:text>--> <!-- default problem weight -->
    <!--<xsl:text>max_attempts = -1&#xa;</xsl:text>--> <!-- default max attempts is unlimited -->
    <!--<xsl:text>showMeAnother = -1&#xa;</xsl:text>--> <!-- default SMA is off -->
    <xsl:text>problem_id = </xsl:text>
    <xsl:apply-templates select="ancestor::exercise" mode="serial-number" />
    <xsl:text>&#xa;</xsl:text>
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
                  "\noindent \bigskip ",
            HTML=>"&lt;span style='font-variant: small-caps; font-size:large;'&gt;WeBWorK Assignment ".protect_underbar($setNumber)." is due: $formattedDueDate. &lt;/span&gt;$PAR",
        ));
        </xsl:text><xsl:choose><xsl:when test="$document-root//frontmatter/colophon/website"><xsl:text>
        TEXT(MODES(
            TeX =>"\noindent This assignment contains exercises from </xsl:text><xsl:apply-templates select="." mode="type-name" /><xsl:text> </xsl:text><xsl:apply-templates select="." mode="number" /><xsl:text> of </xsl:text><xsl:apply-templates select="$document-root"  mode="title-simple" /><xsl:text>.",
            HTML=>"This assignment contains exercises from ".htmlLink(qq!</xsl:text><xsl:apply-templates select="$document-root//frontmatter/colophon/website/address" /><xsl:text>/</xsl:text><xsl:apply-templates select="." mode="visible-id" /><xsl:text>.html!,"</xsl:text><xsl:apply-templates select="." mode="type-name" /><xsl:text> </xsl:text><xsl:apply-templates select="." mode="number" /><xsl:text>")." of </xsl:text><xsl:apply-templates select="$document-root"  mode="title-simple" /><xsl:text>."
        ));
        </xsl:text></xsl:when><xsl:otherwise><xsl:text>
        TEXT("This assignment contains exercises from </xsl:text><xsl:apply-templates select="." mode="type-name" /><xsl:text> </xsl:text><xsl:apply-templates select="." mode="number" /><xsl:text> of </xsl:text><xsl:apply-templates select="$document-root"  mode="title-simple" /><xsl:text>.");
        </xsl:text></xsl:otherwise></xsl:choose>

        <xsl:text>
        TEXT($END_ONE_COLUMN);

        ENDDOCUMENT();
        </xsl:text>
    </xsl:variable>
    <!-- lazy, strips indentation, etc -->
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="$header-text" />
    </xsl:call-template>
</xsl:template>

</xsl:stylesheet>
