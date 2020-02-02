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
            (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
            (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
            m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
            })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

            // Attempt to get status of cookieconsent cookie
            var cookieConsentStatus = getCookie('cookieconsent_status');

            // Initialize cookieconsent popup (will only show popup if cookieconsent has not been dismissed with allow or disallow)
            initializeCookieConsent();

            // If user has not explicitly allowed we should set a property to disable Google Analytics
            // If user has explicitly allowed the value of the cookieconsent cookie will be "allow", if not it will be "dismiss"
            // See: https://developers.google.com/analytics/devguides/collection/analyticsjs/user-opt-out
            if ( cookieConsentStatus != 'allow' ) {
            window['ga-disable-</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']"/><xsl:text>'] = true;
            }

            // Initialize Google Analytics with IP anonymization (will not actually send any data to Google if ga-disable-XXXXX-Y property is set)
            ga('create', '</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']"/><xsl:text>', '</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverName']"/><xsl:text>');
            ga('send', 'pageview', {
              'anonymizeIp': true
            });
            </xsl:text></script>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
