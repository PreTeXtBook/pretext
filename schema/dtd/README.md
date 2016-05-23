# MathBook XML Document Type Definition

This can be employed in the following manner.  Look inside `mathbook.dtd` for more information

`xmllint --xinclude --postvalid --noout --dtdvalid schema/dtd/mathbook.dtd examples/sample-book/sample-book.xml 2> dtdinfo.txt`
