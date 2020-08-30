package com.ultradrive.mapconvert.export.expression;

import com.ultradrive.mapconvert.common.Packable;
import java.util.Iterator;
import java.util.function.Function;


public final class Code
{
    private static class FormattingIterator<T> implements Iterator<String>
    {
        private final Iterator<T> delegate;
        private final String format;

        public FormattingIterator(Iterator<T> delegate, String format)
        {
            this.delegate = delegate;
            this.format = format;
        }

        @Override
        public boolean hasNext()
        {
            return delegate.hasNext();
        }

        @Override
        public String next()
        {
            return String.format(format, delegate.next());
        }
    }

    private static class FormattingIterable<T> implements Iterable<String>
    {
        private final Iterable<T> delegate;
        private final String format;

        FormattingIterable(Iterable<T> delegate, String format)
        {
            this.delegate = delegate;
            this.format = format;
        }

        @Override
        public Iterator<String> iterator()
        {
            return new FormattingIterator<>(delegate.iterator(), format);
        }
    }

    private static class GridIterator<T> implements Iterator<String>
    {
        private final Iterator<T> delegate;
        // When line prefix is defined non continuous output is assumed (ie each line defines a single piece of data)
        private final String linePrefix;
        private final String separator;
        private final int columns;

        public GridIterator(Iterator<T> delegate, String linePrefix, String separator, int columns)
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

    private static class GridIterable<T> implements Iterable<String>
    {
        private final Iterable<T> delegate;
        private final String linePrefix;
        private final String separator;
        private final int columns;

        private GridIterable(Iterable<T> delegate, String linePrefix, String separator, int columns)
        {
            this.delegate = delegate;
            this.linePrefix = linePrefix;
            this.separator = separator;
            this.columns = columns;
        }

        @Override
        public Iterator<String> iterator()
        {
            return new GridIterator<>(delegate.iterator(), linePrefix, separator, columns);
        }
    }

    private static class TransformingIterator<T, R> implements Iterator<R>
    {
        private final Iterator<T> delegate;
        private final Function<T, R> transform;

        private TransformingIterator(Iterator<T> delegate, Function<T, R> transform)
        {
            this.delegate = delegate;
            this.transform = transform;
        }

        @Override
        public boolean hasNext()
        {
            return delegate.hasNext();
        }

        @Override
        public R next()
        {
            return transform.apply(delegate.next());
        }
    }

    private static class TransformingIterable<T, R> implements Iterable<R>
    {
        private final Iterable<T> delegate;
        private final Function<T, R> transform;

        private TransformingIterable(Iterable<T> delegate, Function<T, R> transform)
        {
            this.delegate = delegate;
            this.transform = transform;
        }

        @Override
        public Iterator<R> iterator()
        {
            return new TransformingIterator<>(delegate.iterator(), transform);
        }
    }

    public <T> Iterable<String> format(String format, Iterable<T> iterable)
    {
        return new FormattingIterable<>(iterable, format);
    }

    public String format(String format, Object... values)
    {
        return String.format(format, values);
    }

    public <T> Iterable<String> grid(String linePrefix, String separator, int columns, Iterable<T> iterable)
    {
        return new GridIterable<>(iterable, linePrefix, separator, columns);
    }

    public <T> Iterable<String> grid(String separator, int columns, Iterable<T> iterable)
    {
        return new GridIterable<>(iterable, "", separator, columns);
    }

    public <T extends Packable> Iterable<Integer> pack(Iterable<T> iterable)
    {
        return new TransformingIterable<>(iterable, Packable::pack);
    }

    public int pack(Packable packable)
    {
        return packable.pack();
    }
}
