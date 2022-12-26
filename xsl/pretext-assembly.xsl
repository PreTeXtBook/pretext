<?xml version='1.0'?>

<!--********************************************************************
Copyright 2020 Robert A. Beezer

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

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
    exclude-result-prefixes="pi"
>

<!-- This is the once-mythical pre-processor, though we prefer     -->
<!-- to describe it as the "assembly" of "enhanced" source.  By    -->
<!-- "assembly" we mean pre-processing of source, by "assembling"  -->
<!-- various pieces of material or content, authored or computed,  -->
<!-- into an enhanced source tree. This template operates by       -->
<!-- successive passes through the entire source tree making       -->
<!-- adjustments into a new "enhanced" or modified source tree     -->
<!-- with each pass.                                               -->
<!--                                                               -->
<!-- * $original will point to source file/tree/XML at the overall -->
<!--   "pretext" element.                                          -->
<!-- * The "version" templates are applied to decide if certain    -->
<!--   elements are excluded from the source tree.  This creates   -->
<!--   the new $version source tree by *removing* source.          -->
<!-- * The modal "assembly" templates are applied to the source    -->
<!--   root element, creating a new version of the source, which   -->
<!--   has been "enhanced".  Various things happen in this pass,   -->
<!--   such as assembling auxiliary files of content (WeBWorK      -->
<!--   representations, private solutions, bibliographic items).   -->
<!--   This creates the $assembly source tree by *adding* new      -->
<!--   source elements.                                            -->
<!-- * The "repair" templates will automatically repair deprecated -->
<!--   constructions so that actual conversions can remove         -->
<!--   orphaned code.  Despite the name, we also implement         -->
<!--   conveniences that are universal accross all conversions, so -->
<!--   that conversions can assume a more canonical version of the -->
<!--   source, or remove the need for additional templates to      -->
<!--   realize certain constructions (e.g. url/@visual).  This     -->
<!--   creates the $repair source tree by *changing* source.       -->
<!-- * $root will point to the root of the final enhanced          -->
<!--   source file/tree/XML.                                       -->
<!-- * Derived variables, $docinfo and $document-root, will        -->
<!--   be created here for use in subsequent stylesheets.          -->
<!--                                                               -->
<!-- Notes:                                                        -->
<!--                                                               -->
<!-- 1.  $original is needed for context switches back into the    -->
<!--     original authored source, such as for determining the     -->
<!--     location of the source in the file system.                -->
<!-- 2.  Any coordination of automatically assigned identifiers    -->
<!--     requires identical source, so even a simple extraction    -->
<!--     stylesheet might require preparing identical source       -->
<!--     via this method.                                          -->
<!-- 3.  Overrides, customization of the assembly will typically   -->
<!--     happen here, but can be converter-specific in some ways.  -->
<!--                                                               -->
<!-- The "publisher-variables.xsl" and "pretext-assembly.xsl"      -->
<!-- stylesheets are symbiotic, and should be imported             -->
<!-- simultaneously.  Assembly will change the source in various   -->
<!-- ways, while some defaults for publisher variables will depend -->
<!-- on source.  The default variables should depend on gross      -->
<!-- structure and adjustments should be to smaller portions of    -->
<!-- the source, but we don't take any chances.  So, note in       -->
<!-- "assembly" that an intermediate tree is defined as a          -->
<!-- variable, which is then used in defining some variables,      -->
<!-- based on assembled source.  Conversely, certain variables,    -->
<!-- such as locations of customizations or private solutions,     -->
<!-- are needed early in assembly, while other variables, such     -->
<!-- as options for numbering, are needed for later enhancements   -->
<!-- to the source.  If new code results in undefined, or          -->
<!-- recursively defined, variables, this discussion may be        -->
<!-- relevant.  (This is repeated verbatim in the other            -->
<!-- stylesheet).                                                  -->


<!-- Isolate computation of numbers -->
<xsl:import href="./pretext-numbers.xsl"/>
<!-- Isolate conversion of Runestone/interactive to PreTeXt/static -->
<xsl:import href="./pretext-runestone-static.xsl"/>

<!-- We explicitly do not import "pretext-common.xsl" as we want    -->
<!-- this important pre-processing stylesheet to have no hidden     -->
<!-- dependencies.  In almost every rational use, the "-common"     -->
<!-- stylesheet is imported by a conversion, so it is easy to       -->
<!-- miss these dependencies.  An example in 2022-06 was the use    -->
<!-- of the "visible-id" template to coordinate construction and    -->
<!-- insertion of WeBWorK problems with an intervening trip to a    -->
<!-- WW server.  The "pretext-enhanced-source.xsl" stylesheet is    -->
<!-- one place where "-common" does not creep in.  Use of a modal   -->
<!-- template here, with a definition in -common, will do a         -->
<!-- massive "value-of" when not defined for the "-enhanced-source" -->
<!-- stylesheet, which might be detectable (in strange ways).       -->

<!-- The "representations" pass is used to make derived versions of      -->
<!-- authored exercises which can be rendered dynamically.  For example, -->
<!-- a multiple choice question.  These representations can be "static"  -->
<!-- and so meant for use in PDF or braille output, or "dynamic", which  -->
<!-- means anyplace Javascript (or similar) is available.  Right now     -->
<!-- that is just HTML (and not output built on HTML, such as EPUB).     -->
<!--                                                                     -->
<!-- Notes:                                                              -->
<!--   * We default here to "static".  HTML production will override     -->
<!--     to "dynamic" and then any importing stylesheet will need to     -->
<!--     override back to "static".                                      -->
<!--   * 'pg-problems' are WeBWork problems for an archive               -->
<!--   * If testing, the pretext-enhanced-source.xsl  stylesheet will    -->
<!--     need a stringparam override to view and test dynamic versions.  -->
<xsl:variable name="exercise-style" select="'static'"/>

<!-- ############################## -->
<!-- Source Assembly Infrastructure -->
<!-- ############################## -->

<!-- When building duplicates, we have occasion -->
<!-- to inspect the original in various places  -->
<!-- We do not know if we have "fixed" the      -->
<!-- deprecated overall element, so need to     -->
<!-- try both.  For example, this variable is   -->
<!-- employed by the warnings and deprecation   -->
<!-- messages that result from analyzing an     -->
<!-- author's source, since we may "repair"     -->
<!-- some of them later, so we have to catch    -->
<!-- them early. -->
<xsl:variable name="original" select="/mathbook|/pretext"/>

<!-- These modal templates duplicate the source exactly for each -->
<!-- pass: elements, attributes, text, whitespace, comments,     -->
<!-- everything. Various other templates will override these     -->
<!-- templates to create a new enhanced source tree.             -->
<xsl:template match="node()|@*" mode="version">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="version"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="original-labels">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="original-labels"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="webwork">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="webwork"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="assembly">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="assembly"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="representations">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="representations"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="repair">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="identification">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="identification"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="language">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="language"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="augment">
    <xsl:param name="parent-struct" select="''"/>
    <xsl:param name="level" select="0"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="augment">
            <xsl:with-param name="parent-struct" select="$parent-struct"/>
            <xsl:with-param name="level" select="$level"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<xsl:template match="node()|@*" mode="exercise">
    <xsl:param name="division" select="''"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="exercise">
            <xsl:with-param name="division" select="$division"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- These templates initiate and create several iterations of -->
<!-- the source tree via modal templates.  Think of each as a  -->
<!-- "pass" through the source. Generally this constructs the  -->
<!-- new tree as a (text) result tree fragment and then we     -->
<!-- convert it into real XML nodes. These "real" trees have a -->
<!-- root element, as a result of the node-set() manufacture.  -->
<xsl:variable name="version-rtf">
    <xsl:apply-templates select="/" mode="version"/>
</xsl:variable>
<xsl:variable name="version" select="exsl:node-set($version-rtf)"/>

<xsl:variable name="original-labeled-rtf">
    <xsl:apply-templates select="$version" mode="original-labels"/>
</xsl:variable>
<xsl:variable name="original-labeled" select="exsl:node-set($original-labeled-rtf)"/>

<!-- A global list of all "webwork" used for       -->
<!-- efficient backward-compatible indentification -->
<xsl:variable name="all-webwork" select="$original-labeled//webwork"/>

<xsl:variable name="webwork-rtf">
    <xsl:apply-templates select="$original-labeled" mode="webwork"/>
</xsl:variable>
<xsl:variable name="webworked" select="exsl:node-set($webwork-rtf)"/>

<xsl:variable name="assembly-rtf">
    <xsl:apply-templates select="$webworked" mode="assembly"/>
</xsl:variable>
<xsl:variable name="assembly" select="exsl:node-set($assembly-rtf)"/>

<!-- Exercises are "tagged" as to their nature (division, inline, -->
<!-- worksheet, reading, project-like) and interactive exercises  -->
<!-- get more precise categorization.  The latter is used to      -->
<!-- determine if Runestone Services are loaded.                  -->

<xsl:variable name="exercise-rtf">
    <!-- initialize with default, 'inline' -->
    <xsl:apply-templates select="$assembly" mode="exercise">
        <xsl:with-param name="division" select="'inline'"/>
    </xsl:apply-templates>
</xsl:variable>
<xsl:variable name="exercise" select="exsl:node-set($exercise-rtf)"/>

<xsl:variable name="representations-rtf">
    <xsl:apply-templates select="$exercise" mode="representations"/>
</xsl:variable>
<xsl:variable name="representations" select="exsl:node-set($representations-rtf)"/>

<!-- Dependency: "repair" will fix some exercise representations, -->
<!-- especially coming from an "old" WeBWorK server, so the       -->
<!-- "repair" pass must come after the "representations" pass.    -->
<xsl:variable name="repair-rtf">
    <xsl:apply-templates select="$representations" mode="repair"/>
</xsl:variable>
<xsl:variable name="repair" select="exsl:node-set($repair-rtf)"/>

