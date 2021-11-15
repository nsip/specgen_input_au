<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:specgen="http://sifassociation.org/SpecGen"
	xmlns:xfn="http://stuart.geek.nz/xslt-functions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xml="http://www.w3.org/XML/1998/namespace"
	xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl">

	<!-- Take a SIF_DataModel.input.xml file and produce a matching Json Schema -->
	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
	

	<!-- Shorthand to get a quote character into the output -->
	<xsl:variable name="q"><xsl:text>"</xsl:text></xsl:variable>
	<xsl:variable name="sq"><xsl:text>'</xsl:text></xsl:variable>


	<!-- ....and off we go -->
	<xsl:template match="/specgen:SIFSpecification">
		<xsl:value-of select="concat( '# &#x0a;',
                                      '## Json Schema derived from SIF ', $sifLocale, ' v', $sifVersion, '&#x0a;',
							          '# &#x0a;')"/> 

		<xsl:text>$schema: 'http://json-schema.org/draft-07/schema#'&#x0a;</xsl:text>
		<xsl:value-of select="concat('title: SIF ', $sifLocale, ' v', $sifVersion, '&#x0a;')"/>
		<xsl:value-of select="concat('description: JSON Schema derived from SIF ', $sifLocale, ' v', $sifVersion, '&#x0a;')"/>

		<xsl:apply-templates select=".//specgen:DataObjects" mode="rootObj"/>

		<xsl:text>definitions:&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObjects//specgen:DataObject" mode="definitions"/>

		<xsl:apply-templates select=".//specgen:Appendix[@name = 'Common Types']//specgen:CommonElement"/>
		<xsl:apply-templates select=".//specgen:Appendix[ends-with(@name, 'Code Sets')]//specgen:CodeSet"/>
	</xsl:template>


	<!-- Special rootObject, schema will validate an hetrogonous array of dataObjects... -->
	<xsl:template match="specgen:DataObjects" mode="rootObj">
		<xsl:text>type: array&#x0a;items:&#x0a;</xsl:text>

		<xsl:text>  oneOf:&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObject" mode="reqRootObj">
			<xsl:sort select="@name"/>
		</xsl:apply-templates>

		<xsl:text>properties:&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObject" mode="rootObj">
			<xsl:sort select="@name"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="specgen:DataObject" mode="reqRootObj">
		<xsl:value-of select="concat('  - required: [ ', @name, ' ]&#x0a;')"/>
	</xsl:template>
	
	<xsl:template match="specgen:DataObject" mode="rootObj">
		<xsl:value-of select="concat('  ', @name, ':&#x0a;')"/>
		<xsl:value-of select="concat('    $ref: ''#/definitions/', @name, '''&#x0a;')"/>
		<xsl:text>&#x0a;</xsl:text>
	</xsl:template>

	<xsl:template match="specgen:DataObject" mode="definitions">
		<xsl:text>  # //////////////////////////////// data object /////////////////////////////&#x0a;</xsl:text>
		<!-- First up the collection edition -->
		<xsl:value-of select="concat('  ', @name, 'Collection:&#x0a;',
									 '    type: object&#x0a;',
									 '    properties:&#x0a;',
									 '      ', @name , ':&#x0a;',
									 '        type: array&#x0a;',
									 '        items:&#x0a;',
									 '          $ref: ''#/definitions/', @name, '''&#x0a;')"/>


		<!-- Now do the actual dataObject definition --> 
		<xsl:value-of select="concat('  ', @name, ':&#x0a;')"/>

		<!-- Maybe some fields are required -->
		<xsl:if test="$mandatoryFields = 'required'">
			<xsl:variable name="req">
				<xsl:apply-templates select="specgen:Item|//specgen:CommonElement[@name = current()/specgen:Item[1]/specgen:Type/@name]/specgen:Item" mode="required">
					<xsl:sort select="specgen:Element|specgen:Attribute"/>
				</xsl:apply-templates>
			</xsl:variable>
			<xsl:if test="string-length($req) gt 0">
				<xsl:value-of select="concat('    required:&#x0a;', $req)"/>
			</xsl:if>
		</xsl:if>

		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>

		<!-- DataObject maybe extension of a base type -->
		<!--xsl:text>#DEBUG: DataObject maybe extension of a base type - check for specgen:Item[1]/specgen:Type[@complex]&#x0a;</xsl:text-->
		<!--xsl:if test="specgen:Item[1]/specgen:Type[@complex]"-->
		<xsl:if test="specgen:Item[1]/specgen:Type/@complex">
			<!--xsl:text>#DEBUG: check: true&#x0a;</xsl:text-->
			<xsl:value-of select="concat('    type: object&#x0a;',
			                             '    description: &gt;-&#x0a;',
			                             '      ', $desc, '&#x0a;',
										 '#   allOfA:&#x0a;',
										 '    $ref: ''#/definitions/', xfn:chopType(specgen:Item[1]/specgen:Type/@name), '''&#x0a;')"/>
			<!--xsl:value-of select="concat('    type: object&#x0a;',
										 '    allOfA:&#x0a;',
										 '    - $ref: ''#/definitions/', xfn:chopType(specgen:Item[1]/specgen:Type/@name), '''&#x0a;',
										 '    - properties:&#x0a;')"/-->
		</xsl:if>

		<!-- DataObject may not be an extension -->
		<!--xsl:if test="not(specgen:Item[1]/specgen:Type[@complex])"-->
		<xsl:if test="not(specgen:Item[1]/specgen:Type/@complex)">
			<!--xsl:text>#DEBUG: check: false&#x0a;</xsl:text-->
			<xsl:text>    type: object&#x0a;</xsl:text>
			<xsl:if test="count(specgen:Item) gt 1">
				<xsl:text>    properties:&#x0a;</xsl:text>
			</xsl:if>
		</xsl:if>

		<!-- Work out the indent for properties -->
		<xsl:variable name="objIndent">
			<xsl:choose>
				<!--xsl:when test="specgen:Item[1]/specgen:Type[@complex]"-->
				<xsl:when test="specgen:Item[1]/specgen:Type/@complex">
				    <!--xsl:text>#DEBUG: Work out the indent - true&#x0a;          </xsl:text-->
				    <xsl:text>          </xsl:text>
				</xsl:when>
				<xsl:otherwise>
				    <!--xsl:text>#DEBUG: Work out the indent - false&#x0a;      </xsl:text-->
				    <xsl:text>      </xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:apply-templates select="specgen:Item[position() gt 1]">
			<xsl:with-param name="indent" select="$objIndent"/>
		</xsl:apply-templates>

		<!--xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable-->
		<!--xsl:if test="not(specgen:Item[1]/specgen:Type[@complex])"-->
		<xsl:if test="not(specgen:Item[1]/specgen:Type/@complex)">
			<xsl:if test="string-length($desc) gt 0">
				<xsl:value-of select="concat('    description: &gt;-&#x0a;      ', $desc, '&#x0a;')"/>
			</xsl:if>
			<!--xsl:text>#DEBUG: not(specgen:Item[1]/specgen:Type[@complex] - true - add desc if available&#x0a;</xsl:text-->
		</xsl:if>
	</xsl:template>
	
	<!-- Common type is empty extension of another type -->
	<xsl:template match="specgen:CommonElement[count(specgen:Item) eq 1 and
						 specgen:Item[1]/specgen:Type/@complex eq 'extension']">
		<xsl:text>&#x0a;  # /////////////////////////////// empty extn ///////////////////////////&#x0a;</xsl:text>
		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>
		
		<xsl:if test="string-length($desc) gt 0">
			<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;',
										 '#     allOfB:&#x0a;',
										 '      type: object&#x0a;',
										 '      description: &gt;-&#x0a;',
										 '        ', $desc, '&#x0a;',
								         '      $ref: ''#/definitions/', xfn:chopType(specgen:Item[1]/specgen:Type/@name), '''&#x0a;')"/>
		</xsl:if>
		<xsl:if test="string-length($desc) eq 0">
			<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;',
										 '#     allOfB:&#x0a;',
										 '      type: object&#x0a;',
								         '      $ref: ''#/definitions/', xfn:chopType(specgen:Item[1]/specgen:Type/@name), '''&#x0a;')"/>
		</xsl:if>
	</xsl:template>

	<!-- Common type is EMPTY with a collection of attributes -->
	<xsl:template priority="2" match="specgen:CommonElement[count(specgen:Item) gt 1 and
	                     specgen:Item[1]/specgen:Type/@name eq 'EMPTY' and
						 count(specgen:Item[position() gt 1]) eq count(specgen:Item[specgen:Attribute]) ]">
		<xsl:text>&#x0a;  # ////////////////////////// EMPTY with attrs ///////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;',
									 '    type: object&#x0a;',
									 '    properties:&#x0a;')"/>

		<xsl:apply-templates select="specgen:Item[position() gt 1]">
			<xsl:with-param name="indent" select="'      '"/>
		</xsl:apply-templates>

		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>
		<xsl:if test="string-length($desc) gt 0">
			<xsl:value-of select="concat('      - description: &gt;-&#x0a;          ', $desc, '&#x0a;')"/>
		</xsl:if>
	</xsl:template>

	<!-- Common type is an attribute only extension of another type -->
	<xsl:template match="specgen:CommonElement[count(specgen:Item) gt 1 and
	                     specgen:Item[1]/specgen:Type/@complex eq 'extension' and
						 count(specgen:Item[position() gt 1]) eq count(specgen:Item[specgen:Attribute]) ]" priority="2">
		<xsl:text>&#x0a;  # //////////////////////// attr extn /////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;',
									 '    type: object&#x0a;',
									 '    properties:&#x0a;',
									 '      value:&#x0a;',
									 '#        allOfC:&#x0a;',
									 '        $ref: ''#/definitions/', xfn:chopType(specgen:Item[1]/specgen:Type/@name), '''&#x0a;')"/>

		<!--xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;',
									 '    type: object&#x0a;',
									 '    properties:&#x0a;',
									 '      value:&#x0a;',
									 '        allOf:&#x0a;',
									 '          - $ref: ''#/definitions/', xfn:chopType(specgen:Item[1]/specgen:Type/@name), '''&#x0a;')"/-->

		<xsl:apply-templates select="specgen:Item[position() gt 1]">
			<xsl:with-param name="indent" select="'      '"/>
		</xsl:apply-templates>

		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>
		<xsl:if test="string-length($desc) gt 0">
			<!--xsl:value-of select="concat('      - description: &gt;-&#x0a;          ', $desc, '&#x0a;')"/-->
			<xsl:value-of select="concat('    description: &gt;-&#x0a;'
			                            ,'      ', $desc, '&#x0a;')"/>
		</xsl:if>
	</xsl:template>

	<!-- Common type is a known xs:* simpleType with attributes (no extension) -->
	<xsl:template match="specgen:CommonElement[count(specgen:Item) gt 1 and
	                     not(specgen:Item[1]/specgen:Type/@complex) and
						 starts-with(specgen:Item[1]/specgen:Type/@name, 'xs:') and
						 count(specgen:Item[position() gt 1]) eq count(specgen:Item[specgen:Attribute]) ]" priority="2">
		<xsl:text>&#x0a;  # //////////////////////// xs:* with attrs /////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;',
									 '    type: object&#x0a;',
									 '    properties:&#x0a;',
									 '      value:&#x0a;')"/>

		<!-- There might be a description -->
		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>
		<xsl:if test="string-length($desc) gt 0">
			<xsl:value-of select="concat('      - description: &gt;-&#x0a;          ', $desc, '&#x0a;')"/>
		</xsl:if>

		<!-- Translate xs:* type into json schema type -->
		<xsl:apply-templates select="specgen:Item[1]/specgen:Type">
			<xsl:with-param name="indent" select="'      '"/>
		</xsl:apply-templates>

		<!-- Add the attributes -->
		<xsl:apply-templates select="specgen:Item[position() gt 1]">
			<xsl:with-param name="indent" select="'      '"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- Common type is single item, with inline values -->
	<xsl:template match="specgen:CommonElement[count(specgen:Item) eq 1 and
	                                           count(specgen:Item[1]/specgen:Values) eq 1]" priority="2">
		<xsl:text>&#x0a;  # ///////////////////////////// single Item with Values ////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;',
		                             '    type: string&#x0a;')"/>

		<!-- Pickup inline Values -->
		<xsl:apply-templates select="specgen:Item[1]/specgen:Values">
			<xsl:with-param name="indent" select="'    '"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- Common type is instance of xs:* type with no attributes (not an extension) -->
	<xsl:template match="specgen:CommonElement[count(specgen:Item) eq 1 and
						 starts-with(specgen:Item[1]/specgen:Type/@name, 'xs:') and
					     not(specgen:Item[1]/specgen:Type/@complex eq 'extension')]">
						 
		<xsl:text>&#x0a;  # ////////////////////////////// xs:* no attrs ///////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;')"/>

		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>

		<xsl:if test="string-length($desc) gt 0">
			<xsl:value-of select="concat('    description: &gt;-&#x0a;      ', $desc, '&#x0a;')"/>
		</xsl:if>

		<!-- Simple and extended Types -->
		<xsl:apply-templates select="specgen:Item[1]/specgen:Type">
			<xsl:with-param name="indent" select="'  '"/>
		</xsl:apply-templates>
		
		<!-- Inline facets, etc. -->
		<xsl:apply-templates select="specgen:Item[1]/specgen:Facets/xs:*">
			<xsl:with-param name="indent" select="'    '"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- Common type is instance of another type -->
	<xsl:template match="specgen:CommonElement[count(specgen:Item) eq 1 and
						 not(starts-with(specgen:Item[1]/specgen:Type/@name, 'xs:')) and
						 not(specgen:Item[1]/specgen:Type/@complex eq 'extension')]">
		<xsl:text>&#x0a;  # ////////////////////////////// another type ///////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;')"/>
		<!--xsl:text>    allOf:&#x0a;</xsl:text-->
		<xsl:text>#    allOfD:&#x0a;</xsl:text>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Type">
			<xsl:with-param name="indent" select="'    '"/>
		</xsl:apply-templates>

		<xsl:text>    description: &gt;-&#x0a;      </xsl:text>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>

		<!-- Pickup Type ref -->
		<!-- 
		<xsl:apply-templates select="specgen:Item[1]/specgen:Type">
			<xsl:with-param name="indent" select="'    - '"/>
		</xsl:apply-templates>

		<xsl:text>    - description: &gt;-&#x0a;        </xsl:text>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
		-->
	</xsl:template>
	
	<!-- Common type is a list (implicit or explict), with repeatable choice (hetrogynous list) -->
	<xsl:template priority="2" match="specgen:CommonElement[count(specgen:Item|specgen:Choice) eq 2 and specgen:Choice/@repeatable='true'] ">
		<xsl:text>&#x0a;  # ////////////////////////////////////// hetrogynous list ///////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;')"/>

		<xsl:text>    description: &gt;-&#x0a;      </xsl:text>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
		<xsl:text>    type: object&#x0a;    properties: &#x0a;</xsl:text>
		<xsl:value-of select="concat('      ', xfn:chopType(specgen:Item[1]/specgen:Element), ':&#x0a;        type: array&#x0a;        items:&#x0a;')"/>

		<xsl:apply-templates select="specgen:Choice">
			<xsl:with-param name="indent" select="'          '"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- Common type is a list (implicit or explict), with choice items all the same (homogonous list) -->
	<xsl:template priority="2" match="specgen:CommonElement[count(specgen:Item|specgen:Choice) eq 2 and
																	contains(specgen:Choice/specgen:Item[1]/specgen:Characteristics, 'R')] ">
		<xsl:text>&#x0a;  # ///////////////////////////// homogonous list ////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;')"/>

		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>
		<xsl:if test="string-length($desc) gt 0">
			<xsl:value-of select="concat('    description: &gt;-&#x0a;      ', $desc, '&#x0a;')"/>
		</xsl:if>

		<xsl:text>    type: object&#x0a;    properties: &#x0a;</xsl:text>
		<xsl:value-of select="concat('      ', xfn:chopType(specgen:Item[1]/specgen:Element), ':&#x0a;        type: object&#x0a;        properties:&#x0a;')"/>

		<xsl:apply-templates select="specgen:Choice">
			<xsl:with-param name="indent" select="'          '"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- Common type is a list (implicit or explicit), without choices -->
	<xsl:template priority="2" match="specgen:CommonElement[count(specgen:Item) eq 2 and
	                                           (specgen:Item[1]/specgen:List or contains(specgen:Item[2]/specgen:Characteristics, 'R'))]">
		<xsl:text>&#x0a;  # ///////////////////////////////// list ////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;')"/>

		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>
		<xsl:if test="string-length($desc) gt 0">
			<xsl:value-of select="concat('    description: &gt;-&#x0a;      ', $desc, '&#x0a;')"/>
		</xsl:if>
		
		<xsl:text>    type: object&#x0a;</xsl:text>

<!--  		
		<xsl:value-of select="concat('#DEBUG: is list required: ', $mandatoryFields, '&#x0a;')"/>
		<xsl:value-of select="concat('#DEBUG: Item 2 (list items): ', specgen:Item[position() = 2]/specgen:Characteristics, '&#x0a;')"/>
-->		
		<xsl:if test="$mandatoryFields = 'required'">
			<xsl:if test="specgen:Item[contains(specgen:Characteristics, 'M')] and specgen:Item[position() = 2]/specgen:Characteristics = 'MR'">
			<!--xsl:if test="specgen:Item[contains(specgen:Characteristics, 'M')]"-->
				<xsl:text>    required:&#x0a;</xsl:text>
				<xsl:apply-templates select="specgen:Item[position() gt 1]" mode="required"/>
			</xsl:if>
		</xsl:if>				
		<xsl:text>    properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      ', specgen:Item[2]/specgen:Element, ':&#x0a;')"/>
		<xsl:text>        type: array&#x0a;</xsl:text>
		<xsl:text>        items:&#x0a;</xsl:text>

		<!-- What kind of thing is each list member? -->
		<xsl:choose>
			<!-- array of atomic type  -->
			<xsl:when test="specgen:Item[2]/specgen:Type/@name eq 'xs:string' 
							or specgen:Item[2]/specgen:Type/@name eq 'xs:normalizedString'
							or specgen:Item[2]/specgen:Type/@name eq 'xs:token'
							or specgen:Item[2]/specgen:Type/@name eq 'NCName'">
				<xsl:text>          type: string&#x0a;</xsl:text>
			</xsl:when>
			<xsl:when test="specgen:Item[2]/specgen:Type/@name eq 'xs:integer' 
							or specgen:Item[2]/specgen:Type/@name eq 'xs:int'
							or specgen:Item[2]/specgen:Type/@name eq 'xs:unsignedInt'">
				<xsl:text>          type: integer&#x0a;</xsl:text>
			</xsl:when>
			<xsl:when test="specgen:Item[2]/specgen:Type/@name eq 'xs:date'"> 
				<xsl:text>          type: string&#x0a;</xsl:text>
				<xsl:text>          format: date&#x0a;</xsl:text>
			</xsl:when>
			<xsl:when test="specgen:Item[2]/specgen:Type/@name eq 'xs:boolean'"> 
				<xsl:text>          type: boolean&#x0a;</xsl:text>
			</xsl:when>
			<xsl:when test="specgen:Item[2]/specgen:Type/@name eq 'xs:decimal'">
				<xsl:text>          type: number&#x0a;</xsl:text>
			</xsl:when>

			<!-- array of some other defined type -->
			<xsl:otherwise>
				<!--  Some types are listed in a <Union> element. In this case we take the first one -->
				<xsl:variable name="typeName" select="xfn:getNoneEmptyValue(specgen:Item[2]/specgen:Type/@name,specgen:Item[2]/specgen:Union/specgen:Type[1]/@name)"/>
				<xsl:value-of select="concat('          $ref: ''#/definitions/', xfn:chopType($typeName), '''&#x0a;')"/>
