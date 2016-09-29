<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
	  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	  xmlns:fn="fn" 
	  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	  exclude-result-prefixes="xs fn">
  
<!--This can be used for simple transformation of tab delimited thesaurus mappings files produced by partners-->
<xsl:output method="text" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" standalone="yes"/>

<!--params are actually passed in as parameter (see associated batch file) - these are just for standalone testing-->
<xsl:param name="inputFilePath" as="xs:string" select="'file:///test.txt'" />
<xsl:param name="lang" as="xs:string" select="'en'"/><!--language of source data labels-->
<xsl:param name="format" as="xs:string" select="'json'"/><!--json or nt-->
<xsl:param name="source" as="xs:string" select="'tmp.txt'"/><!--source data file-->
<!--TODO: could modularize by putting functions into separate files like this: <xsl:include href="getFullUriFromShortUri.xslt"/>-->

<!-- get full URI from short prefixed URI e.g. "skos:Concept" becomes "http://www.w3.org/2004/02/skos/core#Concept" -->
<!-- if URI is already full URI, or if the prefix is not one of the know prefixes then it is just returned as is -->
<xsl:function name="fn:getFullUriFromShortUri" as="xs:string">
	<xsl:param name="uri" as="xs:string" />
	
	<xsl:variable name="prefix" as="xs:string" select="substring-before(normalize-space($uri), ':')"/>	
	<xsl:variable name="suffix" as="xs:string" select="substring-after(normalize-space($uri), ':')"/>
	
	<!--expand namespace if it's a known alias, otherwise leave it alone. (Note in XSLT 2.0 there is now fn:namespace-uri-for-prefix)-->
	<xsl:choose>
		<xsl:when test="($prefix='dc')">
			<xsl:value-of select="concat('http://purl.org/dc/elements/1.1/', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='dct')">
			<xsl:value-of select="concat('http://purl.org/dc/terms/', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='foaf')">
			<xsl:value-of select="concat('http://xmlns.com/foaf/spec/', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='owl')">
			<xsl:value-of select="concat('http://www.w3.org/TR/owl-ref/', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='rdf')">
			<xsl:value-of select="concat('http://www.w3.org/1999/02/22-rdf-syntax-ns#', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='rdfs')">
			<xsl:value-of select="concat('http://www.w3.org/2000/01/rdf-schema#', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='skos')">
			<xsl:value-of select="concat('http://www.w3.org/2004/02/skos/core#', $suffix)" />
		</xsl:when>	
		<xsl:when test="($prefix='crm')">
			<xsl:value-of select="concat('http://www.cidoc-crm.org/cidoc-crm/', $suffix)" />
		</xsl:when>	
		<xsl:when test="($prefix='fasti')">
			<xsl:value-of select="concat('http://www.fastionline.org/concept/attribute/', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='aat')">
			<xsl:value-of select="concat('http://vocab.getty.edu/aat/', $suffix)" />
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="normalize-space($uri)"/>
		</xsl:otherwise>
	</xsl:choose>	
		
</xsl:function>

<!-- get short URI from full URI e.g. "http://www.w3.org/2004/02/skos/core#Concept" becomes "skos:Concept" -->
<!-- if not one of the known alias prefixes then URI is returned as it is -->
<xsl:function name="fn:getShortUriFromFullUri" as="xs:string">
	<xsl:param name="uri" as="xs:string" />
	
	<xsl:variable name="prefix" as="xs:string" select="substring-before(normalize-space($uri), ':')"/>	
	<xsl:variable name="suffix" as="xs:string" select="substring-after(normalize-space($uri), ':')"/>
	
	<!--get short alias from full namespace prefix-->
	<xsl:choose>
		<xsl:when test="($prefix='http://purl.org/dc/elements/1.1/')">
			<xsl:value-of select="concat('dc:', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='http://purl.org/dc/terms/')">
			<xsl:value-of select="concat('dct:', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='http://xmlns.com/foaf/spec/')">
			<xsl:value-of select="concat('foaf:', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='http://www.w3.org/TR/owl-ref/')">
			<xsl:value-of select="concat('owl:', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='http://www.w3.org/1999/02/22-rdf-syntax-ns#')">
			<xsl:value-of select="concat('rdf:', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='http://www.w3.org/2000/01/rdf-schema#')">
			<xsl:value-of select="concat('rdfs:', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='http://www.w3.org/2004/02/skos/core#')">
			<xsl:value-of select="concat('skos:', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='http://www.cidoc-crm.org/cidoc-crm/')">
			<xsl:value-of select="concat('crm:', $suffix)" />
		</xsl:when>
		<xsl:when test="($prefix='http://www.fastionline.org/concept/attribute/')">
			<xsl:value-of select="concat('fasti:', $suffix)" />
		</xsl:when>				
		<xsl:otherwise>
			<xsl:value-of select="normalize-space($uri)"/>
		</xsl:otherwise>
	</xsl:choose>	
	
</xsl:function>

<!-- If we don't have URIs can construct temp URI from input values -->
<xsl:function name="fn:getTempUriFromString" as="xs:string">
	<xsl:param name="inputValue" as="xs:string" />
	<xsl:variable name="prefix" select="concat('http://tempuri/',$source,'/')"/>
	<xsl:value-of select="concat($prefix, encode-for-uri(normalize-space($inputValue)))"/>
</xsl:function>	

<!--read text file contents to a string-->
<xsl:function name="fn:file2string" as="xs:string">
	<xsl:param name="filePath" as="xs:string" />
	<xsl:choose>
		<xsl:when test="unparsed-text-available($filePath)">	     	
			<xsl:value-of select="unparsed-text($filePath)"/>
		</xsl:when>
		<xsl:otherwise>
	     	<xsl:text>Cannot locate or access: </xsl:text>
	     	<xsl:value-of select="$filePath" />
	     </xsl:otherwise>
     </xsl:choose>
</xsl:function>

<!-- turn tab delimited data (with header row containing field names) into the following xml:
		<row>
			<field @name='field1name'>row1field1value</field>
			<field @name='field2name'>row1field2value</field>
			etc.
		</row>
		<row>
			<field @name='field1name'>row2field1value</field>
			<field @name='field2name'>row2field2value</field>
			etc.
		</row>
-->	
<xsl:function name="fn:tab2xml" as="element(row)*">
	<xsl:param name="tab" as="xs:string" />

	<xsl:variable name="lines" select="tokenize($tab, '&#xD;')" as="xs:string+" />  
	<xsl:variable name="fieldNames" select="tokenize($lines[1], '\t')" as="xs:string*" />
	
	<xsl:for-each select="$lines[position() &gt; 1]">
		<xsl:element name="row">
			<xsl:variable name="lineItems" select="tokenize(., '\t')" as="xs:string*"  />
			<xsl:for-each select="$fieldNames">
				<xsl:variable name="pos" select="position()"/>
				<xsl:element name="field">
					<xsl:attribute name="name">
						<xsl:value-of select="normalize-space($fieldNames[$pos])"/>
					</xsl:attribute>	
					<xsl:value-of select="$lineItems[$pos]" />
				</xsl:element>
			</xsl:for-each>
		</xsl:element>
	</xsl:for-each>
</xsl:function> 

<!--
convert xml (as produced by tab2xml) into ntriples
 i.e. <sourceURI> <skos:matchURI> <targetURI> .
<sourceURI> <http://www.w3.org/2004/02/skos/core#prefLabel> "sourceLabel"@lang .
(default language tag is @en unless a different language is passed in as parameter 'lang')
-->
<xsl:function name="fn:xml2ntriples" as="xs:string*">
	<xsl:param name="xml" as="element(row)*" />
	<xsl:param name="lang" as="xs:string" />  
			    			         
	<!--for each xml element...-->
     <xsl:for-each select="$xml">    	
     		
	     	<xsl:variable name="sourceURI" as="xs:string">
	     		<xsl:choose>
	     			<!--if sourceURI is absent but sourceLabel is present, create URI from sourceLabel-->
					<xsl:when test="not(field[@name='sourceURI']) and field[@name='sourceLabel'] !=''">
						<xsl:value-of select="fn:getTempUriFromString(field[@name='sourceLabel'])"/>
					</xsl:when>
					<xsl:otherwise>
						<!--otherwise just use the sourceURI field-->
						<xsl:value-of select="normalize-space(field[@name='sourceURI'])"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>	
			
			<xsl:variable name="sourceLabel" as="xs:string">
	     		<xsl:choose>
	     			<xsl:when test="not(field[@name='sourceLabel'])">
	     				<xsl:value-of select="''"/><!--blank string-->
	     			</xsl:when>
	     			<xsl:otherwise>
	     				<xsl:value-of select="normalize-space(field[@name='sourceLabel'])"/>
	     			</xsl:otherwise>
				</xsl:choose>
	     	</xsl:variable>
	     	
	     	<xsl:variable name="matchURI" as="xs:string">
	     		<xsl:choose>
	     			<xsl:when test="not(field[@name='matchURI'])">
	     				<xsl:value-of select="''"/><!--blank string-->
	     			</xsl:when>
	     			<xsl:otherwise>
	     				<xsl:value-of select="normalize-space(field[@name='matchURI'])"/>
	     			</xsl:otherwise>
				</xsl:choose>
	     	</xsl:variable>
	     	
	     	<xsl:variable name="matchLabel" as="xs:string">
	     		<xsl:choose>
	     			<xsl:when test="not(field[@name='matchLabel'])">
	     				<xsl:value-of select="''"/><!--blank string-->
	     			</xsl:when>
	     			<xsl:otherwise>
	     				<xsl:value-of select="normalize-space(field[@name='matchLabel'])"/>
	     			</xsl:otherwise>
				</xsl:choose>
	     	</xsl:variable>
	     	
	     	<xsl:variable name="targetURI" as="xs:string">
	     		<xsl:choose>
	     			<xsl:when test="not(field[@name='targetURI'])">
	     				<xsl:value-of select="''"/><!--blank string-->
	     			</xsl:when>
	     			<xsl:otherwise>
	     				<xsl:value-of select="normalize-space(field[@name='targetURI'])"/>
	     			</xsl:otherwise>
				</xsl:choose>
	     	</xsl:variable>		
	     	
	     	<xsl:variable name="targetLabel" as="xs:string">
	     		<xsl:choose>
	     			<xsl:when test="not(field[@name='targetLabel'])">
	     				<xsl:value-of select="''"/><!--blank string-->
	     			</xsl:when>
	     			<xsl:otherwise>
	     				<xsl:value-of select="normalize-space(field[@name='targetLabel'])"/>
	     			</xsl:otherwise>
				</xsl:choose>
	     	</xsl:variable>	     	
				     	     	
	     	<!--construct a single triple for the source-target concept mapping-->	     	
	     	<xsl:if test="($sourceURI  !='' and $matchURI != '' and $targetURI != '')">	     	
	     		<xsl:call-template name="write-ntriple">
	     			<xsl:with-param name="subjectURI" select="$sourceURI"/>
	     			<xsl:with-param name="predicateURI" select="$matchURI"/>
					<xsl:with-param name="objectURI" select="$targetURI"/>					
				</xsl:call-template>
			</xsl:if>	     		
			
			<!--construct a single triple for the source concept preferred label-->
			<xsl:if test="($sourceURI  !='' and $sourceLabel !='')">
				<xsl:call-template name="write-ntriple">
	     			<xsl:with-param name="subjectURI" select="$sourceURI"/>
	     			<xsl:with-param name="predicateURI" select="'rdfs:label'"/><!-- commits less than skos:prefLabel - we don't really know if it's 'preferred'-->
					<xsl:with-param name="objectLiteral" select="$sourceLabel"/>
					<xsl:with-param name="objectLiteralLang" select="$lang"/>
				</xsl:call-template>
			</xsl:if> 
		
     </xsl:for-each>
     
</xsl:function> 

	<!--
	convert XML (as produced by fn:tab2xml) into JSON formatted text e.g.
	[
	 	{ "field1name": "row1field1value", "field2name": "row1field2value" },
	 	{ "field1name": "row2field1value", "field2name": "row2field2value" },
	 	etc.
	]
 	-->
	<xsl:function name="fn:xml2json" as="xs:string*">
		<xsl:param name="xml" as="element(row)*" />
		
		<xsl:text>[&#xD;&#xA;</xsl:text><!--opening array bracket and newline-->
		
		<!--create a record for every row containing data (ignoring blank rows)-->
     	<xsl:for-each select="$xml[count(field[normalize-space(text()) !='']) != 0]">
     	
     		<xsl:text>{&#xD;&#xA;</xsl:text><!--opening brace and newline-->
     		
			<!--VocabularyMatchingTool outputs 'created' date field. If it's missing then add for consistency-->
			<xsl:if test="(normalize-space(field[@name='created'])='')">
				<xsl:value-of select="fn:write-json-property('created', string(current-dateTime()))" />				
				<xsl:text>,&#xD;&#xA;</xsl:text><!--comma and newline-->
			</xsl:if>
			
			<!--if sourceURI is absent but sourceLabel is present, create temp URI from sourceLabel-->
			<xsl:if test="(normalize-space(field[@name='sourceURI'])='')">
				<xsl:if test="(normalize-space(field[@name='sourceLabel'])!='')">
					<xsl:variable name="sourceURI" select="fn:getTempUriFromString(normalize-space(field[@name='sourceLabel']))"/>
					<xsl:value-of select="fn:write-json-property('sourceURI', $sourceURI)" />
					<xsl:text>,&#xD;&#xA;</xsl:text><!--comma and newline-->
				</xsl:if>
			</xsl:if>			
			
			<!--output each named field (with a non-blank value) as an individual JSON property-->		
			<xsl:for-each select="field[normalize-space(@name) !='' and normalize-space(text()) !='']">
				<xsl:value-of select="fn:write-json-property(@name, text())" /><!--named property value-->
				<xsl:if test="not(position() = last())">,</xsl:if><!--comma if not last field-->
				<xsl:text>&#xD;&#xA;</xsl:text><!--newline-->
			</xsl:for-each>			
			
			<xsl:text>}</xsl:text><!--closing brace-->
			<xsl:if test="not(position() = last())">,</xsl:if><!--comma if not last row-->
			<xsl:text>&#xD;&#xA;</xsl:text><!--newline-->
			
     	</xsl:for-each><!--end for each xml element.-->

		<xsl:text>]&#xD;&#xA;</xsl:text><!--closing array bracket and newline. Finito-->	
			
	</xsl:function>
	
	<!--
	write a single correctly formatted JSON property. (used by fn:xml2json)
	usage:	fn:write-json-property("myPropertyName", "myPropertyValue")
	output:	(tab)"myPropertyName" : "myPropertyValue"
	-->
	<xsl:function name="fn:write-json-property" as="xs:string">
		<xsl:param name="propertyName" as="xs:string" /> 
		<xsl:param name="propertyValue" as="xs:string" /> 
		
		<!--if value is an aliased URI then this function will expand it, otherwise will leave it alone-->
		<xsl:variable name="propertyValue" select="fn:getFullUriFromShortUri($propertyValue)"/>
		
		<xsl:value-of select="concat('&#x9;', '&quot;', fn:json-escape($propertyName), '&quot;', ': ', '&quot;', fn:json-escape($propertyValue), '&quot;')" />
	</xsl:function>
	
	
	<!--
	escape any problematic characters to make a string safe for use in JSON
	usage: 	fn:json-escape('my\proble"m\string')
	output:	"my\\proble\"m\\string"
	-->
	<xsl:function name="fn:json-escape">
		<xsl:param name="string" as="xs:string?"/>
		
		<xsl:variable name="string" select="normalize-space($string)"/>		<!--remove leading or trailing spaces-->
		<xsl:variable name="string" select="replace($string, '\\', '\\\\')"/>		<!--escape backslash characters-->
		<xsl:variable name="string" select="replace($string, '&quot;', '\\&quot;')"/> <!--escape doublequote characters-->
		<xsl:variable name="string" select="replace($string, '&#08;', '\\b')"/>	<!--escape backspace characters-->
		<xsl:variable name="string" select="replace($string, '&#09;', '\\t')"/>	<!--escape tab characters-->
		<xsl:variable name="string" select="replace($string, '&#10;', '\\n')"/>	<!--escape new line characters-->
		<xsl:variable name="string" select="replace($string, '&#13;', '\\r')"/>	<!--escape carriage return characters-->
		
		<xsl:value-of select="$string"/>
	</xsl:function>
	

	<!--create single ntriple formatted line-->
	<xsl:template name="write-ntriple">
		<xsl:param name="subjectURI" as="xs:string" select="''" /> 
		<xsl:param name="predicateURI" as="xs:string" select="''" />  
		<xsl:param name="objectURI" as="xs:string" select="''" /> 
		<xsl:param name="objectLiteral" as="xs:string" select="''" /> 
		<xsl:param name="objectLiteralLang" as="xs:string" select="'en'" /> 
		
		<!--subjectURI--> 
		<xsl:value-of select="concat('&lt;',  fn:getFullUriFromShortUri(normalize-space($subjectURI)), '&gt;')" />
		<!--space character-->
		<xsl:text>&#x20;</xsl:text>
		<!--predicateURI-->
		<xsl:value-of select="concat('&lt;',  fn:getFullUriFromShortUri(normalize-space($predicateURI)), '&gt;')" />
		<!--space character-->
		<xsl:text>&#x20;</xsl:text>		
		<!--either objectURI or objectLiteral-->
		<xsl:choose>
			<xsl:when test="(normalize-space($objectURI)  !='')">
				<!--URI-->
				<xsl:value-of select="concat('&lt;',  fn:getFullUriFromShortUri(normalize-space($objectURI)), '&gt;')" />
			</xsl:when>
			<xsl:otherwise>
				<!--literal-->
				<xsl:value-of select="concat('&quot;', normalize-space($objectLiteral), '&quot;', '@', normalize-space($objectLiteralLang))"  />
			</xsl:otherwise>
		</xsl:choose>			
		<!--space character-->
		<xsl:text>&#x20;</xsl:text>
		<!--ntriples line terminator (dot)-->
		<xsl:text>.</xsl:text>		
		<!--newline - CR/LF-->
		<xsl:text>&#xD;&#xA;</xsl:text>	
	</xsl:template> 

	<!--read csv file contents and convert (via xml) to ntriples-->
	<xsl:template match="/" name="main">
		<xsl:variable name="tab" as="xs:string" select="fn:file2string($inputFilePath)" />
		<xsl:variable name="xml" as="element(row)*" select="fn:tab2xml($tab)" />	
				
		<xsl:choose>
			<xsl:when test="($format = 'nt')">
				<xsl:value-of select="fn:xml2ntriples($xml, $lang)" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="fn:xml2json($xml)" />	
			</xsl:otherwise>				
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>