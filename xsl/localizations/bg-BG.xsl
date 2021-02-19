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

<!-- bg-BG, Bulgarian (Bulgaria) -->
<!-- Boyko Bantchev, bantchev@gmail.com, 2019-07-04 -->

<xsl:variable name="bg-BG">
    <!-- THEOREM-LIKE blocks -->
    <!-- Environments which have proofs, plus proofs themselves -->
    <localization string-id='theorem'><xsl:text>Теорема</xsl:text></localization>
    <localization string-id='corollary'><xsl:text>Следствие</xsl:text></localization>
    <localization string-id='lemma'><xsl:text>Лема</xsl:text></localization>
    <localization string-id='algorithm'><xsl:text>Алгоритъм</xsl:text></localization>
    <localization string-id='proposition'><xsl:text>Предложение</xsl:text></localization>
    <localization string-id='claim'><xsl:text>Твърдение</xsl:text></localization>
    <localization string-id='fact'><xsl:text>Факт</xsl:text></localization>
    <localization string-id='identity'><xsl:text>Тъждество</xsl:text></localization>
    <localization string-id='proof'><xsl:text>Доказателство</xsl:text></localization>
    <localization string-id='case'><xsl:text>Случай</xsl:text></localization>
    <!-- Components of the narrative -->
    <!-- Mathematical statements without proofs -->
    <!-- AXIOM-LIKE blocks -->
    <localization string-id='axiom'><xsl:text>Аксиома</xsl:text></localization>
    <localization string-id='conjecture'><xsl:text>Хипотеза</xsl:text></localization>
    <localization string-id='principle'><xsl:text>Принцип</xsl:text></localization>
<!--
    <localization string-id='heuristic'><xsl:text>Heuristic</xsl:text></localization>
    <localization string-id='hypothesis'><xsl:text>Хипотеза</xsl:text></localization>
-->
    <localization string-id='assumption'><xsl:text>Постулат</xsl:text></localization>
    <!-- Definitions -->
    <localization string-id='definition'><xsl:text>Определение</xsl:text></localization>
    <!-- Single Line Mathematics -->
    <localization string-id='me'><xsl:text>Уравнение</xsl:text></localization>
    <localization string-id='men'><xsl:text>Уравнение</xsl:text></localization>
    <localization string-id='mrow'><xsl:text>Уравнение</xsl:text></localization>
    <!-- Display Mathematics -->
    <localization string-id='md'><xsl:text>Изнесена формула</xsl:text></localization>
    <localization string-id='mdn'><xsl:text>Изнесена формула</xsl:text></localization>
    <!-- Types of documents, mostly for informational messages -->
    <localization string-id='volume'><xsl:text>Том</xsl:text></localization>
    <localization string-id='book'><xsl:text>Книга</xsl:text></localization>
    <localization string-id='article'><xsl:text>Статия</xsl:text></localization>
    <!-- <localization string-id='slideshow'><xsl:text>Slideshow</xsl:text></localization> -->
    <localization string-id='letter'><xsl:text>Писмо</xsl:text></localization>
    <localization string-id='memo'><xsl:text>Паметна записка</xsl:text></localization>
    <localization string-id='presentation'><xsl:text>Презентация</xsl:text></localization>
    <!-- Parts of a document -->
    <!-- "part" will also be used for a "stage" of a WeBWorK problem -->
    <localization string-id='frontmatter'><xsl:text>Титулни страници</xsl:text></localization>
    <localization string-id='part'><xsl:text>Част</xsl:text></localization>
    <localization string-id='chapter'><xsl:text>Глава</xsl:text></localization>
    <localization string-id='appendix'><xsl:text>Приложение</xsl:text></localization>
    <localization string-id='section'><xsl:text>Параграф</xsl:text></localization>
    <localization string-id='subsection'><xsl:text>Точка</xsl:text></localization>
    <localization string-id='subsubsection'><xsl:text>Подточка</xsl:text></localization>
    <!-- A "slide" is a screenful of a presentation (Powerpoint, Beamer) -->
    <!-- <localization string-id='slide'><xsl:text>Slide</xsl:text></localization> -->
    <localization string-id='introduction'><xsl:text>Увод</xsl:text></localization>
    <localization string-id='conclusion'><xsl:text>Заключение</xsl:text></localization>
    <localization string-id='exercises'><xsl:text>Упражнения</xsl:text></localization>
<!--
    <localization string-id='worksheet'><xsl:text>Worksheet</xsl:text></localization>
    <localization string-id='reading-questions'><xsl:text>Reading Questions</xsl:text></localization>
-->
    <localization string-id='solutions'><xsl:text>Решения</xsl:text></localization>
    <localization string-id='glossary'><xsl:text>Речник на термините</xsl:text></localization>
    <localization string-id='references'><xsl:text>Библиография</xsl:text></localization>
    <localization string-id='backmatter'><xsl:text>Издателско каре</xsl:text></localization>
    <!-- paragraph is deprecated, getting plural correct is not super critical, just in messages -->
<!--
    <localization string-id='paragraphs'><xsl:text>Paragraphs</xsl:text></localization>
