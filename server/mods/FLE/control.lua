local json = require("include.dkjson")
local crash_site = require("crash-site")
local util = require("util")

local fle_utils = require("fle_utils")
local handle_tick = require("handle_tick")
local state_data = require("data.state_data")
local meta_data = require("data.meta_data")
local map_data = require("data.map_data")

local function destroy_all_characters(surface)
    for _, entity in pairs(surface.find_entities_filtered {type = "character"}) do
        if entity.valid then entity.destroy() end
    end
end

script.on_init(function()
    global.tick_paused = true
    global.fle = {}
    global.fle.character_configs = {}
    global.font_size = 0.15
    global.fle.game_surface = game.surfaces["nauvis"]
    global.fle.backup = game.create_surface("scenario_backup")
    global.fle.area = {{-1000, -1000}, {1000, 1000}}

    global.fle.game_surface.clone_area {
        source_area = global.fle.area,
        destination_area = global.fle.area,
        destination_surface = global.fle.backup,
        clone_tiles = true,
        clone_entities = true
    }

    destroy_all_characters(global.fle.backup)

end)

script.on_event(defines.events.on_player_joined_game, function(event)
    global.tick_paused = true
    local p = game.players[event.player_index]

    if p.character and p.character.valid then p.character.destroy() end

    p.set_controller {type = defines.controllers.spectator}

    local chars = p.surface.find_entities_filtered {type = "character"}

    if chars[1] then
        p.associate_character(chars[1])
        p.set_controller {
            type = defines.controllers.character,
            character = chars[1]
        }
    end
end)

script.on_event(defines.events.on_tick, function(event)
    if not global.fle.characters then return end

    for character_id, character in pairs(global.fle.characters) do
        local character_config = global.fle.character_configs[character_id]

        local current_action_number = character_config.action_number
        local number_of_actions = #character_config.actions

        -- It seems like this could be the cause of the stuttering when a players is attached to a character, but I don't currently have a good fix.
        character.walking_state = {
            walking = false,
            direction = character_config.walking_state.direction
        }

        if current_action_number <= number_of_actions then
            handle_tick(character, character_config)

            local current_action_number = character_config.action_number
            character.walking_state = character_config.walking_state
        end
    end
end)

function reset_scenario(num_characters)
    global.fle.backup.clone_area {
        source_area = global.fle.area,
        destination_area = global.fle.area,
        destination_surface = global.fle.game_surface,
        clone_tiles = true,
        clone_entities = true
    }

    spawn_positions = {
        {0, 0}, -- center
        {0, 2}, -- north
        {0, -2}, -- south
        {2, 0}, -- east
        {-2, 0}, -- west
        {2, 2}, -- northeast
        {2, -2}, -- southeast
        {-2, 2}, -- northwest
        {-2, -2} -- southwest
    }

    global.fle.characters = {}

    for i = 1, num_characters do
        local character = global.fle.game_surface.create_entity {
            name = "character",
            position = spawn_positions[i],
            force = game.forces.player
        }

        if character and character.valid then
            local inv = character.get_main_inventory()
            if inv then
                inv.insert({name = "wood", count = 1})
                inv.insert({name = "burner-mining-drill", count = 1})
                inv.insert({name = "stone-furnace", count = 1})
            end

            local guns_inv = character.get_inventory(defines.inventory
                                                         .character_guns)
            if guns_inv then
                guns_inv.insert({name = "pistol", count = 1})
            end

            local ammo_inv = character.get_inventory(defines.inventory
                                                         .character_ammo)
            if ammo_inv then
                ammo_inv.insert({name = "firearm-magazine", count = 10})
            end

            global.fle.characters[i] = character
            global.fle.character_configs[i] = {
                character_id = i,
                walking_state = {walking = false, direction = defines.direction.north},
                destination = character.position,
                actions = {},
                action_number = 1,
                action_reached = 1,
                wait = 0,
                pickup_ticks = 0,
                ticks_mined = 0,
                tried_to_mine_for = 0,
            }
        end
    end

    if remote.interfaces["freeplay"] ~= nil then
        local crashed_ship_items = remote.call("freeplay", "get_ship_items")
        local crashed_debris_items = remote.call("freeplay", "get_debris_items")

        crash_site.create_crash_site(global.fle.game_surface, {-5, -6},
                                     util.copy(crashed_ship_items),
                                     util.copy(crashed_debris_items))
    end

    game.tick_paused = true

    if num_characters > 1 then
        return "Scenario reset with " .. num_characters .. " agents."
    else
        return "Scenario reset with " .. num_characters .. " agent."
    end
end

-- The intention is that the game with be paused when an agent either runs out of actions or runs into an error. Then once it thinks it has been fixed it can start executing actions again.
function execute_actions()
    game.tick_paused = false
    return "Actions set to be executed."
end

function add_actions(character_id, actions)
    if not global.fle.characters[character_id] then
        return "Agent does not exist."
    end

    local character = global.fle.characters[character_id]
    if not character.valid then return "Agent is invalid." end

    -- Log the actions being added to server log
    log("Adding " .. #actions .. " actions to character " .. character_id)
    
    for i = 1, #actions do
        local action = actions[i]
        -- Log each individual action to server log
        log("Character " .. character_id .. " action " .. i .. ": " .. json.encode(action))
        
        table.insert(global.fle.character_configs[character_id].actions,
                     action)
    end

    return "Actions added successfully."
end

remote.add_interface("FLE", {
    reset = function(num_characters)
        if not num_characters or num_characters < 1 and num_characters > 9 then
            return "Invalid number of agents. Please specify a number between 1 and 9."
        end

        return reset_scenario(num_characters)
    end,
    state_data = function(character_id, radius)
        local data = state_data(character_id, radius)
        rcon.print(json.encode(data))
    end,
    meta_data = function(character_id, radius)
        local data = meta_data(character_id, radius)
        rcon.print(json.encode(data))
    end,
    map_data = function(character_id, radius)
        local data = map_data(character_id, radius)
        rcon.print(json.encode(data))
    end,
    add_actions = function(character_id, actions)
        return add_actions(character_id, actions)
    end,
    execute_actions = function() 
        return execute_actions() 
    end
})
