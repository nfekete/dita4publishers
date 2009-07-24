<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
  xmlns:RSUITE="http://www.reallysi.com" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:df="http://dita2indesign.org/dita/functions"
  exclude-result-prefixes="RSUITE df xs"
  >
  
  <!-- ===============================================================
       Default DITA HTML preview style sheet for use with RSuite CMS.
       
       Provides good-enough HTML preview of DITA maps and topics. Handles
       topicref resolution, does not currently handle conref resolution.
       
       This style sheet is normally packaged as an RSuite plugin from 
       which it is used by shell transforms that override or extend
       this one in the style of the DITA Open Toolkit.
    
       =============================================================== -->
  
  <xsl:import href="../lib/dita-support-lib.xsl"/>

  <xsl:template match="*[df:class(., 'hi-d/i')]">
    <xsl:message> + [DEBUG] dita-hi-dPreview.xsl: <xsl:sequence select="name(.)"/>[class=<xsl:sequence select="string(@class)"/>]</xsl:message>
    <i class="{df:getHtmlClass(.)}"><xsl:apply-templates/></i>
  </xsl:template>
  
  <xsl:template match="*[df:class(., 'hi-d/b')]">
    <b class="{df:getHtmlClass(.)}"><xsl:apply-templates/></b>
  </xsl:template>
  
  <xsl:template match="*[df:class(., 'hi-d/u')]">
    <u class="{df:getHtmlClass(.)}"><xsl:apply-templates/></u>
  </xsl:template>
  
  <xsl:template match="*[df:class(., 'hi-d/tt')]">
    <tt class="{df:getHtmlClass(.)}"><xsl:apply-templates/></tt>
  </xsl:template>
  
  <xsl:template match="*[df:class(., 'hi-d/sub')]">
    <sub class="{df:getHtmlClass(.)}"><xsl:apply-templates/></sub>
  </xsl:template>
  
  <xsl:template match="*[df:class(., 'hi-d/sup')]">
    <sup class="{df:getHtmlClass(.)}"><xsl:apply-templates/></sup>
  </xsl:template>
  
  <!-- ===========================
       Catch-all templates
       =========================== -->
    
  <xsl:template match="*" mode="#all" priority="-1"> 
    <xsl:message> + [DEBUG] dita-hi-dPreview.xsl: Catch call caught <xsl:sequence select="name(.)"/>[class=<xsl:sequence select="string(@class)"/>]</xsl:message>
    <xsl:apply-imports/>
  </xsl:template>
  
   
</xsl:stylesheet>
