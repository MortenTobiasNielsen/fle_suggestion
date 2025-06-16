namespace API.Models;

public class ResourcesData
{
    [JsonPropertyName("trees")]
    public List<TreeResource> Trees { get; set; } = [];

    [JsonPropertyName("special")]
    public List<SpecialResource> Special { get; set; } = [];

    [JsonPropertyName("iron-ore")]
    public List<MineableResource> IronOre { get; set; } = [];

    [JsonPropertyName("copper-ore")]
    public List<MineableResource> CopperOre { get; set; } = [];

    [JsonPropertyName("coal")]
    public List<MineableResource> Coal { get; set; } = [];

    [JsonPropertyName("stone")]
    public List<MineableResource> Stone { get; set; } = [];

    [JsonPropertyName("crude-oil")]
    public List<FluidResource> CrudeOil { get; set; } = [];
}

public abstract class ResourceBase
{
    [JsonPropertyName("selection_box")]
    public BoundingBox SelectionBox { get; set; } = new BoundingBox();
}

public class TreeResource : ResourceBase
{
    [JsonPropertyName("mining_time")]
    public double MiningTime { get; set; }

    [JsonPropertyName("output")]
    public List<FixedOutput> Output { get; set; } = [];
}

public class SpecialResource : ResourceBase
{
    [JsonPropertyName("mining_time")]
    public double MiningTime { get; set; }

    [JsonPropertyName("output")]
    public List<VariableOutput> Output { get; set; } = [];
}

public class MineableResource : ResourceBase
{
    [JsonPropertyName("mining_time")]
    public double MiningTime { get; set; }

    [JsonPropertyName("output")]
    public List<FixedOutput> Output { get; set; } = [];

    [JsonPropertyName("amount")]
    public int Amount { get; set; }
}

public class FluidResource : ResourceBase
{
    [JsonPropertyName("amount")]
    public int Amount { get; set; }
}

public class FixedOutput
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("amount")]
    public int Amount { get; set; }

    [JsonPropertyName("probability")]
    public double Probability { get; set; }
}

public class VariableOutput
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("amount_min")]
    public int AmountMin { get; set; }

    [JsonPropertyName("amount_max")]
    public int AmountMax { get; set; }

    [JsonPropertyName("probability")]
    public double Probability { get; set; }
}
