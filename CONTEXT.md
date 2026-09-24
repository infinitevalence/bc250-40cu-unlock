Phase 1 findings:

### Key differences between 7.0.x and 6.18.53:

1. Locking: Old 7.0.x used smu->msg_ctl.lock (a mutex inside struct smu_msg_ctl). In 6.18.53, it's smu->message_lock (a direct struct mutex member in struct smu_context).
2. Message control structs: Old 7.0.x had struct smu_msg_ctl (containing lock and config which was struct smu_msg_config). In 6.18.53, these are gone - the locking and configuration fields are directly in struct smu_context.
3. Polling: Old 7.0.x had __smu_msg_v1_poll_stat() that took a struct smu_msg_ctl *. In 6.18.53, it's __smu_cmn_poll_stat() that takes struct smu_context *smu.
4. Send message: Old 7.0.x wrote to cfg->arg_regs[0], cfg->arg_regs[1], cfg->msg_reg, etc. In 6.18.53, __smu_cmn_send_msg() writes to smu->resp_reg, smu->param_reg, smu->msg_reg.
5. Read arg: Old 7.0.x read from cfg->arg_regs[0]. In 6.18.53, smu_cmn_read_arg() reads from smu->param_reg.
6. Second arg register: Old 7.0.x handled num_arg_regs > 1 and num_arg_regs == 1 (where arg_regs[0] - 1 was used for the extra arg). In 6.18.53, __smu_cmn_send_msg() only takes one param. For the raw send function, I'll need to handle the second argument register directly.
7. No smu_cmn_send_raw_smc_msg exists in 6.18.53 - it needs to be added.
8. The send_raw debugfs and CAC debugfs also need to be added.

Now let me proceed to write the patches. I'll create:
- patch/bc250-cachyos-6.18.53/08-smu-cmn-send-raw-debugfs-definitions.patch - adds smu_cmn_send_raw_smc_msg(), smu_cmn_create_send_raw_debugfs(), and the debugfs implementation
- patch/bc250-cachyos-6.18.53/07-cac-weight-and-sendraw-debugfs.patch - adds CAC weight debugfs and declarations

Phase 1 Complete — Source context gathered

Here's what I found in 6.18.53 vs old 7.0.x:

┌───────────────────────────────────────────┬────────────────────────────────────────────────────────────────┐
│ Old (7.0.x)                               │ New (6.18.53)                                                  │
├───────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤
│ smu->msg_ctl.lock                         │ smu->message_lock                                              │
├───────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤
│ struct smu_msg_ctl *ctl = &smu->msg_ctl   │ Gone — fields inline in struct smu_context                     │
├───────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤
│ struct smu_msg_config *cfg = &ctl->config │ Gone — replaced by smu->param_reg, smu->msg_reg, smu->resp_reg │
├───────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤
│ __smu_msg_v1_poll_stat(ctl, 0)            │ __smu_cmn_poll_stat(smu)                                       │
├───────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤
│ cfg->arg_regs[0] for read                 │ smu->param_reg (via smu_cmn_read_arg())                        │
├───────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤
│ cfg->num_arg_regs > 1 / == 1 trick        │ No 2nd arg reg support in __smu_cmn_send_msg()                 │
└───────────────────────────────────────────┴────────────────────────────────────────────────────────────────┘

No smu_cmn_send_raw_smc_msg() exists in 6.18.53 — it must be added.

Phase 1 — Agent 2 complete.

Copied both CachyOS 7.0.x patches to patch/bc250-cachyos-6.18.53/ for reference:

┌───────────────────────────────────────────────┬───────┬───────────────────────────────────────────────┐
│ Patch                                         │ Lines │ Files touched                                 │
├───────────────────────────────────────────────┼───────┼───────────────────────────────────────────────┤
│ 07-cac-weight-and-sendraw-debugfs.patch       │ 207   │ cyan_skillfish_ppt.c, smu_cmn.h, amdgpu_smu.c │
├───────────────────────────────────────────────┼───────┼───────────────────────────────────────────────┤
│ 08-smu-cmn-send-raw-debugfs-definitions.patch │ 167   │ smu_cmn.c                                     │
└───────────────────────────────────────────────┴───────┴───────────────────────────────────────────────┘

Key patterns extracted via grep scan:

7.0.x patterns to replace:
- smu->msg_ctl.lock — mutex lock around send-raw
- __smu_msg_v1_poll_stat(ctl, ...) — drain/poll helper
- struct smu_msg_ctl *ctl and struct smu_msg_config *cfg — struct references

Functions defined in 08:
- smu_cmn_send_raw_smc_msg() — core send-raw function
- smu_cmn_create_send_raw_debugfs() — debugfs node setup

→ skipped: nothing for this phase. Agent 1 now handles Phase 2 mapping + writing the 6.18.53 patches.


 Here's the verification:

 Agent 1 — Analyze locking ✅
 - smu->msg_ctl.lock confirmed gone in 6.18.53
 - New lock: smu->message_lock (a struct mutex in struct smu_context, found at amdgpu_smu.h:553)

 Agent 2 — Map struct/function replacements ✅

 ┌──────────────────────────┬─────────────────────────────────────────────┬────────┐
 │ Old (7.0.x)              │ New (6.18.53)                               │ Status │
 ├──────────────────────────┼─────────────────────────────────────────────┼────────┤
 │ smu->msg_ctl.lock        │ smu->message_lock                           │ mapped │
 ├──────────────────────────┼─────────────────────────────────────────────┼────────┤
 │ struct smu_msg_ctl       │ fields inline in smu_context                │ mapped │
 ├──────────────────────────┼─────────────────────────────────────────────┼────────┤
 │ struct smu_msg_config    │ smu->param_reg, smu->msg_reg, smu->resp_reg │ mapped │
 ├──────────────────────────┼─────────────────────────────────────────────┼────────┤
 │ __smu_msg_v1_poll_stat() │ __smu_cmn_poll_stat()                       │ mapped │
 └──────────────────────────┴─────────────────────────────────────────────┴────────┘

 Agent 1 — Write patched 08 ✅
 - patch/bc250-cachyos-6.18.53/08-smu-cmn-send-raw-debugfs-definitions.patch (184 lines)
 - Uses smu->message_lock, __smu_cmn_poll_stat(), no old-API references

 Agent 2 — Patch 07 ✅
 - patch/bc250-cachyos-6.18.53/07-cac-weight-and-sendraw-debugfs.patch (207 lines)
 - No old-API references, targets correct kernel files

 CONTEXT.md already documents: ✅ Phase 2 — API mapping analyzed

 Next up per CONTEXT.md: Phase 3 (compile check) and Phase 4 (build script).
