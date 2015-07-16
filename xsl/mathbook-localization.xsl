<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 
<!--********************************************************************
Copyright 2013 Robert A. Beezer

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

<!-- This file contains language-specific strings                -->
<!-- The "name" attribute of the variables are used to           -->
<!-- reference the language code and the "string-id" of          -->
<!-- the localization element is the lookup identifier.          -->
<!-- Element content is the language-specific string.            -->
<!-- The English version ("en-US") is carefully documented, so   -->
<!-- additions of new languages do not necessarily require       -->
<!-- new documentation, though it could help other implementers. -->
<!-- See xsl/mathbook-common.xsl for the two routines which      -->
<!-- make use of this information, one is a named template and   -->
<!-- the other uses the name of an element as the string-id.     -->
<!--                                                             -->
<!-- Some items peculiar to LaTeX can be explained by            -->
<!-- http://www.tex.ac.uk/cgi-bin/texfaq2html?label=fixnam       -->
<!--                                                             -->
<!-- Contibutions of new languages are welcome and encouraged!   -->
<!-- Search on "Translation needed" to see where you can help.   -->

<!-- A general overview:                                                               -->
<!-- http://www.w3.org/International/articles/language-tags/                           -->
<!-- Subtag Registry:                                                                  -->
<!-- http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry -->

<!-- To test, or use:                             -->
<!--   place  xml:lang="es-ES", or similar,       -->
<!--   as an attribute on your <mathbook> element -->

<!-- Current (partially) implemented language codes and contributors -->
<!-- en-US, US English, Robert A. Beezer                             -->
<!-- pt-BR, Brazilian Portugese, Igor Morgado                        -->
<!-- es-ES, Spain Spanish, Juan José Torrens                         -->

<!-- en-US, US English, Robert A. Beezer, 2014/08/11 -->
<!-- This is the default if no @xml:lang attribute is given on the mathbook element -->
<xsl:variable name="en-US">
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id='theorem'><xsl:text>Theorem</xsl:text></localization>
    <localization string-id='corollary'><xsl:text>Corollary</xsl:text></localization>
    <localization string-id='lemma'><xsl:text>Lemma</xsl:text></localization>
    <localization string-id='algorithm'><xsl:text>Algorithm</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Proposition</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Claim</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Fact</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Proof</xsl:text></localization>
    <!-- Mathematical statements without proofs -->
    <localization string-id='definition'><xsl:text>Definition</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Conjecture</xsl:text></localization>
    <localization string-id='axiom'><xsl:text>Axiom</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Principle</xsl:text></localization>
    <!-- Equations, when referenced by number -->
    <localization string-id='men'><xsl:text>Equation</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Equation</xsl:text></localization>
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
    <localization string-id='example'><xsl:text>Example</xsl:text></localization>
    <localization string-id='remark'><xsl:text>Remark</xsl:text></localization>
    <localization string-id='figure'><xsl:text>Figure</xsl:text></localization>
    <localization string-id='table'><xsl:text>Table</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Footnote</xsl:text></localization>
    <!-- Parts of an exercise and it's solution -->
    <localization string-id='exercise'><xsl:text>Exercise</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Hint</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Answer</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Solution</xsl:text></localization>
    <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Contents</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Abstract</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Preface</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Acknowledgements</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Author Biography</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Foreword</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Dedication</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Colophon</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='indexsection'><xsl:text>Index</xsl:text></localization>
    <localization string-id='see'><xsl:text>see</xsl:text></localization>
    <localization string-id='also'><xsl:text>see also</xsl:text></localization>
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
</xsl:variable>

