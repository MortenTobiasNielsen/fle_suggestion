local json = require("dkjson")

local resources_data = {}

local function sq_dist(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return dx * dx + dy * dy
end

local function cluster_positions(points, radius)
    local clusters = {}
    local visited = {}

    local r2 = radius * radius
    for i = 1, #points do
        if not visited[i] then
            local cluster = {}
            local queue = {i}
            visited[i] = true

            while #queue > 0 do
                local idx = table.remove(queue)
                local pt = points[idx]
                cluster[#cluster + 1] = pt

                -- look for neighbors not yet visited
                for j = 1, #points do
                    if not visited[j] and sq_dist(pt, points[j]) <= r2 then
                        visited[j] = true
                        queue[#queue + 1] = j
                    end
                end
            end

            clusters[#clusters + 1] = cluster
        end
    end

    return clusters
end

function resources_data.get(cluster_radius)
    local all = global.game_surface.find_entities_filtered {
        area = {{-30, -30}, {30, 30}},
        type = {"resource", "tree"}
    }

    local out = {trees = {}, resources = {}}

    for _, ent in ipairs(all) do
        if ent.valid then

            if ent.type == "tree" then
                table.insert(out.trees, {x = ent.position.x, y = ent.position.y})
            else
                local name = ent.name
                out.resources[name] = out.resources[name] or {}
                table.insert(out.resources[name], {
                    x = ent.position.x,
                    y = ent.position.y,
                    amount = ent.amount,
                    yield = (name == "crude-oil") and
                        math.max(math.floor(ent.amount / 300), 20) or nil
                })
            end
        end
    end

    cluster_radius = cluster_radius or 2
    for name, points in pairs(out.resources) do
        out.resources[name] = cluster_positions(points, cluster_radius)
    end

    local json_data = json.encode(out)

    return json_data
end

return resources_data
