namespace API.Models;

public class MetaData
{
    [JsonPropertyName("resources")]
    public ResourcesData Resources { get; set; } = new();

    [JsonPropertyName("items")]
    public List<ItemData> Items { get; set; } = [];

    [JsonPropertyName("recipes")]
    public List<RecipeData> Recipes { get; set; } = [];

    [JsonPropertyName("technologies")]
    public List<TechnologyData> Technologies { get; set; } = [];
}
