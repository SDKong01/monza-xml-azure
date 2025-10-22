from dataclasses import dataclass
from src.shared.domain.exceptions import BaseException


@dataclass
class CubeNotFound(BaseException):
    def __init__(self, detail="Cube not found"):
        super().__init__(code="cube.not_found", detail=detail, status_code=404)
