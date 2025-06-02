local fle_utils = require("fle_utils")

local take = {}

function take.all(character, character_config, target_position, item,
                  inventory_type)

    if not fle_utils.check_selection_reach(character, character_config,
                                           target_position) then return false end

    if not fle_utils.check_inventory(character, character_config, inventory_type) then
        return false;
    end

    local contents = character_config.target_inventory.get_contents()
    for name, count in pairs(contents or character_config.target_inventory) do
        local item_stack = character_config.target_inventory.find_item_stack(
                               name)
        if not item_stack then
            Error("Item stack " .. item .. " not found for put")
            return false
        end

        local health = item_stack.health
        local durability = item_stack.is_tool and item_stack.durability or 1
        local ammo = item_stack.is_ammo and item_stack.ammo or 10

        local quantity = character.insert {
            name = name,
            health = health,
            durability = durability,
            ammo = ammo,
            count = character_config.target_inventory.remove {
                name = name,
                count = count,
                durability = durability
            }
        }

        local text = string.format("+%d %s (%d)", quantity,
                                   fle_utils.format_name(name),
                                   character.get_item_count(name)) -- "+2 Iron plate (5)"
        local position = {
            x = character_config.target_inventory.entity_owner.position.x +
                #text / 2 * global.font_size,
            y = character_config.target_inventory.entity_owner.position.y
        }
        global.tas.player.play_sound {path = "utility/inventory_move"}
        global.tas.player.create_local_flying_text {
            text = text,
            position = position
        }
    end

    return true
end

function take.quantity(character, character_config, target_position, item,
                       quantity, inventory_type)

    if not fle_utils.check_selection_reach(character, character_config,
                                           target_position) then return false end

    if not fle_utils.check_inventory(character, character_config, inventory_type) then
        return false;
    end

    local removalable_items = character_config.target_inventory.get_item_count(
                                  item)
    local insertable_items = character.get_main_inventory()
                                 .get_insertable_count(item)

    if removalable_items == 0 then
        if not character_config.walking.walking then
            -- Warning({
            --     "step-warning.take", global.tas.task[1], global.tas.task[2],
            --     global.tas.step, fle_utils.format_name(item),
            --     "is not available from the inventory"
            -- })
        end

        return false;
    end

    if insertable_items == 0 then
        if not character_config.walking.walking then
            -- Warning(string.format(
            --             "Step_number: %d - Take: %s can't be put into your inventory",
            --             character_config.step_number,
            --             fle_utils.format_name(item)))
        end

        return false;
    end

    if quantity < 1 then
        quantity = math.min(removalable_items, insertable_items)
    end

    if quantity > removalable_items or quantity > insertable_items then
        if not character_config.walking.walking then
            -- Warning(string.format(
            --             "Step_number: %d - Take: not enough %s can be transferred. Quantity: %d Removalable: %d Insertable: %d",
            --             character_config.step_number,
            --             fle_utils.format_name(item), quantity,
            --             removalable_items, insertable_items))
        end

        return false
    end

    local moved = 0
    while quantity > moved do
        local item_stack = character_config.target_inventory.find_item_stack(
                               item)
        if not item_stack then
            Error("Item stack " .. item .. " not found for take")
            return false
        end
        local health = item_stack.health
        local durability = item_stack.is_tool and item_stack.durability or 1
        local ammo = item_stack.is_ammo and item_stack.ammo or 10
        local stack_count = item_stack.count

        local remaining = quantity - moved

        stack_count = stack_count < remaining and stack_count or remaining

        if stack_count ~= character.insert {
            name = item,
            durability = durability,
            health = health,
            ammo = ammo,
            count = character_config.target_inventory.remove {
                name = item,
                count = stack_count,
                durability = durability,
                health = health,
                ammo = ammo
            }
        } then
            Error(string.format(
                      "Step_number: %d - Take: %s can not be transferred. Quantity: %d Removalable: %d Insertable: %d",
                      character_config.step_number, fle_utils.format_name(item),
                      quantity, removalable_items, insertable_items))
            return false
        end

        moved = moved + stack_count
    end

    global.fle.game_surface.play_sound {
        path = "utility/inventory_move",
        position = target_position
    }

    local player = character.player
    if player then
        local text = string.format("+%d %s (%d)", quantity,
                                   fle_utils.format_name(item),
                                   character.get_item_count(item)) -- "+2 Iron plate (5)"
        local pos = {
            x = character_config.target_inventory.entity_owner.position.x +
                #text / 2 * global.font_size,
            y = character_config.target_inventory.entity_owner.position.y
        }
        player.create_local_flying_text {text = text, position = pos}
    end

    return true
end

return take
