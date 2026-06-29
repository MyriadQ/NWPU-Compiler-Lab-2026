# Compiler Test Cases:
**Coverage:** Arithmetic, If/Else, Loops, Logical Operators, Functions, 1D/2D/ND Arrays

---

# 🟢 BASIC
> Single concept per test. Verifies each feature works in isolation.

---

### B01 — Arithmetic: all four operators
```
a = 20;
b = 4;
print a + b;
print a - b;
print a * b;
print a / b;
```
**Expected:** `24 / 16 / 80 / 5`

---

### B02 — Unary minus and parentheses
```
x = 5;
print -x;
print (2 + 3) * 4;
print 10 / (1 + 1);
```
**Expected:** `-5 / 20 / 5`

---

### B03 — Variable overwrite
```
x = 1;
print x;
x = x + 1;
print x;
x = x * 3;
print x;
```
**Expected:** `1 / 2 / 6`

---

### B04 — If: true branch taken
```
x = 10;
if (x > 5) {
    print 1;
}
```
**Expected:** `1`

---

### B05 — If-else: both branches
```
x = 3;
if (x > 5) { print 1; } else { print 0; }
x = 10;
if (x > 5) { print 1; } else { print 0; }
```
**Expected:** `0 / 1`

---

### B06 — All 6 comparison operators
```
a = 5;
b = 5;
if (a == b) { print 1; } else { print 0; }
if (a != b) { print 1; } else { print 0; }
if (a <= b) { print 1; } else { print 0; }
if (a >= b) { print 1; } else { print 0; }
if (a <  b) { print 1; } else { print 0; }
if (a >  b) { print 1; } else { print 0; }
```
**Expected:** `1 / 0 / 1 / 1 / 0 / 0`

---

### B07 — While loop: basic count
```
i = 1;
while (i <= 5) {
    print i;
    i = i + 1;
}
```
**Expected:** `1 / 2 / 3 / 4 / 5`

---

### B08 — While loop: condition false from start
```
x = 10;
while (x < 5) {
    print x;
}
print 99;
```
**Expected:** `99`

---

### B09 — For loop: basic count
```
for (i = 1; i <= 5; i = i + 1) {
    print i;
}
```
**Expected:** `1 / 2 / 3 / 4 / 5`

---

### B10 — For loop: countdown
```
for (i = 5; i > 0; i = i - 1) {
    print i;
}
```
**Expected:** `5 / 4 / 3 / 2 / 1`

---

### B11 — Do-while: always runs once
```
x = 10;
do {
    print x;
    x = x + 1;
} while (x < 5);
```
**Expected:** `10`

---

### B12 — Do-while: normal loop
```
i = 1;
do {
    print i;
    i = i + 1;
} while (i <= 4);
```
**Expected:** `1 / 2 / 3 / 4`

---

### B13 — Logical AND: truth table
```
a = 1; b = 1;
if (a > 0 && b > 0) { print 1; } else { print 0; }
a = 1; b = 0;
if (a > 0 && b > 0) { print 1; } else { print 0; }
a = 0; b = 0;
if (a > 0 && b > 0) { print 1; } else { print 0; }
```
**Expected:** `1 / 0 / 0`

---

### B14 — Logical OR: truth table
```
a = 1; b = 0;
if (a > 0 || b > 0) { print 1; } else { print 0; }
a = 0; b = 0;
if (a > 0 || b > 0) { print 1; } else { print 0; }
```
**Expected:** `1 / 0`

---

### B15 — Logical NOT
```
x = 5;
if (!(x > 0)) { print 1; } else { print 0; }
x = -5;
if (!(x > 0)) { print 1; } else { print 0; }
```
**Expected:** `0 / 1`

---

### B16 — Function: return constant, call as expression
```
int getVal() {
    return 42;
}
print getVal();
```
**Expected:** `42`

---

