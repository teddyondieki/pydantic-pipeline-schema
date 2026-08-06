#!/bin/bash

set -euo pipefail

cd "${TASK_WORKDIR:-/app}"

python - <<'PY'
from pathlib import Path

path = Path('pydantic/experimental/pipeline.py')
source = path.read_text()

# Native numeric schemas can accept the constraint values directly; pydantic-core
# performs the required conversion when it constructs the validator.  Keeping
# the constraint on that schema is what makes it appear in JSON Schema.
replacements = {
    """            if s['type'] == 'int' and isinstance(gt, int):
                s['gt'] = gt
            elif s['type'] == 'float' and isinstance(gt, float):
                s['gt'] = gt
            elif s['type'] == 'decimal' and isinstance(gt, Decimal):
                s['gt'] = gt
""": """            s['gt'] = gt  # pyright: ignore[reportGeneralTypeIssues]
""",
    """            if s['type'] == 'int' and isinstance(ge, int):
                s['ge'] = ge
            elif s['type'] == 'float' and isinstance(ge, float):
                s['ge'] = ge
            elif s['type'] == 'decimal' and isinstance(ge, Decimal):
                s['ge'] = ge
""": """            s['ge'] = ge  # pyright: ignore[reportGeneralTypeIssues]
""",
    """            if s['type'] == 'int' and isinstance(lt, int):
                s['lt'] = lt
            elif s['type'] == 'float' and isinstance(lt, float):
                s['lt'] = lt
            elif s['type'] == 'decimal' and isinstance(lt, Decimal):
                s['lt'] = lt
""": """            s['lt'] = lt  # pyright: ignore[reportGeneralTypeIssues]
""",
    """            if s['type'] == 'int' and isinstance(le, int):
                s['le'] = le
            elif s['type'] == 'float' and isinstance(le, float):
                s['le'] = le
            elif s['type'] == 'decimal' and isinstance(le, Decimal):
                s['le'] = le
""": """            s['le'] = le  # pyright: ignore[reportGeneralTypeIssues]
""",
    """            if s['type'] == 'int' and isinstance(multiple_of, int):
                s['multiple_of'] = multiple_of
            elif s['type'] == 'float' and isinstance(multiple_of, float):
                s['multiple_of'] = multiple_of
            elif s['type'] == 'decimal' and isinstance(multiple_of, Decimal):
                s['multiple_of'] = multiple_of
""": """            s['multiple_of'] = multiple_of  # pyright: ignore[reportGeneralTypeIssues]
""",
}

for old, new in replacements.items():
    if old not in source:
        raise RuntimeError('Expected pre-fix constraint block was not found')
    source = source.replace(old, new, 1)

for operator_name in ('ge', 'lt', 'le', 'multiple_of'):
    marker = f"    elif isinstance(constraint, annotated_types.{''.join(part.capitalize() for part in operator_name.split('_'))}):"
    start = source.index(marker)
    next_branch = source.find("    elif isinstance(constraint,", start + len(marker))
    if next_branch == -1:
        next_branch = source.find("    else:", start + len(marker))
    block = source[start:next_branch]
    function_start = block.index("\n        def check_")
    function = block[function_start:]
    prefix = block[:function_start]
    indented_function = function.replace("\n        ", "\n            ")
    replacement = prefix + "\n        else:" + indented_function
    source = source[:start] + replacement + source[next_branch:]

path.write_text(source)
PY
