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

<!-- it-IT, Italian (Italy) -->
<!-- Valerio Monti, gedeonedepaperoni@gmail.com, 2020-07-27   -->

<xsl:variable name="it-IT">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id='theorem'><xsl:text>Teorema</xsl:text></localization>
    <localization string-id='corollary'><xsl:text>Corollario</xsl:text></localization>
    <localization string-id='lemma'><xsl:text>Lemma</xsl:text></localization>
    <localization string-id='algorithm'><xsl:text>Algoritmo</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Proposizione</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Affermazione</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Fatto</xsl:text></localization>
    <localization string-id='identity'><xsl:text>Identità</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Dimostrazione</xsl:text></localization>
    <localization string-id='case'><xsl:text>Caso</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Assioma</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Congettura</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Principio</xsl:text></localization>
    <localization string-id='heuristic'><xsl:text>Processo euristico</xsl:text></localization>
    <localization string-id='hypothesis'><xsl:text>Ipotesi</xsl:text></localization>
    <localization string-id='assumption'><xsl:text>Assunzione</xsl:text></localization>
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Definizione</xsl:text></localization>
    <!-- Single Line Mathematics -->
    <localization string-id='me'><xsl:text>Equazione</xsl:text></localization>
    <localization string-id='men'><xsl:text>Equazione</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Equazione</xsl:text></localization>
    <!-- Display Mathematics -->
    <localization string-id='md'><xsl:text>Matematica in display</xsl:text></localization>
    <localization string-id='mdn'><xsl:text>Matematica in display</xsl:text></localization>
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Volume</xsl:text></localization>
    <localization string-id='book'><xsl:text>libro</xsl:text></localization>
    <localization string-id='article'><xsl:text>Articolo</xsl:text></localization>
    <!-- <localization string-id='slideshow'><xsl:text>Slideshow</xsl:text></localization> -->
    <localization string-id='letter'><xsl:text>Lettera</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Memo</xsl:text></localization>
    <localization string-id='presentation'><xsl:text>Presentazione</xsl:text></localization>
    <!-- Parts of a document -->
    <!-- "part" will also be used for a "stage" of a WeBWorK problem -->
    <localization string-id='frontmatter'><xsl:text>Materiale iniziale</xsl:text></localization>
    <localization string-id='part'><xsl:text>Parte</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Capitolo</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Appendice</xsl:text></localization>
    <localization string-id='section'><xsl:text>Paragrafo</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Sottoparagrafo</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>Sotto-sottoparagrafo</xsl:text></localization>
    <!-- A "slide" is a screenful of a presentation (Powerpoint, Beamer) -->
    <!-- <localization string-id='slide'><xsl:text>Slide</xsl:text></localization> -->
    <localization string-id='introduction'><xsl:text>Introduzione</xsl:text></localization>
    <localization string-id='conclusion'><xsl:text>Conclusione</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Esercizi</xsl:text></localization>
    <localization string-id='worksheet'><xsl:text>Scheda didattica</xsl:text></localization>
    <localization string-id='reading-questions'><xsl:text>Domande di comprensione del testo</xsl:text></localization>
    <localization string-id='solutions'><xsl:text>Soluzioni</xsl:text></localization>
    <localization string-id='glossary'><xsl:text>Glossario</xsl:text></localization>
    <localization string-id='references'><xsl:text>Bibliografia</xsl:text></localization>
    <localization string-id='backmatter'><xsl:text>Materiale finale</xsl:text></localization>
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Capoversi</xsl:text></localization>
    <localization string-id='commentary'><xsl:text>Commento</xsl:text></localization>
    <localization string-id='subparagraph'><xsl:text>Sottocapoverso</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Osservazione</xsl:text></localization>
    <localization string-id='convention'><xsl:text>Convenzione</xsl:text></localization>
    <localization string-id='note'><xsl:text>Nota</xsl:text></localization>
    <!-- <localization string-id='observation'><xsl:text>Observation</xsl:text></localization>  -->
    <localization string-id='warning'><xsl:text>Attenzione</xsl:text></localization>
    <localization string-id='insight'><xsl:text>Intuizione</xsl:text></localization>
    <localization string-id='computation'><xsl:text>Computazione</xsl:text></localization>
    <localization string-id='technology'><xsl:text>Tecnologia</xsl:text></localization>
    <!-- ASIDE-LIKE blocks -->
    <localization string-id='aside'><xsl:text>Inciso</xsl:text></localization>
    <localization string-id='biographical'><xsl:text>Inciso biografico</xsl:text></localization>
    <localization string-id='historical'><xsl:text>Inciso storico</xsl:text></localization>
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Esempio</xsl:text></localization>
    <localization string-id='question'><xsl:text>Domanda</xsl:text></localization>
    <localization string-id='problem'><xsl:text>Problema</xsl:text></localization>
    <!-- PROJECT-LIKE blocks -->
    <localization string-id='project'><xsl:text>Progetto</xsl:text></localization>
    <localization string-id='activity'><xsl:text>Attività</xsl:text></localization>
    <localization string-id='exploration'><xsl:text>Esplorazione</xsl:text></localization>
    <localization string-id='task'><xsl:text>Compito</xsl:text></localization>
    <localization string-id='investigation'><xsl:text>Investigazione</xsl:text></localization>
    <!-- assemblages are collections of minimally structured material -->
    <localization string-id='assemblage'><xsl:text>Raccolta</xsl:text></localization>
    <localization string-id='poem'><xsl:text>Poema</xsl:text></localization>
    <!-- Objectives is the block, objective is a list item within -->
    <localization string-id='objectives'><xsl:text>Obiettivi</xsl:text></localization>
    <localization string-id='objective'><xsl:text>Obiettivo</xsl:text></localization>
    <!-- Outcomes is the block, outcome is a list item within (different) -->
    <!-- These two words need to be different, to avoid ambiguous cross-references -->
    <localization string-id='outcomes'><xsl:text>Risultati</xsl:text></localization>
    <localization string-id='outcome'><xsl:text>Risultato</xsl:text></localization>
    <!--  -->
    <localization string-id='figure'><xsl:text>Figura</xsl:text></localization>
    <localization string-id='table'><xsl:text>Tabella</xsl:text></localization>
    <localization string-id='listing'><xsl:text>Listato</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Nota a piè di pagina</xsl:text></localization>
    <localization string-id='contributor'><xsl:text>Contributore</xsl:text></localization>
    <!-- Lists and their items -->
    <localization string-id='list'><xsl:text>Elenco</xsl:text></localization>
    <localization string-id='li'><xsl:text>Punto</xsl:text></localization>
    <!-- A term (word) defined in a glossary -->
    <localization string-id='defined-term'><xsl:text>Termine</xsl:text></localization>
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Capoverso</xsl:text></localization>
    <localization string-id='blockquote'><xsl:text>Citazione</xsl:text></localization>
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
    <!-- the term is a location on a roadway where you must stop for the      -->
    <!-- police to do an inspection. A worksheet is a collection of activities or  -->
    <!-- problems, typically printed on paper, which might be used in a classroom. -->
    <localization string-id='divisionalexercise'><xsl:text>Esercizio</xsl:text></localization>
    <localization string-id='inlineexercise'><xsl:text>Punto di controllo</xsl:text></localization>
    <localization string-id='worksheetexercise'><xsl:text>Esercizio in scheda didattica</xsl:text></localization>
    <localization string-id='readingquestion'><xsl:text>Domanda di comprensione del testo</xsl:text></localization>
    <localization string-id='webwork'><xsl:text>WeBWorK</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Suggerimento</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Risposta</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Soluzione</xsl:text></localization>
    <!-- A group of divisional exercises (with introduction and conclusion) -->
    <localization string-id='exercisegroup'><xsl:text>Gruppo di esercizi</xsl:text></localization>
    <!-- Bibliographic items (note is distinct from sidebar "Annotations" below) -->
    <localization string-id='biblio'><xsl:text>Riferimento bibliografico</xsl:text></localization>
    <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Indice</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Sommario</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Prefazione</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Ringraziamenti</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Biografia dell'autore</xsl:text></localization>
    <!-- singular and plural titles for biography subdivision -->
    <localization string-id='about-author'><xsl:text>Sull'autore</xsl:text></localization>
    <localization string-id='about-authors'><xsl:text>Sugli autori</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Presentazione</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Dedica</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Colophon</xsl:text></localization>
    <!-- Back matter components -->
    <!-- index-part is deprecated, but not abandoned          -->
    <!-- NB: repurpose translations, maybe move appendix here -->
    <localization string-id='index-part'><xsl:text>Indice analitico</xsl:text></localization>
    <localization string-id='jump-to'><xsl:text>Vai a:</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='index'><xsl:text>Indice analitico</xsl:text></localization>
    <localization string-id='see'><xsl:text>Vedi</xsl:text></localization>
    <localization string-id='also'><xsl:text>Vedi anche</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>Simbolo</xsl:text></localization>
    <localization string-id='description'><xsl:text>Descrizione</xsl:text></localization>
    <localization string-id='location'><xsl:text>Posizione</xsl:text></localization>
    <localization string-id='page'><xsl:text>Pag.</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Continua alla pagina successiva</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <!-- Assistive "skip to content" link -->
    <localization string-id='skip-to-content'><xsl:text>Vai all'indice generale</xsl:text></localization>
    <localization string-id='previous'><xsl:text>Precedente</xsl:text></localization>
    <localization string-id='up'><xsl:text>Su</xsl:text></localization>
    <localization string-id='next'><xsl:text>Successivo</xsl:text></localization>
    <!-- Keep these short, so buttons are not overly wide, 4 characters maximum -->
    <localization string-id='previous-short'><xsl:text>Prec</xsl:text></localization>
    <localization string-id='up-short'><xsl:text>Su</xsl:text></localization>
    <localization string-id='next-short'><xsl:text>Succ</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Annotazioni</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Feedback</xsl:text></localization>
    <!-- This phrase should suggest that PreTeXt is the source -->
    <!-- language that makes a particular output possible      -->
    <localization string-id='authored'><xsl:text>Redatto in PreTeXt</xsl:text></localization>
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>Per</xsl:text></localization>
    <localization string-id='from'><xsl:text>Da</xsl:text></localization>
    <localization string-id='subject'><xsl:text>Oggetto</xsl:text></localization>
    <localization string-id='date'><xsl:text>Data</xsl:text></localization>
    <localization string-id='copy'><xsl:text>e p.c.</xsl:text></localization>
    <localization string-id='enclosure'><xsl:text>allegati</xsl:text></localization>
    <!-- Various -->
    <localization string-id='todo'><xsl:text>Da fare</xsl:text></localization>
    <localization string-id='editor'><xsl:text>Curatore</xsl:text></localization>
    <localization string-id='edition'><xsl:text>Edizione</xsl:text></localization>
    <localization string-id='website'><xsl:text>Sito web</xsl:text></localization>
    <localization string-id='copyright'><xsl:text>Copyright</xsl:text></localization>
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>permalink</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>Contesto</xsl:text></localization>
    <!-- Sage Cell evaluate button      -->
    <!-- eg, "Evaluate (Maxima)"        -->
    <!-- 2017-05-14: 'code' is obsfolete -->
    <!-- This needs to be defined to *something* (always)       -->
    <!-- else whatever crud ends up on the button kills the cell -->
    <localization string-id='evaluate'><xsl:text>Calcola</xsl:text></localization>
    <!-- <localization string-id='code'><xsl:text>Code</xsl:text></localization> -->
</xsl:variable>

</xsl:stylesheet>
