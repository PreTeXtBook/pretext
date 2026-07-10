# MathJax (MJ) and Speech Rule Engine (SRE)

Offline support for conversions to EPUB, Kindle, braille,
and the XSL-FO PDF.

Requires installations of MathJax (version 4, npm package
"@mathjax/src") and Speech Rule Engine (version 5),
presumably via the node package manager, `npm`.

### `mj-sre-page`
A `node` Javascript program to generate representations of
mathematics as MathML, SVG, braille, and speech.

### `update-sre`
bash script to manage npm installs, so SRE is not pinned to MJ.

### `package.json`
Manages dependencies for npm installs.
