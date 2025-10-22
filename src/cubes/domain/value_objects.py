from typing import Dict, Any, Callable, List, Tuple, Optional
from dataclasses import dataclass, field


@dataclass
class Level:
    name: str
    column: str
    type: str = "String"
    uniqueMembers: Optional[bool] = None


@dataclass
class Hierarchy:
    name: Optional[str] = None
    hasAll: bool = True
    allMemberName: Optional[str] = None
    levels: List[Level] = field(default_factory=list)


@dataclass
class Dimension:
    name: str
    hierarchies: List[Hierarchy] = field(default_factory=list)


@dataclass
class Measure:
    name: str
    column: str
    aggregator: str = "sum"
    formatString: Optional[str] = None
