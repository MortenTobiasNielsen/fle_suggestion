using System.Text.Json.Serialization;

namespace API.Models;

public class ActionsRequest
{
    [JsonPropertyName("agent_actions")]
    public required List<AgentActions> AgentActions { get; set; }
} 