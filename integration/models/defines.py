from enum import Enum

class Direction(Enum):
    NORTH = "north"
    SOUTH = "south"
    EAST = "east"
    WEST = "west"

class InventoryType(Enum):
    FUEL = "fuel"
    INPUT = "input"
    MAIN = "main"
    CHEST = "chest"