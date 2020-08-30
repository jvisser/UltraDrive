package com.ultradrive.mapconvert.export.compression.slz;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.export.compression.CompressionResult;
import com.ultradrive.mapconvert.export.compression.Compressor;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.StreamSupport;


/**
 * Java port of SLZ compression by Javier Degirolmo (https://github.com/sikthehedgehog)
 */
public class SLZCompressor implements Compressor
{
    @Override
    public CompressionResult compress(Iterable<Byte> input)
    {
        Byte[] uncompressedBytes = collectInputBytes(input);

        List<Byte> compressedBytes = compressBytes(uncompressedBytes);

        return new CompressionResult(compressedBytes, uncompressedBytes.length);
    }

    private List<Byte> compressBytes(Byte[] inputBytes)
    {
        List<Byte> compressedBytes = createSLZBuffer(inputBytes);

        SLZCompressionBuffer compressionBuffer = new SLZCompressionBuffer();

        SLZToken token = SLZToken.init(inputBytes);
        while (!token.isTerminal())
        {
            compressionBuffer.writeToken(token);
            if (compressionBuffer.isFull())
            {
                compressedBytes.addAll(compressionBuffer.reset());
            }

            token = token.next(inputBytes);
        }

        compressedBytes.addAll(compressionBuffer.complete());

        return compressedBytes;
    }

    private Byte[] collectInputBytes(Iterable<Byte> input)
    {
        return StreamSupport.stream(input.spliterator(), false).toArray(Byte[]::new);
    }

    private List<Byte> createSLZBuffer(Byte[] inputBytes)
    {
        List<Byte> buffer = new ArrayList<>();

        byte[] bytes = Endianess.BIG.toBytes((short) inputBytes.length);
        buffer.add(bytes[0]);
        buffer.add(bytes[1]);

        return buffer;
    }}
