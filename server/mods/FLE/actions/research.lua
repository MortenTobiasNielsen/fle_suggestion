function research(character, name, cancel)
    local force = character.force
    local technology = force.technologies[name]

	if not technology then
        -- log("Technology '" .. name .. "' does not exist for force '" .. force.name .. "'.")
        return false
    end

    if technology.researched then
        -- log("Technology '" .. name .. "' has already been researched.")
        return false
    end

    if not technology.enabled then
        -- log("Technology '" .. name .. "' is not enabled and cannot be researched.")
        return false
    end

    if cancel then
        force.research_queue = {}
    end

    local success = force.add_research(name)
    if not success then
        -- log("Failed to add technology '" .. name .. "' to the research queue.")
        return false
    end

    return true
end

return research