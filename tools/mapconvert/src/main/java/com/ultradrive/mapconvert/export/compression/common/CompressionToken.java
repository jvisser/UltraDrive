package com.ultradrive.mapconvert.export.compression.common;

import java.util.List;


public interface CompressionToken
{
    void write(List<Byte> buffer);

    boolean isCompressed();
}
