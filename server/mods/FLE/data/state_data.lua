local json = require("include.dkjson")
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

function state_data(character_id, radius)
    local characters = global.fle.characters
    if not characters or #characters == 0 then
        return {
            Developer_Error = "No characters initialized. Please use /c remote.call('AICommands', 'reset', 1) to initialize."
        }
    end

    local character = global.fle.characters[character_id]
    local force = character.force
    local surface = character.surface

    -- This is intended for external use, we therefore use agents instead of characters.
    local state = {
        agents = {},
        buildings = {},
        electricity = {},
        flow = {production = {}, consumption = {}},
        research_queue = {}
    }

    ---------------------------------------------------------------------------
    -- Agents
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

            local actions = global.fle.character_configs[id].actions
            local current = global.fle.character_configs[id].action_number
            local total = #actions

            local past_actions = {}
            for i = 1, current - 1 do
                table.insert(past_actions, actions[i])
            end

            local future_actions = {}
            for i = current + 1, total do
                table.insert(future_actions, actions[i])
            end

            local actions = {
                past_actions = past_actions,
                current_action = actions[current],
                future_actions = future_actions
            }

            local prototype = character.prototype

            local record = {
                agent_id = id,
                position = position,
                inventory = {
                    main = main_stats,
                    guns = gun_stats,
                    ammo = ammo_stats
                },
                walking_state = character.walking_state.walking,
                mining = {
                    speed = prototype.mining_speed * 1 +
                        character.character_mining_speed_modifier,
                    progress = character.character_mining_progress,
                    is_mining = character.mining_state.mining,
                    position = character.mining_state.position
                },
                crafting = {
                    queue = character.crafting_queue or {},
                    progress = fle_utils.floor(
                        character.crafting_queue_progress, DECIMALS)
                },
                actions = actions
            }

            table.insert(state.agents, record)
        end
    end

    ---------------------------------------------------------------------------
    -- Buildings
    ---------------------------------------------------------------------------

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
                position = building.position,
                selection_box = building.selection_box,
                status = building.status,
                direction = direction
            }

            local status = status_names[building.status]
            if status then record.status = status end

            local inventory_stats = {}

            local fuel_inventory = building.get_fuel_inventory()
            if fuel_inventory then
                inventory_stats.fuel = fle_utils.inventory_stats(fuel_inventory)
            end

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

            local output_inventory = building.get_output_inventory()
            if output_inventory then
                inventory_stats.output =
                    fle_utils.inventory_stats(output_inventory)
            end

            local module_inventory = building.get_module_inventory()
            if module_inventory then
                inventory_stats.moduels =
                    fle_utils.inventory_stats(module_inventory)
            end

            if next(inventory_stats) then
                record.inventory_stats = inventory_stats
            end

            if building.prototype.crafting_categories then
                local recipe = building.get_recipe()
                if recipe then record.recipe = recipe.name end
            end

            if building.drop_target then
                record.drop_target = {
                    name = building.drop_target.name,
                    position = building.drop_target.position
                }
            end

            if building.type == "inserter" and building.pickup_target then
                record.pickup_target = {
                    name = building.pickup_target.name,
                    position = building.pickup_target.position
                }
            end

            -- Add how many ticks of fuel is left, how many ticks is left for the next craft to finish, how many crafts can be made with the current input inventory and how much time that is.  

            table.insert(state.buildings, record)
        end
    end

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
                    level = technology.level,
                    research_unit_count = technology.research_unit_count,
                    research_unit_energy = technology.research_unit_energy,
                    ingredients = ingredients,
                    effects = effects
                }

                if current_research and name == current_research.name then
                    record.progress = current_progress
                end

                table.insert(state.research_queue, record)
            end
        end
    end

    return state
end

return state_data