<!--
				<xsl:value-of select="concat('          $ref: ''#/definitions/', xfn:chopType(specgen:Item[2]/specgen:Type/@name), '''&#x0a;')"/>
-->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Common type is a non-empty extension of a base type -->
	<xsl:template priority="1" match="specgen:CommonElement[count(specgen:Item) gt 1 and specgen:Item[1]/specgen:Type/@complex = 'extension']">
		<xsl:text>&#x0a;  # ////////////////////////////// extension ///////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;')"/>

		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>
		<xsl:if test="string-length($desc) gt 0">
			<xsl:value-of select="concat('    description: &gt;-&#x0a;      ', $desc, '&#x0a;')"/>
		</xsl:if>

		<xsl:text>    allOf:&#x0a;</xsl:text>
		<xsl:value-of select="concat('    - $ref: ''#/definitions/', xfn:chopType(@name), '''&#x0a;')"/>
		<xsl:text>    - type: object&#x0a;</xsl:text>
		<xsl:if test="$mandatoryFields = 'required'">
			<xsl:if test="specgen:Item[contains(specgen:Characteristics, 'M')]|//specgen:CommonElement[@name = current()/specgen:Item[1]/specgen:Type/@name]/specgen:Item[contains(specgen:Characteristics, 'M')]">
				<xsl:text>    - required:&#x0a;</xsl:text>
				<xsl:apply-templates select="specgen:Item|//specgen:CommonElement[@name = current()/specgen:Item[1]/specgen:Type/@name]/specgen:Item" mode="required">
					<xsl:sort select="specgen:Element|specgen:Attribute"/>
					<xsl:with-param name="indent" select="'      '"/>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:if>
		<xsl:if test="count(specgen:Item|specgen:Choice) gt 0">
			<xsl:text>    - properties:&#x0a;</xsl:text>
		</xsl:if>
	

		<!-- Add extra properties, which may be wrapped up in a choice -->
		<xsl:apply-templates select="specgen:Item[position() gt 1] | specgen:Choice">
			<xsl:with-param name="indent" select="'          '"/>
		</xsl:apply-templates>
	</xsl:template>

    <!-- Common type is a straightforward sequence of 1 or more items -->
	<xsl:template priority="1" match="specgen:CommonElement[count(specgen:Item) gt 1 and not(specgen:Item[1]/specgen:Type/@complex = 'extension')]">
		<xsl:text>&#x0a;  # ////////////////////////////// default sequence ///////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;')"/>

		<xsl:variable name="desc">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/>
		</xsl:variable>
		<xsl:if test="string-length($desc) gt 0">
			<xsl:value-of select="concat('    description: &gt;-&#x0a;      ', $desc, '&#x0a;')"/>
		</xsl:if>

		<!-- Simple and extended Types but not complex sub-type of style <Type><otherstuff></Type> -->
		
		<!-- 
			Make sure we only apply the template if we deal with something like <Type ...></Type> (no child nodes)
			In cases where we have <Type><otherstuff></Type> then we do not want set the type as it is covered
			somewhere else.
		-->
		<xsl:if test="count(specgen:Item[1]/specgen:Type/node()) = 0">
			<xsl:apply-templates select="specgen:Item[1]/specgen:Type">
				<xsl:with-param name="indent" select="'    '"/>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:apply-templates select="specgen:Item[1]/specgen:Facets/xs:*">
			<xsl:with-param name="indent" select="'    '"/>
		</xsl:apply-templates>

		<xsl:text>    type: object&#x0a;</xsl:text>
		<xsl:if test="$mandatoryFields = 'required'">
			<xsl:if test="specgen:Item[contains(specgen:Characteristics, 'M')]|//specgen:CommonElement[@name = current()/specgen:Item[1]/specgen:Type/@name]/specgen:Item[contains(specgen:Characteristics, 'M')]">
				<xsl:text>    required:&#x0a;</xsl:text>
				<xsl:apply-templates select="specgen:Item|//specgen:CommonElement[@name = current()/specgen:Item[1]/specgen:Type/@name]/specgen:Item" mode="required">
					<xsl:sort select="specgen:Element|specgen:Attribute"/>
				</xsl:apply-templates>
			</xsl:if>

			<xsl:apply-templates select="specgen:Choice" mode="required"/>
		</xsl:if>				
		<xsl:if test="count(specgen:Item) gt 1">
			<xsl:text>    properties:&#x0a;</xsl:text>
		</xsl:if>

		<!-- Add properties, which may be wrapped up in a choice -->
		<xsl:apply-templates select="specgen:Item[position() gt 1] | specgen:Choice">
			<xsl:with-param name="indent" select="'      '"/>
		</xsl:apply-templates>
	</xsl:template>
	

	<!-- Items can be wrapped up in choices -->
	<xsl:template match="specgen:Choice">
		<xsl:param name="indent"/>
		<xsl:apply-templates select="specgen:Item">
			<xsl:with-param name="indent" select="$indent"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- Item is required;  if Characteristcs == 'M' -->
	<xsl:template match="specgen:Item" mode="required"/>
	<xsl:template match="specgen:Item[contains(specgen:Characteristics, 'M')]" mode="required">
		<xsl:param name="indent"><xsl:value-of select="'    '"/></xsl:param>

		<xsl:value-of select="concat($indent, '- ', $q, specgen:Element, specgen:Attribute, $q, '&#x0a;')"/>
	</xsl:template>
	<xsl:template match="specgen:Choice" mode="required">
		<xsl:text>    oneOf:&#x0a;</xsl:text>
		<xsl:for-each select="specgen:Item">
			<xsl:value-of select="concat('    - required: [ ''', specgen:Element, ''' ]&#x0a;')"/>
		</xsl:for-each>
	</xsl:template>

	<!-- Item is of a named Type -->
	<xsl:template match="specgen:Item[specgen:Type/@ref]">
		<xsl:param name="indent"/>
		
		<xsl:value-of select="concat($indent, specgen:Element|specgen:Attribute, ':&#x0a;')"/>

		<xsl:choose>
			<!-- Item is repeatable -->
			<xsl:when test="contains(specgen:Characteristics,  'R')">
				<xsl:value-of select="concat($indent, '  type: array&#x0a;', $indent, '  items:&#x0a;')"/>
				<xsl:value-of select="concat('#', $indent, '  - allOfG:&#x0a;')"/>

				<!-- $ref -->
