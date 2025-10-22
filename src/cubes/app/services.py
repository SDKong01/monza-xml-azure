from nest.core import Injectable
from typing import List, Optional, Dict, Any, Tuple

from src.cubes.domain.services import CubeServices
from src.cubes.domain.entities import Cube

from .exceptions import CubeNotFound
from .xml_translator import CubeXMLTranslator


@Injectable
class CubeAppServices:
    def __init__(self):
        self.services = CubeServices

    def list_cubes(
        self,
    ) -> Tuple[List[Cube], int]:
        """
        List cubes with optional filtering, ordering, and pagination.
        """
        return self.services.repo().read()

    def get_cube(self, cube_id: str) -> Optional[Cube]:
        """
        Retrieve a cube by its ID.
        """
        cubes, _ = self.services.repo().read(name=cube_id)
        if not cubes:
            raise CubeNotFound(f"Cube with the given ID {cube_id} does not exist.")
        return cubes[0] if cubes else None

    def update_cube(self, cube_id: str, update_data: Dict[str, Any]) -> Cube:
        """
        Update an existing cube by its ID.
        """
        return self.services.repo().update(cube_id, update_data)

    def create_cube(self, cube: Cube) -> Cube:
        """
        Create a new cube with the provided data.
        """
        xml_string = CubeXMLTranslator(cube).create_cube()
        cube.xml = xml_string
        self.services.repo().create(cube)

        return cube

    def delete_cube(self, cube_id: str) -> None:
        """
        Delete a cube by its ID.
        """
        self.services.repo().delete(cube_id)
