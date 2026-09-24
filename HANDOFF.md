# Handoff: Patch 17 compilation failure — undeclared GMC9 fault source constants

## The issue

Kernel 6.18.53 does not define these three constants used by patch 17
(`17-bc250-gfx1013-fault-probe.patch`):

- `AMDGPU_GMC9_FAULT_SOURCE_DATA_RETRY`
- `AMDGPU_GMC9_FAULT_SOURCE_DATA_EXE`
- `AMDGPU_GMC9_FAULT_SOURCE_DATA_WRITE`

The error is in `gmc_v10_0_process_interrupt()` at lines 205–213 of
`gmc_v10_0.c`. The patch is **diagnostic, report-only** — it changes no
control flow and fixes nothing. It's not required for the 40 CU unlock.

## Recommended fix (pick one)

### Option A — Drop patch 17 (simpler)

In `bc250-enable-40cu-alpine.sh`, add patch 17 to the `skip_default` list
(so it defaults to N on interactive prompt). Or hard-remove it from the
build. This is the simplest path — the probe is purely diagnostic.

### Option B — Define the constants locally in the patch

Add `#define` statements at the top of the patch's hunk in
`gmc_v10_0.c` for these three macros. They are bitmask values used to
extract bits from `entry->src_data[1]`. You'll need to look up the actual
bit positions in a kernel where they're defined (e.g. a newer amdgull
driver tree), or reverse-engineer them from the bit layout of the GMC9
fault source data register.

## Context

- The script (`scripts/bc250-enable-40cu-alpine.sh`) selects patches from
  `patch/` directory before applying them to kernel source.
- Patch 17 sits at line 180-223 of `gmc_v10_0.c` in the kernel source.
- The fault probe is gated by `amdgpu.bc250_fault_probe` (default 1).
