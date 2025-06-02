local walk = require("actions.walk")
local take = require("actions.take")
local build = require("actions.build")
local put = require("actions.put")
local fle_utils = require("fle_utils")

local handle_tick = {}

local function change_step(character_config)
    character_config.step_number = character_config.step_number + 1
end

local function update_walking(character, character_config, step)
    local destination = fle_utils.to_position(step[2])

    walk.update_destination_position(character_config, destination)
    walk.find_walking_pattern(character, character_config)

    character_config.walk_towards = step.walk_towards
    character_config.walking = walk.update(character, character_config)
    change_step(character_config)
end

local function doStep(character, character_config, current_step)

    global.vehicle = current_step.vehicle
    global.wait_for_recipe = current_step.wait_for
    global.cancel = current_step.cancel

    local action = current_step[1]

    if action == "craft" then
        global.tas.task_category = "Craft"
        global.tas.task = current_step[1]
        global.tas.count = current_step[3]
        global.tas.item = current_step[4]
        return craft()

    elseif action == "cancel crafting" then
        global.tas.task_category = "Cancel craft"
        global.tas.task = current_step[1]
        global.tas.count = current_step[3]
        global.tas.item = current_step[4]
        return cancel_crafting()

    elseif action == "build" then
        -- global.tas.task_category = "Build"
        -- global.tas.task = current_step[1]
        -- global.tas.target_position = current_step[3]
        -- global.tas.item = current_step[4]
        -- global.tas.direction = current_step[5]
        return build(character, character_config, fle_utils.to_position(current_step[2]), current_step[3], current_step[4])

    elseif action == "take" then
        -- global.tas.task_category = "Take"
        -- global.tas.task = current_step[1]
        -- global.tas.target_position = current_step[3]
        -- global.tas.item = current_step[4]
        -- global.tas.amount = current_step[5]
        -- global.tas.slot = current_step[6]

        if current_step.all then
            return take_all()
        else
            return take.quantity(character, character_config, fle_utils.to_position(current_step[2]), current_step[3], current_step[4], current_step[5])
        end

    elseif action == "put" then
        -- global.tas.task_category = "Put"
        -- global.tas.task = current_step[1]
        -- global.tas.target_position = current_step[3]
        -- global.tas.item = current_step[4]
        -- global.tas.amount = current_step[5]
        -- global.tas.slot = current_step[6]
        return put(character, character_config, fle_utils.to_position(current_step[2]), current_step[3], current_step[4], current_step[5])

    elseif action == "rotate" then
        global.tas.task_category = "Rotate"
        global.tas.task = current_step[1]
        global.tas.target_position = current_step[3]
        global.tas.rev = current_step[4]
        return rotate()

    elseif action == "tech" then
        global.tas.task_category = "Tech"
        global.tas.task = current_step[1]
        global.tas.item = current_step[3]
        return tech()

    elseif action == "recipe" then
        global.tas.task_category = "Recipe"
        global.tas.task = current_step[1]
        global.tas.target_position = current_step[3]
        global.tas.item = current_step[4]
        return recipe()

    elseif action == "limit" then
        global.tas.task_category = "limit"
        global.tas.task = current_step[1]
        global.tas.target_position = current_step[3]
        global.tas.amount = current_step[4]
        global.tas.slot = current_step[5]
        return limit()

    elseif action == "priority" then
        global.tas.task_category = "priority"
        global.tas.task = current_step[1]
        global.tas.target_position = current_step[3]
        global.tas.input = current_step[4]
        global.tas.output = current_step[5]
        return priority()

    elseif action == "filter" then
        global.tas.task_category = "filter"
        global.tas.task = current_step[1]
        global.tas.target_position = current_step[3]
        global.tas.item = current_step[4]
        global.tas.slot = current_step[5]
        global.tas.type = current_step[6]
        return filter()

    elseif action == "drop" then
        global.tas.task = current_step[1]
        global.tas.drop_position = current_step[3]
        global.tas.drop_item = current_step[4]
        return drop()

    elseif action == "pick" then
        global.tas.player.picking_state = true
        return true

    elseif action == "idle" then
        global.tas.idle = current_step[3]
        return true

    elseif action == "launch" then
        global.tas.task_category = "launch"
        global.tas.task = current_step[1]
        global.tas.target_position = current_step[3]
        return launch()

    elseif action == "next" then
        global.tas.task_category = "next"
        global.tas.task = current_step[1]
        return Next()

    elseif action == "shoot" then
        global.tas.task_category = "shoot"
        global.tas.task = current_step[1]
        global.tas.target_position = current_step[3]
        global.tas.amount = current_step[4]
        return shoot()

    elseif action == "throw" then
        global.tas.task_category = "throw"
        global.tas.task = current_step[1]
        global.tas.target_position = current_step[3]
        global.tas.item = current_step[4]
        return throw()

    elseif action == "equip" then
        global.tas.task_category = "equip"
        global.tas.task = current_step[1]
        global.tas.amount = current_step[3]
        global.tas.item = current_step[4]
        global.tas.slot = current_step[5]
        return equip()

    elseif action == "enter" then
        global.tas.task_category = "enter"
        global.tas.task = current_step[1]
        return enter()

    elseif action == "send" then
        global.tas.task_category = "send"
        global.tas.task = current_step[1]
        global.tas.target_position = current_step[3]
        return send()
    end

end

local function update_mining(character, character_config, step)
    character.update_selected_entity(step[2])

    character.mining_state = {mining = true, position = step[2]}

    character_config.duration = step[3]
    character_config.ticks_mining = character_config.ticks_mining + 1

    if character_config.ticks_mining >= character_config.duration then
        change_step(character_config)
        character_config.mining = 0
        character_config.ticks_mining = 0
    end

    character_config.mining = character_config.mining + 1
    if character_config.mining > 5 then
        if character.character_mining_progress == 0 then
            rcon.print(string.format(
                           "Step: %s, Action: %s: Cannot reach resource",
                           character_config.step_number, action))
        else
            character_config.mining = 0
        end
    end
end

local function handle_pretick(character, character_config, steps)
    while true do
        local step = steps[character_config.step_number]

        if step == nil then
            return -- no more steps to handle
        elseif (step[1] == "walk" and
            (character_config.walking.walking == false or
                character_config.walk_towards) and character_config.idle < 1) then

            update_walking(character, character_config, step)
        else
            return -- no more to do, break loop
        end
    end
end

local function handle_ontick(character, character_config, step)
    local action = step[1]

    if character_config.walking.walking == false then
        if character_config.idle > 0 then
            character_config.idle = character_config.idle - 1
            character_config.idled = character_config.idled + 1

            if character_config.idle == 0 then
                character_config.idled = 0

                if action == "walk" then
                    update_walking(character, character_config, step)
                end
            end
        elseif action == "walk" then
            update_walking(character, character_config, step)

        elseif action == "mine" then
            update_mining(character, character_config, step)

        elseif doStep(character, character_config, step) then
            change_step(character_config)
        end
    else
        if global.walk_towards_state and action == "mine" then
            update_mining(character, character_config, step)

        elseif action ~= "walk" and action ~= "idle" and action ~= "mine" then
            if doStep(character, character_config, step) then change_step(character_config) end
        end
    end
end

function handle_tick.update(character, character_config)
    character_config.walking = walk.update(character, character_config)

    local steps = character_config.steps
    handle_pretick(character, character_config, steps)

    local step = steps[character_config.step_number]
    if step == nil then
        return -- no more steps to handle
    end

    handle_ontick(character, character_config, step)
end

return handle_tick
