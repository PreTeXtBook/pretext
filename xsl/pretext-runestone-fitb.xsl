<?xml version='1.0'?> <!-- As XML file -->

<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
>

<!-- ==================================================== -->
<!-- Actual rules for substution when generating HTML     -->
<!-- ==================================================== -->


<!-- Convert fillin tag to an input element on the page -->
<xsl:template match="exercise[@exercise-interactive='fillin']//fillin">
    <xsl:param name="b-human-readable" />
    <xsl:variable name="parent-id">
        <xsl:apply-templates select="ancestor::exercise" mode="html-id" />
    </xsl:variable>
    <xsl:element name="input">
        <xsl:attribute name="types"><xsl:text>text</xsl:text></xsl:attribute>
        <xsl:attribute name="id">
            <xsl:value-of select="$parent-id"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="@name"/>
        </xsl:attribute>
        <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
    </xsl:element>
</xsl:template>


<!-- ========================================================= -->
<!-- The Runestone element is based on JSON scripts describing -->
<!-- the exercise, how to set it up, and how to evaluate it.   -->
<!-- The HTML will contain this JSON and Runestone extracts it -->
<!-- and inserts it into the HTML page via JS.                 -->
<!-- ========================================================= -->
<xsl:template match="exercise[@exercise-interactive='fillin']" mode="runestone-to-interactive">
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:variable>
    <div class="runestone">
        <div data-component="fillintheblank" class="fillintheblank" style="visibility: hidden;">
            <xsl:attribute name="id">
                <xsl:value-of select="$the-id"/>
            </xsl:attribute>
            <script type="application/json">
                <xsl:text>{&#xa;</xsl:text>
                    <!-- A seed is provided to generate consistent static content -->
                    <xsl:if test="$b-dynamics-static-seed">
                        <xsl:text>"static_seed": "</xsl:text>
                        <xsl:choose>
                            <xsl:when test="setup/@seed">
                                <xsl:value-of select="setup/@seed"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- Report if a seed is not provided-->
                                <xsl:message>PTX:WARNING:   Dynamic exercise "<xsl:value-of select="$the-id"/>" is missing setup @seed for static content generation.</xsl:message>
                                <xsl:text>1234</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>",&#xa;</xsl:text>
                    </xsl:if>
                    <!-- The formatted HTML presentation of the problem, -->
                    <!-- with escape codes for dynamic content, all of   -->
                    <!-- which is serialized and escaped to a string.    -->
                    <xsl:text>"problemHtml": </xsl:text>
                    <xsl:call-template name="escape-quote-xml">
                        <xsl:with-param name="xml_content">
                            <xsl:apply-templates select="statement" mode="body" />
                            <xsl:if test="$b-dynamics-static-seed">
                                <div>
                                    <xsl:attribute name="id">
                                        <xsl:apply-templates select="." mode="html-id"/>
                                        <xsl:text>-substitutions</xsl:text>
                                    </xsl:attribute>
                                    <xsl:apply-templates select="(statement|solution)//eval[@expr]" mode="track-evaluation" />
                                </div>
                            </xsl:if>
                        </xsl:with-param>
                    </xsl:call-template>
                    <!-- The formatted HTML presentation of the solution, -->
                    <!-- similar to statement but no fillins              -->
                    <xsl:text>,&#xa;"solutionHtml": </xsl:text>
                    <xsl:call-template name="escape-quote-xml">
                        <xsl:with-param name="xml_content">
                            <xsl:apply-templates select="solution" mode="body" />
                        </xsl:with-param>
                    </xsl:call-template>
                    <!-- Add packages that need to be loaded as javascript -->
                    <xsl:text>,&#xa;"dyn_imports": [</xsl:text>
                    <xsl:if test="setup/de-object">
                        <xsl:text>"BTM"</xsl:text>
                    </xsl:if>
                    <xsl:text>]</xsl:text>
                    <!-- Names assigned to the blanks. (Inclusion is     -->
                    <!-- really so that evaluation of answers can refer  -->
                    <!-- to submitted work by name.                      -->
                    <xsl:text>,&#xa;"blankNames": {</xsl:text>
                    <xsl:apply-templates select="statement//fillin" mode="declare-blanks" />
                    <!-- The actual setup code is javascript enclosed in quotes. -->
                    <!-- The declaration creates the objects that are needed.    -->
                    <!-- The script is included as an escaped string             -->
                    <xsl:text>},&#xa;"dyn_vars": </xsl:text>
                    <xsl:call-template name="dynamic-setup" />
                    <!-- An array of tests and feedback for answer evaluation    -->
                    <!-- Each blank has a corresponding array of test/feedback   -->
                    <!-- response. The test is Javascript (stringified) that     -->
                    <!-- returns a boolean response. The first test is for       -->
                    <!-- correctness. The last response is default.              -->
                    <xsl:text>,&#xa;"feedbackArray": [</xsl:text>
                    <!-- In case all answers are based on one test               -->
                    <xsl:variable name="multiAns">
                        <xsl:apply-templates select="evaluation" mode="get-multianswer-check" />
                    </xsl:variable>
                    <!-- Generate test/feedback pair for each fillin             -->
                    <xsl:apply-templates select="statement//fillin" mode="dynamic-feedback">
                        <xsl:with-param name="multiAns" select="$multiAns" />
                    </xsl:apply-templates>
                    <xsl:text>]</xsl:text>
                <xsl:text>&#xa;}</xsl:text>
            </script>
        </div>
        <xsl:text>&#xa;</xsl:text>
    </div>
