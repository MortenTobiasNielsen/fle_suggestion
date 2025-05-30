local fle_utils = {}

function fle_utils.inventory_stats(inv)
    if not inv then return nil end
    local slots = #inv
    local empty = inv.count_empty_stacks()
    local items = inv.get_contents()
    return {slots = slots, empty = empty, items = items}
end


function fle_utils.send_data(data, chunk_size)
    local len = #data
    local i   = 1

    while i <= len do
        local part = data:sub(i, i + chunk_size - 1)
        rcon.print(part)
        i = i + chunk_size
    end
end

return fle_utils