# Contributing to the *Basics Reference* portion of The PreTeXt Guide

## `xml:id` usage

* Add `xml:id`s to all divisions and listings (at a minimum).
* Within the *Basics Reference*, please ensure that your `xml:id`s begin with "basics".
* Within the *Basics Reference*, use `ch` for chapter, `s` for section, `ss` for subsection, `l` for listing, and `fig` for figure when constructing `xml:id`s.
* An `xref` to another portion of the *Basics Reference* can be done via something like `<xref ref="basics-ch-exercises"/>`.

## Cross references to other parts of The Guide

* To help readers develop an understanding for the delineation between the parts of the guide, state which part you are making a reference to. For instance, `The <pubtitle>Author's Guide</pubtitle>  (<xref ref="topic-cross-referencing"/>)
goes into greater detail` is the preferred style of making an `xref` out of the *Basics Reference*.
* We encourage contributors to add lots of cross references. The *Basics Reference* is not meant to be the ultimate guide to every feature of PreTeXt.

## Code snippets

* Unless demonstrating something such as inline math or a cross reference that must live within a `p`, you are expected to put your code snippet in a separate file with extension `.ptx`.
* Follow the model done in existing sections to use `xi:include` twice, once with `@parse="text"` (always within a listing) and once without setting `@parse`. This allows the reader to see how the code is rendered by the PreTeXt converters.

## Index entries

* The initial indexing of the *Basics Reference* is being done by Matt Boelkins, Mitch Keller, and Oscar Levin based on extensive conversations with a larger group at the Portland workshop in 2019. **Please do not add additional `idx` tags to existing portions of the *Basics Reference* while this bullet remains in the `README.md` file.**
* Code snippets contained in `listing` are required to have at least two index entries. One should have main heading `<pretext/> code for` and subheading that identifies what it is the PreTeXt code for. The second must have the appropriate main heading to identify what the sampmle code for and subheading `<pretext/> code for`.
* Use `see` and `seealso` liberally in your indexing. Try to think of any other (nontechnical) terms someone might use to look up an idea and put the appropriate `see` entry in the index. For instance, we have "problem" as an index heading with with "as homework" as the subheading. This points the reader to see exercise.
* When referring to a PreTeXt tag or attribute in the index, use `<tag>` or `<attr>` as appropriate. Also ensure that you use `@sortby` in these cases, as otherwise the index isn't sorted correctly. For instance, you might use something like `<idx sortby="example"><tag>example</tag></idx>` to create a top-level index entry for the PreTeXt example tag.
* The various "-like" elements need to be indexed carefully. The main index entry needs to follow the lead of example-like elements, which is presented (in output) as "example-like elements (<example>, <problem>, <question>)". When using `<see>` or `<seealso>` to point to a "-like" category, use only the portion that does not list the tags (e.g., `<see>example-like elements</see>`. For the top-level `<pretext/> code for` index entry, the subheading for a "-like" element should be comprehensive: `<idx><h sortby="pretext code for"><pretext/> code for</h><h>example-like elements (<tag>example</tag>, <tag>problem</tag>, <tag>question</tag>)</h></idx>`. This allows a user of the index to scan and realize that if they want to create a `<question>` element, then they can copy the listing given for the example-like elements and change `example` to `question`.
