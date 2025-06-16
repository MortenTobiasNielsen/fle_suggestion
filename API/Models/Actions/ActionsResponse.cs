namespace API.Models;

public class ActionsResponse
{
    [JsonPropertyName("message")]
    public required string Message { get; set; }

    [JsonPropertyName("result")]
    public required string Result { get; set; }
} 