import requests
import time
from typing import List, Dict, Any, Optional
from enum import Enum
from models.position import Position
from models.defines import InventoryType, Direction

class DataType(Enum):
    META = "meta_data"
    MAP = "map_data"
    STATE = "state_data"

class CommunicationHandler:
    def __init__(self, api_base_url: str, agent_id: int, timeout: int = 30):
        if not api_base_url:
            raise ValueError("api_base_url cannot be empty")
        if agent_id <= 0:
            raise ValueError("agent_id must be positive")
        if timeout <= 0:
            raise ValueError("timeout must be positive")
            
        self.api_base_url = api_base_url.rstrip('/')
        self.agent_id = agent_id
        self.timeout = timeout
        self.session = requests.Session()
        self.actions: List[Dict[str, Any]] = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    def close(self) -> None:
        """Close the session and clean up resources."""
        if self.session:
            self.session.close()

    def _add_action(self, action: Dict[str, Any]) -> None:
        self.actions.append(action)

    def _validate_quantity(self, quantity: int) -> None:
        if quantity != -1 and quantity <= 0:
            raise ValueError("quantity must be either -1 or positive")

    def _validate_ticks(self, ticks: int) -> None:
        if ticks <= 0:
            raise ValueError("ticks must be positive")

    def send_actions(self) -> str:
        """Send all accumulated actions to the API."""
        if not self.actions:
            raise ValueError("No actions to send")
        
        payload = {
            "agent_actions": [
                {
                    "agent_id": self.agent_id,
                    "actions": self.actions
                }
            ]
        }
        
        try:
            response = self.session.post(
                f"{self.api_base_url}/actions",
                json=payload,
                timeout=self.timeout
            )
            
            # Get detailed error response if available
            if response.status_code != 200:
                try:
                    error_detail = response.text
                    raise Exception(f"Error sending actions: {response.status_code} - {error_detail}")
                except:
                    pass
            
            response.raise_for_status()
            
            # Clear actions after successful send
            self.actions.clear()
            
            return response.text
        except requests.RequestException as e:
            # Get detailed error response if available
            if hasattr(e, 'response') and e.response is not None:
                try:
                    error_detail = e.response.text
                    raise Exception(f"Error sending actions: {e} - Server response: {error_detail}")
                except:
                    pass
            raise Exception(f"Error sending actions: {e}")

    def get_data(self, data_type: DataType) -> Dict[str, Any]:
        """Get data from the API as parsed JSON."""
        try:
            if data_type == DataType.META:
                endpoint = f"/data/meta/{self.agent_id}"
            elif data_type == DataType.MAP:
                endpoint = f"/data/map/{self.agent_id}"
            elif data_type == DataType.STATE:
                endpoint = f"/data/state/{self.agent_id}"
            else:
                raise ValueError(f"Unknown data type: {data_type}")
            
            response = self.session.get(
                f"{self.api_base_url}{endpoint}",
                timeout=self.timeout
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            raise Exception(f"Error getting {data_type.value}: {e}")

    def wait_for_api_ready(self, max_attempts: int = 30, delay: float = 1.0) -> bool:
        """Wait for the API to become available."""
        if max_attempts <= 0:
            raise ValueError("max_attempts must be positive")
        if delay <= 0:
            raise ValueError("delay must be positive")
            
        for attempt in range(max_attempts):
            try:
                response = self.session.get(f"{self.api_base_url}/openapi/v1.json", timeout=self.timeout)
                if response.status_code == 200:
                    return True
            except (requests.ConnectionError, requests.Timeout):
                pass
            
            if attempt < max_attempts - 1:
                time.sleep(delay)
        
        return False

    def reset(self, agent_count: int = 1) -> str:
        """Reset the game state and create the specified number of agents."""
        if agent_count <= 0:
            raise ValueError("agent_count must be positive")
            
        try:
            response = self.session.post(
                f"{self.api_base_url}/reset/{agent_count}",
                timeout=self.timeout
            )
            response.raise_for_status()
            return response.text
        except requests.RequestException as e:
            raise Exception(f"Error resetting game: {e}")

    def execute_actions(self) -> str:
        """Execute all queued actions in the game."""
        try:
            response = self.session.post(
                f"{self.api_base_url}/actions/execute",
                timeout=self.timeout
            )
            response.raise_for_status()
            return response.text
        except requests.RequestException as e:
            raise Exception(f"Error executing actions: {e}")
    
    def research(self, technology_name: str) -> None:
        if not technology_name:
            raise ValueError("technology_name cannot be empty")
        action = {
            "type": "research",
            "technology_name": technology_name
        }
        self._add_action(action)
    
    def cancel_research(self) -> None:
        action = {"type": "cancel_research"}
        self._add_action(action)

    def walk(self, position: Position) -> None:
        if position is None:
            raise ValueError("position cannot be None")
        action = {
            "type": "walk",
            "position": position
        }
        self._add_action(action)
    
    def take(self, position: Position, item_name: str, quantity: int, inventory_type: InventoryType) -> None:
        if position is None:
            raise ValueError("position cannot be None")
        if not item_name:
            raise ValueError("item_name cannot be empty")
        self._validate_quantity(quantity)
        if inventory_type is None:
            raise ValueError("inventory_type cannot be None")
        action = {
            "type": "take",
            "position": position,
            "item_name": item_name,
            "quantity": quantity,
            "inventory_type": inventory_type.value
        }
        self._add_action(action)
    
    def put(self, position: Position, item_name: str, quantity: int, inventory_type: InventoryType) -> None:
        if position is None:
            raise ValueError("position cannot be None")
        if not item_name:
            raise ValueError("item_name cannot be empty")
        self._validate_quantity(quantity)
        if inventory_type is None:
            raise ValueError("inventory_type cannot be None")
        action = {
            "type": "put",
            "position": position,
            "item_name": item_name,
            "quantity": quantity,
            "inventory_type": inventory_type.value
        }
        self._add_action(action)
    
    def craft(self, item_name: str, quantity: int) -> None:
        if not item_name:
            raise ValueError("item_name cannot be empty")
        self._validate_quantity(quantity)
        action = {
            "type": "craft",
            "item_name": item_name,
            "quantity": quantity
        }
        self._add_action(action)

    def cancel_craft(self, item_name: str, quantity: int) -> None:
        if not item_name:
            raise ValueError("item_name cannot be empty")
        self._validate_quantity(quantity)
        action = {
            "type": "cancel_craft",
            "item_name": item_name,
            "quantity": quantity
        }
        self._add_action(action)

    def build(self, position: Position, item_name: str, direction: Direction) -> None:
        if position is None:
            raise ValueError("position cannot be None")
        if not item_name:
            raise ValueError("item_name cannot be empty")
        if direction is None:
            raise ValueError("direction cannot be None")
        action = {
            "type": "build",
            "position": position,
            "item_name": item_name,
            "direction": direction.value
        }
        self._add_action(action)
    
    def rotate(self, position: Position, reverse: bool = False) -> None:
        if position is None:
            raise ValueError("position cannot be None")
        action = {
            "type": "rotate",
            "position": position,
            "reverse": reverse
        }
        self._add_action(action)
    
    def mine(self, position: Position, ticks: int) -> None:
        if position is None:
            raise ValueError("position cannot be None")
        self._validate_ticks(ticks)
        action = {
            "type": "mine",
            "position": position,
            "ticks": ticks
        }
        self._add_action(action)
    
    def recipe(self, position: Position, recipe_name: str) -> None:
        if position is None:
            raise ValueError("position cannot be None")
        if not recipe_name:
            raise ValueError("recipe_name cannot be empty")
        action = {
            "type": "recipe",
            "position": position,
            "recipe_name": recipe_name
        }
        self._add_action(action)
    
    def wait(self, ticks: int) -> None:
        self._validate_ticks(ticks)
        action = {
            "type": "wait",
            "ticks": ticks
        }
        self._add_action(action)

    def drop(self, position: Position, item_name: str) -> None:
        if position is None:
            raise ValueError("position cannot be None")
        if not item_name:
            raise ValueError("item_name cannot be empty")
        action = {
            "type": "drop",
            "position": position,
            "item_name": item_name
        }
        self._add_action(action)
    
    def launch_rocket(self, position: Position) -> None:
        if position is None:
            raise ValueError("position cannot be None")
        action = {
            "type": "launch_rocket",
            "position": position
        }
        self._add_action(action)
    
    def pick_up(self, ticks: int) -> None:
        self._validate_ticks(ticks)
        action = {
            "type": "pick_up",
            "ticks": ticks
        }
        self._add_action(action)
    