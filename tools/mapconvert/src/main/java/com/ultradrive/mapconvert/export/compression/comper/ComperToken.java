package com.ultradrive.mapconvert.export.compression.comper;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.export.compression.common.CompressionToken;
import java.util.List;


class ComperToken implements CompressionToken
{
    public int cost;

    public ComperToken nextToken;
    public ComperToken previousToken;

    public int length;
    public int offset;

    public int index;
    public short value;

    public ComperToken(int cost, int index, short value)
    {
        this.cost = cost;
        this.index = index;
        this.value = value;
    }

    @Override
    public void write(List<Byte> compressionBuffer)
    {
        if (isCompressed())
        {
            int length = nextToken.length;
            int distance = nextToken.index - nextToken.length - nextToken.offset;

            compressionBuffer.add((byte)-distance);
            compressionBuffer.add((byte)(length - 1));
        }
        else
        {
            // Uncompressed
            byte[] bytes = Endianess.BIG.toBytes(value);

            compressionBuffer.add(bytes[0]);
            compressionBuffer.add(bytes[1]);
        }
    }

    @Override
    public boolean isCompressed()
    {
        return nextToken != null && nextToken.length != 0;
    }

    public void linkWeighed(ComperToken token, int offset)
    {
        if (cost > token.cost + 1 + 16)
        {
            cost = token.cost + 1 + 16;
            previousToken = token;
            length = index - token.index;
            this.offset = offset;
        }
    }
}
