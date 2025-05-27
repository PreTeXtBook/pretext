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

<!-- These need to be replaced by localization calls.      -->
<!-- Or maybe push localization strings to Runestone,      -->
<!-- since this feedback is only useful in an interactive. -->
<xsl:variable name="defaultCorrectFeedback">
    <p>Correct!</p>
</xsl:variable>

<xsl:variable name="defaultIncorrectFeedback">
    <p>Incorrect.</p>
</xsl:variable>

<!-- Convert fillin tag to an input element on the page -->
<xsl:template match="exercise[@exercise-interactive='fillin']//fillin
                     | project[@exercise-interactive='fillin']//fillin
                     | activity[@exercise-interactive='fillin']//fillin
                     | exploration[@exercise-interactive='fillin']//fillin
                     | investigation[@exercise-interactive='fillin']//fillin
                     | task[@exercise-interactive='fillin']//fillin">
    <xsl:param name="b-human-readable" />
    <xsl:variable name="parent-id">
        <xsl:apply-templates select="ancestor::exercise" mode="html-id" />
    </xsl:variable>
    <xsl:element name="input">
        <xsl:attribute name="type">
            <xsl:choose>
                <xsl:when test="@mode = 'number'">
                    <xsl:text>number</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>text</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:value-of select="$parent-id"/>
            <xsl:text>-</xsl:text>
            <xsl:apply-templates select="." mode="blank-name"/>
        </xsl:attribute>
        <xsl:if test="@name">
            <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
        </xsl:if>
        <xsl:if test="@width">
            <xsl:attribute name="size">
                <xsl:value-of select="@width"/>
            </xsl:attribute>
        </xsl:if>
    </xsl:element>
</xsl:template>

<!-- ========================================================= -->
<!-- The Runestone element is based on JSON scripts describing -->
<!-- the exercise, how to set it up, and how to evaluate it.   -->
<!-- The HTML will contain this JSON and Runestone extracts it -->
<!-- and inserts it into the HTML page via JS.                 -->
<!-- ========================================================= -->
<xsl:template match="exercise[@exercise-interactive='fillin']
                     | project[@exercise-interactive='fillin']
                     | activity[@exercise-interactive='fillin']
                     | exploration[@exercise-interactive='fillin']
                     | investigation[@exercise-interactive='fillin']
                     | task[@exercise-interactive='fillin']" mode="runestone-to-interactive">
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:variable>
    <xsl:variable name="b-is-dynamic" select="boolean(./setup)"/>
    <div class="ptx-runestone-container">
        <div class="runestone">
            <div data-component="fillintheblank" class="fillintheblank" style="visibility: hidden;">
                <xsl:apply-templates select="." mode="runestone-id-attribute"/>
                <script type="application/json">
                    <xsl:text>{&#xa;</xsl:text>
                    <!-- A seed is provided to generate consistent static content -->
                    <xsl:if test="setup and $b-dynamics-static-seed">
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
                            <xsl:apply-templates select="statement/*" />
                            <xsl:if test="$b-dynamics-static-seed">
                                <div>
                                    <xsl:attribute name="id">
                                        <xsl:apply-templates select="." mode="html-id"/>
                                        <xsl:text>-substitutions</xsl:text>
                                    </xsl:attribute>
                                    <xsl:apply-templates select="(statement|solution)//eval[@obj]|evaluation//feedback//eval[@obj]|statement//fillin[@ansobj]" mode="track-evaluation" />
                                </div>
                            </xsl:if>
                        </xsl:with-param>
                    </xsl:call-template>
                    <!-- The formatted HTML presentation of the solution, -->
                    <!-- similar to statement but no fillins              -->
                    <xsl:text>,&#xa;"solutionHtml": </xsl:text>
                    <xsl:call-template name="escape-quote-xml">
                        <xsl:with-param name="xml_content">
                            <xsl:apply-templates select="solution/*" />
                        </xsl:with-param>
                    </xsl:call-template>
                    <!-- Add packages that need to be loaded as javascript -->
                    <xsl:if test="$b-is-dynamic">
                        <xsl:text>,&#xa;"dyn_imports": [</xsl:text>
                        <xsl:text>"BTM"</xsl:text>
                        <!-- Future: add additional packages here -->
                        <xsl:text>]</xsl:text>
                    </xsl:if>
                    <!-- Names assigned to the blanks.      -->
                    <!-- Empty if none named.               -->
                    <xsl:text>,&#xa;"blankNames": {</xsl:text>
                    <xsl:apply-templates select="statement//fillin" mode="declare-blanks" />
                    <xsl:text>}</xsl:text>
                    <xsl:if test="$b-is-dynamic">
                        <!-- The actual setup code is javascript enclosed in quotes. -->
                        <!-- The declaration creates the objects that are needed.    -->
                        <!-- The script is included as an escaped string             -->
                        <xsl:text>,&#xa;"dyn_vars": </xsl:text>
                        <xsl:call-template name="dynamic-setup" />
                    </xsl:if>
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
    </div>
