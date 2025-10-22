from nest.core import Module


from src.reports.app.services import ReportAppServices
from .controller import ReportController, PrivateEquityDemoController


@Module(
    controllers=[ReportController, PrivateEquityDemoController],
    providers=[ReportAppServices],
)
class ReportModule:
    """
    Module for managing reports, including creation, listing, retrieval, and updating of reports.
    This module integrates the application services with the controller for handling HTTP requests.
    """

    pass
