local json = require("dkjson")
local fle_utils = require("fle_utils")

local DECIMALS = 2

function buildings_data()
    local wreck_names = {
        "crash-site-spaceship-wreck-big-1", "crash-site-spaceship-wreck-big-2",
        "crash-site-spaceship-wreck-medium-1",
        "crash-site-spaceship-wreck-medium-2",
        "crash-site-spaceship-wreck-medium-3"
    }

    -- gather entities
    local buildings = global.fle.game_surface.find_entities_filtered {
        area = global.fle.area,
        force = "player"
    }

    for _, ent in ipairs(global.fle.game_surface.find_entities_filtered {
        area = global.fle.area,
        name = wreck_names
    }) do

        -- game.print(ent.get_output_inventory().count_empty_stacks())

        table.insert(buildings, ent)
    end

    -- maps for status & direction names
    local status_names, direction_names = {}, {}
    for n, c in pairs(defines.entity_status) do status_names[c] = n end
    for n, c in pairs(defines.direction) do direction_names[c] = n end

    data = {}
    for _, building in ipairs(buildings) do
        if building.valid and building.name ~= "character" then
            local status = status_names[building.status] or "unknown"
            local direction = direction_names[building.direction or 0] or
                                  tostring(building.direction)

            local box = building.selection_box
            local left_top = box.left_top
            local right_bottom = box.right_bottom

            local left_top_x = fle_utils.floor(left_top.x, DECIMALS)
            local left_top_y = fle_utils.floor(left_top.y, DECIMALS)
            local right_bottom_x = fle_utils.ceil(right_bottom.x, DECIMALS)
            local right_bottom_y = fle_utils.ceil(right_bottom.y, DECIMALS)

            local selection_box = {
                {x = left_top_x, y = left_top_y},
                {x = right_bottom_x, y = right_bottom_y}
            }

            local record = {
                name = building.name,
                position = {x = building.position.x, y = building.position.y},
                selection_box = selection_box,
                status = status,
                direction = direction
            }

            local inventory_stats = {}

            -- Fuel inventory
            local fuel_inventory = building.get_fuel_inventory()
            if fuel_inventory then
                inventory_stats.fuel = fle_utils.inventory_stats(fuel_inventory)
            end

            -- Input inventory (assembling machine or lab)
            local input_inventory = building.get_inventory(defines.inventory
                                                               .assembling_machine_input)
            if not input_inventory then
                input_inventory = building.get_inventory(defines.inventory
                                                             .lab_input)
            end
            if input_inventory then
                inventory_stats.input = fle_utils.inventory_stats(
                                            input_inventory)
            end

            -- Output inventory
            local output_inventory = building.get_output_inventory()
            if output_inventory then
                inventory_stats.output =
                    fle_utils.inventory_stats(output_inventory)
            end

            -- Module inventory
            local module_inventory = building.get_module_inventory()
            if module_inventory then
                inventory_stats.moduels = fle_utils.inventory_stats(
                                           module_inventory)
            end

            -- Add inventory_stats to record if any inventories are present
            if next(inventory_stats) then
                record.inventory_stats = inventory_stats
            end

            -- Recipe information
            if building.prototype.crafting_categories then
                local recipe = building.get_recipe()
                if recipe then record.recipe = recipe.name end
            end

            table.insert(data, record)
        end
    end

    return json.encode(data)
end

return buildings_data
