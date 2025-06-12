local fle_utils = require("fle_utils")

local build = require("actions.build")
local craft = require("actions.craft")
local launch_rocket = require("actions.launch_rocket")
local put = require("actions.put")
local recipe = require("actions.recipe")
local research = require("actions.research")
local rotate = require("actions.rotate")
local take = require("actions.take")
local walk = require("actions.walk")

local function increment_action_number(character_config)
    character_config.action_number = character_config.action_number + 1
end

local function update_walking(character, character_config, action)
    walk.update_destination_position(character_config, action.destination)
    walk.find_walking_pattern(character, character_config)

    character_config.walking_state = walk.update(character, character_config)
    increment_action_number(character_config)
end

local function update_mining(character, character_config, action)
    local position = action.position

    character.update_selected_entity(position)

    character.mining_state = {mining = true, position = position}

    character_config.ticks_mined = character_config.ticks_mined + 1

    if character_config.ticks_mined > action.ticks then
        increment_action_number(character_config)
        character_config.ticks_mined = 0
        character.mining_state = {mining = false, position = position}
    end

    -- This error state should be revisited when we are more clear about the action flow
    character_config.tried_to_mine_for = character_config.tried_to_mine_for + 1
    if character_config.tried_to_mine_for > 5 then
        if character.character_mining_progress == 0 then
            -- Meaningful error message
        else
            character_config.tried_to_mine_for = 0
        end
    end
end

local function do_action(character, character_config, action)

    local action_type = action.type

    if action_type == "build" then
        return build(character, character_config, action.position,
                     action.item_name, action.direction)
    end

    if action_type == "craft" then
        return craft.add(character, character_config, action.item_name,
                         action.quantity)
    end

    if action_type == "cancel_craft" then
        return craft.cancel(character, character_config, action.item_name,
                            action.quantity)
    end

    if action_type == "drop" then
        return drop(character, character_config, action.position,
                    action.item_name)
    end

    if action_type == "launch_rocket" then
        return launch_rocket(character, character_config, action.position)
    end

    if action_type == "put" then
        return put(character, character_config, action.position,
                   action.item_name, action.quantity)
    end

    if action_type == "recipe" then
        return recipe(character, character_config, action.position,
                      action.recipe_name)
    end

    if action_type == "research" then
        return research(character, action.technology_name)
    end

    if action_type == "cancel_research" then
        character.force.research_queue = {}
    end

    if action_type == "rotate" then
        return rotate(character, character_config, action.position,
                      action.reverse)
    end

    if action_type == "take" then
        return take(character, character_config, action.position,
                    action.item_name, action.quantity)
    end

    if action_type == "pick_up" then
        character_config.pickup_ticks = character_config.pickup_ticks +
                                            action.ticks - 1
        character.picking_state = true
        return true
    end

    if action_type == "wait" then
        character_config.wait = action.ticks
        return true
    end
end

local function handle_pretick(character, character_config, actions)
    while true do
        local action = actions[character_config.action_number]

        if action == nil then
            return -- no more actions to handle (pause game?)
        end

        local action_type = action.type

        if (action_type == "walk" and character_config.walking_state.walking ==
            false and character_config.wait < 1) then

            update_walking(character, character_config, action)

        elseif action_type == "pick_up" then
            character_config.pickup_ticks =
                character_config.pickup_ticks + action.ticks - 1
            character.picking_state = true
            increment_action_number(character_config)

        else
            return -- action is not a pretick action, break loop
        end
    end
end

local function handle_ontick(character, character_config, action)
    if character.pickup_ticks > 0 then
        character.picking_state = true
        character.pickup_ticks = character.pickup_ticks - 1
    end

    local action_type = action.type

    if character_config.walking_state.walking == false then
        if character_config.wait > 0 then
            character_config.wait = character_config.wait - 1

            if character_config.wait == 0 then
                if action_type == "walk" then
                    update_walking(character, character_config, action)
                end
            end
        elseif action_type == "walk" then
            update_walking(character, character_config, action)

        elseif action_type == "mine" then
            update_mining(character, character_config, action)

        elseif do_action(character, character_config, action) then
            increment_action_number(character_config)
        end
    else
        if action_type ~= "walk" and action_type ~= "wait" and action_type ~=
            "mine" then
            if do_action(character, character_config, action) then
                increment_action_number(character_config)
            end
        end
    end
end

function handle_tick(character, character_config)
    character_config.walking_state = walk.update(character, character_config)

    local actions = character_config.actions
    handle_pretick(character, character_config, actions)

    local action = actions[character_config.action_number]
    if action == nil then
        return -- no more actions to handle (pause game?)
    end

    handle_ontick(character, character_config, action)
end

return handle_tick
