namespace API.Models;

public class Inventory
{
    [JsonPropertyName("slots")]
    public int Slots { get; set; }

    [JsonPropertyName("empty")]
    public int Empty { get; set; }

    [JsonPropertyName("items")]
    public Dictionary<string, int> Items { get; set; } = new();
}