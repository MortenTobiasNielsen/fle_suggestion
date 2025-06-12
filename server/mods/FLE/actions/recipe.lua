local fle_utils = require("fle_utils")

function recipe(character, character_config, target_position, item_name)
    if not fle_utils.check_selection_reach(character, character_config,
                                           target_position) then return false end

    if item_name ~= "none" and not character.force.recipes[item_name].enabled then
        if (character_config.action_number > character_config.action_reached) then
            -- Meaningful error message
            character_config.action_reached = character_config.action_number
        end

        return false;
    end

    if character.selected.crafting_progress ~= 0 then
        -- Meaningful error message
        character_config.action_reached = character_config.action_number
        return false
    end

    global.wait_for_recipe = nil

    local items_returned = character.selected.set_recipe(
                               item_name ~= "none" and item_name or nil)

    for name, count_ in pairs(items_returned) do
        character.insert {name = name, count = count_}
    end

    global.fle.game_surface.play_sound {
        path = "utility/entity_settings_pasted",
        position = target_position
    }
    return true
end

return recipe
