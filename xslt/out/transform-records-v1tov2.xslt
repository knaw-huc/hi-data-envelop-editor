<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cmd="http://www.clarin.eu/cmd/1"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:old="http://www.clarin.eu/cmd/1/profiles/clarin.eu:cr1:p_1708423613607"
    xmlns:cmdp="http://www.clarin.eu/cmd/1/profiles/clarin.eu:cr1:p_1770289476181"
    exclude-result-prefixes="xs old"
    version="3.0">

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    
    <!-- Note: this XSLT has been generated with Opus 4.6 via Claude AI. Liliana Melgar ran Several iterations to improve it using good quality XSLTs from Menzo Windhouwer. 
        The correctness of the transformation is fully checked with other xslts for overviews and a jupyter notebook available at the repository -->

    <xsl:variable name="old-prof">clarin.eu:cr1:p_1708423613607</xsl:variable>
    <xsl:variable name="new-prof">clarin.eu:cr1:p_1770289476181</xsl:variable>

    <!-- ================================================================
         Identity template: copies everything unchanged by default.
         ================================================================ -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- ================================================================
         NAMESPACE SWITCH: all old cmdp elements → new namespace
         ================================================================ -->
    <xsl:template match="old:*">
        <xsl:choose>
            <!-- Skip empty elements (no child elements, no meaningful text) -->
            <xsl:when test="not(*) and normalize-space() = ''"/>
            <xsl:otherwise>
                <xsl:element name="cmdp:{local-name()}" namespace="http://www.clarin.eu/cmd/1/profiles/{$new-prof}">
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Profile references updated everywhere -->
    <xsl:template match="cmd:CMD/@xsi:schemaLocation">
        <xsl:attribute name="xsi:schemaLocation">
            <xsl:value-of select="replace(., $old-prof, $new-prof)"/>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="cmd:MdProfile/text()">
        <xsl:value-of select="replace(., $old-prof, $new-prof)"/>
    </xsl:template>

    <!-- cmd:valueConceptLink attributes are preserved by the identity template -->

    <!-- ================================================================
         BasicInformation → DataEnvelopeMetadata
         ================================================================ -->
    <xsl:template match="old:BasicInformation">
        <cmdp:DataEnvelopeMetadata>
            <xsl:apply-templates select="old:title"/>
            <!-- Version wrapper (NEW): contains Snapshot/version + BI/Dates -->
            <cmdp:Version>
                <xsl:for-each select="ancestor::old:DataEnvelope/old:BasicMetadata/old:Snapshot/old:version">
                    <cmdp:versionNumber><xsl:value-of select="."/></cmdp:versionNumber>
                </xsl:for-each>
                <xsl:if test="old:Dates/*">
                    <cmdp:Dates>
                        <xsl:apply-templates select="old:Dates/*"/>
                    </cmdp:Dates>
                </xsl:if>
            </cmdp:Version>
            <xsl:apply-templates select="old:authorDataEnvelope"/>
            <xsl:if test="old:feedbackElaboration/old:feedbackSectionOne">
                <cmdp:Comments>
                    <xsl:for-each select="old:feedbackElaboration/old:feedbackSectionOne">
                        <cmdp:comment><xsl:apply-templates select="@* | node()"/></cmdp:comment>
                    </xsl:for-each>
                </cmdp:Comments>
            </xsl:if>
        </cmdp:DataEnvelopeMetadata>
    </xsl:template>

    <!-- authorDataEnvelope → AuthorDataEnvelope -->
    <xsl:template match="old:BasicInformation/old:authorDataEnvelope">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:AuthorDataEnvelope>
                <xsl:apply-templates select="@* | node()"/>
            </cmdp:AuthorDataEnvelope>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:BasicInformation/old:authorDataEnvelope/old:name">
        <cmdp:personName><xsl:apply-templates select="@* | node()"/></cmdp:personName>
    </xsl:template>
    <xsl:template match="old:BasicInformation/old:authorDataEnvelope/old:orcidID">
        <cmdp:orcidId><xsl:apply-templates select="@* | node()"/></cmdp:orcidId>
    </xsl:template>

    <!-- ================================================================
         BasicMetadata → DatasetMetadata
         ================================================================ -->
    <xsl:template match="old:BasicMetadata">
        <cmdp:DatasetMetadata>
            <xsl:apply-templates select="old:Snapshot/old:title"/>
            <!-- DescriptiveMetadata wrapper (NEW in v2) -->
            <cmdp:DescriptiveMetadata>
                <xsl:apply-templates select="old:Snapshot/old:description"/>
                <!-- Languages -->
                <xsl:if test="old:Snapshot/old:languages | old:Snapshot/old:languageOther">
                    <cmdp:Languages>
                        <xsl:for-each select="old:Snapshot/old:languages">
                            <cmdp:controlledTerm>
                                <xsl:copy-of select="@cmd:valueConceptLink"/>
                                <xsl:value-of select="."/>
                            </cmdp:controlledTerm>
                        </xsl:for-each>
                        <xsl:for-each select="old:Snapshot/old:languageOther">
                            <cmdp:otherTerm><cmdp:term><xsl:value-of select="."/></cmdp:term></cmdp:otherTerm>
                        </xsl:for-each>
                    </cmdp:Languages>
                </xsl:if>
                <!-- Dates (BasicMetadata/Dates → DescriptiveMetadata/Dates) -->
                <xsl:if test="old:Dates/*">
                    <cmdp:Dates>
                        <xsl:for-each select="old:Dates/old:dateFrom">
                            <cmdp:dateFrom><xsl:value-of select="."/></cmdp:dateFrom>
                        </xsl:for-each>
                        <xsl:for-each select="old:Dates/old:dateTo">
                            <cmdp:dateTo><xsl:value-of select="."/></cmdp:dateTo>
                        </xsl:for-each>
                        <xsl:for-each select="old:Dates/old:datasetPublicationDate">
                            <cmdp:datePublished><xsl:value-of select="."/></cmdp:datePublished>
                        </xsl:for-each>
                    </cmdp:Dates>
                </xsl:if>
            </cmdp:DescriptiveMetadata>
            <!-- SubjectMetadata wrapper (NEW in v2) -->
            <cmdp:SubjectMetadata>
                <!-- Genre → GenreOrForm (renamed) -->
                <xsl:if test="old:Snapshot/old:genre | old:Snapshot/old:genreOther">
                    <cmdp:GenreOrForm>
                        <xsl:for-each select="old:Snapshot/old:genre">
                            <cmdp:controlledTerm>
                                <xsl:copy-of select="@cmd:valueConceptLink"/>
                                <xsl:value-of select="."/>
                            </cmdp:controlledTerm>
                        </xsl:for-each>
                        <xsl:for-each select="old:Snapshot/old:genreOther">
                            <cmdp:otherTerm><cmdp:term><xsl:value-of select="."/></cmdp:term></cmdp:otherTerm>
                        </xsl:for-each>
                    </cmdp:GenreOrForm>
                </xsl:if>
                <!-- Topic -->
                <xsl:if test="old:Snapshot/old:topic | old:Snapshot/old:topicOther">
                    <cmdp:Topic>
                        <xsl:for-each select="old:Snapshot/old:topic">
                            <cmdp:controlledTerm>
                                <xsl:copy-of select="@cmd:valueConceptLink"/>
                                <xsl:value-of select="."/>
                            </cmdp:controlledTerm>
                        </xsl:for-each>
                        <xsl:for-each select="old:Snapshot/old:topicOther">
                            <cmdp:otherTerm><cmdp:term><xsl:value-of select="."/></cmdp:term></cmdp:otherTerm>
                        </xsl:for-each>
                    </cmdp:Topic>
                </xsl:if>
                <!-- TemporalCoverage (restructured) -->
                <xsl:apply-templates select="old:Snapshot/old:TemporalCoverage"/>
                <!-- GeographicalCoverage -->
                <xsl:if test="old:Snapshot/old:GeographicalCoverage | old:Snapshot/old:GeographicalCoverageOther">
                    <cmdp:GeographicalCoverage>
                        <xsl:for-each select="old:Snapshot/old:GeographicalCoverage">
                            <cmdp:controlledTerm>
                                <xsl:copy-of select="@cmd:valueConceptLink"/>
                                <xsl:value-of select="."/>
                            </cmdp:controlledTerm>
                        </xsl:for-each>
                        <xsl:for-each select="old:Snapshot/old:GeographicalCoverageOther">
                            <cmdp:otherTerm><cmdp:term><xsl:value-of select="."/></cmdp:term></cmdp:otherTerm>
                        </xsl:for-each>
                    </cmdp:GeographicalCoverage>
                </xsl:if>
            </cmdp:SubjectMetadata>
            <!-- ResponsibleAgents -->
            <xsl:choose>
                <xsl:when test="old:CreatorsContributors">
                    <xsl:apply-templates select="old:CreatorsContributors"/>
                </xsl:when>
                <!-- If no CreatorsContributors but ContactDetails exists, still create ResponsibleAgents -->
                <xsl:when test="ancestor::old:DataEnvelope/old:BasicInformation/old:ContactDetails/*">
                    <cmdp:ResponsibleAgents>
                        <xsl:for-each select="ancestor::old:DataEnvelope/old:BasicInformation/old:ContactDetails">
                            <cmdp:ContactPoint>
                                <xsl:for-each select="old:name">
                                    <cmdp:personName><xsl:value-of select="."/></cmdp:personName>
                                </xsl:for-each>
                                <xsl:for-each select="old:orcidID">
                                    <cmdp:orcidId><xsl:value-of select="."/></cmdp:orcidId>
                                </xsl:for-each>
                                <xsl:for-each select="old:roleInProject">
                                    <cmdp:role><xsl:value-of select="."/></cmdp:role>
                                </xsl:for-each>
                                <xsl:for-each select="old:email">
                                    <cmdp:email><xsl:value-of select="."/></cmdp:email>
                                </xsl:for-each>
                            </cmdp:ContactPoint>
                        </xsl:for-each>
                    </cmdp:ResponsibleAgents>
                </xsl:when>
            </xsl:choose>
            <!-- Distribution -->
            <xsl:apply-templates select="old:distribution"/>
            <!-- RightsStatement -->
            <xsl:apply-templates select="old:accessLicenses"/>
            <!-- VersionMaintenance -->
            <xsl:apply-templates select="old:versionMaintenance"/>
            <!-- Comments (from BM feedbackElaboration) -->
            <xsl:if test="old:feedbackElaboration/old:feedbackSectionTwo">
                <cmdp:Comments>
                    <xsl:for-each select="old:feedbackElaboration/old:feedbackSectionTwo">
                        <cmdp:comment><xsl:apply-templates select="@* | node()"/></cmdp:comment>
                    </xsl:for-each>
                </cmdp:Comments>
            </xsl:if>
        </cmdp:DatasetMetadata>
    </xsl:template>

    <!-- TemporalCoverage: restructured significantly -->
    <xsl:template match="old:Snapshot/old:TemporalCoverage">
        <cmdp:TemporalCoverage>
            <!-- yearFrom/yearTo → CoveragePeriod/dateStart+dateEnd -->
            <xsl:if test="old:yearFrom | old:yearTo">
                <cmdp:CoveragePeriod>
                    <xsl:for-each select="old:yearFrom">
                        <cmdp:dateStart><xsl:value-of select="."/></cmdp:dateStart>
                    </xsl:for-each>
                    <xsl:for-each select="old:yearTo">
                        <cmdp:dateEnd><xsl:value-of select="."/></cmdp:dateEnd>
                    </xsl:for-each>
                </cmdp:CoveragePeriod>
            </xsl:if>
            <!-- year → dateRangeUnstructured -->
            <xsl:for-each select="old:year">
                <cmdp:dateRangeUnstructured><xsl:value-of select="."/></cmdp:dateRangeUnstructured>
            </xsl:for-each>
            <!-- additionalNotes → Comments/comment -->
            <xsl:if test="old:additionalNotes">
                <cmdp:Comments>
                    <xsl:for-each select="old:additionalNotes">
                        <cmdp:comment><xsl:value-of select="."/></cmdp:comment>
                    </xsl:for-each>
                </cmdp:Comments>
            </xsl:if>
        </cmdp:TemporalCoverage>
    </xsl:template>

    <!-- ================================================================
         CreatorsContributors → ResponsibleAgents
         ================================================================ -->
    <xsl:template match="old:CreatorsContributors">
        <cmdp:ResponsibleAgents>
            <!-- ContactPoint from BasicInformation/ContactDetails -->
            <xsl:for-each select="ancestor::old:DataEnvelope/old:BasicInformation/old:ContactDetails">
                <cmdp:ContactPoint>
                    <xsl:for-each select="old:name">
                        <cmdp:personName><xsl:value-of select="."/></cmdp:personName>
                    </xsl:for-each>
                    <xsl:for-each select="old:orcidID">
                        <cmdp:orcidId><xsl:value-of select="."/></cmdp:orcidId>
                    </xsl:for-each>
                    <xsl:for-each select="old:roleInProject">
                        <cmdp:role><xsl:value-of select="."/></cmdp:role>
                    </xsl:for-each>
                    <xsl:for-each select="old:email">
                        <cmdp:email><xsl:value-of select="."/></cmdp:email>
                    </xsl:for-each>
                </cmdp:ContactPoint>
            </xsl:for-each>
            <xsl:apply-templates select="old:Creators"/>
            <xsl:apply-templates select="old:contributors"/>
            <xsl:apply-templates select="old:funding"/>
            <xsl:apply-templates select="old:publishingOrganisation"/>
        </cmdp:ResponsibleAgents>
    </xsl:template>

    <!-- Creators children renamed -->
    <xsl:template match="old:CreatorsContributors/old:Creators/old:Name">
        <cmdp:personName><xsl:apply-templates select="@* | node()"/></cmdp:personName>
    </xsl:template>
    <xsl:template match="old:CreatorsContributors/old:Creators/old:ORCID">
        <cmdp:orcidId><xsl:apply-templates select="@* | node()"/></cmdp:orcidId>
    </xsl:template>
    <xsl:template match="old:CreatorsContributors/old:Creators/old:Organisation">
        <cmdp:organisationName><xsl:apply-templates select="@* | node()"/></cmdp:organisationName>
    </xsl:template>
    <xsl:template match="old:CreatorsContributors/old:Creators/old:ROR">
        <cmdp:rorId><xsl:apply-templates select="@* | node()"/></cmdp:rorId>
    </xsl:template>
    <xsl:template match="old:CreatorsContributors/old:Creators/old:Role">
        <cmdp:role><xsl:apply-templates select="@* | node()"/></cmdp:role>
    </xsl:template>

    <!-- contributors → Contributors -->
    <xsl:template match="old:contributors">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Contributors><xsl:apply-templates select="@* | node()"/></cmdp:Contributors>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:contributors/old:name">
        <cmdp:personName><xsl:apply-templates select="@* | node()"/></cmdp:personName>
    </xsl:template>
    <xsl:template match="old:contributors/old:organisation">
        <cmdp:organisationName><xsl:apply-templates select="@* | node()"/></cmdp:organisationName>
    </xsl:template>

    <!-- funding → Funders -->
    <xsl:template match="old:funding">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Funders><xsl:apply-templates select="@* | node()"/></cmdp:Funders>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:funding/old:name">
        <cmdp:funderName><xsl:apply-templates select="@* | node()"/></cmdp:funderName>
    </xsl:template>
    <xsl:template match="old:funding/old:ROR">
        <cmdp:rorId><xsl:apply-templates select="@* | node()"/></cmdp:rorId>
    </xsl:template>
    <xsl:template match="old:funding/old:summary">
        <cmdp:description><xsl:apply-templates select="@* | node()"/></cmdp:description>
    </xsl:template>

    <!-- publishingOrganisation → PublishingOrganisation -->
    <xsl:template match="old:publishingOrganisation">
        <cmdp:PublishingOrganisation>
            <xsl:for-each select="old:Name">
                <cmdp:organisationName><xsl:value-of select="."/></cmdp:organisationName>
            </xsl:for-each>
            <xsl:for-each select="old:ROR">
                <cmdp:rorId><xsl:value-of select="."/></cmdp:rorId>
            </xsl:for-each>
            <xsl:if test="old:type | old:other">
                <cmdp:OrganisationType>
                    <xsl:for-each select="old:type">
                        <cmdp:controlledTerm><xsl:value-of select="."/></cmdp:controlledTerm>
                    </xsl:for-each>
                    <xsl:for-each select="old:other">
                        <cmdp:otherTerm><cmdp:term><xsl:value-of select="."/></cmdp:term></cmdp:otherTerm>
                    </xsl:for-each>
                </cmdp:OrganisationType>
            </xsl:if>
        </cmdp:PublishingOrganisation>
    </xsl:template>

    <!-- ================================================================
         distribution → Distribution
         ================================================================ -->
    <xsl:template match="old:distribution">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Distribution><xsl:apply-templates select="@* | node()"/></cmdp:Distribution>
        </xsl:if>
    </xsl:template>
    <!-- datasetlink → datasetLink (capital L) -->
    <xsl:template match="old:distribution/old:datasetlink">
        <cmdp:datasetLink><xsl:apply-templates select="@* | node()"/></cmdp:datasetLink>
    </xsl:template>
    <xsl:template match="old:distribution/old:download">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Download><xsl:apply-templates select="@* | node()"/></cmdp:Download>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:distribution/old:citation">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Citation><xsl:apply-templates select="@* | node()"/></cmdp:Citation>
        </xsl:if>
    </xsl:template>

    <!-- ================================================================
         accessLicenses → RightsStatement
         licensingInformation → License (identifier→licenseLabel, url→uri)
         access → AccessDetails (flattened: accessRestricted children promoted)
         ================================================================ -->
    <xsl:template match="old:accessLicenses">
        <cmdp:RightsStatement>
            <xsl:apply-templates select="old:licensingInformation"/>
            <xsl:apply-templates select="old:access"/>
        </cmdp:RightsStatement>
    </xsl:template>
    <xsl:template match="old:licensingInformation">
        <cmdp:Licence>
            <xsl:for-each select="old:identifier">
                <cmdp:label><xsl:value-of select="."/></cmdp:label>
            </xsl:for-each>
            <xsl:for-each select="old:url">
                <cmdp:uri><xsl:value-of select="."/></cmdp:uri>
            </xsl:for-each>
        </cmdp:Licence>
    </xsl:template>
    <!-- access → AccessDetails (flattened: accessRestricted children promoted up) -->
    <xsl:template match="old:access">
        <cmdp:AccessDetails>
            <xsl:apply-templates select="old:accessLevel"/>
            <xsl:apply-templates select="old:accessRestricted/*"/>
        </cmdp:AccessDetails>
    </xsl:template>

    <!-- ================================================================
         versionMaintenance → VersionMaintenance
         ================================================================ -->
    <xsl:template match="old:versionMaintenance">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:VersionMaintenance><xsl:apply-templates select="@* | node()"/></cmdp:VersionMaintenance>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:versionMaintenance/old:version">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Version><xsl:apply-templates select="@* | node()"/></cmdp:Version>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:versionMaintenance/old:maintenance">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Maintenance><xsl:apply-templates select="@* | node()"/></cmdp:Maintenance>
        </xsl:if>
    </xsl:template>
    <!-- maintenancePlan → MaintenancePlan, feedback → Comments/comment -->
    <xsl:template match="old:versionMaintenance/old:maintenancePlan">
        <cmdp:MaintenancePlan>
            <xsl:apply-templates select="old:updates"/>
            <xsl:if test="old:feedback">
                <cmdp:Comments>
                    <xsl:for-each select="old:feedback">
                        <cmdp:comment><xsl:value-of select="."/></cmdp:comment>
                    </xsl:for-each>
                </cmdp:Comments>
            </xsl:if>
        </cmdp:MaintenancePlan>
    </xsl:template>
    <xsl:template match="old:versionMaintenance/old:nextUpdate">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:NextUpdate><xsl:apply-templates select="@* | node()"/></cmdp:NextUpdate>
        </xsl:if>
    </xsl:template>

    <!-- ================================================================
         Data section: mostly case changes on component names
         ================================================================ -->
    <!-- Description → description (lowercase) -->
    <xsl:template match="old:DataResourceDescription/old:Description">
        <cmdp:description><xsl:apply-templates select="@* | node()"/></cmdp:description>
    </xsl:template>

    <!-- dataSubjects → DataSubjects, Subjects → subjects -->
    <xsl:template match="old:dataSubjects">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:DataSubjects><xsl:apply-templates select="@* | node()"/></cmdp:DataSubjects>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:dataSubjects/old:Subjects">
        <cmdp:subjects><xsl:apply-templates select="@* | node()"/></cmdp:subjects>
    </xsl:template>

    <!-- dataModality → DataModality, other → otherTerm/term -->
    <xsl:template match="old:dataModality">
        <cmdp:DataModality>
            <xsl:apply-templates select="old:modality"/>
            <xsl:for-each select="old:other">
                <cmdp:otherTerm><cmdp:term><xsl:value-of select="."/></cmdp:term></cmdp:otherTerm>
            </xsl:for-each>
        </cmdp:DataModality>
    </xsl:template>

    <!-- descriptiveStatistics → DescriptiveStatistics -->
    <xsl:template match="old:descriptiveStatistics">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:DescriptiveStatistics><xsl:apply-templates select="@* | node()"/></cmdp:DescriptiveStatistics>
        </xsl:if>
    </xsl:template>

    <!-- dataFields → DataFields, dataField → DataField, usedVocabularies → UsedVocabularies -->
    <xsl:template match="old:dataFields">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:DataFields><xsl:apply-templates select="@* | node()"/></cmdp:DataFields>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:dataField">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:DataField><xsl:apply-templates select="@* | node()"/></cmdp:DataField>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:usedVocabularies">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:UsedVocabularies><xsl:apply-templates select="@* | node()"/></cmdp:UsedVocabularies>
        </xsl:if>
    </xsl:template>

    <!-- dataExamples → DataExamples, typicalExample → TypicalExample, atypicalExample → AtypicalExample -->
    <xsl:template match="old:dataExamples">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:DataExamples><xsl:apply-templates select="@* | node()"/></cmdp:DataExamples>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:typicalExample">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:TypicalExample><xsl:apply-templates select="@* | node()"/></cmdp:TypicalExample>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:atypicalExample">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:AtypicalExample><xsl:apply-templates select="@* | node()"/></cmdp:AtypicalExample>
        </xsl:if>
    </xsl:template>

    <!-- errors → Errors -->
    <xsl:template match="old:errors">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Errors><xsl:apply-templates select="@* | node()"/></cmdp:Errors>
        </xsl:if>
    </xsl:template>

    <!-- externalResources → ExternalResources -->
    <xsl:template match="old:externalResources">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:ExternalResources><xsl:apply-templates select="@* | node()"/></cmdp:ExternalResources>
        </xsl:if>
    </xsl:template>

    <!-- annotations → Annotations, annotationCharacteristics → AnnotationCharacteristics -->
    <xsl:template match="old:annotations">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Annotations><xsl:apply-templates select="@* | node()"/></cmdp:Annotations>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:annotationCharacteristics">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:AnnotationCharacteristics><xsl:apply-templates select="@* | node()"/></cmdp:AnnotationCharacteristics>
        </xsl:if>
    </xsl:template>

    <!-- socialImpact → SocialImpact and all sub-components capitalised -->
    <xsl:template match="old:socialImpact">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:SocialImpact><xsl:apply-templates select="@* | node()"/></cmdp:SocialImpact>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:safety">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Safety><xsl:apply-templates select="@* | node()"/></cmdp:Safety>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:confidentiality">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Confidentiality><xsl:apply-templates select="@* | node()"/></cmdp:Confidentiality>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:biases">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Biases><xsl:apply-templates select="@* | node()"/></cmdp:Biases>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:sensAttributes">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:SensitivesAttributes><xsl:apply-templates select="@* | node()"/></cmdp:SensitivesAttributes>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:ethicalReview">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:EthicalReview><xsl:apply-templates select="@* | node()"/></cmdp:EthicalReview>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:reviewContact">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:ReviewContact><xsl:apply-templates select="@* | node()"/></cmdp:ReviewContact>
        </xsl:if>
    </xsl:template>

    <!-- dataProvenance → DataProvenance, Name → name -->
    <xsl:template match="old:dataProvenance">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:DataProvenance><xsl:apply-templates select="@* | node()"/></cmdp:DataProvenance>
        </xsl:if>
    </xsl:template>
    <xsl:template match="old:dataProvenance/old:Name">
        <cmdp:name><xsl:apply-templates select="@* | node()"/></cmdp:name>
    </xsl:template>

    <!-- digitisation → Digitisation -->
    <xsl:template match="old:digitisation">
        <xsl:if test="* or normalize-space() != ''">
            <cmdp:Digitisation><xsl:apply-templates select="@* | node()"/></cmdp:Digitisation>
        </xsl:if>
    </xsl:template>

    <!-- ================================================================
         Data/feedbackElaboration → Comments
         ================================================================ -->
    <xsl:template match="old:Data/old:feedbackElaboration">
        <xsl:if test="old:feedbackSectionThree">
            <cmdp:Comments>
                <xsl:for-each select="old:feedbackSectionThree">
                    <cmdp:comment><xsl:apply-templates select="@* | node()"/></cmdp:comment>
                </xsl:for-each>
            </cmdp:Comments>
        </xsl:if>
    </xsl:template>

    <!-- ================================================================
         Uses section
         ================================================================ -->
    <!-- SafetyLevel → safetyLevel (lowercase) in UseWithOtherData -->
    <xsl:template match="old:UseWithOtherData/old:SafetyLevel">
        <cmdp:safetyLevel><xsl:apply-templates select="@* | node()"/></cmdp:safetyLevel>
    </xsl:template>
    <!-- Uses/feedbackElaboration → Comments -->
    <xsl:template match="old:Uses/old:feedbackElaboration">
        <xsl:if test="old:feedbackSectionFour">
            <cmdp:Comments>
                <xsl:for-each select="old:feedbackSectionFour">
                    <cmdp:comment><xsl:apply-templates select="@* | node()"/></cmdp:comment>
                </xsl:for-each>
            </cmdp:Comments>
        </xsl:if>
    </xsl:template>

    <!-- ================================================================
         HumanPerspective/feedbackElaboration → Comments
         ================================================================ -->
    <xsl:template match="old:HumanPerspective/old:feedbackElaboration">
        <xsl:if test="old:feedbackSectionFive">
            <cmdp:Comments>
                <xsl:for-each select="old:feedbackSectionFive">
                    <cmdp:comment><xsl:apply-templates select="@* | node()"/></cmdp:comment>
                </xsl:for-each>
            </cmdp:Comments>
        </xsl:if>
    </xsl:template>

    <!-- ================================================================
         Element renames (new in this version of v2)
         ================================================================ -->
    <!-- confidentialityBin → IsDatasetConfidential -->
    <xsl:template match="old:confidentiality/old:confidentialityBin">
        <cmdp:IsDatasetConfidential><xsl:apply-templates select="@* | node()"/></cmdp:IsDatasetConfidential>
    </xsl:template>

    <!-- errors/errordescription → Errors/description -->
    <xsl:template match="old:errors/old:errordescription">
        <cmdp:description><xsl:apply-templates select="@* | node()"/></cmdp:description>
    </xsl:template>

    <!-- atypicalExample/atypdescription → AtypicalExample/description -->
    <xsl:template match="old:atypicalExample/old:atypdescription">
        <cmdp:description><xsl:apply-templates select="@* | node()"/></cmdp:description>
    </xsl:template>

    <!-- atypicalExample/atyplink → AtypicalExample/link -->
    <xsl:template match="old:atypicalExample/old:atyplink">
        <cmdp:link><xsl:apply-templates select="@* | node()"/></cmdp:link>
    </xsl:template>

    <!-- dataProvenance/yearPublication → yearOfPublication -->
    <xsl:template match="old:dataProvenance/old:yearPublication">
        <cmdp:yearOfPublication><xsl:apply-templates select="@* | node()"/></cmdp:yearOfPublication>
    </xsl:template>

    <!-- dataProvenance/datasheetEnvelope → datasheetOrEnvelopeLink -->
    <xsl:template match="old:dataProvenance/old:datasheetEnvelope">
        <cmdp:datasheetOrEnvelopeLink><xsl:apply-templates select="@* | node()"/></cmdp:datasheetOrEnvelopeLink>
    </xsl:template>

    <!-- avgannotations → averageNumberOfAnnotations -->
    <xsl:template match="old:AnnotationType/old:avgannotations">
        <cmdp:averageNumberOfAnnotations><xsl:apply-templates select="@* | node()"/></cmdp:averageNumberOfAnnotations>
    </xsl:template>

    <!-- knownSafeDatasetsDataTypes → knownSafeDatasetsOrDataTypes -->
    <xsl:template match="old:UseWithOtherData/old:knownSafeDatasetsDataTypes">
        <cmdp:knownSafeDatasetsOrDataTypes><xsl:apply-templates select="@* | node()"/></cmdp:knownSafeDatasetsOrDataTypes>
    </xsl:template>

    <!-- KnownUnsafeDatasetsDataTypes → knownUnsafeDatasetsOrDataTypes -->
    <xsl:template match="old:UseWithOtherData/old:KnownUnsafeDatasetsDataTypes">
        <cmdp:knownUnsafeDatasetsOrDataTypes><xsl:apply-templates select="@* | node()"/></cmdp:knownUnsafeDatasetsOrDataTypes>
    </xsl:template>

</xsl:stylesheet>
