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

<!-- af-ZA, Afrikaans (South Africa) -->
<!-- Dirk Basson, djbasson@sun.ac.za, 2018-03-23 -->

<xsl:variable name="af-ZA">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id='theorem'><xsl:text>Stelling</xsl:text></localization>
    <localization string-id='corollary'><xsl:text>Gevolg</xsl:text></localization>
    <localization string-id='lemma'><xsl:text>Hulpstelling</xsl:text></localization> <!-- Or "Lemma" as well -->
    <localization string-id='algorithm'><xsl:text>Algoritme</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Stelling</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Aanvoering</xsl:text></localization> <!-- This was a difficult one for me. The most obvious candidate is "bewering", but this is already used as a technical term for a mathematical statement. Words like "veronderstelling", "eis", "postuleer" all convey slightly the wrong meaning. "Aanvoering" is slightly awkward, but the best I could think of. -D.Basson -->
    <localization string-id='fact'><xsl:text>Feit</xsl:text></localization>
    <localization string-id='identity'><xsl:text>Identiteit</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Bewys</xsl:text></localization>
    <localization string-id='case'><xsl:text>Geval</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Aksioma</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Vermoede</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Beginsel</xsl:text></localization>
    <localization string-id='heuristic'><xsl:text>Heuristiek</xsl:text></localization>
    <localization string-id='hypothesis'><xsl:text>Hipotese</xsl:text></localization>
    <localization string-id='assumption'><xsl:text>Aanname</xsl:text></localization>
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Definisie</xsl:text></localization>
    <!-- Single Line Mathematics -->
    <localization string-id='me'><xsl:text>Vergelyking</xsl:text></localization>
    <localization string-id='men'><xsl:text>Vergelyking</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Vergelyking</xsl:text></localization>
    <!-- Display Mathematics -->
    <localization string-id='md'><xsl:text>Vertoon Wiskunde</xsl:text></localization>
    <localization string-id='mdn'><xsl:text>Vertoon Wiskunde</xsl:text></localization>
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Volume</xsl:text></localization>
    <localization string-id='book'><xsl:text>Boek</xsl:text></localization>
    <localization string-id='article'><xsl:text>Artikel</xsl:text></localization>
    <localization string-id='slideshow'><xsl:text>Skyfie Vertoning</xsl:text></localization>
    <localization string-id='letter'><xsl:text>Brief</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Memo</xsl:text></localization>
    <localization string-id='presentation'><xsl:text>Aanbieding</xsl:text></localization>
    <!-- Parts of a document -->
    <!-- "part" will also be used for a "stage" of a WeBWorK problem -->
    <localization string-id='frontmatter'><xsl:text>Voorsake</xsl:text></localization> <!-- Can't find this anywhere, so I made it up. -->
    <localization string-id='part'><xsl:text>Deel</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Hoofstuk</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Bylaag</xsl:text></localization>
    <localization string-id='section'><xsl:text>Afdeling</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Onderafdeling</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>Onderonderafdeling</xsl:text></localization>
    <!-- A "slide" is a screenful of a presentation (Powerpoint, Beamer) -->
    <localization string-id='slide'><xsl:text>Skyfie</xsl:text></localization>
    <localization string-id='introduction'><xsl:text>Inleiding</xsl:text></localization>
    <localization string-id='conclusion'><xsl:text>Slot</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Oefeninge</xsl:text></localization>
    <localization string-id='worksheet'><xsl:text>Werkblad</xsl:text></localization>
    <localization string-id='reading-questions'><xsl:text>Leesvrae</xsl:text></localization>
    <localization string-id='solutions'><xsl:text>Oplossings</xsl:text></localization>
    <localization string-id='glossary'><xsl:text>Woordelys</xsl:text></localization>
    <localization string-id='references'><xsl:text>Verwysings</xsl:text></localization>
    <localization string-id='backmatter'><xsl:text>Nasake</xsl:text></localization> <!-- Can't find this anywhere, so I made it up. -->
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Paragrawe</xsl:text></localization>
    <localization string-id='commentary'><xsl:text>Kommentaar</xsl:text></localization>
    <localization string-id='subparagraph'><xsl:text>Onderparagrawe</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Opmerking</xsl:text></localization>
    <localization string-id='convention'><xsl:text>Konvensie</xsl:text></localization>
    <localization string-id='note'><xsl:text>Nota</xsl:text></localization>
    <localization string-id='observation'><xsl:text>Waarneming</xsl:text></localization>
    <localization string-id='warning'><xsl:text>Waarskuwing</xsl:text></localization>
    <localization string-id='insight'><xsl:text>Insig</xsl:text></localization>
    <localization string-id='computation'><xsl:text>Berekening</xsl:text></localization>
    <localization string-id='technology'><xsl:text>Tegnologie</xsl:text></localization>
    <!-- ASIDE-LIKE blocks -->
    <localization string-id='aside'><xsl:text>Ter Syde</xsl:text></localization>
    <localization string-id='biographical'><xsl:text>Biografiese Ter Syde</xsl:text></localization>
    <localization string-id='historical'><xsl:text>Geskiedkundige Ter Syde</xsl:text></localization>
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Voorbeeld</xsl:text></localization>
    <localization string-id='question'><xsl:text>Vraag</xsl:text></localization>
    <localization string-id='problem'><xsl:text>Probleem</xsl:text></localization>
    <!-- PROJECT-LIKE blocks -->
    <localization string-id='project'><xsl:text>Projek</xsl:text></localization>
    <localization string-id='activity'><xsl:text>Aktiwiteit</xsl:text></localization>
    <localization string-id='exploration'><xsl:text>Verkenning</xsl:text></localization>
    <localization string-id='task'><xsl:text>Taak</xsl:text></localization>
    <localization string-id='investigation'><xsl:text>Ondersoek</xsl:text></localization>
    <!-- assemblages are collections of minimally structured material -->
    <localization string-id='assemblage'><xsl:text>Samevatting</xsl:text></localization>
    <localization string-id='poem'><xsl:text>Gedig</xsl:text></localization>
    <!-- Objectives is the block, objective is a list item within -->
    <localization string-id='objectives'><xsl:text>Doelstellings</xsl:text></localization>
    <localization string-id='objective'><xsl:text>Doelstelling</xsl:text></localization>
    <!-- Outcomes is the block, outcome is a list item within (different) -->
    <!-- These two words need to be different, to avoid ambiguous cross-references -->
    <localization string-id='outcomes'><xsl:text>Uitkomstes</xsl:text></localization>
    <localization string-id='outcome'><xsl:text>Uitkoms</xsl:text></localization>
    <!--  -->
    <localization string-id='figure'><xsl:text>Figuur</xsl:text></localization>
    <localization string-id='table'><xsl:text>Tabel</xsl:text></localization>
    <localization string-id='listing'><xsl:text>Lys</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Voetnota</xsl:text></localization>
    <localization string-id='contributor'><xsl:text>Bydraer</xsl:text></localization>
    <!-- Lists and their items -->
    <localization string-id='list'><xsl:text>Lys</xsl:text></localization>
    <localization string-id='li'><xsl:text>Item</xsl:text></localization>
    <!-- A term (word) defined in a glossary -->
    <localization string-id='defined-term'><xsl:text>Term</xsl:text></localization>
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Paragraaf</xsl:text></localization>
    <localization string-id='blockquote'><xsl:text>Aanhaling</xsl:text></localization>
    <!-- Literate programming, a chunk of computer code -->
    <localization string-id='fragment'><xsl:text>Fragment</xsl:text></localization>
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
    <!-- the term is a location on a roadway where you must stop for the      -->
    <!-- police to do an inspection. A worksheet is a collection of activities or  -->
    <!-- problems, typically printed on paper, which might be used in a classroom. -->
    <localization string-id='divisionalexercise'><xsl:text>Oefening</xsl:text></localization>
    <localization string-id='inlineexercise'><xsl:text>Kontrolepunt</xsl:text></localization>
    <localization string-id='worksheetexercise'><xsl:text>Werkbladoefening</xsl:text></localization>
    <localization string-id='readingquestion'><xsl:text>Leesvraag</xsl:text></localization>
    <localization string-id='webwork'><xsl:text>WeBWorK</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Wenk</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Antwoord</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Oplossing</xsl:text></localization>
    <!-- A group of divisional exercises (with introduction and conclusion) -->
    <localization string-id='exercisegroup'><xsl:text>Oefening Groep</xsl:text></localization>
    <!-- Bibliographic items (note is distinct from sidebar "Annotations" below) -->
    <localization string-id='biblio'><xsl:text>Bibliografiese Inskrywing</xsl:text></localization>
    <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Inhoudsopgawe</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Abstrak</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Voorwoord</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Erkennings</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Skrywer Biografie</xsl:text></localization>
    <!-- singular and plural titles for biography subdivision -->
    <localization string-id='about-author'><xsl:text>Oor die skrywer</xsl:text></localization>
    <localization string-id='about-authors'><xsl:text>Oor die skrywers</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Voorwoord</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Toewyding</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Kolofon</xsl:text></localization> <!-- I have never heard of an Afrikaans version of colophon. Google Translate gives "slottitel" for the Dutch, meaning "Summary title". So , I just made this up. -D.Basson -->
    <!-- Back matter components -->
    <!-- index-part is deprecated, but not abandoned          -->
    <!-- NB: repurpose translations, maybe move appendix here -->
    <localization string-id='index-part'><xsl:text>Indeks</xsl:text></localization>
    <localization string-id='jump-to'><xsl:text>Spring na</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='index'><xsl:text>Indeks</xsl:text></localization>
    <localization string-id='see'><xsl:text>Sien</xsl:text></localization>
    <localization string-id='also'><xsl:text>Sien ook</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>Simbool</xsl:text></localization>
    <localization string-id='description'><xsl:text>Beskrywing</xsl:text></localization>
    <localization string-id='location'><xsl:text>Plek</xsl:text></localization>
    <localization string-id='page'><xsl:text>Bladsy</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Voortgesit op volgende bladsy</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <!-- Assistive "skip to content" link -->
    <localization string-id='skip-to-content'><xsl:text>Slaan oor na hoofinhoud</xsl:text></localization>
    <localization string-id='previous'><xsl:text>Vorige</xsl:text></localization>
    <localization string-id='up'><xsl:text>Op</xsl:text></localization>
    <localization string-id='next'><xsl:text>Volgende</xsl:text></localization>
    <!-- Keep these short, so buttons are not overly wide, 4 characters maximum -->
    <localization string-id='previous-short'><xsl:text>Vorig</xsl:text></localization>
    <localization string-id='up-short'><xsl:text>Op</xsl:text></localization>
    <localization string-id='next-short'><xsl:text>Volg</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Aantekeninge</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Terugvoer</xsl:text></localization>
    <!-- This phrase should suggest that PreTeXt is the source -->
    <!-- language that makes a particular output possible      -->
    <localization string-id='authored'><xsl:text>Geskryf in</xsl:text></localization>
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>Aan</xsl:text></localization>
    <localization string-id='from'><xsl:text>Van</xsl:text></localization>
    <localization string-id='subject'><xsl:text>Onderwerp</xsl:text></localization>
    <localization string-id='date'><xsl:text>Datum</xsl:text></localization>
    <localization string-id='copy'><xsl:text>cc</xsl:text></localization>
    <localization string-id='enclosure'><xsl:text>bylae</xsl:text></localization>
    <!-- Various -->
    <localization string-id='todo'><xsl:text>Om Te Doen</xsl:text></localization>
    <localization string-id='editor'><xsl:text>Redakteur</xsl:text></localization>
    <localization string-id='edition'><xsl:text>Uitgawe</xsl:text></localization>
    <localization string-id='website'><xsl:text>Webtuiste</xsl:text></localization>
    <localization string-id='copyright'><xsl:text>Kopiereg</xsl:text></localization>
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>perma-skakel</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>in-konteks</xsl:text></localization>
    <!-- Sage Cell evaluate button      -->
    <!-- eg, "Evaluate (Maxima)"        -->
    <!-- 2017-05-14: 'code' is obsolete -->
    <!-- This needs to be defined to *something* (always)       -->
    <!-- else whatever crud ends up on the button kills the cell -->
    <localization string-id='evaluate'><xsl:text>Evalueer</xsl:text></localization>
    <localization string-id='evaluate'><xsl:text>Evalueer</xsl:text></localization>
    <!-- <localization string-id='code'><xsl:text>Kode</xsl:text></localization> -->
</xsl:variable>

</xsl:stylesheet>
