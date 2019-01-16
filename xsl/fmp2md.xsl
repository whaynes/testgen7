<?xml version="1.0" encoding="UTF-8"?>
<!-- for test generator version 7 -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fmp="http://www.filemaker.com/fmpdsoresult"
                version="1.0">
  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
  <xsl:strip-space elements=""/>
  <xsl:preserve-space elements="fmp:stem"/>
  <xsl:variable name="limit" select="100"/>
  <!-- maximum number of questions permitted -->
  <xsl:variable name="serverpath" select="'/mewb7/'"/>
  <xsl:variable name="imagepath" select="'illustrations/fullsize/'"/>
  <!-- relative path to image directory -->
  <xsl:param name="include_key"/>
  <xsl:param name="include_illustrations"/>
  <xsl:template match="/">
    <!-- Note: Metadata is added by the cgi -->
    <xsl:if test="$include_key='true'">
      <xsl:call-template name="answers"/>
    </xsl:if>
    <xsl:call-template name="questions"/>
    <xsl:if test="$include_illustrations='true'">
      <xsl:call-template name="illustrations"/>
    </xsl:if>
  </xsl:template>
  <xsl:template name="answers">
    <!-- Produce the answer sheet -->
    <xsl:text>### Answer Key {#answers}&#10;&#10;</xsl:text>
    <xsl:text>| Question | MEWB No. | Answer | Illustration |&#10;</xsl:text>
    <xsl:text>|:---------|:---------|:-------|:---------------|&#10;</xsl:text>
    <xsl:for-each select="//fmp:ROW[position() &lt;= $limit]">
      <xsl:text>|</xsl:text>
      <xsl:value-of select="substring(concat(position(), '.          '), 1, 10)"/>
      <xsl:text>|</xsl:text>
      <xsl:value-of select="substring(concat(fmp:qnum, '.          '), 1, 10)"/>
      <xsl:text>|</xsl:text>
      <xsl:value-of select="substring(concat(translate(fmp:ans, 'ABCD', 'abcd'),'        '),1,8)"/>
      <xsl:text>|</xsl:text>
      <xsl:variable name="illustrations">
        <xsl:for-each select="fmp:illustration/fmp:DATA/text()">
          <xsl:choose>
            <xsl:when test="position() = 1">
              <xsl:value-of select="."/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat(', ', .) "/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="substring(concat($illustrations, '                    '), 1, 16)"/>
      <xsl:text>|&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>&#10;&#10;</xsl:text>
  </xsl:template>
  <xsl:template name="questions">
    <xsl:text>### Questions {#test}&#10;&#10;</xsl:text>
    <xsl:for-each select="//fmp:ROW[position() &lt;= $limit]">
      <!-- Produce each question -->
      <xsl:if test="position()&lt;10"> <!-- make qnum 2 digits long to make pandoc conversion work right - otherwise first 9 questions parse differently -->
        <xsl:text>0</xsl:text>
      </xsl:if>
      <xsl:value-of select="position()"/>
      <xsl:text>.</xsl:text>
      <xsl:call-template name="info_comment"/>
      <xsl:apply-templates select="fmp:stem"/>
      <xsl:apply-templates mode="see" select="fmp:illustration/fmp:DATA"/>
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates select="fmp:ans_a"/>
      <xsl:apply-templates select="fmp:ans_b"/>
      <xsl:apply-templates select="fmp:ans_c"/>
      <xsl:apply-templates select="fmp:ans_d"/>
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>&#10;&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="fmp:ans_a|fmp:ans_b|fmp:ans_c|fmp:ans_d">
    <!-- Produce the choices, abce -->
    <xsl:variable name="label">
      <xsl:value-of select="substring-after(name(),'_')"/>
    </xsl:variable>
    <xsl:text>&#10;</xsl:text>
    <xsl:value-of select="translate($label,'abcd','abcd')"/>
    <xsl:text>.</xsl:text>
    <xsl:variable name="escapeHash">
      <!-- must escape hashes or they render as headings!-->
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="."/>
        <xsl:with-param name="replace" select="'#'"/>
        <xsl:with-param name="by" select="'\#'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="normalize-space($escapeHash)"/>
  </xsl:template>
  <xsl:template name="illustrations">
    <!-- Produce the list of illustrations -->
    <xsl:text>### Illustrations {#pics}&#10;&#10;</xsl:text>
    <xsl:for-each select="//fmp:ROW[position() &lt;= $limit]/fmp:illustration/fmp:DATA[not(.=preceding::fmp:DATA)]">
      <xsl:sort select="text()"/>
      <xsl:if test="text()">
        <xsl:text>![</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>](</xsl:text>
        <xsl:value-of select="concat($serverpath,$imagepath)"/>
        <xsl:value-of select="."/>
        <xsl:text>.png)&#10;&#10;</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="fmp:illustration/fmp:DATA" mode="see">
    <!-- Produce the illustrations -->
    <xsl:if test="text()">
      <xsl:text>*See illustration</xsl:text>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>](</xsl:text>
      <xsl:value-of select="concat($serverpath,$imagepath)"/>
      <xsl:value-of select="."/>
      <xsl:text>.png).*</xsl:text>
    </xsl:if>
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
  <xsl:template match="fmp:stem">
    <!--This template indents all lines in stem so that they don't end the <ol> containing the questions -->
    <xsl:call-template name="string-replace-all">
      <xsl:with-param name="text" select="."/>
      <xsl:with-param name="replace" select="'&#xA;'"/>
      <xsl:with-param name="by" select="'&#xA;    '"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="info_comment">
    <xsl:value-of select="concat(' &lt;!-- ', position(), '. mewb7: ', fmp:qnum, ' ans: ', fmp:ans , ' -->')"
                  disable-output-escaping="yes"/>
  </xsl:template>
</xsl:stylesheet>
