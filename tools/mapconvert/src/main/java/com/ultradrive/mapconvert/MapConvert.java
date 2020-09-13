package com.ultradrive.mapconvert;

import com.ultradrive.mapconvert.datasource.tiled.TiledObjectFactory;
import com.ultradrive.mapconvert.export.MapExporter;
import com.ultradrive.mapconvert.processing.map.TileMap;
import com.ultradrive.mapconvert.processing.map.TileMapCompilation;
import com.ultradrive.mapconvert.processing.map.TileMapCompiler;
import com.ultradrive.mapconvert.render.MapRenderer;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.imageio.ImageIO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static java.lang.String.format;


public final class MapConvert
{
    private static final String APP_NAME = "MapConvert";
    private static final Logger LOGGER = LoggerFactory.getLogger(MapConvert.class.getName());

    private static final String TILED_MAP_FILE_EXTENSION = ".tmx";
    private static final String PNG_FILE_EXTENSION = ".png";

    private void run(String[] commandLineArguments) throws IOException
    {
        MapConvertConfiguration config = loadConfiguration(commandLineArguments);

        TileMapCompilation mapCompilation = compileMaps(config);

        export(config, mapCompilation);

        if (config.isSaveImages())
        {
            exportPNG(config, mapCompilation);
        }
    }

    private MapConvertConfiguration loadConfiguration(String[] commandLineArguments)
    {
        MapConvertConfiguration config = new MapConvertConfiguration();
        if (!config.parseCommandLine(commandLineArguments))
        {
            config.printHelp(APP_NAME);

            System.exit(1);
        }

        return config;
    }

    private TileMapCompilation compileMaps(MapConvertConfiguration config) throws IOException
    {
        TiledObjectFactory tiledObjectFactory = new TiledObjectFactory(config.getObjectTypesFile());

        TileMapCompiler mapCompiler = new TileMapCompiler(config.getBasePatternId());

        Files.walk(Path.of(config.getMapBaseDirectory()), config.getDirectorySearchDepth())
                .filter(path -> path.toString().endsWith(TILED_MAP_FILE_EXTENSION))
                .map(path -> tiledObjectFactory.getMapDataSource(path.toAbsolutePath().toString()))
                .forEach(mapCompiler::addMapDataSource);

        return mapCompiler.compile();
    }

    private void export(MapConvertConfiguration config, TileMapCompilation compile) throws IOException
    {
        MapExporter mapExporter = new MapExporter(config.getTemplateDirectory());

        mapExporter.export(compile, config.getOutputDirectory());
    }

    private void exportPNG(MapConvertConfiguration config, TileMapCompilation mapCompilation) throws IOException
    {
        File imageDirectory = new File(config.getImageOutputDirectory()).getAbsoluteFile();

        if (imageDirectory.exists() || imageDirectory.mkdirs())
        {
            MapRenderer mapRenderer = new MapRenderer();
            for (TileMap map : mapCompilation.getMaps())
            {
                String fileName = map.getName() + PNG_FILE_EXTENSION;

                LOGGER.info(format("Rendering map '%s' to file '%s'", map.getName(), fileName));

                ImageIO.write(mapRenderer.renderMap(map),
                              "png",
                              new File(imageDirectory, fileName));
            }
        }
        else
        {
            LOGGER.warn(format("Unable to create image export output directory '%s'", imageDirectory.getAbsolutePath()));
        }
    }

    public static void main(String[] args) throws IOException
    {
        MapConvert mapConvert = new MapConvert();

        mapConvert.run(args);
    }
}
