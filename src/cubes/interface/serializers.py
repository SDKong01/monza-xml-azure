from typing import List, Optional, Dict, Any, Tuple, Type
from pydantic import BaseModel, Field
from src.shared.interface.serializers import (
    BasePaginatedResponse,
)


class Level(BaseModel):
    name: str = Field(..., description="Level name")
    column: str = Field(..., description="Level column name")
    type: str = Field(default="String", description="Level type")
    uniqueMembers: Optional[bool] = Field(
        default=None, description="Whether members are unique"
    )


class Hierarchy(BaseModel):
    name: Optional[str] = Field(default=None, description="Hierarchy name")
    hasAll: bool = Field(default=True, description="Whether hierarchy has 'All' member")
    allMemberName: Optional[str] = Field(
        default=None, description="Name of the 'All' member"
    )
    levels: List[Level] = Field(
        ..., min_items=1, description="List of levels in the hierarchy"
    )


class Dimension(BaseModel):
    name: str = Field(..., description="Dimension name")
    hierarchies: List[Hierarchy] = Field(
        ..., min_items=1, description="List of hierarchies"
    )


class Measure(BaseModel):
    name: str = Field(..., description="Measure name")
    column: str = Field(..., description="Measure column name")
    aggregator: str = Field(default="sum", description="Measure aggregator")
    formatString: Optional[str] = Field(
        default=None, description="Format string for the measure"
    )


class CreateCubeRequest(BaseModel):
    cube_name: str = Field(..., description="Name of the cube")
    table_name: str = Field(..., description="Name of the fact table")
    dimensions: List[Dimension] = Field(
        ..., min_items=1, description="List of dimensions"
    )
    measures: List[Measure] = Field(..., min_items=1, description="List of measures")


class CubeItemSerializer(BaseModel):
    id: str
    name: str
    table_name: str
    dimensions_count: int
    measures_count: int


class CubesListSerializer(BasePaginatedResponse):

    total_count: int
    data: List[CubeItemSerializer]