</xsl:template>

<!-- Creating a list of blank names. -->
<xsl:template match="fillin" mode="declare-blanks">
    <xsl:if test="position()>1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:if test="@name">
        <xsl:call-template name="quote-string">
            <xsl:with-param name="text" select="@name"/>
        </xsl:call-template>
        <xsl:text>: </xsl:text>
        <xsl:value-of select="position()-1"/>
    </xsl:if>
</xsl:template>


<!-- #eval in a dynamic exercise (has setup) is to evaluate -->
<!-- an expression that has been previously generated. If   -->
<!-- in math-mode, we want to see if it is an object that   -->
<!-- knows how to formulate a LaTeX representation          -->
<!-- The `toTeX` javascript function is defined in BTM.js   -->
<xsl:template match="exercise[//setup]//eval[@expr]">
    <xsl:text>[%= </xsl:text>
    <xsl:choose>
        <xsl:when test="ancestor::m|ancestor::me|ancestor::mrow">
            <xsl:text>toTeX(</xsl:text>
            <xsl:value-of select="@expr"/>
            <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="@expr"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text> %]</xsl:text>
</xsl:template>


<!-- Part of static output content extraction process,   -->
<!-- this creates elements that will be pulled from the  -->
<!-- stand-alone page into a generated XML document that -->
<!-- gives the actual substitution in static mode.       -->
<xsl:template match="eval[@expr]" mode="track-evaluation">
    <eval-subst>
        <xsl:attribute name="expr">
            <xsl:value-of select="@expr"/>
        </xsl:attribute>
        <xsl:apply-templates select="."/>
    </eval-subst>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- Create the dynamic aspect of the problem.           -->
<!-- Define all of the mathematical elements as well as  -->
<!-- objects (e.g. graphs) that might depend on them     -->
<!-- A script in setup/postSetupScript is executed after -->
<!-- the environment setup.                              -->
<!-- A script in setup/postRenderScript is executed      -->
<!-- after the dynamic creation is complete.             -->
<xsl:template name="dynamic-setup">
    <xsl:variable name="js_code">
        <!-- Initialize the evaluation environment -->
        <xsl:if test="setup/de-object">
            <xsl:call-template name="setup-evaluation-environment"/>
        </xsl:if>
        <!-- Any direct JS for environment setup   -->
        <xsl:if test="setup/postSetupScript">
            <xsl:value-of select="setup/postSetupScript"/>
        </xsl:if>
        <!-- Prepare evaluation and feedback       -->
        <xsl:call-template name="setup-fillin-parsers"/>
        <!-- Create the call-back for post-render tasks -->
        <xsl:call-template name="setup-postContent"/>
    </xsl:variable>
    <xsl:call-template name="escape-quote-string">
        <xsl:with-param name="text" select="$js_code"/>
    </xsl:call-template>
</xsl:template>

<!-- Parse any settings for the math environment for the problem -->
<xsl:template name="setup-evaluation-environment">
    <xsl:text>v._menv = new BTM({</xsl:text>
        <!-- Setup seeded random number generator  -->
        <xsl:text>'rand': rand</xsl:text>
        <!-- FUTURE: Pull additional settings from an environment element -->
        <xsl:apply-templates select="de-environment" mode="runestone-setup"/>
    <xsl:text>});&#xa;</xsl:text>
    <!-- Generate all of the XML-declared math objects -->
    <xsl:apply-templates select="setup/de-object" mode="runestone-setup"/>
</xsl:template>

<!-- Environment Setup: Define the mathematical objects -->
<xsl:template match="de-object" mode="runestone-setup">
    <xsl:text>v.</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = v._menv.addMathObject(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="text" select="@name"/>
    </xsl:call-template>
    <xsl:text>, </xsl:text>
    <!-- Get the context of the object here -->
    <xsl:call-template name="quote-string">
        <xsl:with-param name="text">
            <xsl:choose>
                <!-- Usually use value of @context but in case strings change. -->
                <xsl:when test="@context='interval' or @context='set'">
                    <xsl:text>set</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@context"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="." mode="evaluate">
        <xsl:with-param name="setupMode"><xsl:text>1</xsl:text></xsl:with-param>
    </xsl:apply-templates>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- Runestone requires declaring an array of answer-types for  -->
<!-- validating and parsing what the user enters as a response. -->
<xsl:template name="setup-fillin-parsers">
    <xsl:text>v.types = [</xsl:text>
    <xsl:apply-templates select="statement//fillin" mode="setup-parsers" />
    <xsl:text>];&#xa;</xsl:text>
</xsl:template>

<!-- Create a call-back for what occurs post-rendering.  -->
<!-- This includes automated tasks as well as any script -->
<!-- commands in setup/postRenderScript                  -->
<xsl:template name="setup-postContent">
    <xsl:text>v.afterContentRender = function() {&#xa;</xsl:text>
        <xsl:if test="setup/postRenderScript">
            <xsl:value-of select="setup/postRenderScript"/>
        </xsl:if>
    <xsl:text>};&#xa;</xsl:text>
</xsl:template>


<!-- Each fillin defines a blank. Establish the list of parsers. -->
<!-- During setup and called while creating dyn_vars.            -->
<xsl:template match="fillin" mode="setup-parsers">
    <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <!-- Future: There may be attributes of the fillin that declare parser type. -->
    <!-- For now, simply assuming everything is an expression.                   -->
    <xsl:text>v._menv.getParser()</xsl:text>
</xsl:template>


<!-- ========================================================== -->
<!-- Evaluation and Feedback                                    -->
<!-- ========================================================== -->

<!-- Template for answer checking. Actual work done by specialized templates. -->
<xsl:template match="fillin" mode="dynamic-feedback">
    <xsl:param name="multiAns"/>
    <xsl:variable name="curFillIn" select="."/>
    <xsl:variable name="check" select="ancestor::exercise//evaluation/evaluate[@submit = $curFillIn/@name]" />
    <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <!-- First check is for correctness. -->
    <xsl:text>[{"solution_code": </xsl:text>
    <xsl:call-template name="escape-quote-string">
        <xsl:with-param name="text">
            <xsl:choose>
                <xsl:when test="string-length($multiAns)>0">
                    <xsl:value-of select="$multiAns"/>
                </xsl:when>
                <xsl:when test="$check/test[@correct='yes']">
                    <xsl:call-template name="create-test">
                        <xsl:with-param name="submit" select="$curFillIn/@name" />
                        <xsl:with-param name="test" select="$check/test[@correct='yes']/*[not(self::feedback)]" />
                    </xsl:call-template>
                </xsl:when>
                <!-- If no explicit test, must be on the fillin. -->
                <xsl:otherwise>
                    <xsl:text>function() {&#xa;</xsl:text>
                    <xsl:text>    return _menv.compareExpressions(</xsl:text>
                    <xsl:value-of select="$curFillIn/@correct"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$curFillIn/@name"/>
                    <xsl:text>);&#xa;}</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>()</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>, "feedback": </xsl:text>
    <xsl:choose>
        <xsl:when test="$check/test[@correct='yes']/feedback">
            <xsl:call-template name="quote-string">
                <xsl:with-param name="text" select="$check/test[@correct='yes']/feedback"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>"Correct."</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <!-- Now add additional checks for feedback. -->
    <xsl:for-each select="$check/test[not(@correct='yes')]">
        <xsl:text>, {"solution_code": </xsl:text>
        <xsl:call-template name="escape-quote-string">
            <xsl:with-param name="text">
                <xsl:call-template name="create-test">
                    <xsl:with-param name="submit" select="$curFillIn/@name" />
                    <xsl:with-param name="test" select="*[not(self::feedback)]" />
                </xsl:call-template>
                <xsl:text>()</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:text>, "feedback": </xsl:text>
        <xsl:choose>
            <xsl:when test="feedback">
                <xsl:call-template name="quote-string">
                    <xsl:with-param name="text" select="feedback"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>"Try again."</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>}</xsl:text>
    </xsl:for-each>
    <!-- Default feedback for the blank. Always evaluates true.   -->
    <xsl:text>, {"feedback": </xsl:text>
    <xsl:choose>
        <!-- Allow the problem to define it: feedback with no test   -->
        <xsl:when test="$check/feedback">
            <xsl:call-template name="quote-string">
                <xsl:with-param name="text" select="$check/feedback"/>
            </xsl:call-template>
        </xsl:when>
        <!-- Maybe this should be a configurable default???   -->
        <xsl:otherwise>
            <xsl:text>"Try again."</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}]</xsl:text>         
</xsl:template>

<!-- Deal with possibility of global checker for all blanks -->
<xsl:template match="evaluation" mode="get-multianswer-check">
    <xsl:variable name="responseTree" select="ancestor::exercise//fillin" />
    <xsl:if test="count($responseTree) > 1 and ancestor::exercise//evaluation/evaluate[@all='yes']/test">
        <xsl:call-template name="create-test">
            <xsl:with-param name="test" select="ancestor::exercise//evaluation/evaluate[@all='yes']/test/*[not(self::feedback)]" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Template for simple answer checkers: no interaction between different fillins. -->
<!-- Add a post-filter to deal with additional feedback, similar to AnswerHints but allowing more complex logic. -->

<xsl:template name="create-test">
    <xsl:param name="submit" />
    <xsl:param name="test" />
    <xsl:text>function() {&#xa;</xsl:text>
    <!-- Create a checker function. Initialize a stack of flag variables to track results. -->
    <xsl:text>    var testResults = new Array();&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="count($test[not(self::feedback)]) = 1">
            <xsl:call-template name="checker-simple">
                <xsl:with-param name="submit" select="$submit" />
                <xsl:with-param name="curTest" select="$test" />
                <xsl:with-param name="level" select="0" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="checker-layer">
                <xsl:with-param name="tests" select="$test" />
                <xsl:with-param name="level" select="0" />
                <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>    return (testResults[0]);&#xa;</xsl:text>
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- This template is called for a simple test (no compound logic). -->
<xsl:template name="checker-simple">
    <xsl:param name="curTest" />
    <xsl:param name="submit" />
    <xsl:param name="level" select="0" />
    <xsl:choose>
        <!-- Test might be coded directly in javascript -->
        <xsl:when test="name($curTest) = 'raw-js'">
            <xsl:text>    testResults[</xsl:text>
            <xsl:value-of select="$level" />
            <xsl:text>] = </xsl:text>
            <xsl:value-of select="$curTest"/>
        </xsl:when>
        <!-- Test might require logic -->
        <xsl:when test="name($curTest)='and' or name($curTest)='or' or name($curTest)='not'">
            <xsl:call-template name="checker-layer">
                <xsl:with-param name="submit" select="$submit" />
                <xsl:with-param name="tests" select="$curTest/*" />
                <xsl:with-param name="level" select="$level+1" />
                <xsl:with-param name="logic" select="name()" /> <!-- Default: All tests at first layer must be true -->
            </xsl:call-template>
            <xsl:text>    testResults[</xsl:text>
            <xsl:value-of select="$level" />
            <xsl:text>] = testResults[</xsl:text>
            <xsl:value-of select="$level+1" />
            <xsl:text>];&#xa;</xsl:text>
        </xsl:when>
        <!-- Otherwise simple test -->
        <xsl:otherwise>
            <!-- A test can have an implied equal or an explicit equal -->
            <!-- At root level, the test might also have a feedback. Skip that. -->
            <xsl:text>    testResults[</xsl:text>
            <xsl:value-of select="$level" />
            <xsl:text>] = </xsl:text>
            <xsl:text>_menv.compareExpressions(</xsl:text>
            <xsl:choose>
                <!-- An equal element must have two expression children. -->
                <xsl:when test="name($curTest) = 'equal'">
                    <xsl:apply-templates select="$curTest/*[1]" mode="evaluate"/>
                    <xsl:text>, </xsl:text>
                    <xsl:apply-templates select="$curTest/*[2]" mode="evaluate"/>
                </xsl:when>
                <!-- An implied equal compares the submitted answer to the given expression. -->
                <xsl:otherwise>   <!-- Must be expression: #var or #de-term -->
                    <xsl:apply-templates select="$curTest" mode="evaluate"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$submit" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>)</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>;&#xa;</xsl:text>
</xsl:template>

<!-- A test can also be composite involving a combination of logical tests -->
<!-- This template works through one layer, recursively dealing with deeper layers as needed -->
<xsl:template name="checker-layer" >
    <xsl:param name="submit" />
    <xsl:param name="tests" />                   <!-- The layer of tests (subtree) -->
    <xsl:param name="level" select="0" />        <!-- Level (or depth) of the layer -->
    <xsl:param name="logic" select="'and'" />    <!-- and = all must be true, or = at least one, not = negation -->
    <xsl:choose>
        <xsl:when test="$logic = 'and'">         <!-- Treat logic like multipication. A single false (0) makes product zero -->
            <xsl:text>    testResults[</xsl:text><xsl:value-of select="$level" /><xsl:text>] = 1;&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$logic = 'or'">         <!-- Treat logic like addition. A single true makes sum positive -->
            <xsl:text>testResults[</xsl:text><xsl:value-of select="$level" /><xsl:text>] = 0;&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:for-each select="$tests">    <!-- Work through the layer of tests one at a time. -->
        <xsl:choose>
            <xsl:when test="name()='and'">
                <xsl:text>    testResults[</xsl:text>
                <xsl:value-of select="$level+1" />
                <xsl:text>] = 1;&#xa;</xsl:text>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="submit" select="$submit" />
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'and'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='or'">
                <xsl:text>    testResults[</xsl:text>
                <xsl:value-of select="$level+1" />
                <xsl:text>] = 0;&#xa;</xsl:text>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="submit" select="$submit" />
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'or'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='not'">
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="submit" select="$submit" />
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'not'" /> <!-- Default: All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="checker-simple">
                    <xsl:with-param name="submit" select="$submit" />
                    <xsl:with-param name="curTest" select="." />
                    <xsl:with-param name="level" select="$level+1" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose> <!-- Deal with the results of that recursive call to a deeper layer. -->
            <xsl:when test="$logic = 'and'">
                <xsl:text>    testResults[</xsl:text><xsl:value-of select="$level" />
                <xsl:text>] &amp;= testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="$logic = 'or'">
                <xsl:text>    testResults[</xsl:text><xsl:value-of select="$level" />
                <xsl:text>] |= testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>];&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="$logic = 'not'">
                <xsl:text>    testResults[</xsl:text><xsl:value-of select="$level" />
                <xsl:text>] = !(testResults[</xsl:text><xsl:value-of select="$level+1" /><xsl:text>]);&#xa;</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:for-each>
</xsl:template>


<!-- ================================================ -->
<!-- Templates for working with evaluation objects    -->
<!-- ================================================ -->

<!-- Wrapper for calling appropriate javascript commands that  -->
<!-- will parse the expression for a number appropriately,     -->
<!-- which could be written as an expression involving symbols -->
<!-- or a random number                                        -->
<xsl:template match="de-object[@context='number']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="@mode='value' or @mode='formula'">
            <xsl:value-of select="$prefix"/>
            <xsl:text>_menv.parseExpression(</xsl:text>
            <xsl:call-template name="quote-strip-string">
                <xsl:with-param name="text" select="."/>
            </xsl:call-template>
            <xsl:text>, "number")</xsl:text>
        </xsl:when>
        <xsl:when test="@mode='evaluate'">
            <xsl:value-of select="$prefix"/>
            <xsl:text>_menv.evaluateMathObject(</xsl:text>
                <xsl:apply-templates select="formula/*" mode="evaluate">
                    <xsl:with-param name="setupMode" select="$setupMode"/>
                </xsl:apply-templates>
                <xsl:text>, "number", {</xsl:text>
                <xsl:apply-templates select="variable" mode="evaluation-binding" >
                    <xsl:with-param name="setupMode" select="$setupMode" />
                </xsl:apply-templates>
            <xsl:text>}).reduce()</xsl:text>
        </xsl:when>
        <xsl:when test="@mode='random'">
            <!-- Different types of random number generation -->
            <xsl:choose>
                <xsl:when test="options[@distribution='discrete']">
                    <xsl:variable name="rnd-min">
                        <xsl:choose>
                            <xsl:when test="options/@min">
                                <xsl:value-of select="options/@min"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>0</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="rnd-max">
                        <xsl:choose>
                            <xsl:when test="options/@max">
                                <xsl:value-of select="options/@max"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>1</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="rnd-by">
                        <xsl:choose>
                            <xsl:when test="options/@by">
                                <xsl:value-of select="options/@by"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>1</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="rnd-nonzero">
                        <xsl:choose>
                            <xsl:when test="options/@nonzero = 'yes'">
                                <xsl:text>true</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>false</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:call-template name="generate-random-number">
                        <xsl:with-param name="rnd-dist">
                            <xsl:text>discrete</xsl:text>
                        </xsl:with-param>
                        <xsl:with-param name="rnd-options">
                            <xsl:text>{ min:</xsl:text>
                            <xsl:value-of select="$rnd-min"/>
                            <xsl:text>, max:</xsl:text>
                            <xsl:value-of select="$rnd-max"/>
                            <xsl:text>, by:</xsl:text>
                            <xsl:value-of select="$rnd-by"/>
                            <xsl:text>, nonzero:</xsl:text>
                            <xsl:value-of select="$rnd-nonzero"/>
                            <xsl:text>}</xsl:text>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Objects defined as formulas. Several possible modes: -->
<!-- formula (literal), substitution (composition),       -->
<!-- derivative and evaluate                              -->
<xsl:template match="de-object[@context='formula']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:choose>
        <!-- Simple formula is provided, with or without pattern matching -->
        <xsl:when test="@mode='formula'">
            <xsl:value-of select="$prefix"/>
            <xsl:text>_menv.parseExpression(</xsl:text>
            <xsl:call-template name="quote-strip-string">
                <xsl:with-param name="text" select="."/>
            </xsl:call-template>
            <xsl:text>, "formula")</xsl:text>
        </xsl:when>
        <!-- Composition of two formulas (same look as evaluation)                -->
        <!-- Requires descendent nodes: formula and values to substitute          -->
        <xsl:when test="@mode='substitution'">
            <xsl:value-of select="$prefix"/>
            <xsl:text>_menv.composeExpression(</xsl:text>
            <xsl:apply-templates select="formula/*" mode="evaluate">
                <xsl:with-param name="setupMode" select="$setupMode"/>
            </xsl:apply-templates>
            <xsl:text>, {</xsl:text>
                <xsl:apply-templates select="variable" mode="evaluation-binding" >
                    <xsl:with-param name="setupMode" select="$setupMode" />
                </xsl:apply-templates>
            <xsl:text>}).reduce()</xsl:text>
        </xsl:when>
        <!-- Derivative of a formula.                        -->
        <!-- Requires descendent nodes: formula, variable    -->
        <xsl:when test="@mode='derivative'">
            <xsl:apply-templates select="formula" mode="evaluate">
                <xsl:with-param name="setupMode" select="$setupMode" />
            </xsl:apply-templates>
            <xsl:text>.derivative(</xsl:text>
            <xsl:call-template name="quote-string">
                <xsl:with-param name="text" select="variable/@name"/>
            </xsl:call-template>
            <xsl:text>)</xsl:text>
        </xsl:when>
        <!-- Evaluate a formula at specific values.          -->
        <!-- Values for variables define a binding.          -->
        <xsl:when test="@mode='evaluate'">
            <xsl:apply-templates select="formula" mode="evaluate">
                <xsl:with-param name="setupMode" select="$setupMode"/>
            </xsl:apply-templates>
            <xsl:text>.evaluate({</xsl:text>
            <xsl:apply-templates select="variable" mode="evaluation-binding" >
                <xsl:with-param name="setupMode" select="$setupMode" />
            </xsl:apply-templates>
            <xsl:text>})</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Used during composition or evaluation of a variable-->
<xsl:template match="variable" mode="evaluation-binding">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="text" select="@name" />
    </xsl:call-template>
    <xsl:text>: </xsl:text>
    <xsl:choose>
        <xsl:when test="eval or de-object">
            <xsl:apply-templates select="eval|de-object" mode="evaluate">
                <xsl:with-param name="setupMode" select="$setupMode" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="." />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Generate a random parameter. -->
<xsl:template name="generate-random-number">
    <xsl:param name="rnd-dist" />
    <xsl:param name="rnd-options" />
    <xsl:text>v._menv.generateRandom(</xsl:text>
        <xsl:call-template name="quote-string">
            <xsl:with-param name="text" select="$rnd-dist"/>
        </xsl:call-template>
        <xsl:text>, </xsl:text>
        <xsl:value-of select="$rnd-options"/>
    <xsl:text>)&#xa;</xsl:text>
</xsl:template>


<!-- mode="evaluate" is used during setup and during feedback evaluation            -->
<!-- Define an expressions that will be parsed in their math context                -->
<!-- The expression can be defined in terms of the parameters and other expressions -->
<xsl:template match="de-object[@context='formula' and @mode='formula']|de-term[@context='formula']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$prefix"/>
    <xsl:text>_menv.parseExpression(</xsl:text>
    <xsl:call-template name="quote-strip-string">
        <xsl:with-param name="text" select="."/>
    </xsl:call-template>
    <xsl:text>).reduce()</xsl:text>
</xsl:template>


<!-- var elements in expressions (evaluate) are replaced by their name -->
<!-- During setup, we need to use the context of the `v` object        -->
<xsl:template match="eval" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$prefix"/>
    <xsl:value-of select="@expr"/>
</xsl:template>

<!-- Nothing else is defined for evaluation during setup  -->
<xsl:template match="/" mode="evaluate"/>

<!-- How to *add* expressions/formulas to the math context -->
<xsl:template match="de-object[@context='formula' and @mode='formula']|de-term[@context='formula']" mode="runestone-setup-old">
    <xsl:text>v.</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = v._menv.addMathObject(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="text" select="@name"/>
    </xsl:call-template>
    <xsl:text>, "formula", </xsl:text>
    <xsl:apply-templates select="." mode="evaluate">
        <xsl:with-param name="setupMode"><xsl:text>1</xsl:text></xsl:with-param>
    </xsl:apply-templates>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

<!-- How to *add* expressions defined by substitution to the math context -->
<xsl:template match="de-object[@context='formula' and @mode='substitution']|de-term[@context='substitution']" mode="runestone-setup-old">
    <xsl:text>v.</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = v._menv.addExpression(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="text" select="@name"/>
    </xsl:call-template>
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="." mode="evaluate">
        <xsl:with-param name="setupMode"><xsl:text>1</xsl:text></xsl:with-param>
    </xsl:apply-templates>
    <xsl:text>);&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>