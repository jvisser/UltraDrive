package com.ultradrive.mapconvert.export;

import com.ultradrive.mapconvert.processing.map.TileMapCompilation;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collection;
import java.util.List;
import java.util.stream.Stream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.thymeleaf.ITemplateEngine;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import org.thymeleaf.context.IContext;
import org.thymeleaf.templatemode.TemplateMode;
import org.thymeleaf.templateresolver.FileTemplateResolver;

import static java.util.stream.Collectors.toList;


public class MapExporter
{
    private static final Logger LOGGER = LoggerFactory.getLogger(MapExporter.class.getName());
    private final File templatePath;
    private final List<File> additionalTemplatePaths;

    public MapExporter(String templatePath, Collection<String> additionalTemplatePaths)
    {
        this.templatePath = new File(templatePath);
        this.additionalTemplatePaths = additionalTemplatePaths.stream()
                .map(File::new)
                .collect(toList());
    }

    public void export(TileMapCompilation mapCompilation, String outputDirectory) throws IOException
    {
        File outputPath = new File(outputDirectory);
        if (outputPath.exists() || outputPath.mkdirs())
        {
            ITemplateEngine templateEngine = createTemplateEngine();
            IContext context = createContext(mapCompilation);

            List<String> templateFileNames = getTemplateFileNames();
            for (String templateFileName : templateFileNames)
            {
                LOGGER.info("Processing template '{}'", templateFileName);

                String templateResult = templateEngine.process(templateFileName, context);

                writeFile(new File(outputPath, templateFileName), templateResult);
            }
        }
        else
        {
            LOGGER.warn("Unable to create export output directory '{}'", outputDirectory);
        }
    }

    public ITemplateEngine createTemplateEngine()
    {
        FileTemplateResolver templateResolver = new FileTemplateResolver();
        templateResolver.setPrefix(templatePath.getAbsolutePath() + File.separator);
        templateResolver.setTemplateMode(TemplateMode.TEXT);
        templateResolver.setCheckExistence(true);

        TemplateEngine templateEngine = new TemplateEngine();
        templateEngine.addDialect(new MapExporterDialect());

        templateEngine.addTemplateResolver(createFileTemplateResolver(templatePath));
        additionalTemplatePaths.forEach(path -> templateEngine.addTemplateResolver(createFileTemplateResolver(path)));

        return templateEngine;
    }

    private IContext createContext(TileMapCompilation compilation)
    {
        Context context = new Context();

        context.setVariable("tilesets", compilation.getTilesets());
        context.setVariable("maps", compilation.getMaps());
        context.setVariable("collisionblocklists", compilation.getCollisionBlockLists());
        return context;
    }

    private List<String> getTemplateFileNames() throws IOException
    {
        try (Stream<Path> pathStream = Files.walk(templatePath.toPath(), 1))
        {
            return pathStream
                    .map(Path::toFile)
                    .filter(File::isFile)
                    .map(File::getName)
                    .collect(toList());
        }
    }

    private void writeFile(File outputFile, String fileContent) throws IOException
    {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile, false)))
        {
            writer.append(fileContent);
        }
    }

    private FileTemplateResolver createFileTemplateResolver(File path)
    {
        FileTemplateResolver templateResolver = new FileTemplateResolver();
        templateResolver.setPrefix(path.getAbsolutePath() + File.separator);
        templateResolver.setTemplateMode(TemplateMode.TEXT);
        templateResolver.setCheckExistence(true);

        return templateResolver;
    }
}
