local fle_utils = require("fle_utils")

local function create_entity_replace(character, character_config,
                                     target_position, item_name, direction)

    local stack, stack_location = character.get_inventory(1).find_item_stack(
                                      item_name)
    if not stack or not stack.valid then
        -- Meaningful error message
        return false
    end

    local fast_replace_type_lookup = {
        ["underground-belt"] = {
            "transport-belt", "fast-transport-belt", "express-transport-belt"
        },
        ["fast-underground-belt"] = {
            "transport-belt", "fast-transport-belt", "express-transport-belt"
        },
        ["express-underground-belt"] = {
            "transport-belt", "fast-transport-belt", "express-transport-belt"
        },
        ["pipe-to-ground"] = {"pipe"}
    }

    local created_entity = global.fle.game_surface.create_entity {
        name = item_name,
        position = target_position,
        direction = direction,
        force = "player",
        fast_replace = true,
        character = character,
        raise_built = true,
        item = stack
    }

    if created_entity and fast_replace_type_lookup[created_entity.name] ~= nil and
        created_entity.neighbours then
        created_entity.create_build_effect_smoke()
        created_entity.surface.play_sound {
            path = "entity-build/" .. created_entity.prototype.name,
            position = created_entity.position
        }

        created_entity.health = stack.health * created_entity.health

        local replace_type = fast_replace_type_lookup[created_entity.name]
        local neighbour_position = nil
        if (#created_entity.neighbours == 0) then
            neighbour_position = created_entity.neighbours.position
        else
            for _, neighbour in pairs(created_entity.neighbours[1]) do
                if (created_entity.name == neighbour.name) then
                    neighbour_position = neighbour.position
                end
            end
        end

        if (not neighbour_position) then
            character.remove_item({name = item_name, count = 1})
            return true
        end

        local entities_between =
            global.fle.game_surface.find_entities_filtered {
                name = replace_type,
                area = {
                    {
                        x = math.min(created_entity.position.x,
                                     neighbour_position.x),
                        y = math.min(created_entity.position.y,
                                     neighbour_position.y)
                    }, {
                        x = math.max(created_entity.position.x,
                                     neighbour_position.x),
                        y = math.max(created_entity.position.y,
                                     neighbour_position.y)
                    }
                }
            }

        local entities_between_length = math.abs(
                                            created_entity.position.x -
                                                neighbour_position.x +
                                                created_entity.position.y -
                                                neighbour_position.y) - 1

        local can_replace_all = entities_between_length == #entities_between

        -- chech that all entities betweeen are in the same direction
        if can_replace_all and created_entity.name ~= "pipe-to-ground" then -- ignore direction for pipes
            for __, e in pairs(entities_between) do
                if e.direction ~= created_entity.direction then
                    can_replace_all = false
                    break
                end
            end
        elseif can_replace_all and created_entity.name == "pipe-to-ground" then
            for __, e in pairs(entities_between) do -- check all entities
                if e.neighbours and e.neighbours[1] then -- null check
                    for ___, n in pairs(e.neighbours[1]) do -- check all neighbours for each entity
                        for i = 1, #entities_between do -- make sure it exist every neighbour is only part of the set of entities between
                            if entities_between[i] == n then
                                can_replace_all = true
                                break -- break out when found
                            else
                                can_replace_all = false
                            end
                        end
                        if not can_replace_all then break end -- previous loop didn't find it
                    end
                end
                if not can_replace_all then break end -- break out
            end
        end

        -- mine all entities inbetween
        if can_replace_all then
            for __, e in pairs(entities_between) do
                character.mine_entity(e, true)
            end
        end

        character.remove_item({name = item_name, count = 1})
        return true
    end

    -- no special fast replace handling
    if created_entity then
        created_entity.create_build_effect_smoke()
        created_entity.surface.play_sound {
            path = "entity-build/" .. created_entity.prototype.name,
            position = created_entity.position
        }

        created_entity.health = stack.health * created_entity.health

        character.remove_item({name = item_name, count = 1})
    end

    return created_entity ~= nil
end

function build(character, character_config, target_position, item_name,
               direction)
    local is_curved_rail = item_name == "curved_rail"
    local count = character.get_item_count(item_name)

    if count < 1 then
        if (character_config.action_number > character_config.action_reached) then
            if character_config.walking_state.walking == false then
                -- Meaningful error message
                character_config.action_reached = character_config.action_number
            end
        end

        return false
    end

    if (item_name ~= "rail") then
        if fle_utils.item_is_tile(item_name) then
            if fle_utils.is_within_range() then
                if item_name == "stone-brick" then
                    global.fle.game_surface.set_tiles({
                        {position = target_position, name = "stone-path"}
                    })
                elseif (item_name == "hazard-concrete") or
                    (item_name == "refined-hazard-concrete") then
                    global.fle.game_surface.set_tiles({
                        {
                            position = target_position,
                            name = item_name .. "-left"
                        }
                    })
                else
                    global.fle.game_surface.set_tiles({
                        {position = target_position, name = item_name}
                    })
                end

                if (item_name == "landfill") then
                    global.fle.game_surface.play_sound {
                        path = "tile-build-small/landfill",
                        position = target_position
                    }
                else
                    global.fle.game_surface.play_sound {
                        path = "tile-build-small/concrete",
                        position = target_position
                    }
                end

                character.remove_item({name = item_name, count = 1})
                return true
            end

            return false

        elseif fle_utils.is_within_range(character, target_position) and
            (global.fle.game_surface.can_place_entity {
                name = item_name,
                position = target_position,
                direction = direction,
                build_check_type = defines.build_check_type.ghost_revive
            } or global.fle.game_surface.can_fast_replace {
                name = item_name,
                position = target_position,
                direction = direction,
                force = character.force
            }) then
            return create_entity_replace(character, character_config,
                                         target_position, item_name, direction)
        else
            return false
        end
    else

        if fle_utils.is_within_range(character, target_position) and
            global.fle.game_surface.can_place_entity {
                name = item_name,
                position = target_position,
                direction = direction
            } then

            if global.fle.game_surface.create_entity {
                name = item_name,
                position = target_position,
                direction = direction,
                force = "player",
                raise_built = true
            } then
                character.remove_item({name = item_name, count = 1})
                return true
            end

        else
            return false
        end
    end
end

return build
