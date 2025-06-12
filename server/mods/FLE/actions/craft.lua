local craft = {}

function craft.add(character, character_config, item, quantity)
	if not character.force.recipes[item].enabled then
		if(character_config.step_number > character_config.step_reached) then
			-- Meaningful error message
            character_config.step_reached = character_config.step_number
		end

		return false;
	end

	max_quantity = character.get_craftable_count(item)

	if max_quantity > 0 then
		if quantity == -1 then
			character.begin_crafting{count = max_quantity, recipe = item}
			return true
			
		elseif quantity <= max_quantity then
			character.begin_crafting{count = quantity, recipe = item}
			return true

		else
			if not character_config.walking.walking then
				-- Meaningful error message
			end

			return false
		end
    else
        if(character_config.step_number > character_config.step_reached) then
            -- Meaningful error message
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
				return true

			elseif queue[i].count >= quantity then
				character.cancel_crafting{index = i, count = quantity}
				return true
				
			else
				-- Meaningful error message
				return false
			end
		end
	end
	-- Meaningful error message
	return false
end

return craft