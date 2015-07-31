<?xml version="1.0" encoding="UTF-8"?>
<!--
	Authors:
		Ilya Kharlamov
		Mukul Gandhi
		rzrbld
	Released under the MIT license
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:local="http://localhost/base64.xsl"
	xmlns:b64="https://github.com/ilyakharlamov/xslt_base64" 
	xmlns:test="http://localhost/test">
	<xsl:variable name="binarydatamap" select="document('base64_binarydatamap.xml')"/>
	<xsl:key name="binaryToBase64" match="item" use="binary" />
	<xsl:key name="asciiToBinary" match="item" use="ascii" />

	<!-- Template to convert the Ascii string into base64 representation -->
	<xsl:template name="b64:encode">
		<xsl:param name="asciiString"/>
		<xsl:param name="padding" select="true()"/>
		<xsl:param name="urlsafe" select="false()"/>
		<xsl:variable name="result">
			<xsl:variable name="binary">
				<xsl:call-template name="local:asciiStringToBinary">
					<xsl:with-param name="string" select="$asciiString"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="local:binaryToBase64">
				<xsl:with-param name="binary" select="$binary"/>
				<xsl:with-param name="padding" select="$padding"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$urlsafe">
				<xsl:value-of select="translate($result,'+/','-_')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$result"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="local:binaryToBase64">
		<xsl:param name="binary"/>
		<xsl:param name="padding"/>
		<xsl:call-template name="local:sixbitToBase64">
			<xsl:with-param name="sixbit" select="substring($binary, 1, 6)"/>
			<xsl:with-param name="padding" select="$padding"/>
		</xsl:call-template>
		<xsl:call-template name="local:sixbitToBase64">
			<xsl:with-param name="sixbit" select="substring($binary, 7, 6)"/>
			<xsl:with-param name="padding" select="$padding"/>
		</xsl:call-template>
		<xsl:call-template name="local:sixbitToBase64">
			<xsl:with-param name="sixbit" select="substring($binary, 13, 6)"/>
			<xsl:with-param name="padding" select="$padding"/>
		</xsl:call-template>
		<xsl:call-template name="local:sixbitToBase64">
			<xsl:with-param name="sixbit" select="substring($binary, 19, 6)"/>
			<xsl:with-param name="padding" select="$padding"/>
		</xsl:call-template>
		<xsl:variable name="remaining" select="substring($binary, 25)"/>
		<xsl:if test="$remaining != ''">
			<xsl:call-template name="local:binaryToBase64">
				<xsl:with-param name="binary" select="$remaining"/>
				<xsl:with-param name="padding" select="$padding"/>
			</xsl:call-template>
		</xsl:if>		
	</xsl:template>
	
	<xsl:template name="local:sixbitToBase64">
		<xsl:param name="sixbit"/>
		<xsl:param name="padding"/>
		<xsl:variable name="realsixbit">
			<xsl:value-of select="$sixbit"/>
			<xsl:if test="string-length($sixbit)=1">00000</xsl:if>
			<xsl:if test="string-length($sixbit)=2">0000</xsl:if>
			<xsl:if test="string-length($sixbit)=3">000</xsl:if>
			<xsl:if test="string-length($sixbit)=4">00</xsl:if>
			<xsl:if test="string-length($sixbit)=5">0</xsl:if>
		</xsl:variable>
		<xsl:for-each select="$binarydatamap">
			<xsl:value-of select="key('binaryToBase64', $realsixbit)/base64"/>
		</xsl:for-each>
		<xsl:if test="string-length($realsixbit) = 0 and $padding">=</xsl:if>
	</xsl:template>

	<!-- Template to convert a binary number to decimal representation; this template calls template pow -->
	<xsl:template name="local:binaryToDecimal">
		<xsl:param name="binary"/>
		<xsl:param name="sum" select="0"/>
		<xsl:param name="index" select="0"/>
		<xsl:choose>
			<xsl:when test="substring($binary,string-length($binary) - 1) != ''">
				<xsl:variable name="power">
					<xsl:call-template name="local:pow">
						<xsl:with-param name="m" select="2"/>
						<xsl:with-param name="n" select="$index"/>
						<xsl:with-param name="result" select="1"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:call-template name="local:binaryToDecimal">
					<xsl:with-param name="binary"
						select="substring($binary, 1, string-length($binary) - 1)"/>
					<xsl:with-param name="sum"
						select="$sum + substring($binary,string-length($binary) ) * $power"/>
					<xsl:with-param name="index" select="$index + 1"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$sum"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="local:pow">
		<xsl:param name="m"/>
		<xsl:param name="n"/>
		<xsl:param name="result"/>
		<xsl:choose>
			<xsl:when test="$n = 0">
				<xsl:value-of select="$result"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="local:pow">
					<xsl:with-param name="m" select="$m"/>
					<xsl:with-param name="n" select="$n - 1"/>
					<xsl:with-param name="result" select="$result * $m"/>
				</xsl:call-template>				
			</xsl:otherwise>			
		</xsl:choose>
		
	</xsl:template>

	<!-- Template to convert an ascii string to binary representation; this template calls template decimalToBinary -->
	<xsl:template name="local:asciiStringToBinary">
		<xsl:param name="string"/>
		<xsl:variable name="char" select="substring($string, 1, 1)"/>
		<xsl:if test="$char != ''">
			<xsl:for-each select="$binarydatamap">
				<xsl:value-of select="key('asciiToBinary', $char)/binary"/>
			</xsl:for-each>
		</xsl:if>
		<xsl:variable name="remaining" select="substring($string, 2)"/>
		<xsl:if test="$remaining != ''">
			<xsl:call-template name="local:asciiStringToBinary">
				<xsl:with-param name="string" select="$remaining"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<!-- Template to convert a decimal number to binary representation -->
	<xsl:template name="local:decimalToBinary">
		<xsl:param name="decimal"/>
		<xsl:param name="prev" select="''"/>

		<xsl:variable name="divresult" select="floor($decimal div 2)"/>
		<xsl:variable name="modresult" select="$decimal mod 2"/>
		<xsl:choose>
			<xsl:when test="$divresult &gt; 1">
				<xsl:call-template name="local:decimalToBinary">
					<xsl:with-param name="decimal" select="$divresult"/>
					<xsl:with-param name="prev" select="concat($modresult, $prev)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$divresult = 0">
				<xsl:value-of select="concat($modresult, $prev)"/>
			</xsl:when>
			<xsl:when test="$divresult = 1">
				<xsl:text>1</xsl:text>
				<xsl:value-of select="concat($modresult, $prev)"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<!-- Template to convert the base64 string to ascii representation -->
	<xsl:template name="b64:decode">
		<xsl:param name="base64String"/>
		<!-- support for urlsafe -->
		<xsl:variable name="base64StringUniversal" select="translate($base64String, '-_','+/')"/>
		<!-- execute if last 2 characters do not contain = character-->
		<xsl:if
			test="not(contains(substring($base64StringUniversal, string-length($base64StringUniversal) - 1), '='))">
			<xsl:variable name="binaryBase64String">
				<xsl:call-template name="local:base64StringToBinary">
					<xsl:with-param name="string" select="$base64StringUniversal"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="local:base64BinaryStringToAscii">
				<xsl:with-param name="binaryString" select="$binaryBase64String"/>
			</xsl:call-template>
		</xsl:if>

		<!-- extract last two characters -->
		<xsl:variable name="secondLastChar"
			select="substring($base64StringUniversal, string-length($base64StringUniversal) - 1, 1)"/>
		<xsl:variable name="lastChar"
			select="substring($base64StringUniversal, string-length($base64StringUniversal), 1)"/>

		<!-- execute if 2nd last character is not a =, and last character is = -->
		<xsl:if test="($secondLastChar != '=') and ($lastChar = '=')">
			<xsl:variable name="binaryBase64String">
				<xsl:call-template name="local:base64StringToBinary">
					<xsl:with-param name="string" select="substring-before($base64StringUniversal,'=')" />
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="local:base64BinaryStringToAscii">
				<xsl:with-param name="binaryString" select="$binaryBase64String"/>
			</xsl:call-template>
			<xsl:variable name="partialBinary">
				<xsl:call-template name="local:base64StringToBinary">
					<xsl:with-param name="string" select="substring($base64StringUniversal, string-length($base64StringUniversal) - 3, 3)"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="local:base64BinaryStringToAscii">
				<xsl:with-param name="binaryString" select="substring($partialBinary, 1, 6)"/>
			</xsl:call-template>
		</xsl:if>

		<!-- execute if last 2 characters are both = -->
		<xsl:if test="($secondLastChar = '=') and ($lastChar = '=')">
			<!-- xsl:text>this is == </xsl:text -->
			
			<xsl:variable name="binaryBase64String">
				<xsl:call-template name="local:base64StringToBinary">
					<!-- xsl:with-param name="string" select="substring($base64StringUniversal, 1, string-length($base64StringUniversal) - 4)" / -->
					<xsl:with-param name="string" select="substring-before($base64StringUniversal,'==')" />
				</xsl:call-template>
			</xsl:variable>
			<!-- xsl:value-of select="substring-before($base64StringUniversal,'==')"/ -->
			<xsl:call-template name="local:base64BinaryStringToAscii">
				<xsl:with-param name="binaryString" select="$binaryBase64String"/>
			</xsl:call-template>
			<xsl:variable name="partialBinary">
				<xsl:call-template name="local:base64StringToBinary">
					<xsl:with-param name="string" select="substring($base64StringUniversal, string-length($base64StringUniversal) - 3, 2)"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="local:base64BinaryStringToAscii">
				<xsl:with-param name="binaryString" select="substring($partialBinary, 1, 7)"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<!-- Template to convert the base64 binary string to ascii representation -->
	<xsl:template name="local:base64BinaryStringToAscii">
		<xsl:param name="binaryString"/>
		<xsl:variable name="binaryPortion16" select="substring($binaryString, 1, 16)"/>
		<xsl:variable name="binaryPortion8" select="substring($binaryString, 1, 8)"/>
		<xsl:if test="$binaryPortion8 != ''">
			<xsl:variable name="decoded8" select="$binarydatamap/datamap/asciibinary/item[binary = $binaryPortion8]/ascii"/>
			<xsl:variable name="decoded16" select="$binarydatamap/datamap/asciibinary/item[binary = $binaryPortion16]/ascii"/>
			<xsl:choose>
				<xsl:when test="$decoded8 != ''">
					<!-- xsl:text>(8)</xsl:text -->
					<xsl:value-of select="$decoded8"/>
					<xsl:call-template name="local:base64BinaryStringToAscii">
						<xsl:with-param name="binaryString" select="substring($binaryString, 9)"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<!-- xsl:text>(16)</xsl:text -->
					<xsl:value-of select="$decoded16"/>
					<xsl:call-template name="local:base64BinaryStringToAscii">
						<xsl:with-param name="binaryString" select="substring($binaryString, 17)"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
			
		</xsl:if>
	</xsl:template>
	<!-- Template to convert a base64 string to binary representation; this template calls template decimalToBinary -->
	<xsl:template name="local:base64StringToBinary">
		<xsl:param name="string"/>
		<xsl:variable name="base64Portion" select="substring($string, 1, 1)"/>
		<xsl:if test="$base64Portion != ''">
			<xsl:variable name="binary" select="$binarydatamap/datamap/binarybase64/item[base64 = $base64Portion]/binary"/>
			<xsl:call-template name="local:padZeros">
				<xsl:with-param name="string" select="$binary"/>
				<xsl:with-param name="no" select="6 - string-length($binary)"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="substring($string, 2) != ''">
			<xsl:call-template name="local:base64StringToBinary">
				<xsl:with-param name="string" select="substring($string, 2)"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<!-- Template to left pad a binary string, with the specified no of 0s, to make it of length 6 -->
	<xsl:template name="local:padZeros">
		<xsl:param name="string"/>
		<xsl:param name="no"/>

		<xsl:if test="$no &gt; 0">
			<xsl:call-template name="local:padZeros">
				<xsl:with-param name="string" select="concat('0', $string)"/>
				<xsl:with-param name="no" select="6 - string-length($string) - 1"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="$no = 0">
			<xsl:value-of select="$string"/>
		</xsl:if>
	</xsl:template>



</xsl:stylesheet>
