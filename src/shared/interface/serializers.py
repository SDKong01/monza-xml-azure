from typing import Optional, Type
from pydantic import BaseModel, create_model


class BasePaginatedResponse(BaseModel):
    """
    Base response model for API responses.
    """

    total_count: Optional[int] = None
    page: Optional[int] = 1
    page_size: Optional[int] = 10
    pages: Optional[int] = None
    next_page: Optional[str] = None
    previous_page: Optional[str] = None
    data: Optional[dict] = None
    bff: Optional[dict] = None


class BaseResponseSuccess(BaseModel):
    """
    Base response model for API success responses.
    """

    data: dict
    bff: Optional[dict] = None


class BaseResponseError(BaseModel):
    """
    Base response model for API error responses.
    """

    detail: str
    status_code: int
    code: str


class RequestFilters(BaseModel):
    """
    Base model for request filters.
    """

    page: int = 1
    limit: int = 10
    sort: Optional[str] = None
    order_by: Optional[str] = None
    filter: Optional[str] = None


def basemodel_from_dataclass(dc_cls) -> BaseModel:
    fields = {f.name: (f.type, ...) for f in dc_cls.__dataclass_fields__.values()}
    return create_model(dc_cls.__name__ + "Model", **fields)
