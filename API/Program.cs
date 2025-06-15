using System.Text.Json.Serialization;
using API.Services;
using API.Models;
using System.Text.Json;
using Scalar.AspNetCore;
using Microsoft.Extensions.Logging;

namespace API;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateSlimBuilder(args);

        // Configure logging
        builder.Logging.ClearProviders();
        builder.Logging.AddConsole();
        builder.Logging.SetMinimumLevel(LogLevel.Information);

        builder.Services.ConfigureHttpJsonOptions(options =>
        {
            options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default);
            options.SerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
        });

        // Add API documentation services (AOT-compatible)
        builder.Services.AddOpenApi(options =>
        {
            options.AddDocumentTransformer((document, context, cancellationToken) =>
            {
                document.Info.Title = "Factorio Learning Environment API";
                document.Info.Version = "v1";
                document.Info.Description = "API for accessing Factorio game data including meta, state, and map information";
                return Task.CompletedTask;
            });
        });

        // Register CommunicationHandler as singleton for RCON communication
        builder.Services.AddSingleton<ICommunicationHandler>(serviceProvider =>
            new CommunicationHandler(serviceProvider.GetRequiredService<IConfiguration>()));
        
        // Register ActionProcessor
        builder.Services.AddSingleton<IActionProcessor, ActionProcessor>();

        var app = builder.Build();

        // Configure OpenAPI and Scalar UI for all environments (useful for containerized deployment)
        app.MapOpenApi();
        app.MapScalarApiReference();

        var dataApi = app.MapGroup("/data");

        // Strongly-typed meta data endpoint
        dataApi.MapGet("/meta/{agentId:int}", async (int agentId, ICommunicationHandler communicationHandler) =>
        {
            try
            {
                var jsonData = await communicationHandler.GetDataAsync(agentId, DataType.Meta, 150);
                var metaData = JsonSerializer.Deserialize<MetaData>(jsonData, AppJsonSerializerContext.Default.MetaData);
                
                return Results.Ok(metaData);
            }
            catch (Exception ex)
            {
                return Results.BadRequest($"Error parsing meta data: {ex.Message}");
            }
        })
        .WithName("GetMetaData")
        .WithSummary("Get game meta data")
        .WithDescription("Retrieves meta information about the game including items, recipes, and technologies for the specified agent.")
        .Produces<MetaData>(200)
        .ProducesProblem(400);

        // Strongly-typed state data endpoint
        dataApi.MapGet("/state/{agentId:int}", async (int agentId, ICommunicationHandler communicationHandler) =>
        {
            try
            {
                var jsonData = await communicationHandler.GetDataAsync(agentId, DataType.State, 150);
                var stateData = JsonSerializer.Deserialize<StateData>(jsonData, AppJsonSerializerContext.Default.StateData);
                
                return Results.Ok(stateData);
            }
            catch (Exception ex)
            {
                return Results.BadRequest($"Error parsing state data: {ex.Message}");
            }
        })
        .WithName("GetStateData")
        .WithSummary("Get game state data")
        .WithDescription("Retrieves current state information including agent status, buildings, and research progress for the specified agent.")
        .Produces<StateData>(200)
        .ProducesProblem(400);

        // Strongly-typed map data endpoint
        dataApi.MapGet("/map/{agentId:int}", async (int agentId, ICommunicationHandler communicationHandler) =>
        {
            try
            {
                var jsonData = await communicationHandler.GetDataAsync(agentId, DataType.Map, 150);
                var mapData = JsonSerializer.Deserialize<MapData>(jsonData, AppJsonSerializerContext.Default.MapData);
                
                return Results.Ok(mapData);
            }
            catch (Exception ex)
            {
                return Results.BadRequest($"Error parsing map data: {ex.Message}");
            }
        })
        .WithName("GetMapData")
        .WithSummary("Get game map data")
        .WithDescription("Retrieves map information including tile locations and offshore pump positions for the specified agent.")
        .Produces<MapData>(200)
        .ProducesProblem(400);

        // Actions endpoint - moved out of data group
        app.MapPost("/actions", async (ActionsRequest request, IActionProcessor actionProcessor, ICommunicationHandler communicationHandler, ILogger<Program> logger) =>
        {
            try
            {
                logger.LogInformation("=== Actions request received ===");
                
                // Log the raw request for debugging
                logger.LogInformation("Request object is null: {IsNull}", request == null);
                
                if (request != null)
                {
                    logger.LogInformation("AgentActions is null: {IsNull}", request.AgentActions == null);
                    logger.LogInformation("AgentActions count: {Count}", request.AgentActions?.Count ?? -1);
                }

                // Validate request
                if (request?.AgentActions == null || !request.AgentActions.Any())
                {
                    logger.LogWarning("Validation failed: AgentActions is null or empty");
                    return Results.BadRequest(new { error = "AgentActions cannot be null or empty", details = "The request must contain at least one agent with actions" });
                }

                // Log detailed request information
                foreach (var agentActions in request.AgentActions)
                {
                    logger.LogInformation("Processing agent {AgentId} with {ActionCount} actions", 
                        agentActions.AgentId, agentActions.Actions?.Count ?? 0);
                    
                    if (agentActions.Actions != null)
                    {
                        for (int i = 0; i < agentActions.Actions.Count; i++)
                        {
                            var action = agentActions.Actions[i];
                            logger.LogInformation("  Action {Index}: Type='{Type}', Position={Position}, ItemName='{ItemName}', Quantity={Quantity}", 
                                i, action.Type, action.Position, action.ItemName, action.Quantity);
                        }
                    }
                }

                logger.LogInformation("Starting action processing...");
                var processedActions = actionProcessor.ProcessActions(request.AgentActions);
                
                logger.LogInformation("Action processing completed. Processed {AgentCount} agents", processedActions.Count);
                foreach (var kvp in processedActions)
                {
                    logger.LogInformation("Agent {AgentId}: {ActionCount} processed actions", kvp.Key, kvp.Value.Count);
                    for (int i = 0; i < kvp.Value.Count; i++)
                    {
                        logger.LogInformation("  Processed action {Index}: {Action}", i, kvp.Value[i]);
                    }
                }

                logger.LogInformation("Sending actions to communication handler...");
                var result = await communicationHandler.SendActionsAsync(processedActions);
                logger.LogInformation("Actions sent successfully. Result: {Result}", result);
                
                var response = new ActionsResponse 
                { 
                    Message = "Actions processed successfully", 
                    Result = result 
                };
                return Results.Ok(response);
            }
            catch (ArgumentException ex)
            {
                logger.LogError(ex, "Argument validation error in actions endpoint");
                return Results.BadRequest(new { error = "Validation error", details = ex.Message, type = "ArgumentException" });
            }
            catch (JsonException ex)
            {
                logger.LogError(ex, "JSON deserialization error in actions endpoint");
                return Results.BadRequest(new { error = "Invalid JSON format", details = ex.Message, type = "JsonException" });
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Unexpected error in actions endpoint");
                return Results.BadRequest(new { error = "Processing error", details = ex.Message, type = ex.GetType().Name, stackTrace = ex.StackTrace });
            }
        })
        .WithName("ProcessActions")
        .WithSummary("Process game actions")
        .WithDescription("Processes a list of actions for multiple agents. Each agent can have multiple actions that will be executed in sequence.")
        .Produces<ActionsResponse>(200)
        .ProducesProblem(400);

        // Reset endpoint - moved out of data group
        app.MapPost("/reset/{agentCount:int}", async (int agentCount, ICommunicationHandler communicationHandler) =>
        {
            try
            {
                var result = await communicationHandler.ResetAsync(agentCount);
                var response = new ActionsResponse 
                { 
                    Message = "Reset completed successfully", 
                    Result = result 
                };
                return Results.Ok(response);
            }
            catch (Exception ex)
            {
                return Results.BadRequest($"Error resetting game: {ex.Message}");
            }
        })
        .WithName("ResetGame")
        .WithSummary("Reset game state with specified agent count")
        .WithDescription("Resets the game state and creates the specified number of agents.")
        .Produces<ActionsResponse>(200)
        .ProducesProblem(400);

        // Execute actions endpoint
        app.MapPost("/actions/execute", async (ICommunicationHandler communicationHandler, ILogger<Program> logger) =>
        {
            try
            {
                logger.LogInformation("=== Execute actions request received ===");
                
                logger.LogInformation("Executing actions via communication handler...");
                var result = await communicationHandler.ExecuteActionsAsync();
                logger.LogInformation("Actions executed successfully. Result: {Result}", result);
                
                var response = new ActionsResponse 
                { 
                    Message = "Actions executed successfully", 
                    Result = result 
                };
                return Results.Ok(response);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Unexpected error in execute actions endpoint");
                return Results.BadRequest(new { error = "Execution error", details = ex.Message, type = ex.GetType().Name });
            }
        })
        .WithName("ExecuteActions")
        .WithSummary("Execute queued actions")
        .WithDescription("Executes all actions that have been queued for all agents in the game.")
        .Produces<ActionsResponse>(200)
        .ProducesProblem(400);

        app.Run();
    }
}

[JsonSerializable(typeof(MetaData))]
[JsonSerializable(typeof(StateData))]
[JsonSerializable(typeof(MapData))]
[JsonSerializable(typeof(ActionsRequest))]
[JsonSerializable(typeof(ActionsResponse))]
[JsonSerializable(typeof(AgentActions))]
[JsonSerializable(typeof(AgentAction))]
[JsonSerializable(typeof(Microsoft.AspNetCore.Mvc.ProblemDetails))]
internal partial class AppJsonSerializerContext : JsonSerializerContext
{

}
