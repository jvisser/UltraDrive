package com.ultradrive.mapconvert.common;

import java.util.List;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

import static java.util.stream.Collectors.toList;
import static org.junit.jupiter.api.Assertions.assertEquals;


class EndianessTest
{
    @Test
    void testLongLE()
    {
        testLong(Endianess.LITTLE, 0x0102030405060708L, toBytes( 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01 ));
    }

    @Test
    void testLongBE()
    {
        testLong(Endianess.BIG, 0x0102030405060708L, toBytes( 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08 ));
    }

    @Test
    void testIntegerLE()
    {
        testInteger(Endianess.LITTLE, 0x01020304, toBytes( 0x04, 0x03, 0x02, 0x01 ));
    }

    @Test
    void testIntegerBE()
    {
        testInteger(Endianess.BIG, 0x01020304, toBytes( 0x01, 0x02, 0x03, 0x04 ));
    }

    @Test
    void testShortLE()
    {
        testShort(Endianess.LITTLE, (short) 0x0102, toBytes( 0x02, 0x01 ));
    }

    @Test
    void testShortBE()
    {
        testShort(Endianess.BIG, (short) 0x0102, toBytes( 0x01, 0x02 ));
    }

    private void testLong(Endianess endianess, long value, List<Byte> expectedByteRepresentation)
    {
        List<Byte> byteRepresentation = endianess.toBytes(value);

        assertEquals(expectedByteRepresentation, byteRepresentation);
        assertEquals(value, endianess.longFromBytes(byteRepresentation));
    }

    private void testInteger(Endianess endianess, int value, List<Byte> expectedByteRepresentation)
    {
        List<Byte> byteRepresentation = endianess.toBytes(value);

        assertEquals(expectedByteRepresentation, byteRepresentation);
        assertEquals(value, endianess.intFromBytes(byteRepresentation));
    }

    private void testShort(Endianess endianess, short value, List<Byte> expectedByteRepresentation)
    {
        List<Byte> byteRepresentation = endianess.toBytes(value);

        assertEquals(expectedByteRepresentation, byteRepresentation);
        assertEquals(value, endianess.shortFromBytes(byteRepresentation));
    }

    private List<Byte> toBytes(Integer... bytes)
    {
        return Stream.of(bytes).map(Integer::byteValue).collect(toList());
    }
}