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
        request += "{"
        for action in self.actions:
            request += action + ","
        request = request[:-1]
        request += "})"
        
        return self.client.send_command(request)

    def get_data(self, data_Type: DataType, radius_to_search: int) -> str:
        return self._send_data_request(data_Type, radius_to_search)
    
    def research(self, technology_name: str) -> str:
        action = f'{{type = "research", technology_name = "{technology_name}"}}'
        self._add_action(action)
    
    def cancel_research(self) -> str:
        action = f'{{type = "cancel_research"}}'
        self._add_action(action)

    def walk(self, position: Position) -> str:
        action = f'{{type = "walk", destination = {position}}}'
        self._add_action(action)
    
    def take(self, position: Position, item_name: str, quantity: int, inventory_type: InventoryType) -> str:
        action = f'{{type = "take", position = {position}, item_name = "{item_name}", quantity = {quantity}, inventory_type = {inventory_type.value}}}'
        self._add_action(action)
    
    def put(self, position: Position, item_name: str, quantity: int, inventory_type: InventoryType) -> str:
        action = f'{{type = "put", position = {position}, item_name = "{item_name}", quantity = {quantity}, inventory_type = {inventory_type.value}}}'
        self._add_action(action)
    
    def craft(self, item_name: str, quantity: int) -> str:
        action = f'{{type = "craft", item_name = "{item_name}", quantity = {quantity}}}'
        self._add_action(action)

    def cancel_craft(self, item_name: str, quantity: int) -> str:
        action = f'{{type = "cancel_craft", item_name = "{item_name}", quantity = {quantity}}}'
        self._add_action(action)

    def build(self, position: Position, item_name: str, direction: Direction) -> str:
        action = f'{{type = "build", position = {position}, item_name = "{item_name}", direction = {direction.value}}}'
        self._add_action(action)
    
    def rotate(self, position: Position, reverse: bool = False) -> str:
        action = f'{{type = "rotate", position = {position}, reverse = {self._bool(reverse)}}}'
        self._add_action(action)
    
    def mine(self, position: Position, ticks: int) -> str:
        action = f'{{type = "mine", position = {position}, ticks = {ticks}}}'
        self._add_action(action)
    
    def recipe(self, position: Position, recipe_name: str) -> str:
        action = f'{{type = "recipe", position = {position}, recipe_name = "{recipe_name}"}}'
        self._add_action(action)
    
    def wait(self, ticks: int) -> str:
        action = f'{{type = "wait", ticks = {ticks}}}'
        self._add_action(action)

    def drop(self, position: Position, item_name: str) -> str:
        action = f'{{type = "drop", position = {position}, item_name = "{item_name}"}}'
        self._add_action(action)
    
    def launch_rocket(self, position: Position) -> str:
        action = f'{{type = "launch_rocket", position = {position}}}'
        self._add_action(action)
    
    def pick_up(self, ticks: int) -> str:
        action = f'{{type = "pick_up", ticks = {ticks}}}'
        self._add_action(action)
    