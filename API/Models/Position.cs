using System.Text.Json.Serialization;

namespace API.Models;

public record Position(
    [property: JsonPropertyName("x")] double X, 
    [property: JsonPropertyName("y")] double Y)
{
    public override string ToString()
    {
        return $"{{x = {X}, y = {Y}}}";
    }
} 