from src.users_api.controllers import UsersController
from src.users_api.service import UsersService


class UsersModule:

    def __init__(self):
        self.providers = [UsersService]
        self.controllers = [UsersController]
