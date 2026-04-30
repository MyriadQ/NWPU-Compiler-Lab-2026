# exp.y — `dump_buffer` and if / if-else Logic Flow

This document explains two things in `exp.y`:

1. What the `dump_buffer` helper does and why it exists.
2. How the grammar implements `if` and `if/else`, mapped onto the IR in `output.ll`.

---

## 1. `dump_buffer` (exp.y:35-44)

```c
void dump_buffer(FILE *src){
    fflush(src);
    rewind(src);
    char chunk[4096];
    size_t n;
    while((n = fread(chunk, 1, sizeof(chunk), src)) > 0){
        fwrite(chunk, 1, n, ir_file);
    }
    fclose(src);
}
```

Think of it as a **"replay tape"** for IR that was buffered into a temporary file.

`src` is a `tmpfile()` we have been writing LLVM IR into instead of the real
`output.ll`. The function:

1. `fflush(src)` — pushes any stdio-buffered bytes out into the actual file.
2. `rewind(src)` — seeks back to byte 0 so we can read what we just wrote.
3. Reads the file in 4 KB chunks and writes each chunk straight into the
   *current* `ir_file` (which by the time this is called has been restored
   to `output.ll`, or to an outer tmpfile if we are nested inside another
   `if`).
4. `fclose(src)` — discards the temporary file. The OS automatically
   unlinks `tmpfile()` files when they are closed.

### Why does it exist?

When bison reduces `IF '(' expr ')'`, the IR for the condition has already
been emitted, but we **don't yet know** whether an `ELSE` clause will
follow. We also haven't decided the final names of `L_true / L_false /
L_end`. LLVM IR requires labels to appear in source order, before the
blocks that branch into them.

So instead of flushing the body straight to `output.ll`, we redirect
`ir_file` to a scratch tmpfile, let the body write into it, and replay the
bytes later in the correct order once we know the full structure.
`dump_buffer` is the replay step.

---

## 2. If / If-Else Logic Flow

The grammar is split into **three** rules so that each side-effect lands at
the right reduction point.

### Rule A — `if_cond` (exp.y:112-124)

Fires the moment `IF '(' expr ')'` has been recognized, *before* the body
parses.

```c
if_cond:
    IF '(' expr ')' {
        $$.cond       = $3;
        $$.l_true     = new_label();
        $$.l_end      = new_label();
        $$.l_false    = NULL;        // allocated lazily later
        $$.saved_file = ir_file;
        $$.true_body  = NULL;
        ir_file = tmpfile();         // body now writes here
    }
    ;
```

- `$$.cond` — the `i1` register holding the result of the condition.
- Allocates `l_true` and `l_end` immediately. We do **not** allocate
  `l_false` here because we do not yet know whether an `ELSE` will follow.
- Saves the current `ir_file` into `saved_file` so we can restore it
  later.
- Swaps `ir_file` to a fresh `tmpfile()` so the upcoming body's IR is
  buffered, not written into `output.ll`.

### Rule B — `if_else_prefix` (exp.y:126-135)

Fires after `if_cond '{' program '}' ELSE`, i.e. the moment we are
**committed** to having an `else` branch.

```c
if_else_prefix:
    if_cond '{' program '}' ELSE {
        $$ = $1;
        $$.l_false   = new_label();
        $$.true_body = ir_file;
        ir_file = tmpfile();
    }
    ;
```

- The true body is now sitting in the current `ir_file` tmpfile. Stash it
  in `$$.true_body`.
- Allocate `l_false` (now needed, because there is an `else`).
- Swap `ir_file` to **another** fresh `tmpfile()` so the false body's IR
  also gets buffered separately.

### Rule C1 — Full if/else (exp.y:148-173)

```c
| if_else_prefix '{' program '}' { ... }
```

Triggered when the `else { ... }` block has finished parsing. Emits IR in
final source order:

1. `FILE *false_body = ir_file;` — the current tmpfile is the false body.
2. `ir_file = $1.saved_file;` — restore to the real `output.ll` (or
   outer tmpfile).
3. Emit the deferred conditional branch:
   `br i1 %cond, label %L_true, label %L_false`.
4. Emit `L_true:`, then `dump_buffer(true_body)`, then `br label %L_end`.
5. Emit `L_false:`, then `dump_buffer(false_body)`, then `br label %L_end`.
6. Emit `L_end:` — the merge point.
7. Free the three label strings.

### Rule C2 — If only (exp.y:174-191)

```c
| if_cond '{' program '}' { ... }
```

Triggered when there is **no** `else`. The false target is simply
`L_end` — no dummy false block is created, and `l_false` stays `NULL` (so
nothing to free).

1. `FILE *body = ir_file;` — the current tmpfile is the (only) body.
2. `ir_file = $1.saved_file;` — restore.
3. Emit `br i1 %cond, label %L_true, label %L_end`.
4. Emit `L_true:`, then `dump_buffer(body)`, then `br label %L_end`.
5. Emit `L_end:`.
6. Free `l_true` and `l_end`.

---

## 3. Mapping to `output.ll`

The IR currently in `output.ll` corresponds to roughly:

```
a = 10;
if (a < 50) { print 1; }
```

This is an **if-only** case, so it follows Rule C2.

| `output.ll` line                                   | What in `exp.y` generated it |
|----------------------------------------------------|-------------------------------|
| 7  `%t0 = add i32 10, 0`                            | `expr: INTEGER` for `10`. Written to the **real** `ir_file` because no `if_cond` is active yet. |
| 8  `%var_a = alloca i32, align 4`                   | `get_var_alloca("a")` — first reference to `a`. |
| 9  `store i32 %t0, i32* %var_a, align 4`            | `stmt: IDENT '=' expr ';'`. |
| 10 `%t1 = load i32, i32* %var_a, align 4`           | `expr: IDENT` for `a` inside the condition. |
| 11 `%t2 = add i32 50, 0`                            | `expr: INTEGER` for `50`. |
| 12 `%t3 = icmp slt i32 %t1, %t2`                    | `expr: expr '<' expr`. |
| (Note) `if_cond`'s action runs **after** `expr` is built, so lines 10–12 land in the real `output.ll`. The tmpfile swap happens just before the body parses. | |
| 13 `br i1 %t3, label %L0, label %L1`                | exp.y:179 — the deferred conditional branch (Rule C2). |
| 14 `L0:`                                            | exp.y:182 — the `l_true` label definition. |
| 15 `%t4 = add i32 1, 0`                             | `expr: INTEGER` for `1`, **replayed** from the tmpfile by `dump_buffer(body)` on exp.y:183. |
| 16 `call i32 (i8*, ...) @printf(...)`               | `gen_print_int` from `PRINT expr ';'`, also replayed. |
| 17 `br label %L1`                                   | exp.y:184 — fallthrough from the true block to the merge label. |
| 18 `L1:`                                            | exp.y:186 — the `l_end` label, which in the if-only case doubles as the false target. |

### Note on `%` prefixes

`new_label()` returns a bare name like `L0`, no `%`. The `%` is added in
the `printf` format string when the label is **used**:

- Use:        `label %%%s`  →  `label %L0` (the `%%` prints a literal
  `%`, then `%s` substitutes the name).
- Definition: `%s:`         →  `L0:`        (no `%`, which is correct
  LLVM syntax for a label definition).

### What an if/else case would look like

If the input had been e.g. `if (a < 50) { print 1; } else { print 2; }`,
the same flow would have produced an additional false block between the
true block's `br label %L_end` and the `L_end:` label — its body sourced
from the **second** tmpfile via `dump_buffer(false_body)`.
