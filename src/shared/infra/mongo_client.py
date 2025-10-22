from pymongo import MongoClient
from typing import Dict


class MongoDBConnection:
    _clients: Dict[str, MongoClient] = {}

    @classmethod
    def get_client(cls, connection_string: str) -> MongoClient:
        if connection_string not in cls._clients:
            cls._clients[connection_string] = MongoClient(connection_string)
        return cls._clients[connection_string]

    @classmethod
    def close_all(cls) -> None:
        for client in cls._clients.values():
            client.close()
        cls._clients.clear()
