local json = require("dkjson")

local electricity_data = {}

function electricity_data.get()
    local surface = global.fle.game_surface
    local pole = surface.find_entities_filtered{
        area = global.fle.area,
        type = "electric-pole"
    }[1]
    if not pole or not pole.valid then
        return "No electric pole found in the area."
    end

    local stats = pole.electric_network_statistics

    local prod = 0
    for name in pairs(stats.output_counts) do
        prod = prod + stats.get_flow_count {
            name = name,
            output = true,
            precision_index = defines.flow_precision_index.one_minute
        }
    end

    local cap = 0
    for _, gen in ipairs(surface.find_entities_filtered {
        area = area,
        type = {"burner-generator", "generator", "fusion-reactor"}
    }) do
        if gen.is_connected_to_electric_network() then
            cap = cap + gen.prototype.max_power_output
        end
    end

    for _, solar in ipairs(surface.find_entities_filtered {
        area = area,
        type = "solar-panel"
    }) do
        if solar.is_connected_to_electric_network() then
            cap = cap + solar.get_electric_output_flow_limit()
        end
    end

    local record = {production = prod * 60 / 1000, capacity = cap * 60 / 1000}
    return json.encode(record)
end

return electricity_data
