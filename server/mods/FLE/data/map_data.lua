local json = require("include.dkjson")

local function is_water_tile(tile_name)
    return tile_name == "water" or tile_name == "water-green" or tile_name ==
               "water-mud" or tile_name == "water-shallow" or tile_name ==
               "deepwater" or tile_name == "deepwater-green"
end

-- Used to check if a land tile is a valid position for an offshore pump
local function valid_position(surface, position)
    local north_water = {
        {dx = 0, dy = -1}, {dx = 1, dy = -1}, {dx = 0, dy = -2},
        {dx = 1, dy = -2}, {dx = 0, dy = -3}, {dx = 1, dy = -3}
    }

    local south_water = {
        {dx = 0, dy = 1}, {dx = 1, dy = 1}, {dx = 0, dy = 2}, {dx = 1, dy = 2},
        {dx = 0, dy = 3}, {dx = 1, dy = 3}
    }

    local west_water = {
        {dx = -1, dy = 0}, {dx = -1, dy = 1}, {dx = -2, dy = 0},
        {dx = -2, dy = 1}, {dx = -3, dy = 0}, {dx = -3, dy = 1}
    }

    local east_water = {
        {dx = 1, dy = 0}, {dx = 1, dy = 1}, {dx = 2, dy = 0}, {dx = 2, dy = 1},
        {dx = 3, dy = 0}, {dx = 3, dy = 1}
    }

    local all_shapes = {north_water, south_water, west_water, east_water}

    for _, shape in ipairs(all_shapes) do
        local all_water = true
        for _, offset in ipairs(shape) do
            local tile_x = position.x + offset.dx
            local tile_y = position.y + offset.dy
            local tile = surface.get_tile(tile_x, tile_y)
            if not tile or not is_water_tile(tile.name) then
                all_water = false
                break
            end
        end
        if all_water then return true end
    end

    return false
end

function map_data(character_id, radius)
    local character = global.fle.characters[character_id]
    local force = character.force
    local surface = character.surface

    local map_data = {
        tiles = {water_tiles = {}, land_tiles = {}},
        offshore_pump_locations = {}
    }

    local tiles = surface.find_tiles_filtered {
        position = character.position,
        radius = radius
    }

    for _, tile in ipairs(tiles) do
        local position = tile.position

        if is_water_tile(tile.name) then
            table.insert(map_data.tiles.water_tiles, {position = position})

        else
            table.insert(map_data.tiles.land_tiles, {position = position})

            if surface.can_place_entity {
                name = "offshore-pump",
                position = position
            } and valid_position(surface, position) then
                table.insert(map_data.offshore_pump_locations,
                             {position = position})
            end
        end
    end

    return map_data
end

return map_data