</xsl:template>

<!-- Fillins can be provided a name or use a default rule -->
<xsl:template match="fillin" mode="blank-name">
    <xsl:choose>
        <xsl:when test="@name">
            <xsl:value-of select="@name"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>blank</xsl:text>
            <xsl:value-of select="position()" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Creating a list of blank names. -->
<xsl:template match="fillin" mode="declare-blanks">
    <xsl:variable name="blankNum">
        <xsl:value-of select="position()" />
    </xsl:variable>
    <xsl:if test="$blankNum>1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="text">
            <xsl:apply-templates select="." mode="blank-name"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>: </xsl:text>
    <xsl:value-of select="$blankNum - 1"/>
</xsl:template>

<!-- #eval in a dynamic exercise (has setup) is to evaluate -->
<!-- an expression that has been previously generated. If   -->
<!-- in math-mode, we want to see if it is an object that   -->
<!-- knows how to formulate a LaTeX representation          -->
<!-- The `toTeX` javascript function is defined in BTM.js   -->
<!-- which is loaded by Runestone.                          -->
<xsl:template match="eval[@obj]">
    <xsl:text>[%= </xsl:text>
    <xsl:choose>
        <xsl:when test="ancestor::m|ancestor::me|ancestor::mrow">
            <xsl:text>toTeX(</xsl:text>
            <xsl:value-of select="@obj"/>
            <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="@obj"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text> %]</xsl:text>
</xsl:template>


<!-- Part of static output content extraction process,   -->
<!-- this creates elements that will be pulled from the  -->
<!-- stand-alone page into a generated XML document that -->
<!-- gives the actual substitution in static mode.       -->
<xsl:template match="eval[@obj]" mode="track-evaluation">
    <eval-subst>
        <xsl:attribute name="obj">
            <xsl:value-of select="@obj"/>
        </xsl:attribute>
        <xsl:apply-templates select="."/>
    </eval-subst>
</xsl:template>

<xsl:template match="fillin[@ansobj]" mode="track-evaluation">
    <eval-subst>
        <xsl:attribute name="obj">
            <xsl:value-of select="@ansobj"/>
        </xsl:attribute>
        <xsl:variable name="temp-eval">
            <xsl:choose>
                <xsl:when test="@mode='math' or @mode='number'">
                    <m><eval>
                        <xsl:attribute name="obj">
                            <xsl:value-of select="@ansobj"/>
                        </xsl:attribute>
                    </eval></m>
                </xsl:when>
                <xsl:otherwise>
                    <eval>
                        <xsl:attribute name="obj">
                            <xsl:value-of select="@ansobj"/>
                        </xsl:attribute>
                    </eval>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:apply-templates select="exsl:node-set($temp-eval)//eval"/>
    </eval-subst>
</xsl:template>


<!-- Create the dynamic aspect of the problem.           -->
<!-- Define all of the mathematical elements as well as  -->
<!-- objects (e.g. graphs) that might depend on them     -->
<!-- A script in setup/setupScript is executed after     -->
<!-- object-based setup concludes.                       -->
<!-- A script in setup/postRenderScript is executed      -->
<!-- after the dynamic creation is complete.             -->
<xsl:template name="dynamic-setup">
    <xsl:variable name="js_code">
        <!-- Initialize the evaluation environment -->
        <xsl:call-template name="setup-evaluation-environment"/>
        <!-- Any direct JS for environment setup   -->
        <xsl:if test="setup/setupScript">
            <xsl:value-of select="setup/setupScript"/>
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
    <xsl:text>v._mobjs = new BTM({</xsl:text>
        <!-- Setup seeded random number generator  -->
        <xsl:text>'rand': rand</xsl:text>
        <!-- FUTURE: Pull additional settings from an environment element -->
        <xsl:apply-templates select="de-environment" mode="runestone-setup"/>
    <xsl:text>});&#xa;</xsl:text>
    <xsl:text>var RNG = v._mobjs.menv.rng;&#xa;</xsl:text>
    <!-- Generate all of the XML-declared math objects -->
    <xsl:apply-templates select="setup/de-object" mode="runestone-setup"/>
</xsl:template>

<!-- Environment Setup: Define the mathematical objects -->
<xsl:template match="de-object" mode="runestone-setup">
    <xsl:text>v.</xsl:text><xsl:value-of select="@name"/>
    <xsl:text> = v._mobjs.addMathObject(</xsl:text>
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
    <xsl:apply-templates select="*" mode="evaluate">
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
     <xsl:choose>
        <xsl:when test="@mode='math-formula'">
            <xsl:text>v._mobjs.getParser()</xsl:text>
        </xsl:when>
        <xsl:when test="@mode='number'">
            <xsl:text>Number</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>function(val){ return val; }</xsl:text>
        </xsl:otherwise>
     </xsl:choose>
</xsl:template>


<!-- ========================================================== -->
<!-- Evaluation and Feedback                                    -->
<!-- ========================================================== -->

<!-- Deal with possibility of global checker for all blanks -->
<xsl:template match="evaluation" mode="get-multianswer-check">
    <xsl:variable name="responseTree" select="../statement//fillin" />
    <xsl:if test="count($responseTree) > 1 and evaluate[@all='yes']/test">
        <xsl:apply-templates select="evaluate[@all='yes']/test" mode="create-test-feedback">
            <xsl:with-param name="fillin" select="$responseTree"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>


<!-- Template for answer checking. Actual work done by specialized templates. -->
<xsl:template match="fillin" mode="dynamic-feedback">
    <xsl:param name="multiAns"/>
    <xsl:variable name="curFillIn" select="."/>
    <xsl:variable name="fillinName">
        <xsl:apply-templates select="." mode="blank-name"/>
    </xsl:variable>
    <xsl:variable name="blankNum">
        <xsl:value-of select="position()" />
    </xsl:variable>
    <xsl:variable name="check">
        <xsl:choose>
            <xsl:when test="ancestor::statement/../evaluation/evaluate[@name = $fillinName]">
                <xsl:copy-of select="ancestor::statement/../evaluation/evaluate[@name = $fillinName]"/>
            </xsl:when>
            <xsl:when test="ancestor::statement/../evaluation/evaluate[position() = $blankNum]">
                <xsl:copy-of select="ancestor::statement/../evaluation/evaluate[position() = $blankNum]"/>
            </xsl:when>
            <!-- No check matches: Make blank default. -->
            <xsl:otherwise>
                <evaluate>
                    <xsl:attribute name="name">
                        <xsl:value-of select="$fillinName"/>
                    </xsl:attribute>
                    <test>
                        <xsl:attribute name="correct">
                            <xsl:text>yes</xsl:text>
                        </xsl:attribute>
                        <jscmp>
                            <xsl:text>false</xsl:text>
                        </jscmp>
                        <feedback>
                            <xsl:text>No comparison rule was provided.</xsl:text>
                        </feedback>
                    </test>
                </evaluate>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="checkCorrectTest">
        <xsl:choose>
            <xsl:when test="exsl:node-set($check)/evaluate/test[@correct='yes']">
                <xsl:copy-of select="exsl:node-set($check)/evaluate/test[@correct='yes']"/>
            </xsl:when>
            <!-- If no test matches @correct='yes', then use the default answer. Leave blank. -->
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$blankNum > 1">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <!-- First check is for correctness. -->
    <xsl:text>[</xsl:text>
    <xsl:choose>
        <xsl:when test="string-length($multiAns)>0">
            <xsl:value-of select="$multiAns"/>
        </xsl:when>
        <xsl:when test="string-length($checkCorrectTest) > 0">
            <xsl:apply-templates select="exsl:node-set($checkCorrectTest)/test" mode="create-test-feedback">
                <xsl:with-param name="fillin" select="$curFillIn" />
                <xsl:with-param name="b-correct" select="'yes'" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- If no explicit test is provided, use given answer. -->
        <xsl:otherwise>
            <xsl:text>{</xsl:text>
            <xsl:choose>
                <xsl:when test="$curFillIn/@answer">
                    <xsl:choose>
                        <xsl:when test="$curFillIn/@mode='number'">
                            <xsl:text>"number": [</xsl:text>
                            <xsl:value-of select="exsl:node-set($curFillIn)/@answer"/>
                            <xsl:text>,</xsl:text>
                            <xsl:value-of select="exsl:node-set($curFillIn)/@answer"/>
                            <xsl:text>]</xsl:text>
                        </xsl:when>
                        <xsl:when test="$curFillIn/@mode='string'">
                            <xsl:text>"regex": "</xsl:text>
                            <xsl:value-of select="exsl:node-set($curFillIn)/@answer"/>
                            <xsl:text>"</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$curFillIn/@ansobj">
                    <xsl:choose>
                        <xsl:when test="$curFillIn/@mode='number'">
                            <xsl:text>function() {&#xa;</xsl:text>
                            <xsl:text>    return (Math.abs(</xsl:text>
                            <xsl:value-of select="$curFillIn/@ansobj"/>
                            <xsl:text>- ans) &lt; 1e-10);&#xa;}</xsl:text>
                        </xsl:when>
                        <xsl:when test="$curFillIn/@mode='string'">
                            <xsl:text>function() {&#xa;</xsl:text>
                            <xsl:text>    return (</xsl:text>
                            <xsl:value-of select="$curFillIn/@ansobj"/>
                            <xsl:text>== ans);&#xa;}</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$curFillIn/@mode='math'">
                    <xsl:text>function() {&#xa;</xsl:text>
                    <xsl:text>    return _mobjs.compareExpressions(</xsl:text>
                    <xsl:value-of select="$curFillIn/@ansobj"/>
                    <xsl:text>, ans</xsl:text>
                    <!-- Can we use ans above instead of $curFillIn/@name? -->
                    <!-- xsl:value-of select="exsl:node-set($curFillIn)/@name"/-->
                    <xsl:text>);&#xa;}</xsl:text>
                </xsl:when>
            </xsl:choose>
            <xsl:text>, "feedback": "</xsl:text>
            <xsl:value-of select="$defaultCorrectFeedback"/>
            <xsl:text>"}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>

    <!-- Now add additional checks for feedback. -->
    <xsl:for-each select="exsl:node-set($check)//test[not(@correct='yes')]">
        <xsl:text>, </xsl:text>
        <xsl:apply-templates select="." mode="create-test-feedback">
            <xsl:with-param name="fillin" select="$curFillIn"/>
        </xsl:apply-templates>
    </xsl:for-each>
    <!-- Default feedback for the blank. Always evaluates true.   -->
    <xsl:text>, {"feedback": "</xsl:text>
    <xsl:value-of select="$defaultIncorrectFeedback"/>
    <xsl:text>"}]</xsl:text>
</xsl:template>

<xsl:template match="test" mode="create-test-feedback">
    <xsl:param name="fillin"/>
    <xsl:param name="b-correct" select="'no'"/>
    <xsl:variable name="feedback-rtf">
        <xsl:apply-templates select="feedback"/>
    </xsl:variable>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="create-test">
        <xsl:with-param name="fillin" select="$fillin" />
    </xsl:apply-templates>
    <xsl:text>, "feedback": "</xsl:text>
    <xsl:choose>
        <xsl:when test="feedback">
            <!-- serialize HTML as text, then escape as JSON -->
            <xsl:call-template name="escape-json-string">
                <xsl:with-param name="text">
                    <xsl:apply-templates select="exsl:node-set($feedback-rtf)" mode="xml-to-string"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="$b-correct">
            <xsl:value-of select="$defaultCorrectFeedback"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$defaultIncorrectFeedback"/>
        </xsl:otherwise>
    </xsl:choose>
<xsl:text>"}</xsl:text>
</xsl:template>

<!-- Template for simple answer checkers: no interaction between different fillins. -->
<!-- Add a post-filter to deal with additional feedback, similar to AnswerHints but allowing more complex logic. -->
<!-- JSON dictionary for numerical condition -->
<xsl:template match="test[numcmp]" mode="create-test">
    <xsl:param name="fillin"/>
    <xsl:choose>
        <xsl:when test="(numcmp/@use-answer='yes' and $fillin/@ansobj) or numcmp/@object">
            <xsl:apply-templates select="." mode="create-test-ansobj">
                <xsl:with-param name="fillin" select="$fillin"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="answer">
                <xsl:choose>
                    <xsl:when test="numcmp/@use-answer='yes' and $fillin/@answer">
                        <xsl:value-of select="$fillin/@answer"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="numcmp/@value"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="tolerance">
                <xsl:choose>
                    <xsl:when test="numcmp/@use-answer='yes' and $fillin/@tolerance">
                        <xsl:value-of select="$fillin/@tolerance"/>
                    </xsl:when>
                    <xsl:when test="numcmp/@tolerance">
                        <xsl:value-of select="numcmp/@tolerance"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>0</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="min-val">
              <xsl:choose>
                <xsl:when test="numcmp/@min">
                  <xsl:value-of select="numcmp/@min"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$answer - $tolerance"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="max-val">
              <xsl:choose>
                <xsl:when test="numcmp/@max">
                  <xsl:value-of select="numcmp/@max"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$answer + $tolerance"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:text>"number": [</xsl:text>
            <xsl:value-of select="$min-val"/>
            <xsl:text>,</xsl:text>
            <xsl:value-of select="$max-val"/>
            <xsl:text>]</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- When the comparison is with an object, we rely on function comparisons. -->
<xsl:template match="test[numcmp]" mode="create-test-ansobj">
    <xsl:param name="fillin"/>
    <xsl:variable name="ansObject">
        <xsl:choose>
            <xsl:when test="numcmp/@use-answer='yes' and $fillin/@ansobj">
                <xsl:value-of select="$fillin/@ansobj"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="numcmp/@object"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="tolerance">
        <xsl:choose>
            <xsl:when test="numcmp/@use-answer='yes' and $fillin/@tolerance">
                <xsl:value-of select="$fillin/@tolerance"/>
            </xsl:when>
            <xsl:when test="numcmp/@tolerance">
                <xsl:value-of select="numcmp/@tolerance"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>0</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="min-val">
        <xsl:choose>
            <xsl:when test="numcmp/@min">
                <xsl:value-of select="numcmp/@min"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$ansObject"/>
                <xsl:text> - </xsl:text>
                <xsl:value-of select="$tolerance"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="max-val">
        <xsl:choose>
            <xsl:when test="numcmp/@max">
            <xsl:value-of select="numcmp/@max"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$ansObject"/>
                <xsl:text> + </xsl:text>
                <xsl:value-of select="$tolerance"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>"solution_code": </xsl:text>
    <xsl:variable name="js_code">
        <xsl:text>function() { </xsl:text>
        <xsl:text>return (ans &gt;= </xsl:text>
        <xsl:value-of select="$min-val"/>
        <xsl:text>) &amp;&amp; (ans &lt;= </xsl:text>
        <xsl:value-of select="$max-val"/>
        <xsl:text>); }()</xsl:text>
    </xsl:variable>
    <xsl:call-template name="escape-quote-string">
        <xsl:with-param name="text" select="$js_code"/>
    </xsl:call-template>
</xsl:template>

<!-- JSON dictionary for string condition -->
<xsl:template match="test[strcmp]" mode="create-test">
    <xsl:param name="fillin"/>
    <xsl:choose>
        <xsl:when test="strcmp/@use-answer='yes' and $fillin/@ansobj or strcmp//eval">
            <xsl:apply-templates mode="create-test-ansobj">
                <xsl:with-param name="fillin" select="$fillin"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="answer">
                <xsl:choose>
                    <xsl:when test="strcmp/@use-answer='yes'">
                        <xsl:value-of select="$fillin/@answer"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="strcmp"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="regexFlags">
                <xsl:choose>
                    <xsl:when test="strcmp/@use-answer='yes' and $fillin/@case = 'insensitive'">
                        <xsl:text>i</xsl:text>
                    </xsl:when>
                    <xsl:when test="strcmp/@case = 'insensitive'">
                        <xsl:text>i</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <!-- regex string match, drop    -->
            <!-- leading/trailing whitespace -->
            <xsl:text>"regex": "</xsl:text>
            <!-- JSON escapes necessary for regular expression -->
            <xsl:call-template name="escape-json-string">
                <xsl:with-param name="text">
                    <xsl:choose>
                        <xsl:when test="strcmp/@strip = 'no'">
                            <xsl:value-of select="$answer"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>^\s*</xsl:text>
                            <xsl:value-of select="$answer"/>
                            <xsl:text>\s*$</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
            <xsl:text>"</xsl:text>
            <!-- flag for case-sensitive match -->
            <!-- default:  'sensitive'         -->
            <xsl:text>, "regexFlags": "</xsl:text>
            <xsl:value-of select="$regexFlags"/>
            <xsl:text>"</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- When the comparison is with an object, we rely on function comparisons. -->
<xsl:template match="test[strcmp]" mode="create-test-ansobj">
    <xsl:variable name="regex">
        <xsl:choose>
            <xsl:when test="strcmp/@use-answer='yes' and $fillin/@ansobj">
                <xsl:text>`${</xsl:text>
                <xsl:value-of select="$fillin/@ansobj"/>
                <xsl:text>}`</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>`</xsl:text>
                <xsl:apply-templates select="strcmp/*" mode="strcmp-object-substitution"/>
                <xsl:text>`</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="regexFlags">
        <xsl:choose>
            <xsl:when test="strcmp/@use-answer='yes' and $fillin/@case = 'insensitive'">
                <xsl:text>i</xsl:text>
            </xsl:when>
            <xsl:when test="strcmp/@case = 'insensitive'">
                <xsl:text>i</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <!-- create a function to do the regex -->
    <xsl:text>"solution_code": </xsl:text>
    <xsl:variable name="js_code">
        <xsl:text>function(){&#xa;</xsl:text>
            <xsl:text>  const re_str = </xsl:text><xsl:value-of select="$regex"/><xsl:text>;&#xa;</xsl:text>
            <xsl:text>  const re = new RegExp(re_str, "</xsl:text>
            <xsl:value-of select="$regexFlags"/>
            <xsl:text>");&#xa;</xsl:text>
            <xsl:text>  return re.test(ans);&#xa;</xsl:text>
            <xsl:text>}()&#xa;</xsl:text>
            </xsl:variable>
    <xsl:call-template name="escape-quote-string">
        <xsl:with-param name="text" select="$js_code"/>
    </xsl:call-template>
</xsl:template>

<xsl:template match="eval" mode="strcmp-object-substitution">
    <xsl:text>${</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="*" mode="strcmp-object-substitution">
    <xsl:copy-of select="."/>
</xsl:template>

<!-- Otherwise create a function that deals with the test. -->
<xsl:template match="test" mode="create-test">
    <xsl:param name="fillin" />
    <xsl:variable name="conditions" select="*[not(self::feedback)]"/>
    <xsl:text>"solution_code": </xsl:text>
    <xsl:variable name="js_code">
        <xsl:text>function() {&#xa;</xsl:text>
        <!-- Create a checker function. Initialize a stack of flag variables to track results. -->
        <xsl:text>    var testResults = new Array();&#xa;</xsl:text>
        <xsl:choose>
            <xsl:when test="count($conditions) = 1">
                <xsl:call-template name="checker-simple">
                    <xsl:with-param name="fillin" select="$fillin" />
                    <xsl:with-param name="curTest" select="$conditions" />
                    <xsl:with-param name="level" select="0" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="fillin" select="$fillin" />
                    <xsl:with-param name="tests" select="$conditions" />
                    <xsl:with-param name="level" select="0" />
                    <xsl:with-param name="logic" select="'and'" /> <!-- All tests at first layer must be true -->
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>    return (testResults[0]);&#xa;</xsl:text>
        <xsl:text>}()</xsl:text>
    </xsl:variable>
    <xsl:call-template name="escape-quote-string">
        <xsl:with-param name="text" select="$js_code"/>
    </xsl:call-template>
</xsl:template>


<!-- This template is called for a simple test (no compound logic). -->
<xsl:template name="checker-simple">
    <xsl:param name="curTest" />
    <xsl:param name="fillin" />
    <xsl:param name="level" select="0" />
    <xsl:choose>
        <!-- Test might be coded directly in javascript -->
        <xsl:when test="name($curTest) = 'jscmp'">
            <xsl:text>    testResults[</xsl:text>
            <xsl:value-of select="$level" />
            <xsl:text>] = </xsl:text>
            <xsl:value-of select="$curTest"/>
        </xsl:when>
        <!-- Test might require logic -->
        <xsl:when test="name($curTest)='logic'">
            <xsl:call-template name="checker-layer">
                <xsl:with-param name="fillin" select="$fillin" />
                <xsl:with-param name="tests" select="$curTest/*" />
                <xsl:with-param name="level" select="$level + 1" />
                <xsl:with-param name="logic" select="$curTest/@op" /> <!-- Default: All tests at first layer must be true -->
            </xsl:call-template>
            <xsl:text>    testResults[</xsl:text>
            <xsl:value-of select="$level" />
            <xsl:text>] = testResults[</xsl:text>
            <xsl:value-of select="$level + 1" />
            <xsl:text>];&#xa;</xsl:text>
        </xsl:when>
        <!-- Otherwise simple test -->
        <xsl:otherwise>
            <!-- A test can have an implied equal or an explicit equal -->
            <!-- At root level, the test might also have a feedback. Skip that. -->
            <xsl:text>    testResults[</xsl:text>
            <xsl:value-of select="$level" />
            <xsl:text>] = </xsl:text>
            <xsl:text>_mobjs.compareExpressions(</xsl:text>
            <xsl:choose>
                <!-- An equal element must have two expression children. -->
                <xsl:when test="name($curTest)='mathcmp' and $curTest/@use-answer='yes'">
                    <xsl:choose>
                        <xsl:when test="not($fillin/@ansobj)">
                            <xsl:message>PTX:WARNING: Feedback for "<xsl:value-of select="$the-id"/>" says to use given math answer, but @ansobj not defined. </xsl:message>
                            <xsl:text>UNDEFINED</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$fillin/@ansobj"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>, ans</xsl:text>
                </xsl:when>
                <xsl:when test="name($curTest)='mathcmp' and $curTest/@obj">
                    <xsl:value-of select="$curTest/@obj"/>
                    <xsl:text>, ans</xsl:text>
                </xsl:when>
                <xsl:when test="name($curTest)='mathcmp' and count($curTest/*)=1">
                    <xsl:apply-templates select="$curTest/*[1]" mode="evaluate"/>
                    <xsl:text>, ans</xsl:text>
                </xsl:when>
                <xsl:when test="name($curTest)='mathcmp' and count($curTest/*)=2">
                    <xsl:apply-templates select="$curTest/*[1]" mode="evaluate"/>
                    <xsl:text>, </xsl:text>
                    <xsl:apply-templates select="$curTest/*[2]" mode="evaluate"/>
                </xsl:when>
                <!-- An implied equal compares the submitted answer to the given expression. -->
                <xsl:otherwise>   <!-- Must be expression: #eval or #de-expression -->
                    <xsl:apply-templates select="$curTest" mode="evaluate"/>
                    <xsl:text>, ans</xsl:text>
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
    <xsl:param name="fillin" />
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
                    <xsl:with-param name="fillin" select="$fillin" />
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
                    <xsl:with-param name="fillin" select="$fillin" />
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'or'" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="name()='not'">
                <xsl:call-template name="checker-layer">
                    <xsl:with-param name="fillin" select="$fillin" />
                    <xsl:with-param name="tests" select="./*" />
                    <xsl:with-param name="level" select="$level+1" />
                    <xsl:with-param name="logic" select="'not'" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="checker-simple">
                    <xsl:with-param name="fillin" select="$fillin" />
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

<!-- Wrappers for calling appropriate javascript commands that  -->
<!-- will parse the expression for a number appropriately,     -->
<!-- which could be written as an expression involving symbols -->
<!-- or a random number                                        -->
<xsl:template match="de-number" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="de_env">
        <xsl:value-of select="$prefix"/>
        <xsl:text>_mobjs</xsl:text>
    </xsl:variable>
    <xsl:value-of select="$de_env"/>
    <xsl:text>.parseExpression(</xsl:text>
    <xsl:call-template name="quote-strip-string">
        <xsl:with-param name="text" select="."/>
    </xsl:call-template>
    <xsl:text>, "number")</xsl:text>
    <xsl:text>.reduce().simplifyConstants()</xsl:text>
</xsl:template>

<xsl:template match="de-evaluate" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="de_env">
        <xsl:value-of select="$prefix"/>
        <xsl:text>_mobjs</xsl:text>
    </xsl:variable>
    <xsl:value-of select="$de_env"/>
    <xsl:text>.evaluateExpression(</xsl:text>
        <xsl:apply-templates select="formula/*" mode="evaluate">
            <xsl:with-param name="setupMode" select="$setupMode"/>
        </xsl:apply-templates>
        <xsl:text>, "number", {</xsl:text>
        <xsl:apply-templates select="variable" mode="evaluation-binding" >
            <xsl:with-param name="setupMode" select="$setupMode" />
        </xsl:apply-templates>
    <xsl:text>})</xsl:text>
    <xsl:if test="@reduce='yes'">
        <xsl:text>.reduce().simplifyConstants()</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="de-random[@distribution='discrete']" mode="evaluate">
    <xsl:text>v._mobjs.generateRandom("discrete", { min:</xsl:text>
    <xsl:choose>
        <xsl:when test="@min">
            <xsl:value-of select="@min"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, max:</xsl:text>
    <xsl:choose>
        <xsl:when test="@max">
            <xsl:value-of select="@max"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>1</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, by:</xsl:text>
    <xsl:choose>
        <xsl:when test="@by">
            <xsl:value-of select="@by"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>1</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, nonzero:</xsl:text>
    <xsl:choose>
        <xsl:when test="@nonzero = 'yes'">
            <xsl:text>true</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>false</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>})</xsl:text>
</xsl:template>

<!-- Objects defined as formulas. Several possible modes: -->
<!-- formula (literal), substitution (composition),       -->
<!-- derivative and evaluate                              -->
<xsl:template match="de-expression[not(@mode) or @mode='formula']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="de_env">
        <xsl:value-of select="$prefix"/>
        <xsl:text>_mobjs</xsl:text>
    </xsl:variable>
    <xsl:value-of select="$de_env"/>
    <xsl:text>.parseExpression(</xsl:text>
    <xsl:call-template name="quote-strip-string">
        <xsl:with-param name="text" select="."/>
    </xsl:call-template>
    <xsl:text>, "formula")</xsl:text>
    <xsl:if test="@reduce='yes'">
        <xsl:text>.reduce().simplifyConstants()</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="de-expression[@mode='substitution']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="de_env">
        <xsl:value-of select="$prefix"/>
        <xsl:text>_mobjs</xsl:text>
    </xsl:variable>
    <xsl:value-of select="$de_env"/>
    <xsl:text>.composeExpression(</xsl:text>
    <xsl:apply-templates select="formula/*" mode="evaluate">
        <xsl:with-param name="setupMode" select="$setupMode"/>
    </xsl:apply-templates>
    <xsl:text>, {</xsl:text>
    <xsl:apply-templates select="variable" mode="evaluation-binding" >
        <xsl:with-param name="setupMode" select="$setupMode" />
    </xsl:apply-templates>
    <xsl:text>})</xsl:text>
    <xsl:if test="@reduce='yes'">
        <xsl:text>.reduce().simplifyConstants()</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="de-expression[@mode='derivative']" mode="evaluate">
    <xsl:param name="setupMode" />
    <xsl:variable name="prefix">
        <xsl:if test="$setupMode">
            <xsl:text>v.</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="de_env">
        <xsl:value-of select="$prefix"/>
        <xsl:text>_mobjs</xsl:text>
    </xsl:variable>
    <xsl:apply-templates select="formula/*" mode="evaluate">
        <xsl:with-param name="setupMode" select="$setupMode" />
    </xsl:apply-templates>
    <xsl:text>.derivative(</xsl:text>
    <xsl:call-template name="quote-string">
        <xsl:with-param name="text" select="variable/@name"/>
    </xsl:call-template>
    <xsl:text>)</xsl:text>
    <xsl:if test="@reduce='yes'">
        <xsl:text>.reduce().simplifyConstants()</xsl:text>
    </xsl:if>
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
        <xsl:when test="eval or de-number or de-expression">
            <xsl:apply-templates select="eval|de-number|de-expression" mode="evaluate">
                <xsl:with-param name="setupMode" select="$setupMode" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="." />
        </xsl:otherwise>
    </xsl:choose>
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
    <xsl:value-of select="@obj"/>
</xsl:template>

<!-- Nothing else is defined for evaluation during setup  -->
<xsl:template match="/" mode="evaluate"/>

<xsl:template match="feedback" mode="serialize-feedback">
    <xsl:variable name="feedback-rtf">
        <xsl:apply-templates select="*" mode="body"/>
    </xsl:variable>
    <!-- serialize HTML as text, then escape as JSON -->
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:apply-templates select="exsl:node-set($feedback-rtf)" mode="xml-to-string"/>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

</xsl:stylesheet>
