from typing import List, Optional, Dict, Any
from dataclasses import dataclass


class Ktable:
    def __init__(self, name: str, description: str, created_at: str, updated_at: str):
        self.name = name
        self.created_at = created_at
        self.updated_at = updated_at
        self.description = description


class Subset:
    def __init__(
        self,
        name: str,
        ktable_name: str,
        description: str,
        created_at: str,
        updated_at: str,
        tags: Optional[List[str]] = None,
        owner: Optional[str] = None,
    ):
        self.name = name
        self.ktable_name = ktable_name
        self.description = description
        self.created_at = created_at
        self.updated_at = updated_at
        self.tags = tags or []
        self.owner = owner


@dataclass
class DatasetMetadata:
    name: str
    physical_name: str
    schema_name: str
    created_at: str
    updated_at: str
    owner: Optional[str] = None
    description: Optional[str] = None
    is_ktable: bool = False
    query: Optional[Dict[str, Any]] = None
    tags: Optional[List[str]] = None


@dataclass
class AggDatasetMetadata:
    name: str
    physical_name: str
    description: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]
    owner: Optional[str]
    tags: Optional[List[str]]
