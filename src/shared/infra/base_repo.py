from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional, Tuple, Callable, Generic, TypeVar, Any

ConnT = TypeVar('ConnT')
T = TypeVar('T')


class BaseRepo(ABC, Generic[ConnT, T]):
    def __init__(
        self, conn: ConnT, mapper: Callable[[Dict[str, Any]], T] = lambda x: x
    ):
        self.conn = conn
        self._map = mapper

    @abstractmethod
    def create(self, item: T) -> T:
        pass

    @abstractmethod
    def read(self, **kwargs) -> Tuple[List[T], int]:
        pass

    @abstractmethod
    def update(self, item_id: Any, item: T) -> T:
        pass

    @abstractmethod
    def delete(self, item_id: Any) -> None:
        pass
