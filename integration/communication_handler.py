from enum import Enum
from factorio_rcon import RCONClient
from models.position import Position
from models.defines import InventoryType, Direction

class DataType(Enum):
    META = "meta_data"
    MAP = "map_data"
    STATE = "state_data"

class CommunicationHandler:
    def __init__(self, client: RCONClient, character_index: int):
        self.client = client
        self.character_index = character_index
        self.steps = []

    def _bool(self, b: bool) -> str:
        return "true" if b else "false"

    def _add_step(self, step: str) -> None:
        self.steps.append(step)

    def _send_data_request(self, data_type: DataType, radius_to_search: int) -> str:
        command = (
            f'/sc remote.call("FLE", "{data_type.value}", {self.character_index}, {radius_to_search})'
        )
        return self.client.send_command(command)
    
    def send_steps(self) -> str:
        request = f'/sc remote.call("FLE", "add_steps", {self.character_index}, '
        request = request + "{"

        for step in self.steps:
            request = request + step + "," 

        request = request + "})"

        return self.client.send_command(request)

    def get_data(self, data_Type: DataType, radius_to_search: int) -> str:
        return self._send_data_request(data_Type, radius_to_search)
    
    def research(self, name: str, cancel: bool = False) -> str:
        step = f'{{"research", "{name}", cancel = {self._bool(cancel)}}}'
        self._add_step(step)
    
    def walk(self, position: Position) -> str:
        step = f'{{"walk", {position}}}'
        self._add_step(step)
    
    def take(self, position: Position, name: str, quantity: int, inventory_type: InventoryType) -> str:
        step = f'{{"take", {position}, "{name}", {quantity}, {inventory_type.value}}}'
        self._add_step(step)
    
    def put(self, position: Position, name: str, quantity: int, inventory_type: InventoryType) -> str:
        step = f'{{"put", {position}, "{name}", {quantity}, {inventory_type.value}}}'
        self._add_step(step)
    
    def craft(self, name: str, quantity: int, cancel: bool = False) -> str:
        step = f'{{"craft", "{name}", {quantity}, cancel = {self._bool(cancel)}}}'
        self._add_step(step)

    def build(self, position: Position, name: str, direction: Direction) -> str:
        step = f'{{"build", {position}, "{name}", {direction.value}}}'
        self._add_step(step)
    
    def rotate(self, position: Position, reverse: bool = False) -> str:
        step = f'{{"rotate", {position}, {self._bool(reverse)}}}'
        self._add_step(step)
    
    def mine(self, position: Position, ticks: int) -> str:
        step = f'{{"mine", {position}, {ticks}}}'
        self._add_step(step)
    
    def recipe(self, position: Position, name: str) -> str:
        step = f'{{"recipe", {position}, "{name}"}}'
        self._add_step(step)
    
    def idle(self, ticks: int) -> str:
        step = f'{{"idle", {ticks}}}'
        self._add_step(step)
    