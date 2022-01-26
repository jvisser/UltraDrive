package com.ultradrive.mapconvert.datasource.model;

import com.ultradrive.mapconvert.common.PropertySource;
import java.util.List;


public interface MapModel extends PropertySource
{
    String getName();
    
    int getWidth();

    int getHeight();

    MapLayer getBaseLayer();

    MapLayer getOverlayLayer();

    List<MapObject> getMetadataObjects();
}
