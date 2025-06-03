local fle_utils = require("fle_utils")

local function create_entity_replace(character, character_config,
                                     target_position, item, direction)

    local stack, stack_location = character.get_inventory(1).find_item_stack(
                                      item)
    if not stack or not stack.valid then
        Error("Trying to create an entity of " .. item ..
                  " but couldn't find a stack of them in characters inventory")
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
        name = item,
        position = target_position,
        direction = direction,
        force = "player",
        fast_replace = true,
        character = character,
        raise_built = true,
        item = stack
    }

    if created_entity and fast_replace_type_lookup[created_entity.name] ~= nil and
        created_entity.neighbours then -- connected entities eg underground belt https://lua-api.factorio.com/latest/LuaEntity.html#LuaEntity.neighbours
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
            character.remove_item({name = item, count = 1})
            -- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Build: [item=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, global.tas.item ))
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
        -- spend the item placed
        character.remove_item({name = item, count = 1})
        -- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Build: [item=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, global.tas.item ))
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

        -- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Build: [item=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, global.tas.item ))
        character.remove_item({name = item, count = 1})
    end

    return created_entity ~= nil
end

function build(character, character_config, target_position, item, direction)
    local is_curved_rail = item == "curved_rail"
    local count = character.get_item_count(item)

    if count < 1 then
        if (character_config.step_number > character_config.step_reached) then
            if character_config.walking.walking == false then
                Warning(string.format(
                            "Step_number: %d - Build: %s not available",
                            character_config.step_number,
                            fle_utils.format_name(item)))
                character_config.step_reached = character_config.step_number
            end
        end

        return false
    end

    if (item ~= "rail") then
        if fle_utils.item_is_tile(item) then
            if fle_utils.is_within_range() then
                if item == "stone-brick" then
                    global.fle.game_surface.set_tiles({
                        {position = target_position, name = "stone-path"}
                    })
                elseif (item == "hazard-concrete") or
                    (item == "refined-hazard-concrete") then
                    global.fle.game_surface.set_tiles({
                        {position = target_position, name = item .. "-left"}
                    })
                else
                    global.fle.game_surface.set_tiles({
                        {position = target_position, name = item}
                    })
                end

                if (item == "landfill") then
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

                character.remove_item({name = item, count = 1})
                -- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Build: [item=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, item ))
                return true

            elseif not character_config.walking.walking then
                -- Warning(string.format("Step: %s, Action: %s, Step: %d - Build: %s not in reach", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
            end

            return false

        elseif fle_utils.is_within_range(character, target_position) and
            (global.fle.game_surface.can_place_entity {
                name = item,
                position = target_position,
                direction = direction,
                build_check_type = defines.build_check_type.script_ghost,
                forced = true
            } or global.fle.game_surface.can_fast_replace{
                name = item,
                position = target_position,
                direction = direction,
                force = character.force
            }) then
            -- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Build: [item=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, item ))
            return create_entity_replace(character, character_config,
                                         target_position, item, direction)
        else
            if not character_config.walking.walking then
                -- Warning(string.format("Step: %s, Action: %s, Step: %d - Build: %s cannot be placed", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
            end

            return false
        end
    else

        if fle_utils.is_within_range(character, target_position) and
            global.fle.game_surface.can_place_entity {
                name = item,
                position = target_position,
                direction = direction
            } then

            if global.fle.game_surface.create_entity {
                name = item,
                position = target_position,
                direction = direction,
                force = "player",
                raise_built = true
            } then
                character.remove_item({name = item, count = 1})
                -- end_warning_mode(string.format("Step: %s, Action: %s, Step: %d - Build: [item=%s]", global.tas.task[1], global.tas.task[2], global.tas.step, item ))
                return true
            end

        else
            if not character_config.walking.walking then
                -- Warning(string.format("Step: %s, Action: %s, Step: %d - Build: %s cannot be placed", global.tas.task[1], global.tas.task[2], global.tas.step, item:gsub("-", " "):gsub("^%l", string.upper)))
            end

            return false
        end
    end
end

return build