<!-- Once the "repair" tree is formed, any source modifications      -->
<!-- have been made, and it is on to *augmenting* the source.        -->
<!-- Various publisher variables are consulted for the augmentation, -->
<!-- notably the style/depth of numbering.  So this tree needs to    -->
<!-- be available for creating those variables, notably sensible     -->
<!-- defaults based on the source.  We refer to this tree as the     -->
<!-- "assembly" tree.                                                -->
<xsl:variable name="assembly-root" select="$repair/pretext"/>
<xsl:variable name="assembly-docinfo" select="$assembly-root/docinfo"/>
<xsl:variable name="assembly-document-root" select="$assembly-root/*[not(self::docinfo)]"/>

<xsl:variable name="identification-rtf">
    <!-- pass in all elements with authored @xml:id -->
    <!-- to look for authored duplicates            -->
    <xsl:call-template name="duplication-check-xmlid">
        <xsl:with-param name="nodes" select="$repair//*[@xml:id]"/>
        <xsl:with-param name="purpose" select="'authored'"/>
    </xsl:call-template>
    <!-- pass in all elements with authored @label -->
    <!-- to look for authored duplicates           -->
    <xsl:call-template name="duplication-check-label">
        <xsl:with-param name="nodes" select="$repair//*[@label]"/>
        <xsl:with-param name="purpose" select="'authored'"/>
    </xsl:call-template>
    <xsl:apply-templates select="$repair" mode="identification"/>
</xsl:variable>
<xsl:variable name="identification" select="exsl:node-set($identification-rtf)"/>

<xsl:variable name="language-rtf">
    <xsl:apply-templates select="$identification" mode="language"/>
</xsl:variable>
<xsl:variable name="language" select="exsl:node-set($language-rtf)"/>

<xsl:variable name="augment-rtf">
    <xsl:apply-templates select="$language" mode="augment"/>
</xsl:variable>
<xsl:variable name="augment" select="exsl:node-set($augment-rtf)"/>

<!-- The main "pretext" element only has two possible children      -->
<!-- One is "docinfo", the other is "book", "article", etc.         -->
<!-- This is of interest by itself, or the root of content searches -->
<!-- And docinfo is the other child, these help prevent searching   -->
<!-- the wrong half.                                                -->
<!-- NB: source repair below converts a /mathbook to a /pretext     -->
<xsl:variable name="root" select="$augment/pretext"/>
<xsl:variable name="docinfo" select="$root/docinfo"/>
<xsl:variable name="document-root" select="$root/*[not(self::docinfo)]"/>


<!-- ######################## -->
<!-- Bibliography Manufacture -->
<!-- ######################## -->

<!-- Initial experiment, overall "references" flagged with -->
<!-- a @source filename as the place to go get a list of   -->
<!-- candidate "biblio" (in desired order)                 -->
<!-- NB: this needs a rethink when revisited.  A file of   -->
<!-- bibliography items can be specified, perhaps in       -->
<!-- in docinfo (runs with the source?), formed as         -->
<!-- $biblios in -common, and then mined for matches not   -->
<!-- explicitly present?                                   -->
<xsl:template match="backmatter/references[@source]" mode="assembly">
    <!-- Grab the list, filename is relative to the -->
    <!-- "document" holding "references" (original) -->
    <xsl:variable name="biblios" select="document(@source, .)"/>
    <!-- Copy the "references" element (could be literal, but maybe not in "text" output mode) -->
    <xsl:copy>
        <!-- @source attribute not needed in enhanced source -->
        <xsl:apply-templates select="@*[not(local-name() = 'source')]" mode="assembly"/>
        <!-- likely more elements to duplicate, consult schema -->
        <xsl:apply-templates select="title" mode="assembly"/>
        <!-- Look at each "biblio" in the external file -->
        <xsl:for-each select="$biblios/pretext-biblios/biblio">
            <xsl:variable name="the-id" select="@xml:id"/>
            <xsl:message>@xml:id of &lt;biblio&gt; in bibliography file: <xsl:value-of select="$the-id"/></xsl:message>
            <!-- Building duplicate, so look at $original for    -->
            <!-- "xref" pointing to the current context "biblio" -->
            <xsl:if test="$original//xref[@ref = $the-id]">
                <xsl:message>  Located this &lt;biblio&gt; cited in original source</xsl:message>
                <xsl:apply-templates select="." mode="assembly"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:copy>
</xsl:template>

<!-- ################### -->
<!-- WeBWorK Manufacture -->
<!-- ################### -->


<!-- This pre-processing stylesheet will be run prior to isolating WW      -->
<!-- problems for their eventual trip to a WW server ("extraction").       -->
<!-- This is necessary so certain numbers are formed properly, etc.        -->
<!-- In this phase we handle making copies of WW problems by duplicating   -->
<!-- them.  This stylesheet is parameterized by the boolean variable       -->
<!-- $b-extracting-pg, and is set by the stylesheet that actually harvests -->
<!-- the WW problems and converts them to PG versions (extract-pg.xsl).    -->
<xsl:variable name="b-extracting-pg" select="false()"/>

<!-- Don't match on simple WeBWorK logo       -->
<!-- But do match with a @copy attribute      -->
<!-- Seed and possibly source attributes      -->
<!-- Then authored?, pg?, and static children -->
<!-- NB: "xref" check elsewhere is not        -->
<!-- performed here since we accept           -->
<!-- representations at face-value            -->

<!-- NB: when working to improve which parts of the webwork representations -->
<!-- move on to assembled source, realize that the "static" version meant   -->
<!-- for non-HTML outputs is also the best thing to provide to the HTML     -->
<!-- conversion for use as a search document.  Perhaps create the full-on   -->
<!-- JSON (escaped) string here from "static" and provide it as an internal -->
<!-- element ("pi:") for later consumption.  Review the destination for     -->
<!-- similar notes about possible changes.                                  -->

