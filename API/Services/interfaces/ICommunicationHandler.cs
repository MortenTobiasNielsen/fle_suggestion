using API.Models;

namespace API.Services;

public interface ICommunicationHandler
{
    Task<string> SendActionsAsync();
    Task<string> GetDataAsync(int agentId, DataType dataType, int radiusToSearch);
    void Research(int agentId, string technologyName);
    void CancelResearch(int agentId);
    void Walk(int agentId, Position position);
    void Take(int agentId, Position position, string itemName, int quantity, InventoryType inventoryType);
    void Put(int agentId, Position position, string itemName, int quantity, InventoryType inventoryType);
    void Craft(int agentId, string itemName, int quantity);
    void CancelCraft(int agentId, string itemName, int quantity);
    void Build(int agentId, Position position, string itemName, Direction direction);
    void Rotate(int agentId, Position position, bool reverse = false);
    void Mine(int agentId, Position position, int ticks);
    void Recipe(int agentId, Position position, string recipeName);
    void Wait(int agentId, int ticks);
    void Drop(int agentId, Position position, string itemName);
    void LaunchRocket(int agentId, Position position);
    void PickUp(int agentId, int ticks);
}