"""
Application layer for OLAP proxy.
This module contains the business logic for proxying requests to the OLAP server.
"""

from nest.core import Injectable
from typing import Dict, Any, Optional

from src.olap.infra.olap_repo import OlapRepository


@Injectable
class OlapAppServices:
    """
    Application service for OLAP operations.
    Orchestrates the proxying of requests to the OLAP server.
    """

    def __init__(self):
        # Initialize the repository that talks to the OLAP server
        self.repo = OlapRepository()

    def proxy_request(
        self,
        method: str,
        path: str,
        query_params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        body: Optional[bytes] = None,
    ) -> tuple[int, Dict[str, str], bytes]:
        """
        Proxy a request to the OLAP server.

        Args:
            method: HTTP method (GET, POST, PUT, DELETE, PATCH)
            path: URL path to proxy
            query_params: Query parameters
            headers: Request headers
            body: Request body

        Returns:
            A tuple of (status_code, response_headers, response_body)
        """
        print(f"🔧 SERVICE: In proxy_request - {method} {path}")
        # Forward the request through the repository
        result = self.repo.forward_request(
            method=method,
            path=path,
            query_params=query_params,
            headers=headers,
            body=body,
        )
        print(f"🔧 SERVICE: Returning result from repo - status {result[0]}")
        return result
