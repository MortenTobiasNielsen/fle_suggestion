using API.Models;

namespace API.Services;

public interface IActionProcessor
{
    Dictionary<int, List<string>> ProcessActions(List<AgentActions> agentActionsList);
} 