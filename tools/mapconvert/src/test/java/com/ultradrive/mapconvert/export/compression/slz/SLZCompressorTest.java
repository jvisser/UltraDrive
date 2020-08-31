package com.ultradrive.mapconvert.export.compression.slz;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.export.compression.CompressionResult;
import com.ultradrive.mapconvert.export.expression.Compression;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;


class SLZCompressorTest
{
    @Test
    void compress()
    {
        List<Byte> unCompressedBytes = IntStream.range(0, 100)
                .mapToObj(value -> "If two or more (distinct) class modifiers appear in a class declaration, then it is " +
                                   "customary, though not required, that they appear in the order consistent with that " +
                                   "shown above in the production for ClassModifier. " +
                                   "(small text at the bottom of the paragraph!)")
                .flatMap(s -> s.chars().mapToObj(value -> (byte) value))
                .collect(Collectors.toList());

        CompressionResult slzCompressedResult = new Compression().slz(unCompressedBytes);

        List<Byte> decompressedBytes = slzDecompress(slzCompressedResult);

        assertEquals(26000, unCompressedBytes.size());
        assertEquals(3269, slzCompressedResult.getCompressedSize());
        assertEquals(unCompressedBytes, decompressedBytes);
    }

    private List<Byte> slzDecompress(CompressionResult compressionResult)
    {
        List<Byte> compressedBytes = compressionResult.getBytes();

        int size = readShort(compressedBytes, 0);

        List<Byte> result = new ArrayList<>();

        int currentCompressionMarkers = 0;
        int currentTokenCount = 0;

        int readPosition = 2;
        while (result.size() < size)
        {
            if (currentTokenCount == 0)
            {
                currentTokenCount = 8;
                currentCompressionMarkers = compressedBytes.get(readPosition++);
            }

            if ((currentCompressionMarkers & 0x80) == 0x80)
            {
                short info = readShort(compressedBytes, readPosition);
                readPosition += 2;

                int distance = ((info >>> SLZToken.LENGTH_BITS) & SLZToken.DISTANCE_MASK) + 3;
                int length = (info & SLZToken.LENGTH_MASK) + 3;

                int src = result.size() - distance;
                while (length-- > 0)
                {
                    result.add(result.get(src++));
                }
            }
            else
            {
                result.add(compressedBytes.get(readPosition++));
            }

            currentCompressionMarkers <<= 1;
            currentTokenCount--;
        }

        return result;
    }

    private short readShort(List<Byte> compressedBytes, int position)
    {
        return Endianess.BIG.shortFromBytes(new byte[] { compressedBytes.get(position), compressedBytes.get(position + 1) });
    }
}