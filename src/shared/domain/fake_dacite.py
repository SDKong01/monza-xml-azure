import dataclasses
from typing import Any, Dict, Optional, List, get_origin, get_args, Union, Type, TypeVar
from enum import Enum

T = TypeVar('T')


def from_dict(data_class: Type[T], data: Dict[str, Any]) -> T:
    """Convert a dictionary to a dataclass instance with proper type conversion"""
    if not dataclasses.is_dataclass(data_class):
        return data
    kwargs = {}
    for field in dataclasses.fields(data_class):
        value = data.get(field.name)
        if value is None:
            kwargs[field.name] = None
            continue

        kwargs[field.name] = _convert_value(field.type, value)

    return data_class(**kwargs)


def _convert_value(field_type: Type[Any], value: Any) -> Any:
    """Convert a value to the appropriate type based on the field type annotation"""
    if value is None:
        return None

    origin = get_origin(field_type)
    args = get_args(field_type)

    # Handle Optional[T] and Union types
    if origin is Union:
        non_none_types = [arg for arg in args if arg is not type(None)]
        if len(non_none_types) == 1:
            return _convert_value(non_none_types[0], value)
        else:
            for arg_type in non_none_types:
                try:
                    return _convert_value(arg_type, value)
                except Exception:
                    continue
            return value

    # Handle List[T] types
    elif origin is list or origin is List:
        if not isinstance(value, list):
            return value
        if args:
            element_type = args[0]
            return [_convert_value(element_type, item) for item in value]
        return value

    # Handle nested dataclasses
    elif dataclasses.is_dataclass(field_type) and isinstance(value, dict):
        return from_dict(field_type, value)

    # Handle Enum types - auto-convert strings to Enum instances
    elif isinstance(field_type, type) and issubclass(field_type, Enum):
        # If already an Enum instance, return as is
        if isinstance(value, field_type):
            return value
        # If string, try to convert to Enum
        if isinstance(value, str):
            try:
                return field_type(value)
            except (ValueError, KeyError):
                # If conversion fails, try by name
                try:
                    return field_type[value]
                except KeyError:
                    # If all fails, return original value
                    return value
        # For other types, return as is
        return value

    else:
        return value


class StrEnum(str, Enum):
    def __str__(self):
        return self.value
