from dataclasses import dataclass


@dataclass
class BaseException(Exception):
    code: str
    detail: str
    status_code: int = 400

    def __str__(self):
        return f"{self.code}: {self.detail}"

    def to_response(self):
        return {
            "code": self.code,
            "detail": self.detail,
            "status_code": self.status_code,
        }
