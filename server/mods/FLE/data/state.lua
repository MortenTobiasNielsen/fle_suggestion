local json = require("dkjson")
local fle_utils = require("fle_utils")

local DECIMALS = 2
local ELECTRICITY_DECIMALS = 0

local wreck_names = {
    "crash-site-spaceship-wreck-big-1", "crash-site-spaceship-wreck-big-2",
    "crash-site-spaceship-wreck-medium-1",
    "crash-site-spaceship-wreck-medium-2", "crash-site-spaceship-wreck-medium-3"
}

local status_names, direction_names = {}, {}
for n, c in pairs(defines.entity_status) do status_names[c] = n end
for n, c in pairs(defines.direction) do direction_names[c] = n end

function state(character_index, radius)
    local characters = global.fle.characters
    if not characters or #characters == 0 then
        return json.encode({
            Developer_Error = "No characters initialized. Please use /c remote.call('AICommands', 'reset', 1) to initialize."
        })
    end

    local character = global.fle.characters[character_index]
    local force = character.force
    local surface = character.surface

    local state = {
        characters = {},
        buildings = {},
        electricity = {},
        flow = {production = {}, consumption = {}},
        research_queue = {}
    }

    game.print("Processing character")

    ---------------------------------------------------------------------------
    -- Characters
    ---------------------------------------------------------------------------

    -- This needs to be changed to be force specific when the team config is settled.
    for id, character in ipairs(global.fle.characters) do
        if character.valid then
            local position = {
                x = fle_utils.floor(character.position.x, DECIMALS),
                y = fle_utils.floor(character.position.y, DECIMALS)
            }

            local main_inv = character.get_inventory(defines.inventory
                                                         .character_main)
            local gun_inv = character.get_inventory(defines.inventory
                                                        .character_guns)
            local ammo_inv = character.get_inventory(defines.inventory
                                                         .character_ammo)

            local main_stats = fle_utils.inventory_stats(main_inv)
            local gun_stats = fle_utils.inventory_stats(gun_inv)
            local ammo_stats = fle_utils.inventory_stats(ammo_inv)

            local step = {
                total = #global.fle.character_configs[id].steps,
                current = global.fle.character_configs[id].step_number
            }

            local record = {
                character_index = id,
                position = position,
                inventory = {
                    main = main_stats,
                    guns = gun_stats,
                    ammo = ammo_stats
                },
                step = step,
                walking_state = character.walking_state,
                mining_state = character.mining_state,
                mining_progress = character.character_mining_progress,
                crafting_queue = character.crafting_queue or {},
                crafting_queue_progress = fle_utils.floor(
                    character.crafting_queue_progress, DECIMALS)
            }

            table.insert(state.characters, record)
        end
    end

    game.print("Processing buildings")

    ---------------------------------------------------------------------------
    -- Buildings
    ---------------------------------------------------------------------------

    -- gather entities
    local buildings = global.fle.game_surface.find_entities_filtered {
        position = character.position,
        radius = radius,
        force = character.force
    }

    for _, enttity in ipairs(global.fle.game_surface.find_entities_filtered {
        position = character.position,
        radius = radius,
        name = wreck_names
    }) do table.insert(buildings, enttity) end

    for _, building in ipairs(buildings) do
        if building.valid and building.name ~= "character" then
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

            local status = status_names[building.status]
            if status then record.status = status end

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
                inventory_stats.moduels =
                    fle_utils.inventory_stats(module_inventory)
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

            table.insert(state.buildings, record)
        end
    end

    game.print("Processing electricity")

    ---------------------------------------------------------------------------
    -- Electricity
    ---------------------------------------------------------------------------

    local pole = surface.find_entities_filtered{
        position = character.position,
        radius = radius,
        force = character.force,
        type = "electric-pole"
    }[1]

    local production = 0
    local capacity = 0

    if not pole or not pole.valid then
        state.electricity = {
            production = production,
            capacity = capacity,
            Info = "No electric pole found in the area."
        }
    else

        local stats = pole.electric_network_statistics

        for name in pairs(stats.output_counts) do
            production = production + stats.get_flow_count {
                name = name,
                output = true,
                precision_index = defines.flow_precision_index.five_seconds
            }
        end

        for _, generator in ipairs(surface.find_entities_filtered {
            position = character.position,
            radius = radius,
            force = character.force,
            type = {"burner-generator", "generator", "fusion-reactor"}
        }) do
            if generator.is_connected_to_electric_network() then
                capacity = capacity + generator.prototype.max_power_output
            end
        end

        for _, solar in ipairs(surface.find_entities_filtered {
            position = character.position,
            radius = radius,
            force = character.force,
            type = "solar-panel"
        }) do
            if solar.is_connected_to_electric_network() then
                capacity = capacity + solar.get_electric_output_flow_limit()
            end
        end

        state.electricity = {
            production = fle_utils.floor(production * 60 / 1000,
                                         ELECTRICITY_DECIMALS),
            capacity = fle_utils.floor(capacity * 60 / 1000,
                                       ELECTRICITY_DECIMALS)
        }
    end

    game.print("Processing flow")

    ---------------------------------------------------------------------------
    -- Flow
    ---------------------------------------------------------------------------

    -- Retrieve item production statistics
    local item_stats = force.item_production_statistics
    for name, _ in pairs(item_stats.input_counts) do
        local quantity = item_stats.get_flow_count {
            name = name,
            input = true,
            precision_index = defines.flow_precision_index.one_minute
        }
        quantity = fle_utils.floor(quantity, DECIMALS)
        if quantity > 0 then
            table.insert(state.flow.production,
                         {name = name, quantity = quantity})
        end
    end

    for name, _ in pairs(item_stats.output_counts) do
        local quantity = item_stats.get_flow_count {
            name = name,
            input = false,
            precision_index = defines.flow_precision_index.one_minute
        }
        quantity = fle_utils.floor(quantity, DECIMALS)
        if quantity > 0 then
            table.insert(state.flow.consumption,
                         {name = name, quantity = quantity})
        end
    end

    -- Retrieve fluid production statistics
    local fluid_stats = force.fluid_production_statistics
    for name, _ in pairs(fluid_stats.input_counts) do
        local quantity = fluid_stats.get_flow_count {
            name = name,
            input = true,
            precision_index = defines.flow_precision_index.one_minute
        }
        quantity = fle_utils.floor(quantity, DECIMALS)
        if quantity > 0 then
            table.insert(state.flow.production,
                         {name = name, quantity = quantity})
        end
    end

    for name, _ in pairs(fluid_stats.output_counts) do
        local quantity = fluid_stats.get_flow_count {
            name = name,
            input = false,
            precision_index = defines.flow_precision_index.one_minute
        }
        quantity = fle_utils.floor(quantity, DECIMALS)
        if quantity > 0 then
            table.insert(state.flow.consumption,
                         {name = name, quantity = quantity})
        end
    end

    game.print("Processing research")

    ---------------------------------------------------------------------------
    -- Research queue
    ---------------------------------------------------------------------------

    local current_research = force.current_research
    local current_progress = fle_utils.floor(force.research_progress, DECIMALS)

    if force.research_queue then
        for index, queued_technology in ipairs(force.research_queue) do
            local name = queued_technology.name
            local technology = force.technologies[name]
            if technology then
                local ingredients = {}
                for _, ingredient in
                    ipairs(technology.research_unit_ingredients) do
                    table.insert(ingredients, {
                        name = ingredient.name,
                        amount = ingredient.amount
                    })
                end

                local effects = {}
                for _, effect in pairs(technology.effects) do
                    table.insert(effects, {
                        type = effect.type,
                        recipe = effect.recipe,
                        modifier = effect.modifier
                    })
                end

                local record = {
                    name = name,
                    researched = technology.researched,
                    enabled = technology.enabled,
                    level = technology.level,
                    research_unit_count = technology.research_unit_count,
                    research_unit_energy = technology.research_unit_energy,
                    ingredients = ingredients,
                    effects = effects,
                }

                if current_research and name == current_research.name then
                    record.progress = current_progress
                end

                table.insert(state.research_queue, record)
            end
        end
    end

    game.print("Done processing state")

    return json.encode(state)
end

return state
