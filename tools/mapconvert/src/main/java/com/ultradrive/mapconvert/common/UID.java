package com.ultradrive.mapconvert.common;

public class UID
{
    private static int uid = 0;

    private UID()
    {
    }

    public static int create()
    {
        return uid++;
    }
}