<!--xsl:text>#"specgen:Type A</xsl:text-->

				<xsl:apply-templates select="specgen:Type">
					<xsl:with-param name="indent" select="concat($indent, '    ')"/>
				</xsl:apply-templates>

				<xsl:if test="normalize-space(specgen:Description) ne ''">
					<xsl:value-of select="concat($indent, '    description: &gt;-&#x0a;', $indent, '      ')"/>
					<xsl:apply-templates select="specgen:Description"/><xsl:text>&#x0a;</xsl:text>

					<!-- If the Item is a codeset then include (at least some of) the values in the description -->
					<xsl:if test="specgen:Type/@ref eq 'CodeSets'">
						<xsl:variable name="codeSetId">
							<xsl:value-of select="xfn:chopType(substring-after(specgen:Type/@name, 'CodeSets'))"/>
						</xsl:variable>
						<xsl:variable name="codeSetGroupId">
							<xsl:value-of select="substring-before(specgen:Type/@name, $codeSetId)"/>
						</xsl:variable>
						<xsl:value-of select="concat($indent, '      &lt;ul&gt;&#x0a;')"/>
						<xsl:apply-templates select="//specgen:Appendix[ends-with(@name, 'Code Sets')]/specgen:CodeSets//specgen:Grouping[@code = $codeSetGroupId]//specgen:CodeSet[replace(replace(specgen:ID, ' ',''), '-', '') = $codeSetId]/specgen:Values/specgen:Value[position() &lt;= $enumCount]" mode="descr">
							<xsl:with-param name="indent" select="concat($indent, '      ')"/>
						</xsl:apply-templates>
						<xsl:value-of select="concat($indent, '      &lt;/ul&gt;&#x0a;')"/>
						<xsl:if test="count(//specgen:Appendix[ends-with(@name, 'Code Sets')]/specgen:CodeSets//specgen:Grouping[@code = $codeSetGroupId]//specgen:CodeSet[replace(replace(specgen:ID, ' ',''), '-', '') = $codeSetId]/specgen:Values/specgen:Value) &gt; $enumCount">
							<xsl:value-of select="concat($indent, '        plus ', 
														count(//specgen:Appendix[ends-with(@name, 'Code Sets')]/specgen:CodeSets//specgen:Grouping[@code = $codeSetGroupId]//specgen:CodeSet[replace(replace(specgen:ID, ' ',''), '-', '') = $codeSetId]/specgen:Values/specgen:Value) - $enumCount, 
														' more value(s) at &lt;a href=',$q,
														$extDocURLBase, 'CodeSets.html#', specgen:Type/@name, $q, '&gt;',
														specgen:Type/@name, '&lt;a&gt;&#x0a;')"/>
						</xsl:if>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($indent, '  type: object&#x0a;')"/>
				<xsl:if test="normalize-space(specgen:Description) ne ''">
					<xsl:value-of select="concat($indent, '  description: &gt;-&#x0a;', $indent, '    ')"/>
					<xsl:apply-templates select="specgen:Description"/><xsl:text>&#x0a;</xsl:text>

					<!-- If the Item is a codeset then include (at least some of) the values in the description -->
					<xsl:if test="specgen:Type/@ref eq 'CodeSets'">
						<xsl:variable name="codeSetId">
							<xsl:value-of select="xfn:chopType(substring-after(specgen:Type/@name, 'CodeSets'))"/>
						</xsl:variable>
						<xsl:variable name="codeSetGroupId">
							<xsl:value-of select="substring-before(specgen:Type/@name, $codeSetId)"/>
						</xsl:variable>
						<xsl:value-of select="concat($indent, '    &lt;ul&gt;&#x0a;')"/>
						<xsl:apply-templates select="//specgen:Appendix[ends-with(@name, 'Code Sets')]/specgen:CodeSets//specgen:Grouping[@code = $codeSetGroupId]//specgen:CodeSet[replace(replace(specgen:ID, ' ',''), '-', '') = $codeSetId]/specgen:Values/specgen:Value[position() &lt;= $enumCount]" mode="descr">
							<xsl:with-param name="indent" select="concat($indent, '    ')"/>
						</xsl:apply-templates>
						<xsl:value-of select="concat($indent, '    &lt;/ul&gt;&#x0a;')"/>
						<xsl:if test="count(//specgen:Appendix[ends-with(@name, 'Code Sets')]/specgen:CodeSets//specgen:Grouping[@code = $codeSetGroupId]//specgen:CodeSet[replace(replace(specgen:ID, ' ',''), '-', '') = $codeSetId]/specgen:Values/specgen:Value) &gt; $enumCount">
							<xsl:value-of select="concat($indent, '      plus ', 
														count(//specgen:Appendix[ends-with(@name, 'Code Sets')]/specgen:CodeSets//specgen:Grouping[@code = $codeSetGroupId]//specgen:CodeSet[replace(replace(specgen:ID, ' ',''), '-', '') = $codeSetId]/specgen:Values/specgen:Value) - $enumCount, 
														' more value(s) at &lt;a href=',$q,
														$extDocURLBase, 'CodeSets.html#', specgen:Type/@name, $q, '&gt;',
														specgen:Type/@name, '&lt;a&gt;&#x0a;')"/>
						</xsl:if>
					</xsl:if>
				</xsl:if>
				
				<!-- $ref -->
				<!--xsl:text>#"specgen:Type B</xsl:text-->
				<!-- type is already set as 'object' at the begining of the "xsl:otherwise" node. -->

                <!-- Only apply for non-extensions... -->
                <xsl:if test="not(specgen:Type/@complex eq 'extension')">
					<xsl:apply-templates select="specgen:Type">
						<xsl:with-param name="indent" select="concat($indent, '  ')"/>
					</xsl:apply-templates>
				</xsl:if>
				<!-- Can a named type also have Values -->
				<xsl:apply-templates select="specgen:Values">
					<xsl:with-param name="indent" select="concat($indent, '')"/>
				</xsl:apply-templates>

				<!-- Facets need different indents -->
				<xsl:apply-templates select="specgen:Facets/xs:*">
					<xsl:with-param name="indent" select="concat($indent, '')"/>
				</xsl:apply-templates>

				<!-- Item might be an attribute -->
				<xsl:if test="specgen:Attribute"> 
					<xsl:value-of select="concat($indent, '  xml:&#x0a;', $indent, '    attribute: true&#x0a;')"/>
				</xsl:if>

			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Item is untyped, can have inline attributes and values -->
	<xsl:template match="specgen:Item[not(specgen:Type)]">
		<xsl:param name="indent"/>
		
		<xsl:value-of select="concat($indent, specgen:Element|specgen:Attribute, ':&#x0a;')"/>
		
		<xsl:if test="normalize-space(specgen:Description) ne ''">
			<xsl:value-of select="concat($indent, '  description: &gt;-&#x0a;', $indent, '    ')"/>
			<xsl:apply-templates select="specgen:Description"/><xsl:text>&#x0a;</xsl:text>
		</xsl:if>

		<xsl:apply-templates select="specgen:Values">
			<xsl:with-param name="indent" select="concat($indent,'  ')"/>
		</xsl:apply-templates>

		<xsl:apply-templates select="specgen:Facets/xs:*">
			<xsl:with-param name="indent" select="concat($indent, '  ')"/>
		</xsl:apply-templates>

		<xsl:if test="specgen:Attribute"> 
			<xsl:value-of select="concat($indent, '  xml:&#x0a;', $indent, '    attribute: true&#x0a;')"/>
		</xsl:if>

	</xsl:template>
	
	<!-- Item is Typed, but it's an unnamed type -->
	<xsl:template match="specgen:Item[specgen:Type and not(specgen:Type/@ref)]">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, specgen:Element|specgen:Attribute, ':&#x0a;')"/>
	
		<!-- $ref -->
		<xsl:choose>
			<xsl:when test="specgen:Type/@name ne ''">
