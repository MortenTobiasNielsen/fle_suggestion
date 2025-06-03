local craft = {}

function craft.add(character, character_config, item, quantity)
	if not character.force.recipes[item].enabled then
		if(character_config.step_number > character_config.step_reached) then
			-- Warning(string.format("Step: %s, Action: %s, Step: %d - Craft: It is not possible to craft %s - It needs to be researched first.", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
            character_config.step_reached = character_config.step_number
		end

		return false;
	end

	if global.cancel and character.crafting_queue_size > 0 then
		character.cancel_crafting{ index = 1, count = 1000000}
		return false
	elseif global.wait_for_recipe and character.crafting_queue_size > 0 then
		-- Warning(string.format("Step: %s, Action: %s, Step: %d - Craft [item=%s]: It is not possible to craft as the queue is not empty", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
		character_config.step_reached = character_config.step_number
		return false
	else
		global.wait_for_recipe = nil
	end

	global.cancel = nil

	max_quantity = character.get_craftable_count(item)

	if max_quantity > 0 then
		if quantity == -1 then
			character.begin_crafting{count = max_quantity, recipe = item}
		elseif quantity <= max_quantity then
			character.begin_crafting{count = quantity, recipe = item}
		else
			if not character_config.walking.walking then
				-- Warning(string.format("Step: %s, Action: %s, Step: %d - Craft: It is not possible to craft %s - Only possible to craft %d of %d", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper), max_quantity, quantity))
			end

			return false
		end
		-- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Craft: [item=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, item ))
		return true
    else
        if(character_config.step_number > character_config.step_reached) then
            -- Warning(string.format("Step: %s, Action: %s, Step: %d - Craft: It is not possible to craft %s - Please check the script", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
            character_config.step_reached = character_config.step_number
		end

        return false
	end
end

function craft.cancel(character, character_config, item, quantity)
	local queue = character.crafting_queue

	for i = 1, #queue do
		if queue[i].recipe == item then
			if quantity == -1 then
				character.cancel_crafting{index = i, count = 1000000}
				-- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Cancel: [item=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, item ))
				return true
			elseif queue[i].count >= quantity then
				character.cancel_crafting{index = i, count = quantity}
				-- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Cancel: [item=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, item ))
				return true
			else
				-- Warning(string.format("Step: %s, Action: %s, Step: %d - Cancel craft: It is not possible to cancel %s - Please check the script", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
				return false
			end
		end
	end
	-- Warning(string.format("Step: %s, Action: %s, Step: %d - Cancel craft: It is not possible to cancel %s - Please check the script", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
	return false
end

return craft