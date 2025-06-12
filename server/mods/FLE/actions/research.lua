function research(character, name)
    local force = character.force
    local technology = force.technologies[name]

    if not technology then
        -- Meaningful error message
        return false
    end

    if technology.researched then
        -- Meaningful error message
        return false
    end

    if not technology.enabled then
        -- Meaningful error message
        return false
    end

    local success = force.add_research(name)
    if not success then
        -- Meaningful error message
        return false
    end

    return true
end

return research
