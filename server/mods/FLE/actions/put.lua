local fle_utils = require("fle_utils")

function put(character, character_config, target_position, item, quantity,
             inventory_type)

    if not fle_utils.check_selection_reach(character, character_config,
                                           target_position) then
        return false;
    end

    if not fle_utils.check_inventory(character, character_config, inventory_type) then
        return false;
    end

    local removalable_items = character.get_item_count(item)
    local insertable_items = character_config.target_inventory
                                 .get_insertable_count(item)
    if quantity < 1 then
        quantity = math.min(removalable_items, insertable_items)
    end

    if removalable_items == 0 then
        if not character_config.walking.walking then
            -- Warning(string.format(
            --             "Step: %s, Action: %s, Step: %d - Put: %s is not available in your inventory",
            --             global.tas.task[1], global.tas.task[2], global.tas.step,
            --             item:gsub("-", " "):gsub("^%l", string.upper)))
        end

        return false;
    end

    if insertable_items == 0 then
        if not character_config.walking.walking then
            -- Warning(string.format(
            --             "Step: %s, Action: %s, Step: %d - Put: %s can't be put into target inventory",
            --             global.tas.task[1], global.tas.task[2], global.tas.step,
            --             item:gsub("-", " "):gsub("^%l", string.upper)))
        end

        return false;
    end

    if quantity > removalable_items or quantity > insertable_items then
        if not character_config.walking.walking then
            -- Warning(string.format(
            --             "Step: %s, Action: %s, Step: %d - Put: not enough %s can be transferred. Amount: %d Removalable: %d Insertable: %d",
            --             global.tas.task[1], global.tas.task[2], global.tas.step,
            --             item:gsub("-", " "):gsub("^%l", string.upper), quantity,
            --             removalable_items, insertable_items))
        end

        return false
    end

    local moved = 0
    while quantity > moved do
        local item_stack = character.get_main_inventory().find_item_stack(item)
        if not item_stack then
            Error("Item stack " .. item .. " not found for put")
            return false
        end
        local health = item_stack.health
        local durability = item_stack.is_tool and item_stack.durability or 1
        local ammo = item_stack.is_ammo and item_stack.ammo or 10
        local stack_count = item_stack.count

        local remaining = quantity - moved

        stack_count = stack_count < remaining and stack_count or remaining

        if stack_count ~= character_config.target_inventory.insert {
            name = item,
            durability = durability,
            health = health,
            ammo = ammo,
            count = character.remove_item {
                name = item,
                count = stack_count,
                durability = durability,
                health = health,
                ammo = ammo
            }
        } then
            if not character_config.walking.walking then
                -- Warning(string.format(
                --             "Step: %s, Action: %s, Step: %d - Put: %s can not be transferred. Amount: %d Removalable: %d Insertable: %d",
                --             global.tas.task[1], global.tas.task[2], global.tas.step,
                --             item:gsub("-", " "):gsub("^%l", string.upper), quantity,
                --             removalable_items, insertable_items))
            end
            return false
        end

        moved = moved + stack_count
    end

    global.fle.game_surface.play_sound {
        path = "utility/inventory_move",
        position = character.position
    }
    local player = character.player
    if player then
        local text = string.format("-%d %s (%d)", quantity, format_name(item),
                                   character.get_item_count(item)) -- "-2 Iron plate (5)"
        local pos = {
            x = character_config.target_inventory.entity_owner.position.x +
                #text / 2 * global.font_size,
            y = character_config.target_inventory.entity_owner.position.y
        }
        player.create_local_flying_text {text = text, position = pos}
    end

    return true
end

return put
