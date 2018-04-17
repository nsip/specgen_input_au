<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:specgen="http://sifassociation.org/SpecGen"
	xmlns:xfn="http://stuart.geek.nz/xslt-functions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">

	<!-- Take a SIF_DataModel.input.xml file and produce a matching Swagger 2.0 spec -->
	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
	
	<xsl:param name="sifVersion"/>
	<xsl:param name="sifLocale"/>

	<xsl:template match="/specgen:SIFSpecification">
		<xsl:value-of select="concat( 'swagger: ''2.0''&#x0a;',
                                      'info:&#x0a;',
                                      '  version: ', $sifVersion, '&#x0a;',
                                      '  title: &quot;SIF ', sifLocale, ' derived API&quot;&#x0a;',
									  '  description: ', normalize-space(specgen:TitlePage/specgen:h1), '&#x0a;')"/>
		
		<xsl:text># /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObjects" mode="paths"/>

		<xsl:text>&#x0a;# /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:text>definitions:&#x0a;</xsl:text>
		
		<xsl:apply-templates select=".//specgen:DataObjects//specgen:DataObject" mode="schemasList"/>
		<xsl:apply-templates select=".//specgen:DataObjects//specgen:DataObject" mode="schemasSingle"/>
		
		<xsl:apply-templates select=".//specgen:Appendix[@name = 'Common Types']//specgen:CommonElement"/>
		<xsl:apply-templates select=".//specgen:Appendix[@name = 'Code Sets']//specgen:CodeSet"/>
	</xsl:template>


	<xsl:template match="specgen:DataObjects" mode="paths">
		<xsl:text>paths:&#x0a;</xsl:text>

		<xsl:apply-templates select=".//specgen:DataObject" mode="paths"/>
	</xsl:template>              

	<xsl:template match="specgen:DataObject" mode="paths">
		<xsl:text>  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  /', @name, 's:&#x0a;')"/>
		<xsl:text>    get:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      tags:&#x0a;      - ', @name, 's&#x0a;')"/>
		<xsl:value-of select="concat('      summary: Default operation to get a list of all available ', @name, 's&#x0a;')"/>
		<xsl:text>      produces:&#x0a;</xsl:text>
		<xsl:text>      - 'application/json'&#x0a;</xsl:text>
		<xsl:text>      - 'application/xml'&#x0a;</xsl:text>
		<xsl:apply-templates select="." mode="responsesList"/>

		<xsl:if test="specgen:Key">
			<xsl:text>  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
			<xsl:value-of select="concat('  /', @name, 's/{', lower-case(@name), translate(specgen:Key, '@', ''), '}:&#x0a;')"/>
			<xsl:text>    get:&#x0a;</xsl:text>
			<xsl:value-of select="concat('      tags:&#x0a;      - ', @name, 's&#x0a;')"/>
 			<xsl:value-of select="concat('      summary: Default operation to get a single ', @name, '&#x0a;')"/>
    		<xsl:text>      produces:&#x0a;</xsl:text>
	    	<xsl:text>      - 'application/json'&#x0a;</xsl:text>
    		<xsl:text>      - 'application/xml'&#x0a;</xsl:text>
			<xsl:value-of select="concat('      parameters:&#x0a;      - name: ', lower-case(@name), translate(specgen:Key, '@', ''), '&#x0a;')"/>
			<xsl:text>        in: path&#x0a;        description: >-&#x0a;          </xsl:text>
			<xsl:apply-templates select="specgen:Item[concat('@', specgen:Attribute)
										 eq current()/specgen:Key]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
			<xsl:text>        required: true&#x0a;</xsl:text>
			<xsl:text>        type: string&#x0a;</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="." mode="responsesSingle"/>
	</xsl:template>

    <xsl:template match="specgen:DataObject" mode="responsesSingle">
		<xsl:text>      responses:&#x0a;</xsl:text>
        <xsl:text>        '200':&#x0a;</xsl:text>
        <xsl:text>          description: successful operation&#x0a;</xsl:text>
		<xsl:text>          schema:&#x0a;</xsl:text>
		<xsl:text>            type: object&#x0a;</xsl:text>
		<xsl:text>            properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('              ', @name, ':&#x0a;')"/>
		<xsl:value-of select="concat('                $ref: ''#/definitions/', @name, '''&#x0a;')"/>
	</xsl:template>
    <xsl:template match="specgen:DataObject" mode="responsesList">
		<xsl:text>      responses:&#x0a;</xsl:text>
        <xsl:text>        '200':&#x0a;</xsl:text>
        <xsl:text>          description: successful operation&#x0a;</xsl:text>
		<xsl:text>          schema:&#x0a;</xsl:text>
		<xsl:text>            type: object&#x0a;</xsl:text>
		<xsl:text>            properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('              ', @name, 's:&#x0a;')"/>
		<xsl:value-of select="concat('                $ref: ''#/definitions/', @name, 's''&#x0a;')"/>
	</xsl:template>

	<xsl:template match="specgen:DataObject" mode="schemasSingle">
		<xsl:text>  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', @name, ':&#x0a;',
			                         '    type: object&#x0a;',
			                         '    description: &gt;-&#x0a;      ')"/>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
		<xsl:text>    properties:&#x0a;</xsl:text>
		<xsl:apply-templates select="specgen:Item[position() gt 1]">
			<xsl:with-param name="indent" select="'      '"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="specgen:DataObject" mode="schemasList">
		<xsl:text>  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', @name, 's:&#x0a;',
			                         '    type: object&#x0a;',
			                         '    description: &gt;-&#x0a;      A List of ', @name, ' objects&#x0a;')"/>
		<xsl:text>    properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      ', @name, ':&#x0a;')"/>
		<xsl:text>        type: array&#x0a;</xsl:text>
		<xsl:text>        items:&#x0a;</xsl:text>
		<xsl:value-of select="concat('          $ref: ''#/definitions/', @name, '''&#x0a;&#x0a;')"/>
	</xsl:template>		
	

	<xsl:template match="specgen:CommonElement[count(specgen:Item) eq 1 and
						 not(starts-with(specgen:Item[1]/specgen:Type/@name, 'xs:'))]">
		<xsl:text>&#x0a;  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;')"/>
		<xsl:text>    allOf:&#x0a;</xsl:text>

		<!-- Pickup Type ref -->
		<xsl:apply-templates select="specgen:Item[1]/specgen:Type">
			<xsl:with-param name="indent" select="'    - '"/>
		</xsl:apply-templates>

		<xsl:text>    - description: &gt;-&#x0a;        </xsl:text>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
	</xsl:template>
	

	<xsl:template match="specgen:CommonElement[count(specgen:Item) gt 1 or
						 starts-with(specgen:Item[1]/specgen:Type/@name, 'xs:')]">
		<xsl:text>&#x0a;  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', xfn:chopType(@name), ':&#x0a;')"/>

		<xsl:text>    description: &gt;-&#x0a;      </xsl:text>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>

		<!-- Simple and extended Types -->
		<xsl:apply-templates select="specgen:Item[1]/specgen:Type">
			<xsl:with-param name="indent" select="'  '"/>
		</xsl:apply-templates>
		
		<!-- What kind of CommonElement is it ?
			 - Object
			 - List of objects
		-->
		<xsl:choose>
			<!-- List of Object -->
			<xsl:when test="count(specgen:Item[1]/specgen:List) gt 0">
				<xsl:text>    type: object&#x0a;</xsl:text>
				<xsl:text>    properties:&#x0a;</xsl:text>
				<xsl:value-of select="concat('      ', specgen:Item[2]/specgen:Element, ':&#x0a;')"/>
				<xsl:text>        type: array&#x0a;</xsl:text>
				<xsl:text>        items:&#x0a;</xsl:text>
				<xsl:value-of select="concat('          $ref: ''#/definitions/', xfn:chopType(specgen:Item[2]/specgen:Type/@name), '''&#x0a;')"/>
			</xsl:when>
			
			<!-- Object -->
			<xsl:when test="count(specgen:Item[1][specgen:Type]) eq 0">
				<xsl:text>    type: object&#x0a;</xsl:text>
				
				<xsl:if test="count(specgen:Item) gt 1">
					<xsl:text>    properties:&#x0a;</xsl:text>
				</xsl:if>
			</xsl:when>
		</xsl:choose>

		<!-- Add properties for non-List objects, indent is different depending on
		     - properties are being added to an extension of a base type
		     - properties are being added to an ordinary object
		-->
		<xsl:if test="count(specgen:Item[1]/specgen:List) eq 0">
			<xsl:apply-templates select="specgen:Item[position() gt 1]">
				<xsl:with-param name="indent">
					<xsl:choose>
						<xsl:when test="count(specgen:Item[1]/specgen:Type/[@complex]) gt 0">
							<xsl:text>          </xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>      </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>


	<!-- Item is of a named Type -->
	<xsl:template match="specgen:Item[count(specgen:Type/@ref) gt 0]">
		<xsl:param name="indent"/>
		
		<xsl:value-of select="concat($indent, specgen:Element|specgen:Attribute, ':&#x0a;')"/>

		<xsl:value-of select="concat($indent, '  allOf:&#x0a;')"/>
		
		<!-- $ref -->
		<xsl:choose>
			<xsl:when test="specgen:Type/@name ne ''">
				<xsl:apply-templates select="specgen:Type">
					<xsl:with-param name="indent" select="concat($indent, '  -')"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="preceding-sibling::specgen:Item[1]/specgen:Type">
					<xsl:with-param name="indent" select="concat($indent, '  - ')"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:if test="normalize-space(specgen:Description) ne ''">
			<xsl:value-of select="concat($indent, '  - description: &gt;-&#x0a;', $indent, '      ')"/>
			<xsl:apply-templates select="specgen:Description"/><xsl:text>&#x0a;</xsl:text>
		</xsl:if>

		<xsl:apply-templates select="specgen:Values">
			<xsl:with-param name="indent" select="$indent"/>
		</xsl:apply-templates>

		<xsl:if test="specgen:Attribute"> 
			<xsl:value-of select="concat($indent, '  - xml:&#x0a;', $indent, '      attribute: true&#x0a;')"/>
		</xsl:if>
	</xsl:template>


	<!-- Item isn't a named type -->
	<xsl:template match="specgen:Item[count(specgen:Type/@ref) eq 0]">
		<xsl:param name="indent"/>
		
		<xsl:value-of select="concat($indent, specgen:Element|specgen:Attribute, ':&#x0a;')"/>
	
		<!-- $ref -->
		<xsl:choose>
			<xsl:when test="specgen:Type/@name ne ''">
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

		<xsl:if test="specgen:Attribute"> 
			<xsl:value-of select="concat($indent, '  xml:&#x0a;', $indent, '    attribute: true&#x0a;')"/>
		</xsl:if>
	</xsl:template>


	
	<!--  Type is an extension of a base type -->
	<xsl:template match="specgen:Type[@complex = 'extension']">
		<xsl:text>    allOf:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      - $ref: ''#/definitions/', xfn:chopType(@name), '''&#x0a;')"/>
		<xsl:text>      - type: object&#x0a;</xsl:text>
		<xsl:text>        properties:&#x0a;</xsl:text>
	</xsl:template>


	
	<!-- Type is of known xs:type -->
	<xsl:template match="specgen:Type[not(@complex) and starts-with(@name, 'xs:')]">
		<xsl:param name="indent"/>

		<xsl:choose>
			<xsl:when test="   @name eq 'xs:integer'
							or @name eq 'xs:int'">
				<xsl:value-of select="concat($indent, '  type: integer&#x0a;')"/>
			</xsl:when>
			
			<xsl:when test="@name eq 'xs:unsignedInt'">
				<xsl:value-of select="concat($indent, '  type: integer&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  minimum: 0&#x0a;')"/>
				<xsl:value-of select="concat($indent, '  maximum: 4294967295&#x0a;')"/>
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
		<xsl:value-of select="concat($indent, ' $ref: ''#/definitions/',
                                      xfn:chopType(@name), '''&#x0a;')"/>
	</xsl:template>

	<!-- Un-named type, so inline object -->
	<xsl:template match="specgen:Type">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, '  type: object&#x0a;')"/>
	</xsl:template>

	

	<!-- CodeSets become enums - with code definitions in the description field -->
    <xsl:template match="specgen:CodeSet">
		<xsl:text>&#x0a;  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  ', ancestor::specgen:Grouping/@code, @name, translate(specgen:ID, '- /', ''), ':&#x0a;',
			                         '    type: string&#x0a;',
							         '    title: ', specgen:ID, '&#x0a;',
			                         '    description: &gt;-&#x0a;      ')"/>
		<xsl:apply-templates select="specgen:Intro"/><xsl:text>&#x0a;</xsl:text>
		<xsl:apply-templates select="specgen:Values" mode="descr">
			<xsl:with-param name="indent" select="'      '"/>
		</xsl:apply-templates>
		
		<xsl:apply-templates select="specgen:Values" mode="enum">
			<xsl:with-param name="indent" select="'    '"/>
		</xsl:apply-templates>
	</xsl:template>


	
	<xsl:template match="specgen:Values" mode="descr">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, '&lt;dl&gt;&#x0a;')"/>
		<xsl:apply-templates select="specgen:Value" mode="descr">
			<xsl:with-param name="indent" select="$indent"/>
		</xsl:apply-templates>
		<xsl:value-of select="concat($indent, '&lt;/dl&gt;&#x0a;')"/>
	</xsl:template>
	
	<xsl:template match="specgen:Value" mode="descr">
		<xsl:param name="indent"/>

		<xsl:variable name="valDesc">
			<xsl:apply-templates select="specgen:Text"/>
		</xsl:variable>

		<xsl:value-of select="concat($indent,  '&lt;dt&gt;''', specgen:Code, '''&lt;/dt&gt;',
							                   '&lt;dd&gt;''', $valDesc, '''&lt;/dd&gt;&lt;br/&gt;&#x0a;')"/>
	</xsl:template>



	
	<xsl:template match="specgen:Values" mode="enum">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat($indent, 'enum: [')"/>
		<xsl:apply-templates select="specgen:Value" mode="enum"/>
		<xsl:text>]&#x0a;</xsl:text>
	</xsl:template>
	
	<xsl:template match="specgen:Value[position() gt 1]" mode="enum">
		<xsl:param name="indent"/>
		<xsl:value-of select="concat(', ''', specgen:Code, '''')"/>
	</xsl:template>

	<xsl:template match="specgen:Value" mode="enum">
		<xsl:value-of select="concat('''', specgen:Code, '''')"/>
	</xsl:template>




	
	<!-- Bring Description, Intro or Text mixed content elements across with all its embedded html -->
	<xsl:template match="specgen:Description|specgen:Intro|specgen:Text">
		<xsl:variable name="descr"><xsl:apply-templates/></xsl:variable>

		<xsl:value-of select="normalize-space(translate($descr, ':', ''))"/>
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
</xsl:stylesheet>
