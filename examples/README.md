# MathBook XML Examples

Some directories have their own `README`.  This is an overview of the contents of the `examples/` directory, with the date of the last update for each entry.

For several of these, sample output (PDF, HTML) is produced routinely and is available at the MathBook XML website from the "Examples" page.


### Sample Article (`sample-article/`)

The kitchen sink, this attempts to have one of everything.  Look around for something you need, experiment, or read the interspersed commentary on how things work.  (2016-02-20)


### Sample Book (`sample-book/`)

A forked version of the first three chapters of Tom Judson's "Abstract Algebra" textbook.  Use this to get ideas about how to create a book --- both how to organize the content and how to organize your files. (2016-02-20)


### Minimal Example (`minimal/`)

A short article.  This is a good place to test a problematic construction. This is also a good vehicle for filing helpful bug reports: adjust the source and send source and output.  (2016-02-20)


### Hello, World (`hello-world/`)

The bare minimum, about as little as you can do and still be valid MathBook XML.  (2016-02-20)


### WeBWorK (`webwork/`)

Several examples of how to author WeBWorK online homework problems within a MathBook XML book.  See the `Makefile` for guidance on how to build the examples.  (2016-02-20)


### Braille (`braille/`)

A fairly simple document to test the conversion of principal elements of a document into Braille.  (2019-02-17)


### Humanities in Action (`humanities/`)

Various exhibits of material authored in MathBook XML which might be of more interest to Humanities scholars.  Initiated by Jahrme Risner during his Summer 2016 undergraduate research project.  (2016-07-10)


### Characters, Fonts, and Languages (`fonts/`)

A testing and demonstration document similar to the sample article, but focused on print and PDF output in a variety of scripts and languages.  (2016-07-10)


### Pug (`pug`)

Pug (nee Jade) is a Javascript template engine, which can be employed easily to output MathBook XML source.  So if you prefer to format with whitespace, this could be a good choice.  "Normal" output is best, but using a `-P` flag provides better formatting of the XML output for human eyes.  Contributed by Harald Schilly.  (2016-05-21)

A subdirectory contains the original file for the Windows Installation Notes of the Author's Guide, contributed by Dave Rosoff.  It needs a few fixes, and will not be maintained, but will give a good demonstration of how a substantial chunk of content could be authored with Pug.  (2016-05-31)

### Letters (`letter/`)

A sample letter you can adapt to your needs.  See extensive comments in the source about using your letterhead.  (2016-02-20)


### Memoranda (`memo/`)

A sample memo you can adapt to your needs.  See extensive comments in the source about using your own logos.  (2016-02-20)
