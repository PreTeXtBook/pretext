PreTeXt Showcase
================

This directory contains the components for the PreTeXt
Showcase document.  These notes are primarly for contributors.

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

Notes:
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