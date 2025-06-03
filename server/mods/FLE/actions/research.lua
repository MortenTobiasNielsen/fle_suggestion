function research(character, name, cancel)
    local force = character.force
    local technology = force.technologies[name]

	if not tech then
        -- log("Technology '" .. name .. "' does not exist for force '" .. force.name .. "'.")
        return false
    end

    if tech.researched then
        -- log("Technology '" .. name .. "' has already been researched.")
        return false
    end

    if not tech.enabled then
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