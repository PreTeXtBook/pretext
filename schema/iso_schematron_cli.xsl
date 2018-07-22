<?xml version="1.0" ?>

<!--********************************************************************
Copyright 2018 Robert A. Beezer

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

<!-- This stylesheet uses the Schematron API to extend the -->
<!-- "iso_schematron_skeleton_for_xslt1.xsl" sylesheet by  -->
<!-- re-implementing the "process-report" template.        -->
<!--                                                       -->
<!-- Note:                                                 -->
<!--   (1) the "import" has a hard-coded path to the       -->
<!--       Schematron distribution                         -->
<!--   (2) an author does not ever need to use this file   -->
<!--       in anyway, it is a developer tool               -->

<xsl:stylesheet
    version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias">

<xsl:import href="/home/rob/mathbook/schematron/trunk/schematron/code/iso_schematron_skeleton_for_xslt1.xsl"/>

<!-- Causes early output=text declaration -->
<xsl:template name="process-prolog">
   <axsl:output method="text" />
</xsl:template>

<!-- Add a pre/post message to usual results -->
<!-- And blank line before/after             -->
<xsl:template name="process-root">
    <xsl:param name="contents"/>

    <xsl:text>&#xa;</xsl:text>
    <xsl:text>** Begin checking PreTeXt Schematron rules      **&#xa;</xsl:text>
    <xsl:copy-of select="$contents" />
    <xsl:text>** Finished checking PreTeXt Schematron rules   **&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- An assertion is something that must happen,     -->
<!-- so we call the Schematron @test a "requirement" -->
<!-- Messages are emitted on a failure               -->
<xsl:template name="process-assert">
    <xsl:param name="id"/>
    <xsl:param name="test"/>
    <xsl:param name="diagnostics"/>
    <xsl:param name="flag" />
    <!-- "Linkable" parameters -->
    <xsl:param name="role"/>
    <xsl:param name="subject"/>
    <!-- "Rich" parameters -->
    <xsl:param name="fpi" />
    <xsl:param name="icon" />
    <xsl:param name="lang" />
    <xsl:param name="see" />
    <xsl:param name="space" />

    <xsl:text>Location:         </xsl:text>
    <axsl:apply-templates select="." mode="schematron-get-full-path"/>
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>Requirement:      </xsl:text>
    <xsl:value-of select="$test" />
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>Explanation:       </xsl:text>
    <xsl:apply-templates mode="text" />
    <!-- split "diagnostic" template begins with a stray space             -->
    <!-- So                                                                -->
    <!--   (1) don't line-break here, so the space continues the last line -->
    <!--   (2) author diagnostics with a *leading* newline -->
    <!-- <xsl:text>&#xa;</xsl:text> -->

    <xsl:call-template name="diagnosticsSplit">
        <xsl:with-param name="str" select="$diagnostics"/>
    </xsl:call-template>

    <!-- need pre- and post- newline, see above -->
    <xsl:text>&#xa;- - - - - - - - -&#xa;</xsl:text>
</xsl:template>

<!-- A reporting is something that must not happen, -->
<!-- so we call the Schematron @test a "condition"  -->
<!-- Messages are emitted on a success              -->
<xsl:template name="process-report">
    <xsl:param name="id"/>
    <xsl:param name="test"/>
    <xsl:param name="diagnostics"/>
    <xsl:param name="flag" />
    <!-- "Linkable" parameters -->
    <xsl:param name="role"/>
    <xsl:param name="subject"/>
    <!-- "Rich" parameters -->
    <xsl:param name="fpi" />
    <xsl:param name="icon" />
    <xsl:param name="lang" />
    <xsl:param name="see" />
    <xsl:param name="space" />

    <xsl:text>Location:         </xsl:text>
    <axsl:apply-templates select="." mode="schematron-get-full-path"/>
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>Condition:         </xsl:text>
    <xsl:value-of select="$test" />
    <xsl:value-of select="$role" />
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>Explanation:       </xsl:text>
    <xsl:apply-templates mode="text" />

    <!-- split "diagnostic" template begins with a stray space             -->
    <!-- So                                                                -->
    <!--   (1) don't line-break here, so the space continues the last line -->
    <!--   (2) author diagnostics with a *leading* newline -->
    <!-- <xsl:text>&#xa;</xsl:text> -->

    <xsl:call-template name="diagnosticsSplit">
        <xsl:with-param name="str" select="$diagnostics"/>
    </xsl:call-template>

    <!-- need pre- and post- newline, see above -->
    <xsl:text>&#xa;- - - - - - - - -&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>



