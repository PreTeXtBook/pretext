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

<!-- cs-CZ, Czech (Czechia) -->
<!-- Jiri Lebl, lebl@okstate.edu, 2018-10-13   -->

<xsl:variable name="cs-CZ">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id='theorem'><xsl:text>Teorém</xsl:text></localization>
    <localization string-id='corollary'><xsl:text>Důsledek</xsl:text></localization>
    <localization string-id='lemma'><xsl:text>Lemma</xsl:text></localization>
    <localization string-id='algorithm'><xsl:text>Algoritmus</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Věta</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Tvrzení</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Fakt</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Důkaz</xsl:text></localization>
    <localization string-id='identity'><xsl:text>Rovnost</xsl:text></localization>
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Axiom</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Domněnka</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Princip</xsl:text></localization>
    <localization string-id='heuristic'><xsl:text>Heurestika</xsl:text></localization>
    <localization string-id='hypothesis'><xsl:text>Hypotéza</xsl:text></localization>
    <localization string-id='assumption'><xsl:text>Předpoklad</xsl:text></localization>
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Definice</xsl:text></localization>
    <!-- Single Line Mathematics -->
    <localization string-id='me'><xsl:text>Rovnice</xsl:text></localization>
    <localization string-id='men'><xsl:text>Rovnice</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Rovnice</xsl:text></localization>
    <!-- Display Mathematics -->
    <localization string-id='md'><xsl:text>Zobrazená matematika</xsl:text></localization>
    <localization string-id='mdn'><xsl:text>Zobrazená matematika</xsl:text></localization>
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Díl</xsl:text></localization>
    <localization string-id='book'><xsl:text>Kniha</xsl:text></localization>
    <localization string-id='article'><xsl:text>Článek</xsl:text></localization>
    <localization string-id='letter'><xsl:text>Dopis</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Sdělení</xsl:text></localization>
    <localization string-id='presentation'><xsl:text>Prezentace</xsl:text></localization>
    <!-- Parts of a document -->
    <localization string-id='frontmatter'><xsl:text>Úvodní část</xsl:text></localization>
    <localization string-id='part'><xsl:text>Část</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Kapitola</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Appendix</xsl:text></localization>
    <localization string-id='section'><xsl:text>Sekce</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Podsekce</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>Podpodsekce</xsl:text></localization>
    <localization string-id='introduction'><xsl:text>Úvod</xsl:text></localization>
    <localization string-id='conclusion'><xsl:text>Závěr</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Cvičení</xsl:text></localization>
    <localization string-id='worksheet'><xsl:text>Pracovní list</xsl:text></localization>
    <localization string-id='reading-questions'><xsl:text>Otázky ze čtení</xsl:text></localization>
    <localization string-id='solutions'><xsl:text>Řešení</xsl:text></localization>
    <localization string-id='glossary'><xsl:text>Vysvětlivky</xsl:text></localization>
    <localization string-id='references'><xsl:text>Odkazy</xsl:text></localization>
    <localization string-id='backmatter'><xsl:text>Závěrečná část</xsl:text></localization>
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Odstavce</xsl:text></localization>
    <localization string-id='commentary'><xsl:text>Komentář</xsl:text></localization>
    <localization string-id='subparagraph'><xsl:text>Pododstavec</xsl:text></localization>
    <localization string-id='case'><xsl:text>Případ</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Poznámka</xsl:text></localization>
    <localization string-id='convention'><xsl:text>Konvence</xsl:text></localization>
    <localization string-id='note'><xsl:text>Poznámka</xsl:text></localization>
    <localization string-id='observation'><xsl:text>Postřeh</xsl:text></localization>
    <localization string-id='warning'><xsl:text>Varování</xsl:text></localization>
    <localization string-id='insight'><xsl:text>Nahléd</xsl:text></localization>
    <localization string-id='computation'><xsl:text>Výpočet</xsl:text></localization>
    <localization string-id='technology'><xsl:text>Technologie</xsl:text></localization>
    <!-- ASIDE-LIKE blocks -->
    <localization string-id='aside'><xsl:text>Poznámka stranou</xsl:text></localization>
    <localization string-id='biographical'><xsl:text>Biografická poznámka</xsl:text></localization>
    <localization string-id='historical'><xsl:text>Historická poznámka</xsl:text></localization>
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Příklad</xsl:text></localization>
    <localization string-id='question'><xsl:text>Otázka</xsl:text></localization>
    <localization string-id='problem'><xsl:text>Problém</xsl:text></localization>
    <!-- PROJECT-LIKE blocks -->
    <localization string-id='project'><xsl:text>Projekt</xsl:text></localization>
    <localization string-id='activity'><xsl:text>Aktivita</xsl:text></localization>
    <localization string-id='exploration'><xsl:text>Průzkum</xsl:text></localization>
    <localization string-id='task'><xsl:text>Úkol</xsl:text></localization>
    <localization string-id='investigation'><xsl:text>Výzkum</xsl:text></localization>
    <!--  -->
    <!-- assemblages are collections of minimally structured material -->
    <localization string-id='assemblage'><xsl:text>Soustava</xsl:text></localization>
    <localization string-id='poem'><xsl:text>Báseň</xsl:text></localization>
    <!-- Objectives is the block, objective is a list item within -->
    <localization string-id='objectives'><xsl:text>Cíle</xsl:text></localization>
    <localization string-id='objective'><xsl:text>Cíl</xsl:text></localization>
    <!-- Outcomes is the block, outcome is a list item within (different) -->
    <localization string-id='outcomes'><xsl:text>Výsledky</xsl:text></localization>
    <localization string-id='outcome'><xsl:text>Výsledek</xsl:text></localization>
    <!--  -->
    <localization string-id='figure'><xsl:text>Obrázek</xsl:text></localization>
    <localization string-id='table'><xsl:text>Tabulka</xsl:text></localization>
    <localization string-id='listing'><xsl:text>Výpis</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Vysvětlivka</xsl:text></localization>
    <localization string-id='contributor'><xsl:text>Přispěvatel</xsl:text></localization>
    <!-- Lists and their items -->
    <localization string-id='list'><xsl:text>Seznam</xsl:text></localization>
    <localization string-id='li'><xsl:text>Bod</xsl:text></localization>
    <!-- A term (word) defined in a glossary -->
    <localization string-id='defined-term'><xsl:text>Termín</xsl:text></localization>
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Odstavec</xsl:text></localization>
    <localization string-id='blockquote'><xsl:text>Citát</xsl:text></localization>
    <!-- Parts of an exercise and it's solution -->
    <localization string-id='divisionalexercise'><xsl:text>Cvičení</xsl:text></localization>
    <!-- Translation needed for Czech Czech -->
    <!-- See en-US file for distinctions here, do not repeat previous translation -->
    <localization string-id='inlineexercise'><xsl:text>Zkouška</xsl:text></localization>
    <localization string-id='worksheetexercise'><xsl:text>Cvičení pracovního listu</xsl:text></localization>
    <localization string-id='readingquestion'><xsl:text>Otázka ze čtení</xsl:text></localization>
    <localization string-id='webwork'><xsl:text>WeBWorK</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Nápověda</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Odpověď</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Řešení</xsl:text></localization>
    <!-- A group of divisional exercises (with introduction and conclusion) -->
    <localization string-id='exercisegroup'><xsl:text>Skupina cvičení</xsl:text></localization>
    <!-- Bibliographic items (note is distinct from sidebar "Annotations" below) -->
    <localization string-id='biblio'><xsl:text>Bibliografický údaj</xsl:text></localization>
    <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Obsah</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Abstrakt</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Předmluva</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Poděkování</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Životopis autora</xsl:text></localization>
    <!-- singular and plural titles for biography subdivision -->
    <localization string-id='about-author'><xsl:text>O autoru</xsl:text></localization>
    <localization string-id='about-authors'><xsl:text>O autorech</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Předmluva</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Věnování</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Kolofon</xsl:text></localization>
    <!-- Back matter components -->
    <!-- index-part is deprecated, but not abandoned          -->
    <!-- NB: repurpose translations, maybe move appendix here -->
    <localization string-id='index-part'><xsl:text>Rejstřík</xsl:text></localization>
    <localization string-id='jump-to'><xsl:text>Skoč na:</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='index'><xsl:text>Rejstřík</xsl:text></localization>
    <localization string-id='see'><xsl:text>Viz</xsl:text></localization>
    <localization string-id='also'><xsl:text>Viz také</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>Symbol</xsl:text></localization>
    <localization string-id='description'><xsl:text>Popis</xsl:text></localization>
    <localization string-id='location'><xsl:text>Pozice</xsl:text></localization>
    <localization string-id='page'><xsl:text>Stránka</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Pokračuje na další straně</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <!-- Assistive "skip to content" link -->
    <localization string-id='skip-to-content'><xsl:text>Přeskočit na hlavní obsah</xsl:text></localization>
    <localization string-id='previous'><xsl:text>Předchozí</xsl:text></localization>
    <localization string-id='up'><xsl:text>Nahoru</xsl:text></localization>
    <localization string-id='next'><xsl:text>Další</xsl:text></localization>
    <!-- Keep these short, so buttons are not overly wide, 4 characters maximum -->
    <localization string-id='previous-short'><xsl:text>Zpět</xsl:text></localization>
    <localization string-id='up-short'><xsl:text>Výš</xsl:text></localization>
    <localization string-id='next-short'><xsl:text>Dál</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Anotace</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Odezva</xsl:text></localization>
    <localization string-id='authored'><xsl:text>Napsáno v</xsl:text></localization>
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>Komu</xsl:text></localization>
    <localization string-id='from'><xsl:text>Od</xsl:text></localization>
    <localization string-id='subject'><xsl:text>Předmět</xsl:text></localization>
    <localization string-id='date'><xsl:text>Datum</xsl:text></localization>
    <localization string-id='copy'><xsl:text>Kopie</xsl:text></localization>
    <localization string-id='enclosure'><xsl:text>Příloha</xsl:text></localization>
    <!-- Various -->
    <localization string-id='todo'><xsl:text>To Do</xsl:text></localization>
    <localization string-id='editor'><xsl:text>Editor</xsl:text></localization>
    <localization string-id='edition'><xsl:text>Edice</xsl:text></localization>
    <localization string-id='website'><xsl:text>Webová stránka</xsl:text></localization>
    <localization string-id='copyright'><xsl:text>Copyright</xsl:text></localization>
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>permalink</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>v-souvislosti</xsl:text></localization>
    <!-- Sage Cell evaluate button      -->
    <!-- eg, "Evaluate (Maxima)"        -->
    <!-- 2017-05-14: 'code' is obsolete -->
    <!-- This needs to be defined to *something* (English)       -->
    <!-- else whatever crud ends up on the button kills the cell -->
    <!-- Translate at first opportunity, please                  -->
    <localization string-id='evaluate'><xsl:text>Ohodnotit</xsl:text></localization>
    <localization string-id='code'><xsl:text>Kód</xsl:text></localization>
</xsl:variable>

</xsl:stylesheet>
