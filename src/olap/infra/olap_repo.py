"""
Infrastructure layer for OLAP server communication.
This module handles all HTTP requests to the external OLAP/Mondrian server.
"""

import httpx
from requests import Session
from typing import Dict, Any, Optional
from config import settings
import logging

logger = logging.getLogger(__name__)


class OlapRepository:
    """
    Repository for communicating with the OLAP server.
    Acts as a proxy - forwards requests and returns responses.
    """

    def __init__(self):
        # Get the OLAP server URL from settings
        self.base_url = settings.OLAP_SERVER_URL.rstrip('/')
        # Create an HTTP client with timeout
        # We'll handle redirects manually to ensure CORS bypass works correctly
        self.client = httpx.Client(timeout=30.0, follow_redirects=False)
        self.max_redirects = 10  # Maximum number of redirects to follow

    def forward_request(
        self,
        method: str,
        path: str,
        query_params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        body: Optional[bytes] = None,
    ) -> tuple[int, Dict[str, str], bytes]:
        """
        Forward an HTTP request to the OLAP server.

        Args:
            method: HTTP method (GET, POST, PUT, DELETE, PATCH)
            path: URL path (e.g., "/discover", "/xmla")
            query_params: Query parameters as a dictionary
            headers: HTTP headers as a dictionary
            body: Request body as bytes

        Returns:
            A tuple of (status_code, response_headers, response_body)
        """
        # Build the full URL
        url = f"{self.base_url}/{path.lstrip('/')}"

        # Prepare headers - CRITICAL: Remove headers that expose frontend origin
        # This makes the request appear to originate from this backend server
        request_headers = {}
        if headers:
            # List of headers to BLOCK (they reveal the request comes from browser/frontend)
            blocked_headers = [
                'host',  # httpx sets this automatically
                'content-length',  # httpx calculates this
                'origin',  # Reveals frontend origin - MUST remove for CORS bypass
                'referer',  # Reveals frontend URL - MUST remove for CORS bypass
                'sec-fetch-site',  # Browser security header
                'sec-fetch-mode',  # Browser security header
                'sec-fetch-dest',  # Browser security header
                'sec-ch-ua',  # Browser fingerprinting
                'sec-ch-ua-mobile',
                'sec-ch-ua-platform',
                'connection',  # httpx manages this
            ]

            request_headers = {
                k: v for k, v in headers.items() if k.lower() not in blocked_headers
            }

        # Add headers that make the request look like it's from the backend server
        request_headers['User-Agent'] = 'KainamBackend-OLAP-Proxy/1.0'

        logger.debug(f"Cleaned headers: {request_headers}")

        try:
            # Manually follow redirects to ensure proper CORS bypass
            redirect_count = 0
            current_url = url
            current_method = method
            current_body = body

            while redirect_count < self.max_redirects:
                # Log the request details for debugging
                logger.info(
                    f"Proxying {current_method} request to: {current_url} (redirect #{redirect_count})"
                )

                print(f"Forwarding {method} request to OLAP server at path: /{path}")

                # Make the request to the OLAP server
                response = self.client.request(
                    method=current_method,
                    url=current_url,
                    params=(
                        query_params if redirect_count == 0 else None
                    ),  # Only use params on first request
                    headers=request_headers,
                    content=current_body,
                )

                # Log the response details
                logger.info(f"Response status: {response.status_code}")

                # Check if it's a redirect
                if response.status_code in [301, 302, 303, 307, 308]:
                    location = response.headers.get('location')
                    if not location:
                        logger.error("Redirect response without Location header")
                        break

                    logger.info(f"Following redirect to: {location}")

                    # Handle relative vs absolute URLs
                    if location.startswith('http://') or location.startswith(
                        'https://'
                    ):
                        current_url = location
                    else:
                        # Relative URL - construct from base
                        from urllib.parse import urljoin

                        current_url = urljoin(current_url, location)

                    # For 303, always use GET. For 307/308, preserve the method
                    if response.status_code == 303:
                        current_method = 'GET'
                        current_body = None
                    elif response.status_code in [307, 308]:
                        # Keep the same method and body
                        pass
                    else:  # 301, 302
                        # Standard behavior: POST becomes GET, others stay the same
                        if current_method == 'POST':
                            current_method = 'GET'
                            current_body = None

                    redirect_count += 1
                    continue

                # Not a redirect - return the final response
                logger.info(f"Final response after {redirect_count} redirects")

                # Create a HARD COPY of the response to ensure complete isolation
                # This prevents any connection pooling or reference issues
                response_status = int(response.status_code)
                response_headers = dict(response.headers)  # Creates new dict
                response_body = bytes(response.content)  # Creates new bytes object
                # print(response.content)
                logger.debug(
                    f"Returning hard copy - Status: {response_status}, Body size: {len(response_body)}"
                )

                return (
                    response_status,
                    response_headers,
                    response_body,
                )

            # Too many redirects
            logger.error(f"Too many redirects ({self.max_redirects})")
            return (
                508,  # Loop Detected
                {"content-type": "application/json"},
                b'{"error": "Too many redirects"}',
            )

        except httpx.RequestError as e:
            # If the OLAP server is unreachable, return an error
            logger.error(f"OLAP server request failed: {str(e)}")
            error_message = (
                f'{{"error": "OLAP server unavailable", "detail": "{str(e)}"}}'
            )
            return (
                503,
                {"content-type": "application/json"},
                error_message.encode('utf-8'),
            )

    def __del__(self):
        """Close the HTTP client when the repository is destroyed"""
        if hasattr(self, 'client'):
            self.client.close()
