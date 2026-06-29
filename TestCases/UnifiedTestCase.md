// ===================================================
// Unified Test Case — exercises every feature
// ===================================================

/* ---- Part 1: Arithmetic + declarations ---- */
int a = 10;
int b = 3;
print a + b;       // 13
print a - b;       // 7
print a * b;       // 30
print a / b;       // 3
print -a;          // -10

/* ---- Part 2: if / else / comparisons ---- */
if (a > b) {
    print 1;       // 1
} else {
    print 0;
}

/* ---- Part 3: logical operators with short-circuit ---- */
x = 5;
y = -1;
z = -1;
if (z > 0 && (x > 0 || y > 0)) {
    print 1;
} else {
    print 0;       // 0  (z>0 false -> short-circuits, x/y never evaluated)
}
if (x > 0 || y > 0) {
    print 1;        // 1  (x>0 true -> short-circuits, y never evaluated)
} else {
    print 0;
}
if (!(x < 0)) {
    print 1;        // 1
} else {
    print 0;
}

/* ---- Part 4: while + break + continue ---- */
i1 = 1;
sum = 0;
while (i1 <= 10) {
    if (i1 == 6) {
        break;
    }
    sum = sum + i1;
    i1 = i1 + 1;
}
print sum;          // 15  (1+2+3+4+5)

/* ---- Part 5: do-while ---- */
j1 = 1;
do {
    print j1;         // 1 2 3
    j1 = j1 + 1;
} while (j1 <= 3);

/* ---- Part 6: for + continue ---- */
for (k1 = 1; k1 <= 5; k1 = k1 + 1) {
    if (k1 == 3) {
        continue;
    }
    print k1;         // 1 2 4 5
}

/* ---- Part 7: functions without arguments ---- */
int getConstant() {
    return 100;
}
print getConstant();   // 100

/* ---- Part 8: functions with arguments ---- */
int add(int p1, int q1) {
    return p1 + q1;
}
print add(7, 8);        // 15

/* ---- Part 9: function calling function ---- */
int square(int n1) {
    return n1 * n1;
}
int sumOfSquares(int m1, int n2) {
    return square(m1) + square(n2);
}
print sumOfSquares(3, 4);  // 25

/* ---- Part 10: scope isolation ---- */
x = 999;
int scopedFn() {
    x = 111;
    return x;
}
scopedFn();
print x;                // 999 (main's x untouched)

/* ---- Part 11: function with loop + array inside ---- */
int sumArray() {
    int arr[5];
    for (m2 = 0; m2 < 5; m2 = m2 + 1) {
        arr[m2] = m2 + 1;
    }
    s1 = 0;
    for (m3 = 0; m3 < 5; m3 = m3 + 1) {
        s1 = s1 + arr[m3];
    }
    return s1;
}
print sumArray();       // 15

/* ---- Part 12: 1D array — fill, search, max ---- */
int data[5];
data[0] = 3;
data[1] = 7;
data[2] = 1;
data[3] = 9;
data[4] = 4;
maxVal = data[0];
for (n3 = 1; n3 < 5; n3 = n3 + 1) {
    if (data[n3] > maxVal) {
        maxVal = data[n3];
    }
}
print maxVal;            // 9

/* ---- Part 13: 2D array — matrix diagonal sum (trace) ---- */
int mat[3][3];
for (p2 = 0; p2 < 3; p2 = p2 + 1) {
    for (q2 = 0; q2 < 3; q2 = q2 + 1) {
        mat[p2][q2] = p2 * 3 + q2 + 1;
    }
}
trace = 0;
for (p3 = 0; p3 < 3; p3 = p3 + 1) {
    trace = trace + mat[p3][p3];
}
print trace;             // 15  (1+5+9)

/* ---- Part 14: 3D array — fill and sum ---- */
int cube[2][2][2];
total = 0;
for (p4 = 0; p4 < 2; p4 = p4 + 1) {
    for (q3 = 0; q3 < 2; q3 = q3 + 1) {
        for (r1 = 0; r1 < 2; r1 = r1 + 1) {
            cube[p4][q3][r1] = p4 * 4 + q3 * 2 + r1;
            total = total + cube[p4][q3][r1];
        }
    }
}
print total;             // 28

/* ---- Part 15: arrays + functions + logic combined ---- */
int isSorted() {
    int arr[5];
    arr[0] = 1; arr[1] = 3; arr[2] = 5; arr[3] = 7; arr[4] = 9;
    sorted = 1;
    for (t1 = 0; t1 < 4; t1 = t1 + 1) {
        if (arr[t1] > arr[t1 + 1]) {
            sorted = 0;
        }
    }
    return sorted;
}
if (isSorted() == 1 && maxVal > 0) {
    print 1;             // 1
} else {
    print 0;
}
```

---

## Expected Full Output (in order)

```
13
7
30
3
-10
1
0
1
1
15
1
2
3
1
2
4
5
100
15
25
999
15
9
15
28
1
```