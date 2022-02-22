package com.ultradrive.mapconvert;

import com.ultradrive.mapconvert.config.PatternAllocationConfiguration;
import com.ultradrive.mapconvert.config.PatternAllocationRange;
import com.ultradrive.mapconvert.config.PreAllocatedPattern;
import com.ultradrive.mapconvert.datasource.tiled.TiledObjectFactory;
import com.ultradrive.mapconvert.export.MapExporter;
import com.ultradrive.mapconvert.processing.map.TileMap;
import com.ultradrive.mapconvert.processing.map.TileMapCompilation;
import com.ultradrive.mapconvert.processing.map.TileMapCompiler;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.render.MapRenderer;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Stream;
import javax.imageio.ImageIO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;


public final class MapConvert implements Runnable
{
    private static final Logger LOGGER = LoggerFactory.getLogger(MapConvert.class.getName());

    private static final String TILED_MAP_FILE_EXTENSION = ".tmx";
    private static final String PNG_FILE_EXTENSION = ".png";

    @CommandLine.Parameters (
            arity = "1",
            paramLabel = "MAPFILE",
            description = "A single map file or a directory containing the maps to process.")
    private String mapPath;

    @CommandLine.Option (
            names = { "-o", "--output-dir" },
            required = true,
            description = "Directory where the processed map/tileset data will be placed.")
    private String outputDirectory;

    @CommandLine.Option (
            names = { "-r", "--recursive" },
            description = "Search for map files recursively if a directory is specified.")
    private boolean recursive;

    @CommandLine.Option (
            names = { "-t", "--template-dir" },
            description = "Directory containing the input templates used to transform the map data.")
    private String templateDirectory;

    @CommandLine.Option (
            names = { "-s", "--search-dir" },
            description = "Additional template search directories for templates referenced by the input templates. Can be specified multiple times.")
    private List<String> additionalTemplateDirectories = new ArrayList<>();

    @CommandLine.Option (
            names = { "-i", "--save-image" },
            description = "Render maps to PNG file from the internally processed map structure.")
    private boolean saveImages;

    @CommandLine.Option (
            names = { "-f", "--object-types-file" },
            description = "Location of the Tiled editor objecttypes.xml file.")
    private String objectTypesFile;

    @CommandLine.Option (
            names = { "-v", "--vram-config" },
            description = "Location of the VRAM layout configuration file.")
    private String vramConfigurationFile;

    public static void main(String[] args)
    {
        System.exit(new CommandLine(new MapConvert()).execute(args));
    }

    @Override
    public void run()
    {
        try
        {
            TileMapCompilation mapCompilation = compileMaps();

            logTilesetStatistics(mapCompilation);

            if (templateDirectory != null)
            {
                export(mapCompilation);
            }

            if (saveImages)
            {
                exportPNG(mapCompilation);
            }
        }
        catch (IOException e)
        {
            throw new IllegalStateException(e);
        }
    }

    private TileMapCompilation compileMaps() throws IOException
    {
        TiledObjectFactory tiledObjectFactory = new TiledObjectFactory(objectTypesFile);

        TileMapCompiler mapCompiler = new TileMapCompiler(getPatternAllocationConfiguration());

        File mapFile = new File(mapPath);
        if (mapFile.exists())
        {
            if (mapFile.isFile())
            {
                mapCompiler.addMapDataSource(tiledObjectFactory.getMapDataSource(mapFile.getAbsolutePath()));
            }
            else
            {
                try (Stream<Path> pathStream = Files.walk(Path.of(mapFile.getAbsolutePath()),
                                                          recursive ? Integer.MAX_VALUE : 1))
                {
                    pathStream.filter(path -> path.toString().endsWith(TILED_MAP_FILE_EXTENSION))
                            .map(path -> tiledObjectFactory.getMapDataSource(path.toAbsolutePath().toString()))
                            .forEach(mapCompiler::addMapDataSource);
                }
            }
        }

        return mapCompiler.compile();
    }

    private PatternAllocationConfiguration getPatternAllocationConfiguration() throws IOException
    {
        if (vramConfigurationFile == null)
        {
            return new PatternAllocationConfiguration(
                    Collections.singletonList(new PatternAllocationRange("Main", 1, Integer.MAX_VALUE)),
                    Collections.singletonList(new PreAllocatedPattern(0, new Pattern(Collections.nCopies(64, 0)))));
        }
        else
        {
            return PatternAllocationConfiguration.read(new File(vramConfigurationFile));
        }
    }

    private void logTilesetStatistics(TileMapCompilation mapCompilation)
    {
        for (Tileset tileset : mapCompilation.getTilesets())
        {
            LOGGER.info("Tileset '{}' = Chunks = {}, Blocks = {}, Patterns = {}",
                        tileset.getName(),
                        tileset.getChunkTileset().getSize(),
                        tileset.getBlockTileset().getSize(),
                        tileset.getPatternAllocation().getSize());
        }
    }

    private void export(TileMapCompilation compile) throws IOException
    {
        MapExporter mapExporter =
                new MapExporter(templateDirectory, additionalTemplateDirectories);

        mapExporter.export(compile, outputDirectory);
    }

    private void exportPNG(TileMapCompilation mapCompilation) throws IOException
    {
        File imageDirectory = new File(outputDirectory).getAbsoluteFile();

        if (imageDirectory.exists() || imageDirectory.mkdirs())
        {
            MapRenderer mapRenderer = new MapRenderer(mapCompilation.getExternalPatterns());
            for (TileMap map : mapCompilation.getMaps())
            {
                String fileName = map.getName() + PNG_FILE_EXTENSION;

                LOGGER.info("Rendering map '{}' to file '{}'", map.getName(), fileName);

                ImageIO.write(mapRenderer.renderMap(map),
                              "png",
                              new File(imageDirectory, fileName));
            }
        }
        else
        {
            LOGGER.warn("Unable to create image export output directory '{}'", imageDirectory.getAbsolutePath());
        }
    }
}
