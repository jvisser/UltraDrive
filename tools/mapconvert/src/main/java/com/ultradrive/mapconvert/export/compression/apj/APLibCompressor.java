package com.ultradrive.mapconvert.export.compression.apj;

import com.google.common.primitives.Bytes;
import com.ultradrive.mapconvert.export.compression.CompressionResult;
import com.ultradrive.mapconvert.export.compression.Compressor;
import com.ultradrive.mapconvert.export.compression.apj.sgdk.APJ;
import java.io.IOException;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;


public class APLibCompressor implements Compressor
{
    @Override
    public CompressionResult compress(Iterable<Byte> input)
    {
        byte[] data = Bytes.toArray(StreamSupport.stream(input.spliterator(), false).collect(Collectors.toList()));

        try
        {
            byte[] packedResult = APJ.pack(data,true);

            return new CompressionResult(Bytes.asList(packedResult), data.length);
        }
        catch (IOException e)
        {
            throw new IllegalStateException(e);
        }
    }
}
