local fle_utils = require("fle_utils")

function recipe(character, character_config, target_position, item)

	if not fle_utils.check_selection_reach(character, character_config, target_position) then
		return false
	end

	if item ~= "none" and not character.force.recipes[item].enabled then
		if(character_config.step_number > character_config.step_reached) then
			-- Warning(string.format("Step: %s, Action: %s, Step: %d - Recipe: It is not possible to set recipe %s - It needs to be researched first.", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
            character_config.step_reached = character_config.step_number
		end

		return false;
	end

	if character.selected.crafting_progress ~= 0 then
		-- Warning(string.format("Step: %s, Action: %s, Step: %d - Set recipe %s: The entity is still crafting.", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
		character_config.step_reached = character_config.step_number
		return false
	end

	global.wait_for_recipe = nil

	local items_returned = character.selected.set_recipe(item ~= "none" and item or nil)

	for name, count_ in pairs (items_returned) do
		character.insert{name = name, count = count_}
	end

	global.fle.game_surface.play_sound { path = "utility/entity_settings_pasted", position = target_position }
	-- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Recipe: [recipe=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, item ))
	return true
end

return recipe