import sys
import os
from config import settings

if __name__ == "__main__":
    sys.path.append("src")

    action = sys.argv[1]

    if action == "runserver":
        import uvicorn

        # Disable reload in production (Docker/container environments)
        # Enable reload only in local development
        is_development = os.getenv("ENVIRONMENT", "development") == "development"

        uvicorn.run(
            "app:http_server",
            host="0.0.0.0",
            port=8000,
            log_level="info",
            log_config=settings.LOGGING,
            reload=is_development,  # Only reload in development
        )

    else:
        print(f"Unknown action: {action}")
        sys.exit(1)
