namespace API.Models;

public class Agent
{
    [JsonPropertyName("agent_id")]
    public int AgentId { get; set; }

    [JsonPropertyName("position")]
    public Position Position { get; set; } = new(0, 0);

    [JsonPropertyName("inventory")]
    public AgentInventory Inventory { get; set; } = new();

    [JsonPropertyName("walking_state")]
    public bool WalkingState { get; set; }

    [JsonPropertyName("mining")]
    public MiningState Mining { get; set; } = new();

    [JsonPropertyName("crafting")]
    public CraftingState Crafting { get; set; } = new();

    [JsonPropertyName("actions")]
    public ActionHistory Actions { get; set; } = new();
}

public class AgentInventory
{
    [JsonPropertyName("main")]
    public Inventory Main { get; set; } = new();

    [JsonPropertyName("guns")]
    public Inventory Guns { get; set; } = new();

    [JsonPropertyName("ammo")]
    public Inventory Ammo { get; set; } = new();
}

public class MiningState
{
    [JsonPropertyName("speed")]
    public double Speed { get; set; }

    [JsonPropertyName("progress")]
    public double Progress { get; set; }

    [JsonPropertyName("is_mining")]
    public bool IsMining { get; set; }

    [JsonPropertyName("position")]
    public Position Position { get; set; } = new(0, 0);
}

public class CraftingState
{
    [JsonPropertyName("queue")]
    public List<CraftingQueueItem> Queue { get; set; } = [];

    [JsonPropertyName("progress")]
    public double Progress { get; set; }
}

public class CraftingQueueItem
{
    [JsonPropertyName("index")]
    public int Index { get; set; }

    [JsonPropertyName("recipe")]
    public string Recipe { get; set; } = string.Empty;

    [JsonPropertyName("count")]
    public int Count { get; set; }

    [JsonPropertyName("prerequisite")]
    public bool Prerequisite { get; set; }
}

public class ActionHistory
{
    [JsonPropertyName("past_actions")]
    public List<AgentAction> PastActions { get; set; } = [];

    [JsonPropertyName("current_action")]
    public AgentAction? CurrentAction { get; set; }

    [JsonPropertyName("future_actions")]
    public List<AgentAction> FutureActions { get; set; } = [];
}