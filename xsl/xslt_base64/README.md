#README 
----------------
1. description
2. requirement
3. example
4. contact
5. license

#descrption
Library to represent binary data in an ASCII characters.
Base64-encoded data takes about 33% more space than the original data.
Allows encoding and decoding.
Support english and russian letters for decoding, 
other languages can simply add by editing base64_binarydatamap.xml

#requirements
an app that can do xsl transformation

#example:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64"
    version="1.0">
    <xsl:output method="text"/>
    <xsl:include href="base64.xsl"/>
    <xsl:template match="/">
        <xsl:text>encoded Man is </xsl:text>
        <xsl:call-template name="b64:encode">
            <xsl:with-param name="asciiString" select="'Man'"/>
        </xsl:call-template>
		<xsl:text>&#x0A;encoded Человек is </xsl:text>
        <xsl:call-template name="b64:encode">
            <xsl:with-param name="asciiString" select="'Человек'"/>
        </xsl:call-template>
        <xsl:text>&#x0A;encoded 1 with padding is </xsl:text>
        <xsl:call-template name="b64:encode">
            <xsl:with-param name="asciiString" select="'1'"/>
        </xsl:call-template>
        <xsl:text>&#x0A;encoded 1 without padding is </xsl:text>
        <xsl:call-template name="b64:encode">
            <xsl:with-param name="asciiString" select="'1'"/>
            <xsl:with-param name="padding" select="false()"/>
        </xsl:call-template>
        <xsl:text>&#x0A;encoded ..a?&lt;&gt;???!????? as regular is </xsl:text>
        <xsl:call-template name="b64:encode">
            <xsl:with-param name="asciiString" select="'..a?&lt;&gt;???!?????'"/>
        </xsl:call-template>
        <xsl:text>&#x0A;encoded ..a?&lt;&gt;???!????? as urlsafe is </xsl:text>
        <xsl:call-template name="b64:encode">
            <xsl:with-param name="asciiString" select="'..a?&lt;&gt;???!?????'"/>
            <xsl:with-param name="urlsafe" select="true()"/>
        </xsl:call-template>
        <xsl:text>&#x0A;decoded MQ== is </xsl:text>
        <xsl:call-template name="b64:decode">
            <xsl:with-param name="base64String" select="'MQ=='"></xsl:with-param>
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>
```

Output:
<pre>encoded Man is TWFu
encoded 1 with padding is MQ==
encoded 1 without padding is MQ
encoded ..a?<>???!????? as regular is Li5hPzw+Pz8/IT8/Pz8/
encoded ..a?<>???!????? as urlsafe is Li5hPzw-Pz8_IT8_Pz8_
decoded MQ== is 1</pre>

Also supports 'url safe' and 'no padding' syntax via params to b64:encode template

#contact
razblade@gmail.com,
ilyakharlamov@gmail.com

#license
The MIT License (MIT)

Copyright (c) 2012,2013

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


