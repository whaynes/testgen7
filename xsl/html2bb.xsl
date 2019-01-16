<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:h="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="xs xd h" version="1.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>
        <xd:b>Created on:</xd:b>
        Jun 5, 2015
      </xd:p>
      <xd:p>
        <xd:b>Author:</xd:b>
        whaynes
      </xd:p>
      <xd:p/>
    </xd:desc>
  </xd:doc>
  <xsl:output method="xml" omit-xml-declaration="yes" indent="no"/>
  <xsl:strip-space elements="*"/>
  <xsl:param name="include_illustrations"/>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="h:ol|comment()"/>
  <!-- default behavior: strip answers and comments -->
  <xsl:template match="h:a">
    <!-- default behavior: strip link -->
    <xsl:value-of select="."/>
  </xsl:template>
  <xsl:template match="/">
    <xsl:for-each select='//h:section[@id="test"]/h:ol/h:li'>
      <!-- for each question -->
      <!-- each li at this level is a question -->
      <xsl:text>MC&#09;</xsl:text>
      <xsl:apply-templates/>
      <xsl:if test="$include_illustrations='true'">
        <xsl:apply-templates select="descendant::h:a" mode="thumbnails"/>
      </xsl:if>
      <xsl:apply-templates select="h:ol/h:li" mode="answers"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="h:li" mode="answers">
    <xsl:variable name="comment">
      <xsl:value-of select="../..//comment()"/>
    </xsl:variable>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>&#09;</xsl:text>
    <xsl:variable name="this_ans">
      <xsl:value-of select="normalize-space(translate(string(position()),'1234','ABCD'))"/>
    </xsl:variable>
    <xsl:variable name="right_ans">
      <xsl:value-of
              select="substring($comment,string-length($comment)-1,1)"/> <!-- penultimate char of comment is answer -->
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$this_ans=$right_ans">
        <xsl:text>correct</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>incorrect</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="h:a" mode="thumbnails">
    <xsl:element name="a">
      <xsl:attribute name="href">
        <xsl:value-of select="@href"/>
      </xsl:attribute>
      <xsl:element name="img">
        <xsl:attribute name="src">
          <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text">
              <xsl:value-of select="@href"/>
            </xsl:with-param>
            <xsl:with-param name="replace">illustrations/fullsize/</xsl:with-param>
            <xsl:with-param name="by">illustrations/thumbs/</xsl:with-param>
          </xsl:call-template>
        </xsl:attribute>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  <xsl:template name="string-replace-all">
    <xsl:param name="text"/>
    <xsl:param name="replace"/>
    <xsl:param name="by"/>
    <xsl:choose>
      <xsl:when test="contains($text, $replace)">
        <xsl:value-of select="substring-before($text,$replace)"/>
        <xsl:value-of select="$by"/>
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="substring-after($text,$replace)"/>
          <xsl:with-param name="replace" select="$replace"/>
          <xsl:with-param name="by" select="$by"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
