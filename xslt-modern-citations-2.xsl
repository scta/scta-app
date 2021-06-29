<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="3.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
  <xsl:output method="html" media-type="html"/>
  <xsl:param name="nameFilter">false</xsl:param>
  
  <xsl:variable name="items">
    <items xmlns="http://www.tei-c.org/ns/1.0">
      <item>pg-b1q1</item>
      <item>pg-b1q2</item>
      <item>pg-b1q3</item>
      <item>pg-b1q4</item>
      <item>pg-b1q5</item>
      <item>pg-b1q6</item>
      <item>pg-b1q7</item>
      <item>pg-b1q8</item>
      <item>pg-b1q9</item>
      <item>pg-b1q10</item>
      <item>pg-b1q11</item>
      <item>pg-b1q12</item>
      <item>pg-b1q13</item>
      <item>pg-b1q14</item>
      <item>pg-b1q15</item>
      <item>pg-b1q16</item>
      <item>pg-b1q17</item>
      <item>pg-b1q18</item>
      <item>pg-b1q19</item>
      <item>pg-b1q20</item>
    </items>
  </xsl:variable>
  
  
  
  <xsl:template match="/">
    <html>
      <body>
        <xsl:for-each select="$items//item">
          <xsl:variable name="docName" select="concat('https://exist.scta.info/exist/apps/scta-app/text/graciliscommentary/', ., '/', ., '.xml')"/>
          <xsl:variable name="itemDoc" select="doc($docName)"/>
          <p>Modern Citation View</p>
          
          <p>For: <xsl:value-of select="$itemDoc/TEI/teiHeader[1]/fileDesc[1]/titleStmt[1]/title[1]"/>
          </p>
          <xsl:choose>
            <xsl:when test="$nameFilter eq 'false'">
              <xsl:apply-templates select="$itemDoc//cit"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="$itemDoc//cit[contains(./bibl, $nameFilter)]"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="note"/>
  <xsl:template match="cit">
    
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="bibl">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="bibl/name">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="bibl/title">
    <i>
      <xsl:apply-templates/>
    </i>
  </xsl:template>
  <xsl:template match="quote">
    <a href="https://scta.lombardpress.org/#/res?resourceid=http://scta.info/resource/{./@xml:id}" target="new">Quote</a>
  </xsl:template>
  <xsl:template match="ref">
    <a href="https://scta.lombardpress.org/#/res?resourceid=http://scta.info/resource/{./@xml:id}" target="new">Ref</a>
  </xsl:template>
</xsl:stylesheet>