from nest.core import Injectable
from typing import List, Optional, Dict, Any, Tuple
from src.ktable.infra.base_repos import query_factory
from src.ktable.domain.services import KtableServices
from src.ktable.domain.entities import DatasetMetadata, AggDatasetMetadata


@Injectable
class KtableAppServices:
    def __init__(self):
        self.services = KtableServices

    def list_ktable(self, schema_name: str):
        """
        List cubes with optional filtering, ordering, and pagination.
        """
        with self.services.standard_repo() as repo:
            return repo.list_ktables(schema_name)

    def get_ktable_columns(self, schema_name: str, ktable_name: str):
        with self.services.standard_repo() as repo:
            return repo.list_columns(schema_name, ktable_name)

    def get_ktable_column_stats(
        self, schema_name: str, ktable_name: str, column_name: Optional[str] = None
    ):
        with self.services.standard_repo() as repo:
            if column_name:
                return repo.column_stats(schema_name, ktable_name, column_name)
            else:
                return repo.table_stats(schema_name, ktable_name)

    def get_ktable_stats(
        self, schema_name: str, ktable_name: str, query_params: Dict[str, Any]
    ):
        """
        Get ktable data based on query parameters.
        """
        query = query_factory(query_params)
        query.schema = schema_name
        query.table = ktable_name
        with self.services.obt_repo() as repo:
            return repo.stats(query=query)

    def get_ktable_data(
        self, schema_name: str, ktable_name: str, query_params: Dict[str, Any]
    ):
        """
        Get ktable data based on query parameters.
        """
        query = query_factory(query_params)
        query.schema = schema_name
        query.table = ktable_name
        with self.services.obt_repo() as repo:
            return repo.run_query(query=query)


@Injectable
class SubsetAppServices:
    def __init__(self):
        self.services = KtableServices
        self.metadata_repo = self.services.metadata_repo()

    def list_subsets(self, schema_name: str = None, prefix: Optional[str] = None):
        """
        List subsets with optional filtering, ordering, and pagination.
        """
        with self.services.standard_repo() as repo:
            physical_subsets = repo.list_views(schema_name)

        if prefix:
            physical_subsets = [i for i in physical_subsets if i.startswith(prefix)]
        metadata_subsets = self.metadata_repo.read(
            schema_name=schema_name, is_ktable=False
        )

        agg_subsets: List[AggDatasetMetadata] = []

        md_list = metadata_subsets[0] if metadata_subsets else []
        for subset in physical_subsets:
            matched = next((md for md in md_list if md.physical_name == subset), None)
            if not matched:
                agg_subsets.append(
                    AggDatasetMetadata(
                        name=subset,
                        physical_name=subset,
                        description=None,
                        created_at=None,
                        updated_at=None,
                        owner=None,
                        tags=None,
                    )
                )
                continue
            agg_subsets.append(
                AggDatasetMetadata(
                    name=getattr(matched, "name", subset),
                    physical_name=subset,
                    description=getattr(matched, "description"),
                    created_at=getattr(matched, "created_at"),
                    updated_at=getattr(matched, "updated_at"),
                    owner=getattr(matched, "owner"),
                    tags=getattr(matched, "tags"),
                )
            )

        return agg_subsets

    def create_subset(
        self,
        name: str,
        query: Dict[str, Any],
        description: Optional[str] = None,
    ):
        """
        Create a new subset for a given ktable.
        """
        query_obj = query_factory(query)

        with self.services.obt_repo() as obt_repo:
            query_string = obt_repo.build_query_string(query_obj)

        clean_name = name.strip().lower().replace(" ", "_")
        view_name = f"senna_{clean_name}"

        with self.services.standard_repo() as repo:
            repo.create_view(query_obj.schema, view_name, query_string)

        metadata = DatasetMetadata(
            name=name,
            physical_name=view_name,
            schema_name=query_obj.schema,
            created_at="",
            updated_at="",
            description=description,
            is_ktable=False,
            query=query,
        )
        self.metadata_repo.create(metadata)
        return metadata

    def get_subset_data(self, schema_name: str, view_name: str):
        """
        Get subset data based on query parameters.
        """
        with self.services.standard_repo() as repo:
            return repo.get_view_data(schema_name, view_name)

    def delete_subset(
        self,
        schema_name: str,
        ktable_name: str,
        subset_name: str,
    ):
        """
        Delete a subset from a given ktable.
        """
        with self.services.standard_repo() as repo:
            return repo.delete_subset(schema_name, ktable_name, subset_name)
