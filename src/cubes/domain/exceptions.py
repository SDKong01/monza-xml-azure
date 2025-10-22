from dataclasses import dataclass
from src.shared.domain.exceptions import BaseException


@dataclass
class DatasetManagerNotFound(BaseException):
    def __init__(self, detail="Manager not found for this dataset"):
        super().__init__(
            code="dataset.manager_not_found", detail=detail, status_code=404
        )
