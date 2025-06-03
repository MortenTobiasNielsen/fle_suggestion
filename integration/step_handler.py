from dataclasses import dataclass
from enum import Enum
from factorio_rcon import RCONClient

@dataclass
class Position:
    x: float
    y: float

    def __str__(self) -> str:
        return f"{{{self.x},{self.y}}}"

class InventoryType(Enum):
    FUEL = "defines.inventory.fuel"
    INPUT = "defines.inventory.input"
    MAIN = "defines.inventory.main"
    CHEST = "defines.inventory.chest"

class Direction(Enum):
    NORTH = "defines.direction.north"
    SOUTH = "defines.direction.south"
    EAST = "defines.direction.east"
    WEST = "defines.direction.west"

class StepHandler:
    def __init__(self, client: RCONClient, character_index: int):
        self.client = client
        self.character_index = character_index

    def _bool(self, b: bool) -> str:
        return "true" if b else "false"

    def _send_step(self, step: str) -> str:
        command = (
            f'/sc remote.call("AICommands", "add_step", '
            f'{self.character_index}, '
            f'{step})'
        )
        return self.client.send_command(command)
    
    def research(self, name: str, cancel: bool = False) -> str:
        step = f'{{"research", "{name}", cancel = {self._bool(cancel)}}}'
        return self._send_step(step)
    
    def walk(self, position: Position) -> str:
        step = f'{{"walk", {position}}}'
        return self._send_step(step)
    
    def take(self, position: Position, name: str, quantity: int, inventory_type: InventoryType) -> str:
        step = f'{{"take", {position}, "{name}", {quantity}, {inventory_type.value}}}'
        return self._send_step(step)
    
    def put(self, position: Position, name: str, quantity: int, inventory_type: InventoryType) -> str:
        step = f'{{"put", {position}, "{name}", {quantity}, {inventory_type.value}}}'
        return self._send_step(step)
    
    def craft(self, name: str, quantity: int, cancel: bool = False) -> str:
        step = f'{{"craft", "{name}", {quantity}, cancel = {self._bool(cancel)}}}'
        return self._send_step(step)

    def build(self, position: Position, name: str, direction: Direction) -> str:
        step = f'{{"build", {position}, "{name}", {direction}}}'
        return self._send_step(step)
    
    def rotate(self, position: Position, reverse: bool = False) -> str:
        step = f'{{"rotate", {position}, {self._bool(reverse)}}}'
        return self._send_step(step)
    
    def mine(self, position: Position, ticks: int) -> str:
        step = f'{{"mine", {position}, {ticks}}}'
        return self._send_step(step)
    
    def recipe(self, position: Position, name: str) -> str:
        step = f'{{"recipe", {position}, "{name}"}}'
        return self._send_step(step)
    
    def idle(self, ticks: int) -> str:
        step = f'{{"idle", {ticks}}}'
        return self._send_step(step)
        