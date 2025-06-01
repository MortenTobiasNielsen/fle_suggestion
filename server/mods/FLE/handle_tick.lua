local walk = require("walk")

local handle_tick = {}

function handle_tick.update(character_index)

    local steps = global.fle.characters[character_index].steps

    handle_pretick(character_index, steps)

    local step = steps[global.fle.characters[character_index].step_number]
    if step == nil then
        global.fle.characters[character_index].done = true
        return -- no more steps to handle
    end

    handle_ontick(character_index, step)
end

local function change_step()
    global.fle.characters[global.tas.character_index].step_number = global.fle
                                                                        .characters[global.tas
                                                                        .character_index]
                                                                        .step_number +
                                                                        1
end

local function handle_pretick(character_index, steps)
    while true do
        local step = steps[global.fle.characters[character_index].step_number]

        if step == nil then
            return -- no more steps to handle
        elseif (step[1] == "walk" and
            (global.fle.characters[character_index].walking.walking == false or
                global.fle.characters[character_index].walk_towards) and
            global.fle.characters[character_index].idle < 1) then

            update_walking(character_index, step)
        else
            return -- no more to do, break loop
        end
    end
end

local function handle_ontick(character_index, step)
    local action = step[1]

    if global.fle.characters[character_index].walking.walking == false then
        if global.fle.characters[character_index].idle > 0 then
            global.fle.characters[character_index].idle =
                global.fle.characters[character_index].idle - 1
            global.fle.characters[character_index].idled =
                global.fle.characters[character_index].idled + 1

            if global.fle.characters[character_index].idle == 0 then
                global.fle.characters[character_index].idled = 0

                if action == "walk" then
                    update_walking(character_index, step)
                end
            end
        elseif action == "walk" then
            update_walking(character_index, step)

        elseif action == "mine" then
            update_mining(character_index, step)

            -- elseif doStep(steps[global.tas.step]) then
            --     change_step()
        end
    else
        if global.walk_towards_state and action == "mine" then
            update_mining(character_index, step)

        elseif action ~= "walk" and action ~= "idle" and action ~= "mine" then
            -- if doStep(steps[global.tas.step]) then
            --     change_step()
            -- end
        end
    end
end

local function update_walking(character_index, step)
    walk.update_destination_position(character_index, step[2])
    walk.find_walking_pattern(character_index)

    global.fle.characters[character_index].walk_towards = step.walk_towards
    global.fle.characters[character_index].walking =
        walk.update(character_index)
    change_step()
end

local function update_mining(character_index, step)
    global.fle.characters[character_index].update_selected_entity(step[2])

    global.fle.characters[character_index].mining_state = {
        mining = true,
        position = step[2]
    }

    global.fle.characters[character_index].duration = step[3]
    global.fle.characters[character_index].ticks_mining =
        global.fle.characters[character_index].ticks_mining + 1

    if global.fle.characters[character_index].ticks_mining >=
        global.fle.characters[character_index].duration then
        change_step()
        global.fle.characters[character_index].mining = 0
        global.fle.characters[character_index].ticks_mining = 0
    end

    global.fle.characters[character_index].mining =
        global.fle.characters[character_index].mining + 1
    if global.fle.characters[character_index].mining > 5 then
        if global.fle.characters[character_index].character_mining_progress == 0 then
            rcon.print(string.format(
                           "Step: %s, Action: %s: Cannot reach resource",
                           current_step_number, action))
        else
            global.fle.characters[character_index].mining = 0
        end
    end
end

return handle_tick