<xsl:template match="webwork[* or @copy or @source]" mode="webwork">
    <!-- Every "webwork" that is a problem (not a generator) gets a   -->
    <!-- lifetime identification in both passes through the source.   -->
    <!-- The first migrates through the "extract-pg.xsl" template,    -->
    <!-- then the Python communication with the server, and into the  -->
    <!-- representations file.  The second is then used to align the  -->
    <!-- source with the representations file on the second pass.     -->
    <!-- For historical reasons, this ID genertaion is slow and       -->
    <!-- clumsy, we can improve by using a recursive generation,      -->
    <!-- which would require parameter passing through all the        -->
    <!-- "assembly" templates.  Better to perhaps break out a         -->
    <!-- "webwork" pass just prior to assembly.                       -->
    <!-- 2022-11-21: we are a bit careful to optimize the computation -->
    <!-- of the identifiers in a backwards-compatible way.  Better to -->
    <!-- someday switch to a purely recursive descent version as a    -->
    <!-- one-time jolt to authors. (Remove global $all-webwork.)      -->
    <xsl:variable name="ww-id">
        <xsl:choose>
            <xsl:when test="@xml:id">
                <xsl:value-of select="@xml:id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local-name(.)" />
                <xsl:text>-</xsl:text>
                <!-- compute the eqivalent of the count of all previous WW:     -->
                <!-- <xsl:number from="book|article|letter|memo" level="any" /> -->
                <!-- Save off the WW in question -->
                <xsl:variable name="the-ww" select="self::*"/>
                <!-- Run over global list, looking for a match -->
                <xsl:for-each select="$all-webwork">
                    <xsl:if test="count($the-ww|.) = 1">
                        <!-- context is the $all-webwork node-set, so   -->
                        <!-- position() gives index/location of $the-ww -->
                        <xsl:value-of select="position()"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- "normally" not extracting to build PGML, it -->
        <!-- should be saved off in the representations  -->
        <!-- file and available for making replacements  -->
        <xsl:when test="not($b-extracting-pg)">
            <!-- the "webwork-reps" element from the server for this "webwork" -->
            <xsl:variable name="the-webwork-rep" select="document($webwork-representations-file, $original)/webwork-representations/webwork-reps[@ww-id=$ww-id]"/>
            <xsl:choose>
                <!-- An empty string for $webwork-representations-file, and      -->
                <!-- the "document()" still succeeds (returns the source file?). -->
                <!-- But this is hopeless. So just totally bail out repeatedly   -->
                <!-- and leave the containing "exercise" hollow.                 -->
                <xsl:when test="$webwork-representations-file = ''">
                    <xsl:message>PTX:ERROR:    There is a WeBWorK exercise with internal id "<xsl:value-of select="$ww-id"/>"</xsl:message>
                    <xsl:message>              but your publication file does not indicate the file</xsl:message>
                    <xsl:message>              of problem representations created by a WeBWorK server.</xsl:message>
                    <xsl:message>              Your WeBWorK exercises will all, at best, be empty.</xsl:message>
                </xsl:when>
                <!-- This should only fail if the file is missing.  Repeatedly. -->
                <xsl:when test="not($the-webwork-rep)">
                    <xsl:message>PTX:ERROR:    The WeBWorK problem with internal id "<xsl:value-of select="$ww-id"/>"</xsl:message>
                    <xsl:message>              could not be located in the file of WeBWorK problems from</xsl:message>
                    <xsl:message>              the server, which your publication file indicates should be located</xsl:message>
                    <xsl:message>              at "<xsl:value-of select="$webwork-representations-file"/>". </xsl:message>
                    <xsl:message>              If there are many messages like this, then likely your file is missing. </xsl:message>
                    <xsl:message>              But if this is an isolated error message, then it may indicate a bug,</xsl:message>
                    <xsl:message>              which should be reported.</xsl:message>
                </xsl:when>
                <!-- Copy the "webwork-reps" in place of the "webwork", so this is  -->
                <!-- a new signal of a WW problem for the second pass.  This is     -->
                <!-- also temporary, since we will subset and slim this down later. -->
                <xsl:otherwise>
                    <xsl:apply-templates select="$the-webwork-rep" mode="webwork"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- Now we are doing a pass to support extraction -->
        <!-- of PGML, so $b-extracting-pg is true          -->
        <!--                                               -->
        <!-- This is where we copy PTX source to prevent   -->
        <!-- multiple versions foating in around in an     -->
        <!-- author's source                               -->
        <xsl:when test="@copy">
            <!-- Find the target.  Maybe. -->
            <xsl:variable name="target" select="id(@copy)"/>
            <!-- Trap potential pitfalls and record part of an error -->
            <!-- message.  Use a non-empty error message as a signal -->
            <!-- to bail out gracefully on the copy.                 -->
            <xsl:variable name="error-message-for-copy">
                <xsl:choose>
                    <xsl:when test="not($target)">
                        <xsl:text>the @copy attribute points to nothing, check the spelling?</xsl:text>
                    </xsl:when>
                    <xsl:when test="not($target/self::webwork)">
                        <xsl:text>the @copy attribute points to a "</xsl:text>
                        <xsl:value-of select="local-name($target)"/>
                        <xsl:text>" element, not another "webwork".</xsl:text>
                    </xsl:when>
                    <xsl:when test="$target/self::webwork[@source]">
                        <xsl:text>the @copy attribute points a "webwork" with a @source attribute.  (Replace the @copy by the @source?)</xsl:text>
                    </xsl:when>
                    <xsl:when test="$target/self::webwork[@copy]">
                        <xsl:text>the @copy attribute points to "webwork" with a @copy attribute. Sorry, we are not that sophisticated.</xsl:text>
                    </xsl:when>
                    <!-- Presumably OK, no error message -->
                    <xsl:otherwise/>
                </xsl:choose> <!-- end: gauntlet of bad @copy discovery -->
            </xsl:variable>

            <xsl:choose>
                <!-- no error means to proceed with copy -->
                <xsl:when test="$error-message-for-copy = ''">
                    <xsl:copy>
                        <xsl:attribute name="copied-from">
                            <xsl:value-of select="@copy"/>
                        </xsl:attribute>
                        <!-- Duplicate attributes, but remove the @copy attribute -->
                        <!-- used as a signal here.  We don't want to copy this   -->
                        <!-- again after we have been to the WW server.           -->
                        <xsl:apply-templates select="@*[not(local-name(.) = 'copy')]" mode="webwork"/>
                        <!-- The @seed makes the problem different, and there are also   -->
                        <!-- unique identifiers, so grab any other attributes of the     -->
                        <!-- original, but exclude these while formulating a copy/clone. -->
                        <xsl:apply-templates select="$target/@*[(not(local-name(.) = 'id')) and
                                                                (not(local-name(.) = 'label')) and
                                                                (not(local-name(.) = 'seed'))]" mode="webwork"/>
                        <!-- Add a @ww-id for the trip to the server -->
                        <xsl:attribute name="ww-id">
                            <xsl:value-of select="$ww-id"/>
                        </xsl:attribute>
                        <!-- TODO: The following should scrub unique IDs as it continues down the tree. -->
                        <!-- Perhaps with a param to the assembly modal template.                       -->
                        <!-- Does the contents of the original WW have any @xml:id or @label?           -->
                        <xsl:apply-templates select="$target/node()" mode="webwork"/>
                    </xsl:copy>
                </xsl:when>
                <!-- with an error in formulation, drop in something very -->
                <!-- similar in gross form, and alert at the console      -->
                <xsl:otherwise>
                    <xsl:copy>
                        <!-- As for a legitimate copy above , we carry over as much -->
                        <!-- metadata as possible, and in particular include a      -->
                        <!-- @ww-id  for tracking through the server                -->
                        <xsl:apply-templates select="@*[not(local-name(.) = 'copy')]" mode="webwork"/>
                        <xsl:attribute name="ww-id">
                            <xsl:value-of select="$ww-id"/>
                        </xsl:attribute>
                        <!-- Now a minimal, but correct PreTeXt, WW problem into the       -->
                        <!-- extraction machinery, and out into all possible final outputs -->
                        <statement>
                            <p>
                                A WeBWorK problem right here was meant to be a copy of another problem,
                                but potentially with different randomization, but there was a failure.
                                The <c>@copy</c> attribute was set to <c><xsl:value-of select="@copy"/></c>.
                                Please report me, so the publisher can get more details by searching the
                                runtime output for <q><c>PTX:ERROR</c></q>.
                            </p>
                        </statement>
                    </xsl:copy>
                    <!-- minimalist report into source, more at console -->
                    <xsl:message>PTX:ERROR:   A WeBWorK problem has a @copy attribute with value "<xsl:value-of select="@copy"/>".</xsl:message>
                    <xsl:message>             However, the problem did not render:</xsl:message>
                    <xsl:message><xsl:text>             </xsl:text><xsl:value-of select="$error-message-for-copy"/></xsl:message>
                    <xsl:message>             A placeholder problem will appear in your output instead.</xsl:message>
                </xsl:otherwise>
            </xsl:choose> <!-- end: action for copy is good/bad -->
        </xsl:when>
        <!-- extracting, but not copying, so xerox author's source, plus an ID -->
        <xsl:otherwise>
            <xsl:copy>
                <xsl:apply-templates select="@*" mode="webwork"/>
                <!-- Add a @ww-id for the trip to the server -->
                <xsl:attribute name="ww-id">
                    <xsl:value-of select="$ww-id"/>
                </xsl:attribute>
                <xsl:apply-templates select="node()" mode="webwork"/>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Good time to clean-up what comes back from a WW server.  With -->
<!-- "webwork-reps" in the match, this will only be applied in the -->
<!-- second (non-extraction) pass, only within a WW problem.  From -->
<!-- the code comment when this was done with Python: "p with only -->
<!-- a single fillin, not counting those inside an li without      -->
<!-- preceding siblings"                                           -->
<xsl:template match="webwork-reps/static//p[not(normalize-space(text()))][count(fillin)=1 and count(*)=1][not(parent::li) or (parent::li and preceding-sibling::*)]" mode="webwork"/>


<!-- ################# -->
<!-- Private Solutions -->
<!-- ################# -->

<!-- "solutions" here refers generically to "hint", "answer",  -->
<!-- and "solution" elements of an "exercise".  An author may  -->
<!-- wish to provide limited distribution of some solutions to -->
<!-- exercises, which we deem "private" here.  If a            -->
<!-- "private-solutions-file" is provided, it will be mined    -->
<!-- for these private solutions.                              -->

<xsl:variable name="b-private-solutions" select="not($private-solutions-file = '')"/>

<!-- Note: there may be (nested) "pi:privatesolutionsdivision"  -->
<!-- elements in this file.  They are largely meaningless, but  -->
<!-- are necessary if an author wants to modularize their       -->
<!-- collection across multiple files.  Then each file can be a -->
<!-- single overall element.  (We expect/require no additional  -->
<!-- structure in this file.)  The consequence is the "//" in   -->
<!-- each expression below.                                     -->
<!-- NB: relative to *original* source file/tree                -->
<xsl:variable name="privatesolns" select="document($private-solutions-file, $original)"/>
<xsl:variable name="n-hint"     select="$privatesolns/pi:privatesolutions//hint"/>
<xsl:variable name="n-answer"   select="$privatesolns/pi:privatesolutions//answer"/>
<xsl:variable name="n-solution" select="$privatesolns/pi:privatesolutions//solution"/>

<xsl:template match="exercise|task" mode="assembly">
    <xsl:variable name="the-id" select="@xml:id"/>
    <xsl:copy>
        <!-- attributes, then all elements that are not solutions                               -->
        <!--   unstructured exercise:  "p" etc, then solutions OK even if schema violation?     -->
        <!--   structured exercise: copy statement, then interleave solutions                   -->
        <!--   non-terminal Task: introduction, task, conclusion                                -->
        <!--   terminal unstructured task: "p" etc, then solutions OK even if schema violation? -->
        <!--   terminal structured task: copy statement, then interleave solutions              -->
        <!-- TODO: defend against non-terminal task, unstructured cases      -->
        <!-- (identify proper structure + non-empty union of three additions -->
        <!-- Fix unstructured cases by inserting "statement",                -->
        <!-- warn about non-terminal task case and drop additions (error)    -->
        <xsl:apply-templates select="*[not(self::hint or self::answer or self::solution)]|@*" mode="assembly"/>
        <!-- hints, answers, solutions; first regular, second private -->
        <xsl:apply-templates select="hint" mode="assembly"/>
        <xsl:apply-templates select="$n-hint[@ref=$the-id]" mode="assembly"/>
        <xsl:apply-templates select="answer" mode="assembly"/>
        <xsl:apply-templates select="$n-answer[@ref=$the-id]" mode="assembly"/>
        <xsl:apply-templates select="solution" mode="assembly"/>
        <xsl:apply-templates select="$n-solution[@ref=$the-id]" mode="assembly"/>
    </xsl:copy>
</xsl:template>

<!-- ############## -->
<!-- Customizations -->
<!-- ############## -->

<!-- The "custom" element, with a @name in an auxiliary file,     -->
<!-- and a @ref in a source file, allows for custom substitutions -->

<!-- If the publisher variable  $customizations-file  is bad, -->
<!-- then  document()  will raise an error.  The empty string -->
<!-- (default) will not raise an error, so if not specified,  -->
<!-- no problem.  But an empty string, and an attempted       -->
<!-- access in the template *will* raise the error below.     -->
<xsl:variable name="customizations" select="document($customizations-file, $original)"/>

<!-- Set the key, nodes to be located are named -->
<!-- "custom" within the file just accessed     -->
<!-- For each one, @name is the search term     -->
<!-- that will locate it: the key, the index    -->
<xsl:key name="name-key" match="custom" use="@name"/>

<xsl:template match="custom[@ref]" mode="assembly">
    <!-- We need to get the @ref attribute now, due to a context shift -->
    <!-- And the "custom" context also, for use in a location report   -->
    <xsl:variable name="the-ref" select="string(@ref)"/>
    <xsl:variable name="the-custom" select="."/>
    <!-- Now the context shift to query the customizations -->
    <xsl:for-each select="$customizations">
        <xsl:variable name="the-lookup" select="key('name-key', $the-ref)"/>
        <!-- This is an AWOL node, not empty content (which is allowed) -->
        <xsl:if test="not($the-lookup)">
            <xsl:text>[MISSING CUSTOM CONTENT HERE]</xsl:text>
            <xsl:message>PTX:WARNING:   lookup for a "custom" element with @name set to "<xsl:value-of select="$the-ref"/>" has failed, while consulting the customization file "<xsl:value-of select="$customizations-file"/>".  Output will contain "[MISSING CUSTOM CONTENT HERE]" instead</xsl:message>
            <xsl:apply-templates select="$the-custom" mode="location-report"/>
        </xsl:if>
        <!-- Copying the contents of "custom" via the "assembly" templates -->
        <!-- will keep the "pi" namespace from appearing in palces, as it  -->
        <!-- will with an "xsl:copy-of" on the same node set.  But it      -->
        <!-- allows nested "custom" elements.                              -->
        <!--                                                               -->
        <!-- Do we want authors to potentially create cyclic references?   -->
        <!-- A simple 2-cycle test failed quickly and obviously, so it     -->
        <!-- will be caught quite easily, it seems.                        -->
        <xsl:apply-templates select="$the-lookup/node()" mode="assembly"/>
    </xsl:for-each>
</xsl:template>


<!-- ############# -->
<!-- Conveniences  -->
<!-- ############# -->

<!-- Certain markup can be translated into more primitive versions using      -->
<!-- existing markup, so we do a translation of certain forms into more       -->
<!-- potentially verbose forms that an author might tire of doing repeatedly. -->
<!-- See below for examples.  This is better than making a result-tree        -->
<!-- fragment and applying templates, since all context is lost that way.     -->

<!-- Visual URLs -->
<!-- A great way to present a URL is with some clickable text.  But that    -->
<!-- is useless in print.  And maybe a reader really would like to see the  -->
<!-- actual URL.  So "@visual" is a version of the URL that is pleasing to  -->
<!-- look at, maybe just a TLD, no protocol (e.g "https://"), no "www."     -->
<!-- if unnecessary, etc.  Here it becomes a special variant of a footnote, -->
<!-- which allows for numbering and special-handling in LaTeX, based        -->
<!-- strictly on the element itself.  But placing the URL in an attribute   -->
<!-- signals this is an exceptional footnote, so the URL can be handled     -->
<!-- specially, say in a monospace font, or in the LaTeX case, treatment    -->
<!-- like \nolinkurl{}. This is great in print, and is a knowl in HTML.     -->
<!--                                                                        -->
<!-- Advantages: however a conversion does footnotes, this will be the      -->
<!-- right markup for that conversion.  Note that LaTeX pulls footnotes     -->
<!-- out of "tcolorbox" environments, which is based on the *context*,      -->
<!-- so a result-tree fragment implementation is doomed to fail.            -->
<!--                                                                        -->
<!-- N.B.  We are only interpreting the "content" form here by simply       -->
<!-- adding the footnote element.  This leaves various decisions about      -->
<!-- formatting to the subsequent conversion.                               -->
<!--                                                                        -->
<!-- N.B. the automatic "fn/@pi:url" creates a *new* element that is not    -->
<!-- in an author's source.  When we annotate source (as a form of perfect  -->
<!-- documentation) we take care to not annotate these elements which  have -->
<!-- no source to show.                                                     -->

