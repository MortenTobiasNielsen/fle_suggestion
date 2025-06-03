local json = require("dkjson")
local fle_utils = require("fle_utils")

local DECIMALS = 2

function characters_data()
    local characters = global.fle.characters
    if not characters or #characters == 0 then
        return
            "No characters initialized. Please use /c remote.call('AICommands', 'reset', 1) to initialize."
    end

    data = {}
    for character_index, character in ipairs(global.fle.characters) do
        if character.valid then
            local position = {
                x = fle_utils.floor(character.position.x, DECIMALS),
                y = fle_utils.floor(character.position.y, DECIMALS)
            }

            local main_inv = character.get_inventory(defines.inventory
                                                         .character_main)
            local gun_inv = character.get_inventory(defines.inventory
                                                        .character_guns)
            local ammo_inv = character.get_inventory(defines.inventory
                                                         .character_ammo)

            local main_stats = fle_utils.inventory_stats(main_inv)
            local gun_stats = fle_utils.inventory_stats(gun_inv)
            local ammo_stats = fle_utils.inventory_stats(ammo_inv)

            local step_string = string.format("Step: %s of %s", global.fle
                                                  .character_configs[character_index]
                                                  .step_number, #global.fle
                                                  .character_configs[character_index]
                                                  .steps)

            local record = {
                character_index = character_index,
                position = position,
                inventory = {
                    main = main_stats,
                    guns = gun_stats,
                    ammo = ammo_stats
                },
                step = step_string,
                walking_state = character.walking_state,
                mining_state = character.mining_state,
                mining_progress = character.character_mining_progress,
                crafting_queue = character.crafting_queue or {},
                crafting_queue_progress = fle_utils.floor(
                    character.crafting_queue_progress, DECIMALS)
            }

            table.insert(data, record)

        end
    end

    return json.encode(data)
end

return characters_data