### B17 — Function: local variables
```
int add() {
    a = 3;
    b = 4;
    return a + b;
}
print add();
```
**Expected:** `7`

---

### B18 — Function with one argument
```
int double(int x) {
    return x * 2;
}
print double(5);
```
**Expected:** `10`

---

### B19 — Function with two arguments
```
int add(int a, int b) {
    return a + b;
}
print add(3, 4);
```
**Expected:** `7`

---

### B20 — 1D array: declare, write, read
```
int arr[5];
arr[0] = 10;
arr[4] = 50;
print arr[0];
print arr[4];
```
**Expected:** `10 / 50`

---

### B21 — 1D array: variable index
```
int arr[5];
arr[2] = 42;
i = 2;
print arr[i];
```
**Expected:** `42`

---

### B22 — 2D array: declare, write, read
```
int mat[3][3];
mat[0][0] = 1;
mat[1][1] = 5;
mat[2][2] = 9;
print mat[0][0];
print mat[1][1];
print mat[2][2];
```
**Expected:** `1 / 5 / 9`

---

### B23 — int x = expr; declaration syntax
```
int a = 10;
int b = 20;
int c = a + b;
print c;
```
**Expected:** `30`

---

### B24 — Comments are ignored
```
// this is a comment
x = 5; // inline comment
/* block
   comment */
print x;
```
**Expected:** `5`

---

### B25 — break in while loop
```
i = 1;
while (i <= 10) {
    if (i == 4) {
        break;
    }
    print i;
    i = i + 1;
}
```
**Expected:** `1 / 2 / 3`

---

### B26 — continue in for loop
```
for (i = 1; i <= 5; i = i + 1) {
    if (i == 3) {
        continue;
    }
    print i;
}
```
**Expected:** `1 / 2 / 4 / 5`

---

---

# 🟡 INTERMEDIATE
> Two or more features combined. Tests feature interactions.

---

### I01 — Nested if-else (3-way branch)
```
x = 0;
if (x > 0) {
    print 1;
} else {
    if (x < 0) {
        print -1;
    } else {
        print 0;
    }
}
```
**Expected:** `0`

---

### I02 — If-else inside for loop
```
for (i = 1; i <= 6; i = i + 1) {
    if (i == 3) {
        print 100;
    } else {
        print i;
    }
}
```
**Expected:** `1 / 2 / 100 / 4 / 5 / 6`

---

### I03 — Logical AND precedence over OR
```
x = 5; y = -1; z = -1;
if (x > 0 || y > 0 && z > 0) { print 1; } else { print 0; }
if ((x > 0 || y > 0) && z > 0) { print 1; } else { print 0; }
```
**Why:** First: `x>0 || (y>0 && z>0)` = true. Second: `(true || false) && false` = false.

**Expected:** `1 / 0`

---

### I04 — De Morgan's Law verification
```
x = 5; y = -1;
if (!(x > 0 && y > 0)) { print 1; } else { print 0; }
if (!(x > 0) || !(y > 0)) { print 1; } else { print 0; }
```
**Why:** Both expressions are logically identical — must print same value.

**Expected:** `1 / 1`

---

### I05 — Logical AND in while condition
```
i = 1;
while (i > 0 && i < 6) {
    print i;
    i = i + 1;
}
```
**Expected:** `1 / 2 / 3 / 4 / 5`

---

### I06 — Range check using AND
```
x = 7;
if (x >= 1 && x <= 10) { print 1; } else { print 0; }
x = 15;
if (x >= 1 && x <= 10) { print 1; } else { print 0; }
```
**Expected:** `1 / 0`

---

### I07 — While loop: sum 1 to 10
```
i = 1;
sum = 0;
while (i <= 10) {
    sum = sum + i;
    i = i + 1;
}
print sum;
```
**Expected:** `55`

---

