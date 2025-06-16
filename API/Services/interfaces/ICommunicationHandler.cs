namespace API.Services;

public interface ICommunicationHandler
{
    Task<string> SendActionsAsync(Dictionary<int, List<string>> agentActions);
    Task<string> GetDataAsync(int agentId, DataType dataType, int radiusToSearch);
    Task<string> ResetAsync(int agentCount);
    Task<string> ExecuteActionsAsync();
}