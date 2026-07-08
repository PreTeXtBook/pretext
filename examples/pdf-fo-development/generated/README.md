This is the managed directory for *generated* assets of the XSL-FO
development article (`source/directories/@generated` in
`publication.xml`).  Its `prefigure` subdirectory holds the diagram of
the "Images" section, born in `prefigure` source and converted to
several formats: an SVG (embedded by Apache FOP for the XSL-FO PDF, and
also used by the HTML and SVG-EPUB conversions), a PDF (for the
LaTeX-based print route), and a PNG (for the MathML/Kindle EPUB
variants).  Re-generate them with the `prefigure` graphics component of
the build.
