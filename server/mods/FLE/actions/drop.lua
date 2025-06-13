function drop(character, character_config, position, item_name)
    local can_reach = 10 >
                          math.sqrt(
                              math.abs(character.position.x - position.x) ^ 2 +
                                  math.abs(character.position.y - position.y) ^
                                  2)
    if character.get_item_count(item_name) > 0 and can_reach then
        character.surface.create_entity {
            name = "item-on-ground",
            stack = {name = item_name, count = 1},
            position = position,
            force = character.force,
            spill = true
        }
        character.remove_item({name = item_name})
        return true
    end

    if character_config.walking_state.walking == false then
        -- Meaningful error message
    end

    return false
end
