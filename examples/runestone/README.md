# PreTeXt Runestone Testing

As of 2019-12-17, this is a fork of the PreTeXt "Sample Book" adjusted to test hosting via Runestone, and embedding interactive exercises.

## Building with a released version of PreTeXt

```
pip install pretextbook
cd /path/to/mathbook/examples/runestone
pretext build --input sample-runestone.xml --publisher ./publication.xml
```

## Building in a Development Environment


```
mkdir /tmp/rune /tmp/rune/html
cd /tmp/rune/html
cp -av /path/to/mathbook/examples/sample-book/images/ /path/to/mathbook/examples/sample-book/tikz/ /path/to/mathbook/examples/sample-book/code/ .

rm /knowl/*.html *.html
xsltproc -xinclude -stringparam publisher publication.xml /path/to/mathbook/xsl/pretext-html.xsl /path/to/mathbook/examples/runestone/sample-runestone.xml
```

## Installing the book into a Runestone Server

```
mkdir -p /path/to/RunestoneServer/books/ptxrs/published/ptxrs/_static
cp -r * /path/to/RunestoneServer/books/ptxrs/published/ptxrs
cp /path/to/RunestoneComponents/runestone/dist/runestone.js /path/to/RunestoneServer/books/ptxrs/published/ptxrs/_static
```

The rest of this must be done in a shell running in the container.  The easy way to start such a shell is to run `/path/to/RunestoneServer/scripts/dshell`  You will need to create a course in the database and then populate that course with the meta information about the book structure and all of the questions.


```
cd applications/runestone/books/ptxrs/published/ptxrs
rsmanage addcourse --course-name ptxrs --basecourse ptxrs
runestone process-manifest --course XXX

```