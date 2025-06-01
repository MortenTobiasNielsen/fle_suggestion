local fle_utils = {}

function fle_utils.inventory_stats(inv)
    if not inv then return nil end
    local slots = #inv
    local empty = inv.count_empty_stacks()
    local items = inv.get_contents()
    return {slots = slots, empty = empty, items = items}
end

function fle_utils.floor(x, d)
    local p = 10 ^ d
    return math.floor(x * p) / p
end

function fle_utils.ceil(x, d)
    local power = 10 ^ d
    return math.ceil(x * power) / power
end

return fle_utils
