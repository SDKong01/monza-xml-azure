from typing import Optional

from fastapi import Header
from nest.core import Controller, Depends, Get
from src.users_api.service import UsersService


@Controller("api/v1")
class UsersController:

    service: UsersService = Depends(UsersService)

    @Get(
        "/health",
        summary="Health check.",
        operation_id="health",
        responses={
            200: {
                "description": "Successful Response.",
            }
        },
    )
    async def health(self):
        return self.service.health_check()

    @Get(
        "/me",
        summary="Get current user information from headers.",
        operation_id="get_me",
        responses={
            200: {
                "description": "Current user information.",
            }
        },
    )
    async def get_me(
        self,
        x_forwarded_email: Optional[str] = Header(None, alias="X-Forwarded-Email"),
        x_forwarded_preferred_username: Optional[str] = Header(
            None, alias="X-Forwarded-Preferred-Username"
        ),
    ):
        """Get current user information from OAuth2 Proxy headers."""
        email = x_forwarded_email
        name = x_forwarded_preferred_username
        roles = []  # Roles can be extracted from JWT token if needed

        return self.service.get_user_info(email, name, roles)
