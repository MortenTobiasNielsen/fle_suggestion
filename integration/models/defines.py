from enum import Enum

class Direction(Enum):
    NORTH = "defines.direction.north"
    SOUTH = "defines.direction.south"
    EAST = "defines.direction.east"
    WEST = "defines.direction.west"

class InventoryType(Enum):
    FUEL = "defines.inventory.fuel"
    INPUT = "defines.inventory.input"
    MAIN = "defines.inventory.main"
    CHEST = "defines.inventory.chest"