-->
    <localization string-id='commentary'><xsl:text>Коментар</xsl:text></localization>
<!--
    <localization string-id='subparagraph'><xsl:text>Subparagraph</xsl:text></localization>
-->
    <!-- Components of the narrative -->
    <!-- REMARK-LIKE blocks -->
    <!-- "note" is used within "biblio", likely to change -->
<!--
    <localization string-id='remark'><xsl:text>Remark</xsl:text></localization>
    <localization string-id='convention'><xsl:text>Convention</xsl:text></localization>
-->
    <localization string-id='note'><xsl:text>Забележка</xsl:text></localization>
<!--
    <localization string-id='observation'><xsl:text>Observation</xsl:text></localization>
    <localization string-id='warning'><xsl:text>Warning</xsl:text></localization>
    <localization string-id='insight'><xsl:text>Insight</xsl:text></localization>
    <localization string-id='computation'><xsl:text>Computation</xsl:text></localization>
    <localization string-id='technology'><xsl:text>Technology</xsl:text></localization>
-->
    <!-- ASIDE-LIKE blocks -->
    <localization string-id='aside'><xsl:text>Странична бележка</xsl:text></localization>
    <localization string-id='biographical'><xsl:text>Библиографична бележка</xsl:text></localization>
    <localization string-id='historical'><xsl:text>Историческа бележка</xsl:text></localization>
    <!-- EXAMPLE-LIKE blocks -->
    <localization string-id='example'><xsl:text>Пример</xsl:text></localization>
    <localization string-id='question'><xsl:text>Въпрос</xsl:text></localization>
    <localization string-id='problem'><xsl:text>Задача</xsl:text></localization>
    <!-- PROJECT-LIKE blocks -->
    <localization string-id='project'><xsl:text>Задание</xsl:text></localization>
    <localization string-id='activity'><xsl:text>Дейност</xsl:text></localization>
    <localization string-id='exploration'><xsl:text>Проучване</xsl:text></localization>
    <localization string-id='task'><xsl:text>Задача</xsl:text></localization>
    <localization string-id='investigation'><xsl:text>Изследване</xsl:text></localization>
    <!-- assemblages are collections of minimally structured material -->
    <localization string-id='assemblage'><xsl:text>Сборник</xsl:text></localization>
    <localization string-id='poem'><xsl:text>Стихотворение</xsl:text></localization>
    <!-- Objectives is the block, objective is a list item within -->
    <localization string-id='objectives'><xsl:text>Цели</xsl:text></localization>
    <localization string-id='objective'><xsl:text>Цел</xsl:text></localization>
    <!-- Outcomes is the block, outcome is a list item within (different) -->
    <!-- These two words need to be different, to avoid ambiguous cross-references -->
    <localization string-id='outcomes'><xsl:text>Резултати</xsl:text></localization>
    <localization string-id='outcome'><xsl:text>Резултат</xsl:text></localization>
    <!--  -->
    <localization string-id='figure'><xsl:text>Фигура</xsl:text></localization>
    <localization string-id='table'><xsl:text>Таблица</xsl:text></localization>
    <localization string-id='listing'><xsl:text>Списък</xsl:text></localization>
    <localization string-id='fn'><xsl:text>Бележка под линия</xsl:text></localization>
<!--
    <localization string-id='contributor'><xsl:text>Contributor</xsl:text></localization>
-->
    <!-- Lists and their items -->
    <localization string-id='list'><xsl:text>Списък</xsl:text></localization>
    <localization string-id='li'><xsl:text>Точка</xsl:text></localization>
    <!-- A term (word) defined in a glossary -->
    <localization string-id='defined-term'><xsl:text>Термин</xsl:text></localization>
    <!-- A regular paragraph, not the old sectioning structure -->
    <localization string-id='p'><xsl:text>Абзац</xsl:text></localization>
    <localization string-id='blockquote'><xsl:text>Цитат</xsl:text></localization>
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
    <localization string-id='divisionalexercise'><xsl:text>Упражнение</xsl:text></localization>
<!--
    <localization string-id='inlineexercise'><xsl:text>Checkpoint</xsl:text></localization>
    <localization string-id='worksheetexercise'><xsl:text>Worksheet Exercise</xsl:text></localization>
    <localization string-id='readingquestion'><xsl:text>Reading Question</xsl:text></localization>
    <localization string-id='webwork'><xsl:text>WeBWorK</xsl:text></localization>
-->
    <localization string-id='hint'><xsl:text>Подсказка</xsl:text></localization>
    <localization string-id='answer'><xsl:text>Отговор</xsl:text></localization>
    <localization string-id='solution'><xsl:text>Решение</xsl:text></localization>
    <!-- A group of divisional exercises (with introduction and conclusion) -->
<!--
    <localization string-id='exercisegroup'><xsl:text>Exercise Group</xsl:text></localization>
-->
    <!-- Bibliographic items (note is distinct from sidebar "Annotations" below) -->
<!--
    <localization string-id='biblio'><xsl:text>Bibliographic Entry</xsl:text></localization>
