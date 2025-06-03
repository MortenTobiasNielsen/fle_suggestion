local json = require("dkjson")

-- The information extracted doesn't seem too useful and therefore should be improved in the future.
function research_data()
    local technologies_info = {}
    local in_progress = {}
    local research_queue = {}

    local force = global.fle.characters[1].force

    if force.research_queue then
        for _, technology in ipairs(force.research_queue) do
            table.insert(research_queue, technology.name)
        end
    end

    for name, technology in pairs(force.technologies) do
        local ingredients = {}
        for _, ingredient in ipairs(technology.research_unit_ingredients) do
            table.insert(ingredients, {
                name = ingredient.name,
                amount = ingredient.amount
            })
        end

        local technology_info = {
            researched = technology.researched,
            enabled = technology.enabled,
            level = technology.level,
            research_unit_count = technology.research_unit_count,
            research_unit_energy = technology.research_unit_energy,
            ingredients = ingredients
        }

        local current_research = force.current_research
        local current_progress = force.research_progress
        if current_research and name == current_research.name then
            technology_info.progress = current_progress
            in_progress[name] = technology_info
        else
            technologies_info[name] = technology_info
        end
    end

    return json.encode({
        technologies = technologies_info,
        in_progress = in_progress,
        research_queue = research_queue
    })
end

return research_data