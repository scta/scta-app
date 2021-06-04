<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="3.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
  <xsl:output method="html" media-type="html"/>

  <xsl:template match="/">
    <html>
      <body>
        <p>Modern Citation View</p>
        <p>For: <xsl:value-of select="/TEI/teiHeader[1]/fileDesc[1]/titleStmt[1]/title[1]"/>
                </p>
    <xsl:apply-templates select="//cit"/>
      </body>
    </html>
  </xsl:template>
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