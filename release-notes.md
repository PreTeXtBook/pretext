===========================
Release Notes, MathBook XML
===========================

----------------
0.03, 2016/04/23
----------------

'''''''
Summary
'''''''
 * Stable release, many new features
 * LaTeX, HTML conversions stable
 * Preliminary conversions to EPUB, Sage Notebook, SageMathCloud, Jupyter Notebooks
 * DTD (Document Type Definition)
 * More examples (sample book)
 * Author's Guide (documentation)
 * WeBWorK homework problems

'''''''
Changes
'''''''
 * Improvements to front matter, back matter
 * Initial support for poetry
 * Improved chunking for all formats
 * Localizations for Portugese, French
 * More flexible cross-references
 * Improvements to mbx script
 * Letter and memo document types
 * Improved program, console, verbatim text
 * Index support for HTML
 * Deprecated: `html.chunk.level` stringparam is now just `chunk.level`
 * Deprecated: ordered lists can no longer have empty levels
 * Deprecated: autonam'ed cross-references no longer have a plural form

----------------
0.02, 2015/03/18
----------------

'''''''
Summary
'''''''
 * Stable release, many new features, all anticipated deprecations in place
 * Basic or preliminary support for most common document components
 * LaTeX, HTML conversions stable
 * Preliminary conversions to Sage Notebook and SageMathCloud

'''''''
Changes
'''''''
 * Variable level chunking for HTML output
 * Improved numbering scheme, with defaults and customization
 * `<exercises>` sections at any level
 * `<references>` sections at any level
 * New Sage cells: display only, straight copy of other cells, practice
 * Basic index functionality for LaTeX output
 * Automatic names in cross-references (optionally)
 * Program listings for a variety of languages
 * Asymptote, Sage graphics support
 * General LaTeX image code support (tikz, pgfplots, etc.)
 * Basic support for Unicode characters
 * `<conclusion>`, just like `<introduction>`
 * Improved author tools
 * Improved Sage doctest creation
 * New front matter sections
 * New exercise groups
 * Localization: Brazilian Portugese
 * Localization: Spanish Spanish
 * Reference autonaming, with localizations
 * Sage worksheet creation, via XSL and Python script
 * SageMathCloud worksheet creation, via pure XSL
 * Greatly revamped HTML output for better navigation
 * Preliminary support for Unicode characters
 * Added contrib directory for user examples
 * Notation lists in back matter
 * Solutions in back matter
 * Greatly improved nested lists
 * Slanted fraction support
 * Images can have descriptions for HTML alt text
 * Side-by-side objects, horizontal layouts
 * SI units formatting support in text
 * User-supplied CSS enabled
 * `<algorithm>` element, like `<theorem>`
 * Tables reimagined, old style no longer supported
 * Deprecated: filebase attribute replaced by xml:id
 * Deprecated: `<cite>`, just use `<xref>` instead
 * Deprecated: `<tikz>`, use `<latex-image-code>`
 * Deprecated: `<paragraph>`, use `<paragraphs>` instead
 * Deprecated: `<tbody>`, `<entry>`, etc, use `<tabular>`, `<cell>`, etc


----------------
0.01, 2014/04/30
----------------

'''''''
Summary
'''''''

 * Stable release, but incomplete and subject to change
