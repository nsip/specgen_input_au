<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
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
	
	<xsl:variable name="extDocUrlRoot">
	    <xsl:value-of select="concat('http://specification.sifassociation.org/Implementation/NZ/', translate(replace($sifVersion, ' \(', '-'), ') ', ''), '/')"/>
	</xsl:variable>
	
	<xsl:template match="/specgen:SIFSpecification">
		<xsl:value-of select="concat( 'openapi: 3.0.2&#x0a;',
                                      'info:&#x0a;',
                                      '  version: ', $sifVersion, '&#x0a;',
                                      '  title: &quot;SIF ', $sifLocale, ' derived API&quot;&#x0a;',
									  '  description: >-&#x0a;', 
									  '    ', normalize-space(specgen:TitlePage/specgen:h1), '&#x0a;',
									  '    &lt;p&gt;Sample OpenAPI specification, (although somewhat incomplete) derived from SIF locale data model&#x0a;',
									  '    A complete specification requires:&lt;/p&gt;&lt;ul&gt;&#x0a;',
                                      '    &lt;li&gt;Responses on POST, PUT and DELETE verbs&lt;/li&gt;&#x0a;',
									  '    &lt;li&gt;Decide which requests can accept / return single object or object collection&lt;/li&gt;&#x0a;',
									  '    &lt;li&gt;Decide which SIF Infrastructure API endpoints are to be included&lt;/li&gt;&#x0a;',
									  '    &lt;/ul&gt;&#x0a;',
									  '  host: &quot;api.terito.education.govt.nz&quot;&#x0a;',
									  '  basePath: &quot;v3&quot;&#x0a;')"/>

		<!-- Only some Locales have DomainMaps -->
		<xsl:if test=".//specgen:Section[@name = 'Domain Map']">
			<xsl:text># /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
			<xsl:apply-templates select=".//specgen:Section[@name = 'Domain Map']" mode="DomainMap"/>
		
			<xsl:text># /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
			<xsl:apply-templates select=".//specgen:Section[@name = 'Domain Map']" mode="Tags"/>
		</xsl:if>

		<xsl:text># /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:apply-templates select=".//specgen:DataObjects" mode="paths"/>
	</xsl:template>


	<!-- Data models might have DomainMaps to help drive ToC -->
	<xsl:template match="specgen:Section" mode="DomainMap">
		<xsl:text>x-tagGroups:&#x0a;</xsl:text>
		<xsl:apply-templates select="specgen:Domain" mode="DomainMap"/>
	</xsl:template>

	<xsl:template match="specgen:Domain" mode="DomainMap">
		<xsl:value-of select="concat('  - name: ', $q, @name, $q, '&#x0a;',
		                             '    tags:&#x0a;',
								     '      - ', $q, translate(@name, ' /-&amp;', ''), 'Overview', $q, '&#x0a;')"/>
		<xsl:apply-templates select="specgen:DataObject" mode="DomainMap"/>
	</xsl:template>

	<xsl:template match="specgen:DataObject[@role = 'member']" mode="DomainMap">
		<xsl:value-of select="concat('      - ', $q, ., $q, '&#x0a;')"/>
	</xsl:template>
	<xsl:template match="specgen:DataObject" mode="DomainMap"/>


	<xsl:template match="specgen:Section" mode="Tags">
	   <xsl:text>tags:&#x0a;</xsl:text>
	   <xsl:apply-templates select="specgen:Domain" mode="Tags"/>
	   <xsl:apply-templates select="//specgen:DataObjects//specgen:Group//specgen:DataObject" mode="Tags"/>
	</xsl:template>

	<xsl:template match="specgen:Domain" mode="Tags">
		<xsl:value-of select="concat('  - name: ', $q, translate(@name, ' /-&amp;', ''), 'Overview', $q, '&#x0a;',
		                             '    x-displayName: ', $q, @name, ' Overview', $q, '&#x0a;',
									 '    description: &gt;-&#x0a;      ')"/>
		<xsl:apply-templates select="specgen:Intro"/><xsl:text>&#x0a;</xsl:text>
		<xsl:value-of select="concat('    externalDocs: &#x0a;',
		                             '      description: &quot;', @name, ' Domain in SIF NZ Data Model&quot;&#x0a;',
									 '      url: &quot;', $extDocUrlRoot, '/DomainMap.html#Domain__', xfn:cleanUrl(@name), '&quot;&#x0a;')"/>

	</xsl:template>

	<xsl:template match="specgen:DataObject" mode="Tags">
	    <xsl:value-of select="concat('  - name: ', $q, @name, $q, '&#x0a;',
									 '    description: &gt;-&#x0a;      ')"/>
		<xsl:apply-templates select="specgen:Item[1]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
	</xsl:template> 



	<xsl:template match="specgen:DataObjects" mode="paths">
		<xsl:text>paths:&#x0a;</xsl:text>		
		<xsl:apply-templates select=".//specgen:DataObject" mode="paths"/>
	</xsl:template>              

	<xsl:template match="specgen:DataObject" mode="paths">
		<xsl:text>  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
		<xsl:value-of select="concat('  /', @name, 's:&#x0a;')"/>
		<xsl:text>    get:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
		<xsl:value-of select="concat('      summary: Default operation to get a list of all available ', @name, 's&#x0a;')"/>
		<xsl:apply-templates select="." mode="responsesList">
			<xsl:with-param name="schemaId">Create</xsl:with-param>
		</xsl:apply-templates>

		<xsl:text>    post:&#x0a;</xsl:text>
		<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
		<xsl:value-of select="concat('      summary: Default operation to create a single ', @name, '&#x0a;')"/>
		<xsl:apply-templates select="." mode="requestBody">
			<xsl:with-param name="operationId" select="concat('create', @name)"/>
			<xsl:with-param name="schemaId">Create</xsl:with-param>
		</xsl:apply-templates>
		
		<xsl:if test="specgen:Key">
			<xsl:text>  # /////////////////////////////////////////////////////////////&#x0a;</xsl:text>
			<xsl:value-of select="concat('  /', @name, 's/{', translate(specgen:Key, '@', ''), '}:&#x0a;')"/>

			<xsl:text>    put:&#x0a;</xsl:text>
			<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
			<xsl:value-of select="concat('      summary: Default operation to update a single ', @name, '&#x0a;')"/>
			<xsl:value-of select="concat('      parameters:&#x0a;      - name: ', translate(specgen:Key, '@', ''), '&#x0a;')"/>
			<xsl:text>        in: path&#x0a;        description: >-&#x0a;          </xsl:text>
			<xsl:apply-templates select="specgen:Item[specgen:Element eq current()/specgen:Key]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
			<xsl:text>        required: true&#x0a;</xsl:text>
			<xsl:text>        schema:&#x0a;</xsl:text>
			<xsl:text>          type: string&#x0a;</xsl:text>
			<xsl:apply-templates select="." mode="requestBody">
				<xsl:with-param name="operationId" select="concat('update', @name)"/>
				<xsl:with-param name="schemaId">Update</xsl:with-param>
			</xsl:apply-templates>

			<xsl:text>    get:&#x0a;</xsl:text>
			<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
			<xsl:value-of select="concat('      summary: Default operation to get a single ', @name, '&#x0a;')"/>
			<xsl:value-of select="concat('      parameters:&#x0a;      - name: ', translate(specgen:Key, '@', ''), '&#x0a;')"/>
			<xsl:text>        in: path&#x0a;        description: >-&#x0a;          </xsl:text>
			<xsl:apply-templates select="specgen:Item[specgen:Element eq current()/specgen:Key]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
			<xsl:text>        required: true&#x0a;</xsl:text>
			<xsl:text>        schema:&#x0a;</xsl:text>
			<xsl:text>          type: string&#x0a;</xsl:text>
			<xsl:apply-templates select="." mode="responsesSingle">
				<xsl:with-param name="schemaId">Create</xsl:with-param>
			</xsl:apply-templates>

			<xsl:text>    delete:&#x0a;</xsl:text>
			<xsl:value-of select="concat('      tags:&#x0a;      - ', $q, @name, $q, '&#x0a;')"/>
			<xsl:value-of select="concat('      summary: Default operation to delete a single ', @name, '&#x0a;')"/>
			<xsl:value-of select="concat('      parameters:&#x0a;      - name: ', translate(specgen:Key, '@', ''), '&#x0a;')"/>
			<xsl:text>        in: path&#x0a;        description: >-&#x0a;          </xsl:text>
			<xsl:apply-templates select="specgen:Item[specgen:Element eq current()/specgen:Key]/specgen:Description"/><xsl:text>&#x0a;</xsl:text>
			<xsl:text>        required: true&#x0a;</xsl:text>
			<xsl:text>        schema:&#x0a;</xsl:text>
			<xsl:text>          type: string&#x0a;</xsl:text>
			<xsl:text>      responses:&#x0a;</xsl:text>
			<xsl:text>        '200':&#x0a;</xsl:text>
			<xsl:text>          description: successful operation&#x0a;</xsl:text>
		</xsl:if>
	</xsl:template>

    <xsl:template match="specgen:DataObject" mode="requestBody">
		<xsl:param name="operationId"/>
		<xsl:param name="schemaId"/>

		<xsl:value-of select="concat('      operationId: ', $operationId, '&#x0a;')"/>		
		<xsl:text>      requestBody:&#x0a;</xsl:text>
        <xsl:value-of select="concat('        description: CRUD operation on ', @name, '&#x0a;')"/>
		<xsl:text>        content:&#x0a;</xsl:text>
		<xsl:text>          application/json:&#x0a;</xsl:text>
		<xsl:text>            schema:&#x0a;</xsl:text>
		<xsl:text>              type: object&#x0a;</xsl:text>
		<xsl:text>              properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                ', @name, ':&#x0a;')"/>
		<xsl:value-of select="concat('                  $ref: ''jsonSchema', $schemaId, '.yaml#/properties/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="json">
			<xsl:with-param name="pfx"><xsl:text>            </xsl:text></xsl:with-param>
		</xsl:apply-templates>
		<xsl:text>          application/xml:&#x0a;</xsl:text>
		<xsl:text>            schema:&#x0a;</xsl:text>
		<xsl:text>              type: object&#x0a;</xsl:text>
		<xsl:text>              properties:&#x0a;</xsl:text>		
		<xsl:value-of select="concat('                ', @name, ':&#x0a;')"/>
		<xsl:value-of select="concat('                  $ref: ''jsonSchema', $schemaId, '.yaml#/properties/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="xml">
			<xsl:with-param name="pfx"><xsl:text>            </xsl:text></xsl:with-param>
		</xsl:apply-templates>
	</xsl:template>

    <xsl:template match="specgen:DataObject" mode="responsesSingle">
		<xsl:param name="schemaId"/>

		<xsl:text>      responses:&#x0a;</xsl:text>
        <xsl:text>        '200':&#x0a;</xsl:text>
        <xsl:text>          description: successful operation&#x0a;</xsl:text>
		<xsl:text>          content:&#x0a;</xsl:text>
		<xsl:text>            application/json:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:text>                type: object&#x0a;</xsl:text>
		<xsl:text>                properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                  ', @name, ':&#x0a;')"/>
		<xsl:value-of select="concat('                    $ref: ''jsonSchema', $schemaId, '.yaml#/properties/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="json">
			<xsl:with-param name="pfx"><xsl:text>              </xsl:text></xsl:with-param>
		</xsl:apply-templates>		
		<xsl:text>            application/xml:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:text>                type: object&#x0a;</xsl:text>
		<xsl:text>                properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                  ', @name, ':&#x0a;')"/>
		<xsl:value-of select="concat('                    $ref: ''jsonSchema', $schemaId, '.yaml#/properties/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="xml">
			<xsl:with-param name="pfx"><xsl:text>              </xsl:text></xsl:with-param>
		</xsl:apply-templates>		
	</xsl:template>

    <xsl:template match="specgen:DataObject" mode="responsesList">
		<xsl:param name="schemaId"/>

		<xsl:text>      responses:&#x0a;</xsl:text>
        <xsl:text>        '200':&#x0a;</xsl:text>
        <xsl:text>          description: successful operation&#x0a;</xsl:text>
		<xsl:text>          content:&#x0a;</xsl:text>
		<xsl:text>            application/json:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:text>                type: object&#x0a;</xsl:text>
		<xsl:text>                properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                  ', @name, 's:&#x0a;')"/>
        <xsl:text>                    type: object&#x0a;</xsl:text>
        <xsl:text>                    description: >-&#x0a;</xsl:text>
        <xsl:value-of select="concat('                      A List of ', @name, ' objects&#x0a;')"/>
        <xsl:text>                    properties:&#x0a;</xsl:text>
        <xsl:value-of select="concat('                      ', @name, ':&#x0a;')"/>
        <xsl:text>                        type: array&#x0a;</xsl:text>
        <xsl:text>                        items:&#x0a;</xsl:text>
        <xsl:value-of select="concat('                          $ref: ''jsonSchema', $schemaId, '.yaml#/properties/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="jsonArray">
			<xsl:with-param name="pfx"><xsl:text>              </xsl:text></xsl:with-param>
		</xsl:apply-templates>		

		<xsl:text>            application/xml:&#x0a;</xsl:text>
		<xsl:text>              schema:&#x0a;</xsl:text>
		<xsl:text>                type: object&#x0a;</xsl:text>
		<xsl:text>                properties:&#x0a;</xsl:text>
		<xsl:value-of select="concat('                  ', @name, 's:&#x0a;')"/>
        <xsl:text>                    type: object&#x0a;</xsl:text>
        <xsl:text>                    description: >-&#x0a;</xsl:text>
        <xsl:value-of select="concat('                      A List of ', @name, ' objects&#x0a;')"/>
        <xsl:text>                    properties:&#x0a;</xsl:text>
        <xsl:value-of select="concat('                      ', @name, ':&#x0a;')"/>
        <xsl:text>                        type: array&#x0a;</xsl:text>
        <xsl:text>                        items:&#x0a;</xsl:text>
        <xsl:value-of select="concat('                          $ref: ''jsonSchema', $schemaId, '.yaml#/properties/', @name, '''&#x0a;')"/>
		<xsl:apply-templates select="xhtml:Example[lower-case(@intl)=lower-case($sifLocale) or not(@intl)][1]" mode="xmlList">
			<xsl:with-param name="pfx"><xsl:text>              </xsl:text></xsl:with-param>
		</xsl:apply-templates>		
		
	</xsl:template>

	<xsl:template match="xhtml:Example" mode="json">
		<xsl:param name="pfx"/>

		<xsl:value-of select="concat($pfx, 'example:&#x0a;')"/>
		<xsl:value-of select="xfn:jsonString(*, concat($pfx, '  '), 0)"/>
	</xsl:template>	
	<xsl:template match="xhtml:Example" mode="jsonArray">
		<xsl:param name="pfx"/>

		<xsl:value-of select="concat($pfx, 'example:&#x0a;')"/>
		<xsl:value-of select="xfn:jsonString(*, concat($pfx, '  '), 1)"/>
	</xsl:template>

	<xsl:template match="xhtml:Example" mode="xml">
		<xsl:param name="pfx"/>

		<xsl:value-of select="concat($pfx, 'example: &gt;-&#x0a;')"/>
		<xsl:value-of select="xfn:xmlString(*, concat($pfx, '  '), 0)"/>
	</xsl:template>
	<xsl:template match="xhtml:Example" mode="xmlList">
		<xsl:param name="pfx"/>

		<xsl:value-of select="concat($pfx, 'example: &gt;-&#x0a;')"/>
		<xsl:value-of select="xfn:xmlString(*, concat($pfx, '  '), 1)"/>
	</xsl:template>

	<!-- Bring Description, Intro or Text mixed content elements across with all its embedded html -->
	<xsl:template match="specgen:Description|specgen:Intro|specgen:Text">
		<xsl:variable name="descr"><xsl:apply-templates/></xsl:variable>

		<xsl:value-of select="normalize-space(translate($descr, ':', ''))"/>
	</xsl:template>
	<xsl:template match="specgen:p|specgen:br|specgen:a
						 |specgen:code|specgen:strong|specgen:em|specgen:span
						 |specgen:h1|specgen:h2|specgen:h3|specgen:h4
						 |specgen:ul|specgen:ol|specgen:li
						 |specgen:dl|specgen:dt|specgen:dd
						 |specgen:table|specgen:thead|specgen:tbody|specgen:tr|specgen:th|specgen:td">
		<xsl:value-of select="concat('&lt;', local-name(.))"/>
		<xsl:for-each select="@*">
			<xsl:value-of select="concat(' ', local-name(.), '=&quot;', . , '&quot;')"/>
		</xsl:for-each>
		<xsl:choose>
			<xsl:when test="not(*) and not(normalize-space())">
				<xsl:text>/&gt;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&gt;</xsl:text>
				<xsl:apply-templates/>
				<xsl:value-of select="concat('&lt;/', local-name(.), '&gt;')"/>
			</xsl:otherwise>
		</xsl:choose>
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

	<xsl:function name="xfn:jsonString" as="xs:string">
		<xsl:param name="inXml"/>
		<xsl:param name="pfx"/>
		<xsl:param name="isCollection"/>

		<xsl:variable name="outStr">
			<xsl:apply-templates select="$inXml" mode="nodetojson">
				<xsl:with-param name="pfx">
					<xsl:choose>
						<xsl:when test="$isCollection">
							<xsl:value-of select="concat($pfx, '  ')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$pfx"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>

				<xsl:with-param name="isCollection" select="$isCollection"/>
			</xsl:apply-templates>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="$isCollection">
				<xsl:value-of select="concat($pfx, '&quot;', name($inXml), 's&quot;: { &#x0a;', $outStr, $pfx, '}&#x0a;')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$outStr"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:variable name="q">
		<xsl:text>"</xsl:text>
	</xsl:variable>
	<xsl:variable name="empty"/>


	<xsl:template match="*" mode="selfclosetag">
		<xsl:value-of select="concat('&lt;', name())"/>
		<xsl:apply-templates select="@*[not(namespace-uri() = 'http://json.org/')]" mode="attribs"/>
		<xsl:text>/&gt;&#x0a;</xsl:text>
	</xsl:template>

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
						<xsl:value-of select="concat($pfx2, '&lt;', name(), '&gt;&#x0a;')"/> 

						<xsl:apply-templates select="*" mode="nodetostring">
							<xsl:with-param name="pfx" select="concat($pfx2, '  ')"/>
						</xsl:apply-templates>
						<xsl:value-of select="concat($pfx2, '&lt;/', name(), '&gt;&#x0a;')"/>
					</xsl:when>
					<!--
						Just a text element 
					-->
					<xsl:otherwise>
						<xsl:value-of select="concat($pfx2, '&lt;/', name(), '&gt;', normalize-space(.),'&lt;/', name(), '&gt;&#x0a;')"/> 
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

	<xsl:template match="*" mode="nodetojson">
		<xsl:param name="pfx"/>
		<xsl:param name="isCollection" select="0"/>

		<xsl:choose>
			<xsl:when test="boolean(name())">

				<xsl:variable name="isArray" select="    (count(../*[name() = name(current())]) > 1) 
				                                     or  @json:force-array = 'true'"/>
				<xsl:choose>
					<!-- element has children -->
					<xsl:when test="*">
						<xsl:value-of select="$pfx"/>

						<xsl:choose>
							<xsl:when test="$isArray and position() > 1"><xsl:text> </xsl:text></xsl:when>
							<xsl:when test="$isArray"><xsl:value-of select="concat('&quot;',name(), '&quot;: [')"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="concat('&quot;', name(), '&quot;: ')"/></xsl:otherwise>
						</xsl:choose>

						<xsl:if test="$isCollection"><xsl:text>[</xsl:text></xsl:if>
						<xsl:text>{ &#x0a;</xsl:text>
						<xsl:apply-templates select="*" mode="nodetojson">
							<xsl:with-param name="pfx" select="concat($pfx, '  ')"/>
						</xsl:apply-templates>
						<xsl:value-of select="concat($pfx, '}')"/>
						<xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
						<xsl:if test="$isArray and position() = last() or $isCollection"><xsl:text>]</xsl:text></xsl:if>
						<xsl:text>&#x0a;</xsl:text>
					</xsl:when>

					<!--
						Element has no children
					-->
					<xsl:otherwise>
						<xsl:choose>
							<!-- An empty element -->
							<xsl:when test="normalize-space(.) = ''">
								<xsl:value-of select="concat($pfx, '&quot;', name(), '&quot;: {}')"/>
								<xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
								<xsl:text>&#x0a;</xsl:text>
							</xsl:when>

							<!-- An ordinary atomic valued element (or an array thereof) -->
							<xsl:otherwise>
								<xsl:value-of select="$pfx"/>
								<xsl:if test="not($isArray) or (position() = 1)">
									<xsl:value-of select="concat('&quot;', name(), '&quot;: ')"/>
								</xsl:if>

								<xsl:if test="$isArray and position() = 1"><xsl:text>[</xsl:text></xsl:if>

								<xsl:choose>
									<!--
										A value is considered a string if the following conditions are met:
										* There is whitespace/formatting around the value of the node.
										* The value is not a valid JSON number (i.e. '01', '+1', '1.', and '.5' are not valid JSON numbers.)
										* The value does not equal the any of the following strings: 'false', 'true', 'null'.
									-->
									<xsl:when test="./@json:force-string eq 'true' or ((normalize-space(.) ne . or not((string(.) castable as xs:integer  and not(starts-with(string(.),'+')) and not(starts-with(string(.),'0') and not(. = '0'))) or (string(.) castable as xs:decimal  and not(starts-with(string(.),'+')) and not(starts-with(.,'-.')) and not(starts-with(.,'.')) and not(starts-with(.,'-0') and not(starts-with(.,'-0.'))) and not(ends-with(.,'.')) and not(starts-with(.,'0') and not(starts-with(.,'0.'))) )) and not(. = 'false') and not(. = 'true') and not(. = 'null')))">             
										<xsl:text/>&quot;<xsl:value-of select="json:encode-string(.)"/>&quot;<xsl:text/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text/><xsl:value-of select="."/><xsl:text/>
									</xsl:otherwise>
								</xsl:choose>

								<xsl:if test="$isArray and position() = last()"><xsl:text>]</xsl:text></xsl:if>
								<xsl:if test="position() != last()"><xsl:text>,</xsl:text></xsl:if>
								<xsl:text>&#x0a;</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat('&quot;Uuuurrrrkkkkk', ., '&quot;,')"/>
			</xsl:otherwise>
		</xsl:choose>
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
</xsl:stylesheet>