### I08 — Nested while: multiplication table
```
i = 1;
while (i <= 3) {
    j = 1;
    while (j <= 3) {
        print i * j;
        j = j + 1;
    }
    i = i + 1;
}
```
**Expected:** `1 2 3 / 2 4 6 / 3 6 9`

---

### I09 — Function called multiple times, result in expression
```
int getVal() {
    return 5;
}
result = getVal() * 3 + 1;
print result;
print getVal();
print getVal();
```
**Expected:** `16 / 5 / 5`

---

### I10 — Function with args: result used in expression
```
int multiply(int a, int b) {
    return a * b;
}
result = multiply(3, 4) + multiply(2, 5);
print result;
```
**Expected:** `22`

---

### I11 — Function call inside if condition
```
int getFlag() {
    return 1;
}
if (getFlag()) {
    print 100;
} else {
    print 0;
}
```
**Expected:** `100`

---

### I12 — Scope isolation: function local vs main variable
```
x = 100;
int fn() {
    x = 999;
    return x;
}
fn();
print x;
```
**Why:** `fn()` has its own `x`. Main's `x` must still be `100`.

**Expected:** `100`

---

### I13 — Function calling another function
```
int inner() {
    return 7;
}
int outer() {
    return inner() + 1;
}
print outer();
```
**Expected:** `8`

---

### I14 — While loop inside function
```
int sumTo() {
    i = 1;
    s = 0;
    while (i <= 5) {
        s = s + i;
        i = i + 1;
    }
    return s;
}
print sumTo();
```
**Expected:** `15`

---

### I15 — 1D array: fill with for loop, sum all elements
```
int arr[5];
for (i = 0; i < 5; i = i + 1) {
    arr[i] = i + 1;
}
sum = 0;
for (i = 0; i < 5; i = i + 1) {
    sum = sum + arr[i];
}
print sum;
```
**Expected:** `15`

---

### I16 — 1D array: find max element
```
int arr[5];
arr[0] = 3; arr[1] = 7; arr[2] = 1; arr[3] = 9; arr[4] = 4;
max = arr[0];
for (i = 1; i < 5; i = i + 1) {
    if (arr[i] > max) {
        max = arr[i];
    }
}
print max;
```
**Expected:** `9`

---

### I17 — 1D array: linear search
```
int arr[5];
arr[0] = 10; arr[1] = 20; arr[2] = 30; arr[3] = 40; arr[4] = 50;
target = 30;
found = 0;
for (i = 0; i < 5; i = i + 1) {
    if (arr[i] == target) { found = 1; }
}
print found;
```
**Expected:** `1`

---

### I18 — 1D array: expression as index
```
int arr[5];
arr[1] = 55;
arr[2] = 66;
arr[3] = 77;
i = 1;
print arr[i + 1];
```
**Expected:** `66`

---

### I19 — 2D array: fill and sum all elements
```
int mat[3][3];
for (i = 0; i < 3; i = i + 1) {
    for (j = 0; j < 3; j = j + 1) {
        mat[i][j] = i * 3 + j + 1;
    }
}
sum = 0;
for (i = 0; i < 3; i = i + 1) {
    for (j = 0; j < 3; j = j + 1) {
        sum = sum + mat[i][j];
    }
}
print sum;
```
**Expected:** `45`

---

### I20 — 2D array: row sums
```
int mat[3][3];
mat[0][0] = 1; mat[0][1] = 2; mat[0][2] = 3;
mat[1][0] = 4; mat[1][1] = 5; mat[1][2] = 6;
mat[2][0] = 7; mat[2][1] = 8; mat[2][2] = 9;
for (i = 0; i < 3; i = i + 1) {
    rowsum = 0;
    for (j = 0; j < 3; j = j + 1) {
        rowsum = rowsum + mat[i][j];
    }
    print rowsum;
}
```
**Expected:** `6 / 15 / 24`

---

### I21 — 2D array: element in condition
```
int mat[3][3];
mat[0][0] = 10;
mat[1][1] = 2;
if (mat[0][0] > mat[1][1]) { print 1; } else { print 0; }
```
**Expected:** `1`

