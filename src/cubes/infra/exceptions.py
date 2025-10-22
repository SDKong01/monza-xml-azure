from dataclasses import dataclass
from src.shared.domain.exceptions import BaseException


@dataclass
class MetadataNotFoundException(BaseException):
    def __init__(self, detail="Item not found"):
        super().__init__(
            code="datasets.metadata_not_found", detail=detail, status_code=404
        )


@dataclass
class MetadataQueryException(BaseException):
    def __init__(self, detail="Query failed"):
        super().__init__(
            code="datasets.metadata_query_failed", detail=detail, status_code=400
        )
