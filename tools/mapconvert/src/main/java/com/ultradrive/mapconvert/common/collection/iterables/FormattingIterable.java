package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;


public class FormattingIterable<T> implements Iterable<String>
{
    private final Iterable<T> delegate;
    private final String format;

    public FormattingIterable(Iterable<T> delegate, String format)
    {
        this.delegate = delegate;
        this.format = format;
    }

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

    @Override
    public Iterator<String> iterator()
    {
        return new FormattingIterator<>(delegate.iterator(), format);
    }
}
