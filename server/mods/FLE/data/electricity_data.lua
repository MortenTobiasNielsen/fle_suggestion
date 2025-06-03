local json = require("dkjson")
local fle_utils = require("fle_utils")
local DECIMALS = 0

function electricity_data()
    local surface = global.fle.game_surface
    local pole = surface.find_entities_filtered{
        area = global.fle.area,
        type = "electric-pole"
    }[1]
    if not pole or not pole.valid then
        local data = {
            production = 0,
            capacity = 0,
            Info = "No electric pole found in the area."
        }

        return json.encode(data)
    end

    local stats = pole.electric_network_statistics

    local production = 0
    for name in pairs(stats.output_counts) do
        production = production + stats.get_flow_count {
            name = name,
            output = true,
            precision_index = defines.flow_precision_index.five_seconds
        }
    end

    local capacity = 0
    for _, gen in ipairs(surface.find_entities_filtered {
        area = area,
        type = {"burner-generator", "generator", "fusion-reactor"}
    }) do
        if gen.is_connected_to_electric_network() then
            capacity = capacity + gen.prototype.max_power_output
        end
    end

    for _, solar in ipairs(surface.find_entities_filtered {
        area = area,
        type = "solar-panel"
    }) do
        if solar.is_connected_to_electric_network() then
            capacity = capacity + solar.get_electric_output_flow_limit()
        end
    end

    local data = {
        production = fle_utils.floor(production * 60 / 1000, DECIMALS),
        capacity = fle_utils.floor(capacity * 60 / 1000, DECIMALS)
    }
    return json.encode(data)
end

return electricity_data
