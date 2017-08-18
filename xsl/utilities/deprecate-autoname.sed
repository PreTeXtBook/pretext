# PreTeXt deprecations of xref/@autoname attribute
# Robert Beezer, 2017-07-25

# Sample usage on directory of *.xml files
# Converts from current directory to "newdir" subdirectory
#
# for f in *.xml; do echo $f; sed -f mathbook/xsl/utilities/deprecate-autoname.sed $f > newdir/$f; done


s/autoname="no"/text="global"/g
s/autoname = "no"/text = "global"/g

s/autoname="yes"/text="type-global"/g
s/autoname = "yes"/text = "type-global"/g

s/autoname="title"/text="title"/g
s/autoname = "title"/text = "title"/g

