local fle_utils = require("fle_utils")

function rotate(character, character_config, target_position, reverse)
    local has_rotated = false
    if not fle_utils.check_selection_reach(character, character_config,
                                           target_position) then
        return false;
    end

    if reverse then
        has_rotated = character.selected.rotate({reverse = true})
    else
        has_rotated = character.selected.rotate({reverse = false})
    end

    if has_rotated then
        global.fle.game_surface.play_sound {
            path = "utility/rotated_small",
            position = character.selected.position
        }
    end

    return true
end

return rotate
