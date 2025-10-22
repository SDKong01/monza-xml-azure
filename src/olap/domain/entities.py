from typing import Dict, Any, Callable, List, Tuple, Optional
from src.datasets.infra.base_repos import (
    Query,
    BaseManager,
    BaseMetadataRepo,
    BaseDataRepo,
)
from .value_objects import MetaData
from .exceptions import DatasetManagerNotFound


class Dataset:
    def __init__(
        self,
        metadata: MetaData,
        manager: Optional[BaseManager] = None,
    ):
        self.metadata = metadata
        self._manager = manager

    @property
    def id(self) -> str:
        return self.metadata.id

    @property
    def objects(self) -> BaseManager:
        # god bless django :)
        if not self._manager:
            raise DatasetManagerNotFound(detail="No manager assigned to this dataset")
        return self._manager

    @property
    def breakpoints(self):
        pass

    @property
    def outliers(self):
        pass

    @property
    def seasonality_and_trends(self):
        pass

    @classmethod
    def from_dict(
        cls, metadata: Dict[str, Any], manager: Optional[BaseManager] = None
    ) -> 'Dataset':
        """
        Create a Dataset instance from a dictionary.
        """
        meta_data = MetaData.from_dict(metadata)
        return cls(meta_data, manager=manager)


class DatasetFactory:
    def __init__(
        self,
        metadata_repo: BaseMetadataRepo,
    ):
        self.metadata_repo = metadata_repo

    def get_from_id(self, datset_id: str) -> Dataset:
        dataset: Dataset = self.metadata_repo.get(id=datset_id)
        return dataset

    def items_from_query(self, query: str):
        """
        Fetch items from the dataset based on a query.
        """
        return self.repo.fetch_items(query)

    def create_from_query(self, query: str) -> Dataset:
        """
        Create a new dataset from a query.
        """
        meta_data = MetaData(id=query, name="Dataset from query")
        return Dataset(meta_data)

    def save(self, dataset: Dataset):
        """
        Save the dataset to the repository.
        """
        self.repo.save(dataset)


class AggregatedDataset:
    def __init__(self, id: str, datasets: List[Dataset]):
        self.datasets = datasets

    @property
    def correlation(self) -> Dict[str, Any]:
        """
        Calculate and return correlation between datasets.
        """
        # Placeholder for correlation logic
        return {}
