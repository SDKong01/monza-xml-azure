# [PYTHON CODING STANDARDS]

**Version:** 1.0
**Owner:** Orchestrator

## 1. Core Philosophy
- **Readability First:** Code is written once but read many times. Prioritize clarity and simplicity over overly clever or obscure solutions. The code should be self-documenting where possible.
- **Pythonic Solutions:** Strive to use the language's features as they are intended. Aim for idiomatic Python that is both efficient and expressive.
- **Reproducibility:** All code must be deterministic and reproducible. This is especially critical in data processing and machine learning tasks.

## 2. Style & Formatting
- **PEP 8:** All code MUST strictly follow the PEP 8 style guide.
- **Automatic Formatting:** All code MUST be formatted using `black` and `isort` before being committed. No unformatted code will be accepted.
- **Line Length:** The maximum line length is 88 characters, as enforced by `black`.

## 3. Quality & Robustness
- **Typing:** All function signatures and class variables MUST include type annotations as per PEP 484.
- **Modularity & Design Patterns:** Code must be designed to be modular and reusable. Apply relevant software design patterns to create decoupled, maintainable, and testable systems. Refer to [https://refactoring.guru/design-patterns](https://refactoring.guru/design-patterns) for guidance.
- **Error Handling:** Implement robust error handling using `try...except` blocks for any operations that may fail (e.g., I/O, network requests, data parsing). Exceptions should be specific, not generic (`except Exception:`).
- **Constants:** Use `enum.Enum` classes for defining related groups of constants. Avoid loose constants in a `constants.py` file to ensure type safety and clarity.
- **Vectorization:** In numerical or data-heavy code, prefer vectorized operations (e.g., using NumPy, pandas) over explicit loops for performance and readability.

## 4. Documentation
- **Docstrings:** All modules, classes, and functions MUST have detailed docstrings.
- **Docstring Style:** All docstrings MUST follow the **Google Python Style Guide**. A docstring must include a brief description, arguments (`Args:`), and return values (`Returns:`).

**Example of a Google Style Docstring:**
```python
def my_function(param1: int, param2: str) -> bool:
    """This is a brief summary of the function's purpose.

    This section can contain a more detailed explanation of the function's
    behavior, algorithms, and any other relevant details.

    Args:
        param1: The first parameter, representing an integer value.
        param2: The second parameter, a string.

    Returns:
        A boolean value indicating success or failure.
    """
    # function implementation
    return True