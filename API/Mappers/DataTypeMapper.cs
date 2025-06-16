namespace API.Mappers;

public static class DataTypeMapper
{
    public static string ToFactorioString(this DataType dataType) => dataType switch
    {
        DataType.Meta => "meta_data",
        DataType.Map => "map_data",
        DataType.State => "state_data",
        _ => throw new ArgumentOutOfRangeException(nameof(dataType))
    };
}