package com.ultradrive.mapconvert.export.compression.comper;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.export.compression.CompressionResult;
import com.ultradrive.mapconvert.export.compression.CompressionType;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;


class ComperCompressorTest
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

        CompressionResult slzCompressedResult = CompressionType.COMPER.compress(unCompressedBytes);

        List<Byte> decompressedBytes = comperDecompress(slzCompressedResult.getBytes());

        assertEquals(26000, unCompressedBytes.size());
        assertEquals(354, slzCompressedResult.getCompressedSize());
        assertEquals(unCompressedBytes, decompressedBytes);

    }

    private static List<Byte> comperDecompress(List<Byte> data)
    {
        List<Byte> uncompressed = new ArrayList<>();
        int tokens = 0;

        int sourcPos = 0;
        short flags = 0;
        for (; ; )
        {
            if (tokens == 0)
            {
                byte[] a = new byte[]{data.get(sourcPos), data.get(sourcPos+1)};
                sourcPos+=2;
                flags = Endianess.BIG.shortFromBytes(a);
                tokens = 16;
            }

            if ((flags & 0x8000) == 0)
            {
                // Symbolwise match
                byte[] a = new byte[]{data.get(sourcPos), data.get(sourcPos+1)};
                sourcPos+=2;

                uncompressed.add(a[0]);
                uncompressed.add(a[1]);
            }
            else
            {
                // Dictionary match
                int distance = (0x100 - ((int)data.get(sourcPos) & 0xff)) * 2;
                int length = (int)data.get(sourcPos+1) & 0xff;
                sourcPos+= 2;
                if (length == 0)
                {
                    // End-of-stream marker
                    break;
                }

                int src = uncompressed.size() - distance;
                for (int i = 0; i <= length; i++)
                {
                    uncompressed.add(uncompressed.get(src));
                    uncompressed.add(uncompressed.get(src+1));
                    src+=2;
                }
            }
            tokens--;
            flags <<= 1;
        }

        return uncompressed;
    }
}