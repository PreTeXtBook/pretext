<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64"
    version="1.0">
    <xsl:output method="text"/>
    <xsl:include href="base64.xsl"/>
    <xsl:template match="/">
        <xsl:text>&#x0A;--Simple decode english text from base64 (basic function)  </xsl:text>
        <xsl:text>&#x0A;decoded is equal hello_dude-awesome.ru?  </xsl:text>
        <xsl:call-template name="b64:decode">
            <xsl:with-param name="base64String" select="'aGVsbG9fZHVkZS1hd2Vzb21lLnJ1'"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:text>&#x0A;--Simple decode russain text from base64 (new function)  </xsl:text>
        <xsl:text>&#x0A;decoded is equal приве-т.рф?  </xsl:text>
        <xsl:call-template name="b64:decode">
            <xsl:with-param name="base64String" select="'0L/RgNC40LLQtS3Rgi7RgNGE'"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:text>&#x0A;--Testing mixing text with == at the end of hash and english letter at the end of original text</xsl:text>
        <xsl:text>&#x0A;decoded is equal hello_dude-awesome-какой-то текст здесьdsfdsf.рфdsf (==) </xsl:text>
        <xsl:call-template name="b64:decode">
            <xsl:with-param name="base64String" select="'aGVsbG9fZHVkZS1hd2Vzb21lLdC60LDQutC+0Lkt0YLQviDRgtC10LrRgdGCINC30LTQtdGB0Yxkc2Zkc2Yu0YDRhGRzZg=='"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:text>&#x0A;--Testing mixing text with == at the end of hash and russian letter at the end of original text</xsl:text>
        <xsl:text>&#x0A;decoded is equal hello_dude-awesome-какой-то текст здесьdsfdsf.рф (==)  </xsl:text>
        <xsl:call-template name="b64:decode">
            <xsl:with-param name="base64String" select="'aGVsbG9fZHVkZS1hd2Vzb21lLdC60LDQutC+0Lkt0YLQviDRgtC10LrRgdGCINC30LTQtdGB0Yxkc2Zkc2Yu0YDRhA=='"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:text>&#x0A;--Testing mixing text with = at the end of hash and english letter at the end of original text</xsl:text>
        <xsl:text>&#x0A;decoded is equal hello_dude-awesome-какой-то текст здесьdsfdsf.рфdsfd (=)  </xsl:text>
        <xsl:call-template name="b64:decode">
            <xsl:with-param name="base64String" select="'aGVsbG9fZHVkZS1hd2Vzb21lLdC60LDQutC+0Lkt0YLQviDRgtC10LrRgdGCINC30LTQtdGB0Yxkc2Zkc2Yu0YDRhGRzZmQ='"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:text>&#x0A;--Testing mixing text with = at the end of hash and russian letter at the end of original text</xsl:text>
        <xsl:text>&#x0A;decoded is equal hello_dude-awesome-какой-то текст здесьdsfdsf.рфdsfdвам (=)  </xsl:text>
        <xsl:call-template name="b64:decode">
            <xsl:with-param name="base64String" select="'aGVsbG9fZHVkZS1hd2Vzb21lLdC60LDQutC+0Lkt0YLQviDRgtC10LrRgdGCINC30LTQtdGB0Yxkc2Zkc2Yu0YDRhGRzZmTQstCw0Lw='"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:text>&#x0A;--Testing mixing text with == at the end of hash, russain letter at begining and at the end of original text</xsl:text>
        <xsl:text>&#x0A;decoded is equal вhello_dude-awesome-какой-то текст здесьdsfdsf.рфdsfdвам (==)  </xsl:text>
        <xsl:call-template name="b64:decode">
            <xsl:with-param name="base64String" select="'0LJoZWxsb19kdWRlLWF3ZXNvbWUt0LrQsNC60L7QuS3RgtC+INGC0LXQutGB0YIg0LfQtNC10YHRjGRzZmRzZi7RgNGEZHNmZNCy0LDQvA=='"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:text>&#x0A;--Simple mixed text encoding (basic function)</xsl:text>
        <xsl:text>&#x0A;encoding 0LJoZWxsb19kdWRlLWF3ZXNvbWUt0LrQsNC60L7QuS3RgtC+INGC0LXQutGB0YIg0LfQtNC10YHRjGRzZmRzZi7RgNGEZHNmZNCy0LDQvA==  </xsl:text>
        <xsl:call-template name="b64:encode">
            <xsl:with-param name="asciiString" select="'вhello_dude-awesome-какой-то текст здесьdsfdsf.рфdsfdвам'"></xsl:with-param>
        </xsl:call-template>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:text>&#x0A;=================ORIGINAL TESTS=================</xsl:text>
        <xsl:text>&#x0A;encoded Man is </xsl:text>
        <xsl:call-template name="b64:encode">
            <xsl:with-param name="asciiString" select="'Man'"/>
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