---

### I22 — break inside nested loop (inner only)
```
for (i = 1; i <= 3; i = i + 1) {
    for (j = 1; j <= 5; j = j + 1) {
        if (j == 3) { break; }
        print j;
    }
    print 0;
}
```
**Expected:** `1 2 0 / 1 2 0 / 1 2 0`

---

### I23 — Early return vs fallthrough return
```
int classify(int x) {
    if (x > 0) { return 1; }
    return 0;
}
print classify(5);
print classify(-3);
```
**Expected:** `1 / 0`

---

### I24 — Function with if/else inside
```
int max(int a, int b) {
    if (a > b) {
        return a;
    } else {
        return b;
    }
}
print max(10, 7);
print max(3, 9);
```
**Expected:** `10 / 9`

---

### I25 — Two separate 1D arrays, copy operation
```
int src[4];
int dst[4];
src[0] = 5; src[1] = 10; src[2] = 15; src[3] = 20;
for (i = 0; i < 4; i = i + 1) {
    dst[i] = src[i];
}
print dst[0];
print dst[3];
```
**Expected:** `5 / 20`

---

---

# 🔴 ADVANCED
> Multi-feature integration. Tests correctness of complex interactions.

---

### A01 — Short-circuit AND: RHS skipped when LHS false
```
z = -1;
x = 5;
y = 10;
if (z > 0 && (x > 0 || y > 0)) { print 1; } else { print 0; }
```
**Why:** `z > 0` is false → `&&` short-circuits → `x > 0 || y > 0` never evaluated.

**Expected:** `0`

---

### A02 — Short-circuit OR: RHS skipped when LHS true
```
x = 5;
y = -1;
if (x > 0 || y > 0) { print 1; } else { print 0; }
```
**Why:** `x > 0` is true → `||` short-circuits → `y > 0` never evaluated.

**Expected:** `1`

---

### A03 — Double NOT cancels out
```
x = 5;
if (!(!(x > 0))) { print 1; } else { print 0; }
```
**Expected:** `1`

---

### A04 — Fibonacci: iterative using while
```
a = 0; b = 1; i = 0;
print a;
print b;
while (i < 6) {
    c = a + b;
    print c;
    a = b;
    b = c;
    i = i + 1;
}
```
**Expected:** `0 / 1 / 1 / 2 / 3 / 5 / 8 / 13`

---

### A05 — Factorial using while
```
n = 5;
result = 1;
i = 1;
while (i <= n) {
    result = result * i;
    i = i + 1;
}
print result;
```
**Expected:** `120`

---

### A06 — Power: 2^8
```
base = 2; exp = 8; result = 1; i = 0;
while (i < exp) {
    result = result * base;
    i = i + 1;
}
print result;
```
**Expected:** `256`

---

### A07 — Fibonacci stored in 1D array
```
int fib[8];
fib[0] = 0;
fib[1] = 1;
for (i = 2; i < 8; i = i + 1) {
    fib[i] = fib[i - 1] + fib[i - 2];
}
for (i = 0; i < 8; i = i + 1) {
    print fib[i];
}
```
**Expected:** `0 / 1 / 1 / 2 / 3 / 5 / 8 / 13`

---

### A08 — Bubble sort (one full pass)
```
int arr[5];
arr[0] = 5; arr[1] = 3; arr[2] = 8; arr[3] = 1; arr[4] = 4;
for (i = 0; i < 4; i = i + 1) {
    if (arr[i] > arr[i + 1]) {
        temp = arr[i];
        arr[i] = arr[i + 1];
        arr[i + 1] = temp;
    }
}
for (i = 0; i < 5; i = i + 1) {
    print arr[i];
}
```
**Expected:** `3 / 5 / 1 / 4 / 8`

---

