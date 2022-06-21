#PreTeXt Showcase Article

This folder contains the components for the PreTeXt
Showcase document.

##Building the Showcase Article

To build the PreTeXt Showcase article:
1. Install the PreTeXt CLI (https://github.com/PreTeXtBook/pretext-cli)
2. From this folder, run `pretext build html` or `pretext build pdf`
3. To view, run `pretext view html` or `pretext view pdf`

##Notes for Contributors

This example has several purposes:
* To demonstrate PreTeXt features
* To demonstrate best practices when authoring
* To serve as form of documentation for authors
who like to learn from examples

Therefore:
* Organize with division titles that promote browsing
* Highlight novel features of PreTeXt, which is not the
same as providing a comprehensive example
* Include comments in the source file where implementation
is not obvious, such as when settings in `docinfo` are necessary
* Please observe standards for high-quality source.
Running the pretty-printing script across the source
should only introduce minimal changes.
* Do not provide commentary or instruction, just provide
realistic examples.  For example, if demonstrating the markup
for scientific units:
  - Do not say, "And you can put units in the denominator, like m/sec^2."
  - Instead say, "The acceleration due to gravity is 9.8 m/sec^2."
* Review the existing documentation (in the Author's Guide)
for each new feature added, with an eye towards completeness
and correctness.
* Add any new generated assets (for example latex-images) to the
repository, including in all available formats.
* Do not commit insignificant changes to the assets. For example
some insignificant file diff stemming from using different hardware
while building latex-images.