<!-- pt-BR, Brazilian Portugese -->
<!-- Igor Morgado, morgado.igor@gmail.com, 2014/08/11, 2014/08/14 -->
<xsl:variable name="pt-BR">
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id="theorem">Teorema</localization>
    <localization string-id="corollary">Corolário</localization>
    <localization string-id="lemma">Lema</localization>
    <!-- Translation needed for Brazilian Portugese -->
    <!-- <localization string-id='algorithm'><xsl:text>XX</xsl:text></localization> -->
    <localization string-id='proposition'><xsl:text>Proposição</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Afirmação</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Fato</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Demonstração</xsl:text></localization>
    <!-- Mathematical statements without proofs -->
    <localization string-id='definition'><xsl:text>Definição</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Conjectura</xsl:text></localization>
    <localization string-id='axiom'><xsl:text>Axioma</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Princípio</xsl:text></localization>
    <!-- Equations, when referenced by number -->
    <!-- Translation needed for Brazilian Portugese -->
    <!-- <localization string-id='men'><xsl:text>Equation</xsl:text></localization> -->
    <!-- <localization string-id='mrow'><xsl:text>Equation</xsl:text></localization> -->
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Volume</xsl:text></localization>
    <localization string-id='book'><xsl:text>Livro</xsl:text></localization>
    <localization string-id='article'><xsl:text>Artigo</xsl:text></localization>
    <localization string-id='letter'><xsl:text>Carta</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Memorando</xsl:text></localization>
    <localization string-id='presentation'><xsl:text>Apresentação</xsl:text></localization>
    <!-- Parts of a document -->
    <localization string-id='frontmatter'><xsl:text>Pré-textual</xsl:text></localization>
    <localization string-id='part'><xsl:text>Parte</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Capítulo</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Apêndice</xsl:text></localization>
    <localization string-id='section'><xsl:text>Seção</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Subseção</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>Subsubseção</xsl:text></localization>
    <!-- Translation needed for Brazilian Portugese -->
    <!-- <localization string-id='introduction'><xsl:text>Introduction</xsl:text></localization> -->
    <!-- <localization string-id='conclusion'><xsl:text>Conclusion</xsl:text></localization> -->
    <localization string-id='exercises'><xsl:text>Exercícios</xsl:text></localization>
    <localization string-id='references'><xsl:text>Referêcias</xsl:text></localization>
    <!-- Translation needed for Brazilian Portugese -->
    <!-- <localization string-id='backmatter'><xsl:text>Back Matter</xsl:text></localization> -->
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Parágrafo</xsl:text></localization>
    <localization string-id='paragraph'><xsl:text>Parágrafo</xsl:text></localization>
    <localization string-id='subparagraph'><xsl:text>Subparágrafo</xsl:text></localization>
    <!-- Components of the narrative -->
    <localization string-id='example'><xsl:text>Exemplo</xsl:text></localization>
    <localization string-id='remark'><xsl:text>Observação</xsl:text></localization>
    <localization string-id='figure'><xsl:text>Figura</xsl:text></localization>
    <localization string-id='table'><xsl:text>Tabela</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Nota de rodapé</xsl:text></localization>
    <!-- Parts of an exercise and it's solution -->
    <localization string-id='exercise'><xsl:text>Exercício</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Dica</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Resposta</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Solução</xsl:text></localization>
     <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Sumário</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Resumo</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Prefácio</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Agradecimentos</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Biografia do Autor</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Preâmbulo</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Dedicatória</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Ficha técnica</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='indexsection'><xsl:text>Índice</xsl:text></localization>
    <localization string-id='see'><xsl:text>veja</xsl:text></localization>
    <localization string-id='also'><xsl:text>veja também</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <localization string-id='previous'><xsl:text>Anterior</xsl:text></localization>
    <localization string-id='up'><xsl:text>Acima</xsl:text></localization>
    <localization string-id='next'><xsl:text>Próximo</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Anotações</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Comentário</xsl:text></localization>
    <localization string-id='authored'><xsl:text>Feito com</xsl:text></localization>
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>Para</xsl:text></localization>
    <localization string-id='from'><xsl:text>De</xsl:text></localization>
    <localization string-id='subject'><xsl:text>Assunto</xsl:text></localization>
    <localization string-id='date'><xsl:text>Data</xsl:text></localization>
    <localization string-id='copy'><xsl:text>Cópia</xsl:text></localization>
    <localization string-id='enclosure'><xsl:text>Anexo</xsl:text></localization>
    <!-- Various -->
    <localization string-id='todo'><xsl:text>Para fazer</xsl:text></localization>
    <localization string-id='editor'><xsl:text>Editor</xsl:text></localization>
    <localization string-id='copyright'><xsl:text>XXXCopyright</xsl:text></localization>
