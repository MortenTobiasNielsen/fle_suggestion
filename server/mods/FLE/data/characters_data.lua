local json = require("dkjson")
local fle_utils = require("fle_utils")

local characters_data = {}

function characters_data.get()
    local characters = global.fle.characters
    if not characters or #characters == 0 then
        return
            "No characters initialized. Please use /c remote.call('AICommands', 'reset', 1) to initialize."
    end

    records = {}
    for _, character in ipairs(global.fle.characters) do
        if character.valid then
            local position = {
                x = character.position.x,
                y = character.position.y
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

            local record = {
                position = position,
                inventory = {
                    main = main_stats,
                    guns = gun_stats,
                    ammo = ammo_stats
                }
            }

            table.insert(records, record)

        end
    end

    return json.encode(records)
end

return characters_data
