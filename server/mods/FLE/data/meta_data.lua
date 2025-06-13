local json = require("include.dkjson")
local fle_utils = require("fle_utils")
local DECIMALS = 2

function meta_data(character_id, radius)
    local character = global.fle.characters[character_id]
    local force = character.force
    local surface = character.surface

    local meta_data = {
        resources = {trees = {}, special = {}},
        items = {},
        recipes = {},
        technologies = {}
    }

    ---------------------------------------------------------------------------
    -- Resources
    ---------------------------------------------------------------------------
    local resources = surface.find_entities_filtered {
        position = character.position,
        radius = radius,
        type = {"resource", "tree", "simple-entity"}
    }

    for _, entity in ipairs(resources) do
        if entity.valid then
            local box = entity.selection_box
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
            
            local prototype = entity.prototype
            if entity.type == "tree" then
                table.insert(meta_data.resources.trees, {
                    mining_time = prototype.mineable_properties.mining_time,
                    output = prototype.mineable_properties.products,
                    selection_box = selection_box
                })
            elseif entity.type == "simple-entity" then
                if prototype and prototype.mineable_properties.minable then

                    local box = entity.selection_box
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

                    table.insert(meta_data.special, {
                        mining_time = prototype.mineable_properties.mining_time,
                        output = prototype.mineable_properties.products,
                        selection_box = selection_box
                    })
                end
            else
                local name = entity.name

                meta_data.resources[name] =
                    meta_data.resources[name] or {}
                table.insert(meta_data.resources[name], {
                    mining_time = prototype.mineable_properties.mining_time,
                    output = prototype.mineable_properties.products,
                    selection_box = selection_box,
                    amount = entity.amount
                })
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Items
    ---------------------------------------------------------------------------
    for _, item in pairs(game.item_prototypes) do
        local item_data = {
            name = item.name,
            stack_size = item.stack_size,
            type = item.type,
            group = item.group.name,
            subgroup = item.subgroup.name
        }

        -- Check if the item can be placed in the world
        if item.place_result then
            local entity = item.place_result
            item_data.place_result = entity.name
            item_data.selection_box = entity.selection_box
            item_data.collision_box = entity.collision_box
            item_data.tile_width = entity.tile_width
            item_data.tile_height = entity.tile_height
        end

        table.insert(meta_data.items, item_data)
    end

    ---------------------------------------------------------------------------
    -- Recipes
    ---------------------------------------------------------------------------
    for _, recipe in pairs(force.recipes) do
        local ingredients = {}
        for _, ingredient in pairs(recipe.ingredients) do
            table.insert(ingredients,
                         {name = ingredient.name, amount = ingredient.amount})
        end

        local results = {}
        for _, product in pairs(recipe.products) do
            table.insert(results, {
                name = product.name,
                amount = product.amount,
                probability = product.probability or 1
            })
        end

        table.insert(meta_data.recipes, {
            name = recipe.name,
            category = recipe.category,
            enabled = recipe.enabled,
            energy = recipe.energy,
            ingredients = ingredients,
            results = results,
            group = recipe.group.name,
            subgroup = recipe.subgroup.name
        })
    end

    ---------------------------------------------------------------------------
    -- Technologies
    ---------------------------------------------------------------------------
    for _, technology in pairs(force.technologies) do
        local prerequisites = {}
        for _, prerequisite in pairs(technology.prerequisites) do
            table.insert(prerequisites, prerequisite.name)
        end

        local ingredients = {}
        for _, ingredient in pairs(technology.research_unit_ingredients) do
            table.insert(ingredients,
                         {name = ingredient.name, amount = ingredient.amount})
        end

        local effects = {}
        for _, effect in pairs(technology.effects) do
            table.insert(effects, {
                type = effect.type,
                recipe = effect.recipe,
                modifier = effect.modifier
            })
        end

        table.insert(meta_data.technologies, {
            name = technology.name,
            researched = technology.researched,
            enabled = technology.enabled,
            level = technology.level,
            prerequisites = prerequisites,
            research_unit_count = technology.research_unit_count,
            research_unit_energy = technology.research_unit_energy,
            ingredients = ingredients,
            effects = effects
        })
    end

    return json.encode(meta_data)
end

return meta_data
