from os import getenv
from ast import literal_eval
from pathlib import Path
from dotenv import load_dotenv
from pydantic import BaseModel, Field, SecretStr, AliasChoices
from pydantic_settings import BaseSettings, SettingsConfigDict
from logging_utilities.formatters.extra_formatter import ExtraFormatter
from typing import ClassVar

load_dotenv()


class LogSettings(BaseModel):
    BASE_DIR: ClassVar[Path] = Path(__file__).resolve().parent.parent

    @classmethod
    def get_config(cls) -> dict:
        """Return the complete logging configuration as a dictionary"""
        return {
            'version': 1,
            'disable_existing_loggers': False,
            'formatters': {
                'app': {
                    '()': ExtraFormatter,
                    'format': 'level: "%(levelname)s"\t msg: "%(message)s"\t logger: "%(name)s"\t func: "%(funcName)s"\t time: "%(asctime)s"',
                    'datefmt': '%Y-%m-%dT%H:%M:%S.%z',
                    'extra_fmt': '\t extra: %s',
                },
                "uvicorn": {
                    "()": "uvicorn.logging.DefaultFormatter",
                    'format': "%(levelprefix)s | %(asctime)s | %(message)s",
                    "datefmt": "%Y-%m-%d %H:%M:%S",
                },
            },
            'handlers': {
                'console': {
                    'level': 'INFO',
                    'class': 'logging.StreamHandler',
                    'formatter': 'uvicorn',
                },
                # 'app_file': {
                #     'level': 'DEBUG',
                #     'class': 'logging.FileHandler',
                #     'filename': str(cls.BASE_DIR / 'logs/log.log'),
                #     'formatter': 'app',
                # },
            },
            'loggers': {
                # '': {'handlers': ['app_file'], 'level': 'DEBUG', 'propagate': True},
                '': {'handlers': ['console'], 'level': 'ERROR', 'propagate': True},
                'uvicorn': {
                    'handlers': ['console'],
                    'level': 'INFO',
                    'propagate': True,
                },
            },
        }


class AppSettings(BaseSettings):
    # Client settings
    CLIENT_ID: str = Field(default='kimball_dev_client', env='CLIENT_ID')

    # General settings
    DEBUG: bool = Field(default=False, env='DEBUG')
    TIMEZONE: str = Field(default='America/Chicago', env='TIMEZONE')
    CONNECTORS_SECRET_KEY: SecretStr = Field(
        default=SecretStr('supersecretkey'), env='CONNECTORS_SECRET_KEY'
    )
    LOGGING: dict = Field(default_factory=lambda: LogSettings.get_config())

    @property
    def connectors_secret_key_bytes(self) -> bytes:
        return self.CONNECTORS_SECRET_KEY.get_secret_value().encode()

    DEMO_MODE: bool = Field(default=True, env='DEMO_MODE')

    # Storage setting
    STORAGE_ENGINE: str = Field(default='gcp_cloud_storage', env='STORAGE_ENGINE')
    BUCKET_NAME: str = Field(
        default='kimball-bucket',
        validation_alias=AliasChoices('GCP_BUCKET_NAME', 'MINIO_BUCKET_NAME'),
    )
    STORAGE_ENDPOINT: str = Field(
        default='https://storage.googleapis.com', env='STORAGE_ENDPOINT'
    )
    STORAGE_ACCESS_KEY: SecretStr = Field(default='', env='STORAGE_ACCESS_KEY')
    STORAGE_SECRET_KEY: SecretStr = Field(default='', env='STORAGE_SECRET_KEY')
    STORAGE_SECURE: bool = Field(default=True, env='STORAGE_SECURE')

    # LOGGING: dict = LogSettings().model_dump()

    # Database settings
    GENERAL_DB_ENGINE: str = Field(default='mongodb', env='GENERAL_DB_ENGINE')
    GENERAL_DB_URL: str = Field(
        default='mongodb://localhost:27017', env='GENERAL_DB_URL'
    )
    GENERAL_DB_NAME: str = Field(default='dev_customer', env='GENERAL_DB_NAME')

    CLICKHOUSE_HOST: str = Field(default='localhost', env='CLICKHOUSE_HOST')
    CLICKHOUSE_PORT: int = Field(default=8123, env='CLICKHOUSE_PORT')
    CLICKHOUSE_USER: str = Field(default='default', env='CLICKHOUSE_USER')
    CLICKHOUSE_PASSWORD: SecretStr = Field(default='', env='CLICKHOUSE_PASSWORD')
    CLICKHOUSE_DB: str = Field(default='default', env='CLICKHOUSE_DB')
    CLICKHOUSE_SECURE: bool = Field(default=False, env='CLICKHOUSE_SECURE')

    OLAP_SERVER_URL: str = Field(default='http://localhost:4000', env='OLAP_SERVER_URL')

settings = AppSettings()
