# fibonacci(0) returns 1 instead of 0

## Bug Description

The `fibonacci(0)` function returns `1` instead of the expected `0`.

## Steps to Reproduce

```python
from mathutils import fibonacci

print(fibonacci(0))  # Expected: 0, Actual: 1
```

## Expected Behavior

`fibonacci(0)` should return `0`, since the Fibonacci sequence is defined as:
- F(0) = 0
- F(1) = 1
- F(n) = F(n-1) + F(n-2)

## Actual Behavior

`fibonacci(0)` returns `1`.

## Test Failure

```
FAILED tests/test_core.py::TestFibonacci::test_zero - assert 1 == 0
```

## Instructions

Please fix the bug in the repository located at `/app`. After fixing, all tests in `tests/test_core.py` should pass.
