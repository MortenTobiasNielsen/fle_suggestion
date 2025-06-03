-- A docker image with the Factorio headless server which has a mod with different scenarios. The mod exposes LUA functions for all the actions available in the game including extracting stats.
-- An application makes it easy to configure and spin up the docker image for a specific scenario and with a specific amount of agents. It includes a thin RCON wrapper mapping to the exposed LUA functions, so it is easy to work with. 
local json = require("dkjson")
local crash_site = require("crash-site")
local util = require("util")

local fle_utils = require("fle_utils")
local handle_tick = require("handle_tick")
local buildings_data = require("data.buildings_data")
local characters_data = require("data.characters_data")
local electricity_data = require("data.electricity_data")
local resources_data = require("data.resources_data")

local DATA_CHUNK_SIZE = 1024

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
    global.fle.area = {{-1000, -1000}, {1000, 1000}} -- Change this so it instead uses a radius from the a specific character position

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

    for character_index, character in pairs(global.fle.characters) do
        local character_config = global.fle.character_configs[character_index]

        local current_step_number = character_config.step_number
        local number_of_steps = #character_config.steps

        -- if character_index == 1 then
        --     game.print(string.format("Current_step_number: %d, Steps: %d",
        --                              current_step_number, number_of_steps))
        -- end

        character.walking_state = {
            walking = false,
            direction = character_config.walking.direction
        }

        if current_step_number <= number_of_steps then
            handle_tick.update(character, character_config)

            local current_step_number = character_config.step_number

            if character_index == 1 then
                -- game.print(string.format(
                --                "Character %d: Position: (%.2f, %.2f), Walking: %s, Direction: %s, Current_step_number: %d,  Steps: %s, current step: %s",
                --                character_index, character.position.x,
                --                character.position.y, global.fle
                --                    .character_configs[character_index].walking
                --                    .walking, character_config.walking.direction,
                --                current_step_number, character_config.steps,
                --                character_config.steps[current_step_number]))
            end

            character.walking_state = character_config.walking
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
        local char = global.fle.game_surface.create_entity {
            name = "character",
            position = spawn_positions[i],
            force = game.forces.player
        }

        if char and char.valid then
            local inv = char.get_main_inventory()
            if inv then
                inv.insert({name = "wood", count = 1})
                inv.insert({name = "burner-mining-drill", count = 1})
                inv.insert({name = "stone-furnace", count = 1})
            end

            local guns_inv =
                char.get_inventory(defines.inventory.character_guns)
            if guns_inv then
                guns_inv.insert({name = "pistol", count = 1})
            end

            local ammo_inv =
                char.get_inventory(defines.inventory.character_ammo)
            if ammo_inv then
                ammo_inv.insert({name = "firearm-magazine", count = 10})
            end

            global.fle.characters[i] = char
            global.fle.character_configs[i] = {}
            global.fle.character_configs[i].character_index = i
            global.fle.character_configs[i].walking = {
                walking = false,
                direction = defines.direction.north
            }
            global.fle.character_configs[i].destination = {
                x = global.fle.characters[i].position.x,
                y = global.fle.characters[i].position.y
            }
            global.fle.character_configs[i].steps = {}
            global.fle.character_configs[i].step_number = 1
            global.fle.character_configs[i].step_reached = 1
            global.fle.character_configs[i].idle = 0
            global.fle.character_configs[i].idled = 0
            global.fle.character_configs[i].walk_towards = false
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

    return "Scenario reset with " .. num_characters .. " characters."
end

function execute_steps() game.tick_paused = false end

function add_steps(character_index, steps)
    for i = 1, #steps do 
        add_step(character_index, steps[i])
    end

    return "Steps added successfully."
end

function add_step(character_index, step)
    if not global.fle.characters[character_index] then

        game.print("Character index " .. character_index .. " does not exist.")

        return "Character does not exist."
    end

    local character = global.fle.characters[character_index]
    if not character.valid then
        game.print("Character at index " .. character_index .. " is not valid.")
        return "Character is invalid."
    end

    game.print(string.format("Adding step for character %d: %s",
                             character_index, step))

    table.insert(global.fle.character_configs[character_index].steps, step)

    return "Step added successfully."
end

remote.add_interface("AICommands", {
    reset = function(num_characters)
        if not num_characters or num_characters < 1 and num_characters > 9 then
            rcon.print(
                "Invalid number of characters. Please specify a number between 1 and 9.")
        end

        rcon.print(reset_scenario(num_characters))
    end,
    electricity_data = function() rcon.print(electricity_data.get()) end,
    building_data = function() rcon.print(buildings_data.get()) end,
    character_data = function() rcon.print(characters_data.get()) end,
    resource_data = function() rcon.print(resources_data.get()) end,
    add_step = function(character_index, step)
        rcon.print(add_step(character_index, step))
    end,
    add_steps = function(character_index, steps)
        rcon.print(add_steps(character_index, steps))
    end,
    execute_steps = function() rcon.print(execute_steps()) end
})

commands.add_command("flip",
                     "Cycle through available characters on this surface: /flip [next|prev]",
                     function(cmd)
    local player = game.get_player(cmd.player_index)
    if not (player and player.valid) then return end

    local characters = global.fle.characters
    if #characters == 0 then
        player.print("No characters available to flip through.")
        return
    end

    local current = player.character
    local current_index = 1
    if current and current.valid then
        for i, c in ipairs(characters) do
            if c == current then
                current_index = i
                break
            end
        end
    end

    local direction = (cmd.parameter or "next"):lower()
    local new_index
    if direction == "prev" then
        new_index = ((current_index - 2) % #characters) + 1
    else
        new_index = (current_index % #characters) + 1
    end

    local target = characters[new_index]
    if target and target.valid then
        player.associate_character(target)

        player.set_controller {
            type = defines.controllers.character,
            character = target
        }

        player.print(
            ("Switched to character #%d at position [%.1f, %.1f]"):format(
                target.unit_number, target.position.x, target.position.y))
    else
        player.print("Failed to switch character.")
    end
end)
