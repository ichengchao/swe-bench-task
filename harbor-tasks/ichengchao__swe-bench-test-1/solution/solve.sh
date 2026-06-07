#!/bin/bash
set -e

cd /app

# Apply the gold patch to fix fibonacci(0)
cat <<'PATCH' | git apply -
diff --git a/mathutils/core.py b/mathutils/core.py
index 713fd8c..a54e80d 100644
--- a/mathutils/core.py
+++ b/mathutils/core.py
@@ -43,7 +43,9 @@ def fibonacci(n):
     """
     if n < 0:
         raise ValueError("Fibonacci is not defined for negative numbers")
-    if n <= 1:
+    if n == 0:
+        return 0
+    if n == 1:
         return 1
     a, b = 0, 1
     for _ in range(2, n + 1):
PATCH

echo "Gold patch applied successfully"
