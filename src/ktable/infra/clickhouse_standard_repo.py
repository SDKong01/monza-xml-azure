import re
from datetime import date
from typing import List, Dict, Any


class ClickHouseRepo:
    def __init__(self, conn):
        self.conn = conn

    def list_ktables(self, schema_name: str) -> List[Dict[str, Any]]:
        query = f"""
        SELECT name as table_name
        FROM system.tables 
        WHERE database = '{schema_name}' 
        AND name LIKE '%_k%'
        ORDER BY name
        """

        result = self.conn.query(query)

        tables = [row[0] for row in result.result_rows] if result.result_rows else []
        return tables

    def list_columns(self, schema_name: str, ktable_name: str) -> List[Dict[str, Any]]:
        query = f"DESCRIBE {schema_name}.{ktable_name}"

        result = self.conn.query(query)

        # Extract column information from result
        columns = []
        if result.result_rows:
            for row in result.result_rows:
                columns.append({"column_name": row[0], "data_type": row[1]})

        return columns

    def column_stats(
        self, schema_name: str, ktable_name: str, column_name: str
    ) -> Dict[str, Any]:
        # Query to get min, max, and null count
        query = f"""
        SELECT 
            COUNT(*) as total_rows,
            COUNT(DISTINCT {column_name}) as distinct_values,
            COUNT(*) - COUNT({column_name}) as null_values
        FROM {schema_name}.{ktable_name}
        """

        result = self.conn.query(query)

        if result.result_rows:
            row = result.result_rows[0]
            total_rows = row[0]
            distinct_values = row[1]
            null_values = row[2]

            return {
                "status": "success",
                "schema": schema_name,
                "table": ktable_name,
                "column": column_name,
                "statistics": {
                    "total_rows": total_rows,
                    "distinct_values": distinct_values,
                    "null_values": null_values,
                },
                "query": query.strip(),
            }

    def table_stats(self, schema_name: str, ktable_name: str) -> Dict[str, Any]:
        # Query to get table statistics
        query = f"""
        SELECT 
            COUNT(*) as total_rows,
            COUNT(DISTINCT *) as distinct_rows
        FROM {schema_name}.{ktable_name}
        """

        result = self.conn.query(query)

        if result.result_rows:
            row = result.result_rows[0]
            total_rows = row[0]
            distinct_rows = row[1]

            return {
                "status": "success",
                "schema": schema_name,
                "table": ktable_name,
                "statistics": {
                    "total_rows": total_rows,
                    "distinct_rows": distinct_rows,
                },
                "query": query.strip(),
            }

    def create_view(
        self,
        schema_name: str,
        view_name: str,
        query: str,
    ) -> None:
        create_view_query = f"""
        CREATE OR REPLACE VIEW {schema_name}.{view_name} AS
        {query}
        """
        print(create_view_query)
        self.conn.query(create_view_query)

    def list_views(self, schema_name: str) -> List[str]:
        query = f"""
        SELECT name as view_name
        FROM system.tables 
        WHERE database = '{schema_name}' 
        AND engine = 'View'
        ORDER BY name
        """

        result = self.conn.query(query)

        views = [row[0] for row in result.result_rows] if result.result_rows else []
        return views

    def get_view_data(self, schema_name: str, view_name: str) -> List[Dict[str, Any]]:
        desc_query = f"DESCRIBE {schema_name}.{view_name}"
        desc_result = self.conn.query(desc_query)

        column_names = [row[0] for row in desc_result.result_rows]

        data_query = f"SELECT * FROM {schema_name}.{view_name}"  # TODO: add pagination and filtering
        data_result = self.conn.query(data_query)
        rows = data_result.result_rows if data_result.result_rows else []

        if not column_names:
            return []
        return [dict(zip(column_names, row)) for row in rows]
