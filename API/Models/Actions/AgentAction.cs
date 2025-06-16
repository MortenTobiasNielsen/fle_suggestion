namespace API.Models;

public class AgentAction
{
    [JsonPropertyName("type")]
    public required string Type { get; set; }

    [JsonPropertyName("position")]
    public Position? Position { get; set; }

    [JsonPropertyName("item_name")]
    public string? ItemName { get; set; }

    [JsonPropertyName("quantity")]
    public int? Quantity { get; set; }

    [JsonPropertyName("technology_name")]
    public string? TechnologyName { get; set; }

    [JsonPropertyName("inventory_type")]
    [JsonConverter(typeof(InventoryTypeNullableJsonConverter))]
    public InventoryType? InventoryType { get; set; }

    [JsonPropertyName("direction")]
    [JsonConverter(typeof(DirectionNullableJsonConverter))]
    public Direction? Direction { get; set; }

    [JsonPropertyName("reverse")]
    public bool? Reverse { get; set; }

    [JsonPropertyName("recipe_name")]
    public string? RecipeName { get; set; }

    [JsonPropertyName("ticks")]
    public int? Ticks { get; set; }
} 