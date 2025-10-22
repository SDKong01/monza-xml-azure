"""
Controller for OLAP proxy endpoints.
This module defines the HTTP endpoints that act as a proxy to the OLAP server.
"""

from typing import Type
from nest.core import Controller, Get, Post, Put, Delete, Patch, HttpCode
from fastapi import Request, Response as FastAPIResponse
from fastapi.responses import Response

from src.olap.app.services import OlapAppServices
from .serializers import HealthCheckResponse
from config import settings


@Controller(tag="OLAP Proxy", prefix="/olap")
class OlapController:
    """
    Controller for proxying requests to the OLAP server.
    Handles all HTTP methods and forwards them to the Mondrian/OLAP server.
    """

    def __init__(self, service: OlapAppServices):
        self.service: Type[OlapAppServices] = service

    @Get("/health")
    async def health_check(self) -> HealthCheckResponse:
        """
        Health check endpoint to verify the OLAP proxy is working.
        """
        return HealthCheckResponse(
            status="healthy", olap_server_url=settings.OLAP_SERVER_URL
        )

    @Post("/test-cors")
    async def test_cors(self, request: Request) -> Response:
        """Simple test endpoint to verify CORS works"""
        print("🧪 TEST ENDPOINT HIT!")
        return Response(
            content=b'{"status": "ok", "message": "CORS test successful"}',
            status_code=200,
            headers={
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': '*',
                'Access-Control-Allow-Headers': '*',
            },
        )

    @Get("/{path:path}")
    async def proxy_get(self, request: Request, path: str = "") -> Response:
        """Proxy GET requests to OLAP server"""
        print(f"📍 GET endpoint hit for path: {path}")

        try:
            query_params = dict(request.query_params)
            headers = dict(request.headers)

            print(f"📤 Calling service for GET")

            status_code, response_headers, response_body = self.service.proxy_request(
                method="GET",
                path=path,
                query_params=query_params,
                headers=headers,
                body=None,
            )

            print(
                f"📥 Got response: status={status_code}, body_size={len(response_body)}"
            )

            # Create clean headers with CORS
            clean_headers = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Expose-Headers': '*',
            }

            # Only copy safe headers from OLAP response
            safe_header_keys = ['content-type', 'cache-control']
            for key, value in response_headers.items():
                if key.lower() in safe_header_keys:
                    clean_headers[key] = value

            print(f"✅ Returning GET response")

            return Response(
                content=response_body,
                status_code=status_code,
                headers=clean_headers,
            )

        except Exception as e:
            print(f"❌ ERROR in proxy_get: {type(e).__name__}: {str(e)}")
            import traceback

            traceback.print_exc()

            return Response(
                content=f'{{"error": "Proxy error", "detail": "{str(e)}"}}'.encode(),
                status_code=500,
                headers={
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': '*',
                    'Access-Control-Allow-Headers': '*',
                },
            )

    @Post("/{path:path}")
    async def proxy_post(self, request: Request, path: str = "") -> Response:
        """Proxy POST requests to OLAP server"""
        print(f"📍 POST endpoint hit for path: {path}")

        try:
            # Get request details
            query_params = dict(request.query_params)
            headers = dict(request.headers)
            body = await request.body()

            print(f"📤 Calling service with {len(body)} bytes of body")

            # Forward to OLAP server
            status_code, response_headers, response_body = self.service.proxy_request(
                method="POST",
                path=path,
                query_params=query_params,
                headers=headers,
                body=body,
            )

            print(
                f"📥 Got response: status={status_code}, body_size={len(response_body)}"
            )

            # Create clean headers with CORS
            clean_headers = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Expose-Headers': '*',
            }

            # Only copy safe headers from OLAP response
            safe_header_keys = ['content-type', 'cache-control']
            for key, value in response_headers.items():
                if key.lower() in safe_header_keys:
                    clean_headers[key] = value

            print(f"✅ Returning response with {len(clean_headers)} headers")

            return Response(
                content=response_body,
                status_code=status_code,
                headers=clean_headers,
            )

        except Exception as e:
            print(f"❌ ERROR in proxy_post: {type(e).__name__}: {str(e)}")
            import traceback

            traceback.print_exc()

            return Response(
                content=f'{{"error": "Proxy error", "detail": "{str(e)}"}}'.encode(),
                status_code=500,
                headers={
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': '*',
                    'Access-Control-Allow-Headers': '*',
                },
            )

    @Put("/{path:path}")
    async def proxy_put(self, request: Request, path: str = "") -> Response:
        """Proxy PUT requests to OLAP server"""
        return await self._handle_proxy(request, path, "PUT")

    @Delete("/{path:path}")
    async def proxy_delete(self, request: Request, path: str = "") -> Response:
        """Proxy DELETE requests to OLAP server"""
        return await self._handle_proxy(request, path, "DELETE")

    @Patch("/{path:path}")
    async def proxy_patch(self, request: Request, path: str = "") -> Response:
        """Proxy PATCH requests to OLAP server"""
        return await self._handle_proxy(request, path, "PATCH")

    async def _handle_proxy(self, request: Request, path: str, method: str) -> Response:
        """Generic handler for proxy requests with error handling"""
        print(f"📍 {method} endpoint hit for path: {path}")

        try:
            query_params = dict(request.query_params)
            headers = dict(request.headers)
            body = (
                await request.body()
                if method not in ["GET", "HEAD", "DELETE"]
                else None
            )

            print(f"📤 Calling service for {method}")

            status_code, response_headers, response_body = self.service.proxy_request(
                method=method,
                path=path,
                query_params=query_params,
                headers=headers,
                body=body,
            )

            print(f"📥 Got response: status={status_code}")

            # Create clean headers with CORS
            clean_headers = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Expose-Headers': '*',
            }

            # Only copy safe headers
            safe_header_keys = ['content-type', 'cache-control']
            for key, value in response_headers.items():
                if key.lower() in safe_header_keys:
                    clean_headers[key] = value

            return Response(
                content=response_body,
                status_code=status_code,
                headers=clean_headers,
            )

        except Exception as e:
            print(f"❌ ERROR in {method}: {type(e).__name__}: {str(e)}")
            import traceback

            traceback.print_exc()

            return Response(
                content=f'{{"error": "Proxy error", "detail": "{str(e)}"}}'.encode(),
                status_code=500,
                headers={
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                },
            )
