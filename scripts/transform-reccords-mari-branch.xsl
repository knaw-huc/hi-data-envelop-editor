<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:cmd="http://www.clarin.eu/cmd/1"
    xmlns:cmdp="http://www.clarin.eu/cmd/1/profiles/clarin.eu:cr1:p_1708423613607"
    exclude-result-prefixes="xs math"
    version="3.0">

<!--this part copies every node and attribute, and then recursively processes all the children and attributes in the same way, this is the basic part, then we say what are the specific parts that will be changed-->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

   
    <!--Element ‘roleInProject’ in component ‘ContactDetails’ renamed to ‘roleInDatasetCreation’. -->
    <xsl:template match="cmdp:ContactDetails/cmdp:roleInProject">
        <cmdp:roleInDatasetCreation>
            <xsl:apply-templates select="@* | node()"/>
        </cmdp:roleInDatasetCreation>
    </xsl:template>
    
    <!--Removed ‘version’ element from ‘Snapshot’ component.-->
    <xsl:template match="cmdp:Snapshot/cmdp:version"/>
    
    <!-- Added closing bracket to ‘Others (Please specify below’ item in ‘datasetUse’ element of ‘Use’ Component  -->
    <xsl:template match="cmdp:Use/cmdp:datasetUse">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test=". = 'Others (Please specify below'">
                    <xsl:value-of select="'Others (Please specify below)'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <!-- ‘Academic/Research Insitution’ corrected to ‘Academic/Research Institution’ in Element name ‘type’ for component ‘publishingOrganisation’ -->
    <xsl:template match="cmdp:publishingOrganisation/cmdp:type">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
                <xsl:choose>
                    <xsl:when test=" . = 'Academic/Research Insitution'">
                        <xsl:value-of select="'Academic/Research Institution'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="node()"/>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <!--Removed preceding spaces in items in ‘Subjects’ element of ‘dataSubjects’ component -->
    <xsl:template match="cmdp:dataSubjects/cmdp:Subjects">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="normalize-space(.)"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>