import os
import json
from urllib.parse import unquote
from typing import Type, Optional, List, Dict, Any, cast
from fastapi.responses import FileResponse
from nest.core import Controller, Post, Get, Patch, Delete, Put

from src.cubes.app.services import CubeAppServices
from src.cubes.domain.entities import Cube, Dimension, Measure
from .serializers import CubesListSerializer, CubeItemSerializer, CreateCubeRequest
from src.shared.domain.fake_dacite import from_dict

XML_FILE_PATH = os.getenv("XML_FILE_PATH", "./Monza.xml")


@Controller(tag="Cube", prefix="/v2/cube")
class CubeController:
    def __init__(self, service: CubeAppServices):
        self.service: Type[CubeAppServices] = service

    @Get("application/list")
    def legacy_app_list(self) -> List[Dict[str, Any]]:
        """
        Legacy endpoint to list cubes in a simplified format.
        """
        if not os.path.exists(XML_FILE_PATH):
            raise Exception(f"XML file not found at path: {XML_FILE_PATH}")

        return FileResponse(
            path=XML_FILE_PATH, media_type="application/xml", filename="Monza.xml"
        )

    @Get("application/status")
    def legacy_app_status(self) -> None:
        """
        Legacy endpoint to check the status of the application  .
        """
        return

    @Get("/")
    def list_cubes(
        self,
    ) -> CubesListSerializer:
        items, count = self.service.list_cubes()
        serialized_items = [
            CubeItemSerializer(
                id=item.id,
                name=item.name,
                table_name=item.table,
                dimensions_count=item.dimensions_count,
                measures_count=item.measures_count,
            )
            for item in items
        ]
        return CubesListSerializer(total_count=count, data=serialized_items)

    @Get("/{cube_name}")
    def get_cube(self, cube_name: str) -> CubeItemSerializer:
        item = self.service.get_cube(cube_name)
        return CubeItemSerializer(
            id=item.id,
            name=item.name,
            table_name=item.table,
            dimensions_count=item.dimensions_count,
            measures_count=item.measures_count,
        )

    @Post("/")
    def create_cube(self, cube_request: CreateCubeRequest) -> CubeItemSerializer:
        """
        Create a new cube.
        """
        cube = Cube(
            id="id",
            name=cube_request.cube_name,
            table=cube_request.table_name,
            dimensions=[
                from_dict(Dimension, dim.model_dump())
                for dim in cube_request.dimensions
            ],
            measures=[
                from_dict(Measure, measure.model_dump())
                for measure in cube_request.measures
            ],
            xml="",
        )
        cube_response = self.service.create_cube(cube)
        return CubeItemSerializer(
            id=cube_response.id,
            name=cube_response.name,
            table_name=cube_response.table,
            dimensions_count=cube_response.dimensions_count,
            measures_count=cube_response.measures_count,
        )

    @Put("/{cube_id}")
    def update_cube(
        self, cube_id: str, cube_request: CreateCubeRequest
    ) -> CubeItemSerializer:
        """
        Update an existing cube.
        """
        return self.service.update_cube(cube_id, cube_request.dict())

    @Delete("/{cube_id}")
    def delete_cube(self, cube_id: str) -> None:
        """
        Delete a cube by its ID.
        """
        self.service.delete_cube(cube_id)
