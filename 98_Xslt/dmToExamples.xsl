<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet	version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
    xmlns:specgen="http://sifassociation.org/SpecGen"
	xmlns:xfn="http://stuart.geek.nz/xslt-functions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:json="http://json.org/">

	<!-- Take a SIF_DataModel.input.xml file and produce a matching OpenAPI v3.0.0 spec -->
	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

	<xsl:param name="sifVersion"/>
	<xsl:param name="sifLocale"/>
	<xsl:param name="sifObjectList" select="''"/> <!-- Default to empty list -->

	<xsl:import href="./sif2jsonspecgen.xslt"/>
	<xsl:import href="./xmlToJson-goessner.xslt"/>
		
	<xsl:template match="/specgen:SIFSpecification">
		<xsl:text># // Data Model Example file for:&#x0a;</xsl:text>
		<xsl:value-of select="concat('# // Locale: ', $sifLocale, '&#x0a;')"/>
		<xsl:value-of select="concat('# // SIF Datamodel Version: ', $sifVersion, '&#x0a;')"/>
		<xsl:value-of select="concat('# // Limited to Objects: ', $sifObjectList, '&#x0a;')"/>
		<xsl:text>&#x0a;</xsl:text>
	
		<xsl:apply-templates select=".//specgen:DataObjects" mode="objectExamples"/>
	</xsl:template>
	
	<!-- ======================== -->
	<!-- Section: Object Examples -->
	<!-- ======================== -->
	<xsl:template match="specgen:DataObjects" mode="objectExamples">
		<!--xsl:result-document href="{$exampleFileName}"-->
			<xsl:text>&#x0a;</xsl:text>
			<xsl:text># /////////////////////&#x0a;</xsl:text>
			<xsl:text># // Object Examples //&#x0a;</xsl:text>
			<xsl:text># /////////////////////&#x0a;</xsl:text>
			<xsl:text>objectExamples:&#x0a;</xsl:text>
			<xsl:apply-templates select=".//specgen:DataObject" mode="objectExamples"/>
		<!--/xsl:result-document-->
	</xsl:template>

	<xsl:template match="specgen:DataObject" mode="objectExamples">
		<xsl:if test="xfn:containsOrEmpty($sifObjectList, @name)">
			<xsl:variable name="excludeOps" select="specgen:OpenAPI/specgen:ExcludeOperations"/>
	
			<xsl:if test="not(contains($excludeOps,'ALL'))">
				<xsl:apply-templates select="." mode="singleExample"/>
				<xsl:apply-templates select="." mode="collectionExample"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<!-- ============================================ -->
	<!-- Template for producing Single Object Example -->
	<!-- ============================================ -->
	<xsl:template match="specgen:DataObject" mode="singleExample">
		<xsl:text>  #//&#x0a;</xsl:text>
		<xsl:value-of select="concat('  #// ', @name, '&#x0a;')"/>
		<xsl:text>  #//&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', @name, ':&#x0a;')"/>
		<xsl:text>    pesc:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      summary: PESC notation for ', @name, '&#x0a;')"/>
		<xsl:text>      value:&#x0a;</xsl:text>
		<xsl:text>        {</xsl:text>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]/*" mode="detect"/>
		<xsl:text>}&#x0a;</xsl:text>
		<xsl:text>    goessner:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      summary: Goessner notation for ', @name, '&#x0a;')"/>
		<xsl:text>      value:&#x0a;</xsl:text>
		<xsl:text>        </xsl:text>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]/*" mode="goessner"/>
		<xsl:text>&#x0a;</xsl:text>
		<xsl:text>    xml:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      summary: XML ', @name, '&#x0a;')"/>
		<xsl:text>      value: >-&#x0a;</xsl:text>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="xml">
			<xsl:with-param name="pfx"><xsl:text>        </xsl:text></xsl:with-param>
			<xsl:with-param name="excludeExampleTag">true</xsl:with-param>
		</xsl:apply-templates>
		<xsl:text>&#x0a;</xsl:text>
	</xsl:template>

	<!-- ================================================ -->
	<!-- Template for producing Collection Object Example -->
	<!-- ================================================ -->
	<xsl:template match="specgen:DataObject" mode="collectionExample">
		<xsl:text>  #//&#x0a;</xsl:text>
		<xsl:value-of select="concat('  #// ', @name, 's', '&#x0a;')"/>
		<xsl:text>  #//&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', @name, 's:&#x0a;')"/>
		<xsl:text>    pesc:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      summary: PESC notation for ', @name, 's&#x0a;')"/>
		<xsl:text>      value:&#x0a;</xsl:text>
		<xsl:value-of select="concat('        {', $q, @name, 's', $q, ': {')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]/*" mode="detect"/>
		<xsl:text>}}</xsl:text>
		<xsl:text>&#x0a;</xsl:text>
		<xsl:text>    goessner:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      summary: Goessner notation for ', @name, 's&#x0a;')"/>
		<xsl:text>      value:&#x0a;</xsl:text>
		<xsl:value-of select="concat('        {', $q, @name, 's', $q, ': ')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]/*" mode="goessner"/>
		<xsl:text>}</xsl:text>
		<xsl:text>&#x0a;</xsl:text>
		<xsl:text>    xml:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      summary: XML ', @name, 's&#x0a;')"/>
		<xsl:text>      value: >-&#x0a;</xsl:text>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="xmlList">
			<xsl:with-param name="pfx"><xsl:text>        </xsl:text></xsl:with-param>
			<xsl:with-param name="excludeExampleTag">true</xsl:with-param>
		</xsl:apply-templates>
		<xsl:text>&#x0a;</xsl:text>
	</xsl:template>

	<xsl:template match="xhtml:Example" mode="xml">
		<xsl:param name="pfx"/>
		<xsl:param name="excludeExampleTag"/>

		<xsl:if test="$excludeExampleTag eq 'true'">
			<xsl:value-of select="xfn:xmlString(*, $pfx, 0)"/>
		</xsl:if>
		<xsl:if test="not($excludeExampleTag eq 'true')">
			<xsl:value-of select="concat($pfx, 'example: &gt;-&#x0a;')"/>
			<!--xsl:value-of select="concat($pfx, 'xml:&#x0a;')"/-->
			<xsl:value-of select="xfn:xmlString(*, concat($pfx, '  '), 0)"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="xhtml:Example" mode="xmlList">
		<xsl:param name="pfx"/>
		<xsl:param name="excludeExampleTag"/>

		<xsl:if test="$excludeExampleTag eq 'true'">
			<xsl:value-of select="xfn:xmlString(*, $pfx, 1)"/>
		</xsl:if>
		<xsl:if test="not($excludeExampleTag eq 'true')">
			<xsl:value-of select="concat($pfx, 'example: &gt;-&#x0a;')"/>
			<!--xsl:value-of select="concat($pfx, 'xml:&#x0a;')"/-->
			<xsl:value-of select="xfn:xmlString(*, concat($pfx, '  '), 1)"/>
		</xsl:if>
	</xsl:template>

    <xsl:template match="node/@TEXT | text()" name="removeBreaks">
        <xsl:param name="pText" select="normalize-space(.)"/>
        <xsl:choose>
            <xsl:when test="not(contains($pText, '&#xA;'))"><xsl:copy-of select="$pText"/></xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat(substring-before($pText, '&#xD;&#xA;'), ' ')"/>
                <xsl:call-template name="removeBreaks">
                    <xsl:with-param name="pText" select="substring-after($pText, '&#xD;&#xA;')"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

	<!-- Custom function to tidy up URL -->
	<xsl:function name="xfn:cleanUrl" as="xs:string">
		<xsl:param name="inUrl"/>
		<xsl:value-of select="replace(replace($inUrl, ' ', ''), '&amp;', '')"/>
	</xsl:function>

	<!-- Custom function XML to string -->
	<xsl:function name="xfn:xmlString" as="xs:string">
		<xsl:param name="inXml"/>
		<xsl:param name="pfx"/>
		<xsl:param name="isCollection"/>

		<xsl:variable name="outStr">
			<xsl:apply-templates select="$inXml" mode="nodetostring">
				<xsl:with-param name="pfx" select="$pfx"/>
				<xsl:with-param name="isCollection" select="$isCollection"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:value-of select="$outStr"/>
	</xsl:function>

	<xsl:variable name="q">
		<xsl:text>"</xsl:text>
	</xsl:variable>
	<xsl:variable name="empty"/>

	<xsl:template match="* | text()" mode="nodetostring">
		<xsl:param name="pfx"/>
		<xsl:param name="isCollection" select="0"/>

		<xsl:if test="$isCollection">
			<xsl:value-of select="concat($pfx, '&lt;', name(), 's&gt;&#x0a;')"/>		
		</xsl:if>

		<xsl:variable name="pfx2">
			<xsl:choose>
				<xsl:when test="$isCollection"><xsl:value-of select="concat($pfx, '  ')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$pfx"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="boolean(name())">
				<xsl:choose>
					<!-- element has children -->
					<xsl:when test="*">
						<!--xsl:value-of select="concat($pfx2, '&lt;', name(), '&gt;&#x0a;')"/--> 
						<xsl:value-of select="concat($pfx2, '&lt;', name())"/>
						<xsl:apply-templates select="@*[not(namespace-uri() = 'http://json.org/')]" mode="attribs" />
						<xsl:value-of select="concat('&gt;', '&#x0a;')"/> 

						<xsl:apply-templates select="*" mode="nodetostring">
							<xsl:with-param name="pfx" select="concat($pfx2, '  ')"/>
						</xsl:apply-templates>
						<xsl:value-of select="concat($pfx2, '&lt;/', name(), '&gt;&#x0a;')"/>
					</xsl:when>
					<!--
						Just a text element 
					-->
					<xsl:otherwise>
						<!--xsl:value-of select="concat($pfx2, '&lt;', name(), '&gt;', normalize-space(.),'&lt;/', name(), '&gt;&#x0a;')"/--> 
						<xsl:value-of select="concat($pfx2, '&lt;', name())"/> 
						<xsl:apply-templates select="@*[not(namespace-uri() = 'http://json.org/')]" mode="attribs" />
						<xsl:value-of select="concat('&gt;', normalize-space(.),'&lt;/', name(), '&gt;&#x0a;')"/> 
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="$isCollection">
			<xsl:value-of select="concat($pfx, '&lt;/', name(), 's&gt;&#x0a;')"/>		
		</xsl:if>		
	</xsl:template>

	<xsl:template match="@*" mode="attribs">
		<xsl:if test="position() = 1">
			<xsl:text> </xsl:text>
		</xsl:if>
		<xsl:value-of select="concat(name(), '=', $q, ., $q)"/>
		<xsl:if test="position() != last()">
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>	

	<xsl:function name="json:encode-string" as="xs:string">
		<xsl:param name="string" as="xs:string"/>
		<xsl:sequence select="replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace($string,
				'\\','\\\\'),
				'&quot;', '\\&quot;'),
				'&#xA;','\\n'),
				'&#xD;','\\r'),
				'&#x9;','\\t'),
				'\n','\\n'),
				'\r','\\r'),
				'\t','\\t')"/>
	</xsl:function>

	<!-- returns true if value is not set or empty -->
	<xsl:function name="xfn:empty" as="xs:boolean">
		<xsl:param name="value"/>
		<xsl:sequence select="not($value != '')" />
	</xsl:function>

	<!-- returns true if listOfValues is empty or if the valueToCheck is in the given comma separated listOfValues -->
	<xsl:function name="xfn:containsOrEmpty" as="xs:boolean">
		<xsl:param name="listOfValues"/>
		<xsl:param name="valueToCheck"/>
		<xsl:sequence select="xfn:empty($listOfValues) or contains($listOfValues, $valueToCheck)" />
	</xsl:function>

</xsl:stylesheet>