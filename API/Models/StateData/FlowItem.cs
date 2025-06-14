using System.Text.Json.Serialization;

namespace API.Models;

public class FlowItem
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("quantity")]
    public double Quantity { get; set; }
}
