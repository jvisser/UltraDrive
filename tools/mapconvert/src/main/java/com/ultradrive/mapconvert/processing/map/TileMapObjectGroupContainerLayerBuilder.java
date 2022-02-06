package com.ultradrive.mapconvert.processing.map;


import com.ultradrive.mapconvert.datasource.model.ChunkReferenceModel;
import com.ultradrive.mapconvert.datasource.model.MapLayer;
import com.ultradrive.mapconvert.datasource.model.MapModel;


class TileMapObjectGroupContainerLayerBuilder extends GroupLayerBuilder<TileMapObjectGroupContainerBuilder>
{
    private final TileMapObjectGroupContainerBuilder root = new TileMapObjectGroupContainerBuilder(null);

    private GroupSubLayer<TileMapObjectGroupContainerBuilder> baseSubLayer;
    private GroupSubLayer<TileMapObjectGroupContainerBuilder> overlaySubLayer;

    public TileMapObjectGroupContainerLayerBuilder(MapModel mapModel, int screenWidth, int screenHeight)
    {
        super(mapModel, screenWidth, screenHeight);
    }

    public void compile()
    {
        groupBuilders.add(root);

        MapLayer baseLayer = mapModel.getBaseLayer();
        MapLayer overlayLayer = mapModel.getOverlayLayer();

        TileMapObjectGroupContainerBuilder[][] groupMap = createGroupMap(baseLayer);
        TileMapObjectGroupContainerBuilder[][] overlayGroupMap = createGroupMap(overlayLayer);

        // NB: Would be more correct to associate based on the leaf nodes.
        //  But as long as the flags don't overflow it doesn't matter all that much.
        associateObjectGroupsBasedOnScreenSpace(groupMap);
        associateObjectGroupsBasedOnScreenSpace(mergeGroupMaps(groupMap, overlayGroupMap));

        replaceZeroWithRoot(groupMap);
        replaceZeroWithRoot(overlayGroupMap);

        createObjectGroupFlags();

        baseSubLayer = (row, column) -> groupMap[row][column];
        overlaySubLayer = (row, column) -> overlayGroupMap[row][column];
    }

    private void replaceZeroWithRoot(TileMapObjectGroupContainerBuilder[][] groupMap)
    {
        for (int row = 0; row < mapModel.getHeight(); row++)
        {
            for (int column = 0; column < mapModel.getWidth(); column++)
            {
                if (groupMap[row][column].isZeroGroup())
                {
                    groupMap[row][column] = root;
                }
            }
        }
    }

    @Override
    protected int getGroupId(ChunkReferenceModel chunkReference)
    {
        return chunkReference.getObjectGroupContainerId();
    }

    @Override
    protected TileMapObjectGroupContainerBuilder getDefaultGroup(int groupId)
    {
        return groupId == ChunkReferenceModel.EMPTY_GROUP_CONTAINER_ID
               ? TileMapObjectGroupContainerBuilder.ZERO
               : null;
    }

    @Override
    protected TileMapObjectGroupContainerBuilder[][] createMap()
    {
        return new TileMapObjectGroupContainerBuilder[mapModel.getHeight()][mapModel.getWidth()];
    }

    @Override
    protected TileMapObjectGroupContainerBuilder createGroup()
    {
        return new TileMapObjectGroupContainerBuilder(root);
    }

    public GroupSubLayer<TileMapObjectGroupContainerBuilder> getBaseContainers()
    {
        return baseSubLayer;
    }

    public GroupSubLayer<TileMapObjectGroupContainerBuilder> getOverlayContainers()
    {
        return overlaySubLayer;
    }
}
