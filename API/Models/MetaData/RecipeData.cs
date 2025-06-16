namespace API.Models;

public class RecipeData
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("category")]
    public string Category { get; set; } = string.Empty;

    [JsonPropertyName("enabled")]
    public bool Enabled { get; set; }

    [JsonPropertyName("energy")]
    public double Energy { get; set; }

    [JsonPropertyName("ingredients")]
    public List<RecipeIngredient> Ingredients { get; set; } = [];

    [JsonPropertyName("results")]
    public List<RecipeResult> Results { get; set; } = [];

    [JsonPropertyName("group")]
    public string Group { get; set; } = string.Empty;

    [JsonPropertyName("subgroup")]
    public string Subgroup { get; set; } = string.Empty;
}

public class RecipeIngredient
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("amount")]
    public int Amount { get; set; }
}

public class RecipeResult
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("amount")]
    public int Amount { get; set; }

    [JsonPropertyName("probability")]
    public double Probability { get; set; }
}