### A09 — Matrix transpose
```
int mat[3][3];
int trans[3][3];
mat[0][0] = 1; mat[0][1] = 2; mat[0][2] = 3;
mat[1][0] = 4; mat[1][1] = 5; mat[1][2] = 6;
mat[2][0] = 7; mat[2][1] = 8; mat[2][2] = 9;
for (i = 0; i < 3; i = i + 1) {
    for (j = 0; j < 3; j = j + 1) {
        trans[j][i] = mat[i][j];
    }
}
print trans[0][1];
print trans[1][0];
print trans[0][2];
print trans[2][0];
```
**Expected:** `4 / 2 / 7 / 3`

---

### A10 — Matrix diagonal sum (trace)
```
int mat[3][3];
mat[0][0] = 1; mat[0][1] = 2; mat[0][2] = 3;
mat[1][0] = 4; mat[1][1] = 5; mat[1][2] = 6;
mat[2][0] = 7; mat[2][1] = 8; mat[2][2] = 9;
trace = 0;
for (i = 0; i < 3; i = i + 1) {
    trace = trace + mat[i][i];
}
print trace;
```
**Expected:** `15`

---

### A11 — Check if 2D matrix is symmetric
```
int mat[3][3];
mat[0][0] = 1; mat[0][1] = 2; mat[0][2] = 3;
mat[1][0] = 2; mat[1][1] = 5; mat[1][2] = 6;
mat[2][0] = 3; mat[2][1] = 6; mat[2][2] = 9;
symmetric = 1;
for (i = 0; i < 3; i = i + 1) {
    for (j = 0; j < 3; j = j + 1) {
        if (mat[i][j] != mat[j][i]) { symmetric = 0; }
    }
}
print symmetric;
```
**Expected:** `1`

---

### A12 — 2x2 matrix multiplication
```
int a[2][2];
int b[2][2];
int c[2][2];
a[0][0] = 1; a[0][1] = 2; a[1][0] = 3; a[1][1] = 4;
b[0][0] = 5; b[0][1] = 6; b[1][0] = 7; b[1][1] = 8;
for (i = 0; i < 2; i = i + 1) {
    for (j = 0; j < 2; j = j + 1) {
        c[i][j] = 0;
        for (k = 0; k < 2; k = k + 1) {
            c[i][j] = c[i][j] + a[i][k] * b[k][j];
        }
    }
}
print c[0][0];
print c[0][1];
print c[1][0];
print c[1][1];
```
**Expected:** `19 / 22 / 43 / 50`

---

### A13 — 3D array: fill with triple loop and sum
```
int cube[2][2][2];
for (i = 0; i < 2; i = i + 1) {
    for (j = 0; j < 2; j = j + 1) {
        for (k = 0; k < 2; k = k + 1) {
            cube[i][j][k] = i * 4 + j * 2 + k;
        }
    }
}
sum = 0;
for (i = 0; i < 2; i = i + 1) {
    for (j = 0; j < 2; j = j + 1) {
        for (k = 0; k < 2; k = k + 1) {
            sum = sum + cube[i][j][k];
        }
    }
}
print sum;
```
**Expected:** `28`

---

### A14 — 4D array: declare, write, read
```
int arr4[2][2][2][2];
arr4[0][0][0][0] = 111;
arr4[1][1][1][1] = 222;
print arr4[0][0][0][0];
print arr4[1][1][1][1];
```
**Expected:** `111 / 222`

---

### A15 — 1D + 2D arrays used together
```
int arr[3];
int mat[3][3];
arr[0] = 1; arr[1] = 2; arr[2] = 3;
for (i = 0; i < 3; i = i + 1) {
    for (j = 0; j < 3; j = j + 1) {
        mat[i][j] = arr[i] * arr[j];
    }
}
print mat[0][0];
print mat[1][1];
print mat[2][2];
print mat[0][2];
```
**Expected:** `1 / 4 / 9 / 3`

---

