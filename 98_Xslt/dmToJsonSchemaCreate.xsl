<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:specgen="http://sifassociation.org/SpecGen"
	xmlns:xfn="http://stuart.geek.nz/xslt-functions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xml="http://www.w3.org/XML/1998/namespace">

	<!-- Take a SIF_DataModel.input.xml file and produce a matching Json Schema -->
	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
	
	<xsl:param name="sifVersion"/>
	<xsl:param name="sifLocale"/>

	<!-- This Schema is for CREATE so mandatory fields are REQUIRED -->
	<xsl:param name="mandatoryFields">required</xsl:param>

	<!-- How many enumeration values to include in descriptions ? -->
	<xsl:param name="enumCount">12</xsl:param>

	<!-- Include all the vendor extensions ?? -->
	<xsl:param name="strictJSON">false</xsl:param>
	
	<!-- Where is the SIF HTML documentation available for links -->
	<xsl:variable name="extDocURLBase">
		<xsl:value-of select="concat('http://specification.sifassociation.org/Implementation/', $sifLocale, '/', translate(replace($sifVersion, ' \(', '-'), ') ', ''), '/')"/>
	</xsl:variable>

    <!-- Now that we've configured all the options -->
    <xsl:include href="dmToJsonSchema.xsl"/>
</xsl:stylesheet>