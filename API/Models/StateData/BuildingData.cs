namespace API.Models;

public class Building
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("position")]
    public Position Position { get; set; } = new(0, 0);

    [JsonPropertyName("selection_box")]
    public BoundingBox SelectionBox { get; set; } = new BoundingBox();

    [JsonPropertyName("direction")]
    public string Direction { get; set; } = string.Empty;

    [JsonPropertyName("status")]
    public string? Status { get; set; }

    [JsonPropertyName("inventory_stats")]
    public BuildingInventory? InventoryStats { get; set; }
}

public class BuildingInventory
{
    [JsonPropertyName("fuel")]
    public Inventory? Fuel { get; set; }

    [JsonPropertyName("input")]
    public Inventory? Input { get; set; }

    [JsonPropertyName("output")]
    public Inventory? Output { get; set; }

    [JsonPropertyName("modules")]
    public Inventory? Modules { get; set; }
}