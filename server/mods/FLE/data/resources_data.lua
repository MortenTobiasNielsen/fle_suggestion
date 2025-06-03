local json = require("dkjson")
local fle_utils = require("fle_utils")

local DECIMALS = 2

function resources_data()
    local all = global.fle.game_surface.find_entities_filtered {
        area = global.fle.area,
        type = {"resource", "tree"}
    }

    local data = {
        tree = {}
    }

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
                table.insert(data.tree, {selection_box = selection_box})
            else
                local name = entity.name
                data[name] = data[name] or {}
                table.insert(data[name], {
                    selection_box = selection_box,
                    amount = entity.amount,
                    yield = (name == "crude-oil") and
                        math.max(math.floor(entity.amount / 300), 20) or nil -- The calculation is wrong, but I'm unaware of what it should be
                })
            end
        end
    end

    return json.encode(data)
end

return resources_data
