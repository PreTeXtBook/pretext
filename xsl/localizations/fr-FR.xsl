<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!--********************************************************************
Copyright 2016 Robert A. Beezer

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

<!-- fr-FR, French (France) -->
<!-- Thomas W. Judson, judsontw@sfasu.edu, 2016-03-23 -->

<xsl:variable name="fr-FR">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id="theorem">Théorème</localization>
    <localization string-id="corollary">Corollaire</localization>
    <localization string-id="lemma">Lemme</localization>
    <!-- <localization string-id='algorithm'><xsl:text>XX</xsl:text></localization> -->
    <localization string-id='proposition'><xsl:text>Proposition</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Affirmation</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Fait</xsl:text></localization>
    <!-- <localization string-id='identity'><xsl:text>Identity</xsl:text></localization> -->
    <localization string-id='proof'><xsl:text>Démonstration</xsl:text></localization>
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Axiome</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Conjecture</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Principe</xsl:text></localization>
    <!-- <localization string-id='heuristic'><xsl:text>Heuristic</xsl:text></localization> -->
    <!-- <localization string-id='hypothesis'><xsl:text>Hypothesis</xsl:text></localization> -->
    <!-- <localization string-id='assumption'><xsl:text>Assumption</xsl:text></localization> -->
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Définition</xsl:text></localization>
    <!-- Equations, when referenced by number -->
    <!-- <localization string-id='men'><xsl:text>Equation</xsl:text></localization> -->
    <!-- <localization string-id='mrow'><xsl:text>Equation</xsl:text></localization> -->
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Volume</xsl:text></localization>
    <localization string-id='book'><xsl:text>Livre</xsl:text></localization>
    <localization string-id='article'><xsl:text>Article</xsl:text></localization>
    <localization string-id='letter'><xsl:text>Lettre</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Mémo</xsl:text></localization>
    <localization string-id='presentation'><xsl:text>Présentation</xsl:text></localization>
    <!-- Parts of a document -->
    <localization string-id='frontmatter'><xsl:text>Pages Liminaires</xsl:text></localization>
    <localization string-id='part'><xsl:text>Partie</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Chapitre</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Appendice</xsl:text></localization>
    <localization string-id='section'><xsl:text>Section</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Sous-section</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>Sous-sous-section</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Exercices</xsl:text></localization>
    <localization string-id='references'><xsl:text>Références</xsl:text></localization>
    <!-- <localization string-id='backmatter'><xsl:text>Back Matter</xsl:text></localization> -->
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Paragraphes</xsl:text></localization>  <!--checked-->
    <localization string-id='paragraph'><xsl:text>Paragraphe</xsl:text></localization> <!--checked-->
    <localization string-id='subparagraph'><xsl:text>Sous-paragraphe</xsl:text></localization> <!--checked-->
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Remarque</xsl:text></localization>
    <!-- <localization string-id='convention'><xsl:text>Convention</xsl:text></localization> -->
    <!-- <localization string-id='note'><xsl:text>Note</xsl:text></localization> -->
    <!-- <localization string-id='observation'><xsl:text>Observation</xsl:text></localization> -->
    <!-- <localization string-id='warning'><xsl:text>Warning</xsl:text></localization> -->
    <!-- <localization string-id='insight'><xsl:text>Insight</xsl:text></localization> -->
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Exemple</xsl:text></localization> <!--checked-->
    <!-- <localization string-id='question'><xsl:text>Question</xsl:text></localization> -->
    <!-- <localization string-id='problem'><xsl:text>Problem</xsl:text></localization> -->
    <!-- PROJECT-LIKE blocks -->
    <!-- <localization string-id='project'><xsl:text>Project</xsl:text></localization> -->
    <!-- <localization string-id='activity'><xsl:text>Activity</xsl:text></localization> -->
    <!-- <localization string-id='exploration'><xsl:text>Exploration</xsl:text></localization> -->
    <!-- <localization string-id='task'><xsl:text>Task</xsl:text></localization> -->
    <!-- <localization string-id='investigation'><xsl:text>Investigation</xsl:text></localization> -->
    <!--  -->
    <!-- assemblages are collections of minimally structured material -->
    <!-- <localization string-id='assemblage'><xsl:text>Assemblage</xsl:text></localization> -->
    <!-- <localization string-id='poem'><xsl:text>Poem</xsl:text></localization> -->
    <localization string-id='figure'><xsl:text>Figure</xsl:text></localization>
    <localization string-id='table'><xsl:text>Table</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Note de bas de page</xsl:text></localization> <!--checked-->
    <!-- Lists and their items -->
    <!-- Translations needed for France French -->
    <!-- <localization string-id='list'><xsl:text>List</xsl:text></localization> -->
    <!-- <localization string-id='li'><xsl:text>Item</xsl:text></localization> -->
    <!-- Parts of an exercise and it's solution -->
    <localization string-id='exercise'><xsl:text>Exercice</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Indication</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Réponse</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Solution</xsl:text></localization>
     <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Sommaire</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Abstract</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Préface</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Remerciement</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Biographie</xsl:text></localization>
    <!-- singular and plural titles for biography subdivision -->
    <!-- <localization string-id='about-author'><xsl:text>About the Author</xsl:text></localization> -->
    <!-- <localization string-id='about-authors'><xsl:text>About the Authors</xsl:text></localization> -->
    <localization string-id='foreword'><xsl:text>Avant-propos</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Dédicace</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Colophon</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='indexsection'><xsl:text>Index</xsl:text></localization> <!--see latex mechanism-->
    <localization string-id='see'><xsl:text>Visiter</xsl:text></localization> <!--see latex mechanism-->
    <localization string-id='also'><xsl:text>Voir Aussi</xsl:text></localization> <!--see latex mechanism-->
    <!-- Navigation Interface elements -->
    <localization string-id='previous'><xsl:text>Précédent</xsl:text></localization> <!--buttons for HTML navigation-->
    <localization string-id='up'><xsl:text>Haut</xsl:text></localization>
    <localization string-id='next'><xsl:text>Suivant</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Annotations</xsl:text></localization> <!--does not get printed -->
    <localization string-id='feedback'><xsl:text>Commentaires</xsl:text></localization>  <!--e.g., in case there is a link for feedback.  Will appear in HTML.-->
    <localization string-id='authored'><xsl:text>Rédigé</xsl:text></localization> <!--e.g., authored in MBX.  Will appear in HTML.-->
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>À</xsl:text></localization>
    <localization string-id='from'><xsl:text>De</xsl:text></localization>
    <localization string-id='subject'><xsl:text>Sujet</xsl:text></localization>
    <localization string-id='date'><xsl:text>Date</xsl:text></localization>
    <localization string-id='copy'><xsl:text>Copie</xsl:text></localization>
    <localization string-id='enclosure'><xsl:text>Pièce Jointe</xsl:text></localization>
    <!-- Various -->
    <localization string-id='todo'><xsl:text>À Faire</xsl:text></localization>  
    <localization string-id='editor'><xsl:text>Éditeur</xsl:text></localization>  
    <localization string-id='copyright'><xsl:text>Copyright</xsl:text></localization>
</xsl:variable>

</xsl:stylesheet>
