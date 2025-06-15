using API.Models;

namespace API.Services;

public class ActionProcessor : IActionProcessor
{
    public Dictionary<int, List<string>> ProcessActions(List<AgentActions> agentActionsList)
    {
        var actionQueue = new Dictionary<int, List<string>>();
        
        foreach (var agentActions in agentActionsList)
        {
            foreach (var action in agentActions.Actions)
            {
                ProcessSingleAction(agentActions.AgentId, action, actionQueue);
            }
        }

        return actionQueue;
    }

    private static void ProcessSingleAction(int agentId, AgentAction action, Dictionary<int, List<string>> actionQueue)
    {
        var actionString = action.Type.ToLowerInvariant() switch
        {
            "research" => Research(action),
            "cancel_research" => CancelResearch(),
            "walk" => Walk(action),
            "take" => Take(action),
            "put" => Put(action),
            "craft" => Craft(action),
            "cancel_craft" => CancelCraft(action),
            "build" => Build(action),
            "rotate" => Rotate(action),
            "mine" => Mine(action),
            "recipe" => Recipe(action),
            "wait" => Wait(action),
            "drop" => Drop(action),
            "launch_rocket" => LaunchRocket(action),
            "pick_up" => PickUp(action),
            _ => throw new ArgumentException($"Unknown action type: {action.Type}")
        };

        if (!string.IsNullOrEmpty(actionString))
        {
            AddActionToQueue(agentId, actionString, actionQueue);
        }
    }

    private static void AddActionToQueue(int agentId, string action, Dictionary<int, List<string>> actionQueue)
    {
        if (!actionQueue.ContainsKey(agentId))
        {
            actionQueue[agentId] = [];
        }
        actionQueue[agentId].Add(action);
    }

    private static string? Research(AgentAction action)
    {
        if (string.IsNullOrEmpty(action.TechnologyName))
            return null;
        
        return $"{{type = \"research\", technology_name = \"{action.TechnologyName}\"}}";
    }

    private static string CancelResearch()
    {
        return "{type = \"cancel_research\"}";
    }

    private static string? Walk(AgentAction action)
    {
        if (action.Position == null)
            return null;
        
        return $"{{type = \"walk\", destination = {action.Position}}}";
    }

    private static string? Take(AgentAction action)
    {
        if (action.Position == null || string.IsNullOrEmpty(action.ItemName) || 
            !action.Quantity.HasValue || !action.InventoryType.HasValue)
            return null;

        return $"{{type = \"take\", position = {action.Position}, item_name = \"{action.ItemName}\", quantity = {action.Quantity.Value}, inventory_type = {action.InventoryType.Value.GetFactorioValue()}}}";
    }

    private static string? Put(AgentAction action)
    {
        if (action.Position == null || string.IsNullOrEmpty(action.ItemName) || 
            !action.Quantity.HasValue || !action.InventoryType.HasValue)
            return null;

        return $"{{type = \"put\", position = {action.Position}, item_name = \"{action.ItemName}\", quantity = {action.Quantity.Value}, inventory_type = {action.InventoryType.Value.GetFactorioValue()}}}";
    }

    private static string? Craft(AgentAction action)
    {
        if (string.IsNullOrEmpty(action.ItemName) || !action.Quantity.HasValue)
            return null;
        
        return $"{{type = \"craft\", item_name = \"{action.ItemName}\", quantity = {action.Quantity.Value}}}";
    }

    private static string? CancelCraft(AgentAction action)
    {
        if (string.IsNullOrEmpty(action.ItemName) || !action.Quantity.HasValue)
            return null;
        
        return $"{{type = \"cancel_craft\", item_name = \"{action.ItemName}\", quantity = {action.Quantity.Value}}}";
    }

    private static string? Build(AgentAction action)
    {
        if (action.Position == null || string.IsNullOrEmpty(action.ItemName) || 
            !action.Direction.HasValue)
            return null;

        return $"{{type = \"build\", position = {action.Position}, item_name = \"{action.ItemName}\", direction = {action.Direction.Value.GetFactorioValue()}}}";
    }

    private static string? Rotate(AgentAction action)
    {
        if (action.Position == null)
            return null;
        
        var reverse = action.Reverse ?? false;
        return $"{{type = \"rotate\", position = {action.Position}, reverse = {BoolToString(reverse)}}}";
    }

    private static string? Mine(AgentAction action)
    {
        if (action.Position == null || !action.Ticks.HasValue)
            return null;
        
        return $"{{type = \"mine\", position = {action.Position}, ticks = {action.Ticks.Value}}}";
    }

    private static string? Recipe(AgentAction action)
    {
        if (action.Position == null || string.IsNullOrEmpty(action.RecipeName))
            return null;
        
        return $"{{type = \"recipe\", position = {action.Position}, recipe_name = \"{action.RecipeName}\"}}";
    }

    private static string? Wait(AgentAction action)
    {
        if (!action.Ticks.HasValue)
            return null;
        
        return $"{{type = \"wait\", ticks = {action.Ticks.Value}}}";
    }

    private static string? Drop(AgentAction action)
    {
        if (action.Position == null || string.IsNullOrEmpty(action.ItemName))
            return null;
        
        return $"{{type = \"drop\", position = {action.Position}, item_name = \"{action.ItemName}\"}}";
    }

    private static string? LaunchRocket(AgentAction action)
    {
        if (action.Position == null)
            return null;
        
        return $"{{type = \"launch_rocket\", position = {action.Position}}}";
    }

    private static string? PickUp(AgentAction action)
    {
        if (!action.Ticks.HasValue)
            return null;
        
        return $"{{type = \"pick_up\", ticks = {action.Ticks.Value}}}";
    }

    private static string BoolToString(bool value) => value ? "true" : "false";
} 