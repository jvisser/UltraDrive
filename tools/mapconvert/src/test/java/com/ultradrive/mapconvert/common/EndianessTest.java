package com.ultradrive.mapconvert.common;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;


class EndianessTest
{
    @Test
    void testLongLE()
    {
        testLong(Endianess.LITTLE, 0x0102030405060708L, new byte[] { 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01 });
    }

    @Test
    void testLongBE()
    {
        testLong(Endianess.BIG, 0x0102030405060708L, new byte[] { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08 });
    }

    @Test
    void testIntegerLE()
    {
        testInteger(Endianess.LITTLE, 0x01020304, new byte[] { 0x04, 0x03, 0x02, 0x01 });
    }

    @Test
    void testIntegerBE()
    {
        testInteger(Endianess.BIG, 0x01020304, new byte[] { 0x01, 0x02, 0x03, 0x04 });
    }

    @Test
    void testShortLE()
    {
        testShort(Endianess.LITTLE, (short) 0x0102, new byte[] { 0x02, 0x01 });
    }

    @Test
    void testShortBE()
    {
        testShort(Endianess.BIG, (short) 0x0102, new byte[] { 0x01, 0x02 });
    }

    private void testLong(Endianess endianess, long value, byte[] expectedByteRepresentation)
    {
        byte[] byteRepresentation = endianess.toBytes(value);

        assertArrayEquals(expectedByteRepresentation, byteRepresentation);
        assertEquals(value, endianess.longFromBytes(byteRepresentation));
    }

    private void testInteger(Endianess endianess, int value, byte[] expectedByteRepresentation)
    {
        byte[] byteRepresentation = endianess.toBytes(value);

        assertArrayEquals(expectedByteRepresentation, byteRepresentation);
        assertEquals(value, endianess.intFromBytes(byteRepresentation));
    }

    private void testShort(Endianess endianess, short value, byte[] expectedByteRepresentation)
    {
        byte[] byteRepresentation = endianess.toBytes(value);

        assertArrayEquals(expectedByteRepresentation, byteRepresentation);
        assertEquals(value, endianess.shortFromBytes(byteRepresentation));
    }

}