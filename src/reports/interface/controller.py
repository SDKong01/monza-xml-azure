import json
from urllib.parse import unquote
from typing import Type, Optional, List, Dict, Any, cast
from nest.core import Controller, Post, Get, Patch, Delete, Put
from fastapi import FastAPI, HTTPException, UploadFile, File, Query
from pathlib import Path
import copy
from src.reports.app.services import ReportAppServices
from src.cubes.domain.entities import Cube, Dimension, Measure
from src.reports.domain.entities import Report
from .serializers import (
    CreateReportRequest,
    ReportItemSerializer,
    ReportsListSerializer,
)
from src.shared.domain.fake_dacite import from_dict
from .dummy import dummy_data


@Controller(tag="Report", prefix="/v2/report")
class ReportController:
    def __init__(self, service: ReportAppServices):
        self.service: Type[ReportAppServices] = service

    @Get("/")
    def list_report(
        self,
    ) -> ReportItemSerializer:
        items, count = self.service.list_cubes()
        serialized_items = [
            ReportItemSerializer(
                id=item.id,
                name=item.name,
            )
            for item in items
        ]
        return ReportsListSerializer(total_count=count, data=serialized_items)

    @Get("/{report_id}")
    def get_report(self, report_id: str) -> ReportItemSerializer:
        return self.service.get_report(report_id)

    @Post("/")
    def create_report(
        self, report_request: CreateReportRequest
    ) -> ReportItemSerializer:
        """
        Create a new report.
        """
        report = Report(
            id="id",
            name=report_request.name,
        )
        report_response = self.service.create_report(report)
        return ReportItemSerializer(
            id=report_response.id,
            name=report_response.name,
        )

    @Put("/{report_id}")
    def update_report(
        self, report_id: str, report_request: CreateReportRequest
    ) -> ReportItemSerializer:
        """
        Update an existing report.
        """
        return self.service.update_report(report_id, report_request.dict())

    @Delete("/{report_id}")
    def delete_report(self, report_id: str) -> None:
        """
        Delete a report by its ID.
        """
        self.service.delete_report(report_id)


def parse_moic(moic_str: str) -> float:
    try:
        return float(moic_str)
    except Exception:
        return 0.0


def parse_investment(inv_str: str) -> float:
    try:
        s = inv_str.strip().upper().replace("$", "")
        multiplier = 1
        if s.endswith("M"):
            multiplier = 1_000_000
            s = s[:-1]
        elif s.endswith("K"):
            multiplier = 1_000
            s = s[:-1]
        return float(s) * multiplier
    except Exception:
        return 0.0


