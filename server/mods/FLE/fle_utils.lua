local util = require("util")

local fle_utils = {}

function fle_utils.inventory_stats(inv)
    if not inv then return nil end
    local slots = #inv
    local empty = inv.count_empty_stacks()
    local items = inv.get_contents()
    return {slots = slots, empty = empty, items = items}
end

function fle_utils.floor(x, d)
    local p = 10 ^ d
    return math.floor(x * p) / p
end

function fle_utils.ceil(x, d)
    local power = 10 ^ d
    return math.ceil(x * power) / power
end

function fle_utils.check_selection_reach(character, character_config,
                                         target_position)
    character.update_selected_entity(target_position)

    if not character.selected then
        if not character_config.walking.walking then
            -- Warning(string.format(
            --             "Step: %s, Action: %s, Step: %d - %s: Cannot select entity",
            --             global.tas.task[1], global.tas.task[2], global.tas.step,
            --             global.tas.task_category))
        end

        return false
    end

    if not character.can_reach_entity(character.selected) then
        if not character_config.walking.walking then
            -- Warning(string.format(
            --             "Step: %s, Action: %s, Step: %d - %s: Cannot reach entity",
            --             global.tas.task[1], global.tas.task[2], global.tas.step,
            --             global.tas.task_category))
        end

        return false
    end

    return true
end

-- Check that it is possible to get the inventory of the entity
function fle_utils.check_inventory(character, character_config, inventory_type)
    character_config.target_inventory = character.selected.get_inventory(
                                            inventory_type) or
                                            character.selected.get_inventory(1)

    if not character_config.target_inventory then
        if not character_config.walking.walking then
            -- Warning(string.format(
            --             "Step: %s, Action: %s, Step: %d - %s: Cannot get entity inventory",
            --             global.tas.task[1], global.tas.task[2], global.tas.step,
            --             global.tas.task_category))
        end

        return false
    end

    return true
end

function fle_utils.to_position(position)
    if not position then return nil end
    return {x = position[1], y = position[2]}
end

function fle_utils.format_name(str)
	return str:gsub("^%l", string.upper):gsub("-", " ") --uppercase first letter and replace dashes with spaces
end

function fle_utils.item_is_tile(item)
	if item == "stone-brick"
	or item == "concrete"
    or item == "hazard-concrete"
    or item == "refined-concrete"
    or item == "refined-hazard-concrete"
    or item == "landfill" then
        return true
    end
    return false
end

function fle_utils.is_within_range(character, target_position)
  return character.build_distance >= util.distance(character.position, target_position)
end

return fle_utils
