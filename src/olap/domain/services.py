from typing import Dict, Any
from src.datasets.infra.base_repos import BaseMetadataRepo, BaseDataRepo, BaseManager
from src.datasets.infra.clickhouse_obt_repo import ClickHouseManager
from src.datasets.infra.mongo_metadata_repo import MongoMetadataRepo
from src.datasets.infra.mongo_data_repo import MongoDataRepo

from .entities import DatasetFactory, Dataset


def mapper(data: Dict[str, Any]) -> Dataset:
    if data.get("dataset_type") == "obt":
        manager = ClickHouseManager()
        return Dataset.from_dict(metadata=data, manager=manager)
    elif data.get("dataset_type") == "time_series":
        manager = MongoDataRepo()
        return Dataset.from_dict(metadata=data, manager=manager)
    return Dataset.from_dict(metadata=data)


def metadata_mapper(data: Dict[str, Any]) -> Dataset:
    return Dataset.from_dict(metadata=data)


class DatasetServices:
    @staticmethod
    def metadata_repo() -> BaseMetadataRepo:
        return MongoMetadataRepo(mapper=metadata_mapper)

    @staticmethod
    def factory() -> DatasetFactory:
        repo = MongoMetadataRepo(mapper=mapper)
        return DatasetFactory(metadata_repo=repo)
