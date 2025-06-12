from enum import Enum
from factorio_rcon import RCONClient
from models.position import Position
from models.defines import InventoryType, Direction

class DataType(Enum):
    META = "meta_data"
    MAP = "map_data"
    STATE = "state_data"

class CommunicationHandler:
    def __init__(self, client: RCONClient, agent_id: int):
        self.client = client
        self.agent_id = agent_id
        self.actions = []

    def _bool(self, b: bool) -> str:
        return "true" if b else "false"

    def _add_action(self, action: str) -> None:
        self.actions.append(action)

    def _send_data_request(self, data_type: DataType, radius_to_search: int) -> str:
        command = (
            f'/sc remote.call("FLE", "{data_type.value}", {self.agent_id}, {radius_to_search})'
        )
        return self.client.send_command(command)
    
    def send_actions(self) -> str:
        request = f'/sc remote.call("FLE", "add_actions", {self.agent_id}, '
        request = request + "{"

        for action in self.actions:
            request = request + action + "," 

        request = request + "})"

        return self.client.send_command(request)

    def get_data(self, data_Type: DataType, radius_to_search: int) -> str:
        return self._send_data_request(data_Type, radius_to_search)
    
    def research(self, name: str, cancel: bool = False) -> str:
        action = f'{{"research", "{name}", cancel = {self._bool(cancel)}}}'
        self._add_action(action)
    
    def walk(self, position: Position) -> str:
        action = f'{{"walk", {position}}}'
        self._add_action(action)
    
    def take(self, position: Position, name: str, quantity: int, inventory_type: InventoryType) -> str:
        action = f'{{"take", {position}, "{name}", {quantity}, {inventory_type.value}}}'
        self._add_action(action)
    
    def put(self, position: Position, name: str, quantity: int, inventory_type: InventoryType) -> str:
        action = f'{{"put", {position}, "{name}", {quantity}, {inventory_type.value}}}'
        self._add_action(action)
    
    def craft(self, name: str, quantity: int, cancel: bool = False) -> str:
        action = f'{{"craft", "{name}", {quantity}, cancel = {self._bool(cancel)}}}'
        self._add_action(action)

    def build(self, position: Position, name: str, direction: Direction) -> str:
        action = f'{{"build", {position}, "{name}", {direction.value}}}'
        self._add_action(action)
    
    def rotate(self, position: Position, reverse: bool = False) -> str:
        action = f'{{"rotate", {position}, {self._bool(reverse)}}}'
        self._add_action(action)
    
    def mine(self, position: Position, ticks: int) -> str:
        action = f'{{"mine", {position}, {ticks}}}'
        self._add_action(action)
    
    def recipe(self, position: Position, name: str) -> str:
        action = f'{{"recipe", {position}, "{name}"}}'
        self._add_action(action)
    
    def wait(self, ticks: int) -> str:
        action = f'{{"wait", {ticks}}}'
        self._add_action(action)
    