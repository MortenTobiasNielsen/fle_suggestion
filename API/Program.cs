using System.Text.Json.Serialization;
using API.Services;
using API.Models;
using System.Text.Json;
using Scalar.AspNetCore;

namespace API;

public class Program
{
    public static void Main(string[] args)
    {
            var builder = WebApplication.CreateSlimBuilder(args);

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

    // Register CommunicationHandler as singleton since it now handles multiple agents
    builder.Services.AddSingleton<ICommunicationHandler>(serviceProvider =>
        new CommunicationHandler(serviceProvider.GetRequiredService<IConfiguration>()));

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

        app.Run();
    }
}

[JsonSerializable(typeof(MetaData))]
[JsonSerializable(typeof(StateData))]
[JsonSerializable(typeof(MapData))]
[JsonSerializable(typeof(Microsoft.AspNetCore.Mvc.ProblemDetails))]
internal partial class AppJsonSerializerContext : JsonSerializerContext
{

}
