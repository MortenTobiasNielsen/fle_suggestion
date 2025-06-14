using System.Text.Json.Serialization;

namespace API.Models;

public class ElectricityData
{
    [JsonPropertyName("production")]
    public double Production { get; set; }

    [JsonPropertyName("capacity")]
    public double Capacity { get; set; }
}