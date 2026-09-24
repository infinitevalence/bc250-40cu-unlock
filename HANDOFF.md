# Task: Rewrite `bc250-enable-40cu-alpine.sh` to POSIX sh

## Breaking issue
Alpine Linux does **not** ship `bash` by default — it ships `busybox ash` as `/bin/sh` and `/bin/bash` (a symlink). The shebang `#!/usr/bin/env bash` fails on vanilla Alpine: no bash binary exists, script won't start.

**Goal:** rewrite the entire script as `#!/bin/sh` using only POSIX sh constructs. Each task below is self-contained — execute them sequentially.

---

## Task 1 — Shebang and `set`

**Change:**
- `#!/usr/bin/env bash` → `#!/bin/sh`
- `set -euo pipefail` → `set -e` (pipefail is not POSIX; POSIX sh has no guarantee)

**Files:** `scripts/bc250-enable-40cu-alpine.sh`

**After:** Script starts on vanilla Alpine. `set -e` still aborts on error.

---

## Task 2 — Remove all `local` declarations

**Change:** Replace every `local` declaration with a unique variable name using a function-name prefix to avoid scope collision. For example:

```sh
# Before:
check_bc250() {
  local detected=0
  ...
}

# After:
check_bc250() {
  detected=0
  ...
}
```

For functions that need to return a value, use `printf '%s\n' "$value"` and call via command substitution.

**Files:** `scripts/bc250-enable-40cu-alpine.sh`

**After:** No `local` keywords remain. All variables are global (intentional for POSIX sh).

---

## Task 3 — Replace `declare -A` (associative arrays)

**Change:** Replace associative arrays with a simple file or space-separated string lookup.

```sh
# Before:
declare -A skip_default
skip_default[12]=1
skip_default[19]=1
# ... etc.

# After:
skip_default="12 19 21 28"
# Check with: echo "$skip_default" | grep -qw "$pnum"
```

Or use a small temp file with one patch number per line, read with `grep`.

**Files:** `scripts/bc250-enable-40cu-alpine.sh`

**After:** No `declare -A` remains. Patch skip list works via simple string/file lookup.

---

## Task 4 — Replace bash arrays with POSIX-compatible strings

**Change:** Replace all bash array constructs with POSIX space-separated strings.

```sh
# Before:
declare -a patch_nums=()
patch_nums+=("$pnum")
for pnum in "${patch_nums[@]}"; do ...

# After:
patch_nums=""
patch_nums="${patch_nums} $pnum"
for pnum in $patch_nums; do ...
```

Also replace `selected_patches+=("$pnum")` with space-separated string append, and `${#selected_patches[@]}` with `echo "$selected_patches" | wc -w` or `echo "$selected_patches" | grep -o ' ' | wc -l` for count.

**Files:** `scripts/bc250-enable-40cu-alpine.sh`

**After:** No bash arrays (`( )`, `+=`, `[@]`) remain.

---

## Task 5 — Rewrite `patch_source()` interactive selection

**Change:** The entire interactive patch selection (the `for pnum in "${sorted_nums[@]}"` loop with `read` prompts, `case` parsing, array building) needs to be rewritten as a POSIX sh loop.

The logic: iterate patch numbers 01–30, show a yes/no prompt for each, build a string of selected numbers, then apply.

Key changes:
- Remove `${#selected_patches[@]}`, `selected_patches+=("$pnum")`, `case` inside loop
- Use space-separated string: `selected="${selected} $pnum"`
- Use `echo "$selected" | wc -w` for count
- Use `echo "$selected" | tr ' ' '\n' | sort -n` for ordered iteration

**Files:** `scripts/bc250-enable-40cu-alpine.sh`

**After:** No bash array syntax in `patch_source()`. Interactive prompts work identically.

---

## Task 6 — Fix remaining bashisms

**Change:** Scan for any remaining bash-specific constructs and fix them:

| Bashism | POSIX fix |
|---------|-----------|
| `[[ ]]` | Use `[ ]` |
| `${var:-}` or `${var:=}` with `:` | OK in POSIX, but check edge cases |
| `printf '\033[...` | OK in POSIX |
| `read -r` | OK in POSIX |
| `command -v` | OK in POSIX |
| `realpath` | Busybox has it; fine |
| `basename` | Busybox has it; fine |
| `cut`, `sort`, `head`, `tail`, `wc` | Busybox has them; fine |
| `nproc` | Busybox has it; fine |
| `dmesg` | Busybox has it; fine |

Also verify: `grep -qr`, `grep -o`, `grep -i` all work with busybox grep.

**Files:** `scripts/bc250-enable-40cu-alpine.sh`

**After:** Zero bashisms remain. Script runs on busybox ash.

---

## Verification checklist (run after all tasks)

1. `bash -n scripts/bc250-enable-40cu-alpine.sh` — no syntax errors
2. `dash -n scripts/bc250-enable-40cu-alpine.sh` — no syntax errors (dash = POSIX sh)
3. `busybox sh scripts/bc250-enable-40cu-alpine.sh --help` — runs without crash (no-op since no `--help`, but proves parsing works)
4. Verify `patch` is added to `check_deps` apk packages (bonus fix found during review)
