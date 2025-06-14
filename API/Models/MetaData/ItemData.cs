using System.Text.Json.Serialization;

namespace API.Models;

public class ItemData
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("stack_size")]
    public int StackSize { get; set; }

    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("group")]
    public string Group { get; set; } = string.Empty;

    [JsonPropertyName("subgroup")]
    public string Subgroup { get; set; } = string.Empty;

    [JsonPropertyName("place_result")]
    public string? PlaceResult { get; set; }

    [JsonPropertyName("selection_box")]
    public BoundingBox? SelectionBox { get; set; }

    [JsonPropertyName("collision_box")]
    public BoundingBox? CollisionBox { get; set; }

    [JsonPropertyName("tile_width")]
    public int? TileWidth { get; set; }

    [JsonPropertyName("tile_height")]
    public int? TileHeight { get; set; }
}