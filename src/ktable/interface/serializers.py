from typing import List, Optional, Dict, Any, Tuple, Type
from pydantic import BaseModel, Field
from src.shared.interface.serializers import (
    BasePaginatedResponse,
)


class SubsetResponseSerializer(BaseModel):
    name: str
    physical_name: str
    description: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]
    owner: Optional[str]
    tags: Optional[List[str]]

    class Config:
        from_attributes = True


class SubsetListResponseSerializer(BasePaginatedResponse):
    data: List[SubsetResponseSerializer] = Field(default_factory=list)
