# Workbook Example

To extract the worksheets from this PreTeXt book into .odt (Open Office) files,
use the pretext-worksheet-odt.xsl stylesheet. This will build a folder tree with
root `worksheets/` where the leaves are file components of an Open Office file.
These component files must be zipped into a .odt file to be opened by, say, 
LibreOffice. The command is:
`zip -r -X filename.odt mimetype content.xml settings.xml meta.xml style.xml META-INF`
