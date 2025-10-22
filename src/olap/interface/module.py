"""
Module for OLAP proxy.
Registers the controller and services for dependency injection.
"""

from nest.core import Module
from src.olap.app.services import OlapAppServices
from .controller import OlapController


@Module(
    controllers=[OlapController],
    providers=[OlapAppServices],
)
class OlapModule:
    """
    Module for OLAP proxy functionality.
    Provides a proxy to forward requests to the external OLAP/Mondrian server.
    """
    pass
