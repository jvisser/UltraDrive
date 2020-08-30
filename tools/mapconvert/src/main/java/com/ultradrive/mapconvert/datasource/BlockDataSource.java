package com.ultradrive.mapconvert.datasource;

import java.net.URL;


public interface BlockDataSource extends BlockModelProducer
{
    int getBlockSize();

    URL getBlockImageSource();
}
