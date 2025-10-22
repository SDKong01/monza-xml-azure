"""
Serializers for OLAP proxy endpoints.
These define the structure of request and response data.
"""

from pydantic import BaseModel
from typing import Any, Dict


class OlapProxyResponse(BaseModel):
    """
    Response model for OLAP proxy.
    This is just a placeholder - the actual response will be raw data from OLAP server.
    """
    message: str = "OLAP proxy response"


class HealthCheckResponse(BaseModel):
    """Response model for health check endpoint"""
    status: str
    olap_server_url: str
