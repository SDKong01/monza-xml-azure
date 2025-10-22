from nest.core.app import App
from src.users_api.module import UsersModule

app = App(
    description="Test API for Keystone",
    modules=[
        UsersModule,
    ],
)
