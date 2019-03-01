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

<!-- hu-HU, Hungarian (Hungary) -->
<!-- Sándor Czirbusz, czirbusz@gmail.com, 2017-04-09 -->

<xsl:variable name="hu-HU">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id='theorem'><xsl:text>Tétel</xsl:text></localization>
    <localization string-id='corollary'><xsl:text>Következmény</xsl:text></localization>
    <localization string-id='lemma'><xsl:text>Lemma</xsl:text></localization>
    <localization string-id='algorithm'><xsl:text>Algoritmus</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Állítás</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Állítás</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Tény</xsl:text></localization>
    <localization string-id='identity'><xsl:text>Azonosság</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Bizonyítás</xsl:text></localization>
    <localization string-id='case'><xsl:text>Eset</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Axióma</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Sejtés</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Elv</xsl:text></localization>
    <localization string-id='heuristic'><xsl:text>Heurisztikus</xsl:text></localization>
    <localization string-id='hypothesis'><xsl:text>Hipotézis</xsl:text></localization>
    <localization string-id='assumption'><xsl:text>Feltevés</xsl:text></localization>
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Definíció</xsl:text></localization>
    <!-- Single Line Mathematics -->
    <localization string-id='me'><xsl:text>Egyenlet</xsl:text></localization>
    <localization string-id='men'><xsl:text>Egyenlet</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Egyenlet</xsl:text></localization>
    <!-- Display Mathematics -->
    <localization string-id='md'><xsl:text>Matematikai megjelenítés</xsl:text></localization>
    <localization string-id='mdn'><xsl:text>Matematikai megjelenítés</xsl:text></localization>
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Kötet</xsl:text></localization>
    <localization string-id='book'><xsl:text>Könyv</xsl:text></localization>
    <localization string-id='article'><xsl:text>Cikk</xsl:text></localization>
    <localization string-id='letter'><xsl:text>Letter</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Emlékeztető</xsl:text></localization>
    <localization string-id='presentation'><xsl:text>Prezentáció</xsl:text></localization>
    <!-- Parts of a document -->
    <localization string-id='frontmatter'><xsl:text>Bevezető rész</xsl:text></localization>
    <localization string-id='part'><xsl:text>Rész</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Fejezet</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Függelék</xsl:text></localization>
    <localization string-id='section'><xsl:text>Pont</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Alpont</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>alpont</xsl:text></localization>
    <localization string-id='introduction'><xsl:text>Bevezetés</xsl:text></localization>
    <localization string-id='conclusion'><xsl:text>Következtetés</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Feladatok</xsl:text></localization>
    <!-- <localization string-id='worksheet'><xsl:text>Worksheet</xsl:text></localization> -->
    <!-- <localization string-id='reading-questions'><xsl:text>Reading Questions</xsl:text></localization> -->
    <!-- <localization string-id='solutions'><xsl:text>Solutions</xsl:text></localization> -->
    <!-- <localization string-id='glossary'><xsl:text>Glossary</xsl:text></localization> -->
    <localization string-id='references'><xsl:text>Hivatkozások</xsl:text></localization>
    <localization string-id='backmatter'><xsl:text>Záró rész</xsl:text></localization>
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Paragrafusok</xsl:text></localization>
    <!-- <localization string-id='commentary'><xsl:text>Commentary</xsl:text></localization> -->
    <localization string-id='subparagraph'><xsl:text>Al-paragrafus</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Megjegyzés</xsl:text></localization>
    <localization string-id='convention'><xsl:text>Konvenció</xsl:text></localization>
    <localization string-id='note'><xsl:text>Megjegyzés</xsl:text></localization>
    <localization string-id='observation'><xsl:text>Megfigyelés</xsl:text></localization>
    <localization string-id='warning'><xsl:text>Figyelmeztetés</xsl:text></localization>
    <localization string-id='insight'><xsl:text>Bepillantás</xsl:text></localization>
    <localization string-id='computation'><xsl:text>Számítás</xsl:text></localization>
    <localization string-id='technology'><xsl:text>Technológia</xsl:text></localization>
    <!-- ASIDE-LIKE blocks -->
    <localization string-id='aside'><xsl:text>Kiegészítés</xsl:text></localization>
    <localization string-id='biographical'><xsl:text>Életrajzi kiegészítés</xsl:text></localization>
    <localization string-id='historical'><xsl:text>Történeti kiegészítés</xsl:text></localization>
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Példa</xsl:text></localization>
    <localization string-id='question'><xsl:text>Kérdéa</xsl:text></localization>
    <localization string-id='problem'><xsl:text>Probléma</xsl:text></localization>
    <!-- PROJECT-LIKE blocks -->
    <localization string-id='project'><xsl:text>Projekt</xsl:text></localization>
    <localization string-id='activity'><xsl:text>Aktivitás</xsl:text></localization>
    <localization string-id='exploration'><xsl:text>Kutatás</xsl:text></localization>
    <localization string-id='task'><xsl:text>Feladat</xsl:text></localization>
    <localization string-id='investigation'><xsl:text>Vizsgálat</xsl:text></localization>
    <!-- assemblages are collections of minimally structured material -->
    <localization string-id='assemblage'><xsl:text>Összeállítás</xsl:text></localization>
    <localization string-id='poem'><xsl:text>Vers</xsl:text></localization>
    <!-- Objectives is the block, objective is a list item within -->
    <localization string-id='objectives'><xsl:text>Célkitűzések</xsl:text></localization>
    <localization string-id='objective'><xsl:text>Célkitűzés</xsl:text></localization>
    <!-- Outcomes is the block, outcome is a list item within (different) -->
    <!-- <localization string-id='outcomes'><xsl:text>Outcomes</xsl:text></localization> -->
    <!-- <localization string-id='outcome'><xsl:text>Outcome</xsl:text></localization> -->
    <!--  -->
    <localization string-id='figure'><xsl:text>Ábra</xsl:text></localization>
    <localization string-id='table'><xsl:text>Táblázat</xsl:text></localization>
    <localization string-id='listing'><xsl:text>Felsorolás</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Lábjegyzet</xsl:text></localization>
    <localization string-id='contributor'><xsl:text>Résztvevő</xsl:text></localization>
    <!-- Lists and their items -->
    <localization string-id='list'><xsl:text>Lista</xsl:text></localization>
    <localization string-id='li'><xsl:text>Tétel</xsl:text></localization>
    <!-- A term (word) defined in a glossary -->
    <!-- <localization string-id='defined-term'><xsl:text>Term</xsl:text></localization> -->
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Paragrafus</xsl:text></localization>
    <localization string-id='blockquote'><xsl:text>Idézet</xsl:text></localization>
    <!-- Parts of an exercise and it's solution -->
    <localization string-id='divisionalexercise'><xsl:text>Feladat</xsl:text></localization>
    <!-- Translation needed for Hungary Hungarian -->
    <!-- See en-US file for distinctions here, do not repeat previous translation -->
    <!-- <localization string-id='inlineexercise'><xsl:text>Checkpoint</xsl:text></localization> -->
    <!-- <localization string-id='worksheetexercise'><xsl:text>Worksheet Exercise</xsl:text></localization> -->
    <!-- <localization string-id='readingquestion'><xsl:text>Reading Question</xsl:text></localization> -->
    <localization string-id='webwork'><xsl:text>WeBWorK</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Tipp</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Vélasz</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Megoldás</xsl:text></localization>
    <!-- A group of divisional exercises (with introduction and conclusion) -->
    <localization string-id='exercisegroup'><xsl:text>Feladatcsoport</xsl:text></localization>
    <!-- Bibliographic items (note is distinct from sidebar "Annotations" below) -->
    <localization string-id='biblio'><xsl:text>Életrajzi bejegyzés</xsl:text></localization>
    <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Tartalom</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Absztrakt</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Előszó</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Köszönetnyilvánítás</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Szerzői életrajz</xsl:text></localization>
    <!-- singular and plural titles for biography subdivision -->
    <localization string-id='about-author'><xsl:text>A szerzőről</xsl:text></localization>
    <localization string-id='about-authors'><xsl:text>A szerzőkről</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Előszó</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Ajánlás</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Záradék</xsl:text></localization>
    <!-- Back matter components -->
    <!-- index-part is deprecated, but not abandoned          -->
    <!-- NB: repurpose translations, maybe move appendix here -->
    <localization string-id='index-part'><xsl:text>Index</xsl:text></localization>
    <localization string-id='jump-to'><xsl:text>Ugrás ide:</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='index'><xsl:text>Index</xsl:text></localization>
    <localization string-id='see'><xsl:text>Lásd</xsl:text></localization>
    <localization string-id='also'><xsl:text>Lásd még</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>szimbólum</xsl:text></localization>
    <localization string-id='description'><xsl:text>Leírás</xsl:text></localization>
    <localization string-id='location'><xsl:text>Hely</xsl:text></localization>
    <localization string-id='page'><xsl:text>Lap</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Folytatás a következő lapon</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <!-- Assistive "skip to content" link -->
    <localization string-id='skip-to-content'><xsl:text>Ugrás a fő tartalomjegyzékre</xsl:text></localization>
    <localization string-id='previous'><xsl:text>Előző</xsl:text></localization>
    <localization string-id='up'><xsl:text>Fel</xsl:text></localization>
    <localization string-id='next'><xsl:text>Következő</xsl:text></localization>
    <!-- Keep these short, so buttons are not overly wide, 4 characters maximum -->
    <localization string-id='previous-short'><xsl:text>El.</xsl:text></localization>
    <localization string-id='up-short'><xsl:text>Fel</xsl:text></localization>
    <localization string-id='next-short'><xsl:text>Köv.</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Magyarázatok</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Visszacsatolás</xsl:text></localization>
    <localization string-id='authored'><xsl:text>Authored in</xsl:text></localization>
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>Kinek:</xsl:text></localization>
    <localization string-id='from'><xsl:text>Kitől:</xsl:text></localization>
    <localization string-id='subject'><xsl:text>Tárgy</xsl:text></localization>
    <localization string-id='date'><xsl:text>Dátum</xsl:text></localization>
    <localization string-id='copy'><xsl:text>cc</xsl:text></localization>
    <localization string-id='enclosure'><xsl:text>beleértve</xsl:text></localization>
    <!-- Various -->
    <localization string-id='todo'><xsl:text>Tennivaló</xsl:text></localization>
    <localization string-id='editor'><xsl:text>Szerkesztő</xsl:text></localization>
    <localization string-id='edition'><xsl:text>Kiadás</xsl:text></localization>
    <localization string-id='website'><xsl:text>Weboldal</xsl:text></localization>
    <localization string-id='copyright'><xsl:text>Szerzői jog</xsl:text></localization>
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>permalink</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>szövegkörnyezet</xsl:text></localization>
    <!-- Sage Cell evaluate button      -->
    <!-- eg, "Evaluate (Maxima)"        -->
    <!-- 2017-05-14: 'code' is obsolete -->
    <!-- This needs to be defined to *something* (English)       -->
    <!-- else whatever crud ends up on the button kills the cell -->
    <!-- Translate at first opportunity, please                  -->
    <localization string-id='evaluate'><xsl:text>Evaluate</xsl:text></localization>
    <!-- <localization string-id='code'><xsl:text>Kód</xsl:text></localization> -->
</xsl:variable>

</xsl:stylesheet>
