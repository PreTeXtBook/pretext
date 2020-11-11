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

<!-- es-ES, Spanish (Spain) -->
<!-- Juan José Torrens, jjtorrens@unavarra.es, 2014-10-27 -->
<!-- Julian Pfeifle, julian.pfeifle@upc.edu, 2020-05-28 -->

<xsl:variable name="es-ES">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id="theorem">Teorema</localization>
    <localization string-id="corollary">Corolario</localization>
    <localization string-id="lemma">Lema</localization>
    <localization string-id='algorithm'><xsl:text>Algoritmo</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Proposición</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Postulado</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Hecho</xsl:text></localization>
    <localization string-id='identity'><xsl:text>Identidad</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Demostración</xsl:text></localization>
    <localization string-id='case'><xsl:text>Caso</xsl:text></localization>
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Axioma</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Conjetura</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Principio</xsl:text></localization>
    <localization string-id='heuristic'><xsl:text>Heurística</xsl:text></localization>
    <localization string-id='hypothesis'><xsl:text>Hipótesis</xsl:text></localization>
    <localization string-id='assumption'><xsl:text>Hipótesis</xsl:text></localization>
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Definición</xsl:text></localization>
    <!-- Single Line Mathematics -->
    <localization string-id='me'><xsl:text>Ecuación</xsl:text></localization>
    <localization string-id='men'><xsl:text>Ecuación</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Ecuación</xsl:text></localization>
    <!-- Display Mathematics -->
    <localization string-id='md'><xsl:text>Ecuación resaltada</xsl:text></localization>
    <localization string-id='mdn'><xsl:text>Ecuación resaltada</xsl:text></localization>
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Volumen</xsl:text></localization>
    <localization string-id='book'><xsl:text>Libro</xsl:text></localization>
    <localization string-id='article'><xsl:text>Artículo</xsl:text></localization>
    <!-- <localization string-id='slideshow'><xsl:text>Slideshow</xsl:text></localization> -->
    <localization string-id='letter'><xsl:text>Carta</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Memorándum</xsl:text></localization>
    <localization string-id='presentation'><xsl:text>Presentación</xsl:text></localization>
    <!-- Parts of a document -->
    <localization string-id='frontmatter'><xsl:text>Páginas preliminares</xsl:text></localization>
    <localization string-id='part'><xsl:text>Parte</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Capítulo</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Apéndice</xsl:text></localization>
    <localization string-id='section'><xsl:text>Sección</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Subsección</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>Subsubsección</xsl:text></localization>
    <!-- A "slide" is a screenful of a presentation (Powerpoint, Beamer) -->
    <!-- <localization string-id='slide'><xsl:text>Slide</xsl:text></localization> -->
    <localization string-id='introduction'><xsl:text>Introducción</xsl:text></localization>
    <localization string-id='conclusion'><xsl:text>Conclusión</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Ejercicios</xsl:text></localization>
    <localization string-id='worksheet'><xsl:text>Hoja de trabajo</xsl:text></localization>
    <localization string-id='reading-questions'><xsl:text>Preguntas de comprensión</xsl:text></localization>
    <localization string-id='solutions'><xsl:text>Soluciones</xsl:text></localization>
    <localization string-id='glossary'><xsl:text>Glosario</xsl:text></localization>
    <localization string-id='references'><xsl:text>Referencias</xsl:text></localization>
    <!-- Translation needed for Spain Spanish -->
    <!-- <localization string-id='backmatter'><xsl:text>Back Matter</xsl:text></localization> -->
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Párrafo</xsl:text></localization>
    <localization string-id='commentary'><xsl:text>Comentario</xsl:text></localization>
    <localization string-id='subparagraph'><xsl:text>Subpárrafo</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Nota</xsl:text></localization>
    <localization string-id='convention'><xsl:text>Convención</xsl:text></localization>
    <localization string-id='note'><xsl:text>Nota</xsl:text></localization>
    <localization string-id='observation'><xsl:text>Observación</xsl:text></localization>
    <localization string-id='warning'><xsl:text>Advertencia</xsl:text></localization>
    <!-- <localization string-id='insight'><xsl:text>Insight</xsl:text></localization> -->
    <localization string-id='computation'><xsl:text>Computación</xsl:text></localization>
    <localization string-id='technology'><xsl:text>Tecnología</xsl:text></localization>
    <!-- ASIDE-LIKE blocks -->
    <!-- <localization string-id='aside'><xsl:text>Aside</xsl:text></localization> -->
    <!-- <localization string-id='biographical'><xsl:text>Biographical Aside</xsl:text></localization> -->
    <!-- <localization string-id='historical'><xsl:text>Historical Aside</xsl:text></localization> -->
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Ejemplo</xsl:text></localization>
    <localization string-id='question'><xsl:text>Pregunta</xsl:text></localization>
    <localization string-id='problem'><xsl:text>Problema</xsl:text></localization>
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
    <!-- Objectives is the block, objective is a list item within -->
    <!-- <localization string-id='objectives'><xsl:text>Objectives</xsl:text></localization> -->
    <!-- <localization string-id='objective'><xsl:text>Objective</xsl:text></localization> -->
    <!-- Outcomes is the block, outcome is a list item within (different) -->
    <!-- <localization string-id='outcomes'><xsl:text>Outcomes</xsl:text></localization> -->
    <!-- <localization string-id='outcome'><xsl:text>Outcome</xsl:text></localization> -->
    <!--  -->
    <localization string-id='figure'><xsl:text>Figura</xsl:text></localization>
    <localization string-id='table'><xsl:text>Cuadro</xsl:text></localization>
    <localization string-id='listing'><xsl:text>Listado</xsl:text></localization>
    <!-- Translation needed for Spain Spanish -->
    <!-- <localization string-id='contributor'><xsl:text>Contributor</xsl:text></localization> -->
    <localization string-id='fn'><xsl:text>Nota a pie de página</xsl:text></localization>
    <!-- Lists and their items -->
    <!-- Translations needed for Spain Spanish -->
    <!-- <localization string-id='list'><xsl:text>List</xsl:text></localization> -->
    <!-- <localization string-id='li'><xsl:text>Item</xsl:text></localization> -->
    <!-- A term (word) defined in a glossary -->
    <!-- <localization string-id='defined-term'><xsl:text>Term</xsl:text></localization> -->
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Párrafo</xsl:text></localization>
    <!-- <localization string-id='blockquote'><xsl:text>Quotation</xsl:text></localization> -->
    <!-- Literate programming, a chunk of computer code -->
    <!-- <localization string-id='fragment'><xsl:text>Fragment</xsl:text></localization> -->
    <!-- Parts of an exercise and its solution -->
    <localization string-id='divisionalexercise'><xsl:text>Ejercicio</xsl:text></localization>
    <!-- Translation needed for Spain Spanish -->
    <!-- See en-US file for distinctions here, do not repeat previous translation -->
    <!-- <localization string-id='inlineexercise'><xsl:text>Checkpoint</xsl:text></localization> -->
    <!-- <localization string-id='worksheetexercise'><xsl:text>Worksheet Exercise</xsl:text></localization> -->
    <!-- <localization string-id='readingquestion'><xsl:text>Reading Question</xsl:text></localization> -->
    <localization string-id='webwork'><xsl:text>WeBWorK</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Pista</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Respuesta</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Solución</xsl:text></localization>
    <!-- Translation needed for Spain Spanish -->
    <!-- A group of divisional exercises (with introduction and conclusion) -->
    <!-- <localization string-id='exercisegroup'><xsl:text>Exercise Group</xsl:text></localization> -->
    <!-- Bibliographic items (note is distinct from sidebar "Annotations" below) -->
    <!-- <localization string-id='biblio'><xsl:text>Bibliographic Entry</xsl:text></localization> -->
    <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Índice</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Resumen</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Prefacio</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Agradecimentos</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Biografía del autor</xsl:text></localization>
    <!-- singular and plural titles for biography subdivision -->
    <!-- <localization string-id='about-author'><xsl:text>About the Author</xsl:text></localization> -->
    <!-- <localization string-id='about-authors'><xsl:text>About the Authors</xsl:text></localization> -->
    <localization string-id='foreword'><xsl:text>Prólogo</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Dedicatoria</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Colofón</xsl:text></localization>
    <!-- Back matter components -->
    <!-- index-part is deprecated, but not abandoned          -->
    <!-- NB: repurpose translations, maybe move appendix here -->
    <localization string-id='index-part'><xsl:text>Índice alfabético</xsl:text></localization>
    <!-- <localization string-id='jump-to'><xsl:text>Jump to:</xsl:text></localization> -->
    <!-- Parts of the Index -->
    <localization string-id='index'><xsl:text>Índice alfabético</xsl:text></localization>
    <localization string-id='see'><xsl:text>Véase</xsl:text></localization>
    <localization string-id='also'><xsl:text>Véase también</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>Símbolo</xsl:text></localization>
    <localization string-id='description'><xsl:text>Descripción</xsl:text></localization>
    <localization string-id='location'><xsl:text>Ubicación</xsl:text></localization>
    <localization string-id='page'><xsl:text>Página</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Continúa en la página siguiente</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <!-- Assistive "skip to content" link -->
    <localization string-id='skip-to-content'><xsl:text>Salta al contenido principal</xsl:text></localization>
    <localization string-id='previous'><xsl:text>Anterior</xsl:text></localization>
    <localization string-id='up'><xsl:text>Arriba</xsl:text></localization>
    <localization string-id='next'><xsl:text>Siguiente</xsl:text></localization>
    <!-- Keep these short, so buttons are not overly wide, 4 characters maximum -->
    <!-- TODO: SHORTEN THESE -->
    <localization string-id='previous-short'><xsl:text>Anterior</xsl:text></localization>
    <localization string-id='up-short'><xsl:text>Arriba</xsl:text></localization>
    <localization string-id='next-short'><xsl:text>Siguiente</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Anotaciones</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Comentario</xsl:text></localization>
    <localization string-id='authored'><xsl:text>Realizado con PreTeXt</xsl:text></localization>
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>A</xsl:text></localization>
    <localization string-id='from'><xsl:text>De</xsl:text></localization>
    <localization string-id='subject'><xsl:text>Asunto</xsl:text></localization>
    <localization string-id='date'><xsl:text>Fecha</xsl:text></localization>
    <localization string-id='copy'><xsl:text>Copia a</xsl:text></localization>
    <localization string-id='enclosure'><xsl:text>Adjunto</xsl:text></localization>
    <!-- Various -->
    <localization string-id='todo'><xsl:text>Para hacer</xsl:text></localization>
    <localization string-id='editor'><xsl:text>Editor</xsl:text></localization>
    <localization string-id='edition'><xsl:text>Edición</xsl:text></localization> 
    <!-- <localization string-id='website'><xsl:text>Website</xsl:text></localization> -->
    <localization string-id='copyright'><xsl:text>Derechos de autor</xsl:text></localization>
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>enlace permanente</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>en contexto</xsl:text></localization>
    <!-- Sage Cell evaluate button      -->
    <!-- eg, "Evaluate (Maxima)"        -->
    <!-- 2017-05-14: 'code' is obsolete -->
    <!-- This needs to be defined to *something* (English)       -->
    <!-- else whatever crud ends up on the button kills the cell -->
    <!-- Translate at first opportunity, please                  -->
    <localization string-id='evaluate'><xsl:text>Evaluate</xsl:text></localization>
    <!-- <localization string-id='code'><xsl:text>Code</xsl:text></localization> -->
</xsl:variable>

</xsl:stylesheet>
