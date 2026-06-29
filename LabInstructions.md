# Compiler Lab Instructions

## Overview
Build a compiler from simplest to most complex, level by level.

---

## Levels

| Level | Feature | Score |
|---|---|---|
| 001 | Arithmetic expression — grammar only | — |
| 002 | Arithmetic expression — compute directly | 60 |
| 003 | Arithmetic expression — generate AST *(optional)* | — |
| 004 | Arithmetic expression — generate LLVM IR (runs with `lli`) | — |
| 006 | Arithmetic expression — generate assembly code (runs with assembler) | — |
| 007 | Arithmetic + assign + variables → LLVM IR (must) / AST / TAC / assembly *(optional)* | 70 |
| 008 | Level 007 + if-then-else + while + boolean *(without short-circuit)* → LLVM IR (must) | 80 |
| 009 | Level 008 + boolean **with short-circuit** (`and` / `or`) → LLVM IR (must) | 85 |
| 010 | Level 009 + function definition + function call *(no arguments)* → LLVM IR (must) | 90+ |
| 011 | Level 010 + function definition + function call *(with arguments)* → LLVM IR (must) | 90+ |
| 012 | Level 011 + 1-dimensional array definition & use → LLVM IR (must) | 90+ |
| 013 | Level 012 + multi-dimensional array definition & use → LLVM IR (must) | 90+ |

---

## Optional Features (Extra Credit)

| Tag | Feature |
|---|---|
| A | Struct definition |
| B | Variable initialization when defining (`int a = ...;  int b = ..., c = ...;`) |
| C | Array variable initialization *(like SysY)* |
| D | Other features |

---

## Scoring Rules

1. Must be done **by groups yourselves**
2. Must be able to **understand the grammar and code** — show the teacher how it works
3. Score breakdown:

```
60  marks  →  Level 002
70  marks  →  Level 007
80  marks  →  Level 008
85  marks  →  Level 009
90+ marks  →  Level 010 and above (face-to-face checking with more features)
```

---

## Special Case — How to Get 100

Generate assembly code for a **CPU architecture + OS specific** target from the `.ll` IR file.

### Commands

```bash
# Step 1: Compile LLVM IR to x86-64 Intel assembly
llc -march=x86-64 -x86-asm-syntax=intel output.ll -o output.asm

# Step 2: Assemble to object file
# Add -g flag if you want to see realtime register and memory allocation/manipulation in a debugger (GDB)
gcc -x assembler -c output.asm -o output.o

# Step 3: Link to native binary
gcc output.o -o myprog

# Step 4: Run
./myprog
```

> **Note:** The final `myprog` binary can be copied and run directly on **any computer that matches the same CPU architecture and OS** — no environment setup needed.