package org.dspace.app.xmlui.aspect.artifactbrowser;

import org.apache.commons.lang3.StringUtils;
import org.dspace.utils.DSpace;

import java.util.HashMap;

/**
 * Created by jonas on 21/09/15.
 * Search if a given mimetype has a fallback image associated with it (in terms of using it as a thumbnail
 * If no fallback image is configured, a default "blank" will be returned
 */
public class ThumbnailFallBackImagesUtil {


    private static HashMap<String, String> fallbackImages = null;

    public String getFallBackImagesAssociatedToExtension(String metadataField) {
        String fallBackImage = getFallbackImagesConfig().get(metadataField);
        if(StringUtils.isBlank(fallBackImage)){
            return getFallbackImagesConfig().get("default");
        }
        return fallBackImage;
    }

    public HashMap<String, String> getFallbackImagesConfig() {
        if (fallbackImages != null) {
            return fallbackImages;
        }
        fallbackImages = new DSpace().getServiceManager().getServiceByName("mimetypes-with-associated-images", HashMap.class);

        return fallbackImages;
    }
}
