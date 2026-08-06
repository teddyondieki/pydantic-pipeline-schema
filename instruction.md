# Chained pipeline constraints are missing from generated JSON Schema

## Summary

`pydantic.experimental.pipeline` validation works for chained numeric
constraints, but `TypeAdapter.json_schema()` does not always include every
constraint in the resulting schema.

## Steps to reproduce

Build a pipeline from a numeric type with more than one constraint, for
example a lower bound, upper bound, and `multiple_of` constraint.

## Expected behavior

The generated JSON Schema should include each applicable constraint, including
inclusive and exclusive bounds and `multipleOf`, regardless of the order in
which compatible constraints were added. Constraints supplied through
`annotated_types.Interval` should behave the same way.

Existing validation behavior must remain unchanged, including pipelines that
apply a transformation before adding a constraint.