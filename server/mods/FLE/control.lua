local json = require("dkjson")
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

    for character_index, character in pairs(global.fle.characters) do
        local character_config = global.fle.character_configs[character_index]

        local current_step_number = character_config.step_number
        local number_of_steps = #character_config.steps

        -- It seems like this could be the cause of the stuttering when a players is attached to a character, but I don't currently have a good fix.
        character.walking_state = {
            walking = false,
            direction = character_config.walking.direction
        }

        if current_step_number <= number_of_steps then
            handle_tick.update(character, character_config)

            local current_step_number = character_config.step_number
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
                character_index = i,
                walking = {walking = false, direction = defines.direction.north},
                destination = {
                    x = character.position.x,
                    y = character.position.y
                },
                steps = {},
                step_number = 1,
                step_reached = 1,
                idle = 0,
                idled = 0,
                mining = 0,
                ticks_mining = 0,
                walk_towards = false
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

    return "Scenario reset with " .. num_characters .. " characters."
end

function execute_steps()
    game.tick_paused = false
    return "Steps set to be executed."
end

function add_steps(character_index, steps)
    for i = 1, #steps do add_step(character_index, steps[i]) end
    return "Steps added successfully."
end

function add_step(character_index, step)
    if not global.fle.characters[character_index] then
        return "Character does not exist."
    end

    local character = global.fle.characters[character_index]
    if not character.valid then
        return "Character is invalid."
    end

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
    state_data = function(character_index, radius)
        rcon.print(state_data(character_index, radius))
    end,
    meta_data = function(character_index, radius)
        rcon.print(meta_data(character_index, radius))
    end,
    map_data = function(character_index, radius)
        rcon.print(map_data(character_index, radius))
    end,
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
