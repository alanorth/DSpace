/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.app.xmlui.aspect.browseArtifacts;

import org.apache.cocoon.ProcessingException;
import org.dspace.app.xmlui.cocoon.AbstractDSpaceTransformer;
import org.dspace.app.xmlui.utils.HandleUtil;
import org.dspace.app.xmlui.wing.Message;
import org.dspace.app.xmlui.wing.WingException;
import org.dspace.app.xmlui.wing.element.Body;
import org.dspace.app.xmlui.wing.element.Division;
import org.dspace.app.xmlui.wing.element.List;
import org.dspace.authorize.AuthorizeException;
import org.dspace.browse.BrowseException;
import org.dspace.browse.BrowseIndex;
import org.dspace.content.Collection;
import org.dspace.content.DSpaceObject;
import org.xml.sax.SAXException;

import java.io.IOException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

/**
 * Renders the browse links for a collection
 *
 * @author Kevin Van de Velde (kevin at atmire dot com)
 * @author Mark Diggory (markd at atmire dot com)
 * @author Ben Bosman (ben at atmire dot com)
 */
public class CollectionBrowse extends AbstractDSpaceTransformer {

    private static final Message T_head_browse =
        message("xmlui.ArtifactBrowser.CollectionViewer.head_browse");

    private static final Message T_browse_titles =
        message("xmlui.ArtifactBrowser.CollectionViewer.browse_titles");

    private static final Message T_browse_authors =
        message("xmlui.ArtifactBrowser.CollectionViewer.browse_authors");

    private static final Message T_browse_dates =
        message("xmlui.ArtifactBrowser.CollectionViewer.browse_dates");

    @Override
    public void addBody(Body body) throws SAXException, WingException, SQLException, IOException, AuthorizeException, ProcessingException {
        // don't print any browse buttons on collection pages
        return;
    }
}
