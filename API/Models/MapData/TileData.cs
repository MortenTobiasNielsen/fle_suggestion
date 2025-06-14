using System.Text.Json.Serialization;

namespace API.Models;

public class Tile
{
    [JsonPropertyName("position")]
    public Position Position { get; set; } = new(0, 0);
}

public class TileData
{
    [JsonPropertyName("water_tiles")]
    public List<Tile> WaterTiles { get; set; } = [];

    [JsonPropertyName("land_tiles")]
    public List<Tile> LandTiles { get; set; } = [];
} 