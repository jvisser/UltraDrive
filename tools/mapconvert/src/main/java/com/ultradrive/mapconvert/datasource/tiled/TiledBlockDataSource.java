package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.datasource.BlockDataSource;
import com.ultradrive.mapconvert.datasource.CollisionDataSource;
import com.ultradrive.mapconvert.datasource.model.BlockAnimationFrameModel;
import com.ultradrive.mapconvert.datasource.model.BlockAnimationModel;
import com.ultradrive.mapconvert.datasource.model.BlockModel;
import com.ultradrive.mapconvert.datasource.model.CollisionMetaData;
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


class TiledBlockDataSource extends TiledMetaTileset implements BlockDataSource, CollisionDataSource
{
    private static final String BLOCK_GRAPHICS_TILESET_NAME = "graphicblocks";
    private static final String BLOCK_COLLISION_TILESET_NAME = "collisionblocks";

    private static final String BLOCK_GRAPHICS_LAYER_NAME = "Graphics";
    private static final String BLOCK_COLLISION_LAYER_NAME = "Collision";
    private static final String BLOCK_PRIORITY_LAYER_NAME = "Priority";

    private static final String ANIMATION_ID_PROPERTY_NAME = "animation_id";
    private static final String COLLISION_ANGLE_PROPERTY_NAME = "angle";

    private final TiledTileset collisionTileset;

    private final URL blockImageSource;
    private final URL blockCollisionImageSource;

    TiledBlockDataSource(TiledTileset blockTileset, TiledMap blockMap)
    {
        super(blockTileset, blockMap);

        this.collisionTileset = getTileset(BLOCK_COLLISION_TILESET_NAME);
        this.blockImageSource = getTilesetImageURL(blockTileset, BLOCK_GRAPHICS_TILESET_NAME);
        this.blockCollisionImageSource = getTilesetImageURL(blockTileset, BLOCK_COLLISION_TILESET_NAME);
    }

    private URL getTilesetImageURL(TiledTileset blockTileset, String tilesetName)
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
    public int getBlockSize()
    {
        return tileset.getTileWidth();
    }

    @Override
    public URL getBlockImageSource()
    {
        return blockImageSource;
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

            return new BlockAnimationModel(animationId, animationFrames);
        }
    }

    @Override
    public int getCollisionFieldSize()
    {
        return collisionTileset.getTileWidth();
    }

    @Override
    public URL getCollisionImageSource()
    {
        return blockCollisionImageSource;
    }

    @Override
    public CollisionMetaData getCollisionMetaData(int collisionId)
    {
        TiledTile collisionTile = collisionTileset.getTile(collisionId);
        if (collisionTile == null)
        {
            return CollisionMetaData.empty();
        }

        Float collisionAngle = (Float) collisionTile.getProperty(COLLISION_ANGLE_PROPERTY_NAME);
        if (collisionAngle == null)
        {
            return CollisionMetaData.empty();
        }

        return new CollisionMetaData(collisionAngle);
    }
}
