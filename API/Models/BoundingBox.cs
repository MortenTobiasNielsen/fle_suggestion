namespace API.Models;

public class BoundingBox
{
    [JsonPropertyName("left_top")]
    public Position LeftTop { get; set; } = new(0, 0);

    [JsonPropertyName("right_bottom")]
    public Position RightBottom { get; set; } = new(0, 0);
}