local util = require("util")

local fle_utils = {}

function fle_utils.inventory_stats(inv)
    if not inv or #inv == 0 then return nil end
    local slots = #inv
    local empty = inv.count_empty_stacks()
    local items = inv.get_contents()
    
    if empty == slots or not items or not next(items) then
        items = {}
        setmetatable(items, {__jsontype = "object"})
    end
    
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
        if not character_config.walking_state.walking then
            -- Meaningful error message
        end

        return false
    end

    if not character.can_reach_entity(character.selected) then
        if not character_config.walking_state.walking then
            -- Meaningful error message
        end

        return false
    end

    return true
end

function fle_utils.check_inventory(character, character_config, inventory_type)
    character_config.target_inventory = character.selected.get_inventory(
                                            inventory_type) or
                                            character.selected.get_inventory(1)

    if not character_config.target_inventory then
        if not character_config.walking_state.walking then
            -- Meaningful error message
        end

        return false
    end

    return true
end

function fle_utils.format_name(str)
    return str:gsub("^%l", string.upper):gsub("-", " ")
end

function fle_utils.item_is_tile(item)
    if item == "stone-brick" or item == "concrete" or item == "hazard-concrete" or
        item == "refined-concrete" or item == "refined-hazard-concrete" or item ==
        "landfill" then return true end
    return false
end

function fle_utils.is_within_range(character, target_position)
    local within_distance = character.build_distance +5 >= util.distance(character.position, target_position)
    if not within_distance then
        return false
    end

    return true
end

return fle_utils
