from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List, Union, TypeVar, Generic, Tuple
from dataclasses import dataclass, field


@dataclass()
class Filter:
    field: str
    operator: str
    value: Union[str, Dict, List[str], None]


@dataclass()
class Query:
    filters: List[Filter] = field(default_factory=list)
    exclude: Optional[List[Filter]] = None
    order_by: Optional[str] = None
    group_by: Optional[Union[str, List[str]]] = None
    limit: Optional[int] = None
    offset: Optional[int] = None
    headers: Optional[Dict[str, Union[str, Dict[str, str], List[str], None]]] = None
    fields: Optional[List[Union[str, Filter]]] = None
    fields_detail: Optional[Dict[str, Union[str, Dict[str, str], List[str], None]]] = (
        None
    )
    raw_query: Optional[Union[str, Dict[str, str], List[str], None]] = None
    to_insert: Optional[Union[Dict[str, Any], List[Any]]] = None
    schema: Optional[str] = None
    table: Optional[str] = None
    date_column: Optional[str] = None
    pivot: Optional[List[Dict[str, str]]] = None
    pivots: Optional[List[Dict[str, str]]] = None
    pivot_columns: Optional[List[str]] = None
    distinct_field: Optional[str] = None
    columns_only: Optional[List[str]] = None


def query_factory(query: Dict[str, Any]) -> Query:
    """
    Factory function to create a Query object from a dictionary.
    """
    filters = query.get("filters", [])
    filters = [Filter(**f) for f in filters]
    query["filters"] = filters
    return Query(**query)


class BaseManager(ABC):
    def __init__(self):
        self.query = None
        self._fields = ["*"]
        self._filters = []
        self._order_by = "ORDER BY 1"
        self.pivots = []

    table_alias = "gm"
    subset_alias = "sb"

    finish_query = ""

    EQUAL = "eq"
    NOT_EQUAL = "neq"
    GREATER_THAN = "gt"
    GREATER_THAN_EQUAL = "gte"
    LESS_THAN = "lt"
    LESS_THAN_EQUAL = "lte"
    IN = "in"
    NOT_IN = "nin"
    LIKE = "like"
    NOT_LIKE = "nlike"
    SUM_GROUP = "sum_group"

    operators_translation = {
        EQUAL: "=",
        NOT_EQUAL: "!=",
        GREATER_THAN: ">",
        GREATER_THAN_EQUAL: ">=",
        LESS_THAN: "<",
        LESS_THAN_EQUAL: "<=",
        IN: "IN",
        NOT_IN: "NOT IN",
        LIKE: "LIKE",
        NOT_LIKE: "NOT LIKE",
    }

    aggregators_translation = {
        "count": "COUNT",
        "sum": "SUM",
        "avg": "AVG",
        "max": "MAX",
        "min": "MIN",
    }

    @abstractmethod
    def stats(self, **kwargs) -> Dict[str, Any]:
        """Calculate and return statistics for the OBT dataset."""
        pass

    @abstractmethod
    def run_query(self, query: Query, **kwargs) -> Dict[str, Any]:
        """Run a query on the OBT dataset and return the results."""
        pass


T = TypeVar("T")


class BaseMetadataRepo(ABC, Generic[T]):
    @abstractmethod
    def create(self, data: T) -> T:
        """Save metadata to the repository."""
        pass

    @abstractmethod
    def get(self, id: str) -> T:
        """Retrieve metadata by its identifier."""
        pass

    @abstractmethod
    def list(
        self,
        limit: int = 20,
        offset: int = 0,
        order_by: str = None,
        filters: Dict[str, Any] = None,
    ) -> List[T]:
        """List metadata entries with optional filters."""
        pass

    @abstractmethod
    def delete(self, id: str) -> None:
        """Delete metadata by its identifier."""
        pass

    @abstractmethod
    def upsert(self, data: T) -> T:
        """Update existing metadata or create a new one."""
        pass


class BaseDataRepo(ABC):
    @abstractmethod
    def create(self, dataset_hash: str, data: List[Dict[str, Any]]) -> None:
        """Save metadata to the repository."""
        pass

    @abstractmethod
    def list(
        self,
        dataset_hash: str,
        filters: Dict[str, Any] = None,
        order_by: str = None,
    ) -> Tuple[List[Dict[str, Any]], int]:
        """List metadata entries with optional filters."""
        pass