<xsl:template match="url[node()]|datafile[node()]" mode="repair">
    <xsl:copy>
        <!-- we drop the @visual attribute, a decision we might revisit -->
        <xsl:apply-templates select="node()|@*[not(local-name(.) = 'visual')]" mode="repair"/>
    </xsl:copy>
    <!-- manufacture a footnote with (private) attribute -->
    <!-- as a signal to conversions as to its origin     -->
    <xsl:choose>
        <!-- explicitly opt-out, so no footnote -->
        <xsl:when test="@visual = ''"/>
        <!-- go for it, as requested by author -->
        <xsl:when test="@visual">
            <fn pi:url="{@visual}"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- When an author has not made an effort to provide a visual   -->
            <!-- alternative, then attempt some obvious clean-up of the      -->
            <!-- default, and if not possible, settle for an ugly visual URL -->
            <!--                                                             -->
            <!-- We get a candidate visual URI from the @href attribute      -->
            <!-- link/reference/location may be external -->
            <!-- (@href) or internal (datafile[@source]) -->
            <xsl:variable name="uri">
                <xsl:choose>
                    <!-- "url" and "datafile" both support external @href -->
                    <xsl:when test="@href">
                        <xsl:value-of select="@href"/>
                    </xsl:when>
                    <!-- a "datafile" might be local, @source is        -->
                    <!-- indication, so prefix with a base URL,         -->
                    <!-- add "external" directory, via template useful  -->
                    <!-- also for visual URL formulation in -assembly   -->
                    <!-- N.B. we are using the base URL, since this is  -->
                    <!-- the most likely need by employing conversions. -->
                    <!-- It would eem duplicative in a conversion to    -->
                    <!-- HTML, so could perhaps be killed in that case. -->
                    <!-- But it is what we want for LaTeX, and perhaps  -->
                    <!-- for EPUB, etc.                                 -->
                    <xsl:when test="self::datafile and @source">
                        <xsl:apply-templates select="." mode="static-url"/>
                    </xsl:when>
                    <!-- empty will be non-functional -->
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:variable>
            <!-- And clean-up automatically in the prevalent cases -->
            <xsl:variable name="truncated-href">
                <xsl:choose>
                    <xsl:when test="substring(@href, 1, 8) = 'https://'">
                        <xsl:value-of select="substring($uri, 9)"/>
                    </xsl:when>
                    <xsl:when test="substring(@href, 1, 7) = 'http://'">
                        <xsl:value-of select="substring($uri, 8)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$uri"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <fn pi:url="{$truncated-href}"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ############# -->
<!-- Source Repair -->
<!-- ############# -->

<!-- We unilaterally make various changes to an author's source -->
<!-- so a conversion (every conversion?) can assume more        -->
<!-- accurately that the source has certain characteristics.    -->

<!-- 2019-04-02  "mathbook" replaced by "pretext" -->
<xsl:template match="/mathbook" mode="repair">
    <pretext>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </pretext>
</xsl:template>

<!-- 2021-07-02 wrap notation/usage in "m" if not present -->
<xsl:template match="notation/usage[not(m)]" mode="repair">
    <!-- duplicate "usage" w/ attributes, insert "m" as repair -->
    <usage>
        <xsl:apply-templates select="@*" mode="repair"/>
        <m>
            <xsl:apply-templates select="node()|@*" mode="repair"/>
        </m>
    </usage>
</xsl:template>

<!-- 2021-10-04 "glossary" was finalized, so old-style preserved -->

<!-- glossary introductions become headnotes -->
<xsl:template match="glossary/introduction" mode="repair">
    <headnote>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </headnote>
</xsl:template>

<!-- "terms" only ever had "defined-term" as children    -->
<!-- and is now obsolete, so dropped as excess structure -->
<xsl:template match="glossary/terms" mode="repair">
    <xsl:apply-templates select="defined-term" mode="repair"/>
</xsl:template>

<!-- "defined-term" was structured, so we just select elements -->
<xsl:template match="glossary/terms/defined-term" mode="repair">
    <gi>
        <xsl:apply-templates select="*|@*" mode="repair"/>
    </gi>
</xsl:template>

<!-- no more "conclusion", so drop it here; deprecation will warn -->
<xsl:template match="glossary/conclusion" mode="repair"/>

<!-- 2022-04-22 replace Python Tutor with Runestone CodeLens -->
<xsl:template match="program/@interactive" mode="repair">
    <xsl:choose>
        <xsl:when test=". = 'pythontutor'">
            <xsl:attribute name="interactive">
                <xsl:text>codelens</xsl:text>
            </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- 2022-04-25 @label deprecated, slated for renewal in starring  -->
<!-- role. Lists with markers (not description lists) -->
<xsl:template match="ol/@label|ul/@label" mode="repair">
    <xsl:attribute name="marker">
        <xsl:value-of select="."/>
    </xsl:attribute>
</xsl:template>

<!-- 2022-04-24 An exception, label on video tracks mimicing HTML -->
<xsl:template match="video/track/@label" mode="repair">
    <xsl:attribute name="listing">
        <xsl:value-of select="."/>
    </xsl:attribute>
</xsl:template>

<!-- 2022-06-09 WeBWorK "stage" deprecated in favor of "task"       -->
<!-- We could use  match="webwork/stage"  but then this would only  -->
<!-- happen to the author's source while being prepared for the     -->
<!-- "extract-pg.xsl" worksheet.  But we also want to catch "stage" -->
<!-- coming back from an old WeBWorK server, which may be various   -->
<!-- places after we algorithmically manipulate the "webwork-reps"  -->
<!-- structure.  Instead, we just wait until now.  If necessary,    -->
<!-- perhaps "exercise/stage" for the post-server pass.             -->
<xsl:template match="stage" mode="repair">
    <task>
        <xsl:apply-templates select="node()|@*" mode="repair"/>
    </task>
</xsl:template>

<!-- 2022-07-10 webwork//latex-image[syntax='PGtikz'] deprecated    -->
<!-- to just a normal latex-image. The text content for the code    -->
<!-- must be wrapped in a tikzpicture environment.                  -->
<xsl:template match="latex-image[@syntax='PGtikz']" mode="repair">
    <xsl:copy>
        <!-- we drop the @syntax attribute -->
        <xsl:apply-templates select="node()|@*[not(local-name(.) = 'syntax')]" mode="repair"/>
    </xsl:copy>
</xsl:template>
<xsl:template match="latex-image[@syntax='PGtikz']/text()" mode="repair">
    <xsl:text>\begin{tikzpicture}&#xa;</xsl:text>
    <xsl:call-template name="sanitize-latex">
        <xsl:with-param name="text">
            <xsl:copy>
                <xsl:apply-templates select="."/>
            </xsl:copy>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>&#xa;\end{tikzpicture}&#xa;</xsl:text>
</xsl:template>

<!-- Due to naivete, we had empty templates for "keyboard characters"    -->
<!-- we did not have the skills to handle.  A good example was <dollar/> -->
<!-- simply because it is a (very) special character in LaTeX.  These    -->
<!-- were deprecated on 2019-02-06.  Beginning in 2022-12-26, we are     -->
<!-- providing fixes here, and removing all the (dead) code meant for    -->
<!-- backward compatibility.                                             -->

<!-- XML characters -->

