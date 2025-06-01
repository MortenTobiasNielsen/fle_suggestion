local walk = {}

function walk.update_destination_position(character_index, destination)
    local last_destination = global.fle.characters[character_index].destination
    local diff_x = destination.x - last_destination.x
    local diff_y = destination.y - last_destination.y

    global.fle.characters[character_index].keep_x = false
    global.fle.characters[character_index].keep_y = false
    global.fle.characters[character_index].diagonal = false

    if diff_x == 0 and diff_y == 0 then
        global.fle.characters[character_index].diagonal = true
    elseif diff_x == 0 then
        global.fle.characters[character_index].keep_x = true
    elseif diff_y == 0 then
        global.fle.characters[character_index].keep_y = true
    end

    global.fle.characters[character_index].destination = destination
end

function walk.find_walking_pattern(character_index)
    global.fle.characters[character_index].pos_pos = false
    global.fle.characters[character_index].pos_neg = false
    global.fle.characters[character_index].neg_pos = false
    global.fle.characters[character_index].neg_neg = false

    character_position = global.fle.characters[character_index].position
    destination = global.fle.characters[character_index].destination

    if (character_position.x - destination.x >= 0) then
        if (character_position.y - destination.y >= 0) then
            global.fle.characters[character_index].pos_pos = true
        else
            global.fle.characters[character_index].pos_neg = true
        end
    else
        if (character_position.y - destination.y >= 0) then
            global.fle.characters[character_index].neg_pos = true
        else
            global.fle.characters[character_index].neg_neg = true
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

function walk.update(character_index)
    local keep_x = global.fle.characters[character_index].keep_x
    local keep_y = global.fle.characters[character_index].keep_y
    local diagonal = global.fle.characters[character_index].diagonal
    local character_position = global.fle.characters[character_index].position
    local destination = global.fle.characters[character_index].destination
    local current_direction = global.fle.characters[character_index].walking
                                  .direction

    if global.fle.characters[character_index].pos_pos then
        return walk_pos_pos(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    elseif global.fle.characters[character_index].pos_neg then
        return walk_pos_neg(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    elseif global.fle.characters[character_index].neg_pos then
        return walk_neg_pos(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    elseif global.fle.characters[character_index].neg_neg then
        return walk_neg_neg(keep_x, keep_y, diagonal, character_position,
                            destination, current_direction)
    end
end

return walk
