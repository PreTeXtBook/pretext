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

<!-- de-DE, German (Germany) -->
<!-- Karl-Dieter Crisman, kcrisman@gmail.com, 2020-06-01   -->

<xsl:variable name="de-DE">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id='theorem'><xsl:text>Satz</xsl:text></localization>
    <localization string-id='corollary'><xsl:text>Korollar</xsl:text></localization>
    <localization string-id='lemma'><xsl:text>Hilfssatz</xsl:text></localization>
    <localization string-id='algorithm'><xsl:text>Algorithmus</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Proposition</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Behauptung</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Fakt</xsl:text></localization>
    <localization string-id='identity'><xsl:text>Identität</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Beweis</xsl:text></localization>
    <localization string-id='case'><xsl:text>Fall</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Axiom</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Vermutung</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Prinzip</xsl:text></localization>
<!--    <localization string-id='heuristic'><xsl:text>Heuristic</xsl:text></localization> -->
    <localization string-id='hypothesis'><xsl:text>Hypothese</xsl:text></localization>
    <localization string-id='assumption'><xsl:text>Voraussetzung</xsl:text></localization>
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Definition</xsl:text></localization>
    <!-- Single Line Mathematics -->
    <localization string-id='me'><xsl:text>Gleichung</xsl:text></localization>
    <localization string-id='men'><xsl:text>Gleichung</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Gleichung</xsl:text></localization>
    <!-- Display Mathematics -->
<!--    <localization string-id='md'><xsl:text>Display Mathematics</xsl:text></localization> -->
<!--    <localization string-id='mdn'><xsl:text>Display Mathematics</xsl:text></localization> -->
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Band</xsl:text></localization>
    <localization string-id='book'><xsl:text>Buch</xsl:text></localization>
    <localization string-id='article'><xsl:text>Artikel</xsl:text></localization>
    <!-- <localization string-id='slideshow'><xsl:text>Slideshow</xsl:text></localization> -->
    <localization string-id='letter'><xsl:text>Brief</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Memo</xsl:text></localization> <!-- oder Memorandum? -->
    <localization string-id='presentation'><xsl:text>Vortrag</xsl:text></localization>
    <!-- Parts of a document -->
    <!-- "part" will also be used for a "stage" of a WeBWorK problem -->
<!--    <localization string-id='frontmatter'><xsl:text>Front Matter</xsl:text></localization> -->
    <localization string-id='part'><xsl:text>Teil</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Kapitel</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Anhang</xsl:text></localization>
    <localization string-id='section'><xsl:text>Abschnitt</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Unterabschnitt</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>Unterunterabschnitt</xsl:text></localization>
    <!-- A "slide" is a screenful of a presentation (Powerpoint, Beamer) -->
    <!-- <localization string-id='slide'><xsl:text>Slide</xsl:text></localization> -->
    <localization string-id='introduction'><xsl:text>Einleitung</xsl:text></localization>
    <localization string-id='conclusion'><xsl:text>Schluss</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Übungen</xsl:text></localization>
    <localization string-id='worksheet'><xsl:text>Arbeitsblatt</xsl:text></localization>
    <localization string-id='reading-questions'><xsl:text>Lesefragen</xsl:text></localization>
    <localization string-id='solutions'><xsl:text>Lösungen</xsl:text></localization>
    <!-- Wörterverzeichnis scheint viel weniger benutzt zu sein, s. Google ngram -->
    <localization string-id='glossary'><xsl:text>Glossar</xsl:text></localization> 
    <!-- oder Bibliographie wird auch benutzt -->
    <localization string-id='references'><xsl:text>Literaturverzeichnis</xsl:text></localization>
<!--    <localization string-id='backmatter'><xsl:text>Back Matter</xsl:text></localization> -->
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Absätze</xsl:text></localization>
    <localization string-id='commentary'><xsl:text>Kommentar</xsl:text></localization>
    <localization string-id='subparagraph'><xsl:text>Unterabsatz</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Bemerkung</xsl:text></localization>
<!--    <localization string-id='convention'><xsl:text>Convention</xsl:text></localization> -->
    <localization string-id='note'><xsl:text>Vermerk</xsl:text></localization>
    <!-- Bemerkung versus Anmerkung - I have reserved Anmerkung for footnote -->
    <localization string-id='observation'><xsl:text>Bemerkung</xsl:text></localization>
    <localization string-id='warning'><xsl:text>Warnung</xsl:text></localization>
<!--    <localization string-id='insight'><xsl:text>Insight</xsl:text></localization> -->
<!--    <localization string-id='computation'><xsl:text>Computation</xsl:text></localization> -->
    <localization string-id='technology'><xsl:text>Technologie</xsl:text></localization>
    <!-- ASIDE-LIKE blocks -->
