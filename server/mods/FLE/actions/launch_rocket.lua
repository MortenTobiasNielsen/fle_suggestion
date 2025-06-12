local fle_utils = require("fle_utils")

function launch_rocket(character, character_config, position)
    if not fle_utils.check_selection_reach(character, character_config, position) then
        return false
    end

    return character.selected.launch_rocket()
end

return launch_rocket
