from typing import Annotated

import pytest
from annotated_types import Interval
from pydantic import TypeAdapter, ValidationError
from pydantic.experimental.pipeline import validate_as


def pipeline_schema(pipeline):
    return TypeAdapter(Annotated[int, pipeline]).json_schema()


@pytest.mark.parametrize(
    ("pipeline", "expected"),
    [
        (
            validate_as(int).ge(1).le(100),
            {"type": "integer", "minimum": 1, "maximum": 100},
        ),
        (
            validate_as(int).le(100).ge(1),
            {"type": "integer", "minimum": 1, "maximum": 100},
        ),
        (
            validate_as(int).constrain(Interval(ge=1, le=100)),
            {"type": "integer", "minimum": 1, "maximum": 100},
        ),
        (
            validate_as(int).ge(1).le(100).multiple_of(5),
            {"type": "integer", "minimum": 1, "maximum": 100, "multipleOf": 5},
        ),
        (
            validate_as(int).ge(1).multiple_of(5),
            {"type": "integer", "minimum": 1, "multipleOf": 5},
        ),
        (
            validate_as(int).le(100).multiple_of(5),
            {"type": "integer", "maximum": 100, "multipleOf": 5},
        ),
        (
            validate_as(int).multiple_of(5).ge(1).le(100),
            {"type": "integer", "minimum": 1, "maximum": 100, "multipleOf": 5},
        ),
        (
            validate_as(int).ge(1).gt(0).le(100),
            {"type": "integer", "minimum": 1, "exclusiveMinimum": 0, "maximum": 100},
        ),
        (
            validate_as(float).ge(1.0).le(2.5),
            {"type": "number", "minimum": 1.0, "maximum": 2.5},
        ),
        (
            validate_as(int).gt(1).lt(100),
            {"type": "integer", "exclusiveMinimum": 1, "exclusiveMaximum": 100},
        ),
    ],
)
def test_json_schema_keeps_every_chained_constraint(pipeline, expected):
    assert pipeline_schema(pipeline) == expected


def test_float_constraints_are_not_lost_from_json_schema():
    schema = TypeAdapter(Annotated[float, validate_as(float).ge(1).le(2.5).multiple_of(0.5)]).json_schema()
    assert schema == {"type": "number", "minimum": 1, "maximum": 2.5, "multipleOf": 0.5}


def test_chained_constraints_still_validate_each_requirement():
    adapter = TypeAdapter(Annotated[int, validate_as(int).ge(1).le(100).multiple_of(5)])

    assert adapter.validate_python(5) == 5
    assert adapter.validate_python(100) == 100

    for value in (0, 101, 52):
        with pytest.raises(ValidationError):
            adapter.validate_python(value)


def test_constraints_after_a_transform_keep_existing_validation_behavior():
    adapter = TypeAdapter(Annotated[int, validate_as(int).transform(lambda value: value).ge(0)])

    assert adapter.validate_python(0) == 0
    with pytest.raises(ValidationError):
        adapter.validate_python(-1)
