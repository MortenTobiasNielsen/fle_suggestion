function research(character, technology_name)
    local force = character.force
    local technology = force.technologies[technology_name]

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

    local success = force.add_research(technology_name)
    if not success then
        -- Meaningful error message
        return false
    end

    return true
end

return research
