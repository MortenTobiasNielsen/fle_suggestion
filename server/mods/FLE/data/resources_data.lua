local json = require("dkjson")
local fle_utils = require("fle_utils")

local resources_data = {}
local DECIMALS = 2

function resources_data.get(cluster_radius)
    local all = global.fle.game_surface.find_entities_filtered {
        area = global.fle.area,
        type = {"resource", "tree"}
    }

    local out = {trees = {}, resources = {}}

    for _, entity in ipairs(all) do
        if entity.valid then
            local box = entity.selection_box
            local left_top = box.left_top
            local right_bottom = box.right_bottom

            local left_top_x = fle_utils.floor(left_top.x, DECIMALS)
            local left_top_y = fle_utils.floor(left_top.y, DECIMALS)
            local right_bottom_x = fle_utils.ceil(right_bottom.x, DECIMALS)
            local right_bottom_y = fle_utils.ceil(right_bottom.y, DECIMALS)

            local selection_box = {
                {x = left_top_x, y = left_top_y},
                {x = right_bottom_x, y = right_bottom_y}
            }

            if entity.type == "tree" then
                table.insert(out.trees, {selection_box = selection_box})
            else
                local name = entity.name
                out.resources[name] = out.resources[name] or {}
                table.insert(out.resources[name], {
                    selection_box = selection_box,
                    amount = entity.amount,
                    yield = (name == "crude-oil") and
                        math.max(math.floor(entity.amount / 300), 20) or nil -- The calculation is wrong, but I'm unaware of what it should be
                })
            end
        end
    end

    return json.encode(out)
end

return resources_data
