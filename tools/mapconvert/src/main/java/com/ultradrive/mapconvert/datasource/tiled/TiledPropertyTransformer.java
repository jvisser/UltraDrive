package com.ultradrive.mapconvert.datasource.tiled;

import java.util.Map;
import org.tiledreader.TiledCustomizable;


interface TiledPropertyTransformer
{
    Map<String, Object> getProperties(TiledCustomizable tiledObject);
}
