using API.Models;
using CoreRCON;
using System.Text;
using System.Net;
using System.Text.Json;

namespace API.Services;

public class CommunicationHandler : ICommunicationHandler, IDisposable
{
    private readonly RCON _client;
    private readonly Dictionary<int, List<string>> _agentActions = [];
    private readonly SemaphoreSlim _connectionSemaphore = new(1, 1);
    private bool _isConnected = false;

    public CommunicationHandler(IConfiguration configuration)
    {
        // Get RCON configuration with Docker-friendly defaults
        var host = configuration.GetValue<string>("Rcon:Host") ?? "localhost";
        var port = configuration.GetValue<ushort>("Rcon:Port", 27015);
        var password = configuration.GetValue<string>("Rcon:Password") ?? "";
        
        var endpoint = new IPEndPoint(IPAddress.Parse(host), port);
        _client = new RCON(endpoint, password);
    }

    private static string BoolToString(bool value) => value ? "true" : "false";

    private void AddAction(int agentId, string action)
    {
        if (!_agentActions.ContainsKey(agentId))
        {
            _agentActions[agentId] = [];
        }
        _agentActions[agentId].Add(action);
    }

    private async Task EnsureConnectedAsync()
    {
        if (_isConnected) return;
        
        await _connectionSemaphore.WaitAsync();
        try
        {
            if (!_isConnected)
            {
                await _client.ConnectAsync();
                _isConnected = true;
            }
        }
        finally
        {
            _connectionSemaphore.Release();
        }
    }

    private async Task<string> SendDataRequestAsync(int agentId, DataType dataType, int radiusToSearch)
    {
        await EnsureConnectedAsync();
        var command = $"/sc remote.call(\"FLE\", \"{dataType.GetValue()}\", {agentId}, {radiusToSearch})";
        var rawResponse = await _client.SendCommandAsync(command);
        
        // The Factorio mod uses rcon.print(json.encode(data)), so we get a JSON string
        // For AOT compatibility, we'll just return the raw JSON string
        // The JSON is already properly formatted from Factorio
        try
        {
            // Just validate it's proper JSON by parsing it
            using var document = JsonDocument.Parse(rawResponse);
            return rawResponse; // Return the original JSON string
        }
        catch (JsonException)
        {
            // If it's not valid JSON, return the raw response
            return rawResponse;
        }
    }

    public async Task<string> SendActionsAsync()
    {
        await EnsureConnectedAsync();
        
        if (!_agentActions.Any())
        {
            return "No actions to send for any agent.";
        }

        var results = new List<string>();
        var agentsToProcess = _agentActions.Keys.ToList(); // Copy keys to avoid modification during iteration

        foreach (var agentId in agentsToProcess)
        {
            var actions = _agentActions[agentId];
            
            if (!actions.Any())
            {
                continue; // Skip agents with no actions
            }

            var request = new StringBuilder($"/sc remote.call(\"FLE\", \"add_actions\", {agentId}, {{");
            
            for (int i = 0; i < actions.Count; i++)
            {
                request.Append(actions[i]);
                if (i < actions.Count - 1)
                {
                    request.Append(", ");
                }
            }
            
            request.Append("})");
            
            var result = await _client.SendCommandAsync(request.ToString());
            results.Add($"Agent {agentId}: {result}");
            
            _agentActions[agentId].Clear(); // Clear actions after sending
        }

        return string.Join("\n", results);
    }

    public async Task<string> GetDataAsync(int agentId, DataType dataType, int radiusToSearch)
    {
        return await SendDataRequestAsync(agentId, dataType, radiusToSearch);
    }

    public void Research(int agentId, string technologyName)
    {
        var action = $"{{type = \"research\", technology_name = \"{technologyName}\"}}";
        AddAction(agentId, action);
    }

    public void CancelResearch(int agentId)
    {
        var action = "{type = \"cancel_research\"}";
        AddAction(agentId, action);
    }

    public void Walk(int agentId, Position position)
    {
        var action = $"{{type = \"walk\", destination = {position}}}";
        AddAction(agentId, action);
    }

    public void Take(int agentId, Position position, string itemName, int quantity, InventoryType inventoryType)
    {
        var action = $"{{type = \"take\", position = {position}, item_name = \"{itemName}\", quantity = {quantity}, inventory_type = {inventoryType.GetValue()}}}";
        AddAction(agentId, action);
    }

    public void Put(int agentId, Position position, string itemName, int quantity, InventoryType inventoryType)
    {
        var action = $"{{type = \"put\", position = {position}, item_name = \"{itemName}\", quantity = {quantity}, inventory_type = {inventoryType.GetValue()}}}";
        AddAction(agentId, action);
    }

    public void Craft(int agentId, string itemName, int quantity)
    {
        var action = $"{{type = \"craft\", item_name = \"{itemName}\", quantity = {quantity}}}";
        AddAction(agentId, action);
    }

    public void CancelCraft(int agentId, string itemName, int quantity)
    {
        var action = $"{{type = \"cancel_craft\", item_name = \"{itemName}\", quantity = {quantity}}}";
        AddAction(agentId, action);
    }

    public void Build(int agentId, Position position, string itemName, Direction direction)
    {
        var action = $"{{type = \"build\", position = {position}, item_name = \"{itemName}\", direction = {direction.GetValue()}}}";
        AddAction(agentId, action);
    }

    public void Rotate(int agentId, Position position, bool reverse = false)
    {
        var action = $"{{type = \"rotate\", position = {position}, reverse = {BoolToString(reverse)}}}";
        AddAction(agentId, action);
    }

    public void Mine(int agentId, Position position, int ticks)
    {
        var action = $"{{type = \"mine\", position = {position}, ticks = {ticks}}}";
        AddAction(agentId, action);
    }

    public void Recipe(int agentId, Position position, string recipeName)
    {
        var action = $"{{type = \"recipe\", position = {position}, recipe_name = \"{recipeName}\"}}";
        AddAction(agentId, action);
    }

    public void Wait(int agentId, int ticks)
    {
        var action = $"{{type = \"wait\", ticks = {ticks}}}";
        AddAction(agentId, action);
    }

    public void Drop(int agentId, Position position, string itemName)
    {
        var action = $"{{type = \"drop\", position = {position}, item_name = \"{itemName}\"}}";
        AddAction(agentId, action);
    }

    public void LaunchRocket(int agentId, Position position)
    {
        var action = $"{{type = \"launch_rocket\", position = {position}}}";
        AddAction(agentId, action);
    }

    public void PickUp(int agentId, int ticks)
    {
        var action = $"{{type = \"pick_up\", ticks = {ticks}}}";
        AddAction(agentId, action);
    }

    public void Dispose()
    {
        _client?.Dispose();
        _connectionSemaphore?.Dispose();
    }
} 