<!--    <localization string-id='aside'><xsl:text>Aside</xsl:text></localization> -->
<!--    <localization string-id='biographical'><xsl:text>Biographical Aside</xsl:text></localization> -->
<!--    <localization string-id='historical'><xsl:text>Historical Aside</xsl:text></localization> -->
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Beispiel</xsl:text></localization>
    <localization string-id='question'><xsl:text>Frage</xsl:text></localization>
    <localization string-id='problem'><xsl:text>Problem</xsl:text></localization>
    <!-- PROJECT-LIKE blocks -->
<!--    <localization string-id='project'><xsl:text>Project</xsl:text></localization> -->
<!--    <localization string-id='activity'><xsl:text>Activity</xsl:text></localization> -->
<!--    <localization string-id='exploration'><xsl:text>Exploration</xsl:text></localization> -->
    <localization string-id='task'><xsl:text>Aufgabe</xsl:text></localization>
<!--    <localization string-id='investigation'><xsl:text>Investigation</xsl:text></localization> -->
    <!-- assemblages are collections of minimally structured material -->
<!--    <localization string-id='assemblage'><xsl:text>Assemblage</xsl:text></localization> -->
    <localization string-id='poem'><xsl:text>Gedicht</xsl:text></localization>
    <!-- Objectives is the block, objective is a list item within -->
<!--    <localization string-id='objectives'><xsl:text>Objectives</xsl:text></localization> -->
<!--    <localization string-id='objective'><xsl:text>Objective</xsl:text></localization> -->
    <!-- Outcomes is the block, outcome is a list item within (different) -->
    <!-- These two words need to be different, to avoid ambiguous cross-references -->
<!--    <localization string-id='outcomes'><xsl:text>Outcomes</xsl:text></localization> -->
<!--    <localization string-id='outcome'><xsl:text>Outcome</xsl:text></localization> -->
    <localization string-id='figure'><xsl:text>Figur</xsl:text></localization> <!-- Duden 4b für Figur -->
    <localization string-id='table'><xsl:text>Tabelle</xsl:text></localization>
<!--    <localization string-id='listing'><xsl:text>Listing</xsl:text></localization> -->
    <localization string-id='fn'><xsl:text>Anmerkung</xsl:text></localization>
<!--    <localization string-id='contributor'><xsl:text>Contributor</xsl:text></localization> -->
    <!-- Lists and their items -->
    <localization string-id='list'><xsl:text>Liste</xsl:text></localization>
<!--    <localization string-id='li'><xsl:text>Item</xsl:text></localization> -->
    <!-- A term (word) defined in a glossary -->
<!--    <localization string-id='defined-term'><xsl:text>Term</xsl:text></localization> -->
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Absatz</xsl:text></localization>
    <localization string-id='blockquote'><xsl:text>Zitat</xsl:text></localization>
    <!-- Literate programming, a chunk of computer code -->
    <!-- <localization string-id='fragment'><xsl:text>Fragment</xsl:text></localization> -->
    <!-- Parts of an exercise and its solution -->
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
    <localization string-id='divisionalexercise'><xsl:text>Übung</xsl:text></localization>
<!--    <localization string-id='inlineexercise'><xsl:text>Checkpoint</xsl:text></localization> -->
    <localization string-id='worksheetexercise'><xsl:text>Arbeitsübung</xsl:text></localization>
    <localization string-id='readingquestion'><xsl:text>Lesefrage</xsl:text></localization>
    <localization string-id='webwork'><xsl:text>WeBWorK</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Andeutung</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Antwort</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Lösung</xsl:text></localization>
    <!-- A group of divisional exercises (with introduction and conclusion) -->
    <localization string-id='exercisegroup'><xsl:text>Übungsgruppe</xsl:text></localization>
    <!-- Bibliographic items (note is distinct from sidebar "Annotations" below) -->
<!--    <localization string-id='biblio'><xsl:text>Bibliographic Entry</xsl:text></localization> -->
    <!-- Front matter components -->
    <!-- this one is tough because for short version like in navigation bar Inhalt is fine, but long one in print probably Inhaltsverzeichnis -->
    <localization string-id='toc'><xsl:text>Inhalt</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Zusammenfassung</xsl:text></localization><!-- or is Abstrakt used? -->
    <localization string-id='preface'><xsl:text>Einleitung</xsl:text></localization>
<!--    <localization string-id='acknowledgement'><xsl:text>Acknowledgements</xsl:text></localization> -->
<!--    <localization string-id='biography'><xsl:text>Author Biography</xsl:text></localization> -->
    <!-- singular and plural titles for biography subdivision -->
