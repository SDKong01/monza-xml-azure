from typing import List, Optional, Dict, Any, Tuple, Type
from pydantic import BaseModel, Field
from src.shared.interface.serializers import (
    BasePaginatedResponse,
)


class CreateReportRequest(BaseModel):
    name: str = Field(..., description="Name of the cube")


class ReportItemSerializer(BaseModel):
    id: str
    name: str


class ReportsListSerializer(BasePaginatedResponse):

    total_count: int
    data: List[ReportItemSerializer]