@Controller(tag="Private Equity", prefix="/demo/pe")
class PrivateEquityDemoController:
    def __init__(self, service: ReportAppServices):
        self.service: Type[ReportAppServices] = service

    @Get("/portfolio")
    async def get_portfolio(
        self,
        industry: Optional[str] = Query(None, description="Filter by industry"),
        type: Optional[str] = Query(None, description="Filter by company type"),
        search: Optional[str] = Query(None, description="Search by company name/title"),
        sort_by: Optional[str] = Query(
            None, description="Sort by 'moic' or 'investment'"
        ),
        order: Optional[str] = Query("desc", description="Sort order: 'asc' or 'desc'"),
    ):
        companies = copy.deepcopy(dummy_data["portfolio"])

        if industry:
            companies = [
                c for c in companies if industry.lower() in c["industry"].lower()
            ]

        if type:
            companies = [c for c in companies if type.lower() in c["type"].lower()]

        if search:
            companies = [c for c in companies if search.lower() in c["name"].lower()]

        if not companies:
            raise HTTPException(
                status_code=404, detail="No companies found matching the criteria"
            )

        if sort_by:
            order = order.lower()
            reverse = True if order == "desc" else False

            sort_by = sort_by.lower()
            if sort_by == "moic":
                companies.sort(key=lambda c: parse_moic(c["moic"]), reverse=reverse)
            elif sort_by == "investment":
                companies.sort(
                    key=lambda c: parse_investment(c["investment"]), reverse=reverse
                )
            else:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid sort_by value. Use 'moic' or 'investment'.",
                )

        for c in companies:
            c["moic"] = f"{c['moic']}x"

        return companies

    @Get("/analysis/moic")
    async def get_moic_analysis(
        self,
        type: Optional[str] = Query(None, description="Filter by company type"),
        sort_by: Optional[str] = Query("moic", description="Sort by 'moic'"),
        order: Optional[str] = Query("desc", description="Sort order: 'asc' or 'desc'"),
    ):
        moic_data = copy.deepcopy(dummy_data["moic"])

        if type:
            moic_data = [c for c in moic_data if type.lower() in c["type"].lower()]

        if not moic_data:
            raise HTTPException(
                status_code=404, detail="No companies found for the given type"
            )

        total_moic = 0
        total_hold = 0
        top_performers = 0
        chart = []
        details = []

        for item in moic_data:
            moic = item["moic"]
            status = item["status"]
            perf = "Top Performer" if moic >= 2 else "Underperformer"

            total_moic += moic
            total_hold += item["years_hold"]
            if moic >= 2:
                top_performers += 1

            chart.append({"company": item["company"], "moic": f"{moic}x"})

            details.append(
                {
                    "company": item["company"],
                    "type": item["type"],
                    "investment": item["investment"],
                    "valuation": item["valuation"],
                    "years_hold": item["years_hold"],
                    "moic": f"{moic}x",
                    "status": status,
                    "performance": perf,
                }
            )

        # Validate sort field
        if sort_by.lower() not in ["moic", "company", "valuation"]:
            raise HTTPException(
                status_code=400,
                detail="Invalid sort_by value. Use 'moic', 'company', or 'valuation'.",
            )
        reverse = order.lower() != "asc"

        # Helper to extract sortable value
        def extract_value(field, value):
            try:
                if field == "moic":
                    return float(value.replace("x", "").strip())
                elif field == "valuation":
                    return float(value.replace("$", "").replace("M", "").strip())
                elif field == "company":
                    return value.lower()
            except Exception:
                # fallback value for missing or bad data
                if field in ["moic", "valuation"]:
                    return 0.0
                elif field == "company":
                    return ""
            return value

        details.sort(
            key=lambda x: extract_value(sort_by.lower(), x[sort_by.lower()]),
            reverse=reverse,
        )
        chart.sort(
            key=lambda x: extract_value(
                sort_by.lower(), x.get(sort_by.lower(), "moic")
            ),
            reverse=reverse,
        )

        avg_moic = total_moic / len(moic_data)
        avg_hold = total_hold / len(moic_data)

        return {
            "portfolio_avg_moic": f"{round(avg_moic, 2)}x",
            "top_performers_count": top_performers,
            "average_hold_period_years": round(avg_hold, 1),
            "chart": chart,
            "details": details,
        }

    @Get("/analysis/irr")
    async def get_irr_analysis(
        self,
        type: Optional[str] = Query(None, description="Filter by company type"),
        sort_by: Optional[str] = Query(
            None, description="Sort by 'irr' or 'vs_target'"
        ),
        order: Optional[str] = Query("desc", description="Sort order: 'asc' or 'desc'"),
    ):
        irr_data = copy.deepcopy(dummy_data["irr"])

        if type:
            irr_data = [c for c in irr_data if type.lower() in c["type"].lower()]

        if not irr_data:
            raise HTTPException(
                status_code=404, detail="No companies found for the given type"
            )

        total_irr = 0
        total_hold = 0
        outperformers = 0
        chart = []
        details = []

        for item in irr_data:
            irr = item["irr"]
            target = item["target_irr"]
            vs_target = irr - target
            perf = "Above Target" if vs_target > 0 else "Below Target"

            total_irr += irr
            total_hold += item["years_hold"]
            if vs_target > 0:
                outperformers += 1

            chart.append(
                {
                    "company": item["company"],
                    "irr": f"{irr}%",
                    "vs_target": f"{'+' if vs_target >= 0 else ''}{vs_target}%",
                }
            )

            details.append(
                {
                    "company": item["company"],
                    "type": item["type"],
                    "investment": item["investment"],
                    "valuation": item["valuation"],
                    "years_hold": item["years_hold"],
                    "irr": f"{irr}%",
                    "vs_target": f"{'+' if vs_target >= 0 else ''}{vs_target}%",
                    "performance": perf,
                }
            )

        if sort_by and sort_by.lower() not in [
            "irr",
            "vs_target",
            "company",
            "valuation",
        ]:
            raise HTTPException(
                status_code=400,
                detail="Invalid sort_by value. Use 'irr', 'vs_target', 'company', or 'valuation'.",
            )

        # Sorting
        if sort_by:
            sort_by = sort_by.lower()
            order = order.lower()
            reverse = order != "asc"

            def extract_value(field, value):
                if field in ["irr", "vs_target"]:
                    return float(
                        value.replace("%", "").replace("+", "").replace("-", "").strip()
                    )
                elif field == "valuation":
                    return float(value.replace("$", "").replace("M", "").strip())
                elif field == "company":
                    return value.lower()
                return value

            details.sort(
                key=lambda x: extract_value(sort_by, x[sort_by]), reverse=reverse
            )
            chart.sort(
                key=lambda x: extract_value(
                    sort_by if sort_by in x else "irr",
                    x.get(sort_by if sort_by in x else "irr"),
                ),
                reverse=reverse,
            )

        avg_irr = total_irr / len(irr_data)
        avg_hold = total_hold / len(irr_data)

        return {
            "portfolio_avg_irr": f"{round(avg_irr, 1)}%",
            "outperformers_count": outperformers,
            "average_hold_period_years": round(avg_hold, 1),
            "chart": chart,
            "details": details,
        }
