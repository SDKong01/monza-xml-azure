from nest.core import Module


from src.ktable.app.services import KtableAppServices, SubsetAppServices
from .controller import KtableController, SubsetController


@Module(
    controllers=[KtableController, SubsetController],
    providers=[KtableAppServices, SubsetAppServices],
)
class KtableModule:
    """
    Module for managing ktable, including creation, listing, retrieval, and updating of ktable.
    This module integrates the application services with the controller for handling HTTP requests.
    """

    pass
