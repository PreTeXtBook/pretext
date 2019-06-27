<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!--********************************************************************
Copyright 2014-2016 Robert A. Beezer

This file is part of MathBook XML.

MathBook XML is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

MathBook XML is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- See  xsl/localizations/README.md  for an explanation of this file -->

<!-- en-US, English (United States) -->
<!-- Robert A. Beezer, beezer@pugetsound.edu, 2014-08-11   -->

<xsl:variable name="en-US">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id='theorem'><xsl:text>Theorem</xsl:text></localization>
    <localization string-id='corollary'><xsl:text>Corollary</xsl:text></localization>
    <localization string-id='lemma'><xsl:text>Lemma</xsl:text></localization>
    <localization string-id='algorithm'><xsl:text>Algorithm</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Proposition</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Claim</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Fact</xsl:text></localization>
    <localization string-id='identity'><xsl:text>Identity</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Proof</xsl:text></localization>
    <localization string-id='case'><xsl:text>Case</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Axiom</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Conjecture</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Principle</xsl:text></localization>
    <localization string-id='heuristic'><xsl:text>Heuristic</xsl:text></localization>
    <localization string-id='hypothesis'><xsl:text>Hypothesis</xsl:text></localization>
    <localization string-id='assumption'><xsl:text>Assumption</xsl:text></localization>
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Definition</xsl:text></localization>
    <!-- Single Line Mathematics -->
    <localization string-id='me'><xsl:text>Equation</xsl:text></localization>
    <localization string-id='men'><xsl:text>Equation</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Equation</xsl:text></localization>
    <!-- Display Mathematics -->
    <localization string-id='md'><xsl:text>Display Mathematics</xsl:text></localization>
    <localization string-id='mdn'><xsl:text>Display Mathematics</xsl:text></localization>
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Volume</xsl:text></localization>
    <localization string-id='book'><xsl:text>Book</xsl:text></localization>
    <localization string-id='article'><xsl:text>Article</xsl:text></localization>
    <localization string-id='letter'><xsl:text>Letter</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Memo</xsl:text></localization>
    <localization string-id='presentation'><xsl:text>Presentation</xsl:text></localization>
    <!-- Parts of a document -->
    <!-- "part" will also be used for a "stage" of a WeBWorK problem -->
    <localization string-id='frontmatter'><xsl:text>Front Matter</xsl:text></localization>
    <localization string-id='part'><xsl:text>Part</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Chapter</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Appendix</xsl:text></localization>
    <localization string-id='section'><xsl:text>Section</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Subsection</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>Subsubsection</xsl:text></localization>
    <localization string-id='introduction'><xsl:text>Introduction</xsl:text></localization>
    <localization string-id='conclusion'><xsl:text>Conclusion</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Exercises</xsl:text></localization>
    <localization string-id='worksheet'><xsl:text>Worksheet</xsl:text></localization>
    <localization string-id='reading-questions'><xsl:text>Reading Questions</xsl:text></localization>
    <localization string-id='solutions'><xsl:text>Solutions</xsl:text></localization>
    <localization string-id='glossary'><xsl:text>Glossary</xsl:text></localization>
    <localization string-id='references'><xsl:text>References</xsl:text></localization>
    <localization string-id='backmatter'><xsl:text>Back Matter</xsl:text></localization>
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Paragraphs</xsl:text></localization>
    <localization string-id='commentary'><xsl:text>Commentary</xsl:text></localization>
    <localization string-id='subparagraph'><xsl:text>Subparagraph</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Remark</xsl:text></localization>
    <localization string-id='convention'><xsl:text>Convention</xsl:text></localization>
    <localization string-id='note'><xsl:text>Note</xsl:text></localization>
    <localization string-id='observation'><xsl:text>Observation</xsl:text></localization>
    <localization string-id='warning'><xsl:text>Warning</xsl:text></localization>
    <localization string-id='insight'><xsl:text>Insight</xsl:text></localization>
    <localization string-id='computation'><xsl:text>Computation</xsl:text></localization>
    <localization string-id='technology'><xsl:text>Technology</xsl:text></localization>
    <!-- ASIDE-LIKE blocks -->
    <localization string-id='aside'><xsl:text>Aside</xsl:text></localization>
    <localization string-id='biographical'><xsl:text>Biographical Aside</xsl:text></localization>
    <localization string-id='historical'><xsl:text>Historical Aside</xsl:text></localization>
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Example</xsl:text></localization>
    <localization string-id='question'><xsl:text>Question</xsl:text></localization>
    <localization string-id='problem'><xsl:text>Problem</xsl:text></localization>
    <!-- PROJECT-LIKE blocks -->
    <localization string-id='project'><xsl:text>Project</xsl:text></localization>
    <localization string-id='activity'><xsl:text>Activity</xsl:text></localization>
    <localization string-id='exploration'><xsl:text>Exploration</xsl:text></localization>
    <localization string-id='task'><xsl:text>Task</xsl:text></localization>
    <localization string-id='investigation'><xsl:text>Investigation</xsl:text></localization>
    <!-- assemblages are collections of minimally structured material -->
    <localization string-id='assemblage'><xsl:text>Assemblage</xsl:text></localization>
    <localization string-id='poem'><xsl:text>Poem</xsl:text></localization>
    <!-- Objectives is the block, objective is a list item within -->
    <localization string-id='objectives'><xsl:text>Objectives</xsl:text></localization>
    <localization string-id='objective'><xsl:text>Objective</xsl:text></localization>
    <!-- Outcomes is the block, outcome is a list item within (different) -->
    <!-- These two words need to be different, to avoid ambiguous cross-references -->
    <localization string-id='outcomes'><xsl:text>Outcomes</xsl:text></localization>
    <localization string-id='outcome'><xsl:text>Outcome</xsl:text></localization>
    <!--  -->
    <localization string-id='figure'><xsl:text>Figure</xsl:text></localization>
    <localization string-id='table'><xsl:text>Table</xsl:text></localization>
    <localization string-id='listing'><xsl:text>Listing</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Footnote</xsl:text></localization>
    <localization string-id='contributor'><xsl:text>Contributor</xsl:text></localization>
    <!-- Lists and their items -->
    <localization string-id='list'><xsl:text>List</xsl:text></localization>
    <localization string-id='li'><xsl:text>Item</xsl:text></localization>
    <!-- A term (word) defined in a glossary -->
    <localization string-id='defined-term'><xsl:text>Term</xsl:text></localization>
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Paragraph</xsl:text></localization>
    <localization string-id='blockquote'><xsl:text>Quotation</xsl:text></localization>
    <!-- Parts of an exercise and it's solution -->
    <!-- An "exercise", at any level, within an "exercises" division is a          -->
    <!-- "divisional" exercise and the string employed is 'divisionalexercise'.    -->
    <!-- An "exercise" whose parent is a division (chapter, section, etc) we       -->
    <!-- call an "inline exercise" and the string employed is 'inlineexercise'.    -->
    <!-- And an "exercise" in a "worksheet" is a 'worksheetexercise'.              -->
    <!-- And an "exercise" in a "reading-questions" is a 'readingquestion'.         -->
    <!-- It is important to use different translations so that a text with         -->
    <!-- different types of exercises do not have ambiguous cross-references       -->
    <!-- (there is an example of this at the start of one of the later             -->
    <!-- sections of the sample article).                                          -->
    <!--                                                                           -->
    <!-- In English, an "Exercise" is something you do that has a beneficial       -->
    <!-- outcome, such as "I am going to the gym to exercise."  A "Checkpoint"     -->
    <!-- is something you must do before you do something else.  Another use of    -->
    <!-- the term is a location on a on a roadway where you must stop for the      -->
    <!-- police to do an inspection. A worksheet is a collection of activities or  -->
    <!-- problems, typically printed on paper, which might be used in a classroom. -->
    <localization string-id='divisionalexercise'><xsl:text>Exercise</xsl:text></localization>
    <localization string-id='inlineexercise'><xsl:text>Checkpoint</xsl:text></localization>
    <localization string-id='worksheetexercise'><xsl:text>Worksheet Exercise</xsl:text></localization>
    <localization string-id='readingquestion'><xsl:text>Reading Question</xsl:text></localization>
    <localization string-id='webwork'><xsl:text>WeBWorK</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Hint</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Answer</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Solution</xsl:text></localization>
    <!-- A group of divisional exercises (with introduction and conclusion) -->
    <localization string-id='exercisegroup'><xsl:text>Exercise Group</xsl:text></localization>
    <!-- Bibliographic items (note is distinct from sidebar "Annotations" below) -->
    <localization string-id='biblio'><xsl:text>Bibliographic Entry</xsl:text></localization>
    <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Contents</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Abstract</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Preface</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Acknowledgements</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Author Biography</xsl:text></localization>
    <!-- singular and plural titles for biography subdivision -->
    <localization string-id='about-author'><xsl:text>About the Author</xsl:text></localization>
    <localization string-id='about-authors'><xsl:text>About the Authors</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Foreword</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Dedication</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Colophon</xsl:text></localization>
    <!-- Back matter components -->
    <!-- index-part is deprecated, but not abandoned          -->
    <!-- NB: repurpose translations, maybe move appendix here -->
    <localization string-id='index-part'><xsl:text>Index</xsl:text></localization>
    <localization string-id='jump-to'><xsl:text>Jump to:</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='index'><xsl:text>Index</xsl:text></localization>
    <localization string-id='see'><xsl:text>See</xsl:text></localization>
    <localization string-id='also'><xsl:text>See also</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>Symbol</xsl:text></localization>
    <localization string-id='description'><xsl:text>Description</xsl:text></localization>
    <localization string-id='location'><xsl:text>Location</xsl:text></localization>
    <localization string-id='page'><xsl:text>Page</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Continued on next page</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <!-- Assistive "skip to content" link -->
    <localization string-id='skip-to-content'><xsl:text>Skip to main content</xsl:text></localization>
    <localization string-id='previous'><xsl:text>Previous</xsl:text></localization>
    <localization string-id='up'><xsl:text>Up</xsl:text></localization>
    <localization string-id='next'><xsl:text>Next</xsl:text></localization>
    <!-- Keep these short, so buttons are not overly wide, 4 characters maximum -->
    <localization string-id='previous-short'><xsl:text>Prev</xsl:text></localization>
    <localization string-id='up-short'><xsl:text>Up</xsl:text></localization>
    <localization string-id='next-short'><xsl:text>Next</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Annotations</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Feedback</xsl:text></localization>
    <localization string-id='authored'><xsl:text>Authored in</xsl:text></localization>
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>To</xsl:text></localization>
    <localization string-id='from'><xsl:text>From</xsl:text></localization>
    <localization string-id='subject'><xsl:text>Subject</xsl:text></localization>
    <localization string-id='date'><xsl:text>Date</xsl:text></localization>
    <localization string-id='copy'><xsl:text>cc</xsl:text></localization>
    <localization string-id='enclosure'><xsl:text>encl</xsl:text></localization>
    <!-- Various -->
    <localization string-id='todo'><xsl:text>To Do</xsl:text></localization>
    <localization string-id='editor'><xsl:text>Editor</xsl:text></localization>
    <localization string-id='edition'><xsl:text>Edition</xsl:text></localization>
    <localization string-id='website'><xsl:text>Website</xsl:text></localization>
    <localization string-id='copyright'><xsl:text>Copyright</xsl:text></localization>
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>permalink</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>in-context</xsl:text></localization>
    <!-- Sage Cell evaluate button      -->
    <!-- eg, "Evaluate (Maxima)"        -->
    <!-- 2017-05-14: 'code' is obsolete -->
    <!-- This needs to be defined to *something* (always)       -->
    <!-- else whatever crud ends up on the button kills the cell -->
    <localization string-id='evaluate'><xsl:text>Evaluate</xsl:text></localization>
    <localization string-id='evaluate'><xsl:text>Evaluate</xsl:text></localization>
    <!-- <localization string-id='code'><xsl:text>Code</xsl:text></localization> -->
</xsl:variable>

</xsl:stylesheet>
