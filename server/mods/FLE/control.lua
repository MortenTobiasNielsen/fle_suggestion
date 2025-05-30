-- A docker image with the Factorio headless server which has a mod with different scenarios. The mod exposes LUA functions for all the actions available in the game including extracting stats.
-- An application makes it easy to configure and spin up the docker image for a specific scenario and with a specific amount of agents. It includes a thin RCON wrapper mapping to the exposed LUA functions, so it is easy to work with. 
local json = require("dkjson")
local crash_site = require("crash-site")
local util = require("util")
local fle_utils = require("fle_utils")
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
    global.game_surface = game.surfaces["nauvis"]
    global.backup = game.create_surface("scenario_backup")
    global.area = {{-1000, -1000}, {1000, 1000}}

    global.game_surface.clone_area {
        source_area = global.area,
        destination_area = global.area,
        destination_surface = global.backup,
        clone_tiles = true,
        clone_entities = true
    }

    destroy_all_characters(global.backup)

end)

script.on_event(defines.events.on_player_joined_game, function(event)
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

function reset_scenario(num_characters)
    global.backup.clone_area {
        source_area = global.area,
        destination_area = global.area,
        destination_surface = global.game_surface,
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

    global.characters = {}

    for i = 1, num_characters do
        local char = global.game_surface.create_entity {
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

            global.characters[i] = char
        end
    end

    if remote.interfaces["freeplay"] ~= nil then
        local crashed_ship_items = remote.call("freeplay", "get_ship_items")
        local crashed_debris_items = remote.call("freeplay", "get_debris_items")

        crash_site.create_crash_site(global.game_surface, {-5, -6},
                                     util.copy(crashed_ship_items),
                                     util.copy(crashed_debris_items))
    end

    return "Scenario reset with " .. num_characters .. " characters."
end

remote.add_interface("AICommands", {
    reset = function(num_characters)
        if not num_characters or num_characters < 1 and num_characters > 9 then
            rcon.print(
                "Invalid number of characters. Please specify a number between 1 and 9.")
        end

        local out = reset_scenario(num_characters)
        fle_utils.send_data(out, DATA_CHUNK_SIZE)
        return out
    end,
    electricity_data = function() 
        local out = electricity_data.get()
        fle_utils.send_data(out, DATA_CHUNK_SIZE)
        return out
    end,
    building_data = function()
        local out = buildings_data.get()
        fle_utils.send_data(out, DATA_CHUNK_SIZE)
        return out
    end,
    character_data = function() 
        local out = characters_data.get()
       fle_utils.send_data(out, DATA_CHUNK_SIZE)
        return out
    end,
    resource_data = function()
        local out = resources_data.get()
        fle_utils.send_data(out, DATA_CHUNK_SIZE)
        return out
    end
})

commands.add_command("flip",
                     "Cycle through available characters on this surface: /flip [next|prev]",
                     function(cmd)
    local player = game.get_player(cmd.player_index)
    if not (player and player.valid) then return end

    local characters = global.characters
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
