package com.ultradrive.mapconvert.export.expression;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.List;

import static com.google.common.primitives.Bytes.asList;


public class FileExpressions
{
    public String asString(String fileName) throws IOException
    {
        return asString(new File(fileName));
    }

    public String asString(File file) throws IOException
    {
        return new String(readFile(file));
    }

    public List<Byte> asBytes(String fileName) throws IOException
    {
        return asBytes(new File(fileName));
    }

    public List<Byte> asBytes(File file) throws IOException
    {
        return asList(readFile(file));
    }

    private byte[] readFile(File file) throws IOException
    {
        return Files.readAllBytes(file.toPath());
    }
}
