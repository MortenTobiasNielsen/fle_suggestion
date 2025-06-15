using API.Models;
using CoreRCON;
using System.Text;
using System.Net;
using System.Text.Json;

namespace API.Services;

public class CommunicationHandler : ICommunicationHandler, IDisposable
{
    private readonly RCON _client;
    private readonly SemaphoreSlim _connectionSemaphore = new(1, 1);
    private bool _isConnected = false;

    public CommunicationHandler(IConfiguration configuration)
    {
        var host = configuration.GetValue<string>("Rcon:Host") ?? "127.0.0.1";
        var port = configuration.GetValue<ushort>("Rcon:Port", 27015);
        var password = configuration.GetValue<string>("Rcon:Password") ?? "factorio";
        
        var endpoint = new IPEndPoint(IPAddress.Parse(host), port);
        _client = new RCON(endpoint, password);
    }

    public async Task<string> SendActionsAsync(Dictionary<int, List<string>> agentActions)
    {
        await EnsureConnectedAsync();
        
        if (!agentActions.Any())
        {
            return "No actions to send for any agent.";
        }

        var results = new List<string>();

        foreach (var (agentId, actions) in agentActions)
        {
            if (!actions.Any())
                continue;

            var command = BuildActionsCommand(agentId, actions);
            var result = await _client.SendCommandAsync(command);
            results.Add($"Agent {agentId}: {result}");
        }

        return string.Join("\n", results);
    }

    public async Task<string> GetDataAsync(int agentId, DataType dataType, int radiusToSearch)
    {
        await EnsureConnectedAsync();
        
        var command = $"/sc remote.call(\"FLE\", \"{dataType.GetValue()}\", {agentId}, {radiusToSearch})";
        return await _client.SendCommandAsync(command);
    }

    public async Task<string> ResetAsync(int agentCount)
    {
        await EnsureConnectedAsync();
        
        var command = $"/sc remote.call(\"FLE\", \"reset\", {agentCount})";
        return await _client.SendCommandAsync(command);
    }

    public async Task<string> ExecuteActionsAsync()
    {
        await EnsureConnectedAsync();
        
        var command = "/sc remote.call(\"FLE\", \"execute_actions\")";
        return await _client.SendCommandAsync(command);
    }

    private static string BuildActionsCommand(int agentId, List<string> actions)
    {
        var command = new StringBuilder($"/sc remote.call(\"FLE\", \"add_actions\", {agentId}, {{");
        
        for (int i = 0; i < actions.Count; i++)
        {
            command.Append(actions[i]);
            if (i < actions.Count - 1)
            {
                command.Append(", ");
            }
        }
        
        command.Append("})");
        return command.ToString();
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

    public void Dispose()
    {
        _client?.Dispose();
        _connectionSemaphore?.Dispose();
    }
} 