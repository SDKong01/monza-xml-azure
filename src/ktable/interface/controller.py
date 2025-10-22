import json
from urllib.parse import unquote
from typing import Type, Optional, List, Dict, Any, cast
from nest.core import Controller, Post, Get, Patch, Delete, Put

from src.ktable.app.services import KtableAppServices, SubsetAppServices
from src.shared.domain.fake_dacite import from_dict
from .serializers import SubsetResponseSerializer, SubsetListResponseSerializer


@Controller(tag="Ktables", prefix="/v2/ktable")
class KtableController:
    def __init__(self, service: KtableAppServices):
        self.service: Type[KtableAppServices] = service

    @Get("/{schema_name}")
    def list_ktables(self, schema_name: str):
        items = self.service.list_ktable(schema_name)
        return {
            "status": "success",
            "schema": schema_name,
            "tables_found": len(items),
            "tables": items,
            "query": f"SELECT name as table_name\n        FROM system.tables \n        WHERE database = '{schema_name}' \n        AND name LIKE '%_k%'\n        ORDER BY name",
        }

    @Get("/{schema_name}/{ktable_name}/columns")
    def get_ktable_columns(self, schema_name: str, ktable_name: str):
        items = self.service.get_ktable_columns(schema_name, ktable_name)
        return {
            "status": "success",
            "schema": schema_name,
            "table": ktable_name,
            "columns_found": len(items),
            "columns": items,
        }

    @Get("/{schema_name}/{ktable_name}/{column_name}/stats_legacy")
    def get_ktable_column_stats(
        self, schema_name: str, ktable_name: str, column_name: str
    ):
        return self.service.get_ktable_column_stats(
            schema_name, ktable_name, column_name
        )

    @Get("/{schema_name}/{ktable_name}/stats")
    def get_ktable_stats(
        self, schema_name: str, ktable_name: str, query_params: Optional[str] = None
    ):
        decoded_query = unquote(query_params) if query_params else "{}"
        query_dict = json.loads(decoded_query)
        return self.service.get_ktable_stats(schema_name, ktable_name, query_dict)

    @Get("/{schema_name}/{ktable_name}/data")
    def get_ktable_data(
        self, schema_name: str, ktable_name: str, query_params: Optional[str] = None
    ):
        decoded_query = unquote(query_params) if query_params else "{}"
        query_dict = json.loads(decoded_query)
        return self.service.get_ktable_data(schema_name, ktable_name, query_dict)


@Controller(tag="Ktables", prefix="/v2/subset")
class SubsetController:
    def __init__(self, service: SubsetAppServices):
        self.service: Type[SubsetAppServices] = service

    @Post("/subset")
    def create_subset(
        self, name: str, query: Dict[str, Any], description: Optional[str] = None
    ) -> SubsetResponseSerializer:
        """
        Create a new report.
        """
        item = self.service.create_subset(name, query, description)
        return SubsetResponseSerializer.model_validate(item)

    @Get("/")
    def list_subsets(
        self, schema_name: str, prefix: Optional[str] = None
    ) -> SubsetListResponseSerializer:
        """
        List subsets with optional filtering, ordering, and pagination.
        """
        # TODO: Add pagination parameters
        items = self.service.list_subsets(schema_name, prefix)
        serialized_items = [
            SubsetResponseSerializer.model_validate(item) for item in items
        ]
        return SubsetListResponseSerializer.model_validate({"data": serialized_items})

    @Get("/{schema_name}/{view_name}/data")
    def get_subset_data(
        self, schema_name: str, view_name: str, query_params: Optional[str] = None
    ):
        """
        Get subset data based on query parameters.
        """
        return self.service.get_subset_data(schema_name, view_name)

    # @Get("/{view_name}/stats")
    # def get_subset_stats(self, view_name: str, query_params: Optional[str] = None):
    #     """
    #     Get subset stats based on query parameters.
    #     """
    #     decoded_query = unquote(query_params) if query_params else "{}"
    #     query_dict = json.loads(decoded_query)
    #     return self.service.get_subset_stats(view_name, query_dict)
