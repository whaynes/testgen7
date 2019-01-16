<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                exclude-result-prefixes="xs xd" version="1.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>
        <xd:b>Created on:</xd:b>
        Jun 26, 2015
      </xd:p>
      <xd:p>
        <xd:b>Author:</xd:b>
        whaynes
      </xd:p>
      <xd:p/>
    </xd:desc>
  </xd:doc>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  <!-- this deletes the 'questions' header -->
  <xsl:template match="w:body/w:p[w:pPr/w:pStyle/@w:val='Heading3']"/>
  <!-- this strips the section properties -->
  <xsl:template match="w:body/w:sectPr"/>
  <!-- this sets the first paragraph style to mewb-stem and the rest to mewb-stem0 (mewb-stem+)-->
  <xsl:template match="w:body/w:p/w:pPr[w:numPr/w:ilvl/@w:val='0']">
    <w:pPr>
      <w:pStyle>
        <xsl:attribute name="w:val">
          <xsl:choose>
            <!-- the first actual paragraph of the stem is the second paragraph in the doc -->
            <!-- so count preceding paragraphs, and if there's one, this is the beginning of the stem -->
            <xsl:when test="count(../preceding-sibling::w:p)=1">
              <xsl:text>mewb-stem</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>mewb-stem0</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </w:pStyle>
    </w:pPr>
  </xsl:template>
  <!-- this looks for non-blockquote level 1 paragraphs, styles them  as mewb-abcd.-->
  <xsl:template match="w:body/w:p/w:pPr[w:numPr/w:ilvl/@w:val='1' and not(w:pStyle/@w:val='BlockQuote')]">
    <w:pPr>
      <w:pStyle w:val="mewb-abcd"/>
      <!-- If there are no more paragraphs following, it's choice 'D' so 'don't keep with next'  -->
      <xsl:if test="not (../following-sibling::w:p)">
        <w:keepNext w:val="0"/>
      </xsl:if>
    </w:pPr>
  </xsl:template>
  <!-- this strips out hyperlinks. For hyperlinks to work, references must be established -->
  <xsl:template match="//w:hyperlink">
    <xsl:apply-templates/>
  </xsl:template>
  <!-- this adds column specs to the tables in questions 13413,13414  -->
  <xsl:template match="w:body/w:tbl/w:tblGrid">
    <xsl:element name="w:tblGrid">
      <xsl:element name="w:gridCol">
        <xsl:attribute name="w:w">2000</xsl:attribute>
      </xsl:element>
      <xsl:element name="w:gridCol">
        <xsl:attribute name="w:w">2000</xsl:attribute>
      </xsl:element>
      <xsl:element name="w:gridCol">
        <xsl:attribute name="w:w">2000</xsl:attribute>
      </xsl:element>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>
