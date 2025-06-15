namespace API.Models;

public enum Direction
{
    North = 0,           // defines.direction.north
    Northeast = 1,       // defines.direction.northeast  
    East = 2,            // defines.direction.east
    Southeast = 3,       // defines.direction.southeast
    South = 4,           // defines.direction.south
    Southwest = 5,       // defines.direction.southwest
    West = 6,            // defines.direction.west
    Northwest = 7        // defines.direction.northwest
}

public static class DirectionExtensions
{
    public static string GetFactorioValue(this Direction direction) => direction switch
    {
        Direction.North => "defines.direction.north",
        Direction.Northeast => "defines.direction.northeast",
        Direction.East => "defines.direction.east", 
        Direction.Southeast => "defines.direction.southeast",
        Direction.South => "defines.direction.south",
        Direction.Southwest => "defines.direction.southwest",
        Direction.West => "defines.direction.west",
        Direction.Northwest => "defines.direction.northwest",
        _ => throw new ArgumentOutOfRangeException(nameof(direction))
    };

    public static string ToApiString(this Direction direction) => direction switch
    {
        Direction.North => "north",
        Direction.Northeast => "northeast",
        Direction.East => "east",
        Direction.Southeast => "southeast",
        Direction.South => "south",
        Direction.Southwest => "southwest",
        Direction.West => "west",
        Direction.Northwest => "northwest",
        _ => throw new ArgumentOutOfRangeException(nameof(direction))
    };

    public static Direction FromString(string value) => value?.ToLowerInvariant() switch
    {
        "north" => Direction.North,
        "northeast" => Direction.Northeast,
        "east" => Direction.East,
        "southeast" => Direction.Southeast,
        "south" => Direction.South,
        "southwest" => Direction.Southwest,
        "west" => Direction.West,
        "northwest" => Direction.Northwest,
        _ => throw new ArgumentException($"Invalid direction string: {value}")
    };
} 