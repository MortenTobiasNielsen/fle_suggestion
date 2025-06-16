namespace API.Models;

public class AgentActions
{
    [JsonPropertyName("agent_id")]
    public required int AgentId { get; set; }

    [JsonPropertyName("actions")]
    public required List<AgentAction> Actions { get; set; }
}