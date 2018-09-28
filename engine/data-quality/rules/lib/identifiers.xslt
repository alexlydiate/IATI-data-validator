<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version='3.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
  xmlns:me="http://iati.me"
  xmlns:functx="http://www.functx.com"
  exclude-result-prefixes="functx"
  expand-text="yes">

  <xsl:variable name="org-id-prefixes" select="doc('../../lib/known-prefixes.xml')//code"/>
  <xsl:variable name="known-publisher-ids" select="doc('/home/data-quality/lib/known-publishers.xml')//code"/>
  <xsl:variable name="known-10x-ids" select="doc('/home/data-quality/lib/known-publishers-104.xml')//code"/>

  <xsl:template name="identifier_check">
    <xsl:param name="item"/>
    <xsl:param name="class"/>
    <xsl:param name="idclass"/>
    <xsl:param name="versions" select="'any'"></xsl:param>
    
    <xsl:choose>
      <xsl:when test="functx:trim($item)=''">
        <me:feedback class="{$class}" id="{$idclass}.7">
          <xsl:choose>
            <xsl:when test="local-name($item)='iati-identifier' or local-name($item/..)='reporting-org'">
              <xsl:attribute name="type" select="'danger'"/>
              <me:message>The identifier has no value.</me:message>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="type" select="'warning'"/>
              <me:message>The identifier has no value: it should be omitted if you don't have a value for it.</me:message>
            </xsl:otherwise>
          </xsl:choose>            
          <me:src ref="iati" versions="{$versions}"/>
        </me:feedback>        
      </xsl:when>
      
      <xsl:when test="$item != functx:trim($item)">
        <me:feedback type="danger" class="{$class}" id="{$idclass}.1">
          <me:src ref="iati" versions="{$versions}"/>
          <me:message>The identifier should not start or end with spaces or newlines.</me:message>
        </me:feedback>
      </xsl:when>

      <xsl:when test="some $prefix in $org-id-prefixes[@status='withdrawn'] satisfies starts-with(upper-case($item), $prefix)">
        <me:feedback class="{$class}" id="{$idclass}.9">
          <xsl:attribute name="type">
            <xsl:choose>
              <xsl:when test="local-name($item)='iati-identifier' or local-name($item/..)='reporting-org'">warning</xsl:when>
              <xsl:otherwise>info</xsl:otherwise>
            </xsl:choose>                                  
          </xsl:attribute>
          <me:src ref="iati" versions="2.x" href="http://org-id.guide"/>
          <me:message>The identifier starts with a prefix that it is marked as 'withdrawn'.</me:message>
        </me:feedback>
      </xsl:when>

      <xsl:when test="(
        not (some $prefix in $org-id-prefixes satisfies starts-with($item, $prefix)) 
        and (some $prefix in $org-id-prefixes satisfies starts-with(upper-case($item), $prefix)))">
        <me:feedback type="danger" class="{$class}" id="{$idclass}.5">
          <me:src ref="iati" versions="2.x" href="http://org-id.guide"/>
          <me:message>The identifier is invalid: the prefix must be written in uppercase.</me:message>
        </me:feedback>
      </xsl:when>

      <xsl:when test="(some $known-old-id in $known-10x-ids satisfies starts-with($item, $known-old-id))">
<!-- Switch off feedback on deprecated organisation identifiers (DFID case)
	TODO: make this a ruleset specific severity once these are processed in the report
        <me:feedback type="info" class="{$class}" id="1.2.12">
          <me:src ref="iati" versions="2.x"/>
          <me:message>The identifier uses a 1.04 code that has been replaced in 1.05.</me:message>
        </me:feedback>-->
      </xsl:when>
    
      <xsl:when test="matches($item, '^[0-9]{5}$') and local-name($item/..)=('reporting-org', 'participating-org', 'provider-org', 'receiver-org', 'owner-org')">
        <me:feedback class="{$class}" id="{$idclass}.10">
          <xsl:attribute name="type">
            <xsl:choose>
              <xsl:when test="local-name($item/..)='reporting-org'">danger</xsl:when>
              <xsl:otherwise>warning</xsl:otherwise>
            </xsl:choose>                                  
          </xsl:attribute>
          <me:src ref="iati" versions="1.x" href="me:iati-url('organisation-identifiers/')"/>
          <me:message>The identifier is a 5-digit code, but not on the list used up to IATI version 1.04. It may be intended as a CRS channel code.</me:message>
        </me:feedback>
      </xsl:when>
        
      <xsl:when test="matches($item, '^[0-9]{5}.+$')">
        <me:feedback type="warning" class="{$class}" id="{$idclass}.10">
          <me:src ref="iati" versions="1.x" href="me:iati-url('organisation-identifiers/')"/>
          <me:message>The identifier starts with a 5-digit code, but is not on the list used up to IATI version 1.04. It may be intended as a CRS channel code.</me:message>
        </me:feedback>
      </xsl:when>
      
      <xsl:when test="not(some $prefix in $org-id-prefixes satisfies starts-with($item, $prefix))">
        <me:feedback class="{$class}" id="{$idclass}.8">
          <xsl:attribute name="type">
            <xsl:choose>
              <xsl:when test="local-name($item)='iati-identifier' or local-name($item/..)='reporting-org'">danger</xsl:when>
              <xsl:otherwise>warning</xsl:otherwise>
            </xsl:choose>            
          </xsl:attribute>
          <me:src ref="iati" versions="2.x" href="http://org-id.guide"/>
          <me:message>The identifier does not start with a known prefix.</me:message>
        </me:feedback>
      </xsl:when>

      <xsl:when test="not($item=$known-publisher-ids) and local-name($item/..)=('reporting-org', 'participating-org', 'provider-org', 'receiver-org', 'owner-org')">
        <me:feedback class="{$class}" id="{$idclass}.12">
          <xsl:attribute name="type">
            <xsl:choose>
              <xsl:when test="local-name($item)='iati-identifier' or local-name($item/..)='reporting-org'">danger</xsl:when>
              <xsl:otherwise>info</xsl:otherwise>
            </xsl:choose>                      
          </xsl:attribute>
          <me:src ref="iati" versions="2.x"/>
          <me:message>The identifier is not an organisation identifier approved by the IATI registry.</me:message>
        </me:feedback>
      </xsl:when>
      
      <!-- stop further processing of organisation identifiers -->
      <xsl:when test="local-name($item/..)=('reporting-org', 'participating-org', 'provider-org', 'receiver-org', 'owner-org')"/>
      
      <xsl:when test="not(some $known-id in $known-publisher-ids satisfies starts-with($item, $known-id))">
        <me:feedback class="{$class}" id="{$idclass}.11">
          <xsl:attribute name="type">
            <xsl:choose>
              <xsl:when test="local-name($item)='iati-identifier'">danger</xsl:when>
              <xsl:otherwise>warning</xsl:otherwise>
            </xsl:choose>                                  
          </xsl:attribute>
          <me:src ref="iati" versions="2.x"/>
          <me:message>The identifier does not begin with an organisation identifier approved by the IATI registry.</me:message>
        </me:feedback>
      </xsl:when>

    </xsl:choose>

  <xsl:next-match/>
</xsl:template>

</xsl:stylesheet>