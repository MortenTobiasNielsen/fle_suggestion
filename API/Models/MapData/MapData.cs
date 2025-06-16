namespace API.Models;

public class MapData
{
    [JsonPropertyName("tiles")]
    public TileData Tiles { get; set; } = new();

    [JsonPropertyName("offshore_pump_locations")]
    public List<Tile> OffshorePumpLocations { get; set; } = [];
} 