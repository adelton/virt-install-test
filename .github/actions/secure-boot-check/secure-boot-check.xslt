<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text"/>

<xsl:template match="/domain">
  <xsl:variable name="secure-boot">
    <xsl:call-template name="feature">
      <xsl:with-param name="feature">secure-boot</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="enrolled-keys">
    <xsl:call-template name="feature">
      <xsl:with-param name="feature">enrolled-keys</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  <xsl:text>secure-boot=</xsl:text>
  <xsl:value-of select="$secure-boot"/>
  <xsl:if test="$secure-boot != $enrolled-keys">
    <xsl:text>,enrolled-keys=</xsl:text>
    <xsl:value-of select="$enrolled-keys"/>
  </xsl:if>
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template name="feature">
  <xsl:param name="feature"/>
  <xsl:choose>
    <xsl:when test="not(os/firmware/feature[@name = $feature])">
      <xsl:text>missing</xsl:text>
    </xsl:when>
    <xsl:when test="not(os/firmware/feature[@name = $feature and @enabled])">
      <xsl:text>unset</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="os/firmware/feature[@name = $feature]/@enabled"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
