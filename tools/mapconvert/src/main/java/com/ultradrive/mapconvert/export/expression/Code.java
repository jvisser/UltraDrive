package com.ultradrive.mapconvert.export.expression;

import com.ultradrive.mapconvert.common.Packable;
import com.ultradrive.mapconvert.export.expression.common.FormattingIterable;
import com.ultradrive.mapconvert.export.expression.common.TransformingIterable;
import java.util.Iterator;


public final class Code
{
    private static class GroupingIterator<T> implements Iterator<String>
    {
        private final Iterator<T> delegate;
        // When line prefix is defined non continuous output is assumed (ie each line defines a single piece of data)
        private final String linePrefix;
        private final String separator;
        private final int columns;

        public GroupingIterator(Iterator<T> delegate, String linePrefix, String separator, int columns)
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

    private static class GroupingIterable<T> implements Iterable<String>
    {
        private final Iterable<T> delegate;
        private final String linePrefix;
        private final String separator;
        private final int columns;

        private GroupingIterable(Iterable<T> delegate, String linePrefix, String separator, int columns)
        {
            this.delegate = delegate;
            this.linePrefix = linePrefix;
            this.separator = separator;
            this.columns = columns;
        }

        @Override
        public Iterator<String> iterator()
        {
            return new GroupingIterator<>(delegate.iterator(), linePrefix, separator, columns);
        }
    }

    public <T> Iterable<String> format(String format, Iterable<T> iterable)
    {
        return new FormattingIterable<>(
                new TransformingIterable<>(iterable,
                                           value ->
                                           {
                                               if (value instanceof Packable)
                                               {
                                                   return ((Packable) value).pack().numberValue();
                                               }
                                               return value;
                                           }),
                format);
    }

    public String format(String format, Object... values)
    {
        return String.format(format, values);
    }

    public <T> Iterable<String> group(String linePrefix, String separator, int columns, Iterable<T> iterable)
    {
        return new GroupingIterable<>(iterable, linePrefix, separator, columns);
    }

    public <T> Iterable<String> group(String separator, int columns, Iterable<T> iterable)
    {
        return new GroupingIterable<>(iterable, "", separator, columns);
    }
}
