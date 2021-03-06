package com.ultradrive.mapconvert.export.expression;

import com.ultradrive.mapconvert.common.Packable;
import com.ultradrive.mapconvert.common.collection.iterables.TransformingIterable;
import java.util.Arrays;
import java.util.Iterator;
import javax.annotation.Nonnull;


public final class FormatExpressions
{
    private static class ArrayFormattingIterable<T> implements Iterable<String>
    {
        private final Iterable<T> delegate;
        private final String linePrefix;
        private final String separator;
        private final int columns;

        ArrayFormattingIterable(Iterable<T> delegate, String linePrefix, String separator, int columns)
        {
            this.delegate = delegate;
            this.linePrefix = linePrefix;
            this.separator = separator;
            this.columns = columns;
        }

        private static class ArrayFormattingIterator<T> implements Iterator<String>
        {
            private final Iterator<T> delegate;
            // When line prefix is defined non continuous output is assumed (ie each line defines a single piece of data)
            private final String linePrefix;
            private final String separator;
            private final int columns;

            public ArrayFormattingIterator(Iterator<T> delegate, String linePrefix, String separator, int columns)
            {
                this.delegate = delegate;
                this.linePrefix = linePrefix;
                this.separator = separator;
                this.columns = columns;
            }

            @Override
            public boolean hasNext()
            {
                return delegate.hasNext();
            }

            @Override
            public String next()
            {
                StringBuilder result = new StringBuilder(linePrefix);
                for (int i = 0; i < columns && delegate.hasNext(); i++)
                {
                    if (i > 0)
                    {
                        result.append(separator);
                    }
                    result.append(delegate.next());
                }

                if (linePrefix.isEmpty() && delegate.hasNext())
                {
                    result.append(separator);
                }
                return result.toString();
            }
        }

        @Override
        @Nonnull
        public Iterator<String> iterator()
        {
            return new ArrayFormattingIterator<>(delegate.iterator(), linePrefix, separator, columns);
        }
    }

    public <T> Iterable<String> format(String format, Iterable<T> iterable)
    {
        return new TransformingIterable<>(iterable, value -> format(format, unpack(value)));
    }

    public String format(String format, Object... values)
    {
        return String.format(format, Arrays.stream(values).map(this::unpack).toArray());
    }

    private Object unpack(Object value)
    {
        if (value instanceof Packable)
        {
            Packable packable = (Packable) value;

            return packable.pack().numberValue();
        }
        return value;
    }

    public <T> Iterable<String> formatArray(String linePrefix, String separator, int columns, Iterable<T> iterable)
    {
        return new ArrayFormattingIterable<>(iterable, linePrefix, separator, columns);
    }

    public <T> Iterable<String> formatArray(String separator, int columns, Iterable<T> iterable)
    {
        return formatArray( "", separator, columns, iterable);
    }

    public <T> Iterable<String> formatArray(String linePrefix, String separator, int columns, String elementFormat, Iterable<T> iterable)
    {
        return formatArray(linePrefix, separator, columns, format(elementFormat, iterable));
    }

    public <T> Iterable<String> formatArray(String separator, int columns, String elementFormat, Iterable<T> iterable)
    {
        return formatArray( "", separator, columns, format(elementFormat, iterable));
    }
}
