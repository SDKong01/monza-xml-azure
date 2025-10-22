# Test API for Keystone
API to test the authentication service.

## Get started

1. Install poetry.

    Linux, macOS:
    ```bash
    curl -sSL https://install.python-poetry.org | python3 -
    ```

    Windows (Powershellpoetry she
    ```bash
    (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
    ```

2. Install base dependencies.
    ```bash
    poetry install
    ```

3. Source venv.
    Windows (Powershell):
    ```bash
    Invoke-Expression (poetry env activate)
    ```

    Linux, macOS:
    ```bash
    $ eval $(poetry env activate)
    ```

## Run the app
```bash
uvicorn "app:app" --host "0.0.0.0" --port "8000" --reload
```