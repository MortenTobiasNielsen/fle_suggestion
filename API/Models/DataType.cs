namespace API.Models;

public enum DataType
{
    Meta,
    Map,
    State
}

public static class DataTypeExtensions
{
    public static string GetValue(this DataType dataType) => dataType switch
    {
        DataType.Meta => "meta_data",
        DataType.Map => "map_data",
        DataType.State => "state_data",
        _ => throw new ArgumentOutOfRangeException(nameof(dataType))
    };
}