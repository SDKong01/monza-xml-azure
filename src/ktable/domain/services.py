from typing import Dict, Any
from contextlib import contextmanager
from src.ktable.infra.clickhouse_standard_repo import ClickHouseRepo
from src.ktable.infra.clickhouse_obt_repo import ClickHouseOBTManager
from src.ktable.infra.mongo_dataset_metadata import DatasetMetadataMongoRepo
from src.shared.infra.services import SharedInfraServices
from src.shared.infra.base_repo import BaseRepo, T
from dataclasses import asdict
from .entities import DatasetMetadata


class KtableServices:
    @staticmethod
    @contextmanager
    def standard_repo():
        with SharedInfraServices.get_clickhouse_client_context() as ch_client:
            yield ClickHouseRepo(ch_client)

    @staticmethod
    @contextmanager
    def obt_repo():
        with SharedInfraServices.get_clickhouse_client_context() as ch_client:
            yield ClickHouseOBTManager(ch_client)

    @staticmethod
    def metadata_repo() -> BaseRepo:
        mongo_repo = DatasetMetadataMongoRepo(mapper=lambda doc: DatasetMetadata(**doc))
        return mongo_repo
