from dataclasses import dataclass
from typing import Dict, Any, Optional, List
from uuid import UUID
from enum import Enum
from abc import ABC, abstractmethod


class DatasetType(Enum):
    OBT = "obt"
    EXTERNAL = "external"
    DERIVED = "derived"


class DataModelingType(Enum):
    OBT = "obt"
    DIMMENSIONAL = "dimensional"


@dataclass
class MetaData:
    id: str
    name: str
    dataset_type: DatasetType
    description: Optional[str]
    date_column: Optional[str]
    date_grain: Optional[str]
    begin_date: Optional[str]
    end_date: Optional[str]
    target_columns: Optional[List[str]]
    default_forecast: Optional[int]
    owner: Optional[str]
    tags: Optional[List[str]]
    stats: Optional[dict]
    collection_name: Optional[str]
    data_modeling: Optional[DataModelingType]
    is_active: Optional[bool]
    created_at: Optional[str]
    updated_at: Optional[str]
    rows_count: Optional[int] = None
    outliers: Optional[List[str]] = None
    features: Optional[List[str]] = None
    breakpoints: Optional[List[str]] = None
    columns_count: Optional[int] = None
    default_target_column: Optional[str] = None
    default_training_percentage: Optional[float] = None

    @classmethod
    def from_dict(cls, data: dict):
        field_names = {f.name for f in cls.__dataclass_fields__.values()}
        filtered_data = {k: v for k, v in data.items() if k in field_names}
        return cls(**filtered_data)


@dataclass
class MetricsAggregation:
    mape: Optional[float] = None
    r2: Optional[float] = None
