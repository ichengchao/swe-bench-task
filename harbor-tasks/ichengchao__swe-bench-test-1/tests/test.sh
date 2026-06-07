#!/bin/bash
set -e

cd /app

REWARD=0

# Step 1: Run FAIL_TO_PASS tests (these must now pass after the fix)
echo "=== Running FAIL_TO_PASS tests ==="
if python -m pytest tests/test_core.py::TestFibonacci::test_zero -v; then
    echo "FAIL_TO_PASS: PASSED"
else
    echo "FAIL_TO_PASS: FAILED"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Step 2: Run PASS_TO_PASS tests (these must still pass, no regressions)
echo ""
echo "=== Running PASS_TO_PASS tests ==="
PASS_TO_PASS_TESTS=(
    "tests/test_core.py::TestAdd::test_positive"
    "tests/test_core.py::TestAdd::test_negative"
    "tests/test_core.py::TestAdd::test_zero"
    "tests/test_core.py::TestSubtract::test_basic"
    "tests/test_core.py::TestSubtract::test_negative_result"
    "tests/test_core.py::TestMultiply::test_basic"
    "tests/test_core.py::TestMultiply::test_zero"
    "tests/test_core.py::TestDivide::test_basic"
    "tests/test_core.py::TestDivide::test_float_result"
    "tests/test_core.py::TestDivide::test_divide_by_zero"
    "tests/test_core.py::TestFactorial::test_zero"
    "tests/test_core.py::TestFactorial::test_one"
    "tests/test_core.py::TestFactorial::test_five"
    "tests/test_core.py::TestFactorial::test_negative"
    "tests/test_core.py::TestFibonacci::test_one"
    "tests/test_core.py::TestFibonacci::test_two"
    "tests/test_core.py::TestFibonacci::test_ten"
    "tests/test_core.py::TestFibonacci::test_negative"
)

if python -m pytest "${PASS_TO_PASS_TESTS[@]}" -v; then
    echo "PASS_TO_PASS: ALL PASSED"
    REWARD=1
else
    echo "PASS_TO_PASS: REGRESSION DETECTED"
    REWARD=0
fi

# Write reward
mkdir -p /logs/verifier
echo $REWARD > /logs/verifier/reward.txt

echo ""
echo "=== Result: reward=$REWARD ==="
exit $(( 1 - REWARD ))
