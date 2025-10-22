from typing import Dict, Any, Callable, List, Tuple, Optional


class Report:
    def __init__(
        self,
        id: str,
        name: str,
    ):
        self.id = id
        self.name = name

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Report":
        return cls(
            id=data.get("id"),
            name=data.get("name"),
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
        }
