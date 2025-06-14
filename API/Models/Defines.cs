using System.Text.Json.Serialization;

namespace API.Models;

public enum Direction
{
    [JsonPropertyName("defines.direction.north")]
    North,
    
    [JsonPropertyName("defines.direction.south")]
    South,
    
    [JsonPropertyName("defines.direction.east")]
    East,
    
    [JsonPropertyName("defines.direction.west")]
    West
}

public enum InventoryType
{
    [JsonPropertyName("defines.inventory.fuel")]
    Fuel,
    
    [JsonPropertyName("defines.inventory.input")]
    Input,
    
    [JsonPropertyName("defines.inventory.main")]
    Main,
    
    [JsonPropertyName("defines.inventory.chest")]
    Chest
}

public static class DirectionExtensions
{
    public static string GetValue(this Direction direction) => direction switch
    {
        Direction.North => "defines.direction.north",
        Direction.South => "defines.direction.south",
        Direction.East => "defines.direction.east",
        Direction.West => "defines.direction.west",
        _ => throw new ArgumentOutOfRangeException(nameof(direction))
    };
}

public static class InventoryTypeExtensions
{
    public static string GetValue(this InventoryType inventoryType) => inventoryType switch
    {
        InventoryType.Fuel => "defines.inventory.fuel",
        InventoryType.Input => "defines.inventory.input",
        InventoryType.Main => "defines.inventory.main",
        InventoryType.Chest => "defines.inventory.chest",
        _ => throw new ArgumentOutOfRangeException(nameof(inventoryType))
    };
} 