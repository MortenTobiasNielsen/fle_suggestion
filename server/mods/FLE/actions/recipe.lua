local fle_utils = require("fle_utils")

function recipe(character, character_config, target_position, item)
	if not fle_utils.check_selection_reach(character, character_config, target_position) then
		return false
	end

	if item ~= "none" and not character.force.recipes[item].enabled then
		if(character_config.step_number > character_config.step_reached) then
			-- Meaningful error message
            character_config.step_reached = character_config.step_number
		end

		return false;
	end

	if character.selected.crafting_progress ~= 0 then
		-- Meaningful error message
		character_config.step_reached = character_config.step_number
		return false
	end

	global.wait_for_recipe = nil

	local items_returned = character.selected.set_recipe(item ~= "none" and item or nil)

	for name, count_ in pairs (items_returned) do
		character.insert{name = name, count = count_}
	end

	global.fle.game_surface.play_sound { path = "utility/entity_settings_pasted", position = target_position }
	return true
end

return recipe