namespace API.Models;

public class ResearchQueueItem
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("level")]
    public int Level { get; set; }

    [JsonPropertyName("research_unit_count")]
    public int ResearchUnitCount { get; set; }

    [JsonPropertyName("research_unit_energy")]
    public int ResearchUnitEnergy { get; set; }

    [JsonPropertyName("ingredients")]
    public List<ResearchIngredient> Ingredients { get; set; } = [];

    [JsonPropertyName("effects")]
    public List<ResearchEffect> Effects { get; set; } = [];

    [JsonPropertyName("progress")]
    public double Progress { get; set; }
}

public class ResearchIngredient
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("amount")]
    public int Amount { get; set; }
}

public class ResearchEffect
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("modifier")]
    public double? Modifier { get; set; }
}