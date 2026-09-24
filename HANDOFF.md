# Handoff: Option B — Port patches 07+08 to kernel 6.18.53

## Plan

### Phase 1 — Gather source context

**Agent 1 — Extract 6.18.53 kernel source:**
- Download `linux-6.18.53` source (Alpine pkgsrc or `git clone` from alpine linux.git)
- Extract to a known temp directory
- Copy out `drivers/gpu/drm/amd/smu/smu_cmn.c` and `smu_cmn.h`

**Agent 2 — Copy patches for reference:**
- Copy `patch/bc250-cachyos-7.0.9/07-cac-weight-and-sendraw-debugfs.patch` and `08-smu-cmn-send-raw-debugfs-definitions.patch` to a working directory
- These are the 7.0.x originals we're porting

### Phase 2 — Map the API changes (the actual porting work)

**Agent 1 — Analyze locking in 6.18.53:**
- Grepping `smu_cmn.c` in 6.18.53 for the old `smu->msg_ctl` references → confirm they're gone
- Find the current locking mechanism: grep for `mutex`, `spinlock`, or `atomic` in the SMU send functions
- Identify how `smu_cmn_send_smc_msg_with_param()` and `smu_cmn_send_raw_smc_msg()` lock/message-queue in 6.18.53

**Agent 2 — Map the struct/function replacements:**
- Find what replaced `__smu_msg_v1_poll_stat` (grep for `poll_stat`, `smu_poll`, `amdgpu_poll`)
- Find what replaced `struct smu_msg_ctl` and `struct smu_msg_config` (grep for these names or examine `struct smu_context` members)
- Identify what the new send function looks like and how it's called

**Agent 1 — Write the patched 08:**
- Create `patch/bc250-cachyos-6.18.53/08-smu-cmn-send-raw-debugfs-definitions.patch`
- Replace `smu->msg_ctl` references with the 6.18.53 equivalent locking
- Replace `__smu_msg_v1_poll_stat` with the 6.18.53 renamed/reimplemented version
- Replace `struct smu_msg_ctl` and `struct smu_msg_config` with whatever exists in 6.18.53
- Keep `smu_cmn_send_raw_smc_msg()` signature but adapt its internals

**Agent 2 — Patch 07:**
- Create `patch/bc250-cachyos-6.18.53/07-cac-weight-and-sendraw-debugfs.patch`
- Patch 07 depends on the definitions from 08, so it should be straightforward once 08 compiles
- Verify its debugfs nodes reference the same `smu_context` members used in 08

### Phase 3 — Validate

**Agent 1 — Apply patches to kernel source:**
- Apply both patches to the 6.18.53 kernel source
- Run a compile check (`make -j$(nproc) drivers/gpu/drm/amd/smu/`) — verify no SMU-related errors
- Check that the resulting `.ko` loads without errors

**Agent 2 — Verify functional correctness:**
- Confirm the debugfs interface names and file ops match what the script expects
- Verify the CAC weight read and raw SMC message send paths are coherent
- Ensure patches don't break other SMU functions (grep for side effects)

### Phase 4 — Update build script

**Agent 1 — Update bc250-enable-40cu-alpine.sh:**
- Update the patch selection logic to use the new 6.18.53 patches instead of the CachyOS ones
- Or add the new patch directory to the script's patch search path
- Ensure patches 07 and 08 are **not** in `skip_default` (they now compile)

## Key unknowns to resolve in Phase 2

| Old (7.0.x) | New (6.18.53) | Action |
|-------------|---------------|--------|
| `smu->msg_ctl.lock` | ? | grep mutex/spinlock in smu_cmn.c |
| `struct smu_msg_ctl` | ? | grep for name or inline it |
| `struct smu_msg_config` | ? | grep for name or inline it |
| `__smu_msg_v1_poll_stat()` | ? | grep `poll` or `smu_msg` |

## Risk notes

- The locking mechanism may have been redesigned entirely (e.g., per-asic instead of per-asic, or a global lock). This changes the diff size significantly.
- `__smu_msg_v1_poll_stat` may have been fully inlined into its caller or removed entirely — we may need to replicate its logic from scratch.
- If the SMU send path changed fundamentally, `send_raw_smc_msg()` may need a complete rewrite rather than a search-and-replace.