<!--xsl:text>#"specgen:Type C</xsl:text-->
				<xsl:apply-templates select="specgen:Type">
					<xsl:with-param name="indent" select="$indent"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="preceding-sibling::specgen:Item[1]/specgen:Type">
					<xsl:with-param name="indent" select="$indent"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:if test="normalize-space(specgen:Description) ne ''">
			<xsl:value-of select="concat($indent, '  description: &gt;-&#x0a;', $indent, '    ')"/>
			<xsl:apply-templates select="specgen:Description"/><xsl:text>&#x0a;</xsl:text>
		</xsl:if>

		<xsl:apply-templates select="specgen:Values">
			<xsl:with-param name="indent" select="$indent"/>
		</xsl:apply-templates>

		<xsl:apply-templates select="specgen:Facets/xs:*">
			<xsl:with-param name="indent" select="concat($indent, '  ')"/>
		</xsl:apply-templates>

		<xsl:if test="specgen:Attribute"> 
			<xsl:value-of select="concat($indent, '  xml:&#x0a;', $indent, '    attribute: true&#x0a;')"/>
		</xsl:if>
	</xsl:template>

	<!-- Type is of known xs:type -->
	<xsl:template match="specgen:Type[not(@complex) and starts-with(@name, 'xs:')]">
		<xsl:param name="indent"/>

		<xsl:choose>
			<xsl:when test="   @name eq 'xs:integer'
							or @name eq 'xs:int'
							or @name eq 'xs:unsignedInt'">
				<xsl:value-of select="concat($indent, '  type: integer&#x0a;')"/>
			</xsl:when>

			<xsl:when test="@name eq 'xs:decimal'">
				<xsl:value-of select="concat($indent, '  type: number&#x0a;')"/>
			</xsl:when>

			<xsl:when test="@name eq 'xs:date'">
				<xsl:value-of select="concat($indent, '  type: string&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  format: date&#x0a;')"/>
			</xsl:when>
			
			<xsl:when test="   @name eq 'xs:string'
											or @name eq 'xs:normalizedString'
                      or @name eq 'xs:token'
					        		or @name eq 'NCName'">
				<xsl:value-of select="concat($indent, '  type: string&#x0a;')"/>
			</xsl:when>
			
			<xsl:when test="   @name eq 'xs:boolean'">
				<xsl:value-of select="concat($indent, '  type: boolean&#x0a;')"/>
			</xsl:when>
			
			<xsl:when test="@name eq 'xs:anyURI'">
				<xsl:value-of select="concat($indent, '  type: string&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  format: uri&#x0a;')"/>
			</xsl:when>

			<xsl:when test="@name eq 'base64Binary'">
				<xsl:value-of select="concat($indent, '  type: string&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  contentEncoding: base64&#x0a;')"/>				
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- Type is of named type -->
	<xsl:template match="specgen:Type[not(@complex) and @name ne '' and not(starts-with(@name, 'xs:'))]">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent,'$ref: ''#/definitions/', xfn:chopType(@name), '''&#x0a;')"/>
	</xsl:template>

	<!-- Un-named type, so inline object -->
	<xsl:template match="specgen:Type">
		<xsl:param name="indent"/>
		<!--xsl:value-of select="concat($indent, '  typeXYZ: object&#x0a;')"/-->
		<xsl:value-of select="concat($indent, 'type: object&#x0a;')"/>
	</xsl:template>

	
	<!-- Facets -->
	<xsl:template match="specgen:Facets/xs:pattern">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, 'pattern: ''^', @value, '$''&#x0a;')"/>
	</xsl:template>
	<xsl:template match="specgen:Facets/xs:minLength|specgen:Facets/xs:maxLength">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, local-name(.), ': ', @value, '&#x0a;')"/>
	</xsl:template>

	<!-- CodeSets become enums - with code definitions in the description field -->
	<xsl:template match="specgen:CodeSet">
		<xsl:text>&#x0a;  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:variable name="codeSetId">
			<xsl:value-of select="concat(ancestor::specgen:Grouping/@code, translate(specgen:ID, '- /()', ''))"/>
		</xsl:variable>
		<xsl:value-of select="concat('  ', $codeSetId, ':&#x0a;',
			                         '    type: string&#x0a;',
							         '    title: ', specgen:ID, '&#x0a;',
			                         '    description: &gt;-&#x0a;      ')"/>
		<xsl:apply-templates select="specgen:Intro"/><xsl:text>&#x0a;</xsl:text>
		<xsl:text>      &lt;ul&gt;&#x0a;</xsl:text>
		<xsl:apply-templates select="specgen:Values/specgen:Value[position() &lt;= $enumCount]" mode="descr">
			<xsl:with-param name="indent" select="'    '"/>
		</xsl:apply-templates>
		<xsl:text>      &lt;/ul&gt;&#x0a;</xsl:text>
		<xsl:if test="count(specgen:Values/specgen:Value) &gt; $enumCount">
			<xsl:value-of select="concat('      plus ', 
									  	count(specgen:Values/specgen:Value) - $enumCount, 
										' more value(s) at &lt;a href=',$q,
										$extDocURLBase, 'CodeSets.html#', $codeSetId, 'Type', $q, '&gt;',
										$codeSetId, 'Type&lt;a&gt;&#x0a;')"/>
		</xsl:if>
		<xsl:apply-templates select="specgen:Values">
			<xsl:with-param name="indent" select="'    '"/>
		</xsl:apply-templates>
	</xsl:template>

	<!-- Instead of 'enum' we are using 'oneOf' with array of 'const' so we can put 
		title & description alongside the code value;  can't do that with 'enum' -->
	<xsl:template match="specgen:Values">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, 'oneOf:&#x0a;')"/>
		<xsl:apply-templates select="specgen:Value" mode="enum">
			<xsl:with-param name="indent" select="$indent"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="specgen:Value" mode="enum">
		<xsl:param name="indent"/>

		<!-- JSON Schema for OpenAPI doesn't (currently) support 'const' as synonym for singleton 'enum' array -->
		<xsl:choose>
			<xsl:when test="$strictJSON eq 'true'">
				<xsl:value-of select="concat($indent, '- enum: [ ', $q, specgen:Code, $q, ' ]&#x0a;')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($indent, '- const: ', $q, specgen:Code, $q, '&#x0a;')"/>
			</xsl:otherwise>
		</xsl:choose>

		<!--
			If there is no Text we use the Value as the 'title' to ensure nicely rendered enumerations/codesets
		 -->
		<xsl:choose>
        	<xsl:when test="xfn:empty(specgen:Text)">
				<xsl:value-of select="concat($indent, '  title: ', specgen:Code, '&#x0a;')"/>
        	</xsl:when>
        	<xsl:otherwise>
				<xsl:apply-templates select="specgen:Text" mode="enum">
					<xsl:with-param name="indent" select="$indent"/>
				</xsl:apply-templates>
        	</xsl:otherwise>
        </xsl:choose>

		<xsl:apply-templates select="specgen:Description" mode="enum">
			<xsl:with-param name="indent" select="$indent"/>
		</xsl:apply-templates>
	</xsl:template>


	<!-- not doing multiple languages -->
	<xsl:template match="specgen:Text" mode="enum">
		<xsl:param name="indent"/>

		<xsl:value-of select="concat($indent, '  title: ')"/>

		<xsl:variable name="text"><xsl:apply-templates/></xsl:variable>
		<xsl:if test="contains($text, ':')"><xsl:text>"</xsl:text></xsl:if>
		<xsl:value-of select="normalize-space($text)"/>
		<xsl:if test="contains($text, ':')"><xsl:text>"</xsl:text></xsl:if>
		<xsl:text>&#x0a;</xsl:text>
	</xsl:template>

	<!-- doing multiple languages -->
	<xsl:template match="specgen:Text[@xml:lang]" mode="enum">
		<xsl:param name="indent"/>

		<xsl:if test="position() = 1">
			<xsl:value-of select="concat($indent, '  title*: &#x0a;')"/>
		</xsl:if>

		<xsl:variable name="text"><xsl:apply-templates/></xsl:variable>
		<xsl:value-of select="concat($indent, '    ', @xml:lang, ': ')"/>
		<xsl:if test="contains($text, ':')"><xsl:text>"</xsl:text></xsl:if>
		<xsl:value-of select="normalize-space($text)"/>
		<xsl:if test="contains($text, ':')"><xsl:text>"</xsl:text></xsl:if>
		<xsl:text>&#x0a;</xsl:text>

	</xsl:template>

	<!-- not doing multiple languages -->
	<xsl:template match="specgen:Description" mode="enum">
		<xsl:param name="indent"/>

		<xsl:value-of select="concat($indent, '  description: &gt;-&#x0a;', $indent, '    ')"/>

		<xsl:variable name="descr"><xsl:apply-templates/></xsl:variable>
		<xsl:if test="contains($descr, ':')"><xsl:text>"</xsl:text></xsl:if>
		<xsl:value-of select="normalize-space($descr)"/>
		<xsl:if test="contains($descr, ':')"><xsl:text>"</xsl:text></xsl:if>
		<xsl:text>&#x0a;</xsl:text>
	</xsl:template>

	<!-- doing multiple languages -->
	<xsl:template match="specgen:Description[@xml:lang]" mode="enum">
		<xsl:param name="indent"/>

		<xsl:if test="position() = 1">
			<xsl:value-of select="concat($indent, '  description*:&#x0a;')"/>
		</xsl:if>

		<xsl:variable name="descr"><xsl:apply-templates/></xsl:variable>
		<xsl:value-of select="concat($indent, '    ', @xml:lang, ': &gt;-&#x0a;', $indent, '      ')"/>
		<xsl:if test="contains($descr, ':')"><xsl:text>"</xsl:text></xsl:if>
		<xsl:value-of select="normalize-space($descr)"/>
		<xsl:if test="contains($descr, ':')"><xsl:text>"</xsl:text></xsl:if>
		<xsl:text>&#x0a;</xsl:text>
	</xsl:template>

	<!-- CodeSet value (for description text - <li> ... </li>) -->
	<xsl:template match="specgen:Value" mode="descr">
		<xsl:param name="indent"/>

		<xsl:variable name="valDesc">
			<xsl:apply-templates select="specgen:Text">
				<xsl:with-param name="pfx" select="' - '"/>
			</xsl:apply-templates>
		</xsl:variable>

		<xsl:value-of select="concat($indent, '    &lt;li&gt;''', specgen:Code, '''', $valDesc, '&lt;/li&gt;&#x0a;')"/>
	</xsl:template>


	<!-- Bring Description, Intro or Text mixed content elements across with all its embedded html -->
	<xsl:template match="specgen:Description|specgen:Intro|specgen:Text">
		<xsl:param name="pfx"/>
		<xsl:variable name="descr"><xsl:apply-templates/></xsl:variable>

		<xsl:value-of select="concat($pfx, normalize-space($descr))"/>
	</xsl:template>

	<xsl:template match="specgen:p|specgen:br
						 |specgen:code|specgen:strong|specgen:em|specgen:span
						 |specgen:h1|specgen:h2|specgen:h3|specgen:h4
						 |specgen:img
						 |specgen:ul|specgen:ol|specgen:li
						 |specgen:dl|specgen:dt|specgen:dd
						 |specgen:table|specgen:thead|specgen:tbody|specgen:tr|specgen:th|specgen:td">
		<xsl:value-of select="concat('&lt;', local-name(.), '&gt;')"/>
		<xsl:apply-templates/>
		<xsl:value-of select="concat('&lt;/', local-name(.), '&gt;')"/>
	</xsl:template>

	<!-- Custom function to chop 'Type' off the end of XSD type names -->
	<xsl:function name="xfn:chopType" as="xs:string">
		<xsl:param name="inp"/>
		<xsl:choose>
			<xsl:when test="ends-with($inp, 'Type')">
				<xsl:value-of select="substring($inp, 1, string-length($inp)-4)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$inp"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Return the value that is not empty. -->
	<xsl:function name="xfn:getNoneEmptyValue" as="xs:string">
		<xsl:param name="value1"/>
		<xsl:param name="value2"/>
		<xsl:if test="$value1 != ''">
			<xsl:value-of select="$value1"/>
		</xsl:if>
		<xsl:if test="not($value1 != '')">
			<xsl:value-of select="$value2"/>
		</xsl:if>
	</xsl:function>
	
	<!-- returns true if value is not set or empty -->
	<xsl:function name="xfn:empty" as="xs:boolean">
		<xsl:param name="value"/>
		<xsl:sequence select="not($value != '')" />
	</xsl:function>
	
	
</xsl:stylesheet>
