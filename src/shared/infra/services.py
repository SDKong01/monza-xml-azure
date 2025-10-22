from pymongo import MongoClient
from contextlib import contextmanager
from .mongo_client import MongoDBConnection
from .clickhouse_client import ClickHouseConnection
from config import settings


class SharedInfraServices:
    @staticmethod
    def get_sys_general_db() -> MongoClient:
        connection_string = settings.GENERAL_DB_URL
        db = settings.GENERAL_DB_NAME
        return MongoDBConnection.get_client(connection_string)[db]

    @staticmethod
    def get_clickhouse_client():

        return ClickHouseConnection.get_client()

    @staticmethod
    @contextmanager
    def get_clickhouse_client_context():
        with ClickHouseConnection.get_client_context() as client:
            yield client
