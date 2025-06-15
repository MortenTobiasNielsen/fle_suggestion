using System.Text.Json;
using System.Text.Json.Serialization;

namespace API.Models;

public class DirectionJsonConverter : JsonConverter<Direction>
{
    public override Direction Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Number)
        {
            var value = reader.GetInt32();
            if (Enum.IsDefined(typeof(Direction), value))
            {
                return (Direction)value;
            }
            throw new JsonException($"Invalid direction value: {value}");
        }
        else if (reader.TokenType == JsonTokenType.String)
        {
            var stringValue = reader.GetString();
            return DirectionExtensions.FromString(stringValue!);
        }
        throw new JsonException($"Cannot convert {reader.TokenType} to Direction");
    }

    public override void Write(Utf8JsonWriter writer, Direction value, JsonSerializerOptions options)
    {
        writer.WriteStringValue(value.ToApiString());
    }
}

public class DirectionNullableJsonConverter : JsonConverter<Direction?>
{
    public override Direction? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return null;
        }
        
        var converter = new DirectionJsonConverter();
        return converter.Read(ref reader, typeof(Direction), options);
    }

    public override void Write(Utf8JsonWriter writer, Direction? value, JsonSerializerOptions options)
    {
        if (value == null)
        {
            writer.WriteNullValue();
        }
        else
        {
            writer.WriteStringValue(value.Value.ToApiString());
        }
    }
}

public class InventoryTypeJsonConverter : JsonConverter<InventoryType>
{
    public override InventoryType Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Number)
        {
            var value = reader.GetInt32();
            if (Enum.IsDefined(typeof(InventoryType), value))
            {
                return (InventoryType)value;
            }
            throw new JsonException($"Invalid inventory type value: {value}");
        }
        else if (reader.TokenType == JsonTokenType.String)
        {
            var stringValue = reader.GetString();
            return InventoryTypeExtensions.FromString(stringValue!);
        }
        throw new JsonException($"Cannot convert {reader.TokenType} to InventoryType");
    }

    public override void Write(Utf8JsonWriter writer, InventoryType value, JsonSerializerOptions options)
    {
        writer.WriteStringValue(value.ToApiString());
    }
}

public class InventoryTypeNullableJsonConverter : JsonConverter<InventoryType?>
{
    public override InventoryType? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return null;
        }
        
        var converter = new InventoryTypeJsonConverter();
        return converter.Read(ref reader, typeof(InventoryType), options);
    }

    public override void Write(Utf8JsonWriter writer, InventoryType? value, JsonSerializerOptions options)
    {
        if (value == null)
        {
            writer.WriteNullValue();
        }
        else
        {
            writer.WriteStringValue(value.Value.ToApiString());
        }
    }
} 