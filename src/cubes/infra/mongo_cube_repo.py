from datetime import datetime, timezone
from pymongo.collection import Collection
from pymongo.database import Database
from typing import Dict, Any, List, Optional, Tuple, Callable

from shared.infra.services import SharedInfraServices
from src.shared.infra.base_repo import BaseRepo, T
from constants import CUBES_COLLECTION


class MongoCubeRepo(BaseRepo[Database, T]):
    """
    MongoDB repository for Cube entities.

    Implements the BaseRepo interface for CRUD operations on Cube objects.
    """

    def __init__(self, mapper: Callable[[Dict[str, Any]], T] = lambda x: x):
        # Get MongoDB connection from SharedInfraServices
        conn = SharedInfraServices.get_sys_general_db()
        super().__init__(conn, mapper)
        self.collection: Collection = self.conn[CUBES_COLLECTION]

    def create(self, item: T) -> T:
        """
        Create a new cube in the database.

        Args:
            item: Cube entity to create

        Returns:
            Created Cube with assigned ID
        """
        cube_doc = {
            **item.to_dict(),
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
        }

        result = self.collection.insert_one(cube_doc)

        # Return cube with the assigned _id if id was not provided
        if not item.id:
            item.id = str(result.inserted_id)

        return item

    def read(self, **kwargs) -> Tuple[List[T], int]:
        """
        Read cubes from the database with optional filtering.

        Args:
            **kwargs: Filter parameters (e.g., name, id, limit, skip)

        Returns:
            Tuple of (list of Cube objects, total count)
        """
        # Build filter query from kwargs
        query = {}
        if "id" in kwargs:
            query["id"] = kwargs["id"]
        if "name" in kwargs:
            query["name"] = kwargs["name"]

        # Pagination parameters
        limit = kwargs.get("limit", 0)
        skip = kwargs.get("skip", 0)

        # Execute query
        cursor = self.collection.find(query, {"_id": 0})
        if skip:
            cursor = cursor.skip(skip)
        if limit:
            cursor = cursor.limit(limit)

        # Convert documents to Cube objects
        cubes = []
        for doc in cursor:
            cube = self._map(doc)
            cubes.append(cube)

        # Get total count
        total = self.collection.count_documents(query)

        return cubes, total

    def update(self, item_id: Any, item: T) -> T:
        """
        Update an existing cube in the database.

        Args:
            item_id: ID of the cube to update
            item: Updated Cube entity

        Returns:
            Updated Cube entity

        Raises:
            ValueError: If cube not found
        """
        update_doc = {
            "name": item.name,
            "updated_at": datetime.now(timezone.utc),
        }

        result = self.collection.update_one({"id": item_id}, {"$set": update_doc})

        if result.matched_count == 0:
            raise ValueError(f"Cube with id {item_id} not found")

        # Update the item ID to match what was requested
        item.id = item_id
        return item

    def delete(self, item_id: Any) -> None:
        """
        Delete a cube from the database.

        Args:
            item_id: ID of the cube to delete

        Raises:
            ValueError: If cube not found
        """
        result = self.collection.delete_one({"id": item_id})

        if result.deleted_count == 0:
            raise ValueError(f"Cube with id {item_id} not found")

    # Additional convenience methods
    def find_by_name(self, name: str) -> Optional[T]:
        """
        Find a cube by its name.

        Args:
            name: Name of the cube to find

        Returns:
            Cube object if found, None otherwise
        """
        cubes, _ = self.read(name=name, limit=1)
        return cubes[0] if cubes else None

    def find_by_id(self, cube_id: str) -> Optional[T]:
        """
        Find a cube by its ID.

        Args:
            cube_id: ID of the cube to find

        Returns:
            Cube object if found, None otherwise
        """
        cubes, _ = self.read(id=cube_id, limit=1)
        return cubes[0] if cubes else None

    def exists(self, cube_id: str) -> bool:
        """
        Check if a cube exists by ID.

        Args:
            cube_id: ID of the cube to check

        Returns:
            True if cube exists, False otherwise
        """
        return self.collection.count_documents({"id": cube_id}) > 0
