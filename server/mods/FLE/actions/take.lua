local fle_utils = require("fle_utils")

function take(character, character_config, target_position, item_name, quantity,
              inventory_type)

    local can_reach = fle_utils.check_selection_reach(character,
                                                      character_config,
                                                      target_position)

    if not can_reach then return false end

    if not fle_utils.check_inventory(character, character_config, inventory_type) then
        return false;
    end

    local removalable_items = character_config.target_inventory.get_item_count(
                                  item_name)
    local insertable_items = character.get_main_inventory()
                                 .get_insertable_count(item_name)

    if removalable_items == 0 then
        if not character_config.walking_state.walking then
            -- Meaningful error message
        end

        return false;
    end

    if insertable_items == 0 then
        if not character_config.walking_state.walking then
            -- Meaningful error message
        end

        return false;
    end

    if quantity < 1 then
        quantity = math.min(removalable_items, insertable_items)
    end

    if quantity > removalable_items or quantity > insertable_items then
        if not character_config.walking_state.walking then
            -- Meaningful error message
        end

        return false
    end

    local moved = 0
    while quantity > moved do
        local item_stack = character_config.target_inventory.find_item_stack(
                               item_name)
        if not item_stack then
            -- Meaningful error message
            return false
        end
        local health = item_stack.health
        local durability = item_stack.is_tool and item_stack.durability or 1
        local ammo = item_stack.is_ammo and item_stack.ammo or 10
        local stack_count = item_stack.count

        local remaining = quantity - moved

        stack_count = stack_count < remaining and stack_count or remaining

        if stack_count ~= character.insert {
            name = item_name,
            durability = durability,
            health = health,
            ammo = ammo,
            count = character_config.target_inventory.remove {
                name = item_name,
                count = stack_count,
                durability = durability,
                health = health,
                ammo = ammo
            }
        } then
            -- Meaningful error message
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
                                   fle_utils.format_name(item_name),
                                   character.get_item_count(item_name)) -- "+2 Iron plate (5)"
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