### A16 — Iterative Fibonacci inside function
```
int fib() {
    a = 0; b = 1; i = 0;
    while (i < 7) {
        tmp = a + b;
        a = b;
        b = tmp;
        i = i + 1;
    }
    return a;
}
print fib();
```
**Expected:** `13`

---

### A17 — Recursive-style: function calling another function with args
```
int square(int x) {
    return x * x;
}
int sumOfSquares(int a, int b) {
    return square(a) + square(b);
}
print sumOfSquares(3, 4);
```
**Expected:** `25`

---

### A18 — Function with loop and array inside
```
int sumArr() {
    int arr[5];
    arr[0] = 1; arr[1] = 2; arr[2] = 3; arr[3] = 4; arr[4] = 5;
    s = 0;
    for (i = 0; i < 5; i = i + 1) {
        s = s + arr[i];
    }
    return s;
}
print sumArr();
```
**Expected:** `15`

---

### A19 — Multiple functions + scope: same variable name, no bleed
```
int square() {
    x = 6;
    return x * x;
}
int cube() {
    x = 3;
    return x * x * x;
}
print square();
print cube();
```
**Expected:** `36 / 27`

---

### A20 — Logical operators in complex nested condition
```
a = 5; b = 3; c = -1;
if (a > 0 && b > 0 && !(c > 0)) {
    print 1;
} else {
    print 0;
}
```
**Expected:** `1`

---

### A21 — Break to exit nested loop early
```
found = 0;
int arr[5];
arr[0] = 3; arr[1] = 7; arr[2] = 1; arr[3] = 9; arr[4] = 4;
i = 0;
while (i < 5 && found == 0) {
    if (arr[i] == 9) {
        found = i;
    }
    i = i + 1;
}
print found;
```
**Expected:** `3`

---

### A22 — Power function using for loop
```
int power(int base, int exp) {
    result = 1;
    for (i = 0; i < exp; i = i + 1) {
        result = result * base;
    }
    return result;
}
print power(2, 8);
print power(3, 3);
```
**Expected:** `256 / 27`

---

### A23 — Short-circuit with function call chain
```
int alwaysZero() {
    return 0;
}
int getOne() {
    return 1;
}
if (alwaysZero() == 0 && getOne() > 0) { print 1; } else { print 0; }
if (getOne() > 0 || alwaysZero() > 0)  { print 1; } else { print 0; }
```
**Expected:** `1 / 1`

---

### A24 — 3D array with variable indices and condition
```
int cube[2][2][2];
cube[0][0][0] = 5;
cube[1][1][1] = 10;
x = 1; y = 1; z = 1;
if (cube[x][y][z] > cube[0][0][0]) {
    print 1;
} else {
    print 0;
}
```
**Expected:** `1`

---

### A25 — Element-wise addition of two 2D matrices
```
int a[2][2];
int b[2][2];
int c[2][2];
a[0][0] = 1; a[0][1] = 2; a[1][0] = 3; a[1][1] = 4;
b[0][0] = 5; b[0][1] = 6; b[1][0] = 7; b[1][1] = 8;
for (i = 0; i < 2; i = i + 1) {
    for (j = 0; j < 2; j = j + 1) {
        c[i][j] = a[i][j] + b[i][j];
    }
}
print c[0][0];
print c[0][1];
print c[1][0];
print c[1][1];
```
**Expected:** `6 / 8 / 10 / 12`

---

## Test Count Summary

| Category | Count | Features Covered |
| 🟢 Basic | 26 | Arithmetic, if/else, while, for, do-while, logical ops, functions, 1D/2D arrays, comments, break, continue |
| 🟡 Intermediate | 25 | Nested constructs, logical precedence, De Morgan, functions with args, scope, arrays in loops, 2D arrays |
| 🔴 Advanced | 25 | Short-circuit, algorithms, matrix ops, ND arrays, function chains, complex conditions |
| **Total** | **76** |
