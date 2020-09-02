package com.ultradrive.mapconvert.export.compression.slz;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.export.compression.CompressionResult;
import com.ultradrive.mapconvert.export.compression.Compressor;
import com.ultradrive.mapconvert.export.compression.common.CompressionBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.StreamSupport;


/**
 * Java port of SLZ compression by Javier Degirolmo (https://github.com/sikthehedgehog)
 */
public class SLZCompressor implements Compressor
{
    private static final int MAX_TOKENS = 8;

    @Override
    public CompressionResult compress(Iterable<Byte> input)
    {
        Byte[] uncompressedBytes = collectInputBytes(input);

        return new CompressionResult(
                compressBytes(uncompressedBytes),
                uncompressedBytes.length);
    }

    private List<Byte> compressBytes(Byte[] inputBytes)
    {
        CompressionBuffer compressionBuffer = new CompressionBuffer(Endianess.BIG, MAX_TOKENS);
        SLZToken token = SLZToken.init(inputBytes);

        while (!token.isTerminal())
        {
            compressionBuffer.writeToken(token);

            token = token.next(inputBytes);
        }

        List<Byte> compressedBytes = new ArrayList<>();
        compressedBytes.addAll(createHeader(inputBytes.length));
        compressedBytes.addAll(compressionBuffer.complete());

        return compressedBytes;
    }

    private Byte[] collectInputBytes(Iterable<Byte> input)
    {
        return StreamSupport.stream(input.spliterator(), false).toArray(Byte[]::new);
    }

    private List<Byte> createHeader(int uncompressedSize)
    {
        List<Byte> buffer = new ArrayList<>();

        byte[] bytes = Endianess.BIG.toBytes((short) uncompressedSize);
        buffer.add(bytes[0]);
        buffer.add(bytes[1]);

        return buffer;
    }
}
