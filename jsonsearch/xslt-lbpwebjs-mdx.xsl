<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="3.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0">

<xsl:output method="adaptive" indent="no"/>
<xsl:template match="/">
<xsl:call-template name="setMDHeader"/>
<xsl:apply-templates/>
</xsl:template>
<xsl:template name="setMDHeader">
  <xsl:variable name="title" select="/TEI/teiHeader[1]/fileDesc[1]/titleStmt[1]/title[1]/text()"/>
---
<xsl:value-of select="concat('title: ', normalize-space($title))"/>
---
</xsl:template>
<xsl:template match="teiHeader">
</xsl:template>
<xsl:template match="front">
</xsl:template>
<xsl:template match="text()">
<xsl:value-of select="replace(., '\s+', ' ')"/>
</xsl:template>
<xsl:template match="p">
<xsl:variable name="level" select="count(ancestor::div)"/>
<xsl:variable name="sectionNumber" select="count(preceding-sibling::p) + 1"/>
<xsl:variable name="totalNumber">
            <xsl:number level="any" from="text"/>
        </xsl:variable>
<xsl:text>
</xsl:text>
  <Paragraph id="{@xml:id}" level="{$level}" sectionNumber="{$sectionNumber}" totalNumber="{$totalNumber}">
<xsl:text/>
<xsl:apply-templates/>
<xsl:text/>
</Paragraph>
</xsl:template>
<xsl:template match="head">
<xsl:variable name="level" select="count(ancestor::div)"/>
<xsl:variable name="sectionNumber" select="count(./parent::div/preceding-sibling::div) + 1"/>
<xsl:text/>
<Head id="{@xml:id}" level="{$level}" sectionNumber="{$sectionNumber}" type="{@type}">
<xsl:text/>
<xsl:apply-templates/>
<xsl:text/>
</Head>
</xsl:template>

<xsl:template match="quote">
<xsl:text> </xsl:text>
<Quote id="{@xml:id}">
            <xsl:apply-templates/>
        </Quote>
</xsl:template>

<xsl:template match="ref">
<Ref id="{@xml:id}">
            <xsl:apply-templates/>
        </Ref>
</xsl:template>

<xsl:template match="app">
<!--<App>-->
<xsl:apply-templates/>
<!--</App>-->
</xsl:template>

<xsl:template match="lem">
<!--<Lem>-->
<xsl:apply-templates/>
<!--</Lem>-->
</xsl:template>

<xsl:template match="rdg">
</xsl:template>

<xsl:template match="name">
<Name>
            <xsl:apply-templates/>
        </Name>
</xsl:template>

<xsl:template match="title">
<Title>
            <xsl:apply-templates/>
        </Title>
</xsl:template>

<xsl:template match="div">
<xsl:variable name="level" select="count(ancestor::div) + 1"/>
<xsl:variable name="sectionNumber" select="count(preceding-sibling::div) + 1"/>
<xsl:text>
</xsl:text>
<Div id="{@xml:id}" level="{$level}" sectionNumber="{$sectionNumber}">
<xsl:text>
</xsl:text>
<xsl:apply-templates/>
<xsl:text>
</xsl:text>
</Div>
</xsl:template>

<!--<xsl:template match="pb">
<Pb>
<xsl:apply-templates/>
</Pb>
</xsl:template>

<xsl:template match="cb">
<Cb>
<xsl:apply-templates/>
</Cb>
</xsl:template>

<xsl:template match="cit">
<Cit>
<xsl:apply-templates/>
</Cit>
</xsl:template>
-->
<xsl:template match="bibl">

</xsl:template>
<xsl:template match="note">
</xsl:template>

</xsl:stylesheet>