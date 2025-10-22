from nest.core import Injectable
from typing import List, Optional, Dict, Any, Tuple

from src.reports.domain.services import ReportServices
from src.reports.domain.entities import Report


@Injectable
class ReportAppServices:
    def __init__(self):
        self.services = ReportServices

    def list_reports(
        self,
    ) -> Tuple[List[Report], int]:
        """
        List cubes with optional filtering, ordering, and pagination.
        """
        return self.services.repo().read()

    def get_report(self, report_id: str) -> Optional[Report]:
        """
        Retrieve a report by its ID.
        """
        reports, _ = self.services.repo().read(id=report_id)
        return reports[0] if reports else None

    def update_report(self, report_id: str, update_data: Dict[str, Any]) -> Report:
        """
        Update an existing report by its ID.
        """
        return self.services.repo().update(report_id, update_data)

    def create_report(self, report: Report) -> Report:
        """
        Create a new report with the provided data.
        """
        self.services.repo().create(report)

        return report

    def delete_report(self, report_id: str) -> None:
        """
        Delete a report by its ID.
        """
        self.services.repo().delete(report_id)
