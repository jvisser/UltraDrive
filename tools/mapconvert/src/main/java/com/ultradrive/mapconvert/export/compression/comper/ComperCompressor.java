package com.ultradrive.mapconvert.export.compression.comper;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.export.compression.CompressionResult;
import com.ultradrive.mapconvert.export.compression.Compressor;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.StreamSupport;


/**
 * Java implementation of Comper compression by vladikcomper (https://github.com/vladikcomper)
 */
public class ComperCompressor implements Compressor
{
    private Byte[] collectInputBytes(Iterable<Byte> input)
    {
        return StreamSupport.stream(input.spliterator(), false).toArray(Byte[]::new);
    }

    @Override
    public CompressionResult compress(Iterable<Byte> source1)
    {
        Byte[] source = collectInputBytes(source1);
        int size_bytes = source.length;
        Byte[] buffer_bytes = new Byte[size_bytes + (size_bytes & 1)];
        System.arraycopy(source, 0, buffer_bytes, 0, size_bytes);

        int size = (size_bytes + 1) / 2;
        short[] buffer = new short[size];
        for (int i = 0; i < size; ++i)
        {
            buffer[i] = (short)((buffer_bytes[i * 2] << 8) | ((short)(buffer_bytes[(i * 2) + 1]) & 0xff));
        }

        ComperToken[] tokens = new ComperToken[size + 1];

        // Initialise the array
        tokens[0] = new ComperToken(0, 0, buffer[0]);
        for (int i = 1; i < size + 1; ++i)
            tokens[i] = new ComperToken(Integer.MAX_VALUE, i, buffer[Math.min(i, size -1)]);

        // Find matches
        for (int currentPosition = 0; currentPosition < size; ++currentPosition)
        {
            int max_read_ahead = Math.min(0x100, size - currentPosition);
            int max_read_behind = Math.max(0, currentPosition - 0x100);

            // Search for dictionary matches
            for (int readBehindPosition = currentPosition; readBehindPosition-- > max_read_behind;)
            {
                for (int readAheadOffset = 0; readAheadOffset < max_read_ahead; ++readAheadOffset)
                {
                    if (buffer[currentPosition + readAheadOffset] == buffer[readBehindPosition + readAheadOffset])
                    {
                        // Update this node's optimal edge if this one is better
                        tokens[currentPosition + readAheadOffset + 1].linkWeighed(tokens[currentPosition], readBehindPosition);
                    }
                    else
                    {
                        break;
                    }
                }
            }

            // Do literal match
            // Update this node's optimal edge if this one is better (or the same, since literal matches usually decode faster)
            if (tokens[currentPosition + 1].cost >= tokens[currentPosition].cost + 1 + 16)
            {
                tokens[currentPosition + 1].cost = tokens[currentPosition].cost + 1 + 16;
                tokens[currentPosition + 1].previousToken = tokens[currentPosition];
                tokens[currentPosition + 1].length = 0;
            }
        }

        // Reverse the edge link order, so the array can be traversed from start to end, rather than vice versa
        tokens[0].previousToken = null;
        tokens[size].nextToken = null;

        ComperToken currentToken = tokens[size];
        while (currentToken.previousToken != null)
        {
            currentToken.previousToken.nextToken = currentToken;
            currentToken = currentToken.previousToken;
        }

        /*
         * LZSS graph complete
         */

        int tokenCount = 0;
        short tokenCompressionFlags = 0;

        List<Byte> data = new ArrayList<>();
        List<Byte> compressionBuffer = new ArrayList<>();

        currentToken = tokens[0];
        while(currentToken.nextToken != null)
        {
            currentToken.write(compressionBuffer);
            if (currentToken.isCompressed())
            {
                tokenCompressionFlags |= 1;
            }

            tokenCount++;
            if (tokenCount == 16)
            {
                byte[] bytes = Endianess.BIG.toBytes(tokenCompressionFlags);
                data.add(bytes[0]);
                data.add(bytes[1]);

                data.addAll(compressionBuffer);

                compressionBuffer.clear();

                tokenCompressionFlags = 0;
                tokenCount = 0;
            }
            tokenCompressionFlags <<= 1;

            currentToken = currentToken.nextToken;
        }

        tokenCompressionFlags |= 1;
        tokenCount++;

        if (!compressionBuffer.isEmpty())
        {
            compressionBuffer.add((byte)0);
            compressionBuffer.add((byte)0);
        }

        tokenCompressionFlags <<= 16 - tokenCount;
        byte[] bytes = Endianess.BIG.toBytes(tokenCompressionFlags);
        data.add(bytes[0]);
        data.add(bytes[1]);

        data.addAll(compressionBuffer);

        return new CompressionResult(data, source.length);
    }
}
