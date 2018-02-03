<!--********************************************************************
Copyright 2013-2016 Robert A. Beezer

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

MathBook XML Localizations
==========================

Each file in this directory provides translations of various strings used in titles and headings (and other places) to a specific language.  Filenames reflect the code for language (lowercase) and then the code for the region (uppercase).  This is a requirement, so that the right file is located for the language code given in the source XML.

For each file of translations, the "name" attribute of the variables are used to reference the language code and the "string-id" of the localization element is the lookup identifier. Element content is the language-specific string. The English version ("en-US") is carefully documented, so additions of new languages do not necessarily require new documentation, though it could help other implementers. See `xsl/mathbook-common.xsl` for the two routines which make use of this information, one is a named template and the other uses the name of an element as the string-id.

Some items peculiar to LaTeX are explained [here](http://www.tex.ac.uk/cgi-bin/texfaq2html?label=fixnam)

There is a [general overview of language tags](http://www.w3.org/International/articles/language-tags/) and the [Subtag Registry](http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry).

Contibutions of new languages are always welcome and especially encouraged! Search on "Translation needed" to see where you can help. Use the  en-US  file as a template for a new language file, since it is always most complete.

To test, or use: place  `xml:lang="es-ES"`, or similar, as an attribute on your `<mathbook>` element.  `en-US` is the default if no `@xml:lang` attribute is given on the `mathbook` element.

Current (partially) implemented language codes and contributors
* cs-CZ, Czech (Czechia), Jiří Lebl
* es-ES, Spanish (Spain), Juan José Torrens
* en-US, English (United States), Robert A. Beezer
* fr-FR, French (France), Thomas W. Judson
* hu-HU, Hungarian (Hungary), Sándor Czirbusz
* pt-BR, Portugese (Brazil), Igor Morgado
* pt-PT, Portugese (Portugal), António Pereira
