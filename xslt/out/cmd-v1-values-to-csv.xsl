<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:clariah="http://www.clariah.eu/"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="xs math clariah err"
    version="3.0">
    
    <xsl:output method="text" encoding="UTF-8"/>
    
    <!-- XSLTs made by Menzo Windhouwer. Adapted by Liliana Melgar. 
        Used in combination with a jupyter notebook available at the repository to check the correctness of the records transformation between versions -->
    
    <xsl:param name="cwd" select="'file:../hi-data-envelop-editor'"/>
    <xsl:param name="app" select="'data-envelopes'"/>
    <xsl:param name="config" select="doc(concat($cwd, '/data/apps/', $app, '/config.xml'))"/>
    
    <xsl:param name="tweakFile" select="'file:../hi-data-envelop-editor/data/apps/data-envelopes/profiles/clarin.eu:cr1:p_1708423613607/clarin.eu:cr1:p_1708423613607.xml'"/>
    <xsl:param name="tweak" select="document($tweakFile)"/>
    
    <xsl:param name="prof" select="$tweak/ComponentSpec/Header[1]/ID[1]"/>
    
    <xsl:param name="vers" select="'1.2'"/>
    <xsl:variable name="cmd-ns" select="
        if ($vers = '1.1') then
        'http://www.clarin.eu/cmd/'
        else
        'http://www.clarin.eu/cmd/1'"/>
    <xsl:variable name="cmdp-ns" select="
        if ($vers = '1.1') then
        'http://www.clarin.eu/cmd/'
        else
        concat('http://www.clarin.eu/cmd/1/profiles/', $prof)"/>
 
    <xsl:param name="nr" select="()"/>
    
    <xsl:variable name="NL" select="system-property('line.separator')"/>
    
    <xsl:variable name="DELIM" select="','"/>
    <xsl:variable name="STR" select="'&quot;'"/>
    <xsl:variable name="REC" select="$NL"/>
    
    <!-- Separator for multiple values of a repeatable element -->
    <xsl:variable name="MULTI" select="'|'"/>
    
    <xsl:variable name="NS" as="element()">
        <xsl:element namespace="{$cmd-ns}" name="cmd:ns">
            <xsl:if test="exists($cmdp-ns)">
                <xsl:namespace name="cmdp" select="$cmdp-ns"/>
            </xsl:if>
        </xsl:element>
    </xsl:variable>
    
    <xsl:template match="text()" mode="#all"/>
    
    <xsl:template match="/">
        <xsl:call-template name="main"/>
    </xsl:template>
    
    <!-- CSV-escape (RFC 4180): always wrap in double quotes, double any internal quotes -->
    <xsl:function name="clariah:esc">
        <xsl:param name="val"/>
        <xsl:sequence select="concat($STR, replace(string($val), $STR, concat($STR, $STR)), $STR)"/>
    </xsl:function>
    
    <xsl:template name="main">
        <!-- CSV header: full path-based column names -->
        <xsl:text expand-text="yes">"record_nr","record_id"</xsl:text>
        <xsl:apply-templates select="$tweak" mode="path"/>
        <xsl:text expand-text="yes">{$REC}</xsl:text>
        
        <!-- Data rows: one per record -->
        <xsl:variable name="recs" select="concat($cwd, '/data/apps/', $app, '/profiles/', $prof, '/records')"/>
        <xsl:for-each select="collection(concat($recs,'?match=record-',if (normalize-space($nr)!='') then ($nr) else ('\d+'),'\.xml&amp;on-error=warning'))">
            <xsl:sort select="//*:Header/*:MdSelfLink/replace(.,'unl://','') cast as xs:integer?" order="ascending" data-type="number"/>
            <xsl:variable name="rec" select="."/>
            <xsl:message expand-text="yes">DBG:rec[{base-uri($rec)}]</xsl:message>
            <!-- record_nr and record_id -->
            <xsl:text expand-text="yes">{clariah:esc(replace($rec//*:Header/*:MdSelfLink,'unl://',''))}{$DELIM}{clariah:esc(normalize-space($rec//*:BasicInformation/(*:title[@xml:lang='en'],*:title)[1]))}</xsl:text>
            <!-- field values -->
            <xsl:apply-templates select="$tweak" mode="row">
                <xsl:with-param name="rec" select="$rec" tunnel="yes"/>
            </xsl:apply-templates>
            <xsl:text expand-text="yes">{$REC}</xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <!-- ================================================================
         HEADER mode: generate column names from schema paths
         ================================================================ -->
    <xsl:template match="Element" mode="path">
        <xsl:variable name="e" select="."/>
        <xsl:text expand-text="yes">{$DELIM}{clariah:esc(concat('/',string-join(ancestor::Component/@name,'/'),'/',@name))}</xsl:text>
        <xsl:if test="$e/@Multilingual='true'">
            <xsl:text expand-text="yes">{$DELIM}{clariah:esc(concat('/',string-join(ancestor::Component/@name,'/'),'/',@name,'/@xml:lang'))}</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- ================================================================
         ROW mode: output the actual value(s) of each element
         ================================================================ -->
    <xsl:template match="Element" mode="row">
        <xsl:param name="rec" tunnel="yes"/>
        <xsl:variable name="e" select="."/>
        <xsl:variable name="p" select="concat('//cmd:Components/cmdp:', string-join(ancestor::Component/@name,'/cmdp:'),'/cmdp:',$e/@name)"/>
        <xsl:try>
            <xsl:variable name="insts" as="node()*">
                <xsl:evaluate xpath="$p" context-item="$rec" namespace-context="$NS"/>
            </xsl:variable>
            <!-- Join multiple values with | separator; always-quote the result -->
            <xsl:text expand-text="yes">{$DELIM}{clariah:esc(string-join($insts/normalize-space(.), $MULTI))}</xsl:text>
            <xsl:if test="$e/@Multilingual='true'">
                <xsl:text expand-text="yes">{$DELIM}{clariah:esc(string-join(distinct-values($insts/@xml:lang),' '))}</xsl:text>
            </xsl:if>
            <xsl:catch>
                <xsl:message expand-text="yes">ERROR: field [{$e/@name}] path [{$p}] error [{$err:description}]</xsl:message>
                <xsl:text expand-text="yes">{$DELIM}{clariah:esc(concat('ERROR:',$e/@name))}</xsl:text>
                <xsl:if test="$e/@Multilingual='true'">
                    <xsl:text expand-text="yes">{$DELIM}""</xsl:text>
                </xsl:if>
            </xsl:catch>
        </xsl:try>
    </xsl:template>
    
    <xsl:template match="Element"></xsl:template>
</xsl:stylesheet>
