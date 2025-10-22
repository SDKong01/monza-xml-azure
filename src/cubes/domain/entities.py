from typing import Dict, Any, Callable, List, Tuple, Optional
from dataclasses import dataclass, field, asdict

from .value_objects import Dimension, Measure


class Cube:
    def __init__(
        self,
        id: str,
        name: str,
        table: str,
        dimensions: List[Dimension],
        measures: List[Measure],
        xml: str,
    ):
        self.id = id
        self.name = name
        self.table = table
        self.xml = xml
        self.dimensions = dimensions
        self.measures = measures

    @property
    def dimensions_count(self) -> int:
        return len(self.dimensions)

    @property
    def measures_count(self) -> int:
        return len(self.measures)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "table": self.table,
            "xml": self.xml,
            "dimensions": [asdict(dim) for dim in self.dimensions],
            "measures": [asdict(measure) for measure in self.measures],
        }

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "Cube":
        dimensions = [Dimension(**dim) for dim in data.get("dimensions", [])]
        measures = [Measure(**measure) for measure in data.get("measures", [])]
        return Cube(
            id=data["id"],
            name=data["name"],
            table=data["table"],
            xml=data.get("xml", ""),
            dimensions=dimensions,
            measures=measures,
        )
