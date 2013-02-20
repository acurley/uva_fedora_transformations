<?xml version="1.0" encoding="UTF-8"?>
<!--
   - An XSLT stylesheet to convert a PBCORE 2.0 record (which is part
   - of an object in a running fedora repository) into an EAD fragment
   - that is appropriate for the context in which the object exists.
   -
   - The fragment of a "finding aid" generated by this stylesheet is
   - likely unsuitable for archival description, but *is* structured
   - such that the bits read by the hierarchicalSDep (title and level)
   - are present.
  -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:s="http://www.w3.org/2001/sw/DataAccess/rf1/result"
    xmlns:pbcore="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
    xmlns:apia="http://www.fedora.info/definitions/1/0/access/"
    exclude-result-prefixes="xs s pbcore apia"
    version="2.0">
    
    <xsl:output byte-order-mark="no" encoding="UTF-8" media-type="text/xml" xml:space="preserve" indent="yes"/>
    
    <xsl:param name="pid" required="yes" />
    <!-- URL of the source file that was transformed by this stylesheet -->
    <xsl:param name="sourceUrl" required="yes" />
    <!-- publicly accessible URL of this stylesheet -->
    <xsl:param name="thisUrl" required="yes" />
    <xsl:param name="fedora-host" required="no">localhost</xsl:param>
    <xsl:param name="debug" required="no" />
    
    <xsl:template match="/">
        <xsl:variable name="parentComponentType">
            <xsl:call-template name="getParentComponentType" />
        </xsl:variable>
        
        <xsl:variable name="objectProfile" select="document(concat('http://', $fedora-host, ':8080/fedora/objects/', $pid, '?format=xml'))" />
        <xsl:variable name="cmodels">
            <xsl:for-each select="$objectProfile/apia:objectProfile/apia:objModels/apia:model">
                <xsl:if test="not(starts-with(current(), 'info:fedora/fedora-system'))">
                    <value><xsl:value-of select="substring(text(), string-length('info:fedora/') + 1)" /></value>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="level">
            <xsl:choose>
                <xsl:when test="$cmodels/value = 'uva-lib:eadItemCModel'">
                    <xsl:text>item</xsl:text>
                </xsl:when>
                <xsl:when test="$cmodels/value = 'uva-lib:eadComponentCModel'">
                    <xsl:text>series</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$parentComponentType = ''">
                <ead>
                    <xsl:apply-templates select="*" mode="ead" />
                </ead>
            </xsl:when>
            <xsl:when test="$parentComponentType = 'ead'">
                <c01>
                    <xsl:attribute name="level" select="$level" />
                    <xsl:attribute name="id" select="$pid" />
                    <xsl:apply-templates select="*" mode="component" />
                </c01>
            </xsl:when>
            <xsl:when test="$parentComponentType = 'c01'">
                <c02>
                    <xsl:attribute name="level" select="$level" />
                    <xsl:attribute name="id" select="$pid" />
                    <xsl:apply-templates select="*" mode="component" />
                </c02>
            </xsl:when>
            <xsl:when test="$parentComponentType = 'c02'">
                <c03>
                    <xsl:attribute name="level" select="$level" />
                    <xsl:attribute name="id" select="$pid" />
                    <xsl:apply-templates select="*" mode="component" />
                </c03>
            </xsl:when>
            <xsl:when test="$parentComponentType = 'c03'">
                <c04>
                    <xsl:attribute name="level" select="$level" />
                    <xsl:attribute name="id" select="$pid" />
                    <xsl:apply-templates select="*" mode="component" />
                </c04>
            </xsl:when>
            <xsl:otherwise>
                <c>
                    <xsl:attribute name="level" select="$level" />
                    <xsl:attribute name="id" select="$pid" />
                    <xsl:apply-templates select="*" mode="component" />
                </c>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!--
        Performs a resource index query to determine if this object has a 
        parent in the hierarchy and if so, what level it is ("ead", "c01", 
        "c02", ...).
      -->
    <xsl:template name="getParentComponentType">
        <xsl:variable name="lookupParentUri">
            <xsl:text>http://</xsl:text><xsl:value-of select="$fedora-host" /><xsl:text>:8080/fedora/risearch?type=tuples&amp;lang=itql&amp;format=Sparql&amp;query=select%20%24parent%20from%20%3C%23ri%3E%20where%20%3Cinfo%3Afedora%2F</xsl:text>
            <xsl:value-of select="$pid" />
            <xsl:text>%3E%20%3Cinfo%3Afedora%2Ffedora-system%3Adef%2Frelations-external%23isPartOf%3E%20%24parent</xsl:text>
        </xsl:variable>
        <xsl:if test="$debug">
            <xsl:message>
                Querying for parent of <xsl:value-of select="$pid" /> using query: <xsl:value-of select="$lookupParentUri" />
            </xsl:message>
        </xsl:if>
        <xsl:variable name="parentPid" select="substring(document($lookupParentUri)/s:sparql/s:results/s:result/s:parent/@uri, string-length('info:fedora/') + 1)" />
        <xsl:if test="$parentPid">
            <xsl:variable name="currentMetadataUrl">
                <xsl:text>http://</xsl:text><xsl:value-of select="$fedora-host" /><xsl:text>:8080/fedora/objects/</xsl:text>
                <xsl:value-of select="$parentPid" />
                <xsl:text>/methods/uva-lib:descMetadataSDef/getMetadataAsEADFragment</xsl:text>
            </xsl:variable>
            <xsl:if test="$debug">
                <xsl:message>
                    Querying for the metadata for <xsl:value-of select="$parentPid" /> using query: <xsl:value-of select="$currentMetadataUrl" />
                </xsl:message>
            </xsl:if>
            <xsl:variable name="currentMetadataFragment" select="document($currentMetadataUrl)" />
            <xsl:value-of select="local-name($currentMetadataFragment/node())" />
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="pbcore:pbcoreDescriptionDocument" mode="component">
        <xsl:if test="pbcore:identifier">
            <xsl:attribute name="id" select="pbcore:identifier[1]" />
        </xsl:if>
        <did>
            <xsl:for-each select="pbcore:pbcoreTitle">
                <unittitle>
                    <xsl:value-of select="text()" />
                    <xsl:if test="pbcore:pbcoreAssetDate">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="pbcore:pbcoreAssetDate" />
                    </xsl:if>
                </unittitle>
            </xsl:for-each>
            <xsl:if test="pbcore:pbcoreDescription[@type='abstract']">
                <scopecontent>
                    <xsl:for-each select="pbcore:pbcoreDescription[@type='abstract']">
                        <p><xsl:value-of select="text()" /></p>
                    </xsl:for-each>
                </scopecontent>
            </xsl:if>
        </did>
    </xsl:template>
    
    <xsl:template match="pbcore:pbcoreDescriptionDocument" mode="ead">
        <xsl:if test="pbcore:pbcoreIdentifier">
            <xsl:attribute name="id" select="pbcore:pbcoreIdentifier[1]" />
        </xsl:if>
        <xsl:variable name="title" select="pbcore:pbcoreTitle" />
        <xsl:variable name="date" select="pbcore:pbcoreAssetDate[1]/text()" />
        <eadheader>
          <filedesc>
            <titlestmt>
              <titleproper><xsl:value-of select="$title"></xsl:value-of>
                  <xsl:text> </xsl:text>
                  <xsl:if test="$date">
                      <date><xsl:value-of select="$date"></xsl:value-of></date>
                  </xsl:if>
              </titleproper>
            </titlestmt>
          </filedesc>
          <profiledesc>
            <creation>
                This Finding Aid was generated as a transformation from the native form of
                the metadata and may not include all available information.  The original metadata
                may be accessed at <xsl:value-of select="$sourceUrl" />, the transformation 
                used to generate this rendition of the metadata can be viewed at 
                <xsl:value-of select="$thisUrl" />.
            </creation>
            <langusage>Description is in <language>English</language>
            </langusage>
          </profiledesc>
        </eadheader>
        <frontmatter>
          <titlepage>
              <titleproper><xsl:value-of select="$title"></xsl:value-of>
                  <xsl:text> </xsl:text>
                  <xsl:if test="$date">
                      <date><xsl:value-of select="$date"></xsl:value-of></date>
                  </xsl:if>
              </titleproper>
          </titlepage>
        </frontmatter>
        <archdesc level="collection">
          <did>
            <head>Descriptive Summary </head>
            <unittitle><xsl:value-of select="$title"></xsl:value-of>
                <xsl:text> </xsl:text>
                <xsl:if test="$date">
                    <date><xsl:value-of select="$date"></xsl:value-of></date>
                </xsl:if>
            </unittitle>
            <xsl:if test="pbcore:pbcoreDescription[@type='abstract']">
                <scopecontent>
                    <head>Scope and Content</head>
                <xsl:for-each select="pbcore:pbcoreDescription[@type='abstract']">
                    <p><xsl:value-of select="text()" /></p>
                </xsl:for-each>
                </scopecontent>
            </xsl:if>
          </did>
        </archdesc>
    </xsl:template>
    
</xsl:stylesheet>