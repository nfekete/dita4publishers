<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      xmlns:local="urn:local-functions"
      
      xmlns:rsiwp="http://reallysi.com/namespaces/generic-wordprocessing-xml"
      xmlns:stylemap="http://reallysi.com/namespaces/style-to-tag-map"
      xmlns:relpath="http://dita2indesign/functions/relpath"
      
      exclude-result-prefixes="xs rsiwp stylemap local relpath"
      version="2.0">

  <!--==========================================
    DOCX to DITA generic transformation
    
    Copyright (c) 2009 DITA For Publishers, Inc.

    Transforms a DOCX document.xml file into a DITA topic using
    a style-to-tag mapping.
    
    This transform is intended to be the base for more specialized
    transforms that provide style-specific overrides.
    
    The input to this transform is the document.xml file within a DOCX
    package.
    
    
    Originally developed by Really Strategies, Inc.
    
    =========================================== -->
  
  <xsl:import href="../lib/relpath_util.xsl"/>
  
  <xsl:include href="wordml2simple.xsl"/>
  
  <xsl:param name="outputDir" as="xs:string"/>
  <xsl:param name="rootMapUrl" select="'rootMap.ditamap'" as="xs:string"/>
  
  
  
  <xsl:template match="/" priority="10">
    <xsl:variable name="simpleWpDoc" as="element()">
      <xsl:call-template name="processDocumentXml"/>
    </xsl:variable>
    <xsl:apply-templates select="$simpleWpDoc"/>
  </xsl:template>
  
  <xsl:template match="rsiwp:document">
    <!-- First <p> in doc should be title for the root topic. If it's not, bail -->  
    <xsl:variable name="firstP" select="rsiwp:body/(rsiwp:p|rsiwp:table)[1]" as="element()?"/>
<!--    <xsl:message> + [DEBUG] firstP=<xsl:sequence select="$firstP"/></xsl:message>-->
    <xsl:if test="$firstP and not(local:isRootTopicTitle($firstP)) and not(local:isMap($firstP))">
      <xsl:message terminate="yes"> + [ERROR] The first block in the Word document must be mapped to the root topic title.
        First para is style <xsl:sequence select="string($firstP/@style)"/>, mapped as <xsl:sequence 
          select="key('styleMaps', string($firstP/@style), $styleMapDoc)[1]"/> 
      </xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="local:isRootTopicTitle($firstP)">
        <xsl:call-template name="makeTopic">
          <xsl:with-param name="content" select="rsiwp:body/(rsiwp:p|rsiwp:table)" as="node()*"/>
          <xsl:with-param name="level" select="0"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="local:isMap($firstP)">
        <xsl:call-template name="makeMap">
          <xsl:with-param name="content" select="rsiwp:body/(rsiwp:p|rsiwp:table)" as="node()*"/>
          <xsl:with-param name="level" select="0"/>
          <xsl:with-param name="mapUrl" select="$rootMapUrl" as="xs:string"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="rsiwp:p[@structureType = 'skip']" priority="10"/>
  
  <xsl:template match="rsiwp:p" name="transformPara">
    <xsl:variable name="tagName" as="xs:string"
      select="
      if (@tagName) 
      then string(@tagName)
      else 'p'
      "
    />
    <xsl:if test="not(./@tagName)">
      <xsl:message> + [WARNING] No style to tag mapping for paragraph style "<xsl:sequence select="string(@style)"/>"</xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="count(./*) = 0 and normalize-space(.) = ''">
<!--        <xsl:message> + [DEBUG] Skipping apparently-empty paragraph: <xsl:sequence select="local:reportPara(.)"/></xsl:message>-->
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{$tagName}">
          <xsl:call-template name="transformParaContent"/>    
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template name="transformParaContent">
    <!-- Transforms the content of a paragraph, where the containing
         element is generated by the caller. -->
    <xsl:choose>
      <xsl:when test="@useContent = 'elementsOnly'">
        <xsl:apply-templates mode="p-content" select="*"/>
      </xsl:when>
      <xsl:when test="@putValueIn = 'valueAtt'">
        <xsl:attribute name="value" select="string(.)"/>
        <xsl:if test="@dataName">
          <xsl:attribute name="name" select="string(@dataName)"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="p-content"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="rsiwp:table">
    <xsl:message> + [DEBUG] rsiwp:table: Starting...</xsl:message>
    <xsl:variable name="tagName" as="xs:string"
      select="
      if (@tagName) 
      then string(@tagName)
      else 'table'
      "
    />
    <xsl:element name="{$tagName}">
      <!-- FIXME: Need to account for table heads and table bodies -->
      <tgroup cols="{count(rsiwp:cols/rsiwp:col)}">
        <xsl:apply-templates select="rsiwp:cols"/>
        <tbody>
          <xsl:apply-templates select="rsiwp:tr"/>
        </tbody>        
      </tgroup>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="rsiwp:cols">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="rsiwp:col">
    <colspec colname="{position()}" 
      colwidth="{concat(@width, '*')}"/>
  </xsl:template>
  
  <xsl:template match="rsiwp:tr">
    <row>
      <xsl:apply-templates/>
    </row>
  </xsl:template>
  
  <xsl:template match="rsiwp:td">
    <entry>
      <xsl:apply-templates/>
    </entry>
  </xsl:template>
  
  
  <xsl:template match="rsiwp:run" mode="p-content">
    <xsl:variable name="tagName" as="xs:string"
      select="
      if (@tagName) 
      then string(@tagName)
      else 'ph'
      "
    />
    <xsl:if test="not(./@tagName)">
      <xsl:message> + [WARNING] No style to tag mapping for character style "<xsl:sequence select="string(@style)"/>"</xsl:message>
    </xsl:if>
    <xsl:element name="{$tagName}">
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="text()" mode="p-content">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template name="makeMap">
    <xsl:param name="content" as="element()+"/>
    <xsl:param name="level" as="xs:double"/><!-- Level of this topic -->
    <xsl:param name="mapUrl" as="xs:string" select="concat('map_', generate-id($content/*[1]), '.ditamap')"/>
    
    <xsl:variable name="firstP" select="$content[1]"/>
    <xsl:variable name="nextLevel" select="$level + 1" as="xs:double"/>
    
    <xsl:variable name="formatName" select="$firstP/@mapType" as="xs:string?"/>
    <xsl:if test="not($formatName)">
      <xsl:message terminate="yes"> + [ERROR] No mapType= attribute for paragraph style <xsl:sequence select="string($firstP/@styleId)"/>, which is mapped to structure type "map".</xsl:message>
    </xsl:if>
    
    <xsl:variable name="format" select="key('formats', $formatName, $styleMapDoc)[1]"/>
    <xsl:if test="not($format)">
      <xsl:message terminate="yes"> + [ERROR] Failed to find output element with name "<xsl:sequence select="$formatName"/> specified for style <xsl:sequence select="string($firstP/@styleId)"/>.</xsl:message>
    </xsl:if>
    
    <xsl:variable name="prologType" as="xs:string"
      select="
      if ($firstP/@prologType and $firstP/@prologType != '')
      then $firstP/@prologType
      else 'topicmeta'
      "
    />
    
    <xsl:variable name="resultUrl" as="xs:string"
      select="relpath:newFile($outputDir, $mapUrl)"
    />
    
    <xsl:message> + [INFO] Creating new map document "<xsl:sequence select="$resultUrl"/>"...</xsl:message>
    
    
    <xsl:result-document href="{$resultUrl}"
      doctype-public="{$format/@doctype-public}"
      doctype-system="{$format/@doctype-system}"
      >
      <xsl:element name="{$firstP/@tagName}">
        <!-- The first paragraph can simply trigger a (possibly) untitled map, or
          it can also be the map title. If it's the map title, generate it.
        -->
        <xsl:if test="local:isMapTitle($firstP)">
          <xsl:apply-templates select="$firstP"/>
        </xsl:if>
        <xsl:if test="$content[@mapZone = 'topicmeta' and (@level = $level or not(@level))]">
          <!-- Now process any map-level topic metadata paragraphs. -->
          <xsl:element name="{$prologType}">
            <xsl:apply-templates select="$content[@mapZone = 'topicmeta' and (@level = $level or not(@level))]"/>
          </xsl:element>
        </xsl:if>
        <xsl:call-template name="generateTopics">
          <xsl:with-param name="content" select="$content" as="node()*"/>
          <xsl:with-param name="level" select="$nextLevel"/>
        </xsl:call-template>        
        
        <xsl:call-template name="generateTopicrefs">
          <xsl:with-param name="content" select="$content" as="node()*"/>
          <xsl:with-param name="level" select="$nextLevel"/>
        </xsl:call-template>
        
      </xsl:element>
    </xsl:result-document>
  </xsl:template>
  
  <!-- Generate topicsrefs and topicheads.
  -->
  <xsl:template name="generateTopicrefs">
    <xsl:param name="content" as="node()*"/>
    <xsl:param name="level"/>
    
    <xsl:for-each-group select="$content[position() > 1]" 
      group-starting-with="*[(@structureType = 'topicTitle' or 
                              @structureType = 'map' or 
                              @structureType = 'mapTitle' or
                              @structureType = 'topicHead' or
                              @structureType = 'topicGroup')  and
                              @level = string($level)]">
      <xsl:variable name="topicrefType" as="xs:string"
        select="if (@topicrefType) then @topicrefType else 'topicref'"
      />
      <xsl:choose>
        <xsl:when test="@structureType = 'topicTitle' and @topicDoc = 'yes'">
          <xsl:message> + [DEBUG] generateTopicrefs: Got a doc-creating topic title. Level=<xsl:sequence select="string(@level)"/></xsl:message>
          <xsl:variable name="topicUrl"
            as="xs:string"
            select="local:getResultUrlForTopic(current-group()[1])"
          />
          <xsl:element name="{$topicrefType}">
             <xsl:attribute name="href" select="$topicUrl"/>
             <xsl:call-template name="generateTopicrefs">
               <xsl:with-param name="content" select="current-group()[position() > 1]" as="node()*"/>
               <xsl:with-param name="level" select="$level + 1" as="xs:double"/>
             </xsl:call-template>
           </xsl:element>          
        </xsl:when>
        <xsl:when test="@structureType = 'topichead'">
          <xsl:message> + [DEBUG] generateTopicrefs: Got a topic head. Level=<xsl:sequence select="string(@level)"/></xsl:message>
          <xsl:variable name="topicheadType" select="if (@topicheadType) then string(@topicheadType) else 'topichead'"/>
          <xsl:variable name="topicmetaType" select="if (@topicmetaType) then string(@topicmetaType) else 'topicmeta'"/>
          <xsl:variable name="navtitleType" select="if (@navtitleType) then string(@navtitleType) else 'navtitle'"/>
          <xsl:element name="{$topicheadType}">
            <xsl:element name="{$topicmetaType}">
               <xsl:apply-templates select="current-group()[1]"/>
            </xsl:element>
            <xsl:call-template name="generateTopicrefs">
              <xsl:with-param name="content" select="current-group()[position() > 1]" as="node()*"/>
              <xsl:with-param name="level" select="$level + 1" as="xs:double"/>
            </xsl:call-template>
          </xsl:element>          
        </xsl:when>
        <xsl:when test="@structureType = 'map' or @structureType = 'mapTitle'">
          <xsl:message> + [DEBUG] generateTopicrefs: Got a map-reference-generating map or map title. Level=<xsl:sequence select="string(@level)"/></xsl:message>
          <xsl:element name="{$topicrefType}">
            <xsl:attribute name="format" select="'ditamap'"/>
            <xsl:call-template name="generateTopicrefs">
              <xsl:with-param name="content" select="current-group()[position() > 1]" as="node()*"/>
              <xsl:with-param name="level" select="$level + 1" as="xs:double"/>
            </xsl:call-template>
          </xsl:element>          
        </xsl:when>
        <xsl:when test="current-group()[position() = 1]">
          <!-- Ignore this stuff since it should be map metadata or ignorable stuff -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:message> + [WARNING] generateTopicrefs: Shouldn't be here, first para=<xsl:sequence select="current-group()[1]"/></xsl:message>
        </xsl:otherwise>
      </xsl:choose>          
    </xsl:for-each-group>
    
  </xsl:template>
  
  
 
  <!-- Generates topics and submaps. Generation of topicrefs in maps is handled by separate
       mode and processing pass.
    -->
  <xsl:template name="generateTopics">
    <xsl:param name="content" as="node()*"/>
    <xsl:param name="level"/>
    
    <xsl:for-each-group select="$content[position() > 1]" 
      group-starting-with="*[(@structureType = 'topicTitle' or @structureType = 'map' or @structureType = 'mapTitle') and
      @level = string($level)]">
      <xsl:choose>
        <xsl:when test="@structureType = 'topicTitle'">
          <xsl:call-template name="makeTopic">
            <xsl:with-param name="content" select="current-group()" as="node()*"/>
            <xsl:with-param name="level" select="$level"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="@structureType = 'map' or @structureType = 'mapTitle'">
          <xsl:call-template name="makeMap">
            <xsl:with-param name="content" select="current-group()" as="node()*"/>
            <xsl:with-param name="level" select="$level"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="current-group()[position() = 1]">
          <!-- Ignore this stuff since it should be map metadata or ignorable stuff -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:message> + [WARNING] Shouldn't be here, first para=<xsl:sequence select="current-group()[1]"/></xsl:message>
        </xsl:otherwise>
      </xsl:choose>          
    </xsl:for-each-group>
    
  </xsl:template>
  
  <xsl:template name="makeTopic">
    <xsl:param name="content" as="node()+"/>
    <xsl:param name="level" as="xs:double"/><!-- Level of this topic -->
    
    <xsl:variable name="firstP" select="$content[1]"/>
    
    <xsl:variable name="makeDoc" select="$firstP/@topicDoc = 'yes'" as="xs:boolean"/>
    
    
    <xsl:choose>
      <xsl:when test="$makeDoc">
        <xsl:variable name="topicUrl"
           as="xs:string"
           select="local:getResultUrlForTopic($firstP)"
        />
        
        <xsl:variable name="resultUrl" as="xs:string"
            select="relpath:newFile($outputDir,$topicUrl)"
        />
        
        <xsl:message> + [INFO] Creating new topic document "<xsl:sequence select="$resultUrl"/>"...</xsl:message>
        
        <xsl:variable name="formatName" select="$firstP/@topicType" as="xs:string?"/>
        <xsl:if test="not($formatName)">
          <xsl:message terminate="yes"> + [ERROR] No topicType= attribute for paragraph style <xsl:sequence select="string($firstP/@styleId)"/>, when topicDoc="yes".</xsl:message>
        </xsl:if>
        
        <xsl:variable name="format" select="key('formats', $formatName, $styleMapDoc)[1]"/>
        <xsl:if test="not($format)">
          <xsl:message terminate="yes"> + [ERROR] Failed to find output element with name "<xsl:sequence select="$formatName"/> specified for style <xsl:sequence select="string($firstP/@styleId)"/>.</xsl:message>
        </xsl:if>
        <xsl:result-document href="{local:getResultUrlForTopic($firstP)}"
          doctype-public="{$format/@doctype-public}"
          doctype-system="{$format/@doctype-system}"
          >
          <xsl:call-template name="constructTopic">
            <xsl:with-param name="content" select="$content"  as="node()*"/>
            <xsl:with-param name="level" select="$level"/>
          </xsl:call-template>
        </xsl:result-document>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="constructTopic">
          <xsl:with-param name="content" select="$content" as="node()*"/>
          <xsl:with-param name="level" select="$level"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Constructs the topic itself -->
  <xsl:template name="constructTopic">
    <xsl:param name="content" as="node()*"/>
    <xsl:param name="level"/>
    
    <xsl:variable name="initialSectionType" as="xs:string" select="string(@initialSectionType)"/>
    <xsl:variable name="firstP" select="$content[1]"/>
    <xsl:variable name="nextLevel" select="$level + 1" as="xs:double"/>
    
    <xsl:variable name="bodyType" as="xs:string"
      select="
      if ($firstP/@bodyType)
      then $firstP/@bodyType
      else 'body'
      "
    />
    
    <xsl:variable name="prologType" as="xs:string"
      select="
      if ($firstP/@prologType and $firstP/@prologType != '')
      then $firstP/@prologType
      else 'prolog'
      "
    />
    
    
    <xsl:variable name="nextLevel" select="$level + 1" as="xs:double"/>
    
    <xsl:element name="{local:getTopicType($firstP)}">
      <xsl:attribute name="id" select="generate-id($firstP)"/>
      <xsl:variable name="titleTagName" as="xs:string"
        select="if ($firstP/@tagName)
        then $firstP/@tagName
        else 'title'
        "
      />
      <xsl:apply-templates select="$firstP"/>
      <xsl:for-each-group select="$content[position() > 1]" 
        group-starting-with="*[@structureType = 'topicTitle' and @level = string($nextLevel)]">
        <xsl:choose>
          <xsl:when test="current-group()[position() = 1] and current-group()[1][@structureType != 'topicTitle']">
            <!-- Prolog and body elements for the topic -->
            <!-- NOTE: can't process title itself here because we're using title elements to define
              topic boundaries.
            -->
            <xsl:apply-templates select="current-group()[@topicZone = 'titleAlts']"/>        
            <xsl:apply-templates select="current-group()[@topicZone = 'shortdesc']"/>             
            <xsl:if test="current-group()[@topicZone = 'prolog' or $level = 0]">
              <xsl:choose>
                <xsl:when test="$level = 0">
                  <xsl:element name="{$prologType}">
                    <!-- For root topic, can pull metadata from anywhere in the incoming document. -->
                    <xsl:apply-templates select="root($firstP)//*[@containingTopic = 'root' and 
                      @topicZone = 'prolog' and 
                      contains(@baseClass, ' topic/author ')]"/>                        
                    <xsl:apply-templates select="root($firstP)//*[@containingTopic = 'root' and 
                      @topicZone = 'prolog' and 
                      contains(@baseClass, ' topic/data ')
                      ]"/>                        
                  </xsl:element>                  
                </xsl:when>
                <xsl:when test="current-group()[@topicZone = 'prolog' and @containingTopic != 'root']">
                  <xsl:element name="{$prologType}">
                    <xsl:apply-templates select="//*[@containingTopic = 'root' and @topicZone = 'prolog']"/>
                  </xsl:element>
                </xsl:when>
                <xsl:otherwise/><!-- Must be only root-level prolog elements in this non-root topic context -->
              </xsl:choose>
            </xsl:if>
            <xsl:if test="current-group()[@topicZone = 'body']">
              <xsl:message> + [DEBUG] current group is topicZone body</xsl:message>
              <xsl:element name="{$bodyType}">
                <xsl:call-template name="handleSectionParas">
                  <xsl:with-param name="sectionParas" select="current-group()[@topicZone = 'body']" as="element()*"/>
                  <xsl:with-param name="initialSectionType" select="$initialSectionType" as="xs:string"/>
                </xsl:call-template>
              </xsl:element>                  
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <!--            <xsl:message> + [DEBUG] makeTopic(): Calling makeTopic...</xsl:message>-->
            <xsl:call-template name="makeTopic">
              <xsl:with-param name="content" select="current-group()" as="node()*"/>
              <xsl:with-param name="level" select="$level + 1"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>        
      </xsl:for-each-group>
    </xsl:element>      
  </xsl:template>
  
  <xsl:template name="handleSectionParas">
    <xsl:param name="sectionParas" as="element()*"/>
    <xsl:param name="initialSectionType" as="xs:string"/>
    <xsl:for-each-group select="$sectionParas" group-starting-with="*[@structureType = 'section']">
      <xsl:choose>
        <xsl:when test="current-group()[position() = 1] and @structureType != 'section'">
          <xsl:choose>
            <xsl:when test="$initialSectionType != ''">
              <xsl:element name="{$initialSectionType}">
                <xsl:call-template name="handleBodyParas">
                  <xsl:with-param name="bodyParas" select="current-group()"/>
                </xsl:call-template>
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="handleBodyParas">
                <xsl:with-param name="bodyParas" select="current-group()"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
          
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="{@tagName}">
            <xsl:variable name="bodyParas"
              select="if (@useAsTitle = 'no')
                         then current-group()[position() > 1]
                         else current-group()
                         
              "
            />
            <xsl:call-template name="handleBodyParas">
              <xsl:with-param name="bodyParas" select="$bodyParas"/>
            </xsl:call-template>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>      
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template name="handleBodyParas">
    <xsl:param name="bodyParas" as="element()*"/>
    
    <xsl:for-each-group select="$bodyParas" group-adjacent="boolean(@containerType)">
      <xsl:choose>
        <xsl:when test="@containerType">
          <xsl:variable name="containerGroup" as="element()">
            <containerGroup>
              <xsl:sequence select="current-group()"/>
            </containerGroup>
          </xsl:variable>
          <xsl:apply-templates select="$containerGroup"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()"/>
        </xsl:otherwise>
      </xsl:choose>
      
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template match="containerGroup">
    <xsl:message> + [DEBUG] Handling groupContainer...</xsl:message>
    
    <xsl:call-template name="processLevelNContainers">
      <xsl:with-param name="context" select="*" as="element()*"/>
      <xsl:with-param name="level" select="1" as="xs:integer"/>
      <xsl:with-param name="currentContainer" select="'body'" as="xs:string"/>
    </xsl:call-template>    
  </xsl:template>
  
  <xsl:template name="processLevelNContainers">
    <xsl:param name="context" as="element()*"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:param name="currentContainer" as="xs:string"/>
    <xsl:message> + [DEBUG] processLevelNContainers, level="<xsl:sequence select="$level"/>"</xsl:message>
    <xsl:message> + [DEBUG]   currentContainer="<xsl:sequence select="$currentContainer"/>"</xsl:message>
    <xsl:for-each-group select="$context[@level = $level]" group-adjacent="@containerType">
      <xsl:message> + [DEBUG]   @containerType="<xsl:sequence select="string(@containerType)"/>"</xsl:message>
      <xsl:message> + [DEBUG]   $currentContainer != @containerType="<xsl:sequence select="$currentContainer != string(@containerType)"/>"</xsl:message>
      <xsl:choose>
        <xsl:when test="$currentContainer != string(@containerType)">
          <xsl:message> + [DEBUG ]  currentContainer != @containerType</xsl:message>
          <xsl:element name="{@containerType}">
            <xsl:for-each select="current-group()">
              <xsl:call-template name="handleGroupSequence">
                 <xsl:with-param name="level" select="$level"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="current-group()">
            <xsl:call-template name="handleGroupSequence">
              <xsl:with-param name="level" select="$level"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
      
    </xsl:for-each-group>    
  </xsl:template>
  
  <xsl:template name="handleGroupSequence">
    <xsl:param name="level"/>
    <xsl:choose>
      <xsl:when test="@containerType = 'dl' and @structureType = 'dt'">
        <xsl:message> + [DEBUG] Found a dl-contained item.</xsl:message>
        <xsl:element name="{@dlEntryType}">
          <xsl:call-template name="transformPara"/>          
          <xsl:variable name="followingSibling" as="element()?" select="following-sibling::*[1]"/>
          <xsl:if test="not($followingSibling/@structureType = 'dd')">
            <xsl:message> +[WARNING] Paragraph following a paragraph mapped to "dt" is not mapped to "dd". Found "<xsl:sequence 
              select="string($followingSibling/@structureType)"/>"</xsl:message>
          </xsl:if>
          <xsl:for-each select="$followingSibling">
            <xsl:call-template name="transformPara"/>
          </xsl:for-each>
          <!-- FIXME: This isn't going to handle nested paras within DD -->
        </xsl:element>
      </xsl:when>
      <xsl:when test="@containerType = 'dl' and @structureType = 'dd'"/><!-- Handled by dt processing -->
      <xsl:when test="following-sibling::*[1][@level &gt; $level]">
        <xsl:variable name="me" select="." as="element()"/>
        <xsl:element name="{@tagName}">
          <xsl:call-template name="transformParaContent"/>
          <xsl:message> + [DEBUG]   Found following lower-level siblings...</xsl:message>
          <xsl:call-template name="processLevelNContainers">
            <xsl:with-param name="context" 
              select="following-sibling::*[(@level = $level + 1) and 
              preceding-sibling::*[@level = $level][1][. is $me]]" as="element()*"/>
            <xsl:with-param name="level" select="$level + 1" as="xs:integer"/>
            <xsl:with-param name="currentContainer" select="@tagName" as="xs:string"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="transformPara"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="rsiwp:break" mode="p-content">
    <br/>
  </xsl:template>
  
  <xsl:template match="rsiwp:tab" mode="p-content">
    <tab/>
  </xsl:template>
  
  <xsl:template match="rsiwp:hyperlink" mode="p-content">
    <xsl:element name="{@tagName}">
      <!-- Not all Word hyperlinks become DITA hyperlinks: -->
      <xsl:if test="@structureType = 'xref'">
        <xsl:attribute name="href" select="@href"/>
        <xsl:attribute name="scope" select="@scope"/>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="rsiwp:image" mode="p-content">
    <art>
      <art_title><xsl:sequence select="string(@src)"/></art_title>
      <image href="{@src}">
        <alt><xsl:sequence select="string(@src)"/></alt>
      </image>
    </art>
  </xsl:template>
  
  <xsl:function name="local:isMap" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleName" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleName = '' or $styleName = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()?"
          select="key('styleMaps', $styleName, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then ($styleMap/@structureType = 'map' or
                $styleMap/@structureType = 'mapTitle')
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="local:isMapRoot" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleName" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleName = '' or $styleName = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()?"
          select="key('styleMaps', $styleName, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then $styleMap/@structureType = 'map'
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="local:isMapTitle" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleName" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleName = '' or $styleName = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()?"
          select="key('styleMaps', $styleName, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then $styleMap/@structureType = 'mapTitle'
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="local:isRootTopicTitle" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleName" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleName = '' or $styleName = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()?"
          select="key('styleMaps', $styleName, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then (($styleMap/@level = '0') and ($styleMap/@structureType = 'topicTitle'))
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>
  
  <xsl:function name="local:isTopicTitle" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleId" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleId = '' or $styleId = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()"
          select="key('styleMaps', $styleId, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then $styleMap/@structureType = 'topicTitle'
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:function>
  
  <xsl:function name="local:getTopicType" as="xs:string">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleId" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleId = '' or $styleId = '[None]'">
        <xsl:sequence select="'unknown-topic-type'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()"
          select="key('styleMaps', $styleId, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap and $styleMap/@topicType)
          then string($styleMap/@topicType)
          else 'unknown-topic-type'
          "
        />
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>

  <xsl:function name="local:getMapType" as="xs:string">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleId" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleId = '' or $styleId = '[None]'">
        <xsl:sequence select="'unknown-map-type'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()"
          select="key('styleMaps', $styleId, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap and $styleMap/@mapType)
          then string($styleMap/@mapType)
          else 'unknown-map-type'
          "
        />
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>
  
  <xsl:function name="local:getResultUrlForTopic" as="xs:string">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="result" as="xs:string">
      <xsl:apply-templates mode="topic-url" select="$context"/>
    </xsl:variable>
    <xsl:sequence select="$result"/>
  </xsl:function>

  <xsl:template match="rsiwp:p" mode="topic-url">
    <xsl:sequence select="concat('topics/topic_', generate-id(.), '.dita')"/>
  </xsl:template>
  
  
  <xsl:template match="rsiwp:*" mode="topic-url">
    <xsl:message> + [WARNING] Unhandled element <xsl:sequence select="name(..)"/>/<xsl:sequence select="name(.)"/> in mode 'topic-url'</xsl:message>
    <xsl:sequence select="concat('topics/topic_', generate-id(.), '.dita')"/>
  </xsl:template>
  
  <xsl:function name="local:debugMessage">
    <xsl:param name="msg" as="xs:string"/>
    <xsl:message> + [DEBUG] <xsl:sequence select="$msg"/></xsl:message>
  </xsl:function>
  
  <xsl:function name="local:reportPara">
    <xsl:param name="para" as="element()?"/>
    <xsl:if test="$para">
      <xsl:sequence 
        select="concat('[', 
                       name($para),
                       ' ',
                       ' tagName=',
                       $para/@tagName,
                       if ($para/@level)
                          then concat(' level=', $para/@level)
                          else '',
                       if ($para/@containerType)
                          then concat(' containerType=', $para/@containerType)
                          else '',
                       ']',
                       substring(normalize-space($para), 1,20)
                       )"
      />
    </xsl:if>
  </xsl:function>
  
  <xsl:template match="rsiwp:*" priority="-0.5" mode="p-content">
    <xsl:message> + [WARNING] docx2dita[p-content]: Unhandled element <xsl:sequence select="name(..)"/>/<xsl:sequence select="name(.)"/></xsl:message>
  </xsl:template>
  
  <xsl:template match="rsiwp:*" priority="-0.5">
    <xsl:message> + [WARNING] docx2dita: Unhandled element <xsl:sequence select="name(..)"/>/<xsl:sequence select="name(.)"/></xsl:message>
  </xsl:template>

</xsl:stylesheet>
