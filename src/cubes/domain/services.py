from typing import Dict, Any
from src.cubes.infra.mongo_cube_repo import MongoCubeRepo
from src.shared.infra.base_repo import BaseRepo

from dataclasses import asdict

from .entities import Cube


class CubeServices:
    @staticmethod
    def repo() -> BaseRepo:
        return MongoCubeRepo(mapper=Cube.from_dict)
