package com.ultradrive.mapconvert;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;


class MapConvertConfiguration
{
    private static final String OPTION_MAP_DIR = "m";
    private static final String OPTION_TEMPLATE_DIR = "t";
    private static final String OPTION_OUTPUT_DIR = "o";
    private static final String OPTION_IMAGE_OUTPUT_DIR = "p";
    private static final String OPTION_IMAGE = "i";
    private static final String OPTION_OBJECT_TYPES_FILE = "f";
    private static final String OPTION_BASE_PATTERN_ID = "b";
    private static final String OPTION_RECURSIVE = "r";

    private final Options options;

    private String mapBaseDirectory;
    private String templateDirectory;
    private String outputDirectory;
    private String imageOutputDirectory;
    private String objectTypesFile;
    private int basePatternId;
    private boolean recursive;
    private boolean saveImages;

    MapConvertConfiguration()
    {
        options = new Options();
        options.addRequiredOption(OPTION_MAP_DIR, "map-dir", true, "Map base directory.");
        options.addRequiredOption(OPTION_TEMPLATE_DIR, "template-dir", true, "Thymeleaf template directory directory.");
        options.addRequiredOption(OPTION_OUTPUT_DIR, "output-dir", true, "Output directory.");
        options.addOption(OPTION_IMAGE_OUTPUT_DIR, "image-output-dir", true, ".png image output directory (uses output-dir if not specified).");
        options.addOption(OPTION_OBJECT_TYPES_FILE, "object-types-file", true, "Location of the tiled objecttypes.xml file.");
        options.addOption(OPTION_BASE_PATTERN_ID, "base-pattern-id", true, "Lowest possible pattern id.");
        options.addOption(OPTION_RECURSIVE, "recursive", false, "Search for maps recursively from map base directory.");
        options.addOption(OPTION_IMAGE, "image", false, "Save .png images of the maps in the directory specified by image-output-dir.");
    }

    public boolean parseCommandLine(String[] args)
    {
        CommandLineParser parser = new DefaultParser();

        try
        {
            CommandLine cmd = parser.parse(options, args);

            mapBaseDirectory = cmd.getOptionValue(OPTION_MAP_DIR);
            templateDirectory = cmd.getOptionValue(OPTION_TEMPLATE_DIR);
            outputDirectory = cmd.getOptionValue(OPTION_OUTPUT_DIR);
            imageOutputDirectory = cmd.getOptionValue(OPTION_IMAGE_OUTPUT_DIR);
            if (imageOutputDirectory == null)
            {
                imageOutputDirectory = outputDirectory;
            }
            objectTypesFile = cmd.getOptionValue(OPTION_OBJECT_TYPES_FILE);
            basePatternId = Integer.parseInt(cmd.getOptionValue(OPTION_BASE_PATTERN_ID, "0"));
            recursive = cmd.hasOption(OPTION_RECURSIVE);
            saveImages = cmd.hasOption(OPTION_IMAGE);
        }
        catch (ParseException e)
        {
            return false;
        }

        return true;
    }

    public void printHelp(String appName)
    {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp(appName, options, true);
    }

    public String getMapBaseDirectory()
    {
        return mapBaseDirectory;
    }

    public String getTemplateDirectory()
    {
        return templateDirectory;
    }

    public String getOutputDirectory()
    {
        return outputDirectory;
    }

    public String getImageOutputDirectory()
    {
        return imageOutputDirectory;
    }

    public String getObjectTypesFile()
    {
        return objectTypesFile;
    }

    public int getBasePatternId()
    {
        return basePatternId;
    }

    public boolean isRecursive()
    {
        return recursive;
    }

    public boolean isSaveImages()
    {
        return saveImages;
    }

    public int getDirectorySearchDepth()
    {
        return recursive ? Integer.MAX_VALUE : 1;
    }
}
