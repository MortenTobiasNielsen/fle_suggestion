local json = require("dkjson")
local fle_utils = require("fle_utils")

local DECIMALS = 1

function production_data()
    local data = {
        production = {},
        consumption = {}
    }

    local force = global.fle.characters[1].force
    -- Retrieve item production statistics
    local item_stats = force.item_production_statistics
    for name, _ in pairs(item_stats.input_counts) do
        local quantity = item_stats.get_flow_count{
            name = name,
            input = true,
            precision_index = defines.flow_precision_index.one_minute
        }
        quantity = fle_utils.floor(quantity, DECIMALS)
        if quantity > 0 then
            table.insert(data.production, { name = name, quantity = quantity })
        end
    end

    for name, _ in pairs(item_stats.output_counts) do
        local quantity = item_stats.get_flow_count{
            name = name,
            input = false,
            precision_index = defines.flow_precision_index.one_minute
        }
        quantity = fle_utils.floor(quantity, DECIMALS)
        if quantity > 0 then
            table.insert(data.consumption, { name = name, quantity = quantity })
        end
    end

    -- Retrieve fluid production statistics
    local fluid_stats = force.fluid_production_statistics
    for name, _ in pairs(fluid_stats.input_counts) do
        local quantity = fluid_stats.get_flow_count{
            name = name,
            input = true,
            precision_index = defines.flow_precision_index.one_minute
        }
        quantity = fle_utils.floor(quantity, DECIMALS)
        if quantity > 0 then
            table.insert(data.production, { name = name, quantity = quantity })
        end
    end

    for name, _ in pairs(fluid_stats.output_counts) do
        local quantity = fluid_stats.get_flow_count{
            name = name,
            input = false,
            precision_index = defines.flow_precision_index.one_minute
        }
        quantity = fle_utils.floor(quantity, DECIMALS)
        if quantity > 0 then
            table.insert(data.consumption, { name = name, quantity = quantity })
        end
    end

    return json.encode(data)
end

return production_data