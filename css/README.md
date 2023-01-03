CSS Directory
=============

The majority of CSS files here are recent copies of files publicly
available from the [PreTeXt server](https://pretextbook.org).
They are distributed so that they may be incorporated automatically
into offline versions of PreTeXt documents, such as EPUB.
In particular, no author or publisher should ever need to
copy or move these files in order to have useful output.

Also, any requests, suggestions, or corrections should be made
at the GitHub repositories where these are hosted, **not** as part
of this repository.  Any changes can, and will, migrate here promptly.
See the [CSS repository](https://github.com/PreTeXtBook/CSS_core).


Instructions
============

To update these files,

    $ ./update_css

Note that the script may be easily edited to use a branch
other than simply `main`, if necessary.

Then update the following record of when this was last done.
Examine the `xsl/pretext-html.xsl` file if you need to check
on the latest version number for the CSS.  If there are changes,
these should be fashioned into a commit for the repository.
See existing commit messages for communicating the version
number when that changes.  At a minimum, change the date and
commit that as a record of a "no-change" update.

CSS version:  0.31   Date: 2021-07-10
CSS version:  0.6    Date: 2022-12-30
CSS version:  0.6    Date: 2023-01-03


Experimental Jupyter Notebook CSS
=================================

There are two (old) CSS files used for Jupyter output:
`mathbook-add-on.css` and `mathbook-content.css`.
The file `mathbook-content.css` is formed by removing
any CSS not prefixed by `.mathbook-content` from
 `mathbook-3.css` (also included).  The removed material
 is the first portion of the part delimited as
 `MATHBOOK UI MODULE`, but not this entire section.

Last updated: 2020-07-01 (exclusive of CSS update record)