-->
    <!-- Front matter components -->
    <localization string-id='toc'><xsl:text>Съдържание</xsl:text></localization>
    <localization string-id='abstract'><xsl:text>Резюме</xsl:text></localization>  <!-- за книга е по-добре „Анотация“ -->
    <localization string-id='preface'><xsl:text>Предговор</xsl:text></localization><!-- от автора -->
    <localization string-id='acknowledgement'><xsl:text>Благодарности</xsl:text></localization>
    <localization string-id='biography'><xsl:text>Биография на автора</xsl:text></localization>
    <!-- singular and plural titles for biography subdivision -->
    <localization string-id='about-author'><xsl:text>За автора</xsl:text></localization>
    <localization string-id='about-authors'><xsl:text>За авторите</xsl:text></localization>
    <localization string-id='foreword'><xsl:text>Предговор</xsl:text></localization><!-- от другиго -->
    <localization string-id='dedication'><xsl:text>Посвещение</xsl:text></localization>
    <localization string-id='colophon'><xsl:text>Библиографско каре</xsl:text></localization>
    <!-- Back matter components -->
    <!-- index-part is deprecated, but not abandoned          -->
    <!-- NB: repurpose translations, maybe move appendix here -->
<!--
    <localization string-id='index-part'><xsl:text>Index</xsl:text></localization>
    <localization string-id='jump-to'><xsl:text>Jump to:</xsl:text></localization>
-->
    <!-- Parts of the Index -->
    <localization string-id='index'><xsl:text>Азбучен показалец</xsl:text></localization>
    <localization string-id='see'><xsl:text>Виж</xsl:text></localization>
    <localization string-id='also'><xsl:text>Виж също</xsl:text></localization>
    <!-- Notation List headings/foot -->
    <localization string-id='symbol'><xsl:text>Означение</xsl:text></localization>
    <localization string-id='description'><xsl:text>Описание</xsl:text></localization>
    <localization string-id='location'><xsl:text>Местоположение</xsl:text></localization>
    <localization string-id='page'><xsl:text>Страница</xsl:text></localization>
    <localization string-id='continued'><xsl:text>Продължава на следващата страница</xsl:text></localization>
    <!-- Navigation Interface elements -->
    <!-- Assistive "skip to content" link -->
    <localization string-id='skip-to-content'><xsl:text>Главна</xsl:text></localization>
    <localization string-id='previous'><xsl:text>Предишна</xsl:text></localization>
    <localization string-id='up'><xsl:text>Нагоре</xsl:text></localization>
    <localization string-id='next'><xsl:text>Следваща</xsl:text></localization>
    <!-- Keep these short, so buttons are not overly wide, 4 characters maximum -->
    <localization string-id='previous-short'><xsl:text>Пред</xsl:text></localization>
    <localization string-id='up-short'><xsl:text>Наг</xsl:text></localization>
    <localization string-id='next-short'><xsl:text>След</xsl:text></localization>
    <!-- NB: Use toc from above for both headings and navigation sidebar-->
<!--
    <localization string-id='annotations'><xsl:text>Annotations</xsl:text></localization>
    <localization string-id='feedback'><xsl:text>Feedback</xsl:text></localization>
-->
    <localization string-id='authored'><xsl:text>Направено с</xsl:text></localization>
    <!-- Parts of memos and letters -->
    <localization string-id='to'><xsl:text>До</xsl:text></localization>
    <localization string-id='from'><xsl:text>От</xsl:text></localization>
    <localization string-id='subject'><xsl:text>Тема</xsl:text></localization>
    <localization string-id='date'><xsl:text>Дата</xsl:text></localization>
    <localization string-id='copy'><xsl:text>Също до</xsl:text></localization>
    <localization string-id='enclosure'><xsl:text>Прикачено</xsl:text></localization>
    <!-- Various -->
<!--
    <localization string-id='todo'><xsl:text>To Do</xsl:text></localization>
    <localization string-id='editor'><xsl:text>Editor</xsl:text></localization>
    <localization string-id='edition'><xsl:text>Edition</xsl:text></localization>
    <localization string-id='website'><xsl:text>Website</xsl:text></localization>
    <localization string-id='copyright'><xsl:text>Copyright</xsl:text></localization>
-->
    <!-- HTML clickables (lowercase strings to click on) -->
    <localization string-id='permalink'><xsl:text>permalink</xsl:text></localization>
    <localization string-id='incontext'><xsl:text>in-context</xsl:text></localization>
    <!-- Sage Cell evaluate button      -->
    <!-- eg, "Evaluate (Maxima)"        -->
    <!-- 2017-05-14: 'code' is obsolete -->
    <!-- This needs to be defined to *something* (always)       -->
    <!-- else whatever crud ends up on the button kills the cell -->
<!--
    <localization string-id='evaluate'><xsl:text>Evaluate</xsl:text></localization>
    <localization string-id='evaluate'><xsl:text>Evaluate</xsl:text></localization>
-->
    <!-- <localization string-id='code'><xsl:text>Code</xsl:text></localization> -->
</xsl:variable>

</xsl:stylesheet>
