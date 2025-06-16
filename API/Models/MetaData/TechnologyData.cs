namespace API.Models;

public class TechnologyData
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("researched")]
    public bool Researched { get; set; }

    [JsonPropertyName("enabled")]
    public bool Enabled { get; set; }

    [JsonPropertyName("level")]
    public int Level { get; set; }

    [JsonPropertyName("prerequisites")]
    public List<string> Prerequisites { get; set; } = [];

    [JsonPropertyName("research_unit_count")]
    public int ResearchUnitCount { get; set; }

    [JsonPropertyName("research_unit_energy")]
    public int ResearchUnitEnergy { get; set; }

    [JsonPropertyName("ingredients")]
    public List<TechnologyIngredient> Ingredients { get; set; } = [];

    [JsonPropertyName("effects")]
    public List<TechnologyEffect> Effects { get; set; } = [];
}

public class TechnologyIngredient
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("amount")]
    public int Amount { get; set; }
}

public class TechnologyEffect
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("recipe")]
    public string? Recipe { get; set; }

    [JsonPropertyName("modifier")]
    public double? Modifier { get; set; }
} 