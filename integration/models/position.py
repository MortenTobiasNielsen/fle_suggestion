from dataclasses import dataclass

@dataclass
class Position:
    x: float
    y: float

    def __str__(self) -> str:
        return f"{{{self.x},{self.y}}}"