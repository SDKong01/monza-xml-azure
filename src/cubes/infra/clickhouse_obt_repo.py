import re
from datetime import date
from typing import List, Dict, Any

from .base_repos import BaseManager, Query, Filter

DB = "clickhouse"


class ClickHouseManager(BaseManager):
    def __init__(
        self,
    ):
        super().__init__()
        self._fields = ["*"]
        self._filters = ""
        self._order_by = "ORDER BY 1"
        self._group_by = ""
        self._limit = ""
        self.query_string = ""
        self._parse_pivots = []
        self._pivot_fields_names = []
        self.conn = None

        # self._process_query()

    @property
    def fields(self):
        _fields = self._fields[1:] if len(self._fields) > 1 else self._fields
        return ", ".join(_fields)

    @fields.setter
    def fields(self, value):
        self._fields.append(value)

    @fields.deleter
    def fields(self):
        self._fields = ["*"]

    def run_query(self, query: Query) -> List[Dict[str, Any]]:
        self.query = query
        self._process_query()

        def _parse_row(row: Dict[str, Any]) -> Dict[str, Any]:
            _row = []
            for value in row:
                if isinstance(value, date):
                    _row.append(value.isoformat())
                else:
                    _row.append(value)
            return _row

        response = self.conn.query(self.query_string)
        column_names = response.column_names
        results = response.result_rows
        if self.query.columns_only:
            return list(column_names)
        if self.query.distinct_field:
            return (x[0] for x in results)
        records = [dict(zip(column_names, _parse_row(row))) for row in results]

        return records

    def _columns_only(self):
        pass

    def _distinct(self):
        self.query_string = f"SELECT DISTINCT {self.query.distinct_field} FROM {DB}.{self.query.table} LIMIT 500"

    def _process_pivots(self):
        pivots = []
        for p in self.query.pivot or []:
            query_fields = (
                f"SELECT DISTINCT {p['pivot']} FROM {DB}.{self.query.table} LIMIT 500"
            )
            fields = self.conn.query(query_fields).result_rows
            for f in fields:
                pivots.append(
                    {
                        "pivot": p["pivot"],
                        "column": f[0],
                        "fact_column": p.get("fact_column", "sales_revenue"),
                        "agg": p.get("agg", "SUM").upper(),
                    }
                )

        self._parse_pivots = pivots

    def _process_filters(self):
        if not self.query.filters:
            return

        where_statement = "WHERE "

        ands: List[str] = []
        filters_map: Dict[str, List[str]] = {}

        for q in self.query.filters:
            q = Filter(**q) if isinstance(q, dict) else q
            op = self.operators_translation.get(q.operator)
            if not op:
                continue

            filters_map.setdefault(q.field, []).append(q.value)

        ins_statemens = []
        for field, values in filters_map.items():
            _f = field + " IN " + "(" + ", ".join([f"'{v}'" for v in values]) + ")"
            ins_statemens.append(_f)

        ands = list("AND" for x in range(len(ins_statemens))) or [
            " ",
        ]
        ands[-1:] = " "

        for statement, operator in zip(ins_statemens, ands):
            where_statement += f"{statement} {operator} "

        self._filters = where_statement

    def _process_fields(self):
        def parse_field_name(fact_column, field_name) -> str:
            col_name = fact_column
            if field_name != fact_column:
                col_name = f"{fact_column} ({field_name})"
            if self.query.filters:
                col_name = (
                    f"{col_name} ({' · '.join([f.value for f in self.query.filters])})"
                )
            return col_name

        def _clean_str(field_name: str) -> str:
            return re.sub(
                r'[^a-zA-Z0-9_]',
                '',
                field_name.encode('ascii', 'ignore').decode().replace(" ", "_"),
            )

        default_fact_column = "sales_revenue"  # TODO: remove hardcoded value

        for p in self._parse_pivots or []:
            pivot_column = p["pivot"]
            column_name = p["column"]
            fact_column = p.get("fact_column", default_fact_column)
            agg_type = p.get("agg", "SUM").upper()
            field_name = _clean_str(column_name)
            field_name = parse_field_name(fact_column, field_name)
            self._pivot_fields_names.append(field_name)
            self.fields = (
                f"{agg_type}(CASE WHEN {self.table_alias}.{pivot_column} = '{column_name}' THEN toFloat64({self.table_alias}.{fact_column}) ELSE 0 END) AS "
                + f'"{field_name}"'
            )

        if self.query.pivot:
            return

        for f in self.query.fields:
            if isinstance(f, dict):
                f = Filter(**f)
            op = self.aggregators_translation.get(f.operator, "")
            field_name = parse_field_name(op, f.field, f.field)
            if op:
                self.fields = f'{op}(toFloat64("{f.field}")) AS "{field_name}"'
            elif f.operator in ["fields", "eq"]:
                self.fields = f'"{f.field}"'
            elif f.operator == "field_as":
                self.fields = f'"{f.field}" AS "{f.value}"'

    def _process_order_by(self):
        pass

    def _process_limit(self):
        self._limit = f"LIMIT {self.query.limit}" if self.query.limit else ""
        if self.query.columns_only:
            self._limit = "LIMIT 0"

    def _process_group_by(self):
        if not self.query.group_by:
            return

        self.fields = (
            f"{self.table_alias}.{self.query.group_by} AS " + '"Calendar Date"'
        )
        self._order_by = f'ORDER BY "Calendar Date"'
        self._group_by = f'GROUP BY "Calendar Date"'

    def _process_fields(self):
        pass

    def _process_query(self):
        if self.query.distinct_field:
            self._distinct()
            return

        self._process_pivots()
        self._process_group_by()
        self._process_filters()
        self._process_fields()

        query_string = f"SELECT {self.fields} FROM {DB}.{self.query.table} {self.table_alias} {self._filters} {self._group_by} {self._order_by} {self._limit}{self.finish_query}"
        self.query_string = query_string.strip()

    def _set_stats_fields(self, fact_column, aggs):
        fields = []
        for agg_type in aggs:
            fields.append(
                f'{agg_type}(toFloat64({self.subset_alias}."{fact_column}")) AS "{fact_column}_{agg_type}"'
            )
        fields.append(
            f'uniqExact({self.subset_alias}."{fact_column}") AS "{fact_column}_unique"'
        )
        return ", ".join(fields)

    def stats(self, query: Query) -> List[Dict[str, Any]]:
        # self.query = query
        # self._process_query()
        # print(self.query_string)
        # response = self.conn.query(self.query_string)
        response = self.run_query(query)
        column_names_subset = list(response.column_names)[:]
        column_names_subset.remove("Calendar Date")  # Remove date column if present
        subset_table = f"({self.query_string}) {self.subset_alias}"

        # Prepare a single query to calculate statistics for all targets
        aggs = ["min", "max", "avg", "stddevPop"]
        stats_fields = []
        for target in column_names_subset:
            stats_fields.append(self._set_stats_fields(target, aggs))
        stats_query = f"SELECT {', '.join(stats_fields)} FROM {subset_table}"

        # Execute the combined query
        response = self.conn.query(stats_query)
        result_row = response.result_rows[0]

        # Parse the results into a structured format
        stats_results = []
        for i, target in enumerate(column_names_subset):
            offset = i * (len(aggs) + 1)  # Each target has len(aggs) + 1 fields
            stats = {
                "min": result_row[offset],
                "max": result_row[offset + 1],
                "mean": result_row[offset + 2],
                "stddev": result_row[offset + 3],
                "unique": result_row[offset + 4],
                "target": target,
                "missing": 0,  # Placeholder for missing values calculation
            }
            if stats["min"] and stats["max"]:
                stats_results.append(stats)

        return stats_results
