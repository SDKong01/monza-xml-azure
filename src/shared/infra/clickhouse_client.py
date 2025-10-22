from pymongo import MongoClient
from typing import Dict, Optional
import clickhouse_connect
from clickhouse_connect.driver.client import Client as ClickHouseClient
from contextlib import contextmanager
import threading


class ClickHouseConnection:
    _connection_params: Optional[Dict[str, str]] = None
    _lock = threading.Lock()

    @classmethod
    def configure(cls, connection_parameters: Dict[str, str]) -> None:
        with cls._lock:
            cls._connection_params = connection_parameters

    @classmethod
    def get_client(
        cls, connection_parameters: Optional[Dict[str, str]] = None
    ) -> ClickHouseClient:
        params = connection_parameters or cls._connection_params

        if not params:
            raise ValueError(
                "ClickHouse connection parameters not configured. "
                "Call ClickHouseConnection.configure() first."
            )

        # Create a NEW client for each call (thread-safe)
        return clickhouse_connect.get_client(**params)

    @classmethod
    @contextmanager
    def get_client_context(cls, connection_parameters: Optional[Dict[str, str]] = None):
        client = cls.get_client(connection_parameters)
        try:
            yield client
        finally:
            client.close()

    @classmethod
    def close_all(cls) -> None:
        pass
