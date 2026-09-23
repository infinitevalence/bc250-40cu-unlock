# Task: Extend `patch_source()` to apply all patches

## Context

`scripts/bc250-enable-40cu-alpine.sh` currently has `patch_source()` which applies **one** patch (`bc250-40cu-amdgpu.patch`) from GitHub via `curl | patch -p1`. The `patch/` directory contains 30 numbered patches (01.patch through 30.patch) plus a `bc250-cachyos-7.0.9/` subdirectory with identical copies. These patches are applied against the kernel source tree, and `patch -p1` handles all their formats (git diffs, unified diffs, partial git headers).

The script's `do_build()` function calls `patch_source()` and then builds the kernel module. Only the one patch is applied.

## Patch series state

Patches in `patch/SERIES.md` define what's applied vs not. **Applied** (these should be applied in order): 01–11, 13–15, 16–18, 20, 22–28, 29–30. **On-disk but NOT applied** (skip them): 12 (Vulkan-only CU unlock, hangs ROCm), 19 (SDMA0 skip, retired), 21 (KIQ PASID-flush, superseded by patch 14). Patch 28 is the 8-core CPU telemetry fix.

Patches come in three formats — `patch -p1` handles all:
- Git-format (`From <hash>` header) — patches 12–17
- Unified diffs (`--- a/...` header) — patches 01–11, 29
- Partial git headers (preamble text + `Subject:` + `---` + `diff`) — patches 18–28, 30

The `bc250-cachyos-7.0.9/` subdirectory contains identical copies (same format, same content). Use files from `patch/*.patch` (not the subdir).

## Task

Modify `patch_source()` in `scripts/bc250-enable-40cu-alpine.sh` to:

1. **Apply all applied patches** from `patch/` in sorted order (01–11, 13–15, 16–18, 20, 22–28, 29, 30) — skip 12, 19, 21
2. **Skip if already patched** — the existing `grep 'bc250_cc_write_mode'` check is good; keep it but also check each patch individually so you know which one failed
3. **Support verbose mode** — add a `--verbose` flag (or `-v` argv) that prints each patch name + result (applied / already present / failed)
4. **Exit on failure** — `set -euo pipefail` is already active; if a patch fails to apply, die with an error message

### Implementation details

- Use a glob or explicit list for patch ordering. Since filenames are `NN.patch` with zero-padded numbers, `patch/*.patch | sort` gives correct order. Filter out the three unapplied patches (12, 19, 21) before applying.
- Current working directory in `patch_source()` is `cd "$MODSRC"` — apply each patch from there with `patch -p1 < "$patchfile"`.
- For verbose mode, print: `[PATCH 04] ... ok` or `[PATCH 04] ... skip (already applied)` or `[PATCH 04] ... FAILED`
- The `--verbose` flag should be a boolean switch in the script: `./script.sh --verbose build` or add it to `patch_source()`'s args and pass through from `do_build()` (which is called from the `build)` case). Simplest: check for `--verbose` in `$@` or add a global `VERBOSE` flag.
- Keep the existing `bc250_cc_write_mode` check as a fast path — if that greps present, skip all patches.
- The `patch/` directory is relative to the script's location (the script is in `scripts/`, patches are in `patch/` — so use `PATCH_DIR="$(dirname "$0")/../patch"` or similar).

### Constraints

- This is a POSIX shell script (`#!/bin/sh`). Use POSIX-compatible constructs.
- The script already has `info()`, `warn()`, `err()` functions for logging to stderr. Use them.
- `set -euo pipefail` is already active — errors will abort naturally, but add explicit error messages for patch failures.
- Keep the rest of the script unchanged. Only modify `patch_source()` and optionally add verbose flag handling.

## Test criteria

1. **Dry run without verbose**: Script runs `build` silently (only `[+]` info messages, no per-patch output) and completes successfully.
2. **Verbose run**: `build --verbose` or `--verbose` flag shows each patch being applied.
3. **Skip logic**: If the patch was already applied (source tree already has all patches), the script reports "Source already patched" and skips all patches without error.
4. **Failure handling**: If a patch fails (simulated or real), the script reports the failure and exits non-zero.
5. **Patch 12, 19, 21 are skipped**: These patches are never applied even though they exist in the directory.

## Files to touch

- `scripts/bc250-enable-40cu-alpine.sh` — modify `patch_source()`, optionally add verbose flag handling to `do_build()` and the `case` statement