<xsl:template match="less" mode="repair">
    <xsl:text>&lt;</xsl:text>
</xsl:template>

<xsl:template match="greater" mode="repair">
    <xsl:text>&gt;</xsl:text>
</xsl:template>

<!-- Ten LaTeX characters -->
<!-- # $ % ^ & _ { } ~ \  -->

<xsl:template match="hash" mode="repair">
    <xsl:text>#</xsl:text>
</xsl:template>

<xsl:template match="ampersand" mode="repair">
    <xsl:text>&amp;</xsl:text>
</xsl:template>

<xsl:template match="dollar" mode="repair">
    <xsl:text>$</xsl:text>
</xsl:template>

<xsl:template match="percent" mode="repair">
    <xsl:text>%</xsl:text>
</xsl:template>

<xsl:template match="circumflex" mode="repair">
    <xsl:text>^</xsl:text>
</xsl:template>

<xsl:template match="underscore" mode="repair">
    <xsl:text>_</xsl:text>
</xsl:template>

<xsl:template match="lbrace" mode="repair">
    <xsl:text>{</xsl:text>
</xsl:template>

<xsl:template match="rbrace" mode="repair">
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="tilde" mode="repair">
    <xsl:text>~</xsl:text>
</xsl:template>

<xsl:template match="backslash" mode="repair">
    <xsl:text>\</xsl:text>
</xsl:template>

<!-- Lesser keyboard characters -->
<!-- [, ], *, /, `,             -->

<xsl:template match="lbracket" mode="repair">
    <xsl:text>[</xsl:text>
</xsl:template>

<xsl:template match="rbracket" mode="repair">
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Grouping constructions  -->
<!-- "braces" and "brackets" -->

<xsl:template match="braces" mode="repair">
    <xsl:text>{</xsl:text>
    <!-- attributes will be lost -->
    <xsl:apply-templates select="node()" mode="repair"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="brackets" mode="repair">
    <xsl:text>[</xsl:text>
    <!-- attributes will be lost -->
    <xsl:apply-templates select="node()" mode="repair"/>
    <xsl:text>]</xsl:text>
</xsl:template>


<!-- This pass adds 100% internal identification for elements after a   -->
<!-- version has been constructed, but before anything else is added or -->
<!-- manipulated.  The tree it builds is used for constructing          -->
<!-- "View Source" knowls in HTML output as a form of always-accurate   -->
<!-- documentation.  This id might be useful in other scenarios so we   -->
<!-- build it with some care.  Entirely possible that the final pass of -->
<!-- this stylesheet will have produced times which in HTML there is no -->
<!-- real original.  So maybe not perfect.  But good enough?            -->
<!--                                                                    -->
<!-- Key properties of the id:                                          -->
<!--     - built with descent through tree, so fast                     -->
<!--     - unique (numbers give depth and breadth within subtree)       -->
<!--     - resets on discovered @xml:id                                 -->
<!--     - minimal computation (counting siblings)                      -->
<!--     - somewhat insensitive to source edits far away                -->
<xsl:template match="*" mode="original-labels">
    <xsl:param name="parent-id" select="'root-'"/>

    <xsl:copy>
        <!-- duplicate all existing attributes, -->
        <xsl:apply-templates select="@*" mode="original-labels"/>
        <!-- capture the id we will use *and* build upon -->
        <xsl:variable name="new-id">
            <xsl:choose>
                <!-- authored @xml:id, so reset to this subtree -->
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$parent-id"/>
                    <!-- This particular letter is totally irrelevant, could    -->
                    <!-- be a dash, it is just a separator.  We don't want the  -->
                    <!-- numbers (next) to coalesce ( 2,13 = 21,3 = "213" ) and -->
                    <!-- wreck uniqueness.  But a hint of an element name may   -->
                    <!-- make some debugging activity easier.                   -->
                    <xsl:value-of select="substring(local-name(), 1, 1)"/>
                    <!-- Location *within its level* of the tree, while level    -->
                    <!-- itself is implicit in the number of separator letters   -->
                    <!-- accumulated.  This makes this string unique within      -->
                    <!-- the subtree rooted at the most recent authored @xml:id. -->
                    <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Add this id as an attribute -->
        <xsl:attribute name="original-id">
            <xsl:value-of select="$new-id"/>
        </xsl:attribute>
        <!-- If we have reset to a subtree (due to an authored @xml:id) -->
        <!-- then we want a dash after the value of @xml:id and the     -->
        <!-- sequence of letters and numbers (but *not* as part of the  -->
        <!-- id we just added).  We smoosh this on as a concatenation   -->
        <!-- in recursion just below.                                   -->
        <xsl:variable name="lead-separator">
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:text>-</xsl:text>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>
         <!-- Attributes done, recurse into children  -->
         <!-- nodes, passing updated id, possible sep -->
        <xsl:apply-templates select="node()" mode="original-labels">
            <xsl:with-param name="parent-id" select="concat($new-id, $lead-separator)"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>


<!-- ############## -->
<!-- Identification -->
<!-- ############## -->

<!-- For generated identifiers we reserve a separator string for    -->
<!-- internal use, this could also be used to identify authored     -->
<!-- @xml:id and authored @label.  Either on the fly, or as a late  -->
<!-- task in the pre-processor.  We allow a dash and an underscore  -->
<!-- as non-letter characters.  Every other character is a bad idea -->
<!-- when we create variables for languages, WeBWork, LaTeX, etc.   -->
<!-- Good reasons not to use a dollar sign (LaTeX, Perl, WeBWork,   -->
<!-- XSL) or a period (object/method notation in Python or          -->
<!-- Javascript).  Even a dash/hyphen is a bad idea - it is not     -->
<!-- legal in Javascript variables, and is a minus sign in Python.  -->
<!-- So we have a sanitization template below.                      -->
<!--                                                                -->
<!-- Back on task, the string defined here could be made more       -->
<!-- complicated, if it turns out to be insufficient.               -->
<xsl:variable name="gen-id-sep" select="'_-_'"/>

<!-- The "visible-id" template switched to prefer @label,         -->
<!-- rather than @xml:id (at 1779e6dbc84c6ecc).  So to preserve   -->
<!-- authored (crafted) identifier strings, we copy the old over  -->
<!-- into the new.  This preserves identifiers in output          -->
<!-- (filenames, fragment identifiers).  Subsequent passes        -->
<!-- should not introduce or remove elements.                     -->

<!-- NB: this template is "in progresss".  Likely we will -->
<!-- generate manufactured @label (recursively) for many  -->
<!-- elements, which will cause changes in how the        -->
<!-- "visible-id" template behaves.                       -->
<xsl:template match="*" mode="identification">
    <xsl:param name="parent-id"  select="'root-'"/>
    <xsl:copy>
        <!-- duplicate all attributes, especially  -->
        <!-- preserve any authored @xml:id, @label -->
        <xsl:apply-templates select="@*" mode="identification"/>
        <!-- We fix up two identifiers, we assume authored @label are rarest, -->
        <!-- and then authored @xml:id, in order to minimize tests (rather    -->
        <!-- than the overhead of making two variables and checking them).    -->
        <!-- [Probably unnecessary]                                           -->
        <xsl:choose>
            <xsl:when test="not(@xml:id) and not(@label)"/>
            <xsl:when test="@xml:id and not(@label)">
                <xsl:attribute name="label">
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:when test="not(@xml:id) and @label"/>
            <!-- both thoughtfully authored, nothing to do -->
            <xsl:when test="@xml:id and @label"/>
        </xsl:choose>
        <!-- The following is experimental as of 2022-11-18, but will likely              -->
        <!-- become a good model for an auto-generated @label in the absence              -->
        <!-- of any other authored string.                                                -->
        <!--                                                                              -->
        <!-- * Strategy is much like @original-id but maybe needs as much care            -->
        <!-- * Effectively an @xml:id can be promoted to a @label by the first two "when" -->
        <!-- * Element counts are used in base 26 via a lower-case alphabet               -->
        <!-- * Separators are dashes, not initial letters of element names                -->
        <!-- * Colons as separators might create confusion with namespaces                -->
        <!-- * Prefixed with a full element name aids debugging                           -->
        <!-- * Salt (digits) added to authored values may decrease risk of collision      -->
        <xsl:variable name="new-latex-id">
            <xsl:choose>
                <xsl:when test="@label">
                    <xsl:value-of select="@label"/>
                    <!-- add SALT to prevent collisions -->
                </xsl:when>
                <!-- this mimics the upgrade of an authored xml:id to a label -->
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                    <!-- add SALT to prevent collisions -->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$parent-id"/>
                    <!-- With a colon, the value is not an "NCname" - a "non-colonized" name.    -->
                    <!-- So fails as source material.  Unclear why we can use it in these trees. -->
                    <!-- Anyway, perhaps good to avoid.                                          -->
                    <!-- non-alphabetic seprator needed for uniqueness                           -->
                    <xsl:text>-</xsl:text>
                    <!-- A base 26 experiment (which is how 27, 28,... seem to be represented).  -->
                    <!-- Zero is rendered as "0", thus the "+ 1" is necessary.                   -->
                    <xsl:number value="count(preceding-sibling::*) + 1" format="a"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- aids debugging/portabiity somewhat -->
        <xsl:variable name="element-name" select="local-name()"/>
        <xsl:attribute name="latex-id">
            <xsl:value-of select="concat($element-name, '-', $new-latex-id)"/>
        </xsl:attribute>
        <!-- recurse -->
        <xsl:apply-templates select="node()" mode="identification">
            <xsl:with-param name="parent-id" select="$new-latex-id"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- There is no real putpose to put an @xml:id onto an (X)HTML -->
<!-- element floating around as part of an interactive.         -->
<xsl:template match="xhtml:*" mode="identification">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()" mode="identification"/>
    </xsl:copy>
</xsl:template>

<!-- We look for duplicate identifiers both right after    -->
<!-- assembly and right after automatic generation.  The   -->
<!-- application of these templates is mixed-in to the     -->
<!-- creation of the trees.                                -->
<!-- NB: these two templates are identical (keep it that   -->
<!-- way!) because we can't see how to make the attribute  -->
<!-- itself a parameter.                                   -->
<!-- NB: these were built as regular templates and the     -->
<!-- root of the relevant tree was passed in, this created -->
<!-- some error with the construction of the final tree:   -->
<!-- "Recursive definition of root"                        -->
<xsl:template name="duplication-check-xmlid">
    <!-- pass in all elements with @xml:id attributes -->
    <xsl:param name="nodes"/>
    <!-- 'authored' or 'generated', just influences messages -->
    <xsl:param name="purpose"/>

    <xsl:for-each select="$nodes">
        <!-- save off the string on current node -->
        <xsl:variable name="the-id" select="string(./@xml:id)"/>
        <!-- locate all elements that are duplicates of this one -->
        <xsl:variable name="duplicates" select="$nodes[@xml:id = $the-id]"/>
        <!-- warn only for the element that occurs earliest in the duplicate list -->
        <xsl:if test="(count($duplicates) > 1) and (count(.|$duplicates[1]) = 1)">
            <xsl:choose>
                <xsl:when test="$purpose = 'authored'">
                    <xsl:message>PTX:ERROR: the @xml:id value "<xsl:value-of select="$the-id"/>" should be unique, but is authored <xsl:value-of select="count($duplicates)"/> times.</xsl:message>
                </xsl:when>
            </xsl:choose>
            <xsl:message>           Results will be unpredictable, and likely incorrect.  Information on the locations follows:</xsl:message>
            <xsl:for-each select="$duplicates">
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:for-each>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<xsl:template name="duplication-check-label">
    <!-- pass in all elements with @label attributes -->
    <xsl:param name="nodes"/>
    <!-- 'authored' or 'generated', just influences messages -->
    <xsl:param name="purpose"/>

    <xsl:for-each select="$nodes">
        <!-- save off the string on current node -->
        <xsl:variable name="the-id" select="string(./@label)"/>
        <!-- locate all elements that are duplicates of this one -->
        <xsl:variable name="duplicates" select="$nodes[@label = $the-id]"/>
        <!-- warn only for the element that occurs earliest in the duplicate list -->
        <xsl:if test="(count($duplicates) > 1) and (count(.|$duplicates[1]) = 1)">
            <xsl:choose>
                <xsl:when test="$purpose = 'authored'">
                    <xsl:message>PTX:ERROR: the @label value "<xsl:value-of select="$the-id"/>" should be unique, but is authored <xsl:value-of select="count($duplicates)"/> times.</xsl:message>
                </xsl:when>
            </xsl:choose>
            <xsl:message>           Results will be unpredictable, and likely incorrect.  Information on the locations follows:</xsl:message>
            <xsl:for-each select="$duplicates">
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:for-each>
        </xsl:if>
    </xsl:for-each>
</xsl:template>


<!-- ######### -->
<!-- Languages -->
<!-- ######### -->

<!-- The variable $locales is a node-set of all the locales which have    -->
<!-- supported localization files.  A comparison of an @xml:lang (string) -->
<!-- with $locales (node-set) will be true if the attribute value is a    -->
<!-- string value of one of the nodes in the node-set.  So it is easy to  -->
<!-- create a boolean value for localization support .                    -->
<xsl:variable name="locales" select="document('localizations/localizations.xml')/localizations/locale" />

<!-- We want the root node to always have full and accurate language         -->
<!-- information since it will be the fail-safe node on a query up the tree. -->
<!-- Earlier "repair" pass eliminates "mathbook".                            -->
<xsl:template match="/pretext" mode="language">
    <!-- see above description of $locales, false if missing -->
    <xsl:variable name="b-is-supported" select="@xml:lang = $locales"/>
    <!-- duplicate with better language information -->
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="language"/>
        <xsl:choose>
            <xsl:when test="$b-is-supported">
                <!-- if supported, it was just duplicated, save off a -->
                <!-- new attribute indicating use for localizations   -->
                <xsl:attribute name="locale-lang">
                    <xsl:value-of select="@xml:lang"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <!-- if missing we add the default          -->
                <!-- if unsupported, overwrite with default -->
                <xsl:attribute name="xml:lang">
                    <xsl:text>en-US</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="locale-lang">
                    <xsl:text>en-US</xsl:text>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="node()" mode="language"/>
    </xsl:copy>
</xsl:template>

<!-- An  @xml:id  is checked to see if it is supported for localizations.  -->
<!-- If so, we augment the elment with an internal attribute.  If not,     -->
<!-- we just leave a copy alone, it might be relevant for future features. -->
<xsl:template match="*[@xml:lang]" mode="language">
    <!-- see above description of $locales -->
    <xsl:variable name="b-is-supported" select="@xml:lang = $locales"/>
    <!-- duplicate with additional language information -->
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="language"/>
        <xsl:if test="$b-is-supported">
            <xsl:attribute name="locale-lang">
                <xsl:value-of select="@xml:lang"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="node()" mode="language"/>
    </xsl:copy>
</xsl:template>

<!-- ######## -->
<!-- Versions -->
<!-- ######## -->

<xsl:template match="*" mode="version">
    <xsl:choose>
        <!-- version scheme not elected, so use element no matter what -->
        <xsl:when test="$components-fenced = ''">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="version"/>
            </xsl:copy>
        </xsl:when>
        <!-- version scheme elected, but element not participating, -->
        <!-- so a 100% un-tagged element is included by default     -->
        <xsl:when test="not(@component)">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="version"/>
            </xsl:copy>
        </xsl:when>
        <!-- version scheme elected, element participating, so use element -->
        <!-- if it is a component in publisher's selection of components   -->
        <xsl:when test="@component">
            <xsl:variable name="single-component-fenced" select="concat('|', normalize-space(@component), '|')"/>
            <xsl:if test="contains($components-fenced, $single-component-fenced)">
                <xsl:copy>
                    <xsl:apply-templates select="node()|@*" mode="version"/>
                </xsl:copy>
            </xsl:if>
            <!-- scheme in publisher file, element tagged,    -->
            <!-- but not elected, hence element dropped here  -->
        </xsl:when>
        <!-- previous two "when" mutually-exclusive, -->
        <!-- thus we should not ever reach here      -->
        <xsl:otherwise/>
    </xsl:choose>
</xsl:template>

<!-- ######### -->
<!-- Numbering -->
<!-- ######### -->

<!-- We use the "augment" pass to compute, and add, partially naïve        -->
<!-- information about numbers of objects, to be interpreted later by      -->
<!-- templates in the "-common" stylesheet.  By "naïve" we mean that       -->
<!-- these routines may depend on publisher variables (e.g. specification  -->
<!-- of roots of subtrees for serial numbers of blocks) but do not depend  -->
<!-- on subtlties of numbering (such as the structured/unstructured        -->
<!-- division dichotomy), which are addressed in the "-common" stylesheet. -->
<!-- In this way, this information could be interpreted in new ways by     -->
<!-- additional conversions.                                               -->
<!--                                                                       -->
<!-- The manufactured @struct attribute is the (naïve) hierarchical number -->
<!-- of the *container* of an element, known as the "structure number"     -->
<!-- of an element.  The @serial attribute is the computed serial number   -->
<!-- of the element, known as the "serial number".  Typically combining    -->
<!-- these two attributes forms teh number of an element.  As many         -->
<!-- practical subtleties about these numbers is delayed until their       -->
<!-- interpretation by templates in the "-common" stylesheet.              -->

<!-- For every type of division, everywhere, the "division-serial-number"   -->
<!-- modal template will return a count of preceding peers at that level.   -->
<!-- The @struct attribute is the structure number of the *parent*          -->
<!-- (container), which seems odd here, but fits the general scheme better. -->
<!-- The @level attribute is helpful, and trvislly to compute here.         -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|exercises|solutions|reading-questions|references|glossary|worksheet" mode="augment">
    <xsl:param name="parent-struct"/>
    <xsl:param name="level"/>

    <xsl:variable name="the-serial">
        <xsl:apply-templates select="." mode="division-serial-number"/>
    </xsl:variable>
    <xsl:variable name="new-struct">
        <xsl:choose>
            <!-- Parts as Roman numerals make for a lot of clutter.      -->
            <!-- We tend to only use them when necessary to diambiguate  -->
            <!-- a cross-reference in the case where these numbers are   -->
            <!-- structural.  So rightly or wrongly, and owing to        -->
            <!-- historical work, we squelch them as the lead item of a  -->
            <!-- structural number.  So here the Roman numeral will be   -->
            <!-- preserved as a serial number, but the construction of   -->
            <!-- the structural numbers will be delayed one level.       -->
            <!-- (It seems harder to strip these in -common.)            -->
            <xsl:when test="self::part"/>
            <xsl:otherwise>
                <xsl:value-of select="$parent-struct"/>
                <xsl:if test="not($parent-struct='')">
                    <xsl:text>.</xsl:text>
                </xsl:if>
                <xsl:value-of select="$the-serial"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="next-level" select="$level + 1"/>
    <xsl:copy>
        <xsl:attribute name="struct">
            <xsl:value-of select="$parent-struct"/>
        </xsl:attribute>
        <xsl:attribute name="serial">
            <xsl:value-of select="$the-serial"/>
        </xsl:attribute>
        <xsl:attribute name="level">
            <xsl:value-of select="$next-level"/>
        </xsl:attribute>
        <xsl:apply-templates select="node()|@*" mode="augment">
            <xsl:with-param name="parent-struct" select="$new-struct"/>
            <xsl:with-param name="level" select="$next-level"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- See the definitions of levels in -common.  For a book with parts   -->
<!-- ($parts != 'absent') we consider parts as peers of frontmatter and -->
<!-- backmatter.  So we need to increment the level in this case, only. -->
<!-- NB: this might consolidate with above, but seems better solo.      -->
<!-- NB: with some study and work, this situation might be improved?    -->
<xsl:template match="frontmatter|backmatter" mode="augment">
    <xsl:param name="parent-struct"/>
    <xsl:param name="level"/>

    <xsl:variable name="next-level">
        <xsl:choose>
            <xsl:when test="($parts = 'decorative') or ($parts = 'structural')">
                <xsl:value-of select="$level + 1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$level"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- we only add a level (not necessary?) -->
    <!-- and just pass along structure number -->
    <xsl:copy>
        <xsl:attribute name="level">
            <xsl:value-of select="$next-level"/>
        </xsl:attribute>
        <xsl:apply-templates select="node()|@*" mode="augment">
            <xsl:with-param name="parent-struct" select="$parent-struct"/>
            <xsl:with-param name="level" select="$next-level"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- ######### -->
<!-- Exercises -->
<!-- ######### -->

<!-- Exercises, and their kin, are complicated.  They come in five types   -->
<!-- (inline, divisional, reading, worksheet, project-like) based largely  -->
<!-- on location.  They can be static, interactive in HTML, interactive    -->
<!-- on a server.  Interactive versions come in many flavors, such as      -->
<!-- short answer, multiple choice, true/false, Parson, matching, fill-in, -->
<!-- and so on.  Their solutions (hint, answer, solution) apear, or do not -->
<!-- appear, where born or in specialized "solutions" divisions.  We       -->
<!-- scribble on each to record as much as we can right now.  It'll be     -->
<!-- useful below and forever.                                             -->

<!-- Record exercise ancestors/location-->
<!-- An "exercise" can be in one of four places.  We reset the parameter   -->
<!-- as we pass through.  Default is "inline" and we initialize with that  -->
<!-- value.  These three specialized divisions are always terminal, so we  -->
<!-- will never find an inline exercise contained within.  We allow        -->
<!-- publisher customization of exercises based on these locations, *and*  -->
<!-- for project-like.  These templates are just about divisions.          -->

<xsl:template match="reading-questions" mode="exercise">
    <xsl:param name="division"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="exercise">
            <xsl:with-param name="division" select="'reading'"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<xsl:template match="worksheet" mode="exercise">
    <xsl:param name="division"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="exercise">
            <xsl:with-param name="division" select="'worksheet'"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<xsl:template match="exercises" mode="exercise">
    <xsl:param name="division"/>

    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="exercise">
            <xsl:with-param name="division" select="'divisional'"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- Annotate "exercise" and PROJECT-LIKE -->
<!-- Pre-processing here is entirely about supporting interactive       -->
<!-- exercises powered by Runestone Services.  We allow publisher       -->
<!-- options to control interactivity of "short answer" questions       -->
<!-- when hosted on a server, so that is why locations are being noted. -->
<!--   1.  "exercise-customization" refers to the situation where       -->
<!--       certain publication options can vary behavior or visibility  -->
<!--   2.  "exercise-interactive" refers to the type of                 -->
<!--        interactivity, "static" is the default                      -->
<!--                                                                    -->
<!-- TODO:                                                              -->
<!-- 1.  Expand to WW, example-like, and task                           -->
<!-- 2.  Insert "statement" when not authored                           -->
<!-- 3.  Use locations computed here, remove elsewhere                  -->
<!-- 4.  Recognize new, modern fill-in problems                         -->

<xsl:template match="exercise|&PROJECT-LIKE;|task" mode="exercise">
    <xsl:param name="division"/>

    <xsl:copy>
        <!-- Record one of five categories for customization, which    -->
        <!-- are not relevant for "example" (always inline), or "task" -->
        <!-- (always just a component of something larger).  WeBWork   -->
        <!-- problems are interactive or static, inline or not, based  -->
        <!-- on publisher options.                                     -->
        <xsl:if test="not(self::task)">
            <xsl:attribute name="exercise-customization">
                <xsl:choose>
                    <xsl:when test="&PROJECT-FILTER;">
                        <xsl:text>project</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$division"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </xsl:if>
        <!-- Determine and record types of interactivity -->
        <xsl:apply-templates select="." mode="exercise-interactive-attribute"/>
        <!-- catch remaining attributes -->
        <xsl:apply-templates select="@*" mode="exercise">
            <xsl:with-param name="division" select="$division"/>
        </xsl:apply-templates>
        <!-- Now the child elements -->
        <!-- NB: this would be a place to insert a "statement" for  -->
        <!-- "exercise", "example", "project" and "task", for which -->
        <!-- an author has not needed/elected to use one.           -->
        <xsl:apply-templates select="node()" mode="exercise">
            <xsl:with-param name="division" select="$division"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<!-- These "interactivity types" are meant for Runestone-enabled  -->
<!-- interactive exercises and projects                           -->
<xsl:template match="*" mode="exercise-interactive-attribute">
    <xsl:attribute name="exercise-interactive">
        <xsl:choose>
            <!-- This is defensive, so statement//var below does not   -->
            <!-- match for WW.  Ancestor varies on extraction, or not. -->
            <xsl:when test="self::task and (ancestor::webwork|ancestor::webwork-reps)">
                <xsl:text>webwork-task</xsl:text>
            </xsl:when>
            <!-- WeBWorK next, signal is clear.  Again, -->
            <!-- two passes and we identify which one.  -->
            <xsl:when test="webwork and $b-extracting-pg">
                <xsl:text>webwork-authored</xsl:text>
            </xsl:when>
            <xsl:when test="webwork-reps and not(b-extracting-pg)">
                <xsl:text>webwork-reps</xsl:text>
            </xsl:when>
            <xsl:when test="myopenmath">
                <xsl:text>myopenmath</xsl:text>
            </xsl:when>
            <!-- hack for temporary demo HTML versions -->
            <xsl:when test="@runestone">
                <xsl:text>htmlhack</xsl:text>
            </xsl:when>
            <!-- true/false -->
            <xsl:when test="statement/@correct">
                <xsl:text>truefalse</xsl:text>
            </xsl:when>
            <!-- multiple choice -->
            <xsl:when test="statement and choices">
                <xsl:text>multiplechoice</xsl:text>
            </xsl:when>
            <!-- vertical is default/traditional -->
            <xsl:when test="statement and blocks and not(blocks/@layout = 'horizontal')">
                <xsl:text>parson</xsl:text>
            </xsl:when>
            <xsl:when test="statement and blocks and (blocks/@layout = 'horizontal')">
                <xsl:text>parson-horizontal</xsl:text>
            </xsl:when>
            <xsl:when test="statement and matches">
                <xsl:text>matching</xsl:text>
            </xsl:when>
            <xsl:when test="statement and areas">
                <xsl:text>clickablearea</xsl:text>
            </xsl:when>
            <!-- noted WeBWork earlier, so this is Runestone fillin -->
            <xsl:when test="statement//var">
                <xsl:text>fillin-basic</xsl:text>
            </xsl:when>
            <!-- new dynamic fillin goes here, perhaps:                     -->
            <!-- statement//fillin[(@*|node()) and not(@characters|@fill)]? -->
            <!-- only interactive programs make sense after a "statement" -->
            <xsl:when test="statement and program[(@interactive = 'codelens') or (@interactive = 'activecode')]">
                <xsl:text>coding</xsl:text>
            </xsl:when>
            <xsl:when test="statement and response">
                <xsl:text>shortanswer</xsl:text>
            </xsl:when>
            <!-- That's it, we are out of opportunities to be interactive -->

            <!-- A child that is a task indicates the exercise/project/task -->
            <!-- that is its parent is simply a container, rather than a    -->
            <!-- terminal task which would be structured with a "statement" -->
            <!-- in order to be interactive                                 -->
            <xsl:when test="task">
                <xsl:text>container</xsl:text>
            </xsl:when>
            <!-- Now we have what once would have been called a "traditional"     -->
            <!-- PreTeXt question, which is just "statement|hint|answer|solution" -->
            <!-- Or maybe just a bare statement that is not structured as such    -->
            <xsl:otherwise>
                <xsl:text>static</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:attribute>
</xsl:template>


<!-- ############### -->
<!-- Representations -->
<!-- ############### -->

<!-- Build multiple (two) representations of exercises that are produced  -->
<!-- in static (almost everything) and dynamic (HTML) versions.            -->
<!-- Generally these templates are parameterized by the $exercise-style   -->
<!-- variable/parameter.  We need the parameterization, since we do not   -->
<!-- want to make *multiple* copies of each exercise in the source, since -->
<!-- then duplicate items might confuse later templates e.g numbering).   -->
<!--                                                                      -->
<!-- A "static" version should be entirely in the style of a "regular"    -->
<!-- PreTeXt exercise, having a statement|hint|answer|solution structure. -->
<!-- Then it can be leveraged through all the infrastructure for things   -->
<!-- like solutions manuals and non-capable output formats.               -->
<!--                                                                      -->
<!-- A "dynamic" version is simply a duplicate of the author's source,    -->
<!-- which is handled by templates elsewhere, applied in the HTML         -->
<!-- conversion itself.                                                   -->

<!-- Hacked -->
<!-- Will eventually be obsolete -->

<xsl:template match="exercise[@exercise-interactive = 'htmlhack']" mode="representations">
    <xsl:choose>
        <xsl:when test="$exercise-style = 'static'">
            <!-- punt for static versions, we have nothing -->
            <exercise>
                <statement>
                    <p>An interactive Runestone problem goes here, but there is not yet a static representation.</p>
                </statement>
            </exercise>
        </xsl:when>
        <xsl:when test="$exercise-style = 'dynamic'">
            <!-- pass on to the HTML conversion -->
            <xsl:copy-of select="."/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- True/False        -->
<!-- Multiple Choice   -->
<!-- Parson problems   -->
<!-- Matching problems -->
<!-- Clickable Area    -->
<!-- ActiveCode        -->

<!-- TODO: definitely need better filters -->
<!-- complement (not()), single attribute -->
<!-- Also in Runestone manifest creation  -->

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
                               (@exercise-interactive = 'parson-horizontal') or
                               (@exercise-interactive = 'matching') or
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
                               (@exercise-interactive = 'shortanswer')]" mode="representations">
    <!-- always preserve "exercise/project" container here, with attributes -->
    <xsl:copy>
        <xsl:apply-templates select="@*" mode="representations"/>
        <xsl:choose>
            <!-- make a static version, in a PreTeXt   -->
            <!-- statement|hint|answer|solution style  -->
            <!-- for use naturally by most conversions -->
            <xsl:when test="$exercise-style = 'static'">
                <xsl:apply-templates select="." mode="runestone-to-static"/>
            </xsl:when>
            <!-- duplicate for a dynamic version -->
            <xsl:when test="$exercise-style = 'dynamic'">
                <xsl:apply-templates select="node()" mode="representations"/>
            </xsl:when>
        </xsl:choose>
    </xsl:copy>
</xsl:template>

<!-- Static (non-interactive) -->
<!-- @exercise-interactive = 'static' needs no adjustments -->

<!-- PG Code from webwork-reps for problem sets -->

<!-- Matching with the filter means this will only happen on     -->
<!-- the non-extraction pass, since the 'webwork-reps' value     -->
<!-- is placed after the WW representations file has been built. -->
<!-- NB: including "task" though this may not be supported.      -->
<xsl:template match="exercise[(@exercise-interactive = 'webwork-reps')]
                   | project[(@exercise-interactive = 'webwork-reps')]
                   | activity[(@exercise-interactive = 'webwork-reps')]
                   | exploration[(@exercise-interactive = 'webwork-reps')]
                   | investigation[(@exercise-interactive = 'webwork-reps')]" mode="representations">
    <xsl:choose>
        <!-- destined for creating problem sets, really just need PG code -->
        <xsl:when test="$exercise-style = 'pg-problems'">
            <!-- duplicate exercise, task, PROJECT-LIKE -->
            <xsl:copy>
                <!-- and duplicate the associated attributes, while moving to new mode -->
                <xsl:apply-templates select="@*" mode="webwork-rep-to-pg"/>
                <!-- for building problem sets, we do not need much metadata,      -->
                <!-- nor the connecting "introduction" or "conclusion", we just    -->
                <!-- want to make the PG code available in a predictable way       -->
                <!-- (see templates following).  But we do need a title for naming -->
                <!-- files and building the set definition files pointing to them. -->
                <xsl:apply-templates select="title" mode="webwork-rep-to-pg"/>
                <xsl:apply-templates select="webwork-reps" mode="webwork-rep-to-pg"/>
            </xsl:copy>
        </xsl:when>
        <!-- static, for multiple conversions, but primarily LaTeX -->
        <xsl:when test="$exercise-style = 'static'">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-static"/>
            </xsl:copy>
        </xsl:when>
        <!-- dynamic (aka HTML), needs static previews, server base64, etc, -->
        <!-- so just copy as-is with "webwork-reps" to signal and organize  -->
        <!-- to/for HTML conversion                                         -->
        <xsl:otherwise>
            <xsl:copy>
                <xsl:apply-templates select="node()|@*" mode="representations"/>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Edit a "webwork-reps" from the server into just PG material -->
<xsl:template match="node()|@*" mode="webwork-rep-to-pg">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-pg"/>
    </xsl:copy>
</xsl:template>

<!-- Promote "pg" specific information to "webwork-reps" -->
<xsl:template match="webwork-reps" mode="webwork-rep-to-pg">
    <xsl:copy>
        <!-- copy existing attributes -->
        <xsl:apply-templates select="@*" mode="webwork-rep-to-pg"/>
        <!-- promote "pg" attributes (@source, @copied-from) -->
        <xsl:apply-templates select="pg/@*" mode="webwork-rep-to-pg"/>
        <!-- attributes done, recurse into child *elements*  -->
        <!-- no node() here, so drops interstial whitespace  -->
        <!-- that accumulates into the textual PG code, even -->
        <!-- if it does get sanitized in its use/application -->
        <xsl:apply-templates select="*" mode="webwork-rep-to-pg"/>
    </xsl:copy>
</xsl:template>

<!-- Attributes preserved, drop "pg" element, duplicate the guts -->
<!-- which should just be the actual PG version of the problem   -->
<xsl:template match="webwork-reps/pg" mode="webwork-rep-to-pg">
    <xsl:apply-templates select="node()" mode="webwork-rep-to-pg"/>
</xsl:template>

<!-- Drop "webwork-reps" children we don't need for problem sets -->
<xsl:template match="webwork-reps/static" mode="webwork-rep-to-pg"/>
<xsl:template match="webwork-reps/server-data" mode="webwork-rep-to-pg"/>


<!-- Static from webwork-reps as a generic exercise  -->
<!-- Edit a "webwork-reps" from the server into guts -->
<!-- of a static exercise or PROJECT-LIKE            -->

<!-- Kill author's lead-in/lead-out material on sight, we recreate -->
<!-- their children with "node()" in main reorganization template  -->
<xsl:template match="introduction[following-sibling::webwork-reps]" mode="webwork-rep-to-static"/>
<xsl:template match="conclusion[preceding-sibling::webwork-reps]" mode="webwork-rep-to-static"/>

<!-- Meld an author's "introduction" and "conclusion" into          -->
<!-- (a) the similarly-named items of a task-structured object      -->
<!-- (b) the statement of an object with a simpler structure        -->
<!-- We recurse into (many, principal) selected components of       -->
<!-- webwork-reps/static which effectively ignores  webwork-reps/pg -->
<!-- and  webwork-reps/server  so these pieces never make it into   -->
<!-- the assembled source.                                          -->
<!--                                                                -->
<!-- NB: we lose some attributes attached above to                  -->
<!-- "introduction" and "conclusion" (not "exercise"), BUT          -->
<!--   (i) we cannot point *into* a WW problem (no targets)         -->
<!--   (ii) we do not have numbered items (eg Figure)               -->
<!--   (iii) by removing them, we just disrupt any                  -->
<!--         sequences, and uniqueness is preserved                 -->
<!--   (iv) we could figure out which ones to copy where, if needed -->
<xsl:template match="webwork-reps" mode="webwork-rep-to-static">
    <xsl:choose>
        <!-- a WW "staged" exercise, may have an top-level introduction and -->
        <!-- conclusion already, and does not have a top-level statement    -->
        <xsl:when test="static/task">
            <xsl:if test=".//introduction|static/introduction">
                <introduction>
                    <xsl:apply-templates select="../introduction/node()" mode="webwork-rep-to-static"/>
                    <xsl:apply-templates select="static/introduction/node()" mode="webwork-rep-to-static"/>
                </introduction>
            </xsl:if>
            <xsl:apply-templates select="static/task" mode="webwork-rep-to-static"/>
            <xsl:if test="../conclusion|static/conclusion">
                <conclusion>
                    <xsl:apply-templates select="../conclusion/node()" mode="webwork-rep-to-static"/>
                    <xsl:apply-templates select="static/conclusion/node()" mode="webwork-rep-to-static"/>
                </conclusion>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <statement>
                <xsl:apply-templates select="../introduction/node()" mode="webwork-rep-to-static"/>
                <xsl:apply-templates select="static/statement/node()" mode="webwork-rep-to-static"/>
                <xsl:apply-templates select="../conclusion/node()" mode="webwork-rep-to-static"/>
            </statement>
            <xsl:apply-templates select="static/hint" mode="webwork-rep-to-static"/>
            <xsl:apply-templates select="static/answer" mode="webwork-rep-to-static"/>
            <xsl:apply-templates select="static/solution" mode="webwork-rep-to-static"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="node()|@*" mode="webwork-rep-to-static">
    <xsl:copy>
        <xsl:apply-templates select="node()|@*" mode="webwork-rep-to-static"/>
    </xsl:copy>
</xsl:template>

<!-- MyOpenMath (MOM) to static -->

<!-- Static versions come from a MOM server, and have been stored  -->
<!-- as a "generated" component of a project.  We meld with a      -->
<!-- PreTeXt introduction and conclusion, into a "regular" PreTeXt -->
<!-- format, for any conversion to a static format to use.         -->
<xsl:template match="exercise[(@exercise-interactive = 'myopenmath')]
                   | project[(@exercise-interactive = 'myopenmath')]
                   | activity[(@exercise-interactive = 'myopenmath')]
                   | exploration[(@exercise-interactive = 'myopenmath')]
                   | investigation[(@exercise-interactive = 'myopenmath')]" mode="representations">
    <!-- duplicate the exercise/project -->
    <xsl:copy>
        <!-- and preserve attributes on the exercise/project -->
        <xsl:apply-templates select="@*" mode="representations"/>
        <!-- Now bifurcate on static/dynamic.  PG problem creation should not fall in here. -->
        <xsl:choose>
            <xsl:when test="$exercise-style = 'static'">
                <!-- locate the static representation in a file, generated independently -->
                <xsl:variable name="filename">
                    <xsl:if test="$b-managed-directories">
                        <xsl:value-of select="$generated-directory"/>
                    </xsl:if>
                    <xsl:text>problems/mom-</xsl:text>
                    <xsl:value-of select="myopenmath/@problem"/>
                    <xsl:text>.xml</xsl:text>
                </xsl:variable>
                <!-- "myopenmath" child guaranteed by @exercise-interactive value -->
                <xsl:variable name="mom-static-rep" select="document($filename, $original)/myopenmath"/>
                <!-- duplicate metadata first -->
                <xsl:apply-templates select="title|idx" mode="representations"/>
                <!-- Meld PreTeXt introduction, conclusion with MOM statement. We could -->
                <!-- duplicate MOM/statement attributes here, if there were any.        -->
                <statement>
                    <xsl:apply-templates select="introduction/node()" mode="representations"/>
                    <xsl:apply-templates select="$mom-static-rep/statement/node()" mode="representations"/>
                    <xsl:apply-templates select="conclusion/node()" mode="representations"/>
                </statement>
                <!-- these might not all be present, ever, but just to be safe -->
                <xsl:apply-templates select="$mom-static-rep/hint" mode="representations"/>
                <xsl:apply-templates select="$mom-static-rep/answer" mode="representations"/>
                <xsl:apply-templates select="$mom-static-rep/solution" mode="representations"/>
                <!-- NB: the "myopenmath" element has been ignored is now gone -->
            </xsl:when>
            <xsl:when test="($exercise-style = 'dynamic') or ($exercise-style = 'pg-problems')">
                <!-- duplicate authored content for the non-static conversions -->
                <xsl:apply-templates select="node()" mode="representations"/>
            </xsl:when>
        </xsl:choose>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>