</xsl:variable>

<!-- es-ES, Spain Spanish -->
<!-- Juan José Torrens, jjtorrens@unavarra.es, 2014/10/27 -->
<xsl:variable name="es-ES">
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id="theorem">Teorema</localization>
    <localization string-id="corollary">Corolario</localization>
    <localization string-id="lemma">Lema</localization>
    <!-- Translation needed for Spain Spanish -->
    <!-- <localization string-id='algorithm'><xsl:text>XX</xsl:text></localization> -->
    <localization string-id='proposition'><xsl:text>Proposición</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Postulado</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Hecho</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Demostración</xsl:text></localization>
    <!-- Mathematical statements without proofs -->
    <localization string-id='definition'><xsl:text>Definición</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Conjetura</xsl:text></localization>
    <localization string-id='axiom'><xsl:text>Axioma</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Principio</xsl:text></localization>
    <!-- Equations, when referenced by number -->
    <!-- Translation needed for Spain Spanish -->
    <!-- <localization string-id='men'><xsl:text>Equation</xsl:text></localization> -->
    <!-- <localization string-id='mrow'><xsl:text>Equation</xsl:text></localization> -->
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Volumen</xsl:text></localization>
    <localization string-id='book'><xsl:text>Libro</xsl:text></localization>
    <localization string-id='article'><xsl:text>Artículo</xsl:text></localization>
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
    <!-- Translation needed for Spain Spanish -->
    <!-- <localization string-id='introduction'><xsl:text>Introduction</xsl:text></localization> -->
    <!-- <localization string-id='conclusion'><xsl:text>Conclusion</xsl:text></localization> -->
    <localization string-id='exercises'><xsl:text>Ejercicios</xsl:text></localization>
    <localization string-id='references'><xsl:text>Referencias</xsl:text></localization>
    <!-- Translation needed for Spain Spanish -->
    <!-- <localization string-id='backmatter'><xsl:text>Back Matter</xsl:text></localization> -->
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Párrafo</xsl:text></localization>
    <localization string-id='paragraph'><xsl:text>Párrafo</xsl:text></localization>
    <localization string-id='subparagraph'><xsl:text>Subpárrafo</xsl:text></localization>
    <!-- Components of the narrative -->
    <localization string-id='example'><xsl:text>Ejemplo</xsl:text></localization>
    <localization string-id='remark'><xsl:text>Nota</xsl:text></localization>
    <localization string-id='figure'><xsl:text>Figura</xsl:text></localization>
    <localization string-id='table'><xsl:text>Cuadro</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Nota a pie de página</xsl:text></localization>
    <!-- Parts of an exercise and it's solution -->
    <localization string-id='exercise'><xsl:text>Ejercicio</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Pista</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Respuesta</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Solución</xsl:text></localization>
     <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Índice</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Resumen</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Prefacio</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Agradecimentos</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Biografía del autor</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Prólogo</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Dedicatoria</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Colofón</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='indexsection'><xsl:text>Índice alfabético</xsl:text></localization>
    <localization string-id='see'><xsl:text>véase</xsl:text></localization>
    <localization string-id='also'><xsl:text>véase también</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <localization string-id='previous'><xsl:text>Anterior</xsl:text></localization>
    <localization string-id='up'><xsl:text>Arriba</xsl:text></localization>
    <localization string-id='next'><xsl:text>Siguiente</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Anotaciones</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Comentario</xsl:text></localization>
    <localization string-id='authored'><xsl:text>Realizado con</xsl:text></localization>
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
    <localization string-id='copyright'><xsl:text>Derechos de autor</xsl:text></localization>
</xsl:variable>

</xsl:stylesheet>
