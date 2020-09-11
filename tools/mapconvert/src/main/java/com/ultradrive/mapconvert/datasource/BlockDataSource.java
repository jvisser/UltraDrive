package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.common.PropertySource;
import java.net.URL;


public interface BlockDataSource extends BlockModelProducer, PropertySource
{
    int getBlockSize();

    URL getBlockImageSource();
}