<!--    <localization string-id='about-author'><xsl:text>About the Author</xsl:text></localization> -->
<!--    <localization string-id='about-authors'><xsl:text>About the Authors</xsl:text></localization> -->
    <localization string-id='foreword'><xsl:text>Vorwort</xsl:text></localization>
<!--    <localization string-id='dedication'><xsl:text>Dedication</xsl:text></localization> -->
<!--    <localization string-id='colophon'><xsl:text>Colophon</xsl:text></localization> -->
    <!-- Back matter components -->
    <!-- index-part is deprecated, but not abandoned          -->
    <!-- NB: repurpose translations, maybe move appendix here -->
    <!-- oder auch Index, siehe http://www.d-indexer.org/frag/grundsatz.html#index -->
    <localization string-id='index-part'><xsl:text>Register</xsl:text></localization>
<!--    <localization string-id='jump-to'><xsl:text>Jump to:</xsl:text></localization> -->
    <!-- Parts of the Index -->
    <!-- see https://online.liverpooluniversitypress.co.uk/doi/pdf/10.3828/indexer.2006.21 for lots more info on peculiarities of German indexing we cannot hope to follow -->
    <localization string-id='index'><xsl:text>Register</xsl:text></localization>
    <localization string-id='see'><xsl:text>siehe</xsl:text></localization>
    <localization string-id='also'><xsl:text>siehe auch</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>Symbol</xsl:text></localization>
    <localization string-id='description'><xsl:text>Beschreibung</xsl:text></localization>
    <localization string-id='location'><xsl:text>Stelle</xsl:text></localization>
    <localization string-id='page'><xsl:text>Seite</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Nächste Seite weiter</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <!-- Assistive "skip to content" link -->
    <localization string-id='skip-to-content'><xsl:text>Weiter zum Hauptinhalt</xsl:text></localization>
    <!-- I am not at all sure of the state of the art on this convention -->
    <localization string-id='previous'><xsl:text>Zurück</xsl:text></localization>
    <localization string-id='up'><xsl:text>Oben</xsl:text></localization>
    <localization string-id='next'><xsl:text>Weiter</xsl:text></localization>
    <!-- Keep these short, so buttons are not overly wide, 4 characters maximum -->
    <!-- I am even less sure here - can one really shorten "Weiter"? -->
    <localization string-id='previous-short'><xsl:text>Zu</xsl:text></localization>
    <localization string-id='up-short'><xsl:text>Ob</xsl:text></localization>
    <localization string-id='next-short'><xsl:text>We</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
<!--    <localization string-id='annotations'><xsl:text>Annotations</xsl:text></localization> -->
<!--    <localization string-id='feedback'><xsl:text>Feedback</xsl:text></localization> -->
    <!-- This phrase should suggest that PreTeXt is the source -->
    <!-- language that makes a particular output possible      -->
    <localization string-id='authored'><xsl:text>Mit PreTeXt gebaut</xsl:text></localization>
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>An</xsl:text></localization>
    <localization string-id='from'><xsl:text>Von</xsl:text></localization>
<!--    <localization string-id='subject'><xsl:text>Subject</xsl:text></localization> -->
<!--    <localization string-id='date'><xsl:text>Date</xsl:text></localization> -->
<!--    <localization string-id='copy'><xsl:text>cc</xsl:text></localization> -->
<!--    <localization string-id='enclosure'><xsl:text>encl</xsl:text></localization> -->
    <!-- Various -->
<!--    <localization string-id='todo'><xsl:text>To Do</xsl:text></localization> -->
    <!-- Herausgeber seems more at publisher, but not always -->
    <localization string-id='editor'><xsl:text>Redakteur</xsl:text></localization>
    <localization string-id='edition'><xsl:text>Auflage</xsl:text></localization>
    <localization string-id='website'><xsl:text>Website</xsl:text></localization>
    <localization string-id='copyright'><xsl:text>Urheberrechte</xsl:text></localization>
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>Permalink</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>im Zusammenhang</xsl:text></localization>
    <!-- Sage Cell evaluate button      -->
    <!-- eg, "Evaluate (Maxima)"        -->
    <!-- 2017-05-14: 'code' is obsolete -->
    <!-- This needs to be defined to *something* (always)       -->
    <!-- else whatever crud ends up on the button kills the cell -->
    <!-- Though at least one Sage cell installation uses Auswerten instead -->
    <localization string-id='evaluate'><xsl:text>Ausführen</xsl:text></localization>
<!--    <localization string-id='code'><xsl:text>Code</xsl:text></localization> -->
</xsl:variable>

</xsl:stylesheet>
