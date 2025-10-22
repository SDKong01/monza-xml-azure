from nest.core import Module


from src.cubes.app.services import CubeAppServices
from .controller import CubeController


@Module(
    controllers=[CubeController],
    providers=[CubeAppServices],
)
class CubeModule:
    """
    Module for managing cubes, including creation, listing, retrieval, and updating of cubes.
    This module integrates the application services with the controller for handling HTTP requests.
    """

    pass
