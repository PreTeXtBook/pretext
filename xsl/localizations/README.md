<!--********************************************************************
Copyright 2013-2021 Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

PreTeXt Localizations
=====================

Each file in this directory provides translations of various strings used in titles and headings (and other places) to a specific language.  Filenames reflect the code for language (lowercase) and then the code for the region (uppercase).  This is a requirement.

For each file of translations, the "language" attribute of the "locale" element used to reference the language code and the "string-id" of each "localization" element is the lookup key. Element content is the language-specific string. The English version ("en-US") is carefully documented, so additions of new languages do not necessarily require new documentation, though it could help other implementers. See `xsl/pretext-common.xsl` for the two routines which make use of this information, one is a named template and the other (largely) uses the name of an element as the string-id.

Some items peculiar to LaTeX are explained [here](http://www.tex.ac.uk/cgi-bin/texfaq2html?label=fixnam)

There is a [general overview of language tags](http://www.w3.org/International/articles/language-tags/) and the [Subtag Registry](http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry).

Contibutions of new languages are always welcome and especially encouraged! Search on "Translation needed" to see where you can help. Use the  en-US  file as a template for a new language file, since it is always most complete.  It is understood that certain English words and phrases have subtleties that can be very hard to capture in another language.  Do your best to concoct a close approximation -- something should be better than nothing.  And it might improve with additions from others later.  We try to address some of this in the  en-US  file, so do be certain to look there for explanations of how these strings are employed.  Comments about your own decisions, within the relevant language file, can be very helpful later.

NEW LANGUAGES: for a new file to be effective, a single line needs to be added to the `xsl/localizations/localizations.xml` file.  It should be obvious what to do by looking at the other lines of that file.

Additions to incomplete files, or new files for additional languages, are very welcome and are a huge help in making PreTeXt useable for more authors.  A GitHub pull request is preferable.  If you do not know GitHub well, then emailing the entire language file (as an attachment) is very welcome and just as easy to deal with on our end.

To test, or use: place  `xml:lang="es-ES"`, or similar, as an attribute on your `<pretext>` element.  `en-US` is the default if no `@xml:lang` attribute is given on the `pretext` element.

Current (partially) implemented language codes and contributors
* af-ZA, Afrikaans (South Africa), Dirk Basson
* bg-BG, Bulgarian (Bulgaria), Boyko Bantchev
* ca-ES, Catalan (Spain), Jordi Saludes
* cs-CZ, Czech (Czechia), Jiří Lebl
* de-DE, German (Germany), Karl-Dieter Crisman
* es-ES, Spanish (Spain), Juan José Torrens
* en-US, English (United States), Robert A. Beezer
* fr-CA, French (Canada), Jean-Sébastien Turcotte
* fr-FR, French (France), Thomas W. Judson, Julien Giol, Jean-Sébastien Turcotte
* hu-HU, Hungarian (Hungary), Sándor Czirbusz
* it-IT, Italian (Italy), Valerio Monti
* pt-BR, Portugese (Brazil), Igor Morgado
* pt-PT, Portugese (Portugal), António Pereira
