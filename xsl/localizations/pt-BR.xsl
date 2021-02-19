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

<!-- pt-BR, Portugese (Brazil)-->
<!-- Igor Morgado, morgado.igor@gmail.com, 2014-08-11, 2014-08-14 -->
<!-- Vinicius Monego, monego@posteo.net, 2020-11-07 -->

<xsl:variable name="pt-BR">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id="theorem">Teorema</localization>
    <localization string-id="corollary">Corolário</localization>
    <localization string-id="lemma">Lema</localization>
    <localization string-id='algorithm'><xsl:text>Algoritmo</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Proposição</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Afirmação</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Fato</xsl:text></localization>
    <localization string-id='identity'><xsl:text>Identidade</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Demonstração</xsl:text></localization>
    <localization string-id='case'><xsl:text>Caso</xsl:text></localization>
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Axioma</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Conjectura</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Princípio</xsl:text></localization>
    <localization string-id='heuristic'><xsl:text>Heurística</xsl:text></localization>
    <localization string-id='hypothesis'><xsl:text>Hipótese</xsl:text></localization>
    <localization string-id='assumption'><xsl:text>Suposição</xsl:text></localization>
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Definição</xsl:text></localization>
    <!-- Single Line Mathematics -->
    <localization string-id='me'><xsl:text>Equação</xsl:text></localization>
    <localization string-id='men'><xsl:text>Equação</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Equação</xsl:text></localization>
    <!-- Translation needed for Brazilian Portugese -->
    <!-- Display Mathematics -->
    <!-- <localization string-id='md'><xsl:text>Display Mathematics</xsl:text></localization> -->
    <!-- <localization string-id='mdn'><xsl:text>Display Mathematics</xsl:text></localization> -->
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Volume</xsl:text></localization>
    <localization string-id='book'><xsl:text>Livro</xsl:text></localization>
    <localization string-id='article'><xsl:text>Artigo</xsl:text></localization>
    <!-- Translation needed for Brazilian Portugese -->
    <!-- <localization string-id='slideshow'><xsl:text>Slideshow</xsl:text></localization> -->
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
    <!-- A "slide" is a screenful of a presentation (Powerpoint, Beamer) -->
    <localization string-id='slide'><xsl:text>Transparência</xsl:text></localization>
    <localization string-id='introduction'><xsl:text>Introdução</xsl:text></localization>
    <localization string-id='conclusion'><xsl:text>Conclusão</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Exercícios</xsl:text></localization>
    <!-- Translation needed for Brazilian Portugese -->
    <!-- <localization string-id='worksheet'><xsl:text>Worksheet</xsl:text></localization> -->
    <!-- <localization string-id='reading-questions'><xsl:text>Reading Questions</xsl:text></localization> -->
    <localization string-id='solutions'><xsl:text>Soluções</xsl:text></localization>
    <localization string-id='glossary'><xsl:text>Glossário</xsl:text></localization>
    <localization string-id='references'><xsl:text>Referêcias</xsl:text></localization>
    <!-- Translation needed for Brazilian Portugese -->
    <!-- <localization string-id='backmatter'><xsl:text>Back Matter</xsl:text></localization> -->
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
    <localization string-id='paragraphs'><xsl:text>Parágrafo</xsl:text></localization>
    <!-- <localization string-id='commentary'><xsl:text>Commentary</xsl:text></localization> -->
    <localization string-id='subparagraph'><xsl:text>Subparágrafo</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
    <localization string-id='remark'><xsl:text>Nota</xsl:text></localization>
    <localization string-id='convention'><xsl:text>Convenção</xsl:text></localization>
    <localization string-id='note'><xsl:text>Nota</xsl:text></localization>
    <localization string-id='observation'><xsl:text>Observação</xsl:text></localization>
    <localization string-id='warning'><xsl:text>Atenção</xsl:text></localization>
    <!-- Translation needed for Brazilian Portugese -->
    <!-- <localization string-id='insight'><xsl:text>Insight</xsl:text></localization> -->
    <!-- <localization string-id='computation'><xsl:text>Computation</xsl:text></localization> -->
    <!-- <localization string-id='technology'><xsl:text>Technology</xsl:text></localization> -->
    <!-- ASIDE-LIKE blocks -->
    <!-- <localization string-id='aside'><xsl:text>Aside</xsl:text></localization> -->
    <!-- <localization string-id='biographical'><xsl:text>Biographical Aside</xsl:text></localization> -->
    <!-- <localization string-id='historical'><xsl:text>Historical Aside</xsl:text></localization> -->
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Exemplo</xsl:text></localization>
    <localization string-id='question'><xsl:text>Questão</xsl:text></localization>
    <localization string-id='problem'><xsl:text>Problema</xsl:text></localization>
    <!-- PROJECT-LIKE blocks -->
    <localization string-id='project'><xsl:text>Projeto</xsl:text></localization>
    <localization string-id='activity'><xsl:text>Atividade</xsl:text></localization>
    <localization string-id='exploration'><xsl:text>Exploração</xsl:text></localization>
    <localization string-id='task'><xsl:text>Tarefa</xsl:text></localization>
    <localization string-id='investigation'><xsl:text>Investigação</xsl:text></localization>
    <!--  -->
    <!-- Translation needed for Brazilian Portugese -->
    <!-- assemblages are collections of minimally structured material -->
    <!-- <localization string-id='assemblage'><xsl:text>Assemblage</xsl:text></localization> -->
    <!-- <localization string-id='poem'><xsl:text>Poem</xsl:text></localization> -->
    <!-- Objectives is the block, objective is a list item within -->
    <localization string-id='objectives'><xsl:text>Objetivos</xsl:text></localization>
    <localization string-id='objective'><xsl:text>Objetivo</xsl:text></localization>
    <!-- Outcomes is the block, outcome is a list item within (different) -->
    <localization string-id='outcomes'><xsl:text>Resultados</xsl:text></localization>
    <localization string-id='outcome'><xsl:text>Resultado</xsl:text></localization>
    <!--  -->
    <localization string-id='figure'><xsl:text>Figura</xsl:text></localization>
    <localization string-id='table'><xsl:text>Tabela</xsl:text></localization>
    <localization string-id='listing'><xsl:text>Listagem</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Nota de rodapé</xsl:text></localization>
    <localization string-id='contributor'><xsl:text>Contribuidor</xsl:text></localization>
    <!-- Lists and their items -->
    <localization string-id='list'><xsl:text>Lista</xsl:text></localization>
    <localization string-id='li'><xsl:text>Item</xsl:text></localization>
    <!-- A term (word) defined in a glossary -->
    <localization string-id='defined-term'><xsl:text>Termo</xsl:text></localization>
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Parágrafo</xsl:text></localization>
    <localization string-id='blockquote'><xsl:text>Citação</xsl:text></localization>
    <!-- Literate programming, a chunk of computer code -->
    <!-- <localization string-id='fragment'><xsl:text>Fragment</xsl:text></localization> -->
    <!-- Parts of an exercise and its solution -->
    <localization string-id='divisionalexercise'><xsl:text>Exercício</xsl:text></localization>
    <!-- Translation needed for Brazilian Portugese -->
    <!-- See en-US file for distinctions here, do not repeat previous translation -->
    <!-- <localization string-id='inlineexercise'><xsl:text>Checkpoint</xsl:text></localization> -->
    <!-- <localization string-id='worksheetexercise'><xsl:text>Worksheet Exercise</xsl:text></localization> -->
    <!-- <localization string-id='readingquestion'><xsl:text>Reading Question</xsl:text></localization> -->
    <localization string-id='webwork'><xsl:text>WeBWorK</xsl:text></localization>
    <localization string-id='hint'><xsl:text>Dica</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Resposta</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Solução</xsl:text></localization>
    <!-- A group of divisional exercises (with introduction and conclusion) -->
    <localization string-id='exercisegroup'><xsl:text>Grupo de exercícios</xsl:text></localization>
    <!-- Bibliographic items (note is distinct from sidebar "Annotations" below) -->
    <localization string-id='biblio'><xsl:text>Referência bibliográfica</xsl:text></localization>
    <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Sumário</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Resumo</xsl:text></localization>
    <localization string-id='preface'><xsl:text>Prefácio</xsl:text></localization>
    <localization string-id='acknowledgement'><xsl:text>Agradecimentos</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Biografia do autor</xsl:text></localization>
    <!-- singular and plural titles for biography subdivision -->
    <localization string-id='about-author'><xsl:text>Sobre o autor</xsl:text></localization>
    <localization string-id='about-authors'><xsl:text>Sobre os autores</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Preâmbulo</xsl:text></localization>
    <localization string-id='dedication'><xsl:text>Dedicatória</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Ficha técnica</xsl:text></localization>
    <!-- Back matter components -->
    <!-- index-part is deprecated, but not abandoned          -->
    <!-- NB: repurpose translations, maybe move appendix here -->
    <localization string-id='index-part'><xsl:text>Índice</xsl:text></localization>
    <localization string-id='jump-to'><xsl:text>Ir para:</xsl:text></localization>
    <!-- Parts of the Index -->
    <localization string-id='index'><xsl:text>Índice</xsl:text></localization>
    <localization string-id='see'><xsl:text>Veja</xsl:text></localization>
    <localization string-id='also'><xsl:text>Veja também</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>Símbolo</xsl:text></localization>
    <localization string-id='description'><xsl:text>Descrição</xsl:text></localization>
    <localization string-id='location'><xsl:text>Posição</xsl:text></localization>
    <localization string-id='page'><xsl:text>Página</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Continua na próxima página</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <!-- Assistive "skip to content" link -->
    <localization string-id='skip-to-content'><xsl:text>Ir ao conteúdo principal</xsl:text></localization>
    <localization string-id='previous'><xsl:text>Anterior</xsl:text></localization>
    <localization string-id='up'><xsl:text>Acima</xsl:text></localization>
    <localization string-id='next'><xsl:text>Próximo</xsl:text></localization>
    <!-- Keep these short, so buttons are not overly wide, 4 characters maximum -->
    <!-- TODO: SHORTEN THESE -->
    <localization string-id='previous-short'><xsl:text>Anterior</xsl:text></localization>
    <localization string-id='up-short'><xsl:text>Acima</xsl:text></localization>
    <localization string-id='next-short'><xsl:text>Próximo</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
    <localization string-id='annotations'><xsl:text>Anotações</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Comentário</xsl:text></localization>
    <localization string-id='authored'><xsl:text>Feito com PreTeXt</xsl:text></localization>
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
    <localization string-id='edition'><xsl:text>Edição</xsl:text></localization>
    <localization string-id='website'><xsl:text>Endereço eletrônico</xsl:text></localization>
    <localization string-id='copyright'><xsl:text>XXXCopyright</xsl:text></localization>
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>link permanente</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>em contexto</xsl:text></localization>
    <!-- Sage Cell evaluate button      -->
    <!-- eg, "Evaluate (Maxima)"        -->
    <!-- 2017-05-14: 'code' is obsolete -->
    <!-- This needs to be defined to *something* (English)       -->
    <!-- else whatever crud ends up on the button kills the cell -->
    <!-- Translate at first opportunity, please                  -->
    <localization string-id='evaluate'><xsl:text>Executar</xsl:text></localization>
    <localization string-id='code'><xsl:text>Código</xsl:text></localization>
</xsl:variable>

</xsl:stylesheet>
