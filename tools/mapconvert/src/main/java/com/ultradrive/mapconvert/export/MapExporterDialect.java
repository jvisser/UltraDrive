package com.ultradrive.mapconvert.export;

import com.ultradrive.mapconvert.export.expression.Bytes;
import com.ultradrive.mapconvert.export.expression.Code;
import com.ultradrive.mapconvert.export.expression.Collection;
import com.ultradrive.mapconvert.export.expression.Compression;
import java.util.Map;
import java.util.Set;
import org.thymeleaf.context.IExpressionContext;
import org.thymeleaf.dialect.AbstractDialect;
import org.thymeleaf.dialect.IExpressionObjectDialect;
import org.thymeleaf.expression.IExpressionObjectFactory;


class MapExporterDialect extends AbstractDialect implements IExpressionObjectDialect, IExpressionObjectFactory
{
    private final Map<String, Object> expressionObjects = Map.of("code", new Code(),
                                                                 "bytes", new Bytes(),
                                                                 "compression", new Compression(),
                                                                 "collection", new Collection());

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
