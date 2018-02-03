# PreTeXt deprecations of index creation elements
# Robert Beezer, 2017-07-14

# Sample usage on directory of *.xml files
# Converts from current directory to "newdir" subdirectory
#
# for f in *.xml; do echo $f; sed -f mathbook/xsl/utilities/deprecate-index.sed $f > newdir/$f; done


# First, protect elements that begin with "index"
# so "index" match below will not affect them
s/<index-part/PARTPART/g
s/<\/index-part>/PARTENDPARTEND/g
s/<index-list/LISTLIST/g

# index -> idx
s/<index/<idx/g
s/<\/index>/<\/idx>/g

# main -> h
s/<main/<h/g
s/<\/main>/<\/h>/g

# sub -> h
# careful not to clobber <subsection>, etc.
s/<sub /<h /g
s/<sub>/<h>/g
s/<\/sub>/<\/h>/g

# Remove protection, convert to new elements
s/PARTPART/<index/g
s/PARTENDPARTEND/<\/index>/g
s/LISTLIST/<index-list/g
