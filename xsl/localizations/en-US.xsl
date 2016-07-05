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
    <localization string-id='references'><xsl:text>References</xsl:text></localization>
    <localization string-id='backmatter'><xsl:text>Back Matter</xsl:text></localization>
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Paragraphs</xsl:text></localization>
    <localization string-id='paragraph'><xsl:text>Paragraph</xsl:text></localization>
    <localization string-id='subparagraph'><xsl:text>Subparagraph</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Remark</xsl:text></localization>
    <localization string-id='convention'><xsl:text>Convention</xsl:text></localization>
    <localization string-id='note'><xsl:text>Note</xsl:text></localization>
    <localization string-id='observation'><xsl:text>Observation</xsl:text></localization>
    <localization string-id='warning'><xsl:text>Warning</xsl:text></localization>
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
    <!--  -->
    <localization string-id='figure'><xsl:text>Figure</xsl:text></localization>
    <localization string-id='table'><xsl:text>Table</xsl:text></localization>
    <localization string-id='listing'><xsl:text>Listing</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Footnote</xsl:text></localization>
    <localization string-id='contributor'><xsl:text>Contributor</xsl:text></localization>
    <!-- Lists and their items -->
    <localization string-id='list'><xsl:text>List</xsl:text></localization>
    <localization string-id='li'><xsl:text>Item</xsl:text></localization>
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Paragraph</xsl:text></localization>
    <!-- Parts of an exercise and it's solution -->
    <localization string-id='exercise'><xsl:text>Exercise</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Hint</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Answer</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Solution</xsl:text></localization>
    <!-- A group of sectional exercises (with introduction and conclusion) -->
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
    <!-- Following is temporary, "index-part" to be deprecated, only in en-US now -->
    <!-- NB: repurpose translations, replace "indexsection below", maybe move appendix here -->
    <localization string-id='index-part'><xsl:text>Index</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='indexsection'><xsl:text>Index</xsl:text></localization>
    <localization string-id='see'><xsl:text>see</xsl:text></localization>
    <localization string-id='also'><xsl:text>see also</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>Symbol</xsl:text></localization>
    <localization string-id='description'><xsl:text>Description</xsl:text></localization>
    <localization string-id='location'><xsl:text>Location</xsl:text></localization>
    <localization string-id='page'><xsl:text>Page</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Continued on next page</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <localization string-id='previous'><xsl:text>Previous</xsl:text></localization>
    <localization string-id='up'><xsl:text>Up</xsl:text></localization>
    <localization string-id='next'><xsl:text>Next</xsl:text></localization>
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
    <localization string-id='copyright'><xsl:text>Copyright</xsl:text></localization>
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>permalink</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>in-context</xsl:text></localization>
    <!-- Sage Cell evaluate button  -->
    <!-- eg, "Evaluate Maxima Code" -->
    <localization string-id='evaluate'><xsl:text>Evaluate</xsl:text></localization>
    <localization string-id='code'><xsl:text>Code</xsl:text></localization>
</xsl:variable>

</xsl:stylesheet>
