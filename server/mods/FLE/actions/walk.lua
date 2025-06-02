local walk = {}

function walk.update_destination_position(character_config, destination)
    local last_destination = character_config.destination
    local diff_x = destination.x - last_destination.x
    local diff_y = destination.y - last_destination.y

    character_config.keep_x = false
    character_config.keep_y = false
    character_config.diagonal = false

    if math.abs(destination.x - last_destination.x) == math.abs(destination.y - last_destination.y) then
        character_config.diagonal = true
    elseif diff_x == 0 then
        character_config.keep_x = true
    elseif diff_y == 0 then
        character_config.keep_y = true
    end

    character_config.destination = destination
end

function walk.find_walking_pattern(character, character_config)
    character_config.pos_pos = false
    character_config.pos_neg = false
    character_config.neg_pos = false
    character_config.neg_neg = false

    character_position = character.position
    destination = character_config.destination

    if (character_position.x - destination.x >= 0) then
        if (character_position.y - destination.y >= 0) then
            character_config.pos_pos = true
        else
            character_config.pos_neg = true
        end
    else
        if (character_position.y - destination.y >= 0) then
            character_config.neg_pos = true
        else
            character_config.neg_neg = true
        end
    end
end

local function walk_pos_pos(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    if keep_x then
        if character_position.y > destination.y then
            return {walking = true, direction = defines.direction.north}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if keep_y then
        if character_position.x > destination.x then
            return {walking = true, direction = defines.direction.west}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if diagonal then
        if character_position.x > destination.x or character_position.y >
            destination.y then
            return {walking = true, direction = defines.direction.northwest}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if character_position.x > destination.x then
        if character_position.y > destination.y then
            return {walking = true, direction = defines.direction.northwest}
        else
            return {walking = true, direction = defines.direction.west}
        end
    else
        if character_position.y > destination.y then
            return {walking = true, direction = defines.direction.north}
        else
            return {walking = false, direction = current_direction}
        end
    end
end

local function walk_pos_neg(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    if keep_x then
        if character_position.y < destination.y then
            return {walking = true, direction = defines.direction.south}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if keep_y then
        if character_position.x > destination.x then
            return {walking = true, direction = defines.direction.west}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if diagonal then
        if character_position.x > destination.x or character_position.y <
            destination.y then
            return {walking = true, direction = defines.direction.southwest}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if character_position.x > destination.x then
        if character_position.y < destination.y then
            return {walking = true, direction = defines.direction.southwest}
        else
            return {walking = true, direction = defines.direction.west}
        end
    else
        if character_position.y < destination.y then
            return {walking = true, direction = defines.direction.south}
        else
            return {walking = false, direction = current_direction}
        end
    end
end

local function walk_neg_pos(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    if keep_x then
        if character_position.y > destination.y then
            return {walking = true, direction = defines.direction.north}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if keep_y then
        if character_position.x < destination.x then
            return {walking = true, direction = defines.direction.east}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if diagonal then
        if character_position.x < destination.x or character_position.y >
            destination.y then
            return {walking = true, direction = defines.direction.northeast}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if character_position.x < destination.x then
        if character_position.y > destination.y then
            return {walking = true, direction = defines.direction.northeast}
        else
            return {walking = true, direction = defines.direction.east}
        end
    else
        if character_position.y > destination.y then
            return {walking = true, direction = defines.direction.north}
        else
            return {walking = false, direction = current_direction}
        end
    end
end

local function walk_neg_neg(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    if keep_x then
        if character_position.y < destination.y then
            return {walking = true, direction = defines.direction.south}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if keep_y then
        if character_position.x < destination.x then
            return {walking = true, direction = defines.direction.east}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if diagonal then
        if character_position.x < destination.x or character_position.y <
            destination.y then
            return {walking = true, direction = defines.direction.southeast}
        else
            return {walking = false, direction = current_direction}
        end
    end

    if character_position.x < destination.x then
        if character_position.y < destination.y then
            return {walking = true, direction = defines.direction.southeast}
        else
            return {walking = true, direction = defines.direction.east}
        end
    else
        if character_position.y < destination.y then
            return {walking = true, direction = defines.direction.south}
        else
            return {walking = false, direction = current_direction}
        end
    end
end

function walk.update(character, character_config)
    local keep_x = character_config.keep_x
    local keep_y = character_config.keep_y
    local diagonal = character_config.diagonal
    local character_position = character.position
    local destination = character_config.destination
    local current_direction = character_config.walking.direction

    if character_config.character_index == 1 then
        game.print(string.format(
                       "Character %d: Position: (%.2f, %.2f), Destination: (%.2f, %.2f), Keep X: %s, Keep Y: %s, Diagonal: %s",
                       character_config.character_index, character_position.x,
                       character_position.y, destination.x, destination.y,
                       tostring(keep_x), tostring(keep_y), tostring(diagonal)))
    end

    if character_config.pos_pos then
        return walk_pos_pos(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    elseif character_config.pos_neg then
        return walk_pos_neg(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    elseif character_config.neg_pos then
        return walk_neg_pos(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    elseif character_config.neg_neg then
        return walk_neg_neg(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    end

    return {walking = false, direction = current_direction}
end

return walk
