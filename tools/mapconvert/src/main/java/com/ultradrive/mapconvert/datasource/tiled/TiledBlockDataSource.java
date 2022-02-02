package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.datasource.BlockDataSource;
import com.ultradrive.mapconvert.datasource.model.BlockAnimationFrameModel;
import com.ultradrive.mapconvert.datasource.model.BlockAnimationModel;
import com.ultradrive.mapconvert.datasource.model.BlockModel;
import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.tiledreader.TiledMap;
import org.tiledreader.TiledTile;
import org.tiledreader.TiledTileLayer;
import org.tiledreader.TiledTileset;


class TiledBlockDataSource extends TiledMetaTileset implements BlockDataSource
{
    private static final String BLOCK_GRAPHICS_TILESET_NAME = "graphicblocks";
    private static final String BLOCK_COLLISION_TILESET_NAME = "collisionblocks";

    private static final String BLOCK_GRAPHICS_LAYER_NAME = "Graphics";
    private static final String BLOCK_COLLISION_LAYER_NAME = "Collision";
    private static final String BLOCK_PRIORITY_LAYER_NAME = "Priority";

    private static final String ANIMATION_ID_PROPERTY_NAME = "animationId";

    private final URL blockImageSource;

    TiledBlockDataSource(TiledTileset blockTileset, TiledMap blockMap, TiledPropertyTransformer propertyTransformer)
    {
        super(blockTileset, blockMap, propertyTransformer);

        this.blockImageSource = getTilesetImageURL(BLOCK_GRAPHICS_TILESET_NAME);
    }

    private URL getTilesetImageURL(String tilesetName)
    {
        TiledTileset graphicsTileset = getTileset(tilesetName);
        try
        {
            return new File(graphicsTileset.getImage().getSource()).toURI().toURL();
        }
        catch (MalformedURLException eae)
        {
            throw new IllegalArgumentException("Invalid tileset image", eae);
        }
    }

    @Override
    public BlockModel getBlockModel(int blockId)
    {
        TiledTileLayer graphicsLayer = getLayer(BLOCK_GRAPHICS_LAYER_NAME);
        TiledTileLayer collisionLayer = getLayer(BLOCK_COLLISION_LAYER_NAME);
        TiledTileLayer priorityLayer = getLayer(BLOCK_PRIORITY_LAYER_NAME);

        TiledTile blockTile = tileset.getTile(blockId);

        int tileX = blockTile.getTilesetX();
        int tileY = blockTile.getTilesetY();

        return new BlockModel(
                blockId,
                getAnimationModel(blockTile, graphicsLayer),
                getResourceReference(graphicsLayer, tileX, tileY),
                getResourceReference(collisionLayer, tileX, tileY),
                getResourceReference(priorityLayer, tileX, tileY));
    }

    private BlockAnimationModel getAnimationModel(TiledTile blockTile, TiledTileLayer graphicsLayer)
    {
        String animationId = (String) blockTile.getProperty(ANIMATION_ID_PROPERTY_NAME);
        if (animationId == null || animationId.isEmpty())
        {
            return BlockAnimationModel.empty();
        }
        else
        {
            List<BlockAnimationFrameModel> animationFrames = IntStream.range(0, blockTile.getNumAnimationFrames())
                    .mapToObj(animationFrameIndex -> {
                        TiledTile animationFrameTile = blockTile.getAnimationFrame(animationFrameIndex);
                        return new BlockAnimationFrameModel(
                                getResourceReference(graphicsLayer,
                                                     animationFrameTile.getTilesetX(),
                                                     animationFrameTile.getTilesetY()).getId(),
                                blockTile.getAnimationFrameDuration(animationFrameIndex));
                    })
                    .collect(Collectors.toUnmodifiableList());

            return new BlockAnimationModel(animationId, blockTile.getType(), animationFrames,
                                           propertyTransformer.getProperties(blockTile));
        }
    }

    @Override
    public int getBlockSize()
    {
        return tileset.getTileWidth();
    }

    @Override
    public URL getBlockImageSource()
    {
        return blockImageSource;
    }

    public TiledCollisionBlockDataSource readCollisionTileset()
    {
        return new TiledCollisionBlockDataSource(
                getTileset(BLOCK_COLLISION_TILESET_NAME),
                getTilesetImageURL(BLOCK_COLLISION_TILESET_NAME),
                propertyTransformer);
    }
}
