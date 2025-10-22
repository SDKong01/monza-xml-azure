import logging
from nest.core import Module, PyNestFactory
from contextlib import asynccontextmanager
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Request
from fastapi.responses import JSONResponse, Response
from src.cubes.interface.module import CubeModule
from src.reports.interface.module import ReportModule
from src.ktable.interface.module import KtableModule
from src.olap.interface.module import OlapModule
from src.shared.domain.exceptions import BaseException
from src.shared.infra.mongo_client import MongoDBConnection
from src.shared.infra.clickhouse_client import ClickHouseConnection
from config import settings

logging.basicConfig(level=logging.INFO)


@Module(
    imports=[CubeModule, ReportModule, KtableModule, OlapModule],
)
class AppModule:
    pass


@asynccontextmanager
async def lifespan(app: PyNestFactory):
    # Configure ClickHouse connection parameters at startup
    logging.info("Configuring ClickHouse connection...")
    ClickHouseConnection.configure(
        {
            "host": settings.CLICKHOUSE_HOST,
            "port": settings.CLICKHOUSE_PORT,
            "username": settings.CLICKHOUSE_USER,
            "password": settings.CLICKHOUSE_PASSWORD.get_secret_value(),
            "database": settings.CLICKHOUSE_DB,
        }
    )
    logging.info("ClickHouse connection configured successfully")

    yield

    # Cleanup on shutdown
    MongoDBConnection.close_all()
    # No need to call close_all() for ClickHouse since we're using per-request clients


app = PyNestFactory.create(
    AppModule,
    title="Monza API",
    description="API for managing cubes, reports and related services.",
    version="2.0.0",
    debut=True,
    lifespan=lifespan,
)

http_server = app.get_server()


async def base_exception_handler(request: Request, exc: BaseException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "code": exc.code,
            "detail": exc.detail,
        },
    )


async def unhandled_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={
            "code": "INTERNAL_ERROR",
            "detail": str(exc),
        },
    )


http_server.add_exception_handler(BaseException, base_exception_handler)
http_server.add_exception_handler(Exception, unhandled_exception_handler)

http_server.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


# Simple health check endpoint for Docker and monitoring
@http_server.get("/health")
async def health_check():
    """
    Simple health check endpoint.
    Returns 200 OK if the service is running.
    """
    return {"status": "healthy", "service": "monza-api", "version": "2.0.0"}


# Simple health check endpoint for Docker and monitoring
@http_server.get("/")
async def health_check():
    """
    Simple health check endpoint.
    Returns 200 OK if the service is running.
    """
    return {"status": "healthy", "service": "monza-api", "version": "2.0.0"}
