package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.datasource.model.MapModel;

public interface MapDataSource extends MapModel
{
    TilesetDataSource getTilesetDataSource();
}
