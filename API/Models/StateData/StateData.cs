namespace API.Models;

public class StateData
{
    [JsonPropertyName("agents")]
    public List<Agent> Agents { get; set; } = [];

    [JsonPropertyName("buildings")]
    public List<Building> Buildings { get; set; } = [];

    [JsonPropertyName("electricity")]
    public ElectricityData Electricity { get; set; } = new();

    [JsonPropertyName("flow")]
    public FlowData Flow { get; set; } = new();

    [JsonPropertyName("research_queue")]
    public List<ResearchQueueItem> ResearchQueue { get; set; } = [];
}
