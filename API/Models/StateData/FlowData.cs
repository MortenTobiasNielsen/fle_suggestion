using System.Text.Json.Serialization;

namespace API.Models;

public class FlowData
{
    [JsonPropertyName("production")]
    public List<FlowItem> Production { get; set; } = [];

    [JsonPropertyName("consumption")]
    public List<FlowItem> Consumption { get; set; } = [];
}
