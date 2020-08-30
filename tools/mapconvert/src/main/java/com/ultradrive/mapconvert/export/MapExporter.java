package com.ultradrive.mapconvert.export;

import com.ultradrive.mapconvert.processing.map.TileMapCompilation;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.thymeleaf.ITemplateEngine;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import org.thymeleaf.context.IContext;
import org.thymeleaf.templatemode.TemplateMode;
import org.thymeleaf.templateresolver.FileTemplateResolver;

import static java.util.stream.Collectors.toList;


public class MapExporter
{
    private final File templatePath;

    public MapExporter(String templatePath)
    {
        this.templatePath = new File(templatePath);
    }

    public void export(TileMapCompilation mapCompilation, String outputDirectory) throws IOException
    {
        File outputPath = new File(outputDirectory);

        ITemplateEngine templateEngine = createTemplateEngine();
        IContext context = createContext(mapCompilation);

        List<String> templateFileNames = getTemplateFileNames();
        for (String templateFileName : templateFileNames)
        {
            String templateResult = templateEngine.process(templateFileName, context);

            writeFile(new File(outputPath, templateFileName), templateResult);
        }
    }

    private void writeFile(File outputFile, String fileContent) throws IOException
    {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile, false)))
        {
            writer.append(fileContent);
        }
    }

    private List<String> getTemplateFileNames() throws IOException
    {
        return Files.walk(templatePath.toPath(), 1)
                .map(Path::toFile)
                .filter(File::isFile)
                .map(File::getName)
                .collect(toList());
    }

    public ITemplateEngine createTemplateEngine()
    {
        FileTemplateResolver templateResolver = new FileTemplateResolver();
        templateResolver.setPrefix(templatePath.getAbsolutePath() + File.separator);
        templateResolver.setTemplateMode(TemplateMode.TEXT);
        templateResolver.setCheckExistence(true);

        TemplateEngine templateEngine = new TemplateEngine();
        templateEngine.addTemplateResolver(templateResolver);
        templateEngine.addDialect(new MapExporterDialect());
        return templateEngine;
    }

    private IContext createContext(TileMapCompilation compilation)
    {
        Context context = new Context();

        context.setVariable("tilesets", compilation.getTilesets());
        context.setVariable("maps", compilation.getMaps());
        return context;
    }
}
