import os
import re
from typing import Tuple

from models.position import Position
from models.defines import InventoryType, Direction
from communication_handler import CommunicationHandler

class StepParser:

    def __init__(self, path, communication_handler: CommunicationHandler):
        self.path = path
        self.communication_handler = communication_handler

    _direction_re = re.compile(r"defines\.direction\.([A-Za-z_][A-Za-z0-9_]*)")
    _inventory_re = re.compile(r"defines\.inventory\.([A-Za-z_][A-Za-z0-9_]*)")

    def _find_last(self, remaining_step: str) -> str:
        close_brace = remaining_step.find('}')
        found = remaining_step[1 : close_brace]

        return found.strip()

    def _find_between_commas(self, remaining_step: str) -> Tuple[str, str]:
        remaining = remaining_step.strip()

        first = remaining.find(',')
        if first == -1:
            return "", ""
        second = remaining.find(',', first + 1)
        if second == -1:
            return "", ""
        
        found = remaining[first + 1 : second]
        remaining = remaining[second + 1 :].lstrip()

        return found, remaining

    def _find_between_quotes(self, remaining_step: str) -> Tuple[str, str]:
        remaining = remaining_step.strip()

        first = remaining.find('"')
        if first == -1:
            return "", ""
        second = remaining.find('"', first + 1)
        if second == -1:
            return "", ""
        
        found = remaining[first + 1 : second]
        remaining = remaining[second + 1 :].lstrip()

        return found, remaining
    
    def _find_between_bracers(self, remaining_step: str) -> Tuple[str, str]:
        remaining = remaining_step.strip()

        first = remaining.find('[')
        if first == -1:
            return "", ""
        second = remaining.find(']', first + 1)
        if second == -1:
            return "", ""
        
        found = remaining[first + 1 : second]
        remaining = remaining[second + 1 :].lstrip()

        return found, remaining
    
    def _find_between_curly_bracers(self, remaining_step:str) -> Tuple[Position, str]:
        open_brace = remaining_step.find('{')
        if open_brace == -1:
            raise ValueError("No opening brace for first coords found")

        close_brace = remaining_step.find('}', open_brace + 1)
        if close_brace == -1:
            raise ValueError("No closing brace for first coords found")

        position_str = remaining_step[open_brace + 1 : close_brace]
        x1_str, y1_str = position_str.split(',', 1)

        position = Position(float(x1_str), float(y1_str))
        remaining = remaining_step[close_brace + 1 :].lstrip()

        return position, remaining
    
    def _find_direction_definition(self, remaining_step: str) -> Tuple[str, str]:
        match = self._direction_re.search(remaining_step)
        if not match:
            raise ValueError("No direction found")

        direction = match.group(1)
        remainder = remaining_step[match.end():].lstrip()

        return direction, remainder
    
    def _find_inventory_definition(self, remaining_step: str) -> Tuple[str, str]:
        match = self._inventory_re.search(remaining_step)
        if not match:
            raise ValueError("No inventory found")

        inventory = match.group(1)
        remainder = remaining_step[match.end():].lstrip()

        return inventory, remainder

    def parse(self):
        if os.path.exists(self.path):
            with open(self.path, "r", encoding="utf-8") as steps_file:
                processed = 0
                for line in steps_file:
                    line = line.strip()

                    if not line or line.startswith("--"):  # skip empty lines and Lua comments
                        continue
                    else:
                        step_number, remaining = self._find_between_bracers(line)
                        if step_number == "":
                            continue

                        type, remaining = self._find_between_quotes(remaining)
                        if type == "walk":
                            position, remaining = self._find_between_curly_bracers(remaining)

                            result = self.communication_handler.walk(position)

                        elif type == "build":
                            position, remaining = self._find_between_curly_bracers(remaining)
                            name, remaining = self._find_between_quotes(remaining)

                            direction_definition, remaining = self._find_direction_definition(remaining)
                            direction = Direction.NORTH
                            if direction_definition == "south":
                                direction = Direction.SOUTH
                            elif direction_definition == "east": 
                                direction = Direction.EAST
                            elif direction_definition == "west":
                                direction = Direction.WEST

                            result = self.communication_handler.build(position, name, direction)

                        elif type == "recipe":
                            position, remaining = self._find_between_curly_bracers(remaining)
                            name, remaining = self._find_between_quotes(remaining)

                            result = self.communication_handler.recipe(position, name)

                        elif type == "put":
                            position, remaining = self._find_between_curly_bracers(remaining)
                            name, remaining = self._find_between_quotes(remaining)
                            quantity, remaining = self._find_between_commas(remaining)
                            quantity = int(quantity)

                            inventory_definition, remaining = self._find_inventory_definition(remaining)
                            inventory = InventoryType.MAIN
                            if inventory_definition == "fuel":
                                inventory = InventoryType.FUEL
                            elif inventory_definition == "chest": 
                                inventory = InventoryType.CHEST

                            result = self.communication_handler.put(position, name, quantity, inventory)

                        elif type == "take":
                            position, remaining = self._find_between_curly_bracers(remaining)
                            name, remaining = self._find_between_quotes(remaining)
                            quantity, remaining = self._find_between_commas(remaining)
                            quantity = int(quantity)

                            inventory_definition, remaining = self._find_inventory_definition(remaining)
                            inventory = InventoryType.MAIN
                            if inventory_definition == "fuel":
                                inventory = InventoryType.FUEL
                            elif inventory_definition == "chest": 
                                inventory = InventoryType.CHEST

                            result = self.communication_handler.take(position, name, quantity, inventory)

                        elif type == "rotate":
                            position, remaining = self._find_between_curly_bracers(remaining)
                            reverse_str = self._find_last(remaining)

                            reverse = False
                            if reverse_str == "true":
                                reverse = True

                            result = self.communication_handler.rotate(position, reverse)

                        elif type == "idle":
                            ticks = self._find_last(remaining)
                            ticks = int(ticks)

                            result = self.communication_handler.wait(ticks)

                        elif type == "mine":
                            position, remaining = self._find_between_curly_bracers(remaining)
                            ticks = self._find_last(remaining)
                            ticks = int(ticks)

                            result = self.communication_handler.mine(position, ticks)

                        elif type == "craft":
                            quantity, remaining = self._find_between_commas(remaining)
                            quantity = int(quantity)
                            name, remaining = self._find_between_quotes(remaining)

                            result = self.communication_handler.craft(name, quantity)
                        elif type == "tech":
                            name, remaining = self._find_between_quotes(remaining)

                            result = self.communication_handler.research(name)

                        else:
                            test = 1

                self.communication_handler.send_actions()
        else:
            return "Path doesn't exist."
        