<xsl:stylesheet xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
                xmlns:dri="http://di.tamu.edu/DRI/1.0/"
                xmlns:mets="http://www.loc.gov/METS/"
                xmlns:xlink="http://www.w3.org/TR/xlink/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:mods="http://www.loc.gov/mods/v3"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:confman="org.dspace.core.ConfigurationManager"
                exclude-result-prefixes="i18n dri mets xlink xsl dim xhtml mods dc confman">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <!-- Add a google analytics script if the key is present -->
    <xsl:template name="googleAnalytics">
        <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']">
            <script><xsl:text>
                Haven.create({
                    notification: {
                        policyUrl: "/page/privacy"
                    },
                    translations: {
                        en: {
                            notification: {
                                policy: "Our privacy statement.",
                                message: "This site uses cookies. By clicking \"agree\" and continuing to use this site you agree to our use of cookies.",
                                accept: "Agree",
                                decline: "Disagree",
                            }
                        },
                    },
                    services: [
                        {
                            name: 'google-analytics',
                            purposes: ['analytics'],
                            type: 'google-analytics',
                            inject: true,
                            options: {
                                id: '</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']"/><xsl:text>',
                            }
                        }
                    ]
                });
            </xsl:text></script>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
