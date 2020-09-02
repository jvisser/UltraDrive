package com.ultradrive.mapconvert.export;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.common.collection.iterables.ByteIterableFactory;
import com.ultradrive.mapconvert.export.compression.CompressionType;
import com.ultradrive.mapconvert.export.expression.CollectionExpressions;
import com.ultradrive.mapconvert.export.expression.FormattingExpressions;
import java.util.Map;
import java.util.Set;
import org.thymeleaf.context.IExpressionContext;
import org.thymeleaf.dialect.AbstractDialect;
import org.thymeleaf.dialect.IExpressionObjectDialect;
import org.thymeleaf.expression.IExpressionObjectFactory;


class MapExporterDialect extends AbstractDialect implements IExpressionObjectDialect, IExpressionObjectFactory
{
    private final Map<String, Object> expressionObjects = Map.of("format", new FormattingExpressions(),
                                                                 "collection", new CollectionExpressions(),
                                                                 "byteBE", new ByteIterableFactory(Endianess.BIG),
                                                                 "byteLE", new ByteIterableFactory(Endianess.LITTLE),
                                                                 "slz", CompressionType.SLZ,
                                                                 "comper", CompressionType.COMPER);

    protected MapExporterDialect()
    {
        super("MapExporterDialect");
    }

    @Override
    public IExpressionObjectFactory getExpressionObjectFactory()
    {
        return this;
    }

    @Override
    public Set<String> getAllExpressionObjectNames()
    {
        return expressionObjects.keySet();
    }

    @Override
    public Object buildObject(IExpressionContext context, String expressionObjectName)
    {
        return expressionObjects.get(expressionObjectName);
    }

    @Override
    public boolean isCacheable(String expressionObjectName)
    {
        return true;
    }
}
