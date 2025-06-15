class Position(dict):
    """Position class that's directly JSON-serializable."""
    
    def __init__(self, x: float, y: float):
        super().__init__(x=x, y=y)
        self.x = x
        self.y = y

    def __str__(self) -> str:
        return f"{{x = {self.x}, y = {self.y}}}"