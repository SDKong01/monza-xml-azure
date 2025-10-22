import logging
from typing import List, Optional


class UsersService:
    def health_check(self):
        return {"status": "healthy"}

    def get_user_info(
        self, email: Optional[str], name: Optional[str], roles: Optional[str]
    ):
        """
        Extract user information from headers injected by oauth2-proxy.

        Args:
            email: User email from X-User-Email header
            name: User name from X-User-Name header
            roles: User roles from X-User-Roles header (comma-separated)

        Returns:
            Dict containing user information
        """
        # Parse roles if provided (expecting comma-separated string)
        parsed_roles = []
        if roles:
            parsed_roles = [role.strip() for role in roles.split(",") if role.strip()]

        return {
            "email": email,
            "name": name,
            "roles": parsed_roles,
            "authenticated": email is not None